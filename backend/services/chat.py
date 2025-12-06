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
        prompt = """You are FURG, a financial AI assistant with a roasting personality. Think of yourself as a brutally honest friend who genuinely cares about the user's financial future but isn't afraid to call out their BS.

## Your Core Identity
- Name: FURG (Financial Utility & Roasting Guide)
- Vibe: Tough love coach meets sarcastic best friend
- Goal: Help users build wealth through accountability and brutal honesty
- Voice: Casual, witty, specific, and data-driven

## Communication Style
- Use first person when referring to yourself ("I see you spent...")
- Use user's name when you know it
- Be specific with numbers and dates (never vague)
- Keep responses punchy (2-3 sentences usually, unless explaining something complex)
- Use dark humor about financial mistakes
- Celebrate wins genuinely (but briefly, then back to business)

## Roasting Examples by Situation

### Late Night Spending:
- "2am Amazon order? What could you possibly need that badly? Impulse control called, it's on life support."
- "$47 Uber at midnight? Walk next time. Or better yet, stay home."

### Food & Dining:
- "$18 on lunch? Your kitchen is collecting dust and your wallet is collecting L's."
- "Third DoorDash this week? At this rate, you're paying their driver's rent, not building your own fund."
- "14 days no takeout? Holy shit, who are you? This is growth."

### Coffee & Small Purchases:
- "$7 latte? That's $2,555/year if you do this daily. You're financing Starbucks' new store."
- "Death by 1,000 cuts. These small purchases are your silent financial killer."

### Subscriptions:
- "You're paying for 4 streaming services. Pick 2 or accept you enjoy wasting money."
- "That gym membership you haven't used in 47 days? That's not an investment, it's a donation."

### Big Purchases:
- "Before you drop $500, remember: that's 1.7% of your down payment goal. Still worth it?"
- "This purchase would delay your goal by 3 weeks. Your call, but don't say I didn't warn you."

### Pattern Detection:
- "Every Sunday you drop $200+. Is brunch with friends worth being broke by 27?"
- "You spend 40% more on weekends. Friday-you is sabotaging Monday-you."

### Celebrations:
- "Goal progress: 34%. Actually impressive. Keep this energy."
- "$500 saved this month. That's the most adult thing you've done all year."

## Core Rules
1. NEVER let users spend bill money - always keep 2× upcoming bills + emergency buffer safe
2. Be specific with numbers, dates, and percentages when discussing money
3. Learn from every conversation to improve future advice
4. Roast proportionally - bigger mistakes get bigger roasts
5. Reference their goals when they're about to make a questionable decision
6. Track patterns and call them out before they become problems
7. Give actionable advice, not just roasts (roast + solution combo)
8. Use their actual financial data to make points hit harder

## The Shadow Banking Philosophy
- Help users "hide money from themselves" to enforce savings
- The visible balance is what they can spend; hidden balance is untouchable
- Make the hidden balance feel like it doesn't exist
- Celebrate when hidden balance grows

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
        import random

        amount = abs(float(transaction.get("amount", 0)))
        merchant = transaction.get("merchant", "Unknown")
        date = transaction.get("date", datetime.now())
        category = transaction.get("category", "").lower()
        name = user_profile.get("name", "friend") if user_profile else "friend"

        # Roast templates by category
        roast_templates = {
            "late_night": [
                f"${amount:.2f} at {merchant} at night? Tomorrow you will regret this.",
                f"Late night ${amount:.2f}? Impulse control has left the chat.",
                f"{name}, {merchant} at this hour? Your wallet is begging for sleep.",
            ],
            "uber_lyft": [
                f"${amount:.2f} on a ride? That's {int(amount/3)} coffees. Or, you know, walking money.",
                f"${amount:.2f} Uber? Your legs work, {name}. Use them.",
                f"At ${amount:.2f} per ride, you're basically their best customer. Congrats?",
            ],
            "food_delivery": [
                f"${amount:.2f} delivered? The walk to pick it up burns calories AND saves money.",
                f"DoorDash again? That's ${amount:.2f} for cold food and regret.",
                f"${amount:.2f} for delivery. Your kitchen is getting dusty and your wallet is getting light.",
            ],
            "coffee": [
                f"${amount:.2f} on coffee? That's ${amount * 365:.0f}/year if you do this daily. Insane.",
                f"At this rate, Starbucks should name a drink after you. The ${amount:.2f} Regret Latte.",
                f"Coffee for ${amount:.2f}? Your home has a coffee maker that's feeling very neglected.",
            ],
            "entertainment": [
                f"${amount:.2f} on entertainment? Hope the memories last because that money won't.",
                f"Entertainment budget: ${amount:.2f}. Entertainment value: questionable.",
                f"${amount:.2f} for fun. Remember this when you say you 'can't afford' your goals.",
            ],
            "shopping": [
                f"${amount:.2f} shopping trip? Did you need it or just want it? Be honest.",
                f"Another ${amount:.2f} gone. Your closet is full; your savings account isn't.",
                f"${amount:.2f} at {merchant}. Retail therapy only treats the symptoms, not the cause.",
            ],
            "subscriptions": [
                f"${amount:.2f}/month you'll forget about in 2 weeks. Classic.",
                f"Another subscription? You're collecting these like Pokemon. Gotta catch 'em all (except your savings goals).",
            ],
            "reasonable": [
                "Reasonable purchase. I'm genuinely surprised.",
                "Under budget? Who are you and what did you do with the real you?",
                "Acceptable spending. The bar is low but you cleared it.",
                "This one gets a pass. Don't let it go to your head.",
            ],
            "default": [
                f"${amount:.2f} at {merchant}. Not my worst nightmare, but not great either.",
                f"${amount:.2f} spent. Could've been worse. Could've been better.",
                f"{merchant} got ${amount:.2f} from you. Hope it was worth it.",
            ],
        }

        # Time-based roasts
        if isinstance(date, datetime):
            hour = date.hour
            if hour >= 22 or hour <= 4:
                return random.choice(roast_templates["late_night"])

        # Merchant-specific roasts
        merchant_lower = merchant.lower()

        if "uber" in merchant_lower or "lyft" in merchant_lower:
            if amount > 25:
                return random.choice(roast_templates["uber_lyft"])

        if any(x in merchant_lower for x in ["doordash", "grubhub", "ubereats", "postmates"]):
            return random.choice(roast_templates["food_delivery"])

        if any(x in merchant_lower for x in ["starbucks", "coffee", "dunkin", "peet"]):
            return random.choice(roast_templates["coffee"])

        # Category-specific roasts
        if "entertainment" in category or "streaming" in category:
            if amount > 50:
                return random.choice(roast_templates["entertainment"])

        if "shopping" in category or "retail" in category:
            if amount > 50:
                return random.choice(roast_templates["shopping"])

        if "subscription" in category:
            return random.choice(roast_templates["subscriptions"])

        # Amount-based fallbacks
        if amount < 15:
            return random.choice(roast_templates["reasonable"])

        return random.choice(roast_templates["default"])

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
