"""
ML-based transaction categorization with Claude fallback
"""

import os
from typing import Tuple, Dict, Any
from datetime import datetime
import anthropic

from database import db


# Categories for classification
CATEGORIES = [
    "Food & Dining",
    "Transportation",
    "Entertainment",
    "Bills & Utilities",
    "Shopping",
    "Health & Fitness",
    "Travel",
    "Income",
    "Transfer",
    "Other"
]


class TransactionCategorizer:
    """
    Transaction categorization using Claude AI

    In a production system with more data, this would use a trained ML model
    with Claude as fallback. For now, uses Claude directly for accuracy.
    """

    def __init__(self):
        self.client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))

    async def categorize(self, transaction: Dict[str, Any], user_context: str = "") -> Tuple[str, float]:
        """
        Categorize a transaction

        Args:
            transaction: Transaction dict with merchant, amount, date, etc.
            user_context: Optional context about user's spending patterns

        Returns:
            Tuple of (category, confidence)
        """
        # Try simple rule-based first for common cases
        if simple_category := self._try_simple_rules(transaction):
            return simple_category, 0.95

        # Use Claude for unclear cases
        return await self._categorize_with_claude(transaction, user_context)

    def _try_simple_rules(self, txn: Dict[str, Any]) -> str:
        """
        Try simple rule-based categorization for obvious cases

        Returns:
            Category string or None if unclear
        """
        merchant = txn["merchant"].lower()
        amount = float(txn.get("amount", 0))

        # Income (positive amounts)
        if amount > 0:
            if any(word in merchant for word in ["payroll", "salary", "deposit", "direct dep"]):
                return "Income"
            if "transfer" in merchant or "venmo" in merchant or "zelle" in merchant:
                return "Transfer"

        # Bills & Utilities
        if any(word in merchant for word in [
            "electric", "power", "utility", "internet", "verizon", "at&t",
            "tmobile", "sprint", "insurance", "rent", "mortgage", "loan"
        ]):
            return "Bills & Utilities"

        # Food
        if any(word in merchant for word in [
            "restaurant", "cafe", "coffee", "starbucks", "mcdonald",
            "burger", "pizza", "food", "grocery", "whole foods", "trader joe",
            "safeway", "kroger", "publix", "chipotle", "subway"
        ]):
            return "Food & Dining"

        # Transportation
        if any(word in merchant for word in [
            "uber", "lyft", "taxi", "shell", "chevron", "exxon", "bp",
            "gas", "parking", "transit", "metro", "bart"
        ]):
            return "Transportation"

        # Entertainment
        if any(word in merchant for word in [
            "netflix", "spotify", "hulu", "disney", "amazon prime",
            "youtube", "movie", "theater", "cinema", "concert", "tickets"
        ]):
            return "Entertainment"

        # Health & Fitness
        if any(word in merchant for word in [
            "gym", "fitness", "yoga", "pharmacy", "cvs", "walgreens",
            "hospital", "doctor", "dental", "medical"
        ]):
            return "Health & Fitness"

        # Travel
        if any(word in merchant for word in [
            "airline", "hotel", "airbnb", "booking", "expedia",
            "tsa", "airport"
        ]):
            return "Travel"

        return None

    async def _categorize_with_claude(
        self,
        transaction: Dict[str, Any],
        user_context: str = ""
    ) -> Tuple[str, float]:
        """
        Categorize using Claude API

        Args:
            transaction: Transaction dict
            user_context: User spending patterns

        Returns:
            Tuple of (category, confidence)
        """
        merchant = transaction["merchant"]
        amount = abs(float(transaction["amount"]))
        date = transaction.get("date", datetime.now())
        time_str = date.strftime("%I:%M %p, %A") if isinstance(date, datetime) else "unknown time"

        prompt = f"""Categorize this transaction into ONE of these categories:

{', '.join(CATEGORIES)}

Transaction:
- Merchant: {merchant}
- Amount: ${amount:.2f}
- Time: {time_str}
"""

        if user_context:
            prompt += f"\nUser context: {user_context}"

        prompt += """

Respond with ONLY the category name, nothing else. Be precise."""

        try:
            response = self.client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=50,
                messages=[{"role": "user", "content": prompt}]
            )

            category = response.content[0].text.strip()

            # Validate category
            if category not in CATEGORIES:
                # Try to find closest match
                category = self._find_closest_category(category)

            return category, 0.85

        except Exception as e:
            print(f"Claude categorization failed: {e}")
            return "Other", 0.3

    def _find_closest_category(self, text: str) -> str:
        """Find closest matching category from Claude's response"""
        text_lower = text.lower()

        for category in CATEGORIES:
            if category.lower() in text_lower or text_lower in category.lower():
                return category

        return "Other"

    async def learn_from_correction(
        self,
        transaction: Dict[str, Any],
        correct_category: str
    ) -> None:
        """
        Learn from user corrections

        In production, this would retrain the ML model.
        For now, it saves training examples for future model training.

        Args:
            transaction: Transaction dict
            correct_category: User-corrected category
        """
        # Save as training example
        user_id = transaction.get("user_id")
        if user_id:
            await db.save_training_example(
                user_id=user_id,
                transaction_data=transaction,
                correct_category=correct_category
            )

    async def batch_categorize(
        self,
        transactions: list,
        user_context: str = ""
    ) -> list:
        """
        Categorize multiple transactions efficiently

        Args:
            transactions: List of transaction dicts
            user_context: User context

        Returns:
            List of (category, confidence) tuples
        """
        results = []

        for txn in transactions:
            category, confidence = await self.categorize(txn, user_context)
            results.append((category, confidence))

        return results

    def get_category_emoji(self, category: str) -> str:
        """Get emoji for category (for fun UI)"""
        emoji_map = {
            "Food & Dining": "🍔",
            "Transportation": "🚗",
            "Entertainment": "🎬",
            "Bills & Utilities": "📋",
            "Shopping": "🛍️",
            "Health & Fitness": "💪",
            "Travel": "✈️",
            "Income": "💰",
            "Transfer": "💸",
            "Other": "📦"
        }
        return emoji_map.get(category, "❓")


# Singleton instance
_categorizer = None


def get_categorizer() -> TransactionCategorizer:
    """Get or create categorizer instance"""
    global _categorizer
    if _categorizer is None:
        _categorizer = TransactionCategorizer()
    return _categorizer
