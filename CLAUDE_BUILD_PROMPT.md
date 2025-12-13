# FURG - Complete Build Prompt for Claude

> Copy this entire document as a prompt to Claude to build FURG from scratch.

---

## MISSION

Build **FURG** (Financial Utility & Roasting Guide) - a chat-first financial AI assistant with a "roasting" personality. Users manage their money through natural conversation with an AI that roasts their bad spending decisions while protecting their essential bills.

**Tagline**: "Your money, but smarter than you"

---

## CORE PHILOSOPHY

1. **Chat-First**: Everything is configured through conversation, not UI controls
2. **Tough Love**: FURG roasts bad spending to motivate behavioral change
3. **Bill Protection**: Always protect essential bills (2× upcoming bills + $500 emergency buffer)
4. **Shadow Banking**: Help users hide money from themselves for forced savings
5. **AI-Powered**: Intelligent transaction categorization and bill detection

---

## TECH STACK

### Backend
```
Framework: FastAPI 0.109.0+
Language: Python 3.11+
Database: PostgreSQL 15 + TimescaleDB extension
Cache: Redis
ORM: SQLAlchemy 2.0+ (async)
Driver: asyncpg
Server: Uvicorn
AI: Anthropic Claude API (claude-sonnet-4-5-20250929)
Banking: Plaid SDK
Auth: Sign in with Apple + JWT (python-jose)
```

### iOS App
```
Framework: SwiftUI
Minimum iOS: 17.0
Language: Swift 5.9+
Architecture: MVVM with AppContainer (dependency injection)
Storage: Keychain (secrets), UserDefaults (preferences)
```

### Infrastructure
```
Containerization: Docker & Docker Compose
Database: PostgreSQL 15 with TimescaleDB
```

---

## DATABASE SCHEMA

Create these 18 tables in PostgreSQL with TimescaleDB:

```sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- 1. USERS
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    last_seen TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_users_apple_id ON users(apple_id);

-- 2. USER PROFILES
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255),
    location VARCHAR(255),
    employer VARCHAR(255),
    salary DECIMAL(12,2),
    savings_goal JSONB,  -- {amount, deadline, purpose}
    learned_insights TEXT[],
    spending_preferences JSONB,
    health_metrics JSONB,
    intensity_mode VARCHAR(50) DEFAULT 'moderate',  -- mild, moderate, insanity
    emergency_buffer DECIMAL(10,2) DEFAULT 500.00,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. CONVERSATIONS (Chat History)
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,  -- 'user' or 'assistant'
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_conversations_user_time ON conversations(user_id, created_at DESC);

-- 4. TRANSACTIONS (TimescaleDB Hypertable)
CREATE TABLE transactions (
    id UUID DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date TIMESTAMP NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    merchant VARCHAR(255) NOT NULL,
    merchant_category_code VARCHAR(100),
    category VARCHAR(50),
    plaid_transaction_id VARCHAR(255),
    financekit_transaction_id VARCHAR(255),
    notes TEXT,
    is_bill BOOLEAN DEFAULT FALSE,
    is_recurring BOOLEAN DEFAULT FALSE,
    location_lat DECIMAL(10,7),
    location_lon DECIMAL(10,7),
    created_at TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (id, date)
);
SELECT create_hypertable('transactions', 'date', if_not_exists => TRUE);
CREATE INDEX idx_transactions_user ON transactions(user_id, date DESC);
CREATE INDEX idx_transactions_merchant ON transactions(merchant);
CREATE INDEX idx_transactions_category ON transactions(category);

-- 5. BILLS
CREATE TABLE bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    merchant VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    frequency_days INTEGER NOT NULL,  -- 7, 14, 30, 90, 365
    next_due_date DATE NOT NULL,
    confidence FLOAT NOT NULL,  -- 0.0-1.0
    is_active BOOLEAN DEFAULT TRUE,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_bills_user_next_due ON bills(user_id, next_due_date);

-- 6. SHADOW ACCOUNTS (Hidden Savings)
CREATE TABLE shadow_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    bank_name VARCHAR(255),
    account_last_4 VARCHAR(4),
    balance DECIMAL(12,2) DEFAULT 0,
    purpose VARCHAR(100),  -- savings_goal, forced_savings, emergency
    reveal_at TIMESTAMP,
    last_hidden_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_shadow_accounts_user ON shadow_accounts(user_id);

-- 7. PLAID ITEMS (Bank Connections)
CREATE TABLE plaid_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    plaid_item_id VARCHAR(255) UNIQUE NOT NULL,
    plaid_access_token TEXT NOT NULL,
    institution_name VARCHAR(255),
    institution_id VARCHAR(255),
    last_synced TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active',  -- active, error, disconnected
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_plaid_items_user ON plaid_items(user_id);

-- 8. GOALS
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    target_amount DECIMAL(12,2) NOT NULL,
    current_amount DECIMAL(12,2) DEFAULT 0,
    deadline DATE,
    icon VARCHAR(100) DEFAULT 'flag.fill',
    color VARCHAR(20) DEFAULT '#4ECDC4',
    priority INTEGER DEFAULT 1,
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_goals_user ON goals(user_id, is_active);

-- 9. SUBSCRIPTIONS
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    billing_cycle VARCHAR(50) DEFAULT 'monthly',  -- weekly, monthly, yearly
    next_billing_date DATE,
    category VARCHAR(50) DEFAULT 'entertainment',
    icon VARCHAR(100) DEFAULT 'creditcard.fill',
    color VARCHAR(20) DEFAULT '#9B59B6',
    importance VARCHAR(50) DEFAULT 'nice_to_have',  -- essential, important, nice_to_have
    auto_detected BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    cancelled_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_subscriptions_user ON subscriptions(user_id, is_active);

-- 10. ROUNDUP CONFIG
CREATE TABLE roundup_config (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    is_enabled BOOLEAN DEFAULT FALSE,
    round_up_amount VARCHAR(50) DEFAULT 'nearest_dollar',  -- nearest_dollar, nearest_2, nearest_5
    multiplier INTEGER DEFAULT 1,  -- 1-10x
    linked_goal_id UUID REFERENCES goals(id),
    transfer_frequency VARCHAR(50) DEFAULT 'weekly',
    min_transfer_amount DECIMAL(10,2) DEFAULT 5.00,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 11. ROUNDUP TRANSACTIONS
CREATE TABLE roundup_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    original_transaction_id UUID,
    original_amount DECIMAL(10,2) NOT NULL,
    roundup_amount DECIMAL(10,2) NOT NULL,
    multiplied_amount DECIMAL(10,2) NOT NULL,
    goal_id UUID REFERENCES goals(id),
    status VARCHAR(50) DEFAULT 'pending',  -- pending, transferred, cancelled
    transferred_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_roundup_transactions_user ON roundup_transactions(user_id, status);

-- 12. SPENDING LIMITS
CREATE TABLE spending_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    category VARCHAR(50) NOT NULL,
    limit_amount DECIMAL(10,2) NOT NULL,
    period VARCHAR(50) DEFAULT 'monthly',  -- daily, weekly, monthly
    warning_threshold DECIMAL(3,2) DEFAULT 0.80,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_spending_limits_user ON spending_limits(user_id, is_active);

-- 13. WISHLIST
CREATE TABLE wishlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    url TEXT,
    image_url TEXT,
    priority INTEGER DEFAULT 1,
    category VARCHAR(50),
    notes TEXT,
    linked_goal_id UUID REFERENCES goals(id),
    is_active BOOLEAN DEFAULT TRUE,
    is_purchased BOOLEAN DEFAULT FALSE,
    purchased_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_wishlist_user ON wishlist(user_id, is_active);

-- 14. ALERTS
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    alert_type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    data JSONB,
    priority VARCHAR(50) DEFAULT 'normal',  -- low, normal, high, urgent
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_alerts_user ON alerts(user_id, is_read, created_at DESC);

-- 15. API USAGE (Rate Limiting)
CREATE TABLE api_usage (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    endpoint VARCHAR(255),
    input_tokens INTEGER,
    output_tokens INTEGER,
    cost DECIMAL(10,6),
    created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_api_usage_user_date ON api_usage(user_id, created_at DESC);

-- 16. LEARNED INSIGHTS
CREATE TABLE learned_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    insight TEXT NOT NULL,
    confidence FLOAT NOT NULL,
    category VARCHAR(50),  -- spending_pattern, location_pattern, time_pattern
    evidence JSONB,
    learned_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_learned_insights_user ON learned_insights(user_id, learned_at DESC);

-- 17. DEVICE TOKENS (Push Notifications)
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform VARCHAR(20) NOT NULL,  -- ios, android
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(user_id, token)
);

-- 18. TRAINING EXAMPLES (ML)
CREATE TABLE training_examples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    transaction_data JSONB NOT NULL,
    correct_category VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);

-- FUNCTIONS
CREATE OR REPLACE FUNCTION calculate_upcoming_bills(p_user_id UUID, p_days INTEGER)
RETURNS DECIMAL(12,2) AS $$
BEGIN
    RETURN COALESCE((
        SELECT SUM(amount) FROM bills
        WHERE user_id = p_user_id AND is_active = TRUE
        AND next_due_date <= CURRENT_DATE + p_days
    ), 0);
END;
$$ LANGUAGE plpgsql;

-- TRIGGERS
CREATE OR REPLACE FUNCTION update_user_last_seen()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE users SET last_seen = NOW() WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_conversation_updates_last_seen
AFTER INSERT ON conversations
FOR EACH ROW EXECUTE FUNCTION update_user_last_seen();
```

