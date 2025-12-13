"""
FURG - Chat-First Financial AI Backend
Main FastAPI application
"""

import os
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from contextlib import asynccontextmanager

from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel

from auth import (
    verify_apple_token,
    verify_test_apple_token,
    create_jwt_token,
    get_current_user
)
from database import db
from rate_limiter import rate_limit, get_remaining_budget
from services.chat import ChatService  # Legacy single-model service
from services.chat_v2 import ChatServiceV2  # Multi-model service
from services.plaid_service import PlaidService
from services.bill_detection import BillDetector
from services.shadow_banking import ShadowBankingService
from services.gemini_service import gemini_service
from services.grok_service import grok_service
from ml.categorizer import get_categorizer

# Feature flag for multi-model chat
USE_MULTI_MODEL_CHAT = os.getenv("USE_MULTI_MODEL_CHAT", "true").lower() == "true"


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("🚀 Starting FURG backend...")
    await db.connect()
    print("✅ Database connected")

    # Initialize multi-model chat if enabled
    if USE_MULTI_MODEL_CHAT:
        print("🤖 Initializing multi-model chat (Grok + Claude + Gemini)...")
        await ChatServiceV2.initialize()
        print("✅ Multi-model router ready")
        print("   - Grok 4 Fast: Roasting & casual chat")
        print("   - Claude Sonnet: Financial advice")
        print("   - Gemini Flash: Routing & categorization")
    else:
        print("📝 Using single-model chat (Claude only)")

    yield

    # Shutdown
    print("👋 Shutting down FURG backend...")
    await gemini_service.close()
    await grok_service.close()
    await db.disconnect()


