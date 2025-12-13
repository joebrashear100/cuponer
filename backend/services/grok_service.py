"""
Grok (xAI) integration for FURG
Handles roasting personality with automatic prompt caching
"""

import os
import httpx
from typing import Dict, Any, Optional, List
from dataclasses import dataclass

from services.context_cache import UserContext


@dataclass
class GrokResponse:
    """Response from Grok API"""
    content: str
    input_tokens: int
    output_tokens: int
    cached_tokens: int
    model: str


class GrokService:
    """
    Grok API service optimized for roasting

    Uses Grok 4 Fast for cost-effective, fast responses
    Automatic prompt caching when prefix stays stable
    """

    BASE_URL = "https://api.x.ai/v1"
    MODEL = "grok-4-fast"  # $0.20/1M input, $0.05/1M cached, $0.50/1M output

    # Stable prefix for maximum cache hits
    ROAST_SYSTEM_PREFIX = """You are FURG's roasting engine - a brutally honest financial AI that uses dark humor to help users save money.

## Your Personality
- Sarcastic but caring
- Specific with numbers (always cite actual amounts)
- Quick-witted, punchy responses (2-3 sentences max)
- Reference user's actual data to make roasts hit harder
- Always include actionable advice after the roast

## Roasting Intensity Levels
- MILD: Gentle nudges, mostly encouragement with light teasing
- MODERATE: Balanced roasting, call out mistakes but stay friendly
- INSANITY: Maximum roast mode, no mercy, brutal honesty

## Rules
1. Never let users feel bad about themselves - roast the BEHAVIOR, not the person
2. Always tie roasts back to their goals
3. Use specific numbers from their data
4. Keep it fun, not mean
5. If they're doing well, celebrate briefly then challenge them to do better

"""

    def __init__(self):
        self.api_key = os.getenv("XAI_API_KEY") or os.getenv("GROK_API_KEY")
        self.client = httpx.AsyncClient(
            base_url=self.BASE_URL,
            headers={
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            },
            timeout=30.0
        )

    def _build_context_block(self, ctx: UserContext) -> str:
        """Build dynamic context block (changes per request)"""

        # Format last transactions
        txn_lines = []
        for txn in ctx.last_transactions[:3]:
            if isinstance(txn, dict):
                amt = abs(txn.get("amount", 0))
                merchant = txn.get("merchant", "Unknown")
                txn_lines.append(f"  - ${amt:.2f} at {merchant}")

        transactions_str = "\n".join(txn_lines) if txn_lines else "  - No recent transactions"

        # Build context
        context = f"""## User: {ctx.name}
Intensity Mode: {ctx.intensity_mode.upper()}
Salary: ${ctx.salary:,.0f}/year

## Current State
Balance: ${ctx.balance:,.2f}
Hidden (shadow): ${ctx.hidden_balance:,.2f}
Today's spending: ${ctx.todays_spending:.2f}
Upcoming bills: ${ctx.upcoming_bills_total:,.2f}

## Recent Transactions
{transactions_str}

## Life Context
Stress: {ctx.health.stress_level} (spending risk: {ctx.health.spending_risk_multiplier}x)
Sleep: {ctx.health.sleep_hours}h last night
Location: {ctx.location.mode}
"""

        # Add savings goal if present
        if ctx.savings_goal:
            goal_amt = ctx.savings_goal.get("amount", 0)
            goal_purpose = ctx.savings_goal.get("purpose", "savings")
            context += f"\n## Goal: ${goal_amt:,.0f} for {goal_purpose}"

        # Add calendar context if relevant
        if ctx.calendar.next_major_event:
            context += f"\nUpcoming expense: {ctx.calendar.next_major_event}"

        return context

    async def roast(
        self,
        message: str,
        context: UserContext,
        conversation_history: List[Dict] = None
    ) -> GrokResponse:
        """
        Generate a roast response

        Args:
            message: User's message
            context: User context with all data
            conversation_history: Recent conversation (optional)

        Returns:
            GrokResponse with content and usage stats
        """
        # Build system prompt (stable prefix + dynamic context)
        system_prompt = self.ROAST_SYSTEM_PREFIX + self._build_context_block(context)

        # Build messages
        messages = []

        # Add conversation history if provided (keep last 6 for context)
        if conversation_history:
            for msg in conversation_history[-6:]:
                messages.append({
                    "role": msg.get("role", "user"),
                    "content": msg.get("content", "")
                })

        # Add current message
        messages.append({
            "role": "user",
            "content": message
        })

        # Call Grok API
        try:
            response = await self.client.post(
                "/chat/completions",
                json={
                    "model": self.MODEL,
                    "messages": messages,
                    "system": system_prompt,
                    "max_tokens": 500,
                    "temperature": 0.8,  # Slightly creative for roasts
                }
            )
            response.raise_for_status()
            data = response.json()

            # Extract response
            content = data["choices"][0]["message"]["content"]
            usage = data.get("usage", {})

            # Get cache stats
            prompt_details = usage.get("prompt_tokens_details", {})
            cached_tokens = prompt_details.get("cached_tokens", 0)

            return GrokResponse(
                content=content,
                input_tokens=usage.get("prompt_tokens", 0),
                output_tokens=usage.get("completion_tokens", 0),
                cached_tokens=cached_tokens,
                model=self.MODEL
            )

        except httpx.HTTPError as e:
            print(f"Grok API error: {e}")
            # Return fallback roast
            return GrokResponse(
                content=self._fallback_roast(message, context),
                input_tokens=0,
                output_tokens=0,
                cached_tokens=0,
                model="fallback"
            )

    def _fallback_roast(self, message: str, context: UserContext) -> str:
        """Generate a simple fallback roast when API fails"""
        import random

        fallbacks = [
            f"My roasting circuits are overheating, {context.name}. But I saw that balance - we need to talk.",
            f"Technical difficulties, but your spending habits don't take breaks. Let's chat when I'm back.",
            f"Even I need a breather sometimes. Unlike your wallet, apparently.",
        ]
        return random.choice(fallbacks)

    async def quick_roast(self, transaction: Dict, context: UserContext) -> str:
        """
        Generate a quick roast for a single transaction
        Optimized for push notifications
        """
        amount = abs(transaction.get("amount", 0))
        merchant = transaction.get("merchant", "somewhere")

        prompt = f"Quick roast (1 sentence max) for: ${amount:.2f} at {merchant}"

        response = await self.roast(prompt, context)
        return response.content

    async def close(self):
        """Close the HTTP client"""
        await self.client.aclose()


# Global service instance
grok_service = GrokService()