---

## API ENDPOINTS (52 Total)

Build a FastAPI backend with these endpoints:

### Authentication
```
POST /api/v1/auth/apple
  - Input: {apple_token, user_identifier?}
  - Output: {jwt, user_id, is_new_user}
  - Validates Apple identity token, creates/returns user

GET /api/v1/auth/me
  - Requires: JWT Bearer token
  - Output: {user_id, email, created_at, profile}
```

### Chat
```
POST /api/v1/chat
  - Input: {message, include_context: true}
  - Output: {message, tokens_used: {prompt, completion}}
  - Rate limited: 10 req/min, 100k tokens/day, $5/day
  - Sends message to Claude with FURG personality

GET /api/v1/chat/history?limit=50
  - Output: {messages: [{role, content, timestamp}]}

DELETE /api/v1/chat/history
  - Clears all conversation history
```

### Plaid Banking
```
POST /api/v1/plaid/link-token
  - Creates Plaid Link token for bank connection

POST /api/v1/plaid/exchange
  - Input: {public_token}
  - Exchanges for access token, stores connection

POST /api/v1/plaid/sync/{item_id}
  - Syncs transactions for specific bank

POST /api/v1/plaid/sync-all
  - Syncs all connected banks

GET /api/v1/plaid/accounts/{item_id}
  - Returns accounts for connected bank

DELETE /api/v1/plaid/banks/{item_id}
  - Removes bank connection
```

### Transactions
```
GET /api/v1/transactions?days=30&limit=100
  - Output: {transactions: [{id, date, amount, merchant, category, is_bill}]}

GET /api/v1/transactions/spending?days=30
  - Output: {total_spent, by_category: {category: amount}, period_days}
```

### Bills
```
POST /api/v1/bills/detect?days_lookback=90
  - Runs bill detection algorithm
  - Output: {detected: count, bills: [{merchant, amount, frequency_days, confidence}]}

GET /api/v1/bills
  - Output: {bills: [{merchant, amount, frequency_days, next_due, confidence}]}

GET /api/v1/bills/upcoming?days=30
  - Output: {total_amount, bills: [{merchant, amount, due_date}]}
```

### Balance & Money
```
GET /api/v1/balance
  - Output: {visible_balance, hidden_balance, total_balance}

POST /api/v1/money/hide
  - Input: {amount, purpose: 'forced_savings'}
  - Validates against safety buffer before hiding

POST /api/v1/money/reveal
  - Input: {amount?, account_id?}
  - Reveals hidden money

POST /api/v1/savings-goal
  - Input: {goal_amount, deadline, purpose, frequency: 'weekly'}
```

### Profile
```
GET /api/v1/profile
PATCH /api/v1/profile
  - Update intensity_mode, emergency_buffer, etc.
```

### Subscriptions
```
GET /api/v1/subscriptions
  - Output: {subscriptions: [...], total_monthly, unused_count}

POST /api/v1/subscriptions/detect?days_lookback=180
  - Detects subscriptions from transactions

GET /api/v1/subscriptions/{id}/cancellation-guide
  - Output: {merchant, difficulty, steps[], method, estimated_time, tips[]}

POST /api/v1/subscriptions/{id}/mark-cancelled

GET /api/v1/subscriptions/{id}/negotiation-script
  - Output: {merchant, current_price, potential_savings, opening_line, key_points[]}
```

### Goals
```
GET /api/v1/goals
  - Output: {goals: [...], total_target, total_saved, overall_progress}

POST /api/v1/goals
  - Input: {name, target_amount, deadline?, category, auto_contribute, monthly_contribution?}

GET /api/v1/goals/{id}
PATCH /api/v1/goals/{id}
DELETE /api/v1/goals/{id}

POST /api/v1/goals/{id}/contribute
  - Input: {amount}
  - Output: {message, new_amount, progress_percent, milestone?}

GET /api/v1/goals/{id}/history
```

### Round-ups
```
GET /api/v1/round-ups/config
POST /api/v1/round-ups/config
  - Input: {enabled, multiplier: 1-10, goal_id?, auto_transfer, max_per_transaction}

GET /api/v1/round-ups/summary
  - Output: {total_saved, pending_amount, this_month, transaction_count, average_roundup}

GET /api/v1/round-ups/pending
POST /api/v1/round-ups/transfer
  - Input: {goal_id}
```

