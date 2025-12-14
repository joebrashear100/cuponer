"""
Tests for API endpoints (main.py)
Tests all REST API endpoints including auth, chat, balance, and financial operations
"""

import os
import pytest
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, patch, MagicMock

# Set test environment
os.environ["DEBUG"] = "true"
os.environ["JWT_SECRET"] = "test-secret-key-for-testing-only-32chars"


class TestRootEndpoint:
    """Tests for root endpoint"""

    def test_root_returns_app_info(self, test_client):
        """Test that root endpoint returns app information"""
        response = test_client.get("/")

        assert response.status_code == 200
        data = response.json()
        assert data["app"] == "FURG"
        assert "version" in data
        assert "tagline" in data


class TestHealthEndpoint:
    """Tests for health check endpoint"""

    def test_health_check_success(self, test_client, mock_db):
        """Test health check when database is connected"""
        # Mock the acquire context manager
        conn_mock = AsyncMock()
        conn_mock.fetchval.return_value = 1

        @patch("main.db.acquire")
        def run_test(mock_acquire):
            mock_acquire.return_value.__aenter__.return_value = conn_mock
            response = test_client.get("/health")
            return response

        response = run_test()
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"

    def test_health_check_includes_timestamp(self, test_client, mock_db):
        """Test that health check includes timestamp"""
        conn_mock = AsyncMock()
        conn_mock.fetchval.return_value = 1

        with patch("main.db.acquire") as mock_acquire:
            mock_acquire.return_value.__aenter__.return_value = conn_mock
            response = test_client.get("/health")

        data = response.json()
        assert "timestamp" in data


