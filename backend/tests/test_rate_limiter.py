"""
Tests for rate limiting module (rate_limiter.py)
Tests request throttling, token limits, and cost calculations
"""

import os
import time
import pytest
from datetime import datetime
from unittest.mock import AsyncMock, patch, MagicMock

# Set test environment
os.environ["DEBUG"] = "true"
os.environ["JWT_SECRET"] = "test-secret-key-for-testing-only-32chars"

from rate_limiter import (
    rate_limit_check,
    token_limit_check,
    estimate_tokens,
    count_message_tokens,
    calculate_cost,
    truncate_to_budget,
    check_budget_available,
    get_remaining_budget,
    APIUsageTracker,
    RateLimitMiddleware,
    user_requests,
    MAX_REQUESTS_PER_MINUTE,
    MAX_TOKENS_PER_DAY,
    MAX_COST_PER_DAY
)
from fastapi import HTTPException


class TestRateLimitCheck:
    """Tests for request-based rate limiting"""

    def setup_method(self):
        """Clear rate limit state before each test"""
        user_requests.clear()

    def test_rate_limit_allows_first_request(self):
        """Test that first request is allowed"""
        # Should not raise
        rate_limit_check("test-user-1")

    def test_rate_limit_allows_under_limit(self):
        """Test that requests under limit are allowed"""
        user_id = "test-user-2"

        # Make MAX_REQUESTS_PER_MINUTE - 1 requests
        for i in range(MAX_REQUESTS_PER_MINUTE - 1):
            rate_limit_check(user_id)

        # All should succeed without raising

    def test_rate_limit_blocks_over_limit(self):
        """Test that exceeding limit raises 429"""
        user_id = "test-user-3"

        # Make MAX_REQUESTS_PER_MINUTE requests
        for i in range(MAX_REQUESTS_PER_MINUTE):
            rate_limit_check(user_id)

        # Next request should fail
        with pytest.raises(HTTPException) as exc_info:
            rate_limit_check(user_id)

        assert exc_info.value.status_code == 429
        assert "Slow down" in exc_info.value.detail

    def test_rate_limit_resets_after_minute(self):
        """Test that rate limit resets after 60 seconds"""
        user_id = "test-user-4"

        # Fill up the limit
        for i in range(MAX_REQUESTS_PER_MINUTE):
            rate_limit_check(user_id)

        # Manually expire old requests by setting them to past
        user_requests[user_id] = [time.time() - 61] * MAX_REQUESTS_PER_MINUTE

        # Should now be allowed
        rate_limit_check(user_id)  # Should not raise

    def test_rate_limit_per_user_isolation(self):
        """Test that each user has separate rate limit"""
        user1 = "user-isolation-1"
        user2 = "user-isolation-2"

        # Fill up user1's limit
        for i in range(MAX_REQUESTS_PER_MINUTE):
            rate_limit_check(user1)

        # User2 should still be allowed
        rate_limit_check(user2)  # Should not raise

        # User1 should be blocked
        with pytest.raises(HTTPException):
            rate_limit_check(user1)

    def test_rate_limit_cleans_old_requests(self):
        """Test that old requests are cleaned up"""
        user_id = "test-user-cleanup"

        # Add old requests
        user_requests[user_id] = [time.time() - 120] * 20  # 2 minutes ago

        # New request should be allowed and old ones cleaned
        rate_limit_check(user_id)

        # Should have only 1 request (the new one)
        assert len(user_requests[user_id]) == 1


class TestTokenLimitCheck:
    """Tests for token-based rate limiting"""

    @pytest.mark.asyncio
    async def test_token_limit_allows_under_limit(self):
        """Test that requests under token limit are allowed"""
        mock_db = AsyncMock()
        mock_db.get_user_api_usage_today.return_value = {
            "input_tokens": 1000,
            "output_tokens": 2000,
            "total_cost": "0.50",
            "requests": 10
        }

        with patch("rate_limiter.db", mock_db):
            # Should not raise
            await token_limit_check("test-user")

    @pytest.mark.asyncio
    async def test_token_limit_blocks_over_token_limit(self):
        """Test that exceeding token limit raises 429"""
        mock_db = AsyncMock()
        mock_db.get_user_api_usage_today.return_value = {
            "input_tokens": MAX_TOKENS_PER_DAY // 2 + 1,
            "output_tokens": MAX_TOKENS_PER_DAY // 2 + 1,
            "total_cost": "1.00",
            "requests": 100
        }

        with patch("rate_limiter.db", mock_db):
            with pytest.raises(HTTPException) as exc_info:
                await token_limit_check("test-user")

            assert exc_info.value.status_code == 429
            assert "Daily chat quota" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_token_limit_blocks_over_cost_limit(self):
        """Test that exceeding cost limit raises 429"""
        mock_db = AsyncMock()
        mock_db.get_user_api_usage_today.return_value = {
            "input_tokens": 10000,
            "output_tokens": 20000,
            "total_cost": str(MAX_COST_PER_DAY + 0.01),
            "requests": 50
        }

        with patch("rate_limiter.db", mock_db):
            with pytest.raises(HTTPException) as exc_info:
                await token_limit_check("test-user")

            assert exc_info.value.status_code == 429
            assert "Daily cost limit" in exc_info.value.detail