### Forecast
```
GET /api/v1/forecast?days=30
  - Output: {current_balance, projected_balance, avg_monthly_income, avg_monthly_expenses,
             net_monthly, upcoming_bills, risk_level, risk_message, runway_days}

GET /api/v1/forecast/daily?days=14
  - Output: {projections: [{date, projected_balance, bills_due, bills[], is_low}],
             lowest_point, lowest_date}

GET /api/v1/forecast/alerts
  - Output: {alerts: [{type, title, message, action?}], risk_level}
```

### Spending Limits
```
GET /api/v1/spending-limits
POST /api/v1/spending-limits
  - Input: {category, amount, period, notify_at: 0.8}
DELETE /api/v1/spending-limits/{id}
```

### Wishlist
```
GET /api/v1/wishlist
POST /api/v1/wishlist
  - Input: {name, price, priority, url?, notes?}
PATCH /api/v1/wishlist/{id}
DELETE /api/v1/wishlist/{id}
POST /api/v1/wishlist/{id}/purchased
```

### Other
```
GET /api/v1/achievements
GET /api/v1/usage
GET /health
GET /
```

---

## FURG PERSONALITY SYSTEM

### System Prompt Template

```
You are FURG (Financial Utility & Roasting Guide).

PERSONALITY:
- Tough love coach meets sarcastic best friend
- Casual, witty, specific, and data-driven
- Brutal honesty with genuine care about user's financial future
- Dark humor about financial mistakes
- Keep responses punchy (2-3 sentences usually)
- Celebrate wins briefly, then back to business

INTENSITY MODE: {user.intensity_mode}
- INSANITY: Maximum roasting, no mercy
- MODERATE: Balanced roasting and encouragement
- MILD: Gentle nudges, minimal roasting

USER CONTEXT:
- Name: {user.name}
- Salary: ${user.salary}/year
- Savings Goal: ${goal.amount} for {goal.purpose} by {goal.deadline}
- Emergency Buffer: ${user.emergency_buffer}

FINANCIAL CONTEXT:
- Current Balance: ${balance.visible}
- Hidden Savings: ${balance.hidden}
- Upcoming Bills (30 days): ${upcoming_bills}
- Safety Buffer Required: ${safety_buffer}
- Recent Spending: {recent_transactions}

CORE RULES:
1. NEVER let users spend bill money - protect 2× upcoming bills + emergency buffer
2. Track spending patterns and call them out early
3. Give roast + solution combos (not just roasts)
4. Reference user's goals when they make questionable decisions
5. Roast proportionally - bigger mistakes get bigger roasts

SPECIAL COMMANDS (detect and execute):
- "set intensity [insanity|moderate|mild]" - Switch intensity mode
- "emergency buffer $[amount]" - Set emergency safety cushion
```

### Roasting Templates

**Late Night Spending (22:00-04:00)**
```
"$47 Uber at midnight? Walk next time. Or better yet, stay home."
"2am Amazon order? What could you possibly need that badly?"
"Nothing good happens after midnight, especially to your wallet."
```

**Food & Dining**
```
"$18 on lunch? Your kitchen is collecting dust and your wallet is collecting L's."
"Third DoorDash this week? You're paying their driver's rent now."
"$7 latte = $2,555/year if daily. You're financing Starbucks' new store."
"14 days no takeout? Holy shit, who are you? This is growth."
```

**Subscriptions**
```
"4 streaming services: pick 2 or accept you enjoy wasting money."
"Gym membership unused 47 days? That's not investment, that's donation."
"You're paying for 6 things you haven't touched in a month. Pick 3 to kill."
```

**Pattern Detection**
```
"Every Sunday you drop $200+. Worth being broke by 27?"
"40% more on weekends. Friday-you is sabotaging Monday-you."
"You've hit Target 8 times this month. They should name an aisle after you."
```

**Big Purchases**
```
"Before dropping $500: that's 1.7% of your down payment goal. Still worth it?"
"This delays your goal by 3 weeks. Your call, but don't say I didn't warn."
```

**Celebrations**
```
"First week under budget? Don't get cocky, but... nice."
"Goal hit! You actually did it. Now set a bigger one."
```

---

## BILL DETECTION ALGORITHM

