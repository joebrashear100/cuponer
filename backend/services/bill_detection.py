"""
Bill detection service for FURG
Intelligently detects recurring bills from transaction history
"""

from datetime import datetime, timedelta
from collections import defaultdict
from typing import List, Dict, Any, Optional
import statistics

from database import db


# Merchant categories that typically indicate bills
BILL_CATEGORIES = {
    "LOAN_PAYMENTS_CAR_PAYMENT",
    "LOAN_PAYMENTS_STUDENT_LOAN_PAYMENT",
    "LOAN_PAYMENTS_MORTGAGE",
    "LOAN_PAYMENTS_PERSONAL_LOAN_PAYMENT",
    "RENT_AND_UTILITIES_GAS_AND_ELECTRICITY",
    "RENT_AND_UTILITIES_INTERNET_AND_CABLE",
    "RENT_AND_UTILITIES_RENT",
    "RENT_AND_UTILITIES_SEWAGE_AND_WASTE_MANAGEMENT",
    "RENT_AND_UTILITIES_WATER",
    "RENT_AND_UTILITIES_TELEPHONE",
    "GENERAL_SERVICES_INSURANCE",
    "MEDICAL_HEALTH_INSURANCE",
}

# Subscription keywords in merchant names
SUBSCRIPTION_KEYWORDS = [
    "netflix", "spotify", "hulu", "disney", "amazon prime",
    "apple music", "youtube", "gym", "fitness", "subscription",
    "membership", "phone", "internet", "insurance", "loan"
]


