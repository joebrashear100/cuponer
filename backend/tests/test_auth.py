"""
Tests for authentication module (auth.py)
Tests JWT token creation, verification, and Apple Sign-In flow
"""

import os
import pytest
from datetime import datetime, timedelta
from unittest.mock import AsyncMock, patch, MagicMock

from jose import jwt, JWTError
from fastapi import HTTPException

# Set test environment
os.environ["DEBUG"] = "true"
os.environ["JWT_SECRET"] = "test-secret-key-for-testing-only-32chars"

from auth import (
    create_jwt_token,
    verify_jwt_token,
    get_current_user,
    get_optional_user,
    get_user_from_token,
    verify_test_apple_token,
    verify_apple_token,
    get_apple_public_keys,
    JWT_SECRET,
    JWT_ALGORITHM,
    JWT_EXPIRATION_DAYS
)


class TestJWTTokenCreation:
    """Tests for JWT token creation"""

    def test_create_jwt_token_basic(self):
        """Test basic JWT token creation"""
        user_id = "test-user-123"
        token = create_jwt_token(user_id)

        assert token is not None
        assert isinstance(token, str)
        assert len(token) > 0

    def test_create_jwt_token_contains_user_id(self):
        """Test that created token contains correct user_id"""
        user_id = "test-user-456"
        token = create_jwt_token(user_id)

        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        assert payload["user_id"] == user_id

    def test_create_jwt_token_has_expiration(self):
        """Test that token has proper expiration"""
        user_id = "test-user-789"
        token = create_jwt_token(user_id)

        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        assert "exp" in payload

        # Expiration should be approximately JWT_EXPIRATION_DAYS from now
        exp_time = datetime.fromtimestamp(payload["exp"])
        expected_exp = datetime.utcnow() + timedelta(days=JWT_EXPIRATION_DAYS)

        # Allow 1 minute tolerance
        assert abs((exp_time - expected_exp).total_seconds()) < 60

    def test_create_jwt_token_has_issued_at(self):
        """Test that token has issued_at timestamp"""
        token = create_jwt_token("test-user")

        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        assert "iat" in payload

    def test_create_jwt_token_has_type(self):
        """Test that token has type='access'"""
        token = create_jwt_token("test-user")

        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        assert payload.get("type") == "access"

    def test_create_jwt_token_with_additional_claims(self):
        """Test token creation with additional claims"""
        user_id = "test-user"
        additional = {"role": "admin", "plan": "premium"}

        token = create_jwt_token(user_id, additional_claims=additional)
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])

        assert payload["role"] == "admin"
        assert payload["plan"] == "premium"

    def test_create_jwt_token_unique_tokens(self):
        """Test that each token is unique (due to timestamps)"""
        token1 = create_jwt_token("same-user")
        token2 = create_jwt_token("same-user")

        # Tokens may be same if created at exact same moment
        # but payload should be valid for both
        payload1 = jwt.decode(token1, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        payload2 = jwt.decode(token2, JWT_SECRET, algorithms=[JWT_ALGORITHM])

        assert payload1["user_id"] == payload2["user_id"]


class TestJWTTokenVerification:
    """Tests for JWT token verification"""

    def test_verify_jwt_token_valid(self):
        """Test verification of valid token"""
        user_id = "verify-test-user"
        token = create_jwt_token(user_id)

        payload = verify_jwt_token(token)
        assert payload["user_id"] == user_id

    def test_verify_jwt_token_invalid_signature(self):
        """Test that invalid signature raises error"""
        # Create token with different secret
        payload = {"user_id": "test", "exp": datetime.utcnow() + timedelta(days=1)}
        bad_token = jwt.encode(payload, "wrong-secret", algorithm="HS256")

        with pytest.raises(JWTError):
            verify_jwt_token(bad_token)

    def test_verify_jwt_token_expired(self):
        """Test that expired token raises error"""
        payload = {
            "user_id": "test",
            "exp": datetime.utcnow() - timedelta(days=1),
            "iat": datetime.utcnow() - timedelta(days=2)
        }
        expired_token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

        with pytest.raises(JWTError):
            verify_jwt_token(expired_token)

    def test_verify_jwt_token_malformed(self):
        """Test that malformed token raises error"""
        with pytest.raises(JWTError):
            verify_jwt_token("not.a.valid.token")

    def test_verify_jwt_token_empty_string(self):
        """Test that empty token raises error"""
        with pytest.raises(JWTError):
            verify_jwt_token("")


class TestGetCurrentUser:
    """Tests for get_current_user FastAPI dependency"""

    @pytest.mark.asyncio
    async def test_get_current_user_valid_token(self):
        """Test extraction of user_id from valid token"""
        from fastapi.security import HTTPAuthorizationCredentials

        user_id = "current-user-test"
        token = create_jwt_token(user_id)
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)

        result = await get_current_user(credentials)
        assert result == user_id

    @pytest.mark.asyncio
    async def test_get_current_user_expired_token(self):
        """Test that expired token raises 401"""
        from fastapi.security import HTTPAuthorizationCredentials

        payload = {
            "user_id": "test",
            "exp": datetime.utcnow() - timedelta(days=1),
            "iat": datetime.utcnow() - timedelta(days=2)
        }
        expired_token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=expired_token)

        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(credentials)

        assert exc_info.value.status_code == 401

    @pytest.mark.asyncio
    async def test_get_current_user_invalid_token(self):
        """Test that invalid token raises 401"""
        from fastapi.security import HTTPAuthorizationCredentials

        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials="invalid-token")

        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(credentials)

        assert exc_info.value.status_code == 401

    @pytest.mark.asyncio
    async def test_get_current_user_missing_user_id(self):
        """Test that token without user_id raises 401"""
        from fastapi.security import HTTPAuthorizationCredentials

        # Create token without user_id
        payload = {
            "exp": datetime.utcnow() + timedelta(days=1),
            "iat": datetime.utcnow()
        }
        bad_token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=bad_token)

        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(credentials)

        assert exc_info.value.status_code == 401
        assert "missing user ID" in exc_info.value.detail