```python
def detect_bills(transactions: List[Transaction], days_lookback: int = 90) -> List[Bill]:
    """
    Detect recurring bills from transaction history.

    Algorithm:
    1. Group transactions by merchant
    2. For each merchant with 2+ transactions:
       a. Calculate amount consistency (coefficient of variation)
       b. Calculate interval consistency
       c. Match to billing cycles (weekly, monthly, etc.)
       d. Score confidence based on patterns
    """

    # Billing cycles with tolerance
    BILLING_CYCLES = {
        'weekly': (7, 1),      # 6-8 days
        'biweekly': (14, 2),   # 12-16 days
        'monthly': (30, 3),    # 27-33 days
        'quarterly': (90, 7),  # 83-97 days
        'annual': (365, 15),   # 350-380 days
    }

    # Bill category keywords
    BILL_KEYWORDS = [
        'electric', 'power', 'utility', 'internet', 'phone',
        'insurance', 'rent', 'mortgage', 'loan', 'netflix',
        'spotify', 'gym', 'membership', 'subscription'
    ]

    bills = []
    merchant_groups = group_by_merchant(transactions)

    for merchant, txns in merchant_groups.items():
        if len(txns) < 2:
            continue

        amounts = [t.amount for t in txns if t.amount < 0]
        if not amounts:
            continue

        # Calculate consistency
        avg_amount = mean(amounts)
        std_dev = stdev(amounts) if len(amounts) > 1 else 0
        cv = std_dev / avg_amount if avg_amount else 1

        # Calculate intervals
        dates = sorted([t.date for t in txns])
        intervals = [(dates[i+1] - dates[i]).days for i in range(len(dates)-1)]
        avg_interval = mean(intervals)

        # Match billing cycle
        matched_cycle = None
        for cycle_name, (days, tolerance) in BILLING_CYCLES.items():
            if abs(avg_interval - days) <= tolerance:
                matched_cycle = cycle_name
                break

        if not matched_cycle:
            continue

        # Calculate confidence
        confidence = 0.5  # base

        # Boost for keywords
        if any(kw in merchant.lower() for kw in BILL_KEYWORDS):
            confidence += 0.3

        # Boost for amount consistency
        if cv < 0.05:
            confidence += 0.15
        elif cv < 0.15:
            confidence += 0.1

        confidence = min(confidence, 0.95)

        if confidence >= 0.5:
            bills.append(Bill(
                merchant=merchant,
                amount=abs(avg_amount),
                frequency_days=BILLING_CYCLES[matched_cycle][0],
                confidence=confidence,
                next_due_date=calculate_next_due(dates[-1], matched_cycle)
            ))

    return bills
```

### Safety Buffer Calculation

```python
def calculate_safety_buffer(user_id: str) -> Decimal:
    """
    Safety Buffer = (Upcoming 30-day bills × 2) + Emergency Buffer

    This is the MINIMUM balance a user must maintain.
    """
    upcoming_bills = get_upcoming_bills_total(user_id, days=30)
    emergency_buffer = get_user_emergency_buffer(user_id)  # default $500

    return (upcoming_bills * 2) + emergency_buffer
```

---

## SHADOW BANKING LOGIC

```python
async def hide_money(user_id: str, amount: Decimal, purpose: str = 'forced_savings') -> Result:
    """
    Hide money from the user's visible balance.

    Rules:
    1. Calculate current available balance
    2. Calculate safety buffer (2× bills + emergency)
    3. Only allow hiding if remaining balance >= safety buffer
    """
    current_balance = await get_plaid_balance(user_id)
    hidden_balance = await get_total_hidden(user_id)
    safety_buffer = await calculate_safety_buffer(user_id)

    available_after = current_balance - hidden_balance - amount

    if available_after < safety_buffer:
        shortfall = safety_buffer - available_after
        return Error(
            f"Can't hide that much. You'd have ${available_after:.2f} left, "
            f"need ${safety_buffer:.2f}. Short by ${shortfall:.2f}."
        )

    # Create shadow account entry
    await create_shadow_account(user_id, amount, purpose)

    total_hidden = hidden_balance + amount
    return Success(
        f"Hidden ${amount:.2f}. You're broke now. "
        f"But future you is ${total_hidden:.2f} richer."
    )


async def reveal_money(user_id: str, amount: Decimal = None, account_id: str = None) -> Result:
    """
    Reveal hidden money back to visible balance.

    Options:
    1. Reveal specific amount (from newest account)
    2. Reveal specific account by ID
    3. Reveal all (amount=None, account_id=None)
    """
    if account_id:
        account = await get_shadow_account(account_id)
        amount = account.balance
        await delete_shadow_account(account_id)
    elif amount:
        await deduct_from_shadow_accounts(user_id, amount)
    else:
        amount = await get_total_hidden(user_id)
        await delete_all_shadow_accounts(user_id)

    return Success(f"Revealed ${amount:.2f}. Try not to waste it this time.")
```

---

## TRANSACTION CATEGORIZATION

