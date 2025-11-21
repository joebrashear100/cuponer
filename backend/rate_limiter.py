"""
Rate limiting and cost control for FURG
Prevents API abuse and manages Claude API costs
"""

import time
from typing import Dict, Callable
from datetime import datetime
from functools import wraps
from collections import defaultdict
from fastapi import HTTPException, Request
from database import db


# In-memory request tracking (use Redis in production for multi-instance deployments)
user_requests: Dict[str, list] = defaultdict(list)
user_token_usage: Dict[str, int] = defaultdict(int)

# Rate limits
MAX_REQUESTS_PER_MINUTE = 10
MAX_TOKENS_PER_DAY = 100000
MAX_COST_PER_DAY = 5.0  # $5 per day per user


def rate_limit_check(user_id: str) -> None:
    """
    Check if user has exceeded rate limits

    Raises:
        HTTPException: If rate limit exceeded
    """
    now = time.time()
    minute_ago = now - 60

    # Clean old requests
    requests = user_requests[user_id]
    requests = [t for t in requests if t > minute_ago]
    user_requests[user_id] = requests

    # Check request count
    if len(requests) >= MAX_REQUESTS_PER_MINUTE:
        raise HTTPException(
            status_code=429,
            detail=f"Slow down. Roast limit: {MAX_REQUESTS_PER_MINUTE}/min. You're too chatty."
        )

    # Add current request
    requests.append(now)


async def token_limit_check(user_id: str) -> None:
    """
    Check if user has exceeded daily token limit

    Raises:
        HTTPException: If token limit exceeded
    """
    # Get today's usage from database
    usage = await db.get_user_api_usage_today(user_id)
    total_tokens = usage["input_tokens"] + usage["output_tokens"]
    total_cost = float(usage["total_cost"])

    if total_tokens >= MAX_TOKENS_PER_DAY:
        raise HTTPException(
            status_code=429,
            detail=f"Daily chat quota reached ({MAX_TOKENS_PER_DAY:,} tokens). You talk too much. Try again tomorrow."
        )

    if total_cost >= MAX_COST_PER_DAY:
        raise HTTPException(
            status_code=429,
            detail=f"Daily cost limit reached (${MAX_COST_PER_DAY}). Take a break."
        )


def rate_limit(func: Callable) -> Callable:
    """
    Decorator for rate limiting endpoints

    Usage:
        @rate_limit
        async def my_endpoint(user_id: str = Depends(get_current_user)):
            ...
    """
    @wraps(func)
    async def wrapper(*args, **kwargs):
        # Extract user_id from kwargs or args
        user_id = kwargs.get("user_id")
        if not user_id:
            # Try to find in args (dependency injection)
            for arg in args:
                if isinstance(arg, str) and len(arg) == 36:  # UUID length
                    user_id = arg
                    break

        if not user_id:
            raise HTTPException(401, "Authentication required for rate limiting")

        # Check rate limits
        rate_limit_check(user_id)
        await token_limit_check(user_id)

        # Execute function
        return await func(*args, **kwargs)

    return wrapper


# Token counting utilities

def estimate_tokens(text: str) -> int:
    """
    Estimate token count for text
    Rough estimate: 1 token ≈ 4 characters
    """
    return len(text) // 4


def count_message_tokens(messages: list) -> int:
    """Count tokens in message list"""
    total = 0
    for msg in messages:
        content = msg.get("content", "")
        total += estimate_tokens(content)
        # Add overhead for message formatting
        total += 4
    return total


def calculate_cost(input_tokens: int, output_tokens: int) -> float:
    """
    Calculate cost for Claude API usage

    Claude Sonnet 4.5 pricing (as of Jan 2025):
    - Input: $3 per million tokens
    - Output: $15 per million tokens
    """
    input_cost = (input_tokens / 1_000_000) * 3.0
    output_cost = (output_tokens / 1_000_000) * 15.0
    return input_cost + output_cost


async def log_api_call(
    user_id: str,
    endpoint: str,
    input_tokens: int,
    output_tokens: int
) -> None:
    """Log API call for tracking and billing"""
    cost = calculate_cost(input_tokens, output_tokens)

    await db.log_api_usage(
        user_id=user_id,
        endpoint=endpoint,
        input_tokens=input_tokens,
        output_tokens=output_tokens,
        cost=cost
    )


# Middleware for automatic rate limiting

