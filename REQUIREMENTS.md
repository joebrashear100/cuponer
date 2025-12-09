# FURG - Complete Product Requirements Document

> **Financial Utility & Roasting Guide** - A chat-first financial AI assistant with a "roasting" personality that helps users manage money through natural conversation.

---

## Table of Contents

1. [Product Overview](#1-product-overview)
2. [Platform Requirements](#2-platform-requirements)
3. [Authentication Requirements](#3-authentication-requirements)
4. [Data Model Requirements](#4-data-model-requirements)
5. [API Requirements](#5-api-requirements)
6. [iOS App Requirements](#6-ios-app-requirements)
7. [Business Logic Requirements](#7-business-logic-requirements)
8. [AI/ML Requirements](#8-aiml-requirements)
9. [Integration Requirements](#9-integration-requirements)
10. [Security Requirements](#10-security-requirements)
11. [Performance Requirements](#11-performance-requirements)

---

## 1. Product Overview

### 1.1 Vision
A chat-first financial AI assistant that helps users manage their money through natural conversation rather than complex UI controls. FURG roasts bad spending decisions to motivate behavioral change while always protecting essential bills.

### 1.2 Core Philosophy
- Everything is configured through chat (no sliders, dropdowns, or checkboxes for core features)
- FURG roasts bad spending decisions to motivate behavioral change
- Always protects essential bills (2× upcoming bills + emergency buffer)
- Uses "shadow banking" to help users hide money from themselves for forced savings
- AI-powered transaction categorization and bill detection

### 1.3 Tagline
"Your money, but smarter than you"

### 1.4 Target Platforms
| Platform | Priority | Status |
|----------|----------|--------|
| iOS (iPhone) | P0 | Required |
| Android | P1 | Future |
| Web | P2 | Future |
| Backend API | P0 | Required |

---

## 2. Platform Requirements

### 2.1 Backend Stack
| Component | Technology | Version |
|-----------|------------|---------|
| Framework | FastAPI | 0.109.0+ |
| Runtime | Python | 3.11+ |
| Database | PostgreSQL | 15+ |
| Time-Series Extension | TimescaleDB | Latest |
| Cache/Sessions | Redis | Latest |
| Server | Uvicorn | Latest |
| ORM | SQLAlchemy | 2.0+ (async) |
| DB Driver | asyncpg | Latest |

### 2.2 iOS Stack
| Component | Technology | Version |
|-----------|------------|---------|
| Framework | SwiftUI | iOS 17.0+ |
| Language | Swift | 5.9+ |
| IDE | Xcode | 16.0+ |
| Architecture | MVVM | - |
| Dependency Injection | Custom AppContainer | - |

### 2.3 Infrastructure
| Component | Technology |
|-----------|------------|
| Containerization | Docker & Docker Compose |
| CI/CD | GitHub Actions (recommended) |
| Hosting | AWS/GCP/Azure (flexible) |

---

## 3. Authentication Requirements

### 3.1 Sign in with Apple (Required)
- **Scopes**: Full name, email
- **Token Exchange**: Apple identity token → JWT
- **User Creation**: Auto-create user on first sign-in
- **Response**: JWT token, user_id, is_new_user flag

### 3.2 JWT Token Management
- **Algorithm**: HS256 or RS256
- **Expiration**: 30 days (configurable)
- **Refresh**: Auto-refresh on API calls
- **Storage (iOS)**: Keychain

### 3.3 Session Management
- Track `last_seen` timestamp on activity
- Support multiple device sessions
- Secure token invalidation on sign-out

---

## 4. Data Model Requirements

### 4.1 Core Tables

#### 4.1.1 Users
```
users
├── id: UUID (PK)
├── apple_id: VARCHAR(255) UNIQUE NOT NULL
├── email: VARCHAR(255)
├── created_at: TIMESTAMP
└── last_seen: TIMESTAMP
```

#### 4.1.2 User Profiles
```
user_profiles
├── user_id: UUID (PK, FK → users)
├── name: VARCHAR(255)
├── location: VARCHAR(255)
├── employer: VARCHAR(255)
├── salary: DECIMAL(12,2)
├── savings_goal: JSONB {amount, deadline, purpose}
├── learned_insights: TEXT[]
├── spending_preferences: JSONB
├── health_metrics: JSONB
├── intensity_mode: VARCHAR(50) ['mild', 'moderate', 'insanity']
├── emergency_buffer: DECIMAL(10,2) DEFAULT 500.00
└── updated_at: TIMESTAMP
```

#### 4.1.3 Transactions (TimescaleDB Hypertable)
```
transactions
├── id: UUID
├── user_id: UUID (FK → users)
├── date: TIMESTAMP (partition key)
├── amount: DECIMAL(10,2)
├── merchant: VARCHAR(255)
├── merchant_category_code: VARCHAR(100)
├── category: VARCHAR(50)
├── plaid_transaction_id: VARCHAR(255)
├── financekit_transaction_id: VARCHAR(255)
├── notes: TEXT
├── is_bill: BOOLEAN
├── is_recurring: BOOLEAN
├── location_lat: DECIMAL(10,7)
├── location_lon: DECIMAL(10,7)
└── created_at: TIMESTAMP
```

#### 4.1.4 Bills
```
bills
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── merchant: VARCHAR(255)
├── amount: DECIMAL(10,2)
├── frequency_days: INTEGER [7, 14, 30, 90, 365]
├── next_due_date: DATE
├── confidence: FLOAT [0.0-1.0]
├── is_active: BOOLEAN
├── category: VARCHAR(50)
├── created_at: TIMESTAMP
└── updated_at: TIMESTAMP
```

#### 4.1.5 Shadow Accounts (Hidden Savings)
```
shadow_accounts
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── bank_name: VARCHAR(255)
├── account_last_4: VARCHAR(4)
├── balance: DECIMAL(12,2)
├── purpose: VARCHAR(100) ['savings_goal', 'forced_savings', 'emergency']
├── reveal_at: TIMESTAMP
├── last_hidden_at: TIMESTAMP
└── created_at: TIMESTAMP
```

#### 4.1.6 Goals
```
goals
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── name: VARCHAR(255)
├── target_amount: DECIMAL(12,2)
├── current_amount: DECIMAL(12,2)
├── deadline: DATE
├── icon: VARCHAR(100)
├── color: VARCHAR(20)
├── priority: INTEGER
├── is_primary: BOOLEAN
├── is_active: BOOLEAN
├── created_at: TIMESTAMP
└── updated_at: TIMESTAMP
```

#### 4.1.7 Subscriptions
```
subscriptions
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── name: VARCHAR(255)
├── amount: DECIMAL(10,2)
├── billing_cycle: VARCHAR(50) ['weekly', 'monthly', 'yearly']
├── next_billing_date: DATE
├── category: VARCHAR(50)
├── icon: VARCHAR(100)
├── color: VARCHAR(20)
├── importance: VARCHAR(50) ['essential', 'important', 'nice_to_have']
├── auto_detected: BOOLEAN
├── is_active: BOOLEAN
├── cancelled_at: TIMESTAMP
├── created_at: TIMESTAMP
└── updated_at: TIMESTAMP
```

#### 4.1.8 Round-up Configuration
```
roundup_config
├── user_id: UUID (PK, FK → users)
├── is_enabled: BOOLEAN
├── round_up_amount: VARCHAR(50) ['nearest_dollar', 'nearest_2', 'nearest_5']
├── multiplier: INTEGER [1-10]
├── linked_goal_id: UUID (FK → goals)
├── transfer_frequency: VARCHAR(50)
├── min_transfer_amount: DECIMAL(10,2)
├── created_at: TIMESTAMP
└── updated_at: TIMESTAMP
```

#### 4.1.9 Round-up Transactions
```
roundup_transactions
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── original_transaction_id: UUID
├── original_amount: DECIMAL(10,2)
├── roundup_amount: DECIMAL(10,2)
├── multiplied_amount: DECIMAL(10,2)
├── goal_id: UUID (FK → goals)
├── status: VARCHAR(50) ['pending', 'transferred', 'cancelled']
├── transferred_at: TIMESTAMP
└── created_at: TIMESTAMP
```

#### 4.1.10 Spending Limits
```
spending_limits
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── category: VARCHAR(50)
├── limit_amount: DECIMAL(10,2)
├── period: VARCHAR(50) ['daily', 'weekly', 'monthly']
├── warning_threshold: DECIMAL(3,2) DEFAULT 0.80
├── is_active: BOOLEAN
└── created_at: TIMESTAMP
```

#### 4.1.11 Wishlist
```
wishlist
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── name: VARCHAR(255)
├── price: DECIMAL(10,2)
├── url: TEXT
├── image_url: TEXT
├── priority: INTEGER [1-5]
├── category: VARCHAR(50)
├── notes: TEXT
├── linked_goal_id: UUID (FK → goals)
├── is_active: BOOLEAN
├── is_purchased: BOOLEAN
├── purchased_at: TIMESTAMP
├── created_at: TIMESTAMP
└── updated_at: TIMESTAMP
```

#### 4.1.12 Conversations (Chat History)
```
conversations
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── role: VARCHAR(20) ['user', 'assistant']
├── content: TEXT
├── metadata: JSONB
└── created_at: TIMESTAMP
```

#### 4.1.13 Plaid Items (Bank Connections)
```
plaid_items
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── plaid_item_id: VARCHAR(255) UNIQUE
├── plaid_access_token: TEXT (encrypted)
├── institution_name: VARCHAR(255)
├── institution_id: VARCHAR(255)
├── last_synced: TIMESTAMP
├── status: VARCHAR(50) ['active', 'error', 'disconnected']
└── created_at: TIMESTAMP
```

#### 4.1.14 Alerts
```
alerts
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── alert_type: VARCHAR(100)
├── title: VARCHAR(255)
├── message: TEXT
├── data: JSONB
├── priority: VARCHAR(50) ['low', 'normal', 'high', 'urgent']
├── is_read: BOOLEAN
├── read_at: TIMESTAMP
└── created_at: TIMESTAMP
```

#### 4.1.15 API Usage (Rate Limiting)
```
api_usage
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── endpoint: VARCHAR(255)
├── input_tokens: INTEGER
├── output_tokens: INTEGER
├── cost: DECIMAL(10,6)
└── created_at: TIMESTAMP
```

#### 4.1.16 Learned Insights
```
learned_insights
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── insight: TEXT
├── confidence: FLOAT
├── category: VARCHAR(50) ['spending_pattern', 'location_pattern', 'time_pattern']
├── evidence: JSONB
└── learned_at: TIMESTAMP
```

#### 4.1.17 Device Tokens (Push Notifications)
```
device_tokens
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── token: TEXT
├── platform: VARCHAR(20) ['ios', 'android']
├── is_active: BOOLEAN
└── created_at: TIMESTAMP
```

#### 4.1.18 Training Examples (ML)
```
training_examples
├── id: UUID (PK)
├── user_id: UUID (FK → users)
├── transaction_data: JSONB
├── correct_category: VARCHAR(50)
└── created_at: TIMESTAMP
```

### 4.2 Database Views
- `recent_transactions_with_bills` - Joins transactions with detected bills
- `user_financial_summary` - Aggregated user financial snapshot

### 4.3 Stored Functions
- `calculate_upcoming_bills(user_id, days)` → DECIMAL
- `update_bill_next_due(bill_id)` → VOID
- `get_user_total_balance(user_id)` → DECIMAL

### 4.4 Triggers
- `update_user_last_seen()` - Updates last_seen on conversation insert
- `update_profile_timestamp()` - Auto-updates updated_at on profile changes

---

## 5. API Requirements

### 5.1 API Structure
- **Base URL**: `/api/v1`
- **Format**: JSON
- **Authentication**: Bearer JWT token (except health/auth endpoints)

### 5.2 Endpoint Categories

#### 5.2.1 Health & Info (2 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/` | API info and version |
| GET | `/health` | Health check with DB status |

#### 5.2.2 Authentication (2 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/auth/apple` | Sign in with Apple token exchange |
| GET | `/api/v1/auth/me` | Get current user info |

#### 5.2.3 Chat (3 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/chat` | Send message, get FURG response |
| GET | `/api/v1/chat/history` | Get conversation history |
| DELETE | `/api/v1/chat/history` | Clear chat history |

#### 5.2.4 Plaid/Banking (6 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/plaid/link-token` | Create Plaid Link token |
| POST | `/api/v1/plaid/exchange` | Exchange public token |
| POST | `/api/v1/plaid/sync/{item_id}` | Sync specific bank |
| POST | `/api/v1/plaid/sync-all` | Sync all banks |
| GET | `/api/v1/plaid/accounts/{item_id}` | Get accounts for bank |
| DELETE | `/api/v1/plaid/banks/{item_id}` | Remove bank connection |

#### 5.2.5 Transactions (2 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/transactions` | Get transaction history |
| GET | `/api/v1/transactions/spending` | Get spending by category |

#### 5.2.6 Bills (3 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/bills/detect` | Run bill detection |
| GET | `/api/v1/bills` | Get active bills |
| GET | `/api/v1/bills/upcoming` | Get bills due in N days |

#### 5.2.7 Balance & Money (4 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/balance` | Get balance summary |
| POST | `/api/v1/money/hide` | Hide money (shadow banking) |
| POST | `/api/v1/money/reveal` | Reveal hidden money |
| POST | `/api/v1/savings-goal` | Set up savings goal |

#### 5.2.8 Profile (2 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/profile` | Get user profile |
| PATCH | `/api/v1/profile` | Update user profile |

#### 5.2.9 Subscriptions (5 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/subscriptions` | Get all subscriptions |
| POST | `/api/v1/subscriptions/detect` | Detect subscriptions |
| GET | `/api/v1/subscriptions/{id}/cancellation-guide` | Get cancellation guide |
| POST | `/api/v1/subscriptions/{id}/mark-cancelled` | Mark as cancelled |
| GET | `/api/v1/subscriptions/{id}/negotiation-script` | Get negotiation script |

#### 5.2.10 Goals (7 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/goals` | Get all goals |
| POST | `/api/v1/goals` | Create goal |
| GET | `/api/v1/goals/{id}` | Get specific goal |
| PATCH | `/api/v1/goals/{id}` | Update goal |
| DELETE | `/api/v1/goals/{id}` | Delete goal |
| POST | `/api/v1/goals/{id}/contribute` | Contribute to goal |
| GET | `/api/v1/goals/{id}/history` | Get contribution history |

#### 5.2.11 Round-ups (5 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/round-ups/config` | Get round-up config |
| POST | `/api/v1/round-ups/config` | Update config |
| GET | `/api/v1/round-ups/summary` | Get savings summary |
| GET | `/api/v1/round-ups/pending` | Get pending round-ups |
| POST | `/api/v1/round-ups/transfer` | Transfer to goal |

#### 5.2.12 Forecast (3 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/forecast` | Get cash flow forecast |
| GET | `/api/v1/forecast/daily` | Get daily projections |
| GET | `/api/v1/forecast/alerts` | Get forecast alerts |

#### 5.2.13 Spending Limits (3 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/spending-limits` | Get all limits |
| POST | `/api/v1/spending-limits` | Create limit |
| DELETE | `/api/v1/spending-limits/{id}` | Delete limit |

#### 5.2.14 Wishlist (5 endpoints)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/wishlist` | Get wishlist |
| POST | `/api/v1/wishlist` | Add item |
| PATCH | `/api/v1/wishlist/{id}` | Update item |
| DELETE | `/api/v1/wishlist/{id}` | Delete item |
| POST | `/api/v1/wishlist/{id}/purchased` | Mark purchased |

#### 5.2.15 Achievements (1 endpoint)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/achievements` | Get achievements |

#### 5.2.16 Usage (1 endpoint)
| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/v1/usage` | Get API usage stats |

**Total: 52 API Endpoints**

---

## 6. iOS App Requirements

### 6.1 Navigation Architecture

```
MainTabView (Root)
├── Tab 0: Dashboard/Home
├── Tab 1: Chat
├── Tab 2: Transactions
├── Tab 3: Accounts
└── Tab 4: Settings
```

### 6.2 Screen Requirements (51 Views)

#### 6.2.1 Onboarding Flow
| Screen | Purpose | Key Components |
|--------|---------|----------------|
| WelcomeView | App intro + Sign in with Apple | Animated logo, feature cards, Apple Sign-In button |
| OnboardingView | 5-step user setup | Progress bar, name input, salary input, goal setup, intensity selector, bank connection |

#### 6.2.2 Main Tab Screens
| Screen | Purpose | Key Components |
|--------|---------|----------------|
| MainTabView | Root navigation container | Custom glassmorphic tab bar, 5 tabs |
| DashboardView | Financial overview | Net worth card, sparkline chart, quick insights, recent activity |
| HomeView | Alternative dashboard | Spending power, quick actions, goal progress, AI insights |
| ChatView | AI chat interface | Message list, typing indicator, suggestion chips, input bar |
| TransactionsListView | Transaction management | Search, filters, AI suggestions, transaction rows |
| AccountsView | Account portfolio | Net worth, account cards, asset/liability tabs |
| SettingsView | App configuration | Profile, personality settings, feature access |

#### 6.2.3 Financial Analysis Screens
| Screen | Purpose |
|--------|---------|
| SpendingAnalyticsView | Detailed spending analysis with charts |
| CashFlowView | Income vs spending analysis |
| CategoriesView | Category breakdown with trends |
| ForecastView | Cash flow projections |
| SpendingDashboardView | Alternative spending overview |
| SpendingComparisonView | Period-over-period comparison |
| SpendingPredictionsView | AI spending forecast |

#### 6.2.4 Savings & Goals Screens
| Screen | Purpose |
|--------|---------|
| GoalsView | Savings goals with progress |
| WishlistView | Purchase planning |
| SubscriptionsView | Recurring payment tracking |
| RoundUpSettingsView | Round-up configuration |
| EnhancedRoundUpsView | Advanced round-up tracking |
| PurchasePlanView | Multi-month savings plans |

#### 6.2.5 Debt & Bill Management
| Screen | Purpose |
|--------|---------|
| DebtPayoffView | Debt strategies (avalanche/snowball) |
| BillNegotiationView | AI negotiation scripts |

#### 6.2.6 Advanced Financial Screens
| Screen | Purpose |
|--------|---------|
| InvestmentPortfolioView | Investment tracking |
| FinancialHealthView | Holistic wellness score |
| IncomeTrackerView | Multiple income sources |
| CreditFactorsDetailView | Credit score components |
| SavingsRateDetailView | Savings rate analysis |

#### 6.2.7 Utility Screens
| Screen | Purpose |
|--------|---------|
| OffersView | Location-based coupons |
| ReceiptScanView | OCR receipt scanning |
| AchievementsView | Gamification badges |
| BillSplitView | Split bill calculator |
| QuickTransactionView | Fast transaction entry |
| ConnectBankView | Plaid bank linking |
| AppleWalletView | Wallet integration |
| FinancingCalculatorView | Loan scenarios |

#### 6.2.8 Specialized Screens
| Screen | Purpose |
|--------|---------|
| MerchantIntelligenceView | Merchant insights |
| LifeIntegrationView | Calendar/contact integration |
| LocationInsightsView | Location spending patterns |
| SpendingLimitsView | Budget caps |
| MoneyMindfulnessView | Behavioral insights |
| CardRecommendationsView | AI card suggestions |
| ARShoppingView | AR purchase visualization |
| TransactionClarificationView | Category disambiguation |
| AccountDetailView | Individual account details |
| BalanceView | Quick balance summary |

### 6.3 Design System

#### 6.3.1 Color Palette
| Name | Usage |
|------|-------|
| furgMint | Primary action color |
| furgSeafoam | Secondary accent |
| furgPistachio | Tertiary accent |
| furgCharcoal | Dark background |
| furgSuccess | Green (positive/income) |
| furgWarning | Orange (caution) |
| furgDanger | Red (negative/expenses) |
| furgInfo | Blue (informational) |

#### 6.3.2 Component Patterns
- **Cards**: Glassmorphism with `.ultraThinMaterial`, 16-24pt radius
- **Buttons**: Gradient fills, rounded corners, scale animations
- **Charts**: SwiftUI Charts (line, bar, pie, area)
- **Animations**: Spring (response: 0.6, dampingFraction: 0.8)

#### 6.3.3 Typography
- Display: `furgLargeTitle`, `furgTitle2`
- Body: `furgBody`, `furgHeadline`, `furgCaption`

### 6.4 iOS Services/Managers Required

| Manager | Purpose |
|---------|---------|
| AuthManager | Authentication state |
| APIClient | HTTP networking |
| KeychainService | Secure storage |
| ChatManager | Chat coordination |
| FinanceManager | Core financial logic |
| PlaidManager | Bank connections |
| GoalsManager | Savings goals |
| RoundUpManager | Round-up automation |
| SubscriptionManager | Subscription tracking |
| SpendingLimitsManager | Budget enforcement |
| NotificationManager | Push notifications |
| SmartCategorizationManager | ML categorization |
| ForecastingManager | Cash flow predictions |
| MerchantIntelligenceManager | Merchant insights |

---

## 7. Business Logic Requirements

### 7.1 FURG Personality System

#### 7.1.1 Core Identity
- **Name**: FURG (Financial Utility & Roasting Guide)
- **Vibe**: Tough love coach meets sarcastic best friend
- **Voice**: Casual, witty, specific, data-driven
- **Tone**: Brutal honesty with genuine care

#### 7.1.2 Intensity Modes
| Mode | Description |
|------|-------------|
| INSANITY | Maximum roasting, no mercy |
| MODERATE | Balanced roasting and encouragement |
| MILD | Gentle nudges, minimal roasting |

#### 7.1.3 Roasting Templates by Situation

**Late Night Spending (22:00-04:00)**
```
"$47 Uber at midnight? Walk next time. Or better yet, stay home."
"2am Amazon order? What could you possibly need that badly?"
```

**Food & Dining**
```
"$18 on lunch? Your kitchen is collecting dust."
"Third DoorDash this week? You're paying their driver's rent."
```

**Subscriptions**
```
"4 streaming services: pick 2 or accept you enjoy wasting money."
"Gym membership unused 47 days? That's donation, not investment."
```

**Pattern Detection**
```
"Every Sunday you drop $200+. Worth being broke by 27?"
"40% more on weekends. Friday-you is sabotaging Monday-you."
```

#### 7.1.4 Core Rules
1. NEVER let users spend bill money
2. Track patterns and call them out early
3. Give roast + solution combos
4. Reference user's goals on questionable decisions
5. Learn from every conversation
6. Roast proportionally to mistake size

### 7.2 Bill Detection Algorithm

#### 7.2.1 Detection Process
1. Analyze 90-day transaction history
2. Group by merchant
3. Filter negative amounts only
4. Require minimum 2 occurrences

#### 7.2.2 Billing Cycle Recognition
| Cycle | Days | Tolerance |
|-------|------|-----------|
| Weekly | 6-8 | ±1 |
| Bi-weekly | 12-16 | ±2 |
| Monthly | 27-33 | ±3 |
| Quarterly | 83-97 | ±7 |
| Annual | 350-380 | ±15 |

#### 7.2.3 Confidence Scoring
| Score | Criteria |
|-------|----------|
| 0.9 | Merchant category matches bill categories |
| 0.8 | Subscription keywords + low variance |
| 0.75 | Very consistent amounts + regular interval |
| 0.6 | Consistent amounts + regular interval |
| 0.5 | Minimum threshold |

#### 7.2.4 Safety Buffer Formula
```
Safety Buffer = (Upcoming 30-day bills × 2) + Emergency Buffer
Default Emergency Buffer = $500
```

### 7.3 Shadow Banking (Hidden Savings)

#### 7.3.1 Hide Money Logic
```
available_after = current_balance - hidden_amount - amount_to_hide
APPROVE if: available_after >= safety_buffer
```

#### 7.3.2 Reveal Options
1. Reveal specific amount
2. Reveal specific account
3. Reveal all

### 7.4 Transaction Categorization

#### 7.4.1 Categories (16)
1. Food & Dining
2. Groceries
3. Transportation
4. Shopping
5. Entertainment
6. Utilities/Bills
7. Health & Medical
8. Subscriptions
9. Travel
10. Education
11. Personal Care
12. Pets
13. Insurance
14. Fees & Charges
15. Income
16. Transfer

#### 7.4.2 Categorization Priority
1. **Learned Merchant Patterns** (highest priority)
2. **Rule-Based Keywords** (fast path)
3. **Pattern Intelligence** (scoring mechanism)
4. **Amount/Time Heuristics** (fallback)
5. **Claude AI** (low confidence fallback)

#### 7.4.3 Confidence Actions
| Range | Action |
|-------|--------|
| 0.75-1.0 | Auto-apply |
| 0.5-0.75 | Suggest, allow override |
| 0.25-0.5 | Request user input |
| <0.25 | Require user response |

### 7.5 Round-up Calculations

#### 7.5.1 Round-up Formula
```
Round to nearest: $1, $2, or $5
roundup_amount = round_to - (amount % round_to)
final_amount = roundup_amount × multiplier (1-10x)
```

### 7.6 Goal Progress

#### 7.6.1 Formulas
```
percent_complete = min(current / target × 100, 100)
amount_remaining = max(0, target - current)
required_monthly = amount_remaining / months_remaining
```

#### 7.6.2 Milestones
Default: [10%, 25%, 50%, 75%, 90%, 100%]

### 7.7 Rate Limiting

#### 7.7.1 Limits
| Metric | Limit |
|--------|-------|
| Requests per minute | 10 |
| Tokens per day | 100,000 |
| Cost per day | $5.00 |

#### 7.7.2 Cost Calculation
```
Input: $3 per 1M tokens
Output: $15 per 1M tokens
```

---

## 8. AI/ML Requirements

### 8.1 Claude AI Integration

#### 8.1.1 Model
- **Model**: Claude Sonnet 4.5 (`claude-sonnet-4-5-20250929`)
- **Max Tokens**: 2,000 per response
- **Token Budget**: 8,000 per conversation context

#### 8.1.2 System Prompt Components
1. FURG personality definition
2. User profile context
3. Financial context (balance, bills, recent transactions)
4. Intensity mode instructions
5. Communication style rules

### 8.2 ML Categorization

#### 8.2.1 Rule-Based (70%)
Keyword matching for common merchants/categories

#### 8.2.2 Learning System
- Track merchant → category mappings
- Learn from user corrections
- Increase confidence with overrides
- Bulk recategorize on pattern updates

### 8.3 Bill Detection ML
- Pattern recognition on transaction intervals
- Amount consistency analysis
- Confidence scoring with multiple factors

### 8.4 Spending Predictions
- Historical pattern analysis
- Category-based forecasting
- Anomaly detection for unusual spending

---

## 9. Integration Requirements

### 9.1 Plaid Integration

#### 9.1.1 Products Required
- `transactions` - Transaction history
- `auth` - Account verification
- `identity` - User verification

#### 9.1.2 Features
- Link Token creation
- Public → Access token exchange
- Transaction sync (90-day lookback)
- Delta sync for updates
- Multi-bank support
- Error handling and reconnection

### 9.2 Apple Integrations

#### 9.2.1 Sign in with Apple
- Full name scope
- Email scope
- Token validation

#### 9.2.2 HealthKit (Optional)
- Steps data
- Workout data
- Correlation with spending patterns

#### 9.2.3 FinanceKit (Optional)
- Native iOS financial data
- Alternative/supplement to Plaid

#### 9.2.4 Apple Wallet
- Virtual card integration
- Pass management

### 9.3 Push Notifications
- APNs integration
- Device token management
- Alert types: spending limits, bill due, goal milestone, unusual spending

---

## 10. Security Requirements

### 10.1 Data Protection
- All API tokens encrypted at rest
- Plaid access tokens encrypted
- Keychain storage for iOS secrets
- HTTPS only for all API calls

### 10.2 Authentication
- JWT with secure signing
- Token expiration and refresh
- Secure token storage

### 10.3 Rate Limiting
- Per-user request limits
- IP-based abuse prevention
- Cost-based limits

### 10.4 Privacy
- Minimal data collection
- User data deletion on request
- No data sharing with third parties

---

## 11. Performance Requirements

### 11.1 API Performance
| Metric | Target |
|--------|--------|
| Response time (p50) | <200ms |
| Response time (p99) | <1s |
| Uptime | 99.9% |

### 11.2 Chat Performance
| Metric | Target |
|--------|--------|
| First token | <500ms |
| Full response | <5s |

### 11.3 iOS Performance
| Metric | Target |
|--------|--------|
| App launch | <2s |
| Screen transitions | <100ms |
| List scrolling | 60fps |

### 11.4 Database Performance
- TimescaleDB for efficient time-series queries
- Proper indexing on all frequently queried columns
- Connection pooling with asyncpg

---

## Appendix A: Transaction Categories

| Category | Keywords |
|----------|----------|
| Food & Dining | restaurant, cafe, coffee, starbucks, mcdonald, pizza, burger, chipotle |
| Groceries | grocery, supermarket, whole foods, trader joe, safeway, kroger, costco |
| Transportation | uber, lyft, taxi, gas, shell, chevron, parking, transit, metro |
| Entertainment | netflix, spotify, hulu, disney, amazon prime, youtube, movie, theater |
| Health & Fitness | gym, yoga, pharmacy, cvs, walgreens, hospital, doctor, dental |
| Travel | airline, hotel, airbnb, booking, expedia, airport |
| Utilities | electric, power, utility, internet, verizon, at&t, tmobile |
| Income | payroll, salary, deposit, direct dep |

---

## Appendix B: Achievement Types

| Achievement | Criteria |
|-------------|----------|
| First $1K Saved | current_amount >= 1000 |
| 30-Day Streak | consecutive_days >= 30 |
| Debt Free | total_debt == 0 |
| Budget Master | stayed_under_budget for 3 months |
| Round-up Rookie | first round-up transaction |
| Subscription Slayer | cancelled unused subscription |

---

## Appendix C: Alert Types

| Type | Priority | Trigger |
|------|----------|---------|
| spending_limit_warning | high | 80% of limit reached |
| spending_limit_exceeded | urgent | limit exceeded |
| bill_due | normal | bill due in 3 days |
| bill_overdue | high | bill past due |
| goal_milestone | normal | milestone reached |
| unusual_spending | high | anomaly detected |
| subscription_unused | low | no usage in 30 days |

---

*Document Version: 1.0*
*Last Updated: 2024*