### Categories (16)
```python
CATEGORIES = [
    'Food & Dining',
    'Groceries',
    'Transportation',
    'Shopping',
    'Entertainment',
    'Utilities',
    'Health & Medical',
    'Subscriptions',
    'Travel',
    'Education',
    'Personal Care',
    'Pets',
    'Insurance',
    'Fees & Charges',
    'Income',
    'Transfer'
]
```

### Categorization Algorithm

```python
def categorize_transaction(transaction: Transaction, user_id: str) -> CategoryResult:
    """
    Multi-tier categorization:
    1. Learned merchant patterns (highest priority)
    2. Rule-based keyword matching
    3. Pattern intelligence scoring
    4. Amount/time heuristics
    5. Claude AI fallback (low confidence)
    """

    merchant = normalize_merchant(transaction.merchant)

    # Tier 1: Check learned patterns
    learned = get_learned_merchant_category(user_id, merchant)
    if learned and learned.confidence > 0.8:
        return CategoryResult(learned.category, learned.confidence)

    # Tier 2: Rule-based keywords
    KEYWORD_RULES = {
        'Food & Dining': ['restaurant', 'cafe', 'coffee', 'starbucks', 'mcdonald',
                          'pizza', 'burger', 'chipotle', 'subway', 'doordash', 'ubereats'],
        'Groceries': ['grocery', 'supermarket', 'whole foods', 'trader joe',
                      'safeway', 'kroger', 'costco', 'walmart grocery'],
        'Transportation': ['uber', 'lyft', 'taxi', 'gas', 'shell', 'chevron',
                           'parking', 'transit', 'metro', 'bart'],
        'Entertainment': ['netflix', 'spotify', 'hulu', 'disney', 'amazon prime',
                          'youtube', 'movie', 'theater', 'concert', 'tickets'],
        'Utilities': ['electric', 'power', 'utility', 'internet', 'verizon',
                      'at&t', 'tmobile', 'sprint', 'comcast', 'xfinity'],
        'Health & Medical': ['gym', 'yoga', 'pharmacy', 'cvs', 'walgreens',
                             'hospital', 'doctor', 'dental', 'medical'],
        'Travel': ['airline', 'hotel', 'airbnb', 'booking', 'expedia', 'airport'],
        'Income': ['payroll', 'salary', 'deposit', 'direct dep'],
        'Transfer': ['transfer', 'venmo', 'zelle', 'paypal'],
    }

    for category, keywords in KEYWORD_RULES.items():
        if any(kw in merchant.lower() for kw in keywords):
            return CategoryResult(category, 0.85)

    # Tier 3: Amount-based heuristics
    amount = abs(transaction.amount)
    if amount > 500 and transaction.amount > 0:
        return CategoryResult('Income', 0.6)
    elif amount < 30:
        return CategoryResult('Food & Dining', 0.3)
    elif amount < 100:
        return CategoryResult('Shopping', 0.25)

    # Tier 4: Claude AI for uncertain transactions
    if confidence < 0.5:
        category = await ask_claude_for_category(transaction)
        return CategoryResult(category, 0.6)

    return CategoryResult('Other', 0.2)


# Confidence thresholds for actions
CONFIDENCE_ACTIONS = {
    (0.75, 1.0): 'auto_apply',      # Apply automatically
    (0.5, 0.75): 'suggest',          # Suggest, allow override
    (0.25, 0.5): 'ask_user',         # Request user input
    (0.0, 0.25): 'require_response'  # Must have user response
}
```

---

## ROUND-UP CALCULATIONS

```python
def calculate_roundup(amount: Decimal, round_to: str, multiplier: int = 1) -> Decimal:
    """
    Calculate round-up amount for a transaction.

    round_to options:
    - 'nearest_dollar': Round to next $1
    - 'nearest_2': Round to next $2
    - 'nearest_5': Round to next $5

    multiplier: 1-10x the base round-up
    """
    ROUND_VALUES = {
        'nearest_dollar': Decimal('1'),
        'nearest_2': Decimal('2'),
        'nearest_5': Decimal('5'),
    }

    round_value = ROUND_VALUES[round_to]
    remainder = amount % round_value

    if remainder == 0:
        return Decimal('0')

    base_roundup = round_value - remainder
    return base_roundup * multiplier


# Example:
# Transaction: $4.73
# Round to nearest dollar: $5.00 - $4.73 = $0.27
# With 3x multiplier: $0.27 × 3 = $0.81
```

---

## RATE LIMITING