class BillDetector:
    """Intelligent bill detection from transaction patterns"""

    @staticmethod
    async def detect_bills(user_id: str, days_lookback: int = 90) -> List[Dict[str, Any]]:
        """
        Detect bills from transaction history

        Args:
            user_id: User UUID
            days_lookback: How many days of history to analyze

        Returns:
            List of detected bills
        """
        # Get transaction history
        start_date = datetime.now() - timedelta(days=days_lookback)
        transactions = await db.get_transactions(
            user_id=user_id,
            start_date=start_date,
            end_date=datetime.now(),
            limit=1000
        )

        # Group by merchant
        by_merchant = defaultdict(list)
        for txn in transactions:
            # Only consider negative amounts (expenses)
            if txn["amount"] < 0:
                merchant = txn["merchant"].lower().strip()
                by_merchant[merchant].append(txn)

        bills = []

        for merchant, txns in by_merchant.items():
            # Need at least 2 occurrences to detect pattern
            if len(txns) < 2:
                continue

            bill_data = BillDetector._analyze_merchant_pattern(merchant, txns)

            if bill_data and bill_data["confidence"] > 0.5:
                bills.append(bill_data)

        # Save detected bills to database
        for bill in bills:
            await db.upsert_bill(user_id, bill)

        return bills

    @staticmethod
    def _analyze_merchant_pattern(merchant: str, transactions: List[Dict]) -> Optional[Dict[str, Any]]:
        """
        Analyze transactions for a single merchant to detect bill pattern

        Args:
            merchant: Merchant name
            transactions: List of transactions for this merchant

        Returns:
            Bill data dict or None if not a bill
        """
        # Sort by date
        transactions = sorted(transactions, key=lambda x: x["date"])

        # Analyze amount consistency
        amounts = [abs(float(txn["amount"])) for txn in transactions]
        avg_amount = statistics.mean(amounts)

        if len(amounts) > 1:
            std_dev = statistics.stdev(amounts)
            coefficient_of_variation = std_dev / avg_amount if avg_amount > 0 else 1
        else:
            coefficient_of_variation = 0

        # Analyze frequency
        dates = [txn["date"] for txn in transactions]
        intervals = []
        for i in range(1, len(dates)):
            interval = (dates[i] - dates[i-1]).days
            intervals.append(interval)

        if not intervals:
            return None

        avg_interval = statistics.mean(intervals)

        # Check merchant category
        category = transactions[0].get("merchant_category_code", "")
        is_bill_category = any(bill_cat in category for bill_cat in BILL_CATEGORIES)

        # Check for subscription keywords
        is_subscription = any(keyword in merchant.lower() for keyword in SUBSCRIPTION_KEYWORDS)

        # Scoring logic
        is_bill = False
        confidence = 0.0

        # High confidence if category matches
        if is_bill_category:
            is_bill = True
            confidence = 0.9
            bill_type = "bill"

        # Medium-high confidence for subscriptions with consistent amounts
        elif is_subscription and coefficient_of_variation < 0.15:
            is_bill = True
            confidence = 0.8
            bill_type = "subscription"

        # Medium confidence if amount and frequency very consistent
        elif coefficient_of_variation < 0.05 and BillDetector._is_regular_interval(avg_interval):
            is_bill = True
            confidence = 0.75
            bill_type = "recurring"

        # Lower confidence for somewhat regular patterns
        elif coefficient_of_variation < 0.15 and BillDetector._is_regular_interval(avg_interval):
            is_bill = True
            confidence = 0.6
            bill_type = "recurring"

        if not is_bill:
            return None

        # Predict next occurrence
        last_date = dates[-1]
        frequency_days = int(round(avg_interval))
        next_due = last_date + timedelta(days=frequency_days)

        return {
            "merchant": transactions[0]["merchant"],  # Use original case
            "amount": round(avg_amount, 2),
            "frequency_days": frequency_days,
            "next_due_date": next_due.date(),
            "confidence": round(confidence, 2),
            "category": BillDetector._categorize_bill(category, merchant),
            "bill_type": bill_type,
            "occurrences": len(transactions),
            "amount_variance": round(coefficient_of_variation, 2)
        }

    @staticmethod
    def _is_regular_interval(days: float) -> bool:
        """Check if interval matches common billing cycles"""
        # Weekly (7 days ±1)
        if 6 <= days <= 8:
            return True
        # Bi-weekly (14 days ±2)
        if 12 <= days <= 16:
            return True
        # Monthly (30 days ±3)
        if 27 <= days <= 33:
            return True
        # Bi-monthly (60 days ±5)
        if 55 <= days <= 65:
            return True
        # Quarterly (90 days ±7)
        if 83 <= days <= 97:
            return True
        # Semi-annual (180 days ±10)
        if 170 <= days <= 190:
            return True
        # Annual (365 days ±15)
        if 350 <= days <= 380:
            return True

        return False

    @staticmethod
    def _categorize_bill(plaid_category: str, merchant: str) -> str:
        """Categorize bill type"""
        merchant_lower = merchant.lower()

        if any(word in plaid_category.lower() for word in ["rent", "mortgage"]):
            return "Housing"
        if any(word in plaid_category.lower() for word in ["utilities", "gas", "electric", "water"]):
            return "Utilities"
        if "insurance" in plaid_category.lower() or "insurance" in merchant_lower:
            return "Insurance"
        if "loan" in plaid_category.lower() or "loan" in merchant_lower:
            return "Loan"
        if any(word in merchant_lower for word in ["phone", "internet", "cable", "mobile"]):
            return "Utilities"
        if any(word in merchant_lower for word in ["gym", "fitness"]):
            return "Fitness"
        if any(word in merchant_lower for word in ["netflix", "spotify", "hulu", "disney", "prime"]):
            return "Entertainment"

        return "Other"

    @staticmethod
    async def calculate_upcoming_bills(user_id: str, days: int = 30) -> Dict[str, Any]:
        """
        Calculate total bills due in next N days

        Args:
            user_id: User UUID
            days: Number of days to look ahead

        Returns:
            Dict with total and breakdown
        """
        bills = await db.get_upcoming_bills(user_id, days)

        total = sum(bill["amount"] for bill in bills)

        # Group by category
        by_category = defaultdict(float)
        for bill in bills:
            category = bill.get("category", "Other")
            by_category[category] += bill["amount"]

        return {
            "total": round(total, 2),
            "count": len(bills),
            "by_category": dict(by_category),
            "bills": [
                {
                    "merchant": bill["merchant"],
                    "amount": bill["amount"],
                    "due_date": bill["next_due_date"].isoformat() if hasattr(bill["next_due_date"], "isoformat") else str(bill["next_due_date"]),
                    "category": bill.get("category", "Other")
                }
                for bill in bills
            ]
        }

    @staticmethod
    async def get_safety_buffer(user_id: str) -> float:
        """
        Calculate minimum safety buffer (2× upcoming bills + emergency fund)

        Args:
            user_id: User UUID

        Returns:
            Minimum balance to maintain
        """
        # Get upcoming bills (next 30 days)
        upcoming_total = await db.calculate_upcoming_bills_total(user_id, 30)

        # Get user's emergency buffer setting
        profile = await db.get_user_profile(user_id)
        emergency_buffer = float(profile.get("emergency_buffer", 500)) if profile else 500

        # Safety = 2× bills + emergency buffer
        safety_buffer = (upcoming_total * 2) + emergency_buffer

        return round(safety_buffer, 2)

    @staticmethod
    async def can_hide_money(user_id: str, amount: float) -> Dict[str, Any]:
        """
        Check if user can safely hide money without risking bill payments

        Args:
            user_id: User UUID
            amount: Amount to hide

        Returns:
            Dict with can_hide bool and reasoning
        """
        # Get current balance from Plaid
        from services.plaid_service import PlaidService
        balance = await PlaidService.get_total_balance(user_id)

        # Get safety buffer
        safety_buffer = await BillDetector.get_safety_buffer(user_id)

        # Get currently hidden amount
        hidden = await db.get_total_hidden(user_id)

        # Calculate available after hiding
        available_after = balance - hidden - amount

        can_hide = available_after >= safety_buffer

        return {
            "can_hide": can_hide,
            "current_balance": round(balance, 2),
            "already_hidden": round(hidden, 2),
            "safety_buffer": round(safety_buffer, 2),
            "available_after": round(available_after, 2),
            "shortfall": round(max(0, safety_buffer - available_after), 2),
            "reasoning": BillDetector._get_hide_reasoning(can_hide, available_after, safety_buffer)
        }

    @staticmethod
    def _get_hide_reasoning(can_hide: bool, available: float, buffer: float) -> str:
        """Generate explanation for hide decision"""
        if can_hide:
            excess = available - buffer
            return f"✅ Safe to hide. You'll have ${available:.2f} left, ${excess:.2f} above your safety buffer."
        else:
            shortfall = buffer - available
            return f"❌ Can't hide that much. You'd have ${available:.2f} left, but need ${buffer:.2f}. Short by ${shortfall:.2f}."
