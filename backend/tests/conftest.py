"""
Pytest fixtures and configuration for FURG backend tests
"""

import os
import sys
from datetime import datetime, timedelta
from typing import AsyncGenerator, Generator
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient
from httpx import AsyncClient, ASGITransport

# Add backend directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Set test environment before importing modules
os.environ["DEBUG"] = "true"
os.environ["JWT_SECRET"] = "test-secret-key-for-testing-only-32chars"
os.environ["DATABASE_URL"] = "postgresql://test:test@localhost:5432/test_db"


# ==================== DATABASE FIXTURES ====================

@pytest.fixture
def mock_db():
    """Create a mock database instance"""
    db_mock = AsyncMock()

    # Default return values for common operations
    db_mock.get_or_create_user.return_value = {
        "id": "test-user-uuid-1234",
        "apple_id": "apple-user-123",
        "email": "test@example.com",
        "created_at": datetime.utcnow()
    }

    db_mock.get_user.return_value = {
        "id": "test-user-uuid-1234",
        "apple_id": "apple-user-123",
        "email": "test@example.com",
        "created_at": datetime.utcnow() - timedelta(days=30)
    }

    db_mock.get_user_profile.return_value = {
        "user_id": "test-user-uuid-1234",
        "intensity_mode": "moderate",
        "emergency_buffer": 500.00,
        "savings_goal": None,
        "spending_preferences": {}
    }

    db_mock.get_user_api_usage_today.return_value = {
        "requests": 5,
        "input_tokens": 1000,
        "output_tokens": 2000,
        "total_cost": "0.50"
    }

    db_mock.get_transactions.return_value = []
    db_mock.get_active_bills.return_value = []
    db_mock.get_upcoming_bills.return_value = []
    db_mock.calculate_upcoming_bills_total.return_value = 0.0
    db_mock.get_total_hidden.return_value = 0.0
    db_mock.get_plaid_items.return_value = []
    db_mock.get_goals.return_value = []

    return db_mock


@pytest.fixture
def mock_db_connection():
    """Mock database connection for connection pool testing"""
    conn_mock = AsyncMock()
    conn_mock.fetchval.return_value = 1
    conn_mock.fetchrow.return_value = {"id": "test-id"}
    conn_mock.fetch.return_value = []
    conn_mock.execute.return_value = None
    return conn_mock


# ==================== AUTH FIXTURES ====================

@pytest.fixture
def valid_jwt_token():
    """Generate a valid JWT token for testing"""
    from auth import create_jwt_token
    return create_jwt_token("test-user-uuid-1234")


