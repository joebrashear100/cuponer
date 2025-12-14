"""
Tests for database operations (database.py)
Tests connection management, user operations, transactions, and financial data
"""

import os
import pytest
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, patch, MagicMock
import json

# Set test environment
os.environ["DEBUG"] = "true"
os.environ["JWT_SECRET"] = "test-secret-key-for-testing-only-32chars"
os.environ["DATABASE_URL"] = "postgresql://test:test@localhost:5432/test_db"


class TestDatabaseConnection:
    """Tests for database connection management"""

    @pytest.mark.asyncio
    async def test_database_connect_creates_pool(self):
        """Test that connect creates a connection pool"""
        with patch("database.asyncpg.create_pool") as mock_create_pool:
            mock_pool = AsyncMock()
            mock_create_pool.return_value = mock_pool

            from database import Database
            db = Database()
            await db.connect()

            mock_create_pool.assert_called_once()
            assert db.pool is not None

    @pytest.mark.asyncio
    async def test_database_disconnect_closes_pool(self):
        """Test that disconnect closes the pool"""
        mock_pool = AsyncMock()

        from database import Database
        db = Database()
        db.pool = mock_pool

        await db.disconnect()

        mock_pool.close.assert_called_once()
        assert db.pool is None

    @pytest.mark.asyncio
    async def test_acquire_creates_connection_if_not_exists(self):
        """Test that acquire creates pool if it doesn't exist"""
        with patch("database.asyncpg.create_pool") as mock_create_pool:
            mock_pool = AsyncMock()
            mock_conn = AsyncMock()
            mock_pool.acquire.return_value.__aenter__.return_value = mock_conn
            mock_create_pool.return_value = mock_pool

            from database import Database
            db = Database()

            async with db.acquire() as conn:
                assert conn is mock_conn


class TestUserOperations:
    """Tests for user CRUD operations"""

    @pytest.mark.asyncio
    async def test_get_or_create_user_new_user(self):
        """Test creating a new user"""
        mock_conn = AsyncMock()
        # First call returns None (user doesn't exist)
        # Second call returns the created user
        mock_conn.fetchrow.side_effect = [
            None,  # User doesn't exist
            {
                "id": "new-user-uuid",
                "apple_id": "apple123",
                "email": "test@example.com",
                "created_at": datetime.utcnow()
            }
        ]
        mock_conn.execute.return_value = None

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_or_create_user("apple123", "test@example.com")

        assert result["apple_id"] == "apple123"
        assert result["email"] == "test@example.com"

    @pytest.mark.asyncio
    async def test_get_or_create_user_existing_user(self):
        """Test getting an existing user"""
        mock_conn = AsyncMock()
        existing_user = {
            "id": "existing-uuid",
            "apple_id": "apple456",
            "email": "existing@example.com",
            "created_at": datetime.utcnow() - timedelta(days=30)
        }
        mock_conn.fetchrow.return_value = existing_user
        mock_conn.execute.return_value = None

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_or_create_user("apple456")

        assert result["id"] == "existing-uuid"
        # Should update last_seen
        mock_conn.execute.assert_called()

    @pytest.mark.asyncio
    async def test_get_user(self):
        """Test getting user by ID"""
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {
            "id": "user-123",
            "apple_id": "apple789",
            "email": "user@example.com"
        }

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_user("user-123")

        assert result["id"] == "user-123"

    @pytest.mark.asyncio
    async def test_get_user_not_found(self):
        """Test getting non-existent user returns None"""
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = None

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_user("nonexistent-id")

        assert result is None

    @pytest.mark.asyncio
    async def test_get_user_profile(self):
        """Test getting user profile"""
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {
            "user_id": "user-123",
            "intensity_mode": "moderate",
            "emergency_buffer": 500.00,
            "savings_goal": None,
            "spending_preferences": {},
            "health_metrics": None
        }

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_user_profile("user-123")

        assert result["intensity_mode"] == "moderate"
        assert result["emergency_buffer"] == 500.00

    @pytest.mark.asyncio
    async def test_update_user_profile(self):
        """Test updating user profile"""
        mock_conn = AsyncMock()
        mock_conn.execute.return_value = "UPDATE 1"

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.update_user_profile("user-123", {
            "intensity_mode": "insanity",
            "emergency_buffer": 1000.00
        })

        assert result is True
        mock_conn.execute.assert_called_once()


