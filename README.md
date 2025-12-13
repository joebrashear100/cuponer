# FURG - Chat-First Financial AI 🔥

> Your money, but smarter than you.

FURG is a financial AI that learns everything about you through conversation. No sliders, no dropdowns, no checkboxes—just chat. It roasts your bad spending decisions to keep you motivated and always protects your bills.

## 🚀 Get It On Your Phone TONIGHT! (30 minutes)

**Want the fastest path from zero to app on your iPhone?**

### Option 1: Automated Setup with Claude CLI (Recommended)
Open Claude Code CLI and paste the entire contents of:
```
CLAUDE_CLI_SETUP_PROMPT.txt
```

Claude will automatically:
- ✅ Install all backend dependencies
- ✅ Configure your database
- ✅ Set up environment with your API keys (you'll provide when asked)
- ✅ Start the backend server
- ✅ Guide you step-by-step through Xcode
- ✅ Help you install on your iPhone
- ✅ Troubleshoot any issues

**Timeline**: 35-50 minutes, fully guided

### Option 2: Manual Setup
Follow the step-by-step guide:
```
GET_IT_ON_YOUR_PHONE_TONIGHT.md
```

**Timeline**: 30-40 minutes, self-guided

---

## Features

- 💬 **Chat-First Configuration**: Everything configured through natural conversation
- 🔥 **Roasting Personality**: Mocks bad spending to motivate ("Nice $47 Uber for a 10min walk, athlete")
- 🛡️ **Bill Protection**: Always keeps 2× upcoming bills + $500 buffer safe
- 🏦 **Multi-Bank Support**: Plaid integration for all major banks
- 🤖 **Multi-Model AI**: Intelligent routing between Grok, Claude, and Gemini (94% cost savings)
- 📊 **Smart Bill Detection**: Automatically detects recurring bills
- 💰 **Shadow Banking**: Hide money from yourself for forced savings
- 🍎 **Deep Apple Integration**: Sign in with Apple, ready for FinanceKit & Shortcuts

## AI Architecture

FURG uses intelligent multi-model routing to optimize for both cost and quality:

| Model | Purpose | Traffic |
|-------|---------|---------|
| **Grok 4 Fast** | Roasting & casual chat | 60% |
| **Claude Sonnet** | Financial advice | 25% |
| **Gemini Flash** | Routing & categorization | 15% |

See [docs/MULTI_MODEL_ARCHITECTURE.md](docs/MULTI_MODEL_ARCHITECTURE.md) for full details.

## Quick Start

### Prerequisites

- Python 3.11+
- PostgreSQL 15+ with TimescaleDB
- Docker & Docker Compose (recommended)
- API Keys:
  - Anthropic (Claude): [console.anthropic.com](https://console.anthropic.com/)
  - xAI (Grok): [console.x.ai](https://console.x.ai/)
  - Google (Gemini): [aistudio.google.com/apikey](https://aistudio.google.com/apikey)
- Plaid account ([sign up](https://plaid.com/))

### 1. Clone & Setup

```bash
git clone https://github.com/yourusername/cuponer.git
cd cuponer

# Copy environment file
cp backend/.env.example backend/.env

# Edit .env with your API keys
nano backend/.env
```

### 2. Run with Docker (Recommended)

```bash
# Start all services
docker-compose up -d

# Check logs
docker-compose logs -f backend

# API will be available at http://localhost:8000
```

### 3. Initialize Database

```bash
# Database schema is automatically loaded via docker-compose
# Or manually apply:
psql -h localhost -U frugal -d frugal_ai < database/schema.sql
```

### 4. Test the API

```bash
# Health check
curl http://localhost:8000/health

# Generate test token (DEBUG mode only)
python -c "from backend.auth import create_test_token; print(create_test_token('test-user-123'))"

# Test chat endpoint
curl -X POST http://localhost:8000/api/v1/chat \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"message": "What is my balance?"}'
```

## Manual Setup (Without Docker)

### 1. Install Dependencies

```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Setup PostgreSQL

```bash
# Install PostgreSQL and TimescaleDB
# On macOS:
brew install postgresql@15 timescaledb

# Create database
createdb frugal_ai

# Apply schema
psql frugal_ai < ../database/schema.sql
```

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env with your credentials
```

### 4. Run Backend

```bash
python main.py

# Or with uvicorn for hot reload
uvicorn main:app --reload --port 8000
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    iOS App (Swift)                   │
│  ┌────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │   ChatUI   │  │ FinanceKit   │  │  Shortcuts  │ │
│  └────────────┘  └──────────────┘  └─────────────┘ │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              FastAPI Backend (Python)                │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │   Auth   │  │   Chat   │  │  Plaid Service   │  │
│  └──────────┘  └──────────┘  └──────────────────┘  │
│  ┌──────────────────────┐  ┌───────────────────┐   │
│  │   Bill Detection     │  │  ML Categorizer   │   │
│  └──────────────────────┘  └───────────────────┘   │
│  ┌──────────────────────────────────────────────┐  │
│  │         Shadow Banking Service               │  │
│  └──────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│         PostgreSQL + TimescaleDB + Redis             │
└─────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────┐
│              Claude API (Anthropic)                  │
└─────────────────────────────────────────────────────┘
```

## API Documentation

Full API documentation available at: `http://localhost:8000/docs`

### Key Endpoints

#### Authentication
- `POST /api/v1/auth/apple` - Sign in with Apple
- `GET /api/v1/auth/me` - Get current user

#### Chat
- `POST /api/v1/chat` - Send message to FURG
- `GET /api/v1/chat/history` - Get conversation history

#### Banking
- `POST /api/v1/plaid/link-token` - Create Plaid Link token
- `POST /api/v1/plaid/exchange` - Exchange public token
- `POST /api/v1/plaid/sync-all` - Sync all banks

#### Money Management
- `GET /api/v1/balance` - Get balance summary
- `POST /api/v1/money/hide` - Hide money
- `POST /api/v1/money/reveal` - Reveal hidden money
- `POST /api/v1/savings-goal` - Set savings goal

#### Bills & Transactions
- `GET /api/v1/bills` - Get active bills
- `POST /api/v1/bills/detect` - Run bill detection
- `GET /api/v1/transactions` - Get transactions

## Chat Examples

### Setting Intensity Mode
```
User: "Set intensity to insanity"
FURG: "Insanity mode activated. Hope you like being broke-but-rich."
```

### Hiding Money
```
User: "Hide $500 for my house down payment"
FURG: "Hidden $500. You now have $X visible. For your own good."
```

### Getting Balance
```
User: "What's my balance?"
FURG: "You have $2,847 available. I'm hiding $1,200 from you. Bills need $950."
```

### Transaction Roast
```
FURG: "Joe, $47 Uber at 2am? You couldn't wait 4 hours for the train? That's rent money."
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `ANTHROPIC_API_KEY` | Claude API key | ✅ |
| `PLAID_CLIENT_ID` | Plaid client ID | ✅ |
| `PLAID_SECRET` | Plaid secret key | ✅ |
| `DATABASE_URL` | PostgreSQL connection string | ✅ |
| `JWT_SECRET` | JWT signing secret (32+ chars) | ✅ |
| `APPLE_CLIENT_ID` | Apple app bundle ID | For iOS |
| `APPLE_TEAM_ID` | Apple developer team ID | For iOS |
| `DEBUG` | Enable debug mode | No |
| `PORT` | Server port (default: 8000) | No |

## Development

### Running Tests

```bash
cd backend
pytest

# With coverage
pytest --cov=. --cov-report=html
```

### Code Formatting

```bash
# Format with black
black .

# Lint with flake8
flake8 .
```

## Deployment

### Fly.io (Recommended)

```bash
# Install flyctl
brew install flyctl

# Login
flyctl auth login

# Create app
flyctl launch

# Set secrets
flyctl secrets set \
  ANTHROPIC_API_KEY=sk-ant-xxx \
  PLAID_CLIENT_ID=xxx \
  PLAID_SECRET=xxx \
  JWT_SECRET=xxx \
  DATABASE_URL=xxx

# Deploy
flyctl deploy

# View logs
flyctl logs
```

## Security

- ✅ JWT-based authentication
- ✅ Sign in with Apple integration
- ✅ Rate limiting (10 req/min per user)
- ✅ Token usage limits ($5/day per user)
- ✅ SQL injection protection via parameterized queries
- ✅ CORS configuration
- ✅ Environment-based secrets

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - see `LICENSE` file for details

## Roadmap

- [x] Core chat functionality
- [x] Plaid integration
- [x] Bill detection
- [x] Shadow banking
- [ ] iOS app with FinanceKit
- [ ] Apple Shortcuts integration
- [ ] HealthKit integration
- [ ] Location-based insights
- [ ] Apple Watch app
- [ ] Subscription tier ($9.99/mo)

## Credits

Built with:
- [FastAPI](https://fastapi.tiangolo.com/)
- [Claude AI](https://www.anthropic.com/)
- [Plaid](https://plaid.com/)
- [TimescaleDB](https://www.timescale.com/)

---

**"Your money, but smarter than you."** 🔥