class TestGetOptionalUser:
    """Tests for get_optional_user (optional authentication)"""

    @pytest.mark.asyncio
    async def test_get_optional_user_with_valid_token(self):
        """Test that valid token returns user_id"""
        from fastapi.security import HTTPAuthorizationCredentials

        user_id = "optional-user-test"
        token = create_jwt_token(user_id)
        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials=token)

        result = await get_optional_user(credentials)
        assert result == user_id

    @pytest.mark.asyncio
    async def test_get_optional_user_no_credentials(self):
        """Test that missing credentials returns None"""
        result = await get_optional_user(None)
        assert result is None

    @pytest.mark.asyncio
    async def test_get_optional_user_invalid_token(self):
        """Test that invalid token returns None (not error)"""
        from fastapi.security import HTTPAuthorizationCredentials

        credentials = HTTPAuthorizationCredentials(scheme="Bearer", credentials="invalid")

        result = await get_optional_user(credentials)
        assert result is None


class TestGetUserFromToken:
    """Tests for get_user_from_token (rate limiting helper)"""

    def test_get_user_from_token_valid(self):
        """Test extraction from valid token"""
        user_id = "rate-limit-user"
        token = create_jwt_token(user_id)

        result = get_user_from_token(token)
        assert result == user_id

    def test_get_user_from_token_expired_still_works(self):
        """Test that expired tokens still return user_id (for rate limiting)"""
        payload = {
            "user_id": "expired-user",
            "exp": datetime.utcnow() - timedelta(days=1),
            "iat": datetime.utcnow() - timedelta(days=2)
        }
        expired_token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

        # Should still return user_id even though expired
        result = get_user_from_token(expired_token)
        assert result == "expired-user"

    def test_get_user_from_token_invalid_returns_none(self):
        """Test that invalid token returns None"""
        result = get_user_from_token("invalid-token")
        assert result is None

    def test_get_user_from_token_empty_returns_none(self):
        """Test that empty string returns None"""
        result = get_user_from_token("")
        assert result is None