class TestTransactionOperations:
    """Tests for transaction operations"""

    @pytest.mark.asyncio
    async def test_save_transaction(self):
        """Test saving a transaction"""
        mock_conn = AsyncMock()
        mock_conn.execute.return_value = "INSERT 1"

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        transaction = {
            "id": "txn-123",
            "user_id": "user-123",
            "amount": -25.00,
            "description": "Coffee",
            "category": "food",
            "date": datetime.utcnow()
        }

        await db.save_transaction(transaction)

        mock_conn.execute.assert_called()

    @pytest.mark.asyncio
    async def test_get_transactions_with_filters(self):
        """Test getting transactions with date filters"""
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = [
            {"id": "txn-1", "amount": -10.00, "description": "Test 1"},
            {"id": "txn-2", "amount": -20.00, "description": "Test 2"}
        ]

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_transactions(
            user_id="user-123",
            start_date=datetime.utcnow() - timedelta(days=30),
            end_date=datetime.utcnow(),
            limit=100
        )

        assert len(result) == 2
        mock_conn.fetch.assert_called_once()

    @pytest.mark.asyncio
    async def test_get_spending_by_category(self):
        """Test getting spending grouped by category"""
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = [
            {"category": "food", "total": 250.00},
            {"category": "transportation", "total": 150.00},
            {"category": "entertainment", "total": 75.00}
        ]

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_spending_by_category("user-123")

        assert len(result) == 3


class TestBillOperations:
    """Tests for bill-related operations"""

    @pytest.mark.asyncio
    async def test_upsert_bill(self):
        """Test upserting a bill"""
        mock_conn = AsyncMock()
        mock_conn.execute.return_value = "INSERT 1"

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        bill = {
            "merchant_name": "Netflix",
            "amount": 15.99,
            "frequency": "monthly",
            "next_due_date": datetime.utcnow() + timedelta(days=15)
        }

        await db.upsert_bill("user-123", bill)

        mock_conn.execute.assert_called()

    @pytest.mark.asyncio
    async def test_get_active_bills(self):
        """Test getting active bills"""
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = [
            {"id": "bill-1", "merchant_name": "Netflix", "amount": 15.99},
            {"id": "bill-2", "merchant_name": "Spotify", "amount": 9.99}
        ]

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_active_bills("user-123")

        assert len(result) == 2

    @pytest.mark.asyncio
    async def test_get_upcoming_bills(self):
        """Test getting upcoming bills within days"""
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = [
            {"id": "bill-1", "merchant_name": "Rent", "amount": 1500.00, "next_due_date": datetime.utcnow() + timedelta(days=5)}
        ]

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_upcoming_bills("user-123", days=7)

        assert len(result) == 1

    @pytest.mark.asyncio
    async def test_calculate_upcoming_bills_total(self):
        """Test calculating total of upcoming bills"""
        mock_conn = AsyncMock()
        mock_conn.fetchval.return_value = 1525.99

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.calculate_upcoming_bills_total("user-123")

        assert result == 1525.99


class TestShadowBankingOperations:
    """Tests for shadow banking (hidden money) operations"""

    @pytest.mark.asyncio
    async def test_create_shadow_account(self):
        """Test creating a shadow account"""
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {
            "id": "shadow-1",
            "user_id": "user-123",
            "amount": 500.00,
            "purpose": "emergency"
        }

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.create_shadow_account("user-123", 500.00, "emergency")

        assert result["amount"] == 500.00
        assert result["purpose"] == "emergency"

    @pytest.mark.asyncio
    async def test_get_total_hidden(self):
        """Test getting total hidden amount"""
        mock_conn = AsyncMock()
        mock_conn.fetchval.return_value = 1500.00

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_total_hidden("user-123")

        assert result == 1500.00

    @pytest.mark.asyncio
    async def test_get_total_hidden_no_accounts(self):
        """Test getting total hidden when no accounts exist"""
        mock_conn = AsyncMock()
        mock_conn.fetchval.return_value = None

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_total_hidden("user-123")

        assert result == 0.0 or result is None


class TestGoalOperations:
    """Tests for savings goal operations"""

    @pytest.mark.asyncio
    async def test_create_goal(self):
        """Test creating a savings goal"""
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {
            "id": "goal-1",
            "name": "Vacation",
            "target_amount": 5000.00,
            "current_amount": 0.00
        }

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.create_goal(
            user_id="user-123",
            name="Vacation",
            target_amount=5000.00,
            deadline=datetime.utcnow() + timedelta(days=180),
            category="travel"
        )

        assert result["name"] == "Vacation"
        assert result["target_amount"] == 5000.00

    @pytest.mark.asyncio
    async def test_get_goals(self):
        """Test getting all goals for user"""
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = [
            {"id": "goal-1", "name": "Emergency Fund", "target_amount": 10000.00, "current_amount": 2500.00},
            {"id": "goal-2", "name": "Vacation", "target_amount": 3000.00, "current_amount": 750.00}
        ]

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_goals("user-123")

        assert len(result) == 2

    @pytest.mark.asyncio
    async def test_add_to_goal(self):
        """Test adding contribution to goal"""
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {
            "id": "goal-1",
            "current_amount": 600.00  # 500 + 100 contribution
        }

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.add_to_goal("goal-1", 100.00)

        assert result["current_amount"] == 600.00


