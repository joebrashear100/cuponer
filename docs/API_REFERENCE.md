# FURG API Reference

Complete API documentation for FURG backend.

Base URL (local): `http://localhost:8000`
Base URL (production): `https://api.furg.app`

## Authentication

All endpoints except `/health` and `/api/v1/auth/*` require JWT authentication.

Include JWT token in `Authorization` header:

```
Authorization: Bearer <your-jwt-token>
```

### POST /api/v1/auth/apple

Authenticate with Sign in with Apple.

**Request:**
```json
{
  "apple_token": "string",
  "user_identifier": "string (optional)"
}
```

**Response:**
```json
{
  "jwt": "eyJhbGc...",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "is_new_user": true
}
```

**Status Codes:**
- `200` - Success
- `401` - Invalid Apple token
- `503` - Apple service unavailable

---

## Chat

### POST /api/v1/chat

Send a message to FURG and get a response.

**Request:**
```json
{
  "message": "What's my balance?",
  "include_context": true
}
```

**Response:**
```json
{
  "message": "You have $2,847 available. I'm hiding $1,200 from you. Bills need $950.",
  "tokens_used": {
    "input": 1234,
    "output": 567
  }
}
```

**Rate Limits:**
- 10 requests per minute per user
- 100,000 tokens per day per user
- $5 cost per day per user

**Status Codes:**
- `200` - Success
- `401` - Unauthorized
- `429` - Rate limit exceeded

### GET /api/v1/chat/history

Get conversation history.

**Query Parameters:**
- `limit` (int, default: 50) - Number of messages to return

**Response:**
```json
{
  "messages": [
    {
      "role": "user",
      "content": "What's my balance?",
      "timestamp": "2024-01-15T12:00:00Z"
    },
    {
      "role": "assistant",
      "content": "You have $2,847...",
      "timestamp": "2024-01-15T12:00:01Z"
    }
  ]
}
```

### DELETE /api/v1/chat/history

Clear conversation history.

**Response:**
```json
{
  "message": "Conversation history cleared"
}
```

---

## Banking (Plaid)

### POST /api/v1/plaid/link-token

Create a Plaid Link token for connecting banks.

**Response:**
```json
{
  "link_token": "link-sandbox-abc123..."
}
```

Use this token with Plaid Link SDK (iOS or web).

### POST /api/v1/plaid/exchange

Exchange public token for access token after bank connection.

**Request:**
```json
{
  "public_token": "public-sandbox-xyz789..."
}
```

**Response:**
```json
{
  "item_id": "item_abc123",
  "institution_name": "Chase",
  "institution_id": "ins_3"
}
```

### POST /api/v1/plaid/sync/{item_id}

Sync transactions for a specific connected bank.

**Parameters:**
- `item_id` (path) - Plaid item ID

**Response:**
```json
{
  "synced": 45,
  "total_transactions": 45,
  "start_date": "2024-10-15",
  "end_date": "2025-01-15"
}
```

### POST /api/v1/plaid/sync-all

Sync transactions from all connected banks.

**Response:**
```json
{
  "total_synced": 123,
  "banks_synced": 3,
  "errors": []
}
```

### GET /api/v1/plaid/accounts/{item_id}

Get account information for a connected bank.

**Response:**
```json
{
  "accounts": [
    {
      "account_id": "acc_123",
      "name": "Chase Checking",
      "type": "depository",
      "subtype": "checking",
      "balance": {
        "current": 2847.50,
        "available": 2847.50
      },
      "mask": "1234"
    }
  ]
}
```

### DELETE /api/v1/plaid/banks/{item_id}

Remove a connected bank.

**Response:**
```json
{
  "message": "Bank removed successfully"
}
```

---

## Transactions

### GET /api/v1/transactions

Get transaction history.

**Query Parameters:**
- `days` (int, default: 30) - Number of days to look back
- `limit` (int, default: 100) - Max transactions to return

**Response:**
```json
{
  "transactions": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "date": "2024-01-15T12:00:00Z",
      "amount": -47.50,
      "merchant": "Uber",
      "category": "Transportation",
      "is_bill": false
    }
  ]
}
```

### GET /api/v1/transactions/spending

Get spending summary by category.

