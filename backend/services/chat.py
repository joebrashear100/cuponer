"""
Chat service for FURG
Handles conversation with Claude API and maintains roasting personality
"""

import os
from typing import List, Dict, Any, Optional
from datetime import datetime
import anthropic

from database import db
from rate_limiter import APIUsageTracker, truncate_to_budget


# Initialize Claude client
client = anthropic.Anthropic(api_key=os.getenv("ANTHROPIC_API_KEY"))


class ChatService:
    """Service for handling chat conversations with FURG personality"""

    @staticmethod
    def build_system_prompt(
        profile: Optional[Dict[str, Any]] = None,
        context: Optional[Dict[str, Any]] = None
    ) -> str:
        """
        Build system prompt with FURG's personality and user context

        Args:
            profile: User profile data
            context: Additional context (recent transactions, bills, etc.)

        Returns:
            System prompt string
        """
        # Base personality
        prompt = """You are FURG, a financial AI assistant with a roasting personality.

Your core traits:
- BRUTALLY HONEST about bad spending decisions
- Mock users to motivate them (but with love)
- Celebrate good financial choices
- Always protect bills and safety buffer
- Chat-first: everything configured through conversation, NO UI controls
- Use casual language, be witty and sharp

Examples of your personality:
- Bad spending: "Joe, $47 Uber at 2am? You couldn't wait 4 hours for the train? That's rent money."
- Good decision: "14 days no takeout. Holy shit Joe, who are you? Keep this up."
- Pattern detection: "Every Sunday you drop $200+. Brunch crew bankrupting you?"

Core rules:
1. NEVER let users spend bill money - always keep 2× upcoming bills + emergency buffer safe
2. Be specific with numbers and dates when discussing money
3. Learn from every conversation to improve future advice
4. Roast proportionally - bigger mistakes get bigger roasts
5. Keep responses short and punchy (2-3 sentences max usually)

"""

        # Add user profile context
        if profile:
            prompt += "\n## User Profile\n"

            if profile.get("name"):
                prompt += f"Name: {profile['name']}\n"

            if profile.get("location"):
                prompt += f"Location: {profile['location']}\n"

            if profile.get("employer"):
                prompt += f"Employer: {profile['employer']}\n"

            if profile.get("salary"):
                prompt += f"Salary: ${profile['salary']:,.2f}/year\n"

            if profile.get("savings_goal"):
                goal = profile["savings_goal"]
                prompt += f"Savings goal: ${goal.get('amount', 0):,.0f} by {goal.get('deadline', 'TBD')} for {goal.get('purpose', 'unspecified')}\n"

            if profile.get("intensity_mode"):
                mode = profile["intensity_mode"]
                if mode == "insanity":
                    prompt += "Intensity: INSANITY MODE - Maximum roasting, no mercy\n"
                elif mode == "moderate":
                    prompt += "Intensity: Moderate - Balanced roasting and encouragement\n"
                elif mode == "mild":
                    prompt += "Intensity: Mild - Gentle nudges, minimal roasting\n"

            if profile.get("learned_insights"):
                prompt += f"\nLearned insights about user:\n"
                for insight in profile["learned_insights"][:5]:  # Limit to most recent 5
                    prompt += f"- {insight}\n"

        # Add real-time context
        if context:
            prompt += "\n## Current Context\n"

            if context.get("balance"):
                prompt += f"Current balance: ${context['balance']:,.2f}\n"

            if context.get("hidden_balance"):
                prompt += f"Hidden balance: ${context['hidden_balance']:,.2f}\n"

            if context.get("upcoming_bills"):
                bills = context["upcoming_bills"]
                prompt += f"Upcoming bills (30 days): ${bills.get('total', 0):,.2f}\n"

            if context.get("recent_transactions"):
                prompt += f"\nRecent transactions (last 7 days):\n"
                for txn in context["recent_transactions"][:10]:
                    date = txn.get('date', '')
                    if isinstance(date, datetime):
                        date = date.strftime("%m/%d")
                    prompt += f"- {date}: ${abs(txn.get('amount', 0)):.2f} at {txn.get('merchant', 'Unknown')}\n"

            if context.get("spending_by_category"):
                prompt += f"\nSpending this month by category:\n"
                for cat, amount in context["spending_by_category"].items():
                    prompt += f"- {cat}: ${amount:.2f}\n"

        prompt += """
Remember: Your goal is to help users save money through tough love and smart protection of their financial safety."""

        return prompt

    @staticmethod
    async def chat(
        user_id: str,
        message: str,
        profile: Optional[Dict[str, Any]] = None,
        context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Process a chat message and get FURG's response

        Args:
            user_id: User UUID
            message: User's message
            profile: User profile
            context: Additional context

        Returns:
            Dict with response and metadata
        """
        # Load conversation history
        history = await db.get_conversation_history(user_id, limit=50)

        # Build messages for Claude
        messages = []
        for msg in history:
            messages.append({
                "role": msg["role"],
                "content": msg["content"]
            })

        # Add current message
        messages.append({
            "role": "user",
            "content": message
        })

        # Truncate to fit budget
        messages = truncate_to_budget(messages, max_tokens=8000)

        # Build system prompt
        system_prompt = ChatService.build_system_prompt(profile, context)

        # Call Claude with usage tracking
        async with APIUsageTracker(user_id, "chat") as tracker:
            try:
                response = client.messages.create(
                    model="claude-sonnet-4-20250514",
                    max_tokens=2000,
                    system=system_prompt,
                    messages=messages
                )

                response_text = response.content[0].text

                # Track usage
                tracker.record(
                    response.usage.input_tokens,
                    response.usage.output_tokens
                )

                # Save messages to database
                await db.save_message(user_id, "user", message)
                await db.save_message(user_id, "assistant", response_text)

                return {
                    "message": response_text,
                    "tokens_used": {
                        "input": response.usage.input_tokens,
                        "output": response.usage.output_tokens
                    }
                }

            except anthropic.APIError as e:
                print(f"Claude API error: {e}")
                # Fallback response
                fallback = "Whoa, my roasting circuits are overloaded. Try again in a sec."
                await db.save_message(user_id, "user", message)
                await db.save_message(user_id, "assistant", fallback)

                return {
                    "message": fallback,
                    "error": str(e)
                }

    @staticmethod
    def generate_roast(transaction: Dict[str, Any], user_profile: Optional[Dict] = None) -> str:
        """
        Generate a roast for a specific transaction

        Args:
            transaction: Transaction dict
            user_profile: User profile for context

        Returns:
            Roast string
        """
        amount = abs(float(transaction.get("amount", 0)))
        merchant = transaction.get("merchant", "Unknown")
        date = transaction.get("date", datetime.now())
        category = transaction.get("category", "")

        # Time-based roasts
        if isinstance(date, datetime):
            hour = date.hour

            if hour >= 22 or hour <= 4:
                return f"${amount:.2f} at {merchant} at {hour}:00? Drunk shopping or just bad decisions?"

            if hour >= 11 and hour <= 13 and "restaurant" in category.lower():
                return f"${amount:.2f} lunch? Your kitchen must be decorative."

        # Amount-based roasts
        if "uber" in merchant.lower() or "lyft" in merchant.lower():
            if amount > 30:
                return f"${amount:.2f} Uber? That's like a week of groceries for a 15min ride, genius."

        if "coffee" in merchant.lower() or "starbucks" in merchant.lower():
            return f"${amount:.2f} on coffee? Your retirement fund called, it's jealous."

        if amount > 100 and category == "Entertainment":
            return f"${amount:.2f} on entertainment? At least you're entertaining your bank account... by emptying it."

        # Default praise for reasonable spending
        if amount < 20:
            return "Reasonable purchase. Shocking."

        return f"${amount:.2f} at {merchant}. Could be worse, I guess."

    @staticmethod
    async def handle_command(user_id: str, message: str) -> Optional[str]:
        """
        Handle special commands (intensity mode, buffer settings, etc.)

        Args:
            user_id: User UUID
            message: User message

        Returns:
            Command response or None if not a command
        """
        message_lower = message.lower()

        # Set intensity mode
        if "set intensity" in message_lower or "intensity mode" in message_lower:
            if "insanity" in message_lower:
                await db.update_user_profile(user_id, {"intensity_mode": "insanity"})
                return "Insanity mode activated. Hope you like being broke-but-rich. No mercy from now on."
            elif "mild" in message_lower:
                await db.update_user_profile(user_id, {"intensity_mode": "mild"})
                return "Mild mode set. I'll be gentle. (But you'll still hear about that $47 Uber.)"
            elif "moderate" in message_lower:
                await db.update_user_profile(user_id, {"intensity_mode": "moderate"})
                return "Moderate mode locked in. Balanced roasting incoming."

        # Set emergency buffer
        if "emergency buffer" in message_lower or "safety buffer" in message_lower:
            import re
            amounts = re.findall(r'\$?(\d+(?:,\d{3})*(?:\.\d{2})?)', message)
            if amounts:
                amount = float(amounts[0].replace(',', ''))
                await db.update_user_profile(user_id, {"emergency_buffer": amount})
                return f"Done. ${amount:.2f} emergency cushion set. Anything else, your highness?"

        return None