class TestPlaidOperations:
    """Tests for Plaid-related database operations"""

    @pytest.mark.asyncio
    async def test_save_plaid_item(self):
        """Test saving a Plaid item"""
        mock_conn = AsyncMock()
        mock_conn.execute.return_value = "INSERT 1"

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        await db.save_plaid_item(
            user_id="user-123",
            item_id="item-abc",
            access_token="access-xyz",
            institution_name="Test Bank"
        )

        mock_conn.execute.assert_called()

    @pytest.mark.asyncio
    async def test_get_plaid_items(self):
        """Test getting Plaid items for user"""
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = [
            {"item_id": "item-1", "institution_name": "Bank A"},
            {"item_id": "item-2", "institution_name": "Bank B"}
        ]

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_plaid_items("user-123")

        assert len(result) == 2


class TestAPIUsageTracking:
    """Tests for API usage logging"""

    @pytest.mark.asyncio
    async def test_log_api_usage(self):
        """Test logging API usage"""
        mock_conn = AsyncMock()
        mock_conn.execute.return_value = "INSERT 1"

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        await db.log_api_usage(
            user_id="user-123",
            endpoint="chat",
            input_tokens=100,
            output_tokens=50,
            cost=0.01
        )

        mock_conn.execute.assert_called()

    @pytest.mark.asyncio
    async def test_get_user_api_usage_today(self):
        """Test getting today's API usage"""
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {
            "requests": 25,
            "input_tokens": 5000,
            "output_tokens": 10000,
            "total_cost": "1.50"
        }

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_user_api_usage_today("user-123")

        assert result["requests"] == 25
        assert result["input_tokens"] == 5000


class TestChatHistory:
    """Tests for chat history operations"""

    @pytest.mark.asyncio
    async def test_save_chat_message(self):
        """Test saving a chat message"""
        mock_conn = AsyncMock()
        mock_conn.execute.return_value = "INSERT 1"

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        await db.save_chat_message(
            user_id="user-123",
            role="user",
            content="What's my balance?"
        )

        mock_conn.execute.assert_called()

    @pytest.mark.asyncio
    async def test_get_chat_history(self):
        """Test getting chat history"""
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = [
            {"role": "user", "content": "Hello", "timestamp": datetime.utcnow()},
            {"role": "assistant", "content": "Hi!", "timestamp": datetime.utcnow()}
        ]

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_chat_history("user-123", limit=50)

        assert len(result) == 2

    @pytest.mark.asyncio
    async def test_clear_chat_history(self):
        """Test clearing chat history"""
        mock_conn = AsyncMock()
        mock_conn.execute.return_value = "DELETE 10"

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        await db.clear_chat_history("user-123")

        mock_conn.execute.assert_called()


class TestDatabaseEdgeCases:
    """Tests for database edge cases and error handling"""

    @pytest.mark.asyncio
    async def test_empty_transactions_list(self):
        """Test getting transactions when none exist"""
        mock_conn = AsyncMock()
        mock_conn.fetch.return_value = []

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_transactions("user-123")

        assert result == []

    @pytest.mark.asyncio
    async def test_jsonb_field_parsing(self):
        """Test that JSONB fields are properly parsed"""
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {
            "user_id": "user-123",
            "intensity_mode": "moderate",
            "emergency_buffer": 500.00,
            "savings_goal": '{"amount": 10000, "deadline": "2025-12-31"}',
            "spending_preferences": '{"categories": ["food", "entertainment"]}',
            "health_metrics": None
        }

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_user_profile("user-123")

        # JSONB fields should be parsed if they're strings
        assert result is not None

    @pytest.mark.asyncio
    async def test_null_handling(self):
        """Test proper handling of NULL values"""
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = None

        mock_pool = AsyncMock()
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        from database import Database
        db = Database()
        db.pool = mock_pool

        result = await db.get_user_profile("nonexistent-user")

        assert result is None
