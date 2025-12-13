"""
Context caching layer for FURG
Manages layered context with TTL-based caching to reduce token costs
"""

import os
import json
import hashlib
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass, asdict
import asyncio

# Try to import Redis, fall back to in-memory cache
try:
    import redis.asyncio as redis
    REDIS_AVAILABLE = True
except ImportError:
    REDIS_AVAILABLE = False


@dataclass
class HealthContext:
    """Health data from HealthKit"""
    stress_level: str = "moderate"  # low, moderate, elevated, high
    sleep_hours: float = 7.0
    steps_today: int = 0
    hrv: Optional[float] = None
    activity_level: str = "moderate"
    spending_risk_multiplier: float = 1.0


@dataclass
class LocationContext:
    """Location data"""
    mode: str = "home"  # home, work, traveling, shopping, dining
    city: str = "unknown"
    is_traveling: bool = False
    current_place_type: Optional[str] = None


@dataclass
class CalendarContext:
    """Calendar data"""
    upcoming_expensive_events: list = None
    total_upcoming_costs: float = 0
    next_major_event: Optional[str] = None
    busy_days_this_week: int = 0

    def __post_init__(self):
        if self.upcoming_expensive_events is None:
            self.upcoming_expensive_events = []


@dataclass
class UserContext:
    """Combined user context for AI models"""
    # Static (rarely changes)
    user_id: str
    name: str
    intensity_mode: str = "moderate"
    salary: float = 0
    savings_goal: Optional[Dict] = None
    learned_insights: list = None

    # Slow-changing (hourly refresh)
    health: HealthContext = None
    location: LocationContext = None
    calendar: CalendarContext = None
    weekly_spending_avg: float = 0
    weekend_spending_multiplier: float = 1.0

    # Dynamic (per-request)
    balance: float = 0
    hidden_balance: float = 0
    upcoming_bills_total: float = 0
    last_transactions: list = None
    todays_spending: float = 0

    def __post_init__(self):
        if self.health is None:
            self.health = HealthContext()
        if self.location is None:
            self.location = LocationContext()
        if self.calendar is None:
            self.calendar = CalendarContext()
        if self.learned_insights is None:
            self.learned_insights = []
        if self.last_transactions is None:
            self.last_transactions = []


