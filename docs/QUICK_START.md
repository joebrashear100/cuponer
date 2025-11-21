# FURG Quick Start Guide

This guide will get you up and running with FURG in under 10 minutes.

## Prerequisites

Before you begin, make sure you have:

1. **API Keys**:
   - Anthropic API key from [console.anthropic.com](https://console.anthropic.com/)
   - Plaid account from [plaid.com](https://plaid.com/) (free sandbox available)

2. **Software** (choose one):
   - **Option A (Recommended)**: Docker Desktop
   - **Option B**: Python 3.11+, PostgreSQL 15+, Redis

## Option A: Docker Setup (5 minutes)

### 1. Clone and Configure

```bash
git clone <your-repo-url>
cd cuponer

# Copy and edit environment file
cp backend/.env.example backend/.env
```

### 2. Edit `backend/.env`

Add your API keys:

```bash
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here
PLAID_CLIENT_ID=your-plaid-client-id
PLAID_SECRET=your-plaid-secret
JWT_SECRET=$(python3 -c "import secrets; print(secrets.token_urlsafe(32))")
```

### 3. Start Everything

```bash
docker-compose up -d
```

That's it! API is now running at http://localhost:8000

### 4. Test It

```bash
# Health check
curl http://localhost:8000/health

# View API docs
open http://localhost:8000/docs
```

## Option B: Manual Setup (10 minutes)

### 1. Setup Python Environment

```bash
cd cuponer/backend
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Setup Database

```bash
# Install PostgreSQL with TimescaleDB
brew install postgresql@15 timescaledb  # macOS
# or your OS equivalent

# Create database
createdb frugal_ai

# Apply schema
psql frugal_ai < ../database/schema.sql
```

### 3. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your API keys (same as Docker setup above).

### 4. Run Backend

```bash
python main.py
# or
uvicorn main:app --reload
```

## First API Calls

### 1. Test Authentication (Debug Mode)

```bash
# In debug mode, use test tokens
export TOKEN=$(python3 -c "
import sys; sys.path.insert(0, 'backend')
from auth import create_test_token
print(create_test_token('test-user-123'))
")

echo "Token: $TOKEN"
```

### 2. Test Chat

```bash
curl -X POST http://localhost:8000/api/v1/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": "What is my balance?",
    "include_context": true
  }'
```

Expected response:
```json
{
  "message": "Your balance is $0. You have no hidden money. No bills detected yet. Connect a bank to get started.",
  "tokens_used": {
    "input": 123,
    "output": 45
  }
}
```

### 3. Test Plaid Connection

```bash
# Get link token
curl -X POST http://localhost:8000/api/v1/plaid/link-token \
  -H "Authorization: Bearer $TOKEN"
```

Response:
```json
{
  "link_token": "link-sandbox-abc123..."
}
```

Use this token in Plaid Link (iOS or web) to connect a bank.

## Common Commands

### View Logs

```bash
# Docker
docker-compose logs -f backend

# Manual
# Logs go to stdout when running uvicorn
```

### Restart Services

```bash
# Docker
docker-compose restart backend

# Manual
# Ctrl+C and restart python main.py
```

### Database Access

```bash
# Docker
docker-compose exec postgres psql -U frugal -d frugal_ai

# Manual
psql frugal_ai
```

### Reset Database

```bash
# Docker
docker-compose down -v
docker-compose up -d

# Manual
dropdb frugal_ai
createdb frugal_ai
psql frugal_ai < database/schema.sql
```

## Testing the Chat Personality

Try these messages to see FURG's personality:

```bash
# Set intensity mode
curl -X POST http://localhost:8000/api/v1/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Set intensity to insanity"}'

# Response: "Insanity mode activated. Hope you like being broke-but-rich."
```

```bash
# Ask about hiding money
curl -X POST http://localhost:8000/api/v1/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "Can I hide $500 for my house down payment?"}'
```

## API Endpoints Reference

All endpoints documented at: http://localhost:8000/docs

**Key endpoints**:

- `POST /api/v1/auth/apple` - Authenticate with Apple
- `POST /api/v1/chat` - Chat with FURG
- `GET /api/v1/balance` - Get balance summary
- `POST /api/v1/money/hide` - Hide money
- `POST /api/v1/plaid/link-token` - Get Plaid link token
- `GET /api/v1/transactions` - Get transactions
- `GET /api/v1/bills` - Get detected bills

## Troubleshooting

### "Connection refused" error

Database might not be ready. Wait 10 seconds and try again.

### "Invalid API key"

Check your `.env` file has valid `ANTHROPIC_API_KEY`.

### "Rate limit exceeded"

Default limit is 10 requests/minute. Wait 60 seconds or adjust in `.env`:

```bash
MAX_REQUESTS_PER_MINUTE=20
```

### Database connection errors

Make sure PostgreSQL is running:

```bash
# Docker
docker-compose ps

# Manual
pg_isready
```

## Next Steps

1. **Connect a Bank**: Use Plaid Link with the link token
2. **Run Bill Detection**: `POST /api/v1/bills/detect`
3. **Try Chat Commands**: "Set intensity to insanity", "Hide $500", etc.
4. **Build iOS App**: See `ios/` directory (coming soon)

## Development Workflow

```bash
# 1. Make code changes
# 2. Backend auto-reloads (if using --reload)
# 3. Test with curl or Postman
# 4. Check logs

# Run tests
cd backend
pytest

# Format code
black .
flake8 .
```

## Production Deployment

See `docs/DEPLOYMENT.md` for:
- Fly.io deployment
- AWS/GCP/Azure setup
- Environment variable management
- SSL/HTTPS configuration

## Support

- 📖 Full docs: See main README.md
- 🐛 Issues: GitHub Issues
- 💬 Questions: GitHub Discussions

Happy building! 🔥