# Initialize FastAPI app
app = FastAPI(
    title="FURG API",
    description="Chat-First Financial AI with Roasting Personality",
    version="1.0.0",
    lifespan=lifespan
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ==================== REQUEST/RESPONSE MODELS ====================

class AppleAuthRequest(BaseModel):
    apple_token: str
    user_identifier: Optional[str] = None


class AppleAuthResponse(BaseModel):
    jwt: str
    user_id: str
    is_new_user: bool


class ChatRequest(BaseModel):
    message: str
    include_context: bool = True


class ChatResponse(BaseModel):
    message: str
    tokens_used: Optional[Dict[str, int]] = None
    model: Optional[str] = None  # Which model handled the request
    intent: Optional[str] = None  # Classified intent (roast, advice, etc.)
    cost: Optional[float] = None  # Cost in dollars
    latency_ms: Optional[int] = None  # Response latency


class PlaidLinkTokenResponse(BaseModel):
    link_token: str


class PlaidExchangeRequest(BaseModel):
    public_token: str


class HideMoneyRequest(BaseModel):
    amount: float
    purpose: Optional[str] = "forced_savings"


class RevealMoneyRequest(BaseModel):
    amount: Optional[float] = None
    account_id: Optional[str] = None


class SavingsGoalRequest(BaseModel):
    goal_amount: float
    deadline: str  # YYYY-MM-DD
    purpose: str
    frequency: Optional[str] = "weekly"


class CreateGoalRequest(BaseModel):
    name: str
    target_amount: float
    deadline: Optional[str] = None  # YYYY-MM-DD
    category: str = "general"
    auto_contribute: bool = False
    monthly_contribution: Optional[float] = None


class ContributeToGoalRequest(BaseModel):
    goal_id: str
    amount: float


class SubscriptionAction(BaseModel):
    subscription_id: str
    action: str  # "cancel", "pause", "negotiate"


# ==================== HEALTH & INFO ENDPOINTS ====================

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "app": "FURG",
        "tagline": "Your money, but smarter than you",
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    try:
        # Test database connection
        async with db.acquire() as conn:
            await conn.fetchval("SELECT 1")

        return {
            "status": "healthy",
            "database": "connected",
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        return JSONResponse(
            status_code=503,
            content={
                "status": "unhealthy",
                "error": str(e)
            }
        )


# ==================== AUTHENTICATION ENDPOINTS ====================

@app.post("/api/v1/auth/apple", response_model=AppleAuthResponse)
async def authenticate_with_apple(request: AppleAuthRequest):
    """
    Authenticate user with Sign in with Apple

    Exchange Apple ID token for JWT
    """
    # Verify Apple token (use test verification in debug mode)
    if os.getenv("DEBUG", "false").lower() == "true":
        apple_data = await verify_test_apple_token(request.apple_token)
    else:
        apple_data = await verify_apple_token(request.apple_token)

    apple_user_id = apple_data["sub"]
    email = apple_data.get("email")

    # Get or create user
    user = await db.get_or_create_user(apple_user_id, email)
    is_new_user = user.get("created_at") and (
        datetime.utcnow() - user["created_at"]
    ).total_seconds() < 60  # Created in last minute

    # Generate JWT
    jwt_token = create_jwt_token(str(user["id"]))

    return AppleAuthResponse(
        jwt=jwt_token,
        user_id=str(user["id"]),
        is_new_user=is_new_user
    )


@app.get("/api/v1/auth/me")
async def get_current_user_info(user_id: str = Depends(get_current_user)):
    """Get current authenticated user info"""
    user = await db.get_user(user_id)
    profile = await db.get_user_profile(user_id)

    if not user:
        raise HTTPException(404, "User not found")

    return {
        "user_id": user_id,
        "email": user.get("email"),
        "created_at": user.get("created_at"),
        "profile": profile
    }


# ==================== CHAT ENDPOINTS ====================

@app.post("/api/v1/chat", response_model=ChatResponse)
@rate_limit
async def chat(request: ChatRequest, user_id: str = Depends(get_current_user)):
    """
    Send a message to FURG and get a response

    Multi-model routing:
    - Roasting/casual -> Grok 4 Fast (cheap, fast)
    - Financial advice -> Claude Sonnet (nuanced)
    - Categorization -> Gemini Flash (fast)
    """
    # Get user profile
    profile = await db.get_user_profile(user_id)

    # Build context if requested
    context = None
    if request.include_context:
        context = await _build_chat_context(user_id)

    # Use multi-model or legacy single-model chat
    if USE_MULTI_MODEL_CHAT:
        # Multi-model chat with intelligent routing
        response = await ChatServiceV2.chat(
            user_id=user_id,
            message=request.message,
            profile=profile,
            context=context,
            life_context=None  # TODO: Wire up iOS life context
        )

        return ChatResponse(
            message=response["message"],
            tokens_used=response.get("tokens_used"),
            model=response.get("model"),
            intent=response.get("intent"),
            cost=response.get("cost"),
            latency_ms=response.get("latency_ms")
        )
    else:
        # Legacy single-model chat (Claude only)
        command_response = await ChatService.handle_command(user_id, request.message)
        if command_response:
            await db.save_message(user_id, "user", request.message)
            await db.save_message(user_id, "assistant", command_response)
            return ChatResponse(message=command_response)

        response = await ChatService.chat(user_id, request.message, profile, context)

        return ChatResponse(
            message=response["message"],
            tokens_used=response.get("tokens_used"),
            model="claude-sonnet-4-20250514"
        )


@app.get("/api/v1/chat/history")
async def get_chat_history(
    limit: int = 50,
    user_id: str = Depends(get_current_user)
):
    """Get conversation history"""
    history = await db.get_conversation_history(user_id, limit)

    return {
        "messages": [
            {
                "role": msg["role"],
                "content": msg["content"],
                "timestamp": msg["created_at"].isoformat()
            }
            for msg in history
        ]
    }


@app.delete("/api/v1/chat/history")
async def clear_chat_history(user_id: str = Depends(get_current_user)):
    """Clear conversation history"""
    await db.clear_conversation_history(user_id)
    return {"message": "Conversation history cleared"}


@app.get("/api/v1/chat/routing-stats")
async def get_routing_stats(user_id: str = Depends(get_current_user)):
    """
    Get model routing statistics

    Shows which models are handling requests and associated costs
    """
    if not USE_MULTI_MODEL_CHAT:
        return {
            "enabled": False,
            "message": "Multi-model routing is disabled"
        }

    stats = await ChatServiceV2.get_routing_stats(user_id)

    return {
        "enabled": True,
        "user_stats": stats,
        "models": {
            "grok-4-fast": {
                "purpose": "Roasting & casual chat",
                "cost_per_1m_input": 0.20,
                "cost_per_1m_output": 0.50
            },
            "claude-sonnet-4-20250514": {
                "purpose": "Financial advice & complex questions",
                "cost_per_1m_input": 3.00,
                "cost_per_1m_output": 15.00
            },
            "gemini-2.0-flash": {
                "purpose": "Routing & categorization",
                "cost_per_1m_input": 0.075,
                "cost_per_1m_output": 0.30
            }
        }
    }


# ==================== PLAID ENDPOINTS ====================

@app.post("/api/v1/plaid/link-token", response_model=PlaidLinkTokenResponse)
async def create_plaid_link_token(user_id: str = Depends(get_current_user)):
    """Create Plaid Link token for connecting banks"""
    link_token = await PlaidService.create_link_token(user_id)
    return PlaidLinkTokenResponse(link_token=link_token)


@app.post("/api/v1/plaid/exchange")
async def exchange_plaid_token(
    request: PlaidExchangeRequest,
    user_id: str = Depends(get_current_user)
):
    """Exchange public token for access token after bank connection"""
    result = await PlaidService.exchange_public_token(user_id, request.public_token)
    return result


@app.post("/api/v1/plaid/sync/{item_id}")
async def sync_plaid_transactions(
    item_id: str,
    user_id: str = Depends(get_current_user)
):
    """Sync transactions for a connected bank"""
    result = await PlaidService.sync_transactions(user_id, item_id)
    return result


@app.post("/api/v1/plaid/sync-all")
async def sync_all_plaid_transactions(user_id: str = Depends(get_current_user)):
    """Sync transactions from all connected banks"""
    result = await PlaidService.sync_all_banks(user_id)
    return result


@app.get("/api/v1/plaid/accounts/{item_id}")
async def get_plaid_accounts(
    item_id: str,
    user_id: str = Depends(get_current_user)
):
    """Get account information for a connected bank"""
    accounts = await PlaidService.get_accounts(user_id, item_id)
    return {"accounts": accounts}


@app.delete("/api/v1/plaid/banks/{item_id}")
async def remove_plaid_bank(
    item_id: str,
    user_id: str = Depends(get_current_user)
):
    """Remove a connected bank"""
    await PlaidService.remove_bank(user_id, item_id)
    return {"message": "Bank removed successfully"}


# ==================== TRANSACTION ENDPOINTS ====================

@app.get("/api/v1/transactions")
async def get_transactions(
    days: int = 30,
    limit: int = 100,
    user_id: str = Depends(get_current_user)
):
    """Get transaction history"""
    start_date = datetime.now() - timedelta(days=days)
    transactions = await db.get_transactions(
        user_id=user_id,
        start_date=start_date,
        limit=limit
    )

    return {
        "transactions": [
            {
                "id": str(txn["id"]),
                "date": txn["date"].isoformat(),
                "amount": float(txn["amount"]),
                "merchant": txn["merchant"],
                "category": txn.get("category"),
                "is_bill": txn.get("is_bill", False)
            }
            for txn in transactions
        ]
    }


@app.get("/api/v1/transactions/spending")
async def get_spending_summary(
    days: int = 30,
    user_id: str = Depends(get_current_user)
):
    """Get spending summary by category"""
    start_date = datetime.now() - timedelta(days=days)
    spending = await db.get_spending_by_category(
        user_id,
        start_date,
        datetime.now()
    )

    total = sum(spending.values())

    return {
        "total_spent": round(total, 2),
        "by_category": {k: round(v, 2) for k, v in spending.items()},
        "period_days": days
    }


# ==================== BILL ENDPOINTS ====================

@app.post("/api/v1/bills/detect")
async def detect_bills(
    days_lookback: int = 90,
    user_id: str = Depends(get_current_user)
):
    """Run bill detection on transaction history"""
    bills = await BillDetector.detect_bills(user_id, days_lookback)

    return {
        "detected": len(bills),
        "bills": bills
    }


@app.get("/api/v1/bills")
async def get_bills(user_id: str = Depends(get_current_user)):
    """Get all active bills"""
    bills = await db.get_active_bills(user_id)

    return {
        "bills": [
            {
                "merchant": bill["merchant"],
                "amount": float(bill["amount"]),
                "frequency_days": bill["frequency_days"],
                "next_due": bill["next_due_date"].isoformat() if hasattr(bill["next_due_date"], "isoformat") else str(bill["next_due_date"]),
                "confidence": float(bill["confidence"])
            }
            for bill in bills
        ]
    }


@app.get("/api/v1/bills/upcoming")
async def get_upcoming_bills(
    days: int = 30,
    user_id: str = Depends(get_current_user)
):
    """Get bills due in next N days"""
    result = await BillDetector.calculate_upcoming_bills(user_id, days)
    return result


# ==================== BALANCE & MONEY ENDPOINTS ====================

@app.get("/api/v1/balance")
async def get_balance(user_id: str = Depends(get_current_user)):
    """Get balance summary (visible + hidden)"""
    summary = await ShadowBankingService.get_balance_summary(user_id)
    return summary


@app.post("/api/v1/money/hide")
async def hide_money(
    request: HideMoneyRequest,
    user_id: str = Depends(get_current_user)
):
    """Hide money for forced savings"""
    result = await ShadowBankingService.hide_money(
        user_id,
        request.amount,
        request.purpose
    )
    return result


@app.post("/api/v1/money/reveal")
async def reveal_money(
    request: RevealMoneyRequest,
    user_id: str = Depends(get_current_user)
):
    """Reveal hidden money"""
    result = await ShadowBankingService.reveal_money(
        user_id,
        request.amount,
        request.account_id
    )
    return result


@app.post("/api/v1/savings-goal")
async def set_savings_goal(
    request: SavingsGoalRequest,
    user_id: str = Depends(get_current_user)
):
    """Set up automatic savings goal"""
    result = await ShadowBankingService.auto_hide_for_goal(
        user_id,
        request.goal_amount,
        request.deadline,
        request.frequency
    )
    return result


# ==================== PROFILE ENDPOINTS ====================

@app.get("/api/v1/profile")
async def get_profile(user_id: str = Depends(get_current_user)):
    """Get user profile"""
    profile = await db.get_user_profile(user_id)
    if not profile:
        raise HTTPException(404, "Profile not found")
    return profile


@app.patch("/api/v1/profile")
async def update_profile(
    updates: Dict[str, Any],
    user_id: str = Depends(get_current_user)
):
    """Update user profile"""
    success = await db.update_user_profile(user_id, updates)
    if not success:
        raise HTTPException(400, "Failed to update profile")

    return {"message": "Profile updated successfully"}


# ==================== USAGE & BUDGET ENDPOINTS ====================

@app.get("/api/v1/usage")
async def get_usage_stats(user_id: str = Depends(get_current_user)):
    """Get API usage and budget stats"""
    budget = await get_remaining_budget(user_id)
    return budget


# ==================== SUBSCRIPTION ENDPOINTS ====================

@app.get("/api/v1/subscriptions")
async def get_subscriptions(user_id: str = Depends(get_current_user)):
    """Get detected subscriptions"""
    subscriptions = await db.get_subscriptions(user_id)

    return {
        "subscriptions": subscriptions,
        "total_monthly": sum(s.get("monthly_cost", 0) for s in subscriptions),
        "unused_count": sum(1 for s in subscriptions if s.get("is_unused", False))
    }


@app.post("/api/v1/subscriptions/detect")
async def detect_subscriptions(
    days_lookback: int = 180,
    user_id: str = Depends(get_current_user)
):
    """Detect subscriptions from transaction history"""
    # Get transactions
    start_date = datetime.now() - timedelta(days=days_lookback)
    transactions = await db.get_transactions(user_id, start_date=start_date, limit=500)

    # Detect recurring patterns
    subscriptions = await _detect_subscription_patterns(transactions)

    # Save to database
    for sub in subscriptions:
        await db.save_subscription(user_id, sub)

    return {
        "detected": len(subscriptions),
        "subscriptions": subscriptions,
        "total_monthly": sum(s.get("monthly_cost", 0) for s in subscriptions)
    }


@app.get("/api/v1/subscriptions/{subscription_id}/cancellation-guide")
async def get_cancellation_guide(
    subscription_id: str,
    user_id: str = Depends(get_current_user)
):
    """Get cancellation guide for a subscription"""
    subscription = await db.get_subscription(user_id, subscription_id)
    if not subscription:
        raise HTTPException(404, "Subscription not found")

    # Generate cancellation guide based on merchant
    guide = await _get_cancellation_guide(subscription["merchant"])

    return guide


@app.post("/api/v1/subscriptions/{subscription_id}/mark-cancelled")
async def mark_subscription_cancelled(
    subscription_id: str,
    user_id: str = Depends(get_current_user)
):
    """Mark a subscription as cancelled"""
    success = await db.update_subscription(
        user_id,
        subscription_id,
        {"status": "cancelled", "cancelled_at": datetime.now().isoformat()}
    )

    if not success:
        raise HTTPException(400, "Failed to update subscription")

    return {"message": "Subscription marked as cancelled", "id": subscription_id}


@app.get("/api/v1/subscriptions/{subscription_id}/negotiation-script")
async def get_negotiation_script(
    subscription_id: str,
    user_id: str = Depends(get_current_user)
):
    """Get negotiation script for a subscription"""
    subscription = await db.get_subscription(user_id, subscription_id)
    if not subscription:
        raise HTTPException(404, "Subscription not found")

    script = await _get_negotiation_script(subscription)
    return script


# ==================== GOALS ENDPOINTS ====================

@app.get("/api/v1/goals")
async def get_goals(user_id: str = Depends(get_current_user)):
    """Get all savings goals"""
    goals = await db.get_goals(user_id)

    total_target = sum(g.get("target_amount", 0) for g in goals)
    total_saved = sum(g.get("current_amount", 0) for g in goals)

    return {
        "goals": goals,
        "total_target": round(total_target, 2),
        "total_saved": round(total_saved, 2),
        "overall_progress": round((total_saved / total_target * 100) if total_target > 0 else 0, 1)
    }


@app.post("/api/v1/goals")
async def create_goal(
    request: CreateGoalRequest,
    user_id: str = Depends(get_current_user)
):
    """Create a new savings goal"""
    goal = {
        "name": request.name,
        "target_amount": request.target_amount,
        "current_amount": 0,
        "deadline": request.deadline,
        "category": request.category,
        "auto_contribute": request.auto_contribute,
        "monthly_contribution": request.monthly_contribution,
        "created_at": datetime.now().isoformat()
    }

    goal_id = await db.create_goal(user_id, goal)

    return {
        "message": "Goal created successfully",
        "goal_id": goal_id,
        "goal": goal
    }


@app.get("/api/v1/goals/{goal_id}")
async def get_goal(goal_id: str, user_id: str = Depends(get_current_user)):
    """Get a specific goal"""
    goal = await db.get_goal(user_id, goal_id)
    if not goal:
        raise HTTPException(404, "Goal not found")

    # Calculate progress
    progress = round((goal.get("current_amount", 0) / goal.get("target_amount", 1)) * 100, 1)

    return {
        **goal,
        "progress_percent": progress
    }


@app.patch("/api/v1/goals/{goal_id}")
async def update_goal(
    goal_id: str,
    updates: Dict[str, Any],
    user_id: str = Depends(get_current_user)
):
    """Update a goal"""
    success = await db.update_goal(user_id, goal_id, updates)
    if not success:
        raise HTTPException(400, "Failed to update goal")

    return {"message": "Goal updated successfully"}


@app.delete("/api/v1/goals/{goal_id}")
async def delete_goal(goal_id: str, user_id: str = Depends(get_current_user)):
    """Delete a goal"""
    success = await db.delete_goal(user_id, goal_id)
    if not success:
        raise HTTPException(400, "Failed to delete goal")

    return {"message": "Goal deleted successfully"}


@app.post("/api/v1/goals/{goal_id}/contribute")
async def contribute_to_goal(
    goal_id: str,
    request: ContributeToGoalRequest,
    user_id: str = Depends(get_current_user)
):
    """Contribute to a savings goal"""
    goal = await db.get_goal(user_id, goal_id)
    if not goal:
        raise HTTPException(404, "Goal not found")

    new_amount = goal.get("current_amount", 0) + request.amount

    # Update goal
    await db.update_goal(user_id, goal_id, {"current_amount": new_amount})

    # Log contribution
    await db.log_goal_contribution(user_id, goal_id, request.amount)

    # Check for milestone
    progress = (new_amount / goal.get("target_amount", 1)) * 100
    milestone_message = None

    if progress >= 100:
        milestone_message = f"Congratulations! You've reached your '{goal['name']}' goal!"
    elif progress >= 75 and (goal.get("current_amount", 0) / goal.get("target_amount", 1) * 100) < 75:
        milestone_message = f"Amazing! You're 75% of the way to your '{goal['name']}' goal!"
    elif progress >= 50 and (goal.get("current_amount", 0) / goal.get("target_amount", 1) * 100) < 50:
        milestone_message = f"Halfway there! 50% of your '{goal['name']}' goal reached!"
    elif progress >= 25 and (goal.get("current_amount", 0) / goal.get("target_amount", 1) * 100) < 25:
        milestone_message = f"Great start! 25% of your '{goal['name']}' goal achieved!"

    return {
        "message": "Contribution recorded",
        "new_amount": round(new_amount, 2),
        "progress_percent": round(progress, 1),
        "milestone": milestone_message
    }


@app.get("/api/v1/goals/{goal_id}/history")
async def get_goal_history(goal_id: str, user_id: str = Depends(get_current_user)):
    """Get contribution history for a goal"""
    history = await db.get_goal_contributions(user_id, goal_id)

    return {
        "contributions": history,
        "total_contributed": sum(c.get("amount", 0) for c in history)
    }


# ==================== HELPER FUNCTIONS ====================

async def _build_chat_context(user_id: str) -> Dict[str, Any]:
    """Build context for chat with recent transactions, bills, etc."""
    # Get balance
    balance_summary = await ShadowBankingService.get_balance_summary(user_id)

    # Get recent transactions
    start_date = datetime.now() - timedelta(days=7)
    recent_txns = await db.get_transactions(
        user_id,
        start_date=start_date,
        limit=20
    )

    # Get upcoming bills
    upcoming_bills = await BillDetector.calculate_upcoming_bills(user_id, 30)

    # Get spending by category (this month)
    month_start = datetime.now().replace(day=1, hour=0, minute=0, second=0)
    spending = await db.get_spending_by_category(user_id, month_start, datetime.now())

    return {
        "balance": balance_summary["visible_balance"],
        "hidden_balance": balance_summary["hidden_balance"],
        "upcoming_bills": upcoming_bills,
        "recent_transactions": [
            {
                "date": txn["date"],
                "amount": float(txn["amount"]),
                "merchant": txn["merchant"],
                "category": txn.get("category")
            }
            for txn in recent_txns
        ],
        "spending_by_category": {k: round(v, 2) for k, v in spending.items()}
    }


async def _detect_subscription_patterns(transactions: list) -> list:
    """Detect recurring subscription patterns from transactions"""
    from collections import defaultdict

    # Group transactions by merchant
    merchant_txns = defaultdict(list)
    for txn in transactions:
        if txn.get("amount", 0) < 0:  # Only expenses
            merchant_txns[txn.get("merchant", "").lower()].append(txn)

    subscriptions = []
    known_subscription_merchants = [
        "netflix", "spotify", "hulu", "disney", "hbo", "amazon prime",
        "apple music", "youtube premium", "adobe", "microsoft 365",
        "dropbox", "icloud", "google one", "nordvpn", "expressvpn",
        "gym", "fitness", "peloton", "crunchyroll", "paramount",
        "audible", "kindle", "instacart", "doordash", "uber one"
    ]

    for merchant, txns in merchant_txns.items():
        if len(txns) < 2:
            continue

        # Check if known subscription merchant
        is_known = any(known in merchant for known in known_subscription_merchants)

        # Check for consistent amounts
        amounts = [abs(t.get("amount", 0)) for t in txns]
        avg_amount = sum(amounts) / len(amounts)
        is_consistent = all(abs(a - avg_amount) < avg_amount * 0.1 for a in amounts)

        # Check frequency (monthly = ~30 days between charges)
        if len(txns) >= 2 and (is_known or is_consistent):
            # Calculate average days between transactions
            dates = sorted([t.get("date") for t in txns if t.get("date")])

            # Estimate monthly cost
            monthly_cost = avg_amount

            # Determine if unused (no transactions in last 30 days of activity)
            is_unused = len(txns) >= 3 and is_consistent

            subscriptions.append({
                "merchant": txns[0].get("merchant", merchant.title()),
                "amount": round(avg_amount, 2),
                "monthly_cost": round(monthly_cost, 2),
                "annual_cost": round(monthly_cost * 12, 2),
                "frequency": "monthly",
                "is_unused": is_unused,
                "confidence": 0.9 if is_known else 0.7,
                "category": _categorize_subscription(merchant)
            })

    return subscriptions


def _categorize_subscription(merchant: str) -> str:
    """Categorize a subscription based on merchant name"""
    merchant = merchant.lower()

    streaming = ["netflix", "hulu", "disney", "hbo", "paramount", "peacock", "crunchyroll", "youtube"]
    music = ["spotify", "apple music", "tidal", "pandora", "amazon music"]
    software = ["adobe", "microsoft", "dropbox", "google", "icloud", "notion"]
    fitness = ["gym", "fitness", "peloton", "planet fitness", "orange theory"]
    delivery = ["doordash", "uber eats", "grubhub", "instacart", "uber one"]
    gaming = ["xbox", "playstation", "nintendo", "steam", "ea play"]

    if any(s in merchant for s in streaming):
        return "Streaming"
    elif any(s in merchant for s in music):
        return "Music"
    elif any(s in merchant for s in software):
        return "Software"
    elif any(s in merchant for s in fitness):
        return "Fitness"
    elif any(s in merchant for s in delivery):
        return "Delivery"
    elif any(s in merchant for s in gaming):
        return "Gaming"
    else:
        return "Other"


async def _get_cancellation_guide(merchant: str) -> dict:
    """Get cancellation guide for a specific merchant"""
    merchant_lower = merchant.lower()

    # Cancellation difficulty ratings and guides
    cancellation_guides = {
        "netflix": {
            "difficulty": "easy",
            "steps": [
                "Log into your Netflix account",
                "Go to Account settings",
                "Click 'Cancel Membership'",
                "Confirm cancellation"
            ],
            "method": "web",
            "estimated_time": "2 minutes",
            "tips": ["You can reactivate anytime", "Access continues until billing period ends"],
            "warnings": []
        },
        "spotify": {
            "difficulty": "easy",
            "steps": [
                "Log into Spotify.com (not the app)",
                "Go to Account > Subscription",
                "Click 'Cancel Premium'",
                "Confirm"
            ],
            "method": "web",
            "estimated_time": "2 minutes",
            "tips": ["Can't cancel through mobile app", "You keep free tier access"],
            "warnings": []
        },
        "gym": {
            "difficulty": "hard",
            "steps": [
                "Review your contract for cancellation terms",
                "Visit gym in person (often required)",
                "Fill out cancellation form",
                "Get written confirmation",
                "Monitor for continued charges"
            ],
            "method": "in_person",
            "estimated_time": "30+ minutes",
            "tips": ["Bring ID", "Ask for confirmation number", "Take photos of all paperwork"],
            "warnings": ["May require 30-day notice", "Could have cancellation fee", "Some require certified mail"]
        },
        "adobe": {
            "difficulty": "medium",
            "steps": [
                "Log into Adobe.com",
                "Go to Plans & Products",
                "Click 'Manage plan' then 'Cancel plan'",
                "Go through retention offers",
                "Confirm cancellation"
            ],
            "method": "web",
            "estimated_time": "10 minutes",
            "tips": ["They will offer discounts - be firm if you want to cancel"],
            "warnings": ["Annual plans may have early termination fee (50% of remaining)"]
        }
    }

    # Find matching guide
    for key, guide in cancellation_guides.items():
        if key in merchant_lower:
            return {
                "merchant": merchant,
                **guide
            }

    # Default guide
    return {
        "merchant": merchant,
        "difficulty": "medium",
        "steps": [
            "Log into your account on their website",
            "Find Account or Settings section",
            "Look for Subscription or Billing options",
            "Select Cancel or Downgrade",
            "Confirm cancellation",
            "Save confirmation email/number"
        ],
        "method": "web",
        "estimated_time": "5-10 minutes",
        "tips": [
            "Check your email for account credentials",
            "Screenshot all confirmation pages",
            "Monitor bank statements for continued charges"
        ],
        "warnings": [
            "Some services require phone call to cancel",
            "Watch for 'pause' vs actual 'cancel' options"
        ]
    }


async def _get_negotiation_script(subscription: dict) -> dict:
    """Generate negotiation script for subscription discount"""
    merchant = subscription.get("merchant", "")
    amount = subscription.get("amount", 0)

    return {
        "merchant": merchant,
        "current_price": amount,
        "potential_savings": round(amount * 0.2, 2),  # Assume 20% possible
        "opening_line": f"Hi, I've been a loyal {merchant} customer and I'm considering canceling due to the cost. Before I do, I wanted to see if there are any retention offers or discounts available.",
        "key_points": [
            "Mention how long you've been a customer",
            "Reference competitor pricing if lower",
            "Be polite but firm about needing a discount",
            "Ask for supervisor if initial rep says no"
        ],
        "phrases_to_use": [
            "I'm comparing options and your competitors offer...",
            "What retention offers do you have available?",
            "I'd prefer to stay but I need a better rate",
            "Can I speak to someone in the retention department?"
        ],
        "fallback_options": [
            "Ask about downgrading to cheaper plan",
            "Request pause/freeze instead of cancel",
            "Ask about annual vs monthly pricing",
            "Inquire about student/military discounts"
        ],
        "success_tips": [
            "Call during business hours for better agents",
            "Be prepared to actually cancel if needed",
            "Many services have unpublished retention offers"
        ]
    }


# ==================== ROUND-UP ENDPOINTS ====================

class RoundUpConfigRequest(BaseModel):
    enabled: bool = True
    multiplier: float = 1.0  # 1x, 2x, 3x round-ups
    goal_id: Optional[str] = None
    auto_transfer: bool = False
    max_per_transaction: float = 10.0


@app.get("/api/v1/round-ups/config")
async def get_roundup_config(user_id: str = Depends(get_current_user)):
    """Get user's round-up configuration"""
    config = await db.get_roundup_config(user_id)

    if not config:
        # Return default config
        return {
            "enabled": False,
            "multiplier": 1.0,
            "goal_id": None,
            "auto_transfer": False,
            "max_per_transaction": 10.0
        }

    return config


@app.post("/api/v1/round-ups/config")
async def update_roundup_config(
    request: RoundUpConfigRequest,
    user_id: str = Depends(get_current_user)
):
    """Update round-up configuration"""
    config = {
        "enabled": request.enabled,
        "multiplier": request.multiplier,
        "goal_id": request.goal_id,
        "auto_transfer": request.auto_transfer,
        "max_per_transaction": request.max_per_transaction
    }

    success = await db.upsert_roundup_config(user_id, config)

    if not success:
        raise HTTPException(400, "Failed to update round-up config")

    return {"message": "Round-up configuration updated", "config": config}


@app.get("/api/v1/round-ups/summary")
async def get_roundup_summary(user_id: str = Depends(get_current_user)):
    """Get round-up savings summary"""
    summary = await db.get_roundup_summary(user_id)

    return {
        "total_saved": round(summary.get("total_saved", 0), 2),
        "pending_amount": round(summary.get("pending_amount", 0), 2),
        "this_month": round(summary.get("this_month", 0), 2),
        "transaction_count": summary.get("transaction_count", 0),
        "average_roundup": round(summary.get("average_roundup", 0), 2)
    }


@app.get("/api/v1/round-ups/pending")
async def get_pending_roundups(user_id: str = Depends(get_current_user)):
    """Get pending round-up transactions"""
    pending = await db.get_pending_roundups(user_id)

    return {
        "pending": pending,
        "total": round(sum(p.get("roundup_amount", 0) for p in pending), 2),
        "count": len(pending)
    }


class TransferRoundUpsRequest(BaseModel):
    goal_id: str


@app.post("/api/v1/round-ups/transfer")
async def transfer_roundups(
    request: TransferRoundUpsRequest,
    user_id: str = Depends(get_current_user)
):
    """Transfer pending round-ups to a goal"""
    amount = await db.transfer_roundups(user_id, request.goal_id)

    return {
        "message": "Round-ups transferred successfully",
        "amount_transferred": round(amount, 2),
        "goal_id": request.goal_id
    }


# ==================== FORECAST ENDPOINTS ====================

@app.get("/api/v1/forecast")
async def get_forecast(
    days: int = 30,
    user_id: str = Depends(get_current_user)
):
    """Get cash flow forecast"""
    # Get current balance
    balance_summary = await ShadowBankingService.get_balance_summary(user_id)
    current_balance = balance_summary.get("visible_balance", 0)

    # Get upcoming bills
    upcoming_bills = await BillDetector.calculate_upcoming_bills(user_id, days)

    # Get average income (look at last 90 days)
    start_date = datetime.now() - timedelta(days=90)
    transactions = await db.get_transactions(user_id, start_date=start_date, limit=500)

    # Calculate average monthly income
    income_txns = [t for t in transactions if t.get("amount", 0) > 0]
    total_income = sum(t.get("amount", 0) for t in income_txns)
    avg_monthly_income = (total_income / 3) if total_income > 0 else 0  # 3 months

    # Calculate average monthly expenses
    expense_txns = [t for t in transactions if t.get("amount", 0) < 0]
    total_expenses = abs(sum(t.get("amount", 0) for t in expense_txns))
    avg_monthly_expenses = (total_expenses / 3) if total_expenses > 0 else 0

    # Project balance
    days_in_month = 30
    daily_net = (avg_monthly_income - avg_monthly_expenses) / days_in_month
    projected_balance = current_balance + (daily_net * days)

    # Calculate risk level
    bills_total = upcoming_bills.get("total_amount", 0)
    buffer_needed = bills_total * 1.5

    if current_balance > buffer_needed * 2:
        risk_level = "low"
        risk_message = "You're in great shape! Plenty of buffer for upcoming bills."
    elif current_balance > buffer_needed:
        risk_level = "medium"
        risk_message = "You're okay, but consider building more buffer."
    else:
        risk_level = "high"
        risk_message = "Watch out! Upcoming bills may strain your balance."

    return {
        "current_balance": round(current_balance, 2),
        "projected_balance": round(projected_balance, 2),
        "days_forecast": days,
        "avg_monthly_income": round(avg_monthly_income, 2),
        "avg_monthly_expenses": round(avg_monthly_expenses, 2),
        "net_monthly": round(avg_monthly_income - avg_monthly_expenses, 2),
        "upcoming_bills": upcoming_bills,
        "risk_level": risk_level,
        "risk_message": risk_message,
        "runway_days": int(current_balance / (avg_monthly_expenses / 30)) if avg_monthly_expenses > 0 else 365
    }


@app.get("/api/v1/forecast/daily")
async def get_daily_projections(
    days: int = 14,
    user_id: str = Depends(get_current_user)
):
    """Get day-by-day balance projections"""
    # Get current balance
    balance_summary = await ShadowBankingService.get_balance_summary(user_id)
    current_balance = balance_summary.get("visible_balance", 0)

    # Get upcoming bills
    bills = await db.get_upcoming_bills(user_id, days=days)

    # Create daily projections
    projections = []
    running_balance = current_balance

    for day in range(days):
        date = datetime.now() + timedelta(days=day)
        date_str = date.strftime("%Y-%m-%d")

        # Find bills due on this day
        day_bills = [b for b in bills if b.get("next_due_date") and
                    b["next_due_date"].strftime("%Y-%m-%d") == date_str]

        bills_due = sum(b.get("amount", 0) for b in day_bills)
        running_balance -= bills_due

        projections.append({
            "date": date_str,
            "projected_balance": round(running_balance, 2),
            "bills_due": round(bills_due, 2),
            "bills": [{"merchant": b.get("merchant"), "amount": b.get("amount")} for b in day_bills],
            "is_low": running_balance < 100
        })

    return {
        "projections": projections,
        "lowest_point": min(p["projected_balance"] for p in projections),
        "lowest_date": min(projections, key=lambda p: p["projected_balance"])["date"]
    }


@app.get("/api/v1/forecast/alerts")
async def get_forecast_alerts(user_id: str = Depends(get_current_user)):
    """Get forecast-based alerts"""
    alerts = []

    # Get forecast data
    forecast = await get_forecast(days=30, user_id=user_id)

    # Check for low balance warning
    if forecast["projected_balance"] < 100:
        alerts.append({
            "type": "danger",
            "title": "Low Balance Warning",
            "message": f"Your balance is projected to drop to ${forecast['projected_balance']:.2f} in the next 30 days.",
            "action": "Review upcoming bills"
        })

    # Check for negative runway
    if forecast["runway_days"] < 30:
        alerts.append({
            "type": "warning",
            "title": "Limited Runway",
            "message": f"At current spending, your funds will last about {forecast['runway_days']} days.",
            "action": "Reduce spending or increase income"
        })

    # Check upcoming large bills
    upcoming = forecast.get("upcoming_bills", {})
    if upcoming.get("total_amount", 0) > forecast["current_balance"] * 0.5:
        alerts.append({
            "type": "info",
            "title": "Large Bills Coming",
            "message": f"${upcoming.get('total_amount', 0):.2f} in bills due soon - make sure you're prepared.",
            "action": "Review bill schedule"
        })

    # Positive alert if doing well
    if forecast["risk_level"] == "low" and forecast["net_monthly"] > 0:
        alerts.append({
            "type": "success",
            "title": "Looking Good!",
            "message": f"You're saving about ${forecast['net_monthly']:.2f}/month. Keep it up!",
            "action": None
        })

    return {
        "alerts": alerts,
        "risk_level": forecast["risk_level"]
    }


# ==================== SPENDING LIMITS ENDPOINTS ====================

class SpendingLimitRequest(BaseModel):
    category: str
    amount: float
    period: str = "monthly"  # daily, weekly, monthly
    notify_at: float = 0.8  # Notify at 80% by default


@app.get("/api/v1/spending-limits")
async def get_spending_limits(user_id: str = Depends(get_current_user)):
    """Get all spending limits"""
    limits = await db.get_spending_limits(user_id)

    # Check current spending for each limit
    for limit in limits:
        check = await db.check_spending_limit(user_id, limit["category"], limit["period"])
        limit["current_spent"] = check.get("current_spent", 0)
        limit["percent_used"] = check.get("percent_used", 0)
        limit["is_exceeded"] = check.get("is_exceeded", False)

    return {"limits": limits}


@app.post("/api/v1/spending-limits")
async def create_spending_limit(
    request: SpendingLimitRequest,
    user_id: str = Depends(get_current_user)
):
    """Create a new spending limit"""
    limit = {
        "category": request.category,
        "amount": request.amount,
        "period": request.period,
        "notify_at": request.notify_at
    }

    limit_id = await db.create_spending_limit(user_id, limit)

    return {
        "message": "Spending limit created",
        "limit_id": limit_id,
        "limit": limit
    }


@app.delete("/api/v1/spending-limits/{limit_id}")
async def delete_spending_limit(
    limit_id: str,
    user_id: str = Depends(get_current_user)
):
    """Delete a spending limit"""
    success = await db.delete_spending_limit(limit_id)

    if not success:
        raise HTTPException(400, "Failed to delete spending limit")

    return {"message": "Spending limit deleted"}


# ==================== WISHLIST ENDPOINTS ====================

class WishlistItemRequest(BaseModel):
    name: str
    price: float
    priority: int = 3  # 1-5
    url: Optional[str] = None
    notes: Optional[str] = None


@app.get("/api/v1/wishlist")
async def get_wishlist(user_id: str = Depends(get_current_user)):
    """Get user's wishlist"""
    items = await db.get_wishlist(user_id)

    total_cost = sum(i.get("price", 0) for i in items if not i.get("is_purchased"))

    return {
        "items": items,
        "total_cost": round(total_cost, 2),
        "count": len([i for i in items if not i.get("is_purchased")])
    }


@app.post("/api/v1/wishlist")
async def add_wishlist_item(
    request: WishlistItemRequest,
    user_id: str = Depends(get_current_user)
):
    """Add item to wishlist"""
    item = {
        "name": request.name,
        "price": request.price,
        "priority": request.priority,
        "url": request.url,
        "notes": request.notes
    }

    item_id = await db.create_wishlist_item(user_id, item)

    return {
        "message": "Item added to wishlist",
        "item_id": item_id,
        "item": item
    }


@app.patch("/api/v1/wishlist/{item_id}")
async def update_wishlist_item(
    item_id: str,
    updates: Dict[str, Any],
    user_id: str = Depends(get_current_user)
):
    """Update wishlist item"""
    success = await db.update_wishlist_item(item_id, updates)

    if not success:
        raise HTTPException(400, "Failed to update item")

    return {"message": "Item updated"}


@app.delete("/api/v1/wishlist/{item_id}")
async def delete_wishlist_item(
    item_id: str,
    user_id: str = Depends(get_current_user)
):
    """Delete wishlist item"""
    success = await db.delete_wishlist_item(item_id)

    if not success:
        raise HTTPException(400, "Failed to delete item")

    return {"message": "Item deleted"}


@app.post("/api/v1/wishlist/{item_id}/purchased")
async def mark_wishlist_purchased(
    item_id: str,
    user_id: str = Depends(get_current_user)
):
    """Mark wishlist item as purchased"""
    success = await db.mark_wishlist_purchased(item_id)

    if not success:
        raise HTTPException(400, "Failed to update item")

    return {"message": "Item marked as purchased"}


# ==================== ACHIEVEMENTS ENDPOINTS ====================

@app.get("/api/v1/achievements")
async def get_achievements(user_id: str = Depends(get_current_user)):
    """Get user's achievements and progress"""
    # Get user stats for achievement calculation
    goals = await db.get_goals(user_id)
    transactions = await db.get_transactions(user_id, limit=1000)
    balance_summary = await ShadowBankingService.get_balance_summary(user_id)

    # Calculate achievements
    achievements = []

    # Goal achievements
    completed_goals = [g for g in goals if g.get("current_amount", 0) >= g.get("target_amount", 1)]
    if len(completed_goals) >= 1:
        achievements.append({
            "id": "first_goal",
            "name": "Goal Getter",
            "description": "Complete your first savings goal",
            "icon": "🎯",
            "earned": True,
            "earned_date": completed_goals[0].get("completed_at")
        })

    if len(completed_goals) >= 5:
        achievements.append({
            "id": "goal_master",
            "name": "Goal Master",
            "description": "Complete 5 savings goals",
            "icon": "🏆",
            "earned": True
        })

    # Savings achievements
    hidden_balance = balance_summary.get("hidden_balance", 0)
    if hidden_balance >= 100:
        achievements.append({
            "id": "secret_stash",
            "name": "Secret Stash",
            "description": "Hide $100 in shadow savings",
            "icon": "🤫",
            "earned": True
        })

    if hidden_balance >= 1000:
        achievements.append({
            "id": "hidden_treasure",
            "name": "Hidden Treasure",
            "description": "Hide $1,000 in shadow savings",
            "icon": "💎",
            "earned": True
        })

    # Transaction achievements
    if len(transactions) >= 100:
        achievements.append({
            "id": "tracker",
            "name": "Transaction Tracker",
            "description": "Track 100 transactions",
            "icon": "📊",
            "earned": True
        })

    # Streak achievements (simplified)
    achievements.append({
        "id": "consistent",
        "name": "Consistency King",
        "description": "Use FURG for 7 days in a row",
        "icon": "👑",
        "earned": True  # Simplified for demo
    })

    # Available (not yet earned) achievements
    if hidden_balance < 100:
        achievements.append({
            "id": "secret_stash",
            "name": "Secret Stash",
            "description": "Hide $100 in shadow savings",
            "icon": "🤫",
            "earned": False,
            "progress": min(hidden_balance / 100 * 100, 99)
        })

    return {
        "achievements": achievements,
        "total_earned": len([a for a in achievements if a.get("earned")]),
        "total_available": len(achievements)
    }


# ==================== MAIN ====================

if __name__ == "__main__":
    import uvicorn

    port = int(os.getenv("PORT", 8000))

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=os.getenv("DEBUG", "false").lower() == "true",
        log_level="info"
    )
