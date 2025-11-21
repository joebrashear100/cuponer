"""
Shadow banking service for FURG
Handles hiding money from users for forced savings
"""

from typing import Dict, Any, Optional
from datetime import datetime, timedelta

from database import db
from services.bill_detection import BillDetector


class ShadowBankingService:
    """Service for managing hidden savings accounts"""

    @staticmethod
    async def hide_money(
        user_id: str,
        amount: float,
        purpose: str = "forced_savings"
    ) -> Dict[str, Any]:
        """
        Hide money from user's visible balance

        Args:
            user_id: User UUID
            amount: Amount to hide
            purpose: Purpose of hiding (forced_savings, savings_goal, emergency)

        Returns:
            Dict with result and reasoning
        """
        # Check if safe to hide
        safety_check = await BillDetector.can_hide_money(user_id, amount)

        if not safety_check["can_hide"]:
            return {
                "success": False,
                "reason": safety_check["reasoning"],
                "shortfall": safety_check["shortfall"]
            }

        # Create shadow account
        account_id = await db.create_shadow_account(
            user_id=user_id,
            balance=amount,
            purpose=purpose
        )

        # Get new totals
        total_hidden = await db.get_total_hidden(user_id)

        return {
            "success": True,
            "account_id": account_id,
            "hidden_amount": amount,
            "total_hidden": total_hidden,
            "message": f"Hidden ${amount:.2f}. You're broke now. But future you is ${total_hidden:.2f} richer."
        }

    @staticmethod
    async def reveal_money(
        user_id: str,
        amount: Optional[float] = None,
        account_id: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Reveal hidden money back to user

        Args:
            user_id: User UUID
            amount: Amount to reveal (if None, reveal all)
            account_id: Specific account to reveal from

        Returns:
            Dict with result
        """
        accounts = await db.get_shadow_accounts(user_id)

        if not accounts:
            return {
                "success": False,
                "message": "No hidden money. You spent it all, remember?"
            }

        if account_id:
            # Reveal specific account
            account = next((a for a in accounts if str(a["id"]) == account_id), None)
            if not account:
                return {"success": False, "message": "Account not found"}

            revealed = account["balance"]
            await db.update_shadow_balance(account_id, 0)

        elif amount:
            # Reveal specific amount from newest account
            account = accounts[-1]
            if account["balance"] < amount:
                return {
                    "success": False,
                    "message": f"You only have ${account['balance']:.2f} hidden."
                }

            new_balance = account["balance"] - amount
            await db.update_shadow_balance(account["id"], new_balance)
            revealed = amount

        else:
            # Reveal all
            revealed = sum(a["balance"] for a in accounts)
            for account in accounts:
                await db.update_shadow_balance(account["id"], 0)

        total_hidden = await db.get_total_hidden(user_id)

        return {
            "success": True,
            "revealed_amount": revealed,
            "remaining_hidden": total_hidden,
            "message": f"Revealed ${revealed:.2f}. Try not to waste it this time."
        }

    @staticmethod
    async def get_balance_summary(user_id: str) -> Dict[str, Any]:
        """
        Get user's balance summary (visible + hidden)

        Args:
            user_id: User UUID

        Returns:
            Dict with balance breakdown
        """
        from services.plaid_service import PlaidService

        # Get real balance from Plaid
        total_balance = await PlaidService.get_total_balance(user_id)

        # Get hidden balance
        hidden = await db.get_total_hidden(user_id)

        # Get safety buffer
        safety_buffer = await BillDetector.get_safety_buffer(user_id)

        # Calculate visible balance
        visible = total_balance - hidden

        # Calculate truly available (after safety buffer)
        available = max(0, visible - safety_buffer)

        return {
            "total_balance": round(total_balance, 2),
            "visible_balance": round(visible, 2),
            "hidden_balance": round(hidden, 2),
            "safety_buffer": round(safety_buffer, 2),
            "truly_available": round(available, 2),
            "hidden_accounts": await db.get_shadow_accounts(user_id)
        }

    @staticmethod
    async def auto_hide_for_goal(
        user_id: str,
        goal_amount: float,
        goal_deadline: str,
        frequency: str = "weekly"
    ) -> Dict[str, Any]:
        """
        Set up automatic hiding to reach savings goal

        Args:
            user_id: User UUID
            goal_amount: Target amount to save
            goal_deadline: Deadline (YYYY-MM-DD)
            frequency: How often to hide (weekly, biweekly, monthly)

        Returns:
            Dict with auto-save plan
        """
        # Calculate time until deadline
        deadline = datetime.strptime(goal_deadline, "%Y-%m-%d")
        days_until = (deadline - datetime.now()).days

        if days_until <= 0:
            return {
                "success": False,
                "message": "Deadline is in the past. Unless you have a time machine?"
            }

        # Calculate required savings per period
        periods_map = {
            "weekly": 7,
            "biweekly": 14,
            "monthly": 30
        }

        days_per_period = periods_map.get(frequency, 7)
        periods_remaining = days_until / days_per_period
        amount_per_period = goal_amount / periods_remaining

        # Update profile with goal
        await db.update_user_profile(user_id, {
            "savings_goal": {
                "amount": goal_amount,
                "deadline": goal_deadline,
                "frequency": frequency,
                "amount_per_period": round(amount_per_period, 2)
            }
        })

        return {
            "success": True,
            "goal_amount": goal_amount,
            "deadline": goal_deadline,
            "frequency": frequency,
            "amount_per_period": round(amount_per_period, 2),
            "periods_remaining": int(periods_remaining),
            "message": f"Auto-save activated: ${amount_per_period:.2f} {frequency}. {int(periods_remaining)} times until {goal_deadline}."
        }

    @staticmethod
    async def check_auto_hide_due(user_id: str) -> bool:
        """
        Check if auto-hide is due and execute if safe

        Args:
            user_id: User UUID

        Returns:
            True if auto-hide executed
        """
        profile = await db.get_user_profile(user_id)
        if not profile or not profile.get("savings_goal"):
            return False

        goal = profile["savings_goal"]
        amount = goal.get("amount_per_period")

        if not amount:
            return False

        # Check if we can hide safely
        safety_check = await BillDetector.can_hide_money(user_id, amount)

        if safety_check["can_hide"]:
            result = await ShadowBankingService.hide_money(
                user_id,
                amount,
                purpose="savings_goal"
            )
            return result["success"]

        return False

    @staticmethod
    def generate_reveal_message(days_until_goal: int) -> str:
        """Generate personality-driven reveal message"""
        if days_until_goal <= 0:
            return "🎉 Goal reached! Here's your money. Don't waste it now."
        elif days_until_goal <= 30:
            return f"Close! {days_until_goal} days to go. Keep your hands off this."
        elif days_until_goal <= 90:
            return f"{days_until_goal} days left. Patience is a virtue you're learning."
        else:
            return f"{days_until_goal} days out. Your hidden stash is safe... from you."