```python
# Rate limits per user
RATE_LIMITS = {
    'requests_per_minute': 10,
    'tokens_per_day': 100_000,
    'cost_per_day': Decimal('5.00'),
}

# Claude API costs
CLAUDE_COSTS = {
    'input_per_million': Decimal('3.00'),
    'output_per_million': Decimal('15.00'),
}

def calculate_cost(input_tokens: int, output_tokens: int) -> Decimal:
    input_cost = (Decimal(input_tokens) / 1_000_000) * CLAUDE_COSTS['input_per_million']
    output_cost = (Decimal(output_tokens) / 1_000_000) * CLAUDE_COSTS['output_per_million']
    return input_cost + output_cost


# Error messages
RATE_LIMIT_MESSAGES = {
    'requests': "Slow down. Roast limit: 10/min. You're too chatty.",
    'tokens': "Daily chat quota reached (100,000 tokens). Try again tomorrow.",
    'cost': "Daily cost limit reached ($5). Take a break.",
}
```

---

## iOS APP STRUCTURE

### File Organization
```
ios/Furg/
├── App/
│   ├── FurgApp.swift              # App entry point
│   ├── AppContainer.swift         # Dependency injection
│   └── Config.swift               # App configuration
├── Models/
│   ├── User.swift
│   ├── Transaction.swift
│   ├── Goal.swift
│   ├── Subscription.swift
│   ├── Bill.swift
│   └── ChatMessage.swift
├── Services/
│   ├── AuthManager.swift
│   ├── APIClient.swift
│   ├── KeychainService.swift
│   ├── ChatManager.swift
│   ├── FinanceManager.swift
│   ├── PlaidManager.swift
│   ├── GoalsManager.swift
│   ├── RoundUpManager.swift
│   ├── SubscriptionManager.swift
│   ├── SpendingLimitsManager.swift
│   ├── NotificationManager.swift
│   └── SmartCategorizationManager.swift
├── Views/
│   ├── Welcome/
│   │   ├── WelcomeView.swift
│   │   └── OnboardingView.swift
│   ├── Main/
│   │   ├── MainTabView.swift
│   │   ├── DashboardView.swift
│   │   ├── HomeView.swift
│   │   └── SettingsView.swift
│   ├── Chat/
│   │   └── ChatView.swift
│   ├── Transactions/
│   │   ├── TransactionsListView.swift
│   │   └── TransactionDetailView.swift
│   ├── Accounts/
│   │   ├── AccountsView.swift
│   │   └── AccountDetailView.swift
│   ├── Goals/
│   │   ├── GoalsView.swift
│   │   └── GoalDetailView.swift
│   ├── Analytics/
│   │   ├── SpendingAnalyticsView.swift
│   │   ├── CashFlowView.swift
│   │   └── ForecastView.swift
│   └── ... (40+ more views)
├── Components/
│   ├── Cards/
│   ├── Charts/
│   ├── Buttons/
│   └── Inputs/
└── Resources/
    ├── Assets.xcassets
    └── Fonts/
```

### Main Tab View Structure
```swift
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            ChatView()
                .tabItem { Label("Chat", systemImage: "message.fill") }
                .tag(1)

            TransactionsListView()
                .tabItem { Label("Activity", systemImage: "list.bullet") }
                .tag(2)

            AccountsView()
                .tabItem { Label("Accounts", systemImage: "chart.pie.fill") }
                .tag(3)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(4)
        }
    }
}
```

### Design System Colors
```swift
extension Color {
    static let furgMint = Color(hex: "#4ECDC4")      // Primary
    static let furgSeafoam = Color(hex: "#A8E6CF")   // Secondary
    static let furgPistachio = Color(hex: "#C5E99B") // Tertiary
    static let furgCharcoal = Color(hex: "#2C3E50")  // Dark BG
    static let furgDarkBg = Color(hex: "#1A1A2E")    // Darker BG

    static let furgSuccess = Color(hex: "#2ECC71")   // Green
    static let furgWarning = Color(hex: "#F39C12")   // Orange
    static let furgDanger = Color(hex: "#E74C3C")    // Red
    static let furgInfo = Color(hex: "#3498DB")      // Blue
}
```

### Glassmorphism Card Style
```swift
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCard())
    }
}
```

---

## ONBOARDING FLOW (5 Steps)

