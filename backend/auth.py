"""
Authentication module for FURG
Handles Sign in with Apple verification and JWT token management
"""

import os
from datetime import datetime, timedelta
from typing import Optional
import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from jose import jwt, JWTError, jwk
from jose.utils import base64url_decode
import json

security = HTTPBearer()

# Configuration
JWT_SECRET = os.getenv("JWT_SECRET", "your-super-secret-key-change-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION_DAYS = 30
APPLE_CLIENT_ID = os.getenv("APPLE_CLIENT_ID", "com.furg.app")

# Apple's public keys cache
_apple_keys_cache = None
_keys_cache_time = None
KEYS_CACHE_DURATION = 3600  # 1 hour


async def get_apple_public_keys():
    """Fetch and cache Apple's public keys for token verification"""
    global _apple_keys_cache, _keys_cache_time

    # Check cache
    if _apple_keys_cache and _keys_cache_time:
        if (datetime.utcnow() - _keys_cache_time).total_seconds() < KEYS_CACHE_DURATION:
            return _apple_keys_cache

    # Fetch new keys
    async with httpx.AsyncClient() as client:
        try:
            response = await client.get("https://appleid.apple.com/auth/keys")
            response.raise_for_status()
            keys_data = response.json()
            _apple_keys_cache = keys_data["keys"]
            _keys_cache_time = datetime.utcnow()
            return _apple_keys_cache
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Failed to fetch Apple public keys: {str(e)}"
            )


async def verify_apple_token(token: str) -> dict:
    """
    Verify Apple ID token and extract user information

    Args:
        token: Apple ID token from client

    Returns:
        dict with user info: {"sub": apple_user_id, "email": email}

    Raises:
        HTTPException: If token is invalid
    """
    try:
        # Decode header to get key ID
        headers = jwt.get_unverified_header(token)
        kid = headers.get("kid")

        if not kid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Apple token: missing key ID"
            )

        # Get Apple's public keys
        apple_keys = await get_apple_public_keys()

        # Find the key matching the token's kid
        public_key = None
        for key in apple_keys:
            if key.get("kid") == kid:
                public_key = key
                break

        if not public_key:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Apple token: key not found"
            )

        # Construct the public key
        rsa_key = jwk.construct(public_key)

        # Decode and verify the token
        decoded = jwt.decode(
            token,
            rsa_key,
            algorithms=["RS256"],
            audience=APPLE_CLIENT_ID,
            options={"verify_aud": False}  # Make audience verification optional for flexibility
        )

        # Verify expiration
        exp = decoded.get("exp")
        if exp and datetime.utcnow().timestamp() > exp:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Apple token expired"
            )

        return {
            "sub": decoded["sub"],  # Apple user ID
            "email": decoded.get("email"),
            "email_verified": decoded.get("email_verified", False)
        }

    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid Apple token: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token verification failed: {str(e)}"
        )


def create_jwt_token(user_id: str, additional_claims: Optional[dict] = None) -> str:
    """
    Create a JWT token for authenticated user

    Args:
        user_id: Internal user UUID
        additional_claims: Optional additional claims to include

    Returns:
        JWT token string
    """
    expiration = datetime.utcnow() + timedelta(days=JWT_EXPIRATION_DAYS)

    payload = {
        "user_id": user_id,
        "exp": expiration,
        "iat": datetime.utcnow(),
        "type": "access"
    }

    if additional_claims:
        payload.update(additional_claims)

    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> str:
    """
    Extract and verify user ID from JWT token

    Used as FastAPI dependency for protected endpoints

    Args:
        credentials: HTTP Authorization header

    Returns:
        User ID (UUID as string)

    Raises:
        HTTPException: If token is invalid or expired
    """
    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM]
        )

        user_id = payload.get("user_id")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token: missing user ID"
            )

        # Check expiration (jose already validates exp, but double-check)
        exp = payload.get("exp")
        if exp and datetime.utcnow().timestamp() > exp:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token expired"
            )

        return user_id

    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Invalid token: {str(e)}"
        )


async def get_optional_user(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(HTTPBearer(auto_error=False))
) -> Optional[str]:
    """
    Extract user ID from token if present, otherwise return None

    Used for endpoints that work both authenticated and unauthenticated

    Args:
        credentials: HTTP Authorization header (optional)

    Returns:
        User ID if authenticated, None otherwise
    """
    if not credentials:
        return None

    try:
        return await get_current_user(credentials)
    except HTTPException:
        return None


def verify_jwt_token(token: str) -> dict:
    """
    Verify and decode a JWT token without FastAPI dependency

    Args:
        token: JWT token string

    Returns:
        Decoded payload

    Raises:
        JWTError: If token is invalid
    """
    return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])


# Rate limiting helpers (used in rate_limiter.py)

def get_user_from_token(token: str) -> Optional[str]:
    """Extract user ID from token without validation (for rate limiting)"""
    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],
            options={"verify_exp": False}  # Don't fail on expired tokens for rate limit checking
        )
        return payload.get("user_id")
    except:
        return None


# Development/Testing helpers

def create_test_token(user_id: str = "test-user-123") -> str:
    """Create a test token for development (DO NOT use in production)"""
    if os.getenv("DEBUG", "false").lower() != "true":
        raise RuntimeError("Test tokens only available in debug mode")

    return create_jwt_token(user_id)


async def verify_test_apple_token(token: str) -> dict:
    """
    Mock Apple token verification for testing
    Only active when DEBUG=true
    """
    if os.getenv("DEBUG", "false").lower() != "true":
        raise RuntimeError("Test verification only available in debug mode")

    # In test mode, accept tokens in format "test_apple_<user_id>"
    if token.startswith("test_apple_"):
        apple_user_id = token.replace("test_apple_", "")
        return {
            "sub": apple_user_id,
            "email": f"{apple_user_id}@test.com",
            "email_verified": True
        }

    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid test token format"
    )