class TestTokenEstimation:
    """Tests for token estimation utilities"""

    def test_estimate_tokens_basic(self):
        """Test basic token estimation (1 token ≈ 4 chars)"""
        text = "Hello world"  # 11 chars
        tokens = estimate_tokens(text)
        assert tokens == 2  # 11 // 4 = 2

    def test_estimate_tokens_empty(self):
        """Test token estimation for empty string"""
        assert estimate_tokens("") == 0

    def test_estimate_tokens_long_text(self):
        """Test token estimation for longer text"""
        text = "a" * 1000
        tokens = estimate_tokens(text)
        assert tokens == 250  # 1000 // 4

    def test_count_message_tokens_single_message(self):
        """Test token counting for single message"""
        messages = [{"role": "user", "content": "Hello world"}]  # 11 chars = 2 tokens + 4 overhead
        tokens = count_message_tokens(messages)
        assert tokens == 6  # 2 + 4

    def test_count_message_tokens_multiple_messages(self):
        """Test token counting for multiple messages"""
        messages = [
            {"role": "system", "content": "You are helpful"},  # 15 chars = 3 + 4 = 7
            {"role": "user", "content": "Hello"},              # 5 chars = 1 + 4 = 5
            {"role": "assistant", "content": "Hi there!"}      # 9 chars = 2 + 4 = 6
        ]
        tokens = count_message_tokens(messages)
        assert tokens == 18  # 7 + 5 + 6

    def test_count_message_tokens_empty_list(self):
        """Test token counting for empty message list"""
        assert count_message_tokens([]) == 0

    def test_count_message_tokens_missing_content(self):
        """Test handling of messages without content"""
        messages = [{"role": "user"}]
        tokens = count_message_tokens(messages)
        assert tokens == 4  # Just overhead


class TestCostCalculation:
    """Tests for API cost calculation"""

    def test_calculate_cost_basic(self):
        """Test basic cost calculation"""
        # 1M input tokens = $3, 1M output tokens = $15
        cost = calculate_cost(1_000_000, 1_000_000)
        assert cost == 18.0  # $3 + $15

    def test_calculate_cost_zero_tokens(self):
        """Test cost calculation with zero tokens"""
        assert calculate_cost(0, 0) == 0.0

    def test_calculate_cost_input_only(self):
        """Test cost with only input tokens"""
        cost = calculate_cost(1_000_000, 0)
        assert cost == 3.0

    def test_calculate_cost_output_only(self):
        """Test cost with only output tokens"""
        cost = calculate_cost(0, 1_000_000)
        assert cost == 15.0

    def test_calculate_cost_small_amounts(self):
        """Test cost calculation for small token amounts"""
        # 1000 tokens
        cost = calculate_cost(1000, 500)
        expected = (1000 / 1_000_000) * 3.0 + (500 / 1_000_000) * 15.0
        assert abs(cost - expected) < 0.0001

    def test_calculate_cost_typical_chat(self):
        """Test cost for typical chat interaction"""
        # Typical chat: 500 input, 200 output
        cost = calculate_cost(500, 200)
        expected = (500 / 1_000_000) * 3.0 + (200 / 1_000_000) * 15.0
        assert abs(cost - expected) < 0.0001