**Query Parameters:**
- `days` (int, default: 30) - Period to analyze

**Response:**
```json
{
  "total_spent": 1234.56,
  "by_category": {
    "Food & Dining": 456.78,
    "Transportation": 234.56,
    "Entertainment": 123.45
  },
  "period_days": 30
}
```

---

## Bills

### POST /api/v1/bills/detect

Run bill detection on transaction history.

**Query Parameters:**
- `days_lookback` (int, default: 90) - Days of history to analyze

**Response:**
```json
{
  "detected": 3,
  "bills": [
    {
      "merchant": "Verizon",
      "amount": 65.00,
      "frequency_days": 30,
      "next_due_date": "2024-02-15",
      "confidence": 0.9
    }
  ]
}
```

### GET /api/v1/bills

Get all active bills.

**Response:**
```json
{
  "bills": [
    {
      "merchant": "Verizon",
      "amount": 65.00,
      "frequency_days": 30,
      "next_due": "2024-02-15",
      "confidence": 0.9
    }
  ]
}
```

### GET /api/v1/bills/upcoming

Get bills due in next N days.

**Query Parameters:**
- `days` (int, default: 30) - Days to look ahead

**Response:**
```json
{
  "total": 450.00,
  "count": 3,
  "by_category": {
    "Utilities": 200.00,
    "Insurance": 150.00,
    "Entertainment": 100.00
  },
  "bills": [
    {
      "merchant": "Electric Company",
      "amount": 200.00,
      "due_date": "2024-02-01",
      "category": "Utilities"
    }
  ]
}
```

---

## Balance & Money Management

### GET /api/v1/balance

Get balance summary (visible + hidden).

**Response:**
```json
{
  "total_balance": 5000.00,
  "visible_balance": 3800.00,
  "hidden_balance": 1200.00,
  "safety_buffer": 950.00,
  "truly_available": 2850.00,
  "hidden_accounts": [
    {
      "id": "550e8400-...",
      "balance": 1200.00,
      "purpose": "savings_goal",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### POST /api/v1/money/hide

Hide money for forced savings.

**Request:**
```json
{
  "amount": 500.00,
  "purpose": "forced_savings"
}
```

**Response (Success):**
```json
{
  "success": true,
  "account_id": "550e8400-...",
  "hidden_amount": 500.00,
  "total_hidden": 1700.00,
  "message": "Hidden $500.00. You're broke now. But future you is $1700.00 richer."
}
```

**Response (Failed - Not Safe):**
```json
{
  "success": false,
  "reason": "❌ Can't hide that much. You'd have $450.00 left, but need $950.00. Short by $500.00.",
  "shortfall": 500.00
}
```

### POST /api/v1/money/reveal

Reveal hidden money.

**Request:**
```json
{
  "amount": 500.00,
  "account_id": "550e8400-... (optional)"
}
```

**Response:**
```json
{
  "success": true,
  "revealed_amount": 500.00,
  "remaining_hidden": 1200.00,
  "message": "Revealed $500.00. Try not to waste it this time."
}
```

### POST /api/v1/savings-goal

Set up automatic savings goal.

**Request:**
```json
{
  "goal_amount": 30000.00,
  "deadline": "2026-08-01",
  "purpose": "house down payment",
  "frequency": "weekly"
}
```

**Response:**
```json
{
  "success": true,
  "goal_amount": 30000.00,
  "deadline": "2026-08-01",
  "frequency": "weekly",
  "amount_per_period": 384.62,
  "periods_remaining": 78,
  "message": "Auto-save activated: $384.62 weekly. 78 times until 2026-08-01."
}
```

---

## Profile

### GET /api/v1/profile

Get user profile.

**Response:**
```json
{
  "user_id": "550e8400-...",
  "name": "Joe",
  "location": "Atlanta",
  "employer": "Delta Airlines",
  "salary": 121000.00,
  "savings_goal": {
    "amount": 30000.00,
    "deadline": "2026-08-01",
    "purpose": "house down payment"
  },
  "intensity_mode": "moderate",
  "emergency_buffer": 500.00,
  "learned_insights": [
    "Spends heavily on Sunday brunches",
    "Prefers Uber late at night",
    "Regular gym-goer"
  ]
}
```

### PATCH /api/v1/profile

Update user profile.

**Request:**
```json
{
  "name": "Joe",
  "location": "Atlanta",
  "intensity_mode": "insanity"
}
```

**Response:**
```json
{
  "message": "Profile updated successfully"
}
```

---

## Usage & Budget

### GET /api/v1/usage

Get API usage and budget stats for today.

**Response:**
```json
{
  "requests_today": 45,
  "tokens_used": 12345,
  "tokens_remaining": 87655,
  "cost_today": 0.45,
  "cost_remaining": 4.55,
  "percentage_used": 12.3
}
```

---

## System

### GET /health

Health check endpoint (no auth required).

**Response:**
```json
{
  "status": "healthy",
  "database": "connected",
  "timestamp": "2024-01-15T12:00:00Z"
}
```

### GET /

Root endpoint with basic info.

**Response:**
```json
{
  "app": "FURG",
  "tagline": "Your money, but smarter than you",
  "version": "1.0.0",
  "docs": "/docs"
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "detail": "Error message here"
}
```

**Common Status Codes:**
- `200` - Success
- `400` - Bad request
- `401` - Unauthorized (invalid/missing token)
- `403` - Forbidden
- `404` - Not found
- `429` - Rate limit exceeded
- `500` - Internal server error
- `503` - Service unavailable

---

## Rate Limits

**Per User:**
- Requests: 10 per minute
- Tokens: 100,000 per day
- Cost: $5 per day

**Exceeded Rate Limit Response:**
```json
{
  "detail": "Slow down. Roast limit: 10/min. You're too chatty."
}
```

---

## Webhooks

### POST /webhooks/plaid

Plaid webhook endpoint (internal use).

Handles:
- Transaction updates
- Item errors
- Account updates

---

## OpenAPI Documentation

Interactive API docs available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- OpenAPI JSON: `http://localhost:8000/openapi.json`

