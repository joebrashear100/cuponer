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
from services.chat import ChatService
from services.plaid_service import PlaidService
from services.bill_detection import BillDetector
from services.shadow_banking import ShadowBankingService
from ml.categorizer import get_categorizer


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("🚀 Starting FURG backend...")
    await db.connect()
    print("✅ Database connected")
    yield
    # Shutdown
    print("👋 Shutting down FURG backend...")
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

    Handles conversation with full context
    """
    # Check for special commands first
    command_response = await ChatService.handle_command(user_id, request.message)
    if command_response:
        await db.save_message(user_id, "user", request.message)
        await db.save_message(user_id, "assistant", command_response)
        return ChatResponse(message=command_response)

    # Get user profile
    profile = await db.get_user_profile(user_id)

    # Build context if requested
    context = None
    if request.include_context:
        context = await _build_chat_context(user_id)

    # Get response from ChatService
    response = await ChatService.chat(user_id, request.message, profile, context)

    return ChatResponse(
        message=response["message"],
        tokens_used=response.get("tokens_used")
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