class TestBudgetTruncation:
    """Tests for message history truncation"""

    def test_truncate_under_budget(self):
        """Test that messages under budget are not truncated"""
        messages = [
            {"role": "user", "content": "Hello"},
            {"role": "assistant", "content": "Hi"}
        ]

        result = truncate_to_budget(messages, max_tokens=1000)
        assert len(result) == 2

    def test_truncate_empty_list(self):
        """Test truncation of empty list"""
        result = truncate_to_budget([], max_tokens=100)
        assert result == []

    def test_truncate_keeps_system_message(self):
        """Test that system message is always kept"""
        messages = [
            {"role": "system", "content": "You are FURG"},
            {"role": "user", "content": "a" * 1000},  # 250 tokens
            {"role": "assistant", "content": "b" * 1000},
            {"role": "user", "content": "c" * 1000},
        ]

        # Very small budget, but system should be kept
        result = truncate_to_budget(messages, max_tokens=50)

        # Should have system + at least most recent messages
        assert result[0]["role"] == "system"

    def test_truncate_keeps_recent_messages(self):
        """Test that most recent messages are kept"""
        messages = [
            {"role": "user", "content": "old message " + "x" * 100},
            {"role": "assistant", "content": "old response " + "x" * 100},
            {"role": "user", "content": "recent message"},
            {"role": "assistant", "content": "recent response"},
        ]

        result = truncate_to_budget(messages, max_tokens=50)

        # Most recent messages should be kept
        if len(result) > 0:
            assert "recent" in result[-1]["content"] or "recent" in result[-2]["content"]

    def test_truncate_respects_max_tokens(self):
        """Test that result respects max token limit"""
        messages = [
            {"role": "user", "content": "a" * 400},  # 100 tokens + 4 overhead
            {"role": "assistant", "content": "b" * 400},
            {"role": "user", "content": "c" * 400},
        ]

        result = truncate_to_budget(messages, max_tokens=120)
        total_tokens = count_message_tokens(result)

        assert total_tokens <= 120


class TestBudgetAvailability:
    """Tests for budget availability checking"""

    @pytest.mark.asyncio
    async def test_budget_available_under_limit(self):
        """Test budget is available when under limit"""
        mock_db = AsyncMock()
        mock_db.get_user_api_usage_today.return_value = {
            "input_tokens": 1000,
            "output_tokens": 2000,
            "total_cost": "0.50",
            "requests": 10
        }

        with patch("rate_limiter.db", mock_db):
            result = await check_budget_available("test-user", 1000)
            assert result is True

    @pytest.mark.asyncio
    async def test_budget_not_available_over_limit(self):
        """Test budget not available when at limit"""
        mock_db = AsyncMock()
        mock_db.get_user_api_usage_today.return_value = {
            "input_tokens": MAX_TOKENS_PER_DAY - 100,
            "output_tokens": 0,
            "total_cost": "4.00",
            "requests": 100
        }

        with patch("rate_limiter.db", mock_db):
            # Request would push over limit
            result = await check_budget_available("test-user", 10000)
            assert result is False

    @pytest.mark.asyncio
    async def test_get_remaining_budget(self):
        """Test getting remaining budget details"""
        mock_db = AsyncMock()
        mock_db.get_user_api_usage_today.return_value = {
            "input_tokens": 10000,
            "output_tokens": 20000,
            "total_cost": "1.50",
            "requests": 25
        }

        with patch("rate_limiter.db", mock_db):
            result = await get_remaining_budget("test-user")

            assert result["requests_today"] == 25
            assert result["tokens_used"] == 30000
            assert result["tokens_remaining"] == MAX_TOKENS_PER_DAY - 30000
            assert result["cost_today"] == 1.50
            assert result["cost_remaining"] == MAX_COST_PER_DAY - 1.50


class TestAPIUsageTracker:
    """Tests for API usage tracking context manager"""

    @pytest.mark.asyncio
    async def test_usage_tracker_records_usage(self):
        """Test that usage tracker records token usage"""
        mock_db = AsyncMock()

        with patch("rate_limiter.db", mock_db):
            async with APIUsageTracker("test-user", "chat") as tracker:
                tracker.record(100, 50)

            # Should have logged the usage
            mock_db.log_api_usage.assert_called_once()
            call_kwargs = mock_db.log_api_usage.call_args
            assert call_kwargs[1]["input_tokens"] == 100
            assert call_kwargs[1]["output_tokens"] == 50

    @pytest.mark.asyncio
    async def test_usage_tracker_no_log_on_zero_tokens(self):
        """Test that zero token usage is not logged"""
        mock_db = AsyncMock()

        with patch("rate_limiter.db", mock_db):
            async with APIUsageTracker("test-user", "chat") as tracker:
                pass  # Don't record anything

            # Should not have logged
            mock_db.log_api_usage.assert_not_called()

    @pytest.mark.asyncio
    async def test_usage_tracker_calculates_cost(self):
        """Test that cost is calculated correctly"""
        mock_db = AsyncMock()

        with patch("rate_limiter.db", mock_db):
            async with APIUsageTracker("test-user", "chat") as tracker:
                tracker.record(1000, 500)

            call_kwargs = mock_db.log_api_usage.call_args[1]
            expected_cost = calculate_cost(1000, 500)
            assert abs(call_kwargs["cost"] - expected_cost) < 0.0001