---

## SDK Examples

### Python

```python
import httpx

BASE_URL = "http://localhost:8000"

# Authenticate
response = httpx.post(
    f"{BASE_URL}/api/v1/auth/apple",
    json={"apple_token": "test_apple_user123"}
)
token = response.json()["jwt"]

# Chat
response = httpx.post(
    f"{BASE_URL}/api/v1/chat",
    headers={"Authorization": f"Bearer {token}"},
    json={"message": "What's my balance?"}
)
print(response.json()["message"])
```

### JavaScript

```javascript
const BASE_URL = "http://localhost:8000";

// Authenticate
const authResponse = await fetch(`${BASE_URL}/api/v1/auth/apple`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ apple_token: "test_apple_user123" })
});
const { jwt } = await authResponse.json();

// Chat
const chatResponse = await fetch(`${BASE_URL}/api/v1/chat`, {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${jwt}`,
    "Content-Type": "application/json"
  },
  body: JSON.stringify({ message: "What's my balance?" })
});
const { message } = await chatResponse.json();
console.log(message);
```

### Swift (iOS)

```swift
let baseURL = "http://localhost:8000"

// Authenticate
let authURL = URL(string: "\(baseURL)/api/v1/auth/apple")!
var authRequest = URLRequest(url: authURL)
authRequest.httpMethod = "POST"
authRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
authRequest.httpBody = try JSONEncoder().encode([
    "apple_token": "test_apple_user123"
])

let (authData, _) = try await URLSession.shared.data(for: authRequest)
let authResponse = try JSONDecoder().decode(AuthResponse.self, from: authData)
let token = authResponse.jwt

// Chat
let chatURL = URL(string: "\(baseURL)/api/v1/chat")!
var chatRequest = URLRequest(url: chatURL)
chatRequest.httpMethod = "POST"
chatRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
chatRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
chatRequest.httpBody = try JSONEncoder().encode([
    "message": "What's my balance?"
])

let (chatData, _) = try await URLSession.shared.data(for: chatRequest)
let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: chatData)
print(chatResponse.message)
```

---

## Support

For questions or issues:
- GitHub Issues: [github.com/yourrepo/issues](https://github.com/yourrepo/issues)
- Email: api@furg.app
- Docs: [docs.furg.app](https://docs.furg.app)