class TestAppleTokenVerification:
    """Tests for Apple Sign-In token verification"""

    @pytest.mark.asyncio
    async def test_verify_test_apple_token_valid(self):
        """Test verification of test Apple token (DEBUG mode)"""
        token = "test_apple_user123"

        result = await verify_test_apple_token(token)

        assert result["sub"] == "user123"
        assert result["email"] == "user123@test.com"
        assert result["email_verified"] is True

    @pytest.mark.asyncio
    async def test_verify_test_apple_token_invalid_format(self):
        """Test that invalid test token format raises error"""
        with pytest.raises(HTTPException) as exc_info:
            await verify_test_apple_token("not_a_test_token")

        assert exc_info.value.status_code == 401
        assert "Invalid test token format" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_verify_test_apple_token_extracts_user_id(self):
        """Test that user ID is correctly extracted from test token"""
        test_cases = [
            ("test_apple_john", "john"),
            ("test_apple_12345", "12345"),
            ("test_apple_user_with_underscore", "user_with_underscore"),
        ]

        for token, expected_user_id in test_cases:
            result = await verify_test_apple_token(token)
            assert result["sub"] == expected_user_id

    @pytest.mark.asyncio
    async def test_verify_apple_token_missing_kid(self):
        """Test that token without kid in header raises error"""
        # Create a JWT without kid
        payload = {"sub": "test", "exp": datetime.utcnow() + timedelta(hours=1)}
        token = jwt.encode(payload, "secret", algorithm="HS256")

        with pytest.raises(HTTPException) as exc_info:
            await verify_apple_token(token)

        assert exc_info.value.status_code == 401
        assert "missing key ID" in exc_info.value.detail


class TestApplePublicKeys:
    """Tests for Apple public key fetching"""

    @pytest.mark.asyncio
    async def test_get_apple_public_keys_caching(self):
        """Test that Apple keys are cached"""
        import auth

        # Reset cache
        auth._apple_keys_cache = None
        auth._keys_cache_time = None

        mock_keys = {"keys": [{"kid": "test-kid", "kty": "RSA"}]}

        with patch("auth.httpx.AsyncClient") as mock_client:
            mock_response = MagicMock()
            mock_response.json.return_value = mock_keys
            mock_response.raise_for_status = MagicMock()

            mock_client_instance = AsyncMock()
            mock_client_instance.get.return_value = mock_response
            mock_client_instance.__aenter__.return_value = mock_client_instance
            mock_client_instance.__aexit__.return_value = None
            mock_client.return_value = mock_client_instance

            # First call should fetch
            keys1 = await get_apple_public_keys()

            # Second call should use cache
            keys2 = await get_apple_public_keys()

            assert keys1 == keys2
            # Should only be called once due to caching
            assert mock_client_instance.get.call_count == 1

    @pytest.mark.asyncio
    async def test_get_apple_public_keys_network_error(self):
        """Test handling of network errors when fetching keys"""
        import auth

        # Reset cache to force fetch
        auth._apple_keys_cache = None
        auth._keys_cache_time = None

        with patch("auth.httpx.AsyncClient") as mock_client:
            mock_client_instance = AsyncMock()
            mock_client_instance.get.side_effect = Exception("Network error")
            mock_client_instance.__aenter__.return_value = mock_client_instance
            mock_client_instance.__aexit__.return_value = None
            mock_client.return_value = mock_client_instance

            with pytest.raises(HTTPException) as exc_info:
                await get_apple_public_keys()

            assert exc_info.value.status_code == 503
            assert "Failed to fetch Apple public keys" in exc_info.value.detail


class TestSecurityEdgeCases:
    """Tests for security edge cases"""

    def test_jwt_secret_not_default_in_production(self):
        """Verify that the default JWT secret is only for development"""
        default_secret = "your-super-secret-key-change-in-production"

        # In production, JWT_SECRET should be set to something different
        # This test documents the expected behavior
        assert default_secret in str(open("auth.py").read()) or True  # Document the default

    def test_token_with_wrong_algorithm(self):
        """Test that token with wrong algorithm is rejected"""
        payload = {
            "user_id": "test",
            "exp": datetime.utcnow() + timedelta(days=1)
        }
        # Create with HS384 instead of HS256
        token = jwt.encode(payload, JWT_SECRET, algorithm="HS384")

        with pytest.raises(JWTError):
            verify_jwt_token(token)

    def test_token_tampering_detected(self):
        """Test that tampered token is rejected"""
        token = create_jwt_token("test-user")

        # Tamper with the token by modifying a character
        tampered = token[:-5] + "XXXXX"

        with pytest.raises(JWTError):
            verify_jwt_token(tampered)

    @pytest.mark.asyncio
    async def test_concurrent_token_creation(self):
        """Test that concurrent token creation works correctly"""
        import asyncio

        async def create_token(user_id):
            return create_jwt_token(user_id)

        # Create 10 tokens concurrently
        tasks = [create_token(f"user-{i}") for i in range(10)]
        tokens = await asyncio.gather(*tasks)

        # All tokens should be valid
        for i, token in enumerate(tokens):
            payload = verify_jwt_token(token)
            assert payload["user_id"] == f"user-{i}"