@pytest.fixture
def expired_jwt_token():
    """Generate an expired JWT token for testing"""
    from jose import jwt
    from auth import JWT_SECRET, JWT_ALGORITHM

    payload = {
        "user_id": "test-user-uuid-1234",
        "exp": datetime.utcnow() - timedelta(days=1),
        "iat": datetime.utcnow() - timedelta(days=2),
        "type": "access"
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


@pytest.fixture
def test_apple_token():
    """Generate a test Apple token"""
    return "test_apple_user123"


@pytest.fixture
def auth_headers(valid_jwt_token):
    """Generate authorization headers for authenticated requests"""
    return {"Authorization": f"Bearer {valid_jwt_token}"}


# ==================== API CLIENT FIXTURES ====================

@pytest.fixture
def test_client(mock_db) -> Generator[TestClient, None, None]:
    """Create synchronous test client with mocked database"""
    with patch("main.db", mock_db), \
         patch("rate_limiter.db", mock_db):
        from main import app
        with TestClient(app) as client:
            yield client


@pytest.fixture
async def async_client(mock_db) -> AsyncGenerator[AsyncClient, None]:
    """Create async test client with mocked database"""
    with patch("main.db", mock_db), \
         patch("rate_limiter.db", mock_db):
        from main import app
        transport = ASGITransport(app=app)
        async with AsyncClient(transport=transport, base_url="http://test") as client:
            yield client


# ==================== SERVICE FIXTURES ====================

@pytest.fixture
def mock_anthropic_client():
    """Mock Anthropic Claude API client"""
    client_mock = MagicMock()

    # Mock message response
    message_mock = MagicMock()
    message_mock.content = [MagicMock(text="This is a roast response from FURG")]
    message_mock.usage = MagicMock(input_tokens=100, output_tokens=50)

    client_mock.messages.create.return_value = message_mock

    return client_mock


@pytest.fixture
def mock_plaid_client():
    """Mock Plaid API client"""
    client_mock = MagicMock()

    # Mock link token creation
    client_mock.link_token_create.return_value = MagicMock(
        link_token="link-sandbox-test-token"
    )

    # Mock public token exchange
    client_mock.item_public_token_exchange.return_value = MagicMock(
        access_token="access-sandbox-test-token",
        item_id="item-sandbox-test-id"
    )

    # Mock accounts get
    client_mock.accounts_get.return_value = MagicMock(
        accounts=[
            MagicMock(
                account_id="acc-1",
                name="Checking Account",
                type="depository",
                subtype="checking",
                balances=MagicMock(current=1000.00, available=950.00)
            )
        ]
    )

    return client_mock


# ==================== SAMPLE DATA FIXTURES ====================

@pytest.fixture
def sample_transactions():
    """Sample transactions for testing"""
    return [
        {
            "id": "txn-1",
            "user_id": "test-user-uuid-1234",
            "amount": -47.50,
            "description": "UBER TRIP",
            "category": "transportation",
            "date": datetime.utcnow() - timedelta(days=1),
            "account_id": "acc-1"
        },
        {
            "id": "txn-2",
            "user_id": "test-user-uuid-1234",
            "amount": -12.99,
            "description": "NETFLIX.COM",
            "category": "entertainment",
            "date": datetime.utcnow() - timedelta(days=5),
            "account_id": "acc-1"
        },
        {
            "id": "txn-3",
            "user_id": "test-user-uuid-1234",
            "amount": 2500.00,
            "description": "PAYROLL DEPOSIT",
            "category": "income",
            "date": datetime.utcnow() - timedelta(days=7),
            "account_id": "acc-1"
        }
    ]


@pytest.fixture
def sample_bills():
    """Sample bills for testing"""
    return [
        {
            "id": "bill-1",
            "user_id": "test-user-uuid-1234",
            "merchant_name": "Netflix",
            "amount": 12.99,
            "frequency": "monthly",
            "next_due_date": datetime.utcnow() + timedelta(days=10),
            "category": "entertainment",
            "is_active": True
        },
        {
            "id": "bill-2",
            "user_id": "test-user-uuid-1234",
            "merchant_name": "Rent Payment",
            "amount": 1500.00,
            "frequency": "monthly",
            "next_due_date": datetime.utcnow() + timedelta(days=5),
            "category": "housing",
            "is_active": True
        }
    ]


@pytest.fixture
def sample_goals():
    """Sample savings goals for testing"""
    return [
        {
            "id": "goal-1",
            "user_id": "test-user-uuid-1234",
            "name": "Emergency Fund",
            "target_amount": 10000.00,
            "current_amount": 2500.00,
            "deadline": datetime.utcnow() + timedelta(days=365),
            "category": "emergency"
        },
        {
            "id": "goal-2",
            "user_id": "test-user-uuid-1234",
            "name": "Vacation",
            "target_amount": 3000.00,
            "current_amount": 750.00,
            "deadline": datetime.utcnow() + timedelta(days=180),
            "category": "travel"
        }
    ]


# ==================== UTILITY FUNCTIONS ====================

def assert_http_error(response, status_code: int, detail_contains: str = None):
    """Helper to assert HTTP error responses"""
    assert response.status_code == status_code
    if detail_contains:
        assert detail_contains.lower() in response.json().get("detail", "").lower()