class TestRateLimitMiddleware:
    """Tests for rate limiting middleware"""

    @pytest.mark.asyncio
    async def test_middleware_allows_normal_requests(self):
        """Test that normal requests are allowed through"""
        app_mock = AsyncMock()
        middleware = RateLimitMiddleware(app_mock)

        scope = {
            "type": "http",
            "client": ("127.0.0.1", 12345),
            "headers": []
        }

        receive = AsyncMock()
        send = AsyncMock()

        await middleware(scope, receive, send)

        # App should have been called
        app_mock.assert_called_once()

    @pytest.mark.asyncio
    async def test_middleware_tracks_by_ip(self):
        """Test that middleware tracks requests by IP"""
        app_mock = AsyncMock()
        middleware = RateLimitMiddleware(app_mock)

        scope = {
            "type": "http",
            "client": ("192.168.1.1", 12345),
            "headers": []
        }

        # Make several requests
        for _ in range(5):
            await middleware(scope, AsyncMock(), AsyncMock())

        # Should have tracked the IP
        assert "192.168.1.1" in middleware.ip_requests
        assert len(middleware.ip_requests["192.168.1.1"]) == 5

    @pytest.mark.asyncio
    async def test_middleware_uses_x_forwarded_for(self):
        """Test that middleware uses X-Forwarded-For header"""
        app_mock = AsyncMock()
        middleware = RateLimitMiddleware(app_mock)

        scope = {
            "type": "http",
            "client": ("127.0.0.1", 12345),
            "headers": [(b"x-forwarded-for", b"10.0.0.1, 192.168.1.1")]
        }

        await middleware(scope, AsyncMock(), AsyncMock())

        # Should use first IP from X-Forwarded-For
        assert "10.0.0.1" in middleware.ip_requests

    @pytest.mark.asyncio
    async def test_middleware_blocks_excessive_requests(self):
        """Test that excessive requests from same IP are blocked"""
        app_mock = AsyncMock()
        middleware = RateLimitMiddleware(app_mock)

        scope = {
            "type": "http",
            "client": ("10.0.0.100", 12345),
            "headers": []
        }

        send = AsyncMock()

        # Exceed IP limit (2x per-user limit)
        for i in range(MAX_REQUESTS_PER_MINUTE * 2 + 1):
            await middleware(scope, AsyncMock(), send)

        # Last request should have sent 429
        # Check if 429 was sent
        calls = send.call_args_list
        found_429 = any(
            call[0][0].get("status") == 429
            for call in calls
            if isinstance(call[0][0], dict)
        )
        assert found_429

    @pytest.mark.asyncio
    async def test_middleware_ignores_non_http(self):
        """Test that non-HTTP requests are passed through"""
        app_mock = AsyncMock()
        middleware = RateLimitMiddleware(app_mock)

        scope = {"type": "websocket"}

        await middleware(scope, AsyncMock(), AsyncMock())

        # Should pass through without tracking
        app_mock.assert_called_once()


class TestRateLimitConstants:
    """Tests for rate limit configuration"""

    def test_max_requests_per_minute_reasonable(self):
        """Test that max requests per minute is reasonable"""
        assert MAX_REQUESTS_PER_MINUTE >= 5
        assert MAX_REQUESTS_PER_MINUTE <= 100

    def test_max_tokens_per_day_reasonable(self):
        """Test that max tokens per day is reasonable"""
        assert MAX_TOKENS_PER_DAY >= 10000
        assert MAX_TOKENS_PER_DAY <= 1_000_000

    def test_max_cost_per_day_reasonable(self):
        """Test that max cost per day is reasonable"""
        assert MAX_COST_PER_DAY >= 1.0
        assert MAX_COST_PER_DAY <= 100.0