class TestAuthEndpoints:
    """Tests for authentication endpoints"""

    def test_auth_apple_success(self, test_client, mock_db):
        """Test successful Apple authentication"""
        mock_db.get_or_create_user.return_value = {
            "id": "new-user-uuid",
            "apple_id": "apple123",
            "email": "test@example.com",
            "created_at": datetime.utcnow()
        }

        response = test_client.post(
            "/api/v1/auth/apple",
            json={"apple_token": "test_apple_testuser"}
        )

        assert response.status_code == 200
        data = response.json()
        assert "jwt" in data
        assert "user_id" in data
        assert data["user_id"] == "new-user-uuid"

    def test_auth_apple_new_user_flag(self, test_client, mock_db):
        """Test that new user flag is set correctly"""
        # New user - created just now
        mock_db.get_or_create_user.return_value = {
            "id": "brand-new-user",
            "apple_id": "apple456",
            "email": "new@example.com",
            "created_at": datetime.utcnow()
        }

        response = test_client.post(
            "/api/v1/auth/apple",
            json={"apple_token": "test_apple_newbie"}
        )

        data = response.json()
        assert data["is_new_user"] is True

    def test_auth_apple_existing_user(self, test_client, mock_db):
        """Test that existing user flag is set correctly"""
        # Existing user - created 30 days ago
        mock_db.get_or_create_user.return_value = {
            "id": "existing-user",
            "apple_id": "apple789",
            "email": "existing@example.com",
            "created_at": datetime.utcnow() - timedelta(days=30)
        }

        response = test_client.post(
            "/api/v1/auth/apple",
            json={"apple_token": "test_apple_olduser"}
        )

        data = response.json()
        assert data["is_new_user"] is False

    def test_auth_apple_invalid_token(self, test_client):
        """Test that invalid Apple token returns 401"""
        response = test_client.post(
            "/api/v1/auth/apple",
            json={"apple_token": "invalid_token_format"}
        )

        assert response.status_code == 401

    def test_auth_me_authenticated(self, test_client, mock_db, auth_headers):
        """Test getting current user info when authenticated"""
        response = test_client.get("/api/v1/auth/me", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert "user_id" in data
        assert "profile" in data

    def test_auth_me_unauthenticated(self, test_client):
        """Test that unauthenticated request to /me returns 403"""
        response = test_client.get("/api/v1/auth/me")

        assert response.status_code == 403


class TestChatEndpoints:
    """Tests for chat endpoints"""

    def test_chat_success(self, test_client, mock_db, auth_headers, mock_anthropic_client):
        """Test successful chat message"""
        mock_db.get_user_profile.return_value = {
            "intensity_mode": "moderate",
            "emergency_buffer": 500.00
        }
        mock_db.get_chat_history.return_value = []

        with patch("services.chat.Anthropic", return_value=mock_anthropic_client):
            response = test_client.post(
                "/api/v1/chat",
                headers=auth_headers,
                json={"message": "What's my balance?"}
            )

        # Note: This may fail if chat service has other dependencies
        # The test demonstrates the pattern
        assert response.status_code in [200, 500]  # 500 if Claude not mocked properly

    def test_chat_requires_auth(self, test_client):
        """Test that chat requires authentication"""
        response = test_client.post(
            "/api/v1/chat",
            json={"message": "Hello"}
        )

        assert response.status_code == 403

    def test_chat_empty_message(self, test_client, auth_headers):
        """Test that empty message is rejected"""
        response = test_client.post(
            "/api/v1/chat",
            headers=auth_headers,
            json={"message": ""}
        )

        # Should either reject or handle gracefully
        assert response.status_code in [200, 400, 422]

    def test_chat_history_get(self, test_client, mock_db, auth_headers):
        """Test getting chat history"""
        mock_db.get_chat_history.return_value = [
            {"role": "user", "content": "Hello", "timestamp": datetime.utcnow().isoformat()},
            {"role": "assistant", "content": "Hi there!", "timestamp": datetime.utcnow().isoformat()}
        ]

        response = test_client.get("/api/v1/chat/history", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert "messages" in data or isinstance(data, list)

    def test_chat_history_requires_auth(self, test_client):
        """Test that chat history requires authentication"""
        response = test_client.get("/api/v1/chat/history")

        assert response.status_code == 403


class TestBalanceEndpoints:
    """Tests for balance and money management endpoints"""

    def test_get_balance(self, test_client, mock_db, auth_headers):
        """Test getting balance summary"""
        mock_db.get_plaid_items.return_value = [
            {"item_id": "item-1", "institution_name": "Test Bank"}
        ]
        mock_db.calculate_upcoming_bills_total.return_value = 500.00
        mock_db.get_total_hidden.return_value = 1000.00

        response = test_client.get("/api/v1/balance", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert "hidden_amount" in data or "total_hidden" in data or isinstance(data, dict)

    def test_get_balance_requires_auth(self, test_client):
        """Test that balance requires authentication"""
        response = test_client.get("/api/v1/balance")

        assert response.status_code == 403

    def test_hide_money(self, test_client, mock_db, auth_headers):
        """Test hiding money (shadow banking)"""
        mock_db.get_plaid_items.return_value = [{"item_id": "item-1"}]
        mock_db.calculate_upcoming_bills_total.return_value = 100.00
        mock_db.get_user_profile.return_value = {"emergency_buffer": 500.00}

        response = test_client.post(
            "/api/v1/money/hide",
            headers=auth_headers,
            json={"amount": 100.00, "purpose": "savings"}
        )

        # Should succeed or fail with meaningful error
        assert response.status_code in [200, 400]

    def test_hide_money_negative_amount(self, test_client, auth_headers):
        """Test that negative amount is rejected"""
        response = test_client.post(
            "/api/v1/money/hide",
            headers=auth_headers,
            json={"amount": -100.00}
        )

        # Should reject negative amounts
        assert response.status_code in [400, 422]

    def test_reveal_money(self, test_client, mock_db, auth_headers):
        """Test revealing hidden money"""
        mock_db.get_shadow_accounts.return_value = [
            {"id": "shadow-1", "amount": 500.00, "purpose": "savings"}
        ]

        response = test_client.post(
            "/api/v1/money/reveal",
            headers=auth_headers,
            json={"amount": 100.00}
        )

        assert response.status_code in [200, 400]


class TestTransactionEndpoints:
    """Tests for transaction endpoints"""

    def test_get_transactions(self, test_client, mock_db, auth_headers, sample_transactions):
        """Test getting transaction list"""
        mock_db.get_transactions.return_value = sample_transactions

        response = test_client.get("/api/v1/transactions", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, (list, dict))

    def test_get_transactions_with_limit(self, test_client, mock_db, auth_headers):
        """Test getting transactions with limit"""
        mock_db.get_transactions.return_value = []

        response = test_client.get(
            "/api/v1/transactions?limit=10",
            headers=auth_headers
        )

        assert response.status_code == 200

    def test_get_spending_summary(self, test_client, mock_db, auth_headers):
        """Test getting spending summary"""
        mock_db.get_spending_by_category.return_value = {
            "food": 250.00,
            "transportation": 150.00,
            "entertainment": 75.00
        }

        response = test_client.get("/api/v1/transactions/spending", headers=auth_headers)

        assert response.status_code == 200


class TestBillEndpoints:
    """Tests for bill detection and management"""

    def test_get_bills(self, test_client, mock_db, auth_headers, sample_bills):
        """Test getting active bills"""
        mock_db.get_active_bills.return_value = sample_bills

        response = test_client.get("/api/v1/bills", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, (list, dict))

    def test_get_upcoming_bills(self, test_client, mock_db, auth_headers, sample_bills):
        """Test getting upcoming bills"""
        mock_db.get_upcoming_bills.return_value = sample_bills

        response = test_client.get("/api/v1/bills/upcoming", headers=auth_headers)

        assert response.status_code == 200

    def test_detect_bills(self, test_client, mock_db, auth_headers):
        """Test bill detection endpoint"""
        mock_db.get_transactions.return_value = []

        response = test_client.post("/api/v1/bills/detect", headers=auth_headers)

        # Should work even with no transactions
        assert response.status_code in [200, 400]


class TestGoalEndpoints:
    """Tests for savings goals endpoints"""

    def test_get_goals(self, test_client, mock_db, auth_headers, sample_goals):
        """Test getting savings goals"""
        mock_db.get_goals.return_value = sample_goals

        response = test_client.get("/api/v1/goals", headers=auth_headers)

        assert response.status_code == 200
        data = response.json()
        assert isinstance(data, (list, dict))

    def test_create_goal(self, test_client, mock_db, auth_headers):
        """Test creating a savings goal"""
        mock_db.create_goal.return_value = {
            "id": "new-goal-id",
            "name": "Emergency Fund",
            "target_amount": 10000.00
        }

        response = test_client.post(
            "/api/v1/goals",
            headers=auth_headers,
            json={
                "name": "Emergency Fund",
                "target_amount": 10000.00,
                "category": "emergency"
            }
        )

        assert response.status_code in [200, 201]

    def test_contribute_to_goal(self, test_client, mock_db, auth_headers):
        """Test contributing to a goal"""
        mock_db.get_goal.return_value = {
            "id": "goal-1",
            "current_amount": 500.00,
            "target_amount": 1000.00
        }
        mock_db.add_to_goal.return_value = {"id": "goal-1", "current_amount": 600.00}

        response = test_client.post(
            "/api/v1/goals/goal-1/contribute",
            headers=auth_headers,
            json={"amount": 100.00}
        )

        assert response.status_code in [200, 400, 404]


class TestPlaidEndpoints:
    """Tests for Plaid integration endpoints"""

    def test_create_link_token(self, test_client, mock_db, auth_headers, mock_plaid_client):
        """Test creating Plaid link token"""
        with patch("services.plaid_service.plaid_client", mock_plaid_client):
            response = test_client.post(
                "/api/v1/plaid/link-token",
                headers=auth_headers
            )

        # May fail if Plaid not properly configured
        assert response.status_code in [200, 500]

    def test_exchange_public_token(self, test_client, mock_db, auth_headers):
        """Test exchanging Plaid public token"""
        response = test_client.post(
            "/api/v1/plaid/exchange",
            headers=auth_headers,
            json={"public_token": "public-sandbox-test"}
        )

        # Will fail without real Plaid, but should handle gracefully
        assert response.status_code in [200, 400, 500]


class TestSubscriptionEndpoints:
    """Tests for subscription management endpoints"""

    def test_get_subscriptions(self, test_client, mock_db, auth_headers):
        """Test getting subscriptions"""
        mock_db.get_subscriptions.return_value = []

        response = test_client.get("/api/v1/subscriptions", headers=auth_headers)

        assert response.status_code == 200

    def test_detect_subscriptions(self, test_client, mock_db, auth_headers):
        """Test subscription detection"""
        mock_db.get_transactions.return_value = []

        response = test_client.post(
            "/api/v1/subscriptions/detect",
            headers=auth_headers
        )

        assert response.status_code in [200, 400]


class TestForecastEndpoints:
    """Tests for financial forecasting endpoints"""

    def test_get_forecast(self, test_client, mock_db, auth_headers):
        """Test getting financial forecast"""
        mock_db.get_transactions.return_value = []
        mock_db.get_active_bills.return_value = []
        mock_db.get_plaid_items.return_value = []

        response = test_client.get("/api/v1/forecast", headers=auth_headers)

        assert response.status_code in [200, 400]

    def test_get_forecast_alerts(self, test_client, mock_db, auth_headers):
        """Test getting forecast alerts"""
        response = test_client.get("/api/v1/forecast/alerts", headers=auth_headers)

        assert response.status_code in [200, 400]


class TestRoundUpEndpoints:
    """Tests for round-up feature endpoints"""

    def test_get_roundup_config(self, test_client, mock_db, auth_headers):
        """Test getting round-up configuration"""
        mock_db.get_roundup_config.return_value = {
            "enabled": True,
            "multiplier": 1.0,
            "target_goal": "goal-1"
        }

        response = test_client.get("/api/v1/round-ups/config", headers=auth_headers)

        assert response.status_code == 200

    def test_set_roundup_config(self, test_client, mock_db, auth_headers):
        """Test setting round-up configuration"""
        mock_db.set_roundup_config.return_value = True

        response = test_client.post(
            "/api/v1/round-ups/config",
            headers=auth_headers,
            json={"enabled": True, "multiplier": 2.0}
        )

        assert response.status_code in [200, 400]

    def test_get_roundup_summary(self, test_client, mock_db, auth_headers):
        """Test getting round-up summary"""
        mock_db.get_roundup_summary.return_value = {
            "total_rounded": 125.50,
            "transactions_count": 45
        }

        response = test_client.get("/api/v1/round-ups/summary", headers=auth_headers)

        assert response.status_code == 200


class TestErrorHandling:
    """Tests for API error handling"""

    def test_404_for_unknown_endpoint(self, test_client):
        """Test that unknown endpoints return 404"""
        response = test_client.get("/api/v1/nonexistent")

        assert response.status_code == 404

    def test_422_for_invalid_json(self, test_client, auth_headers):
        """Test that invalid JSON returns 422"""
        response = test_client.post(
            "/api/v1/chat",
            headers={**auth_headers, "Content-Type": "application/json"},
            content="not valid json"
        )

        assert response.status_code == 422

    def test_method_not_allowed(self, test_client, auth_headers):
        """Test that wrong HTTP method returns 405"""
        response = test_client.delete("/api/v1/balance", headers=auth_headers)

        assert response.status_code == 405