```swift
enum OnboardingStep: Int, CaseIterable {
    case welcome = 0      // Name input
    case income = 1       // Salary input
    case goal = 2         // Savings goal setup
    case intensity = 3    // Roast intensity selector
    case connectBank = 4  // Plaid bank connection
}

struct OnboardingView: View {
    @State private var currentStep: OnboardingStep = .welcome
    @State private var name = ""
    @State private var salary = ""
    @State private var goalAmount = ""
    @State private var goalPurpose = "Emergency Fund"
    @State private var goalDeadline = Date()
    @State private var intensityMode = "moderate"

    var body: some View {
        VStack {
            // Progress indicator
            ProgressView(value: Double(currentStep.rawValue + 1),
                        total: Double(OnboardingStep.allCases.count))

            TabView(selection: $currentStep) {
                // Step 1: Welcome
                WelcomeStep(name: $name)
                    .tag(OnboardingStep.welcome)

                // Step 2: Income
                IncomeStep(salary: $salary)
                    .tag(OnboardingStep.income)

                // Step 3: Goal
                GoalStep(amount: $goalAmount, purpose: $goalPurpose, deadline: $goalDeadline)
                    .tag(OnboardingStep.goal)

                // Step 4: Intensity
                IntensityStep(mode: $intensityMode)
                    .tag(OnboardingStep.intensity)

                // Step 5: Connect Bank
                ConnectBankStep()
                    .tag(OnboardingStep.connectBank)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Navigation buttons
            HStack {
                if currentStep != .welcome {
                    Button("Back") { previousStep() }
                }
                Spacer()
                Button(currentStep == .connectBank ? "Get Started" : "Continue") {
                    nextStep()
                }
            }
        }
    }
}
```

---

## ENVIRONMENT VARIABLES

```env
# Database
DATABASE_URL=postgresql://furg:password@localhost:5432/furg_db

# Redis
REDIS_URL=redis://localhost:6379

# Auth
JWT_SECRET=your-256-bit-secret
JWT_ALGORITHM=HS256
JWT_EXPIRATION_DAYS=30

# Anthropic
ANTHROPIC_API_KEY=sk-ant-xxx

# Plaid
PLAID_CLIENT_ID=xxx
PLAID_SECRET=xxx
PLAID_ENV=sandbox  # sandbox, development, production

# Apple Sign In
APPLE_TEAM_ID=xxx
APPLE_KEY_ID=xxx
APPLE_PRIVATE_KEY=xxx
```

---

## DOCKER SETUP

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: ./backend
    ports:
      - "8000:8000"
    environment:
      - DATABASE_URL=postgresql://furg:password@db:5432/furg_db
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis

  db:
    image: timescale/timescaledb:latest-pg15
    environment:
      - POSTGRES_USER=furg
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=furg_db
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

---

## KEY FORMULAS REFERENCE

```python
# Safety Buffer
safety_buffer = (upcoming_bills_30_days * 2) + emergency_buffer

# Round-up
roundup = (round_to - (amount % round_to)) * multiplier

# Goal Progress
progress_percent = min((current_amount / target_amount) * 100, 100)
monthly_required = amount_remaining / months_until_deadline

# Spending Limit Alert
is_warning = (current_spent / limit_amount) >= warning_threshold
is_exceeded = current_spent >= limit_amount

# Bill Confidence
confidence = base_confidence + keyword_bonus + consistency_bonus
# Capped at 0.95

# API Cost
cost = (input_tokens / 1M * $3) + (output_tokens / 1M * $15)

# Category Learning Confidence
confidence = category_count / total_categorizations_for_merchant
```

---

## SUCCESS CRITERIA

The app is complete when:

1. **Authentication**: Users can sign in with Apple and receive JWT tokens
2. **Chat**: Users can chat with FURG and receive personality-driven responses
3. **Banking**: Users can connect banks via Plaid and sync transactions
4. **Bills**: System auto-detects recurring bills with confidence scoring
5. **Shadow Banking**: Users can hide/reveal money with safety checks
6. **Goals**: Users can create, track, and contribute to savings goals
7. **Round-ups**: Automatic round-up calculation with multipliers
8. **Categories**: AI-powered transaction categorization with learning
9. **Forecasting**: Cash flow projections and alerts
10. **Rate Limiting**: Usage tracking and cost controls
11. **iOS App**: Full SwiftUI app with 51 views and glassmorphic design

---

## BUILD ORDER RECOMMENDATION

1. **Phase 1: Foundation**
   - Database schema + migrations
   - FastAPI project structure
   - Authentication (Apple Sign-In + JWT)
   - Basic user/profile CRUD

2. **Phase 2: Core Features**
   - Plaid integration
   - Transaction sync and storage
   - Bill detection algorithm
   - Transaction categorization

3. **Phase 3: AI Chat**
   - Claude integration
   - FURG personality system
   - Conversation history
   - Rate limiting

4. **Phase 4: Money Features**
   - Shadow banking (hide/reveal)
   - Goals system
   - Round-ups
   - Spending limits

5. **Phase 5: Analytics**
   - Spending summaries
   - Forecasting
   - Alerts system

6. **Phase 6: iOS App**
   - Project setup + architecture
   - Authentication flow
   - Main tab navigation
   - All 51 views

---

*This prompt contains everything needed to build FURG from scratch. Good luck!*
