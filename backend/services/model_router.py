"""
Multi-Model Router for FURG
Orchestrates requests between Grok, Claude, and Gemini based on intent

Architecture:
    User Message → Gemini (Router) → Grok (Roast) / Claude (Advice) / Gemini (Categorize)

Cost Optimization:
    - Gemini router: ~$0.00001 per classification
    - Grok roasts: ~$0.00007 per response (with caching)
    - Claude advice: ~$0.00127 per response (with caching)
    - Blended average: ~$0.00037 per request (94% savings vs pure Claude)
"""

import os
import asyncio
from typing import Dict, Any, Optional, List
from dataclasses import dataclass
from datetime import datetime
import anthropic

from services.gemini_service import gemini_service, ModelIntent, RouterResponse
from services.grok_service import grok_service, GrokResponse
from services.context_cache import context_cache, UserContext


@dataclass
class ModelResponse:
    """Unified response from any model"""
    content: str
    model: str
    intent: ModelIntent
    input_tokens: int
    output_tokens: int
    cached_tokens: int
    cost: float
    latency_ms: int


class ModelRouter:
    """
    Intelligent model router for FURG

    Routes requests to the optimal model based on intent:
    - ROAST, GENERAL → Grok 4 Fast (cheap, fast, edgy)
    - ADVICE, SENSITIVE → Claude Sonnet (nuanced, safe)
    - CATEGORIZE, RECEIPT → Gemini Flash (fast, multimodal)
    """

    # Cost per 1M tokens (for tracking)
    COSTS = {
        "grok-4-fast": {"input": 0.20, "output": 0.50, "cached": 0.05},
        "claude-sonnet-4-20250514": {"input": 3.00, "output": 15.00, "cached": 0.30},
        "gemini-2.0-flash": {"input": 0.075, "output": 0.30, "cached": 0.02},
    }

    # Intent to model mapping
    INTENT_MODEL_MAP = {
        ModelIntent.ROAST: "grok",
        ModelIntent.GENERAL: "grok",
        ModelIntent.ADVICE: "claude",
        ModelIntent.SENSITIVE: "claude",
        ModelIntent.CATEGORIZE: "gemini",
        ModelIntent.RECEIPT: "gemini",
    }

    def __init__(self):
        self.claude_client = anthropic.Anthropic(
            api_key=os.getenv("ANTHROPIC_API_KEY")
        )
        self._use_local_heuristics = True  # Fast path for obvious intents

    async def initialize(self):
        """Initialize services and caches"""
        await context_cache.connect()

    def _local_intent_heuristics(self, message: str) -> Optional[ModelIntent]:
        """
        Fast local heuristics for obvious intents
        Saves a Gemini call for ~70% of messages
        """
        msg_lower = message.lower().strip()

        # Explicit roast requests
        if any(word in msg_lower for word in ["roast", "roasting", "mock", "burn"]):
            return ModelIntent.ROAST

        # Greetings and casual chat -> roast (cheap)
        greetings = ["hey", "hi", "hello", "what's up", "sup", "yo", "howdy"]
        if any(msg_lower.startswith(g) for g in greetings):
            return ModelIntent.ROAST

        # Serious financial questions -> advice
        advice_triggers = [
            "should i", "is it worth", "can i afford", "how much should",
            "help me", "advice", "recommend", "budget", "invest", "save for",
            "what do you think about buying", "is this a good idea"
        ]
        if any(trigger in msg_lower for trigger in advice_triggers):
            return ModelIntent.ADVICE

        # Category questions
        if "category" in msg_lower or "categorize" in msg_lower:
            return ModelIntent.CATEGORIZE

        # Receipt mentions
        if any(word in msg_lower for word in ["receipt", "scan", "bill"]):
            return ModelIntent.RECEIPT

        # Sensitive/complaints
        complaint_words = ["broken", "not working", "bug", "issue", "problem", "hate", "sucks"]
        if any(word in msg_lower for word in complaint_words):
            return ModelIntent.SENSITIVE

        # Settings changes -> sensitive (needs careful handling)
        if any(word in msg_lower for word in ["change", "update", "set", "settings"]):
            return ModelIntent.SENSITIVE

        return None  # Need Gemini to classify

    async def classify_intent(self, message: str) -> RouterResponse:
        """
        Classify user intent, using local heuristics when possible
        """
        # Try fast local heuristics first
        if self._use_local_heuristics:
            local_intent = self._local_intent_heuristics(message)
            if local_intent:
                return RouterResponse(
                    intent=local_intent,
                    confidence=0.85,
                    reasoning="local heuristics"
                )

        # Fall back to Gemini for ambiguous cases
        return await gemini_service.classify_intent(message)

    async def route(
        self,
        user_id: str,
        message: str,
        profile: Dict,
        dynamic_data: Dict,
        life_context: Optional[Dict] = None,
        conversation_history: List[Dict] = None
    ) -> ModelResponse:
        """
        Route message to appropriate model and get response

        Args:
            user_id: User ID
            message: User's message
            profile: User profile data
            dynamic_data: Real-time data (balance, transactions)
            life_context: Health/location/calendar context
            conversation_history: Recent conversation

        Returns:
            ModelResponse with content and metadata
        """
        start_time = datetime.now()

        # Step 1: Classify intent
        router_response = await self.classify_intent(message)
        intent = router_response.intent

        # Step 2: Build user context (uses caching)
        context = await context_cache.build_user_context(
            user_id=user_id,
            profile=profile,
            dynamic_data=dynamic_data,
            life_context=life_context
        )

        # Step 3: Route to appropriate model
        model_type = self.INTENT_MODEL_MAP.get(intent, "grok")

        if model_type == "grok":
            response = await self._call_grok(message, context, conversation_history)
        elif model_type == "claude":
            response = await self._call_claude(message, context, conversation_history)
        else:  # gemini
            response = await self._call_gemini(message, context)

        # Calculate latency
        latency_ms = int((datetime.now() - start_time).total_seconds() * 1000)

        return ModelResponse(
            content=response["content"],
            model=response["model"],
            intent=intent,
            input_tokens=response["input_tokens"],
            output_tokens=response["output_tokens"],
            cached_tokens=response.get("cached_tokens", 0),
            cost=self._calculate_cost(
                response["model"],
                response["input_tokens"],
                response["output_tokens"],
                response.get("cached_tokens", 0)
            ),
            latency_ms=latency_ms
        )

    async def _call_grok(
        self,
        message: str,
        context: UserContext,
        history: List[Dict] = None
    ) -> Dict:
        """Call Grok for roasting"""
        response = await grok_service.roast(message, context, history)

        return {
            "content": response.content,
            "model": response.model,
            "input_tokens": response.input_tokens,
            "output_tokens": response.output_tokens,
            "cached_tokens": response.cached_tokens
        }

    async def _call_claude(
        self,
        message: str,
        context: UserContext,
        history: List[Dict] = None
    ) -> Dict:
        """Call Claude for serious advice"""
        # Build system prompt with caching hint
        system_parts = [
            {
                "type": "text",
                "text": self._build_claude_system_prompt(),
                "cache_control": {"type": "ephemeral"}  # Cache for 5 min
            },
            {
                "type": "text",
                "text": self._build_claude_context(context)
            }
        ]

        # Build messages
        messages = []
        if history:
            for msg in history[-10:]:
                messages.append({
                    "role": msg.get("role", "user"),
                    "content": msg.get("content", "")
                })

        messages.append({
            "role": "user",
            "content": message
        })

        try:
            response = self.claude_client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=1000,
                system=system_parts,
                messages=messages
            )

            # Extract cache info
            usage = response.usage
            cached_tokens = getattr(usage, 'cache_read_input_tokens', 0)

            return {
                "content": response.content[0].text,
                "model": "claude-sonnet-4-20250514",
                "input_tokens": usage.input_tokens,
                "output_tokens": usage.output_tokens,
                "cached_tokens": cached_tokens
            }

        except Exception as e:
            print(f"Claude API error: {e}")
            return {
                "content": "I'm having trouble thinking clearly right now. Can you try again?",
                "model": "claude-fallback",
                "input_tokens": 0,
                "output_tokens": 0,
                "cached_tokens": 0
            }

    async def _call_gemini(self, message: str, context: UserContext) -> Dict:
        """Call Gemini for categorization queries"""
        # For categorization, provide a helpful response
        prompt = f"""User is asking about categories. Help them understand.

User context:
- Name: {context.name}
- Recent transactions: {len(context.last_transactions)} in history

User asks: {message}

Provide a helpful, concise response about transaction categories."""

        try:
            result = await gemini_service._call_gemini(
                prompt=prompt,
                temperature=0.3,
                max_tokens=300
            )

            text = result["candidates"][0]["content"]["parts"][0]["text"]
            usage = result.get("usageMetadata", {})

            return {
                "content": text,
                "model": "gemini-2.0-flash",
                "input_tokens": usage.get("promptTokenCount", 0),
                "output_tokens": usage.get("candidatesTokenCount", 0),
                "cached_tokens": usage.get("cachedContentTokenCount", 0)
            }

        except Exception as e:
            print(f"Gemini error: {e}")
            return {
                "content": "Let me help you with categories. What would you like to know?",
                "model": "gemini-fallback",
                "input_tokens": 0,
                "output_tokens": 0,
                "cached_tokens": 0
            }

    def _build_claude_system_prompt(self) -> str:
        """Build Claude's system prompt (cacheable prefix)"""
        return """You are FURG, a financial AI advisor with expertise in personal finance.

## Your Role
You provide thoughtful, nuanced financial advice. While you can be witty, your primary goal here is to genuinely help users make smart financial decisions.

## Guidelines
- Be specific with numbers and calculations
- Consider the user's full financial picture
- Weigh pros and cons objectively
- If a purchase is actually fine, say so
- If it's a bad idea, explain why clearly
- Reference their goals and current situation
- Keep responses focused and actionable

## Important
- Never shame users for past decisions
- Focus on forward-looking advice
- Be honest about uncertainty
- Suggest professional help for complex situations (taxes, investments)
"""

    def _build_claude_context(self, ctx: UserContext) -> str:
        """Build dynamic context for Claude"""
        context = f"""
## User Profile
Name: {ctx.name}
Salary: ${ctx.salary:,.0f}/year
Intensity preference: {ctx.intensity_mode}

## Current Financial State
Available balance: ${ctx.balance:,.2f}
Hidden savings: ${ctx.hidden_balance:,.2f}
Upcoming bills: ${ctx.upcoming_bills_total:,.2f}
Today's spending: ${ctx.todays_spending:.2f}

## Life Context
Stress level: {ctx.health.stress_level}
Location mode: {ctx.location.mode}
"""

        if ctx.savings_goal:
            goal = ctx.savings_goal
            context += f"\nSavings goal: ${goal.get('amount', 0):,.0f} for {goal.get('purpose', 'savings')}"

        if ctx.learned_insights:
            context += "\n\nLearned about user:\n"
            for insight in ctx.learned_insights[:3]:
                context += f"- {insight}\n"

        return context

    def _calculate_cost(
        self,
        model: str,
        input_tokens: int,
        output_tokens: int,
        cached_tokens: int
    ) -> float:
        """Calculate cost for a request"""
        costs = self.COSTS.get(model, self.COSTS["grok-4-fast"])

        # Cached tokens are charged at cached rate, rest at input rate
        fresh_input = input_tokens - cached_tokens
        input_cost = (fresh_input / 1_000_000) * costs["input"]
        cached_cost = (cached_tokens / 1_000_000) * costs["cached"]
        output_cost = (output_tokens / 1_000_000) * costs["output"]

        return input_cost + cached_cost + output_cost

    async def get_model_stats(self) -> Dict:
        """Get routing statistics"""
        # In production, track these in Redis/DB
        return {
            "models": {
                "grok": {"requests": 0, "avg_latency_ms": 0, "total_cost": 0},
                "claude": {"requests": 0, "avg_latency_ms": 0, "total_cost": 0},
                "gemini": {"requests": 0, "avg_latency_ms": 0, "total_cost": 0},
            },
            "cache_hit_rate": 0,
            "local_heuristics_rate": 0
        }


# Global router instance
model_router = ModelRouter()