class ContextCache:
    """
    Layered context cache with TTL management

    Layer 1: Static - User profile, preferences (24h TTL)
    Layer 2: Slow - Health, location, calendar (1h TTL)
    Layer 3: Dynamic - Balance, transactions (no cache, always fresh)
    """

    # Cache TTLs in seconds
    STATIC_TTL = 86400   # 24 hours
    SLOW_TTL = 3600      # 1 hour
    PROMPT_TTL = 300     # 5 minutes for compiled prompts

    def __init__(self):
        self.redis_client: Optional[redis.Redis] = None
        self._memory_cache: Dict[str, tuple] = {}  # key -> (value, expiry)
        self._lock = asyncio.Lock()

    async def connect(self):
        """Connect to Redis if available"""
        redis_url = os.getenv("REDIS_URL")
        if redis_url and REDIS_AVAILABLE:
            try:
                self.redis_client = redis.from_url(redis_url)
                await self.redis_client.ping()
                print("Connected to Redis for context caching")
            except Exception as e:
                print(f"Redis connection failed, using in-memory cache: {e}")
                self.redis_client = None
        else:
            print("Using in-memory context cache")

    def _cache_key(self, user_id: str, layer: str) -> str:
        """Generate cache key"""
        return f"ctx:{user_id}:{layer}"

    def _prompt_cache_key(self, user_id: str, model: str, content_hash: str) -> str:
        """Generate prompt cache key for tracking cache hits"""
        return f"prompt:{user_id}:{model}:{content_hash}"

    async def _get(self, key: str) -> Optional[str]:
        """Get from cache (Redis or memory)"""
        if self.redis_client:
            try:
                return await self.redis_client.get(key)
            except Exception:
                pass

        # Fallback to memory cache
        async with self._lock:
            if key in self._memory_cache:
                value, expiry = self._memory_cache[key]
                if datetime.now() < expiry:
                    return value
                else:
                    del self._memory_cache[key]
        return None

    async def _set(self, key: str, value: str, ttl: int):
        """Set in cache with TTL"""
        if self.redis_client:
            try:
                await self.redis_client.setex(key, ttl, value)
                return
            except Exception:
                pass

        # Fallback to memory cache
        async with self._lock:
            expiry = datetime.now() + timedelta(seconds=ttl)
            self._memory_cache[key] = (value, expiry)

    async def _delete(self, key: str):
        """Delete from cache"""
        if self.redis_client:
            try:
                await self.redis_client.delete(key)
            except Exception:
                pass

        async with self._lock:
            self._memory_cache.pop(key, None)

    # ==================== LAYER 1: STATIC ====================

    async def get_static_context(self, user_id: str) -> Optional[Dict]:
        """Get cached static context (user profile, preferences)"""
        key = self._cache_key(user_id, "static")
        data = await self._get(key)
        if data:
            return json.loads(data)
        return None

    async def set_static_context(self, user_id: str, context: Dict):
        """Cache static context"""
        key = self._cache_key(user_id, "static")
        await self._set(key, json.dumps(context), self.STATIC_TTL)

    # ==================== LAYER 2: SLOW-CHANGING ====================

    async def get_slow_context(self, user_id: str) -> Optional[Dict]:
        """Get cached slow-changing context (health, location, calendar)"""
        key = self._cache_key(user_id, "slow")
        data = await self._get(key)
        if data:
            return json.loads(data)
        return None

    async def set_slow_context(self, user_id: str, context: Dict):
        """Cache slow-changing context"""
        key = self._cache_key(user_id, "slow")
        await self._set(key, json.dumps(context), self.SLOW_TTL)

    # ==================== PROMPT CACHING ====================

    async def get_cached_prompt(self, user_id: str, model: str, prefix: str) -> Optional[str]:
        """Get cached compiled prompt for a model"""
        content_hash = hashlib.md5(prefix.encode()).hexdigest()[:8]
        key = self._prompt_cache_key(user_id, model, content_hash)
        return await self._get(key)

    async def set_cached_prompt(self, user_id: str, model: str, prefix: str, full_prompt: str):
        """Cache compiled prompt"""
        content_hash = hashlib.md5(prefix.encode()).hexdigest()[:8]
        key = self._prompt_cache_key(user_id, model, content_hash)
        await self._set(key, full_prompt, self.PROMPT_TTL)

    # ==================== CONTEXT BUILDER ====================

    async def build_user_context(
        self,
        user_id: str,
        profile: Dict,
        dynamic_data: Dict,
        life_context: Optional[Dict] = None
    ) -> UserContext:
        """
        Build complete user context from all sources
        Uses caching for static/slow layers
        """
        # Try to get cached static context
        static = await self.get_static_context(user_id)
        if not static:
            static = {
                "name": profile.get("name", "friend"),
                "intensity_mode": profile.get("intensity_mode", "moderate"),
                "salary": profile.get("salary", 0),
                "savings_goal": profile.get("savings_goal"),
                "learned_insights": profile.get("learned_insights", [])[:5]
            }
            await self.set_static_context(user_id, static)

        # Try to get cached slow context
        slow = await self.get_slow_context(user_id)
        if not slow and life_context:
            slow = {
                "health": {
                    "stress_level": life_context.get("health", {}).get("stress_level", "moderate"),
                    "sleep_hours": life_context.get("health", {}).get("last_night_sleep", 7.0),
                    "steps_today": life_context.get("health", {}).get("step_count", 0),
                    "hrv": life_context.get("health", {}).get("heart_rate_variability"),
                    "spending_risk_multiplier": self._calculate_risk_multiplier(life_context)
                },
                "location": {
                    "mode": life_context.get("location", {}).get("current_mode", "home"),
                    "city": life_context.get("location", {}).get("city", "unknown"),
                    "is_traveling": not life_context.get("location", {}).get("is_in_home_city", True)
                },
                "calendar": {
                    "upcoming_expensive_events": life_context.get("calendar", {}).get("upcoming_events", [])[:3],
                    "total_upcoming_costs": life_context.get("calendar", {}).get("total_upcoming_costs", 0),
                    "next_major_event": life_context.get("calendar", {}).get("next_major_event")
                },
                "weekly_spending_avg": dynamic_data.get("weekly_avg", 0),
                "weekend_spending_multiplier": dynamic_data.get("weekend_multiplier", 1.0)
            }
            await self.set_slow_context(user_id, slow)
        elif not slow:
            slow = {
                "health": {"stress_level": "moderate", "sleep_hours": 7.0, "spending_risk_multiplier": 1.0},
                "location": {"mode": "home", "city": "unknown", "is_traveling": False},
                "calendar": {"upcoming_expensive_events": [], "total_upcoming_costs": 0},
                "weekly_spending_avg": 0,
                "weekend_spending_multiplier": 1.0
            }

        # Build context object
        return UserContext(
            user_id=user_id,
            name=static.get("name", "friend"),
            intensity_mode=static.get("intensity_mode", "moderate"),
            salary=static.get("salary", 0),
            savings_goal=static.get("savings_goal"),
            learned_insights=static.get("learned_insights", []),
            health=HealthContext(**slow.get("health", {})),
            location=LocationContext(**slow.get("location", {})),
            calendar=CalendarContext(**slow.get("calendar", {})),
            weekly_spending_avg=slow.get("weekly_spending_avg", 0),
            weekend_spending_multiplier=slow.get("weekend_spending_multiplier", 1.0),
            balance=dynamic_data.get("balance", 0),
            hidden_balance=dynamic_data.get("hidden_balance", 0),
            upcoming_bills_total=dynamic_data.get("upcoming_bills", 0),
            last_transactions=dynamic_data.get("recent_transactions", [])[:5],
            todays_spending=dynamic_data.get("todays_spending", 0)
        )

    def _calculate_risk_multiplier(self, life_context: Dict) -> float:
        """Calculate spending risk multiplier from life context"""
        risk = 1.0

        health = life_context.get("health", {})
        stress = health.get("stress_level", "moderate")

        stress_multipliers = {
            "low": 1.0,
            "moderate": 1.15,
            "elevated": 1.35,
            "high": 1.6
        }
        risk *= stress_multipliers.get(stress, 1.15)

        # Sleep impact
        sleep = health.get("last_night_sleep", 7)
        if sleep < 5:
            risk *= 1.2
        elif sleep < 6:
            risk *= 1.1

        return round(risk, 2)

    # ==================== INVALIDATION ====================

    async def invalidate_user_cache(self, user_id: str, layers: list = None):
        """Invalidate cache for user (all layers or specific ones)"""
        layers = layers or ["static", "slow"]
        for layer in layers:
            key = self._cache_key(user_id, layer)
            await self._delete(key)

    async def invalidate_on_profile_update(self, user_id: str):
        """Invalidate static cache when profile is updated"""
        await self.invalidate_user_cache(user_id, ["static"])

    async def invalidate_on_life_context_update(self, user_id: str):
        """Invalidate slow cache when life context updates"""
        await self.invalidate_user_cache(user_id, ["slow"])


# Global cache instance
context_cache = ContextCache()