class RateLimitMiddleware:
    """
    FastAPI middleware for rate limiting
    Automatically tracks requests per IP/user
    """

    def __init__(self, app):
        self.app = app
        self.ip_requests: Dict[str, list] = defaultdict(list)

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return

        # Get client IP
        client_ip = None
        for name, value in scope.get("headers", []):
            if name == b"x-forwarded-for":
                client_ip = value.decode().split(",")[0].strip()
                break

        if not client_ip:
            client = scope.get("client")
            client_ip = client[0] if client else "unknown"

        # Check IP-based rate limit (prevent abuse before auth)
        now = time.time()
        minute_ago = now - 60

        requests = self.ip_requests[client_ip]
        requests = [t for t in requests if t > minute_ago]
        self.ip_requests[client_ip] = requests

        if len(requests) >= MAX_REQUESTS_PER_MINUTE * 2:  # More lenient for IP-based
            # Send 429 response
            response = {
                "type": "http.response.start",
                "status": 429,
                "headers": [[b"content-type", b"application/json"]],
            }
            await send(response)
            await send({
                "type": "http.response.body",
                "body": b'{"detail":"Too many requests from your IP. Slow down."}',
            })
            return

        requests.append(now)

        # Continue with request
        await self.app(scope, receive, send)


# Context manager for tracking API usage

class APIUsageTracker:
    """
    Context manager to track API usage and costs

    Usage:
        async with APIUsageTracker(user_id, "chat") as tracker:
            response = await call_claude_api(messages)
            tracker.record(response.usage.input_tokens, response.usage.output_tokens)
    """

    def __init__(self, user_id: str, endpoint: str):
        self.user_id = user_id
        self.endpoint = endpoint
        self.input_tokens = 0
        self.output_tokens = 0

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        if self.input_tokens > 0 or self.output_tokens > 0:
            await log_api_call(
                self.user_id,
                self.endpoint,
                self.input_tokens,
                self.output_tokens
            )

    def record(self, input_tokens: int, output_tokens: int):
        """Record token usage"""
        self.input_tokens = input_tokens
        self.output_tokens = output_tokens


# Budget management

async def check_budget_available(user_id: str, estimated_input_tokens: int) -> bool:
    """
    Check if user has budget for request

    Args:
        user_id: User ID
        estimated_input_tokens: Estimated tokens for request

    Returns:
        True if budget available, False otherwise
    """
    usage = await db.get_user_api_usage_today(user_id)
    total_tokens = usage["input_tokens"] + usage["output_tokens"]

    # Estimate output tokens (typically 2-3x input for chat)
    estimated_total = estimated_input_tokens * 3

    return (total_tokens + estimated_total) < MAX_TOKENS_PER_DAY


async def get_remaining_budget(user_id: str) -> Dict[str, any]:
    """Get user's remaining budget for today"""
    usage = await db.get_user_api_usage_today(user_id)

    total_tokens = usage["input_tokens"] + usage["output_tokens"]
    total_cost = float(usage["total_cost"])

    return {
        "requests_today": usage["requests"],
        "tokens_used": total_tokens,
        "tokens_remaining": max(0, MAX_TOKENS_PER_DAY - total_tokens),
        "cost_today": total_cost,
        "cost_remaining": max(0, MAX_COST_PER_DAY - total_cost),
        "percentage_used": min(100, (total_tokens / MAX_TOKENS_PER_DAY) * 100)
    }


# Truncate conversation history to fit budget

def truncate_to_budget(messages: list, max_tokens: int = 8000) -> list:
    """
    Truncate message history to fit within token budget

    Keeps system message and most recent messages

    Args:
        messages: List of message dicts
        max_tokens: Maximum tokens to use

    Returns:
        Truncated message list
    """
    if not messages:
        return messages

    current_tokens = count_message_tokens(messages)

    if current_tokens <= max_tokens:
        return messages

    # Always keep system message if present
    result = []
    if messages[0].get("role") == "system":
        result.append(messages[0])
        messages = messages[1:]

    # Keep most recent messages
    messages = list(reversed(messages))
    current = 0

    for msg in messages:
        msg_tokens = estimate_tokens(msg.get("content", "")) + 4
        if current + msg_tokens > max_tokens:
            break
        result.append(msg)
        current += msg_tokens

    # Reverse back to chronological order
    if result and result[0].get("role") == "system":
        return [result[0]] + list(reversed(result[1:]))
    else:
        return list(reversed(result))
