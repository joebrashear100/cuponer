# CUPONER/FURG - Complete Project Specification

> **Financial Utility & Roasting Guide** - A chat-first financial AI assistant with a "roasting" personality that helps users manage money through natural conversation.

**Document Version:** 2.0
**Last Updated:** December 2024
**Status:** Production-Ready Specification

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Decisions](#2-architecture-decisions)
3. [Data Models](#3-data-models)
4. [Feature Specifications](#4-feature-specifications)
5. [Screen-by-Screen Breakdown](#5-screen-by-screen-breakdown)
6. [API Contracts](#6-api-contracts)
7. [File Structure](#7-file-structure)
8. [Dependencies](#8-dependencies)
9. [Configuration](#9-configuration)
10. [Testing Requirements](#10-testing-requirements)
11. [Error Handling Strategy](#11-error-handling-strategy)
12. [Implementation Order](#12-implementation-order)

---

## 1. PROJECT OVERVIEW

### 1.1 App Identity

| Attribute | Value |
|-----------|-------|
| **App Name** | FURG (Cuponer) |
| **Bundle Identifier** | `com.furg.app` |
| **Backend Base URL** | `https://api.furg.app/api/v1` |

### 1.2 Description

FURG is a chat-first financial AI assistant that helps users manage their money through natural conversation rather than complex UI controls. The AI "roasts" bad spending decisions to motivate behavioral change while always protecting essential bills. Features include bank connection via Plaid, AI-powered transaction categorization, bill detection, shadow banking (hidden savings), goal tracking, and smart shopping assistance.

### 1.3 Target Platforms

| Platform | Version | Status |
|----------|---------|--------|
| iOS (iPhone) | 17.0+ | **Primary** |
| iOS (iPad) | 17.0+ | Secondary |
| Android | N/A | Future |
| Web | N/A | Future |

### 1.4 Primary User Persona

**Target User:** Young professionals (ages 22-35) who:
- Have irregular income or spending habits
- Want to save more but lack discipline
- Prefer conversational interfaces over traditional finance apps
- Respond well to tough-love motivation
- Use multiple bank accounts and credit cards

---

## 2. ARCHITECTURE DECISIONS

### 2.1 Technology Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| **Architecture Pattern** | MVVM | Clean separation, testable, SwiftUI-native |
| **UI Framework** | SwiftUI | Modern, declarative, built-in animations |
| **Navigation** | NavigationStack + TabView | Native iOS patterns, gesture-friendly |
| **State Management** | @StateObject + @EnvironmentObject | SwiftUI-native, reactive updates |
| **Dependency Injection** | Manual (AppContainer pattern) | Simple, explicit, no overhead |
| **Networking** | URLSession + async/await | Native, no dependencies |
| **Persistence** | UserDefaults + Keychain | Secure credentials, simple caching |
| **Authentication** | Sign in with Apple + JWT | Apple-native, secure |

### 2.2 Backend Stack

| Component | Technology | Version |
|-----------|------------|---------|
| **Framework** | FastAPI | 0.109.0+ |
| **Runtime** | Python | 3.11+ |
| **Database** | PostgreSQL + TimescaleDB | 15+ |
| **Cache** | Redis | Latest |
| **ORM** | SQLAlchemy | 2.0+ (async) |

### 2.3 AI/ML Stack

| Model | Provider | Purpose |
|-------|----------|---------|
| **Grok 4 Fast** | xAI | Roasting, casual chat (cheap, fast) |
| **Claude Sonnet 4** | Anthropic | Financial advice (nuanced) |
| **Gemini 2.0 Flash** | Google | Intent routing, categorization (fast) |

---

## 3. DATA MODELS

### 3.1 iOS Models (Swift)

```swift
// MARK: - Authentication

struct AuthResponse: Codable {
    let jwt: String
    let userId: String        // CodingKey: "user_id"
    let isNewUser: Bool       // CodingKey: "is_new_user"
}

struct AppleAuthRequest: Codable {
    let appleToken: String    // CodingKey: "apple_token"
    let userIdentifier: String?
}

// MARK: - Chat

struct ChatMessage: Identifiable, Codable {
    let id: String            // UUID string
    let role: MessageRole     // .user | .assistant
    let content: String
    let timestamp: Date
}

struct ChatRequest: Codable {
    let message: String
    let includeContext: Bool  // CodingKey: "include_context"
}

struct ChatResponse: Codable {
    let message: String
    let tokensUsed: TokenUsage?
    let model: String?
    let intent: String?
    let cost: Double?
    let latencyMs: Int?
}

struct TokenUsage: Codable {
    let input: Int
    let output: Int
}

// MARK: - Balance

struct BalanceSummary: Codable {
    let totalBalance: Double
    let availableBalance: Double
    let hiddenBalance: Double
    let pendingBalance: Double
    let safetyBuffer: Double
    let lastUpdated: String?
    let hiddenAccounts: [ShadowAccount]?
}

struct ShadowAccount: Codable, Identifiable {
    let id: String
    let balance: Double
    let purpose: String       // "savings_goal" | "forced_savings" | "emergency"
    let createdAt: String
}

// MARK: - Transactions

struct Transaction: Codable, Identifiable {
    let id: String
    let date: String          // ISO 8601 format
    let amount: Double        // Negative = expense, Positive = income
    let merchant: String
    let category: String
    let isBill: Bool
    let isPending: Bool
}

// MARK: - Bills

struct Bill: Codable, Identifiable {
    let id: String
    let merchant: String
    let amount: Double
    let frequency: String?    // "weekly" | "monthly" | "quarterly" | "yearly"
    let frequencyDays: Int?
    let nextDue: String       // ISO 8601 date
    let confidence: Double    // 0.0 - 1.0
    let category: String?
}

// MARK: - Goals

struct Goal: Codable, Identifiable {
    let id: String
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: String?
    var category: String
    var autoContribute: Bool
    var monthlyContribution: Double?
    let createdAt: String
}

// MARK: - Subscriptions

struct Subscription: Codable, Identifiable {
    let id: String
    let merchant: String
    let amount: Double
    let monthlyCost: Double
    let annualCost: Double
    let frequency: String
    let isUnused: Bool
    let confidence: Double
    let category: String
    let status: String        // "active" | "paused" | "cancelled"
}

// MARK: - User Profile

struct UserProfile: Codable {
    let userId: String?
    var name: String?
    var location: String?
    var employer: String?
    var salary: Double?
    var savingsGoal: SavingsGoal?
    var intensityMode: String? // "mild" | "moderate" | "insanity"
    var emergencyBuffer: Double?
    var learnedInsights: [String]?
}

struct SavingsGoal: Codable {
    let amount: Double
    let deadline: String
    let purpose: String
    let frequency: String?
    let amountPerPeriod: Double?
}

// MARK: - Plaid

struct PlaidLinkTokenResponse: Codable {
    let linkToken: String
}

struct PlaidExchangeResponse: Codable {
    let itemId: String
    let institutionName: String
}
```

### 3.2 Backend Models (PostgreSQL)

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    apple_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP
);

-- User Profiles
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    name VARCHAR(255),
    location VARCHAR(255),
    employer VARCHAR(255),
    salary DECIMAL(12,2),
    savings_goal JSONB,
    learned_insights TEXT[],
    spending_preferences JSONB,
    intensity_mode VARCHAR(50) DEFAULT 'moderate',
    emergency_buffer DECIMAL(10,2) DEFAULT 500.00,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transactions (TimescaleDB Hypertable)
CREATE TABLE transactions (
    id UUID DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    date TIMESTAMP NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    merchant VARCHAR(255),
    merchant_category_code VARCHAR(100),
    category VARCHAR(50),
    plaid_transaction_id VARCHAR(255),
    notes TEXT,
    is_bill BOOLEAN DEFAULT FALSE,
    is_recurring BOOLEAN DEFAULT FALSE,
    location_lat DECIMAL(10,7),
    location_lon DECIMAL(10,7),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id, date)
);

-- Bills
CREATE TABLE bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    merchant VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    frequency_days INTEGER,
    next_due_date DATE,
    confidence FLOAT DEFAULT 0.5,
    is_active BOOLEAN DEFAULT TRUE,
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Goals
CREATE TABLE goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    target_amount DECIMAL(12,2) NOT NULL,
    current_amount DECIMAL(12,2) DEFAULT 0,
    deadline DATE,
    icon VARCHAR(100),
    color VARCHAR(20),
    priority INTEGER DEFAULT 1,
    is_primary BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Subscriptions
CREATE TABLE subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    billing_cycle VARCHAR(50),
    next_billing_date DATE,
    category VARCHAR(50),
    importance VARCHAR(50) DEFAULT 'nice_to_have',
    auto_detected BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    cancelled_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Shadow Accounts (Hidden Savings)
CREATE TABLE shadow_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    bank_name VARCHAR(255),
    account_last_4 VARCHAR(4),
    balance DECIMAL(12,2) DEFAULT 0,
    purpose VARCHAR(100),
    reveal_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Conversations (Chat History)
CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Plaid Items
CREATE TABLE plaid_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    plaid_item_id VARCHAR(255) UNIQUE,
    plaid_access_token TEXT,
    institution_name VARCHAR(255),
    institution_id VARCHAR(255),
    last_synced TIMESTAMP,
    status VARCHAR(50) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Round-up Config
CREATE TABLE roundup_config (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    is_enabled BOOLEAN DEFAULT FALSE,
    round_up_amount VARCHAR(50) DEFAULT 'nearest_dollar',
    multiplier INTEGER DEFAULT 1,
    linked_goal_id UUID REFERENCES goals(id),
    transfer_frequency VARCHAR(50) DEFAULT 'weekly',
    min_transfer_amount DECIMAL(10,2) DEFAULT 5.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Spending Limits
CREATE TABLE spending_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    category VARCHAR(50) NOT NULL,
    limit_amount DECIMAL(10,2) NOT NULL,
    period VARCHAR(50) DEFAULT 'monthly',
    warning_threshold DECIMAL(3,2) DEFAULT 0.80,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wishlist
CREATE TABLE wishlist (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    url TEXT,
    image_url TEXT,
    priority INTEGER DEFAULT 3,
    category VARCHAR(50),
    notes TEXT,
    linked_goal_id UUID REFERENCES goals(id),
    is_active BOOLEAN DEFAULT TRUE,
    is_purchased BOOLEAN DEFAULT FALSE,
    purchased_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 4. FEATURE SPECIFICATIONS

### 4.1 Authentication (P0 - Must Have)

**Feature Name:** Sign in with Apple + JWT Authentication

**User Story:** As a user, I want to sign in securely with my Apple ID so that my financial data is protected.

**Acceptance Criteria:**
- User can sign in with Apple on launch
- JWT token stored securely in Keychain (NOT UserDefaults)
- Token auto-refreshes on API calls
- 30-day token expiration
- New users proceed to onboarding flow
- Returning users go directly to dashboard

**Edge Cases:**
- Apple ID verification failure → Show error, allow retry
- Network failure during auth → Cache credentials, retry with exponential backoff
- Token expired → Auto-refresh, if failed → Re-authenticate

### 4.2 AI Chat (P0 - Must Have)

**Feature Name:** FURG AI Financial Advisor

**User Story:** As a user, I want to chat with an AI that helps me manage finances and roasts my bad spending decisions.

**Acceptance Criteria:**
- Real-time chat with streaming responses
- Three personality modes: Mild, Moderate, Insanity
- Context-aware responses (includes balance, recent transactions, bills)
- Multi-model routing (Grok for roasts, Claude for advice, Gemini for routing)
- Chat history persistence
- Typing indicator during response generation

**Business Logic:**
- Roasting proportional to mistake severity
- Never let users spend bill money (2x upcoming bills + emergency buffer)
- Reference user's goals on questionable decisions
- Learn from every conversation

**Edge Cases:**
- Empty chat state → Show welcome message with suggested questions
- API timeout → Show "FURG is thinking..." then retry
- Rate limit exceeded → Show friendly message with cooldown timer

### 4.3 Bank Connection (P0 - Must Have)

**Feature Name:** Plaid Bank Linking

**User Story:** As a user, I want to connect my bank accounts so FURG can analyze my spending automatically.

**Acceptance Criteria:**
- Connect multiple banks via Plaid Link
- Support for checking, savings, credit cards
- Transaction sync with 90-day lookback
- Delta sync for incremental updates
- Automatic bill detection from transaction patterns
- Error handling for disconnected accounts

**Edge Cases:**
- Bank not supported → Show message, suggest alternative
- Credentials expired → Prompt re-authentication
- Sync failure → Retry with backoff, show last successful sync date

### 4.4 Dashboard (P0 - Must Have)

**Feature Name:** Financial Overview Dashboard

**User Story:** As a user, I want to see my financial health at a glance so I can make informed decisions.

**Acceptance Criteria:**
- Total balance across all accounts
- Hidden balance (shadow savings) separate
- Spending vs. ideal pace indicator
- Recent transactions (last 5-10)
- Upcoming bills (next 30 days)
- Goal progress visualization
- Quick action buttons (Ask AI, Add Transaction, Scan Receipt)

### 4.5 Transactions (P0 - Must Have)

**Feature Name:** Transaction Management

**User Story:** As a user, I want to view and categorize my transactions so I understand my spending.

**Acceptance Criteria:**
- Chronological transaction list
- Search by merchant or amount
- Filter by category, date range, bill status
- AI-powered category suggestions
- Manual category override with learning
- Export capability

**Categories (16):**
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

### 4.6 Goals (P0 - Must Have)

**Feature Name:** Savings Goals

**User Story:** As a user, I want to set and track savings goals so I can achieve my financial objectives.

**Acceptance Criteria:**
- Create goals with name, target amount, deadline
- Track progress with visual indicators
- Contribute manually or via round-ups
- Milestone notifications (25%, 50%, 75%, 100%)
- Goal prioritization
- Goal history/archive

**Milestones:** 10%, 25%, 50%, 75%, 90%, 100%

### 4.7 Shadow Banking (P1 - Should Have)

**Feature Name:** Hidden Savings

**User Story:** As a user, I want to hide money from myself so I can build forced savings.

**Acceptance Criteria:**
- Hide specific amounts with purpose
- Hidden balance not shown in "available" balance
- Reveal with optional delay
- Safety buffer enforcement (can't hide below 2x upcoming bills + emergency)
- Multiple shadow accounts per user

**Safety Buffer Formula:**
```
Safety Buffer = (Upcoming 30-day bills × 2) + Emergency Buffer
Default Emergency Buffer = $500
```

### 4.8 Bill Detection (P1 - Should Have)

**Feature Name:** Automatic Bill Detection

**User Story:** As a user, I want FURG to automatically detect my recurring bills so I never miss a payment.

**Acceptance Criteria:**
- Analyze 90-day transaction history
- Detect weekly, bi-weekly, monthly, quarterly, yearly patterns
- Confidence scoring (0.5 - 1.0)
- Manual confirmation/rejection
- Next due date prediction
- Bill reminder notifications

**Detection Logic:**
- Minimum 2 occurrences required
- Amount variance tolerance: 10%
- Date variance tolerance: ±3 days for monthly

### 4.9 Subscriptions (P1 - Should Have)

**Feature Name:** Subscription Management

**User Story:** As a user, I want to track my subscriptions and identify unused ones so I can save money.

**Acceptance Criteria:**
- Auto-detect subscriptions from transactions
- Flag unused subscriptions (no activity in 30 days)
- Cancellation guides per merchant
- Negotiation scripts for discounts
- Annual cost projection

### 4.10 Round-ups (P1 - Should Have)

**Feature Name:** Spare Change Savings

**User Story:** As a user, I want to automatically save spare change from purchases so I can grow savings effortlessly.

**Acceptance Criteria:**
- Round up to nearest $1, $2, or $5
- Multiplier option (1x - 10x)
- Link to specific goal
- Minimum transfer threshold
- Weekly/monthly transfer frequency

**Formula:**
```
roundup_amount = round_to - (amount % round_to)
final_amount = roundup_amount × multiplier
```

### 4.11 Shopping Assistant (P1 - Should Have)

**Feature Name:** AI Shopping Mode

**User Story:** As a user, I want AI-powered shopping help to find deals and make smart purchases.

**Acceptance Criteria:**
- Product search with filters
- Price comparison across retailers
- Deal alerts and tracking
- Credit card recommendations per merchant
- Shopping list management
- Price history and predictions

### 4.12 Spending Limits (P2 - Nice to Have)

**Feature Name:** Category Budgets

**User Story:** As a user, I want to set spending limits per category so I stay within budget.

**Acceptance Criteria:**
- Set limits by category and period (daily/weekly/monthly)
- Warning at 80% threshold
- Real-time tracking
- Push notifications when exceeded

### 4.13 Forecast (P2 - Nice to Have)

**Feature Name:** Cash Flow Prediction

**User Story:** As a user, I want to see my projected balance so I can plan ahead.

**Acceptance Criteria:**
- 30-day balance projection
- Factor in upcoming bills
- Average income/expense calculation
- Risk level indicator
- Daily breakdown view

### 4.14 Achievements (P2 - Nice to Have)

**Feature Name:** Gamification Badges

**User Story:** As a user, I want to earn achievements so I feel motivated to maintain good habits.

**Achievements:**
- First $1K Saved
- 30-Day Streak
- Debt Free
- Budget Master (3 months under budget)
- Round-up Rookie
- Subscription Slayer

---

## 5. SCREEN-BY-SCREEN BREAKDOWN

### 5.1 Authentication Flow

| Screen | File | Parent | Elements |
|--------|------|--------|----------|
| WelcomeView | `WelcomeView.swift` | Root | Animated logo, feature cards, Sign in with Apple button |
| OnboardingView | `OnboardingView.swift` | Post-auth | 5-step wizard: Name → Salary → Goal → Intensity → Bank connection |

### 5.2 Main Navigation (TabView)

| Tab | Screen | File | Icon |
|-----|--------|------|------|
| 0 | Dashboard | `DashboardView.swift` | `chart.bar.fill` |
| 1 | Chat | `ChatView.swift` | `message.fill` |
| 2 | Activity | `TransactionsListView.swift` | `list.bullet.rectangle` |
| 3 | Accounts | `AccountsView.swift` | `creditcard.fill` |
| 4 | Settings | `SettingsView.swift` | `gearshape.fill` |

### 5.3 Dashboard (Tab 0)

**File:** `DashboardView.swift`

**Elements:**
- Net worth header with sparkline chart
- Quick stats row (spending, income, saved)
- Budget pace indicator
- Recent transactions list (5 items)
- Upcoming bills card
- Goal progress rings
- AI insight card
- FAB (Floating Action Button) with quick actions

**Data Requirements:** Balance summary, transactions (7 days), bills (30 days), goals

### 5.4 Chat (Tab 1)

**File:** `ChatView.swift`

**Elements:**
- Message list (ScrollView)
- Typing indicator
- Suggestion chips (pre-filled prompts)
- Text input with send button
- Context indicator (shows what FURG knows)

**States:**
- Empty: Welcome message + suggested questions
- Loading: Typing indicator animation
- Error: Retry button

### 5.5 Transactions (Tab 2)

**File:** `TransactionsListView.swift`

**Elements:**
- Search bar
- Filter pills (All, Income, Expenses, Bills, Pending)
- Date range picker
- Transaction rows with swipe actions
- Category breakdown summary

**Navigation Destinations:**
- TransactionDetailView (on tap)
- TransactionClarificationView (on category conflict)

### 5.6 Accounts (Tab 3)

**File:** `AccountsView.swift`

**Elements:**
- Net worth summary
- Connected accounts list
- Add bank button (opens Plaid Link)
- Account cards with balances
- Asset/Liability toggle

**Navigation Destinations:**
- AccountDetailView (on account tap)
- ConnectBankView (add new)

### 5.7 Settings (Tab 4)

**File:** `SettingsView.swift`

**Elements:**
- Profile section (name, avatar)
- FURG personality slider (Mild/Moderate/Insanity)
- Notification preferences
- Data export
- Privacy policy
- Sign out button

### 5.8 Tools Hub

**File:** `ToolsHubView.swift`

**Access:** Via Settings or Dashboard

**Features Grid:**
- Goals (`GoalsView.swift`)
- Subscriptions (`SubscriptionsView.swift`)
- Round-ups (`EnhancedRoundUpsView.swift`)
- Shopping (`ShoppingChatView.swift`)
- Deals (`DealsSearchView.swift`)
- Card Recommendations (`CardRecommendationsView.swift`)
- Merchant Intelligence (`MerchantIntelligenceView.swift`)
- Investment Portfolio (`InvestmentPortfolioView.swift`)
- Life Integration (`LifeIntegrationView.swift`)
- Spending Analytics (`SpendingAnalyticsView.swift`)
- Forecast (`ForecastView.swift`)
- Achievements (`AchievementsView.swift`)

---

## 6. API CONTRACTS

### 6.1 Authentication

#### POST `/api/v1/auth/apple`
Exchange Apple token for JWT.

**Request:**
```json
{
    "apple_token": "string",
    "user_identifier": "string?"
}
```

**Response (200):**
```json
{
    "jwt": "string",
    "user_id": "uuid",
    "is_new_user": boolean
}
```

#### GET `/api/v1/auth/me`
Get current user info.

**Headers:** `Authorization: Bearer {jwt}`

**Response (200):**
```json
{
    "user_id": "uuid",
    "email": "string?",
    "created_at": "datetime",
    "profile": { ... }
}
```

### 6.2 Chat

#### POST `/api/v1/chat`
Send message to FURG.

**Request:**
```json
{
    "message": "string",
    "include_context": boolean
}
```

**Response (200):**
```json
{
    "message": "string",
    "tokens_used": { "input": int, "output": int },
    "model": "string",
    "intent": "string",
    "cost": float,
    "latency_ms": int
}
```

#### GET `/api/v1/chat/history?limit=50`
**Response (200):**
```json
{
    "messages": [
        { "role": "user|assistant", "content": "string", "timestamp": "datetime" }
    ]
}
```

### 6.3 Transactions

#### GET `/api/v1/transactions?days=30&limit=100`
**Response (200):**
```json
{
    "transactions": [
        {
            "id": "uuid",
            "date": "datetime",
            "amount": float,
            "merchant": "string",
            "category": "string",
            "is_bill": boolean
        }
    ]
}
```

#### GET `/api/v1/transactions/spending?days=30`
**Response (200):**
```json
{
    "total_spent": float,
    "by_category": { "category": float },
    "period_days": int
}
```

### 6.4 Balance

#### GET `/api/v1/balance`
**Response (200):**
```json
{
    "total_balance": float,
    "visible_balance": float,
    "hidden_balance": float,
    "safety_buffer": float,
    "hidden_accounts": [
        { "id": "uuid", "balance": float, "purpose": "string" }
    ]
}
```

#### POST `/api/v1/money/hide`
**Request:**
```json
{
    "amount": float,
    "purpose": "string"
}
```

### 6.5 Bills

#### GET `/api/v1/bills`
**Response (200):**
```json
{
    "bills": [
        {
            "merchant": "string",
            "amount": float,
            "frequency_days": int,
            "next_due": "date",
            "confidence": float
        }
    ]
}
```

#### POST `/api/v1/bills/detect?days_lookback=90`
Run bill detection algorithm.

### 6.6 Goals

#### GET `/api/v1/goals`
**Response (200):**
```json
{
    "goals": [ ... ],
    "total_target": float,
    "total_saved": float,
    "overall_progress": float
}
```

#### POST `/api/v1/goals`
**Request:**
```json
{
    "name": "string",
    "target_amount": float,
    "deadline": "date?",
    "category": "string",
    "auto_contribute": boolean,
    "monthly_contribution": float?
}
```

#### POST `/api/v1/goals/{id}/contribute`
**Request:**
```json
{
    "goal_id": "uuid",
    "amount": float
}
```

### 6.7 Plaid

#### POST `/api/v1/plaid/link-token`
**Response:** `{ "link_token": "string" }`

#### POST `/api/v1/plaid/exchange`
**Request:** `{ "public_token": "string" }`

#### POST `/api/v1/plaid/sync-all`
Sync all connected banks.

### 6.8 Full API Summary

| Category | Endpoints |
|----------|-----------|
| Health | 2 |
| Auth | 2 |
| Chat | 4 |
| Plaid | 6 |
| Transactions | 2 |
| Bills | 3 |
| Balance/Money | 4 |
| Profile | 2 |
| Subscriptions | 5 |
| Goals | 7 |
| Round-ups | 5 |
| Forecast | 3 |
| Spending Limits | 3 |
| Wishlist | 5 |
| Achievements | 1 |
| Usage | 1 |
| Shopping | 12 |
| Deals | 14 |
| **TOTAL** | **81** |

---

## 7. FILE STRUCTURE

```
cuponer/
├── ios/
│   └── Furg/
│       ├── App/
│       │   ├── FurgApp.swift                    # Main entry point
│       │   ├── AppDelegate.swift                 # Push notifications, lifecycle
│       │   ├── DesignSystem.swift                # Colors, fonts, gradients, components
│       │   ├── Config.swift                      # Configuration constants
│       │   └── EnvironmentSetup.swift            # Manager initialization
│       │
│       ├── Views/
│       │   ├── MainTabView.swift                 # Root TabView navigation
│       │   ├── ToolsHubView.swift                # Premium features grid
│       │   │
│       │   ├── # Core Screens
│       │   ├── DashboardView.swift
│       │   ├── HomeView.swift
│       │   ├── ChatView.swift
│       │   ├── TransactionsListView.swift
│       │   ├── AccountsView.swift
│       │   ├── SettingsView.swift
│       │   │
│       │   ├── # Financial Features
│       │   ├── GoalsView.swift
│       │   ├── SubscriptionsView.swift
│       │   ├── EnhancedRoundUpsView.swift
│       │   ├── SpendingAnalyticsView.swift
│       │   ├── SpendingLimitsView.swift
│       │   ├── CashFlowView.swift
│       │   ├── ForecastView.swift
│       │   ├── DebtPayoffView.swift
│       │   │
│       │   ├── # Shopping & Deals
│       │   ├── ShoppingChatView.swift
│       │   ├── DealsSearchView.swift
│       │   ├── DealsView.swift
│       │   ├── OffersView.swift
│       │   ├── WishlistView.swift
│       │   ├── CardRecommendationsView.swift
│       │   │
│       │   ├── # Intelligence Features
│       │   ├── MerchantIntelligenceView.swift
│       │   ├── InvestmentPortfolioView.swift
│       │   ├── LifeIntegrationView.swift
│       │   │
│       │   ├── # Utility Screens
│       │   ├── ConnectBankView.swift
│       │   ├── ReceiptScanView.swift
│       │   ├── AchievementsView.swift
│       │   ├── BillSplitView.swift
│       │   │
│       │   └── Components/
│       │       ├── NavigationHeader.swift
│       │       ├── UnifiedComponents.swift
│       │       ├── PillTabBar.swift
│       │       └── QuickDebtPaymentSheet.swift
│       │
│       ├── Services/
│       │   ├── # Core Services
│       │   ├── AuthManager.swift
│       │   ├── APIClient.swift
│       │   ├── KeychainService.swift
│       │   ├── KeychainHelper.swift
│       │   │
│       │   ├── # Financial Managers
│       │   ├── FinanceManager.swift
│       │   ├── PlaidManager.swift
│       │   ├── GoalsManager.swift (TBD)
│       │   ├── RoundUpManager.swift (TBD)
│       │   ├── SubscriptionManager.swift
│       │   ├── SpendingLimitsManager.swift (TBD)
│       │   │
│       │   ├── # AI/Intelligence
│       │   ├── ChatManager.swift (TBD)
│       │   ├── RecommendationEngine.swift
│       │   ├── SmartCategorizationManager.swift (TBD)
│       │   ├── SpendingPredictionManager.swift
│       │   ├── MerchantIntelligenceManager.swift
│       │   │
│       │   ├── # Shopping
│       │   ├── ShoppingAssistantManager.swift
│       │   ├── ShoppingIntelligenceManager.swift
│       │   ├── WishlistManager.swift
│       │   ├── DealsManager.swift (TBD)
│       │   │
│       │   ├── # Specialized
│       │   ├── IncomeManager.swift
│       │   ├── InvestmentPortfolioManager.swift
│       │   ├── LifeContextManager.swift
│       │   ├── HealthKitManager.swift
│       │   ├── LocationManager.swift
│       │   ├── ReceiptScannerManager.swift
│       │   ├── AchievementsManager.swift
│       │   │
│       │   └── # Utilities
│       │       ├── CacheManager.swift
│       │       ├── NotificationManager.swift (TBD)
│       │       ├── DataExportManager.swift
│       │       └── ShortcutsManager.swift
│       │
│       ├── Models/
│       │   ├── Models.swift                      # Core models
│       │   ├── DealsModels.swift
│       │   └── LifeModels.swift
│       │
│       └── Resources/
│           └── Assets.xcassets
│
├── backend/
│   ├── main.py                                   # FastAPI app, all routes
│   ├── auth.py                                   # JWT, Apple verification
│   ├── database.py                               # PostgreSQL models, queries
│   ├── rate_limiter.py                           # Rate limiting logic
│   │
│   ├── services/
│   │   ├── chat.py                               # Legacy single-model
│   │   ├── chat_v2.py                            # Multi-model routing
│   │   ├── plaid_service.py
│   │   ├── bill_detection.py
│   │   ├── shadow_banking.py
│   │   ├── deals_service.py
│   │   ├── gemini_service.py
│   │   ├── grok_service.py
│   │   ├── openai_shopping.py
│   │   ├── model_router.py
│   │   └── context_cache.py
│   │
│   ├── ml/
│   │   └── categorizer.py                        # Transaction categorization
│   │
│   ├── .env                                      # Environment config
│   └── requirements.txt
│
├── database/
│   └── schema.sql                                # Database migrations
│
├── scripts/
│   ├── setup.sh
│   └── setup-github-secrets.sh
│
├── docs/
│   ├── API_REFERENCE.md
│   ├── IMPLEMENTATION_SUMMARY.md
│   ├── MULTI_MODEL_ARCHITECTURE.md
│   └── QUICK_START.md
│
├── CLAUDE.md                                     # Claude development guide
├── REQUIREMENTS.md                               # Original requirements doc
├── docker-compose.yml
└── README.md
```

---

## 8. DEPENDENCIES

### 8.1 iOS (Swift Package Manager)

```swift
// Package.swift or Xcode SPM
dependencies: [
    // None required - using native frameworks only
    // Optional future additions:
    // .package(url: "https://github.com/plaid/plaid-link-ios", from: "5.0.0"),
]
```

**Native Frameworks Used:**
- SwiftUI
- Charts (iOS 16+)
- AuthenticationServices (Sign in with Apple)
- Security (Keychain)
- WebKit (Plaid Link webview)
- CoreLocation (optional, for location features)
- HealthKit (optional, for health correlation)

### 8.2 Backend (Python)

```txt
# requirements.txt
fastapi>=0.109.0
uvicorn>=0.27.0
python-jose>=3.3.0
passlib>=1.7.4
bcrypt>=4.1.2
asyncpg>=0.29.0
SQLAlchemy>=2.0.25
pydantic>=2.5.3
httpx>=0.26.0
plaid-python>=15.0.0
anthropic>=0.18.0
google-generativeai>=0.4.0
openai>=1.12.0
redis>=5.0.1
python-multipart>=0.0.6
python-dotenv>=1.0.0
```

---

## 9. CONFIGURATION

### 9.1 iOS Info.plist

```xml
<key>CFBundleIdentifier</key>
<string>com.furg.app</string>

<key>CFBundleDisplayName</key>
<string>FURG</string>

<key>NSFaceIDUsageDescription</key>
<string>Use Face ID to securely access your financial data</string>

<key>NSCameraUsageDescription</key>
<string>Scan receipts to automatically track expenses</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>Find nearby deals and offers based on your location</string>

<key>NSHealthShareUsageDescription</key>
<string>Correlate health data with spending patterns</string>
```

### 9.2 Entitlements

```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>

<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.furg.app</string>
</array>
```

### 9.3 Backend Environment (.env)

```bash
# Debug
DEBUG=false

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/furg

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=your-256-bit-secret-key
JWT_ALGORITHM=HS256
JWT_EXPIRATION_DAYS=30

# Apple Sign In
APPLE_CLIENT_ID=com.furg.app
APPLE_TEAM_ID=YOUR_TEAM_ID
APPLE_KEY_ID=YOUR_KEY_ID
APPLE_PRIVATE_KEY_PATH=./AuthKey.p8

# Plaid
PLAID_CLIENT_ID=your_plaid_client_id
PLAID_SECRET=your_plaid_secret
PLAID_ENV=sandbox  # sandbox | development | production

# AI APIs
ANTHROPIC_API_KEY=sk-ant-...
GOOGLE_API_KEY=AIza...
XAI_API_KEY=xai-...
OPENAI_API_KEY=sk-...

# Rate Limiting
RATE_LIMIT_REQUESTS_PER_MINUTE=10
RATE_LIMIT_TOKENS_PER_DAY=100000
RATE_LIMIT_COST_PER_DAY=5.00
```

---

## 10. TESTING REQUIREMENTS

### 10.1 Unit Test Coverage Targets

| Component | Target | Priority |
|-----------|--------|----------|
| AuthManager | 90% | P0 |
| APIClient | 85% | P0 |
| FinanceManager | 80% | P0 |
| ChatManager | 75% | P1 |
| Bill Detection | 85% | P1 |
| Categorization | 80% | P1 |

### 10.2 Test Scenarios

**Authentication:**
- Valid Apple token → Success
- Invalid token → Error
- Expired JWT → Auto-refresh
- Network failure → Retry

**Chat:**
- Message sent → Response received
- Context included → Relevant response
- Rate limit → Appropriate error
- Multi-model routing → Correct model selected

**Transactions:**
- Fetch transactions → Correct list
- Category filter → Filtered results
- Search → Matching results
- Empty state → Appropriate UI

**Bills:**
- Detection accuracy → >80% precision
- Next due date → Correct calculation
- Frequency detection → Correct pattern

### 10.3 Mock Requirements

- MockAPIClient for network calls
- MockKeychainService for credential storage
- MockPlaidManager for bank connections
- MockChatService for AI responses

---

## 11. ERROR HANDLING STRATEGY

### 11.1 Error Enums

```swift
enum FurgError: LocalizedError {
    // Network
    case networkUnavailable
    case timeout
    case serverError(Int)

    // Auth
    case authenticationFailed
    case tokenExpired
    case unauthorized

    // Plaid
    case plaidLinkFailed(String)
    case bankConnectionFailed
    case syncFailed

    // Data
    case invalidData
    case notFound
    case insufficientFunds

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Check your network and try again."
        case .timeout:
            return "Request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). We're working on it!"
        case .authenticationFailed:
            return "Sign in failed. Please try again."
        case .tokenExpired:
            return "Session expired. Please sign in again."
        case .unauthorized:
            return "You don't have permission for this action."
        case .plaidLinkFailed(let reason):
            return "Bank connection failed: \(reason)"
        case .bankConnectionFailed:
            return "Couldn't connect to your bank. Try again later."
        case .syncFailed:
            return "Couldn't sync transactions. Using cached data."
        case .invalidData:
            return "Something went wrong. Please try again."
        case .notFound:
            return "Couldn't find what you're looking for."
        case .insufficientFunds:
            return "Not enough money for this action."
        }
    }
}
```

### 11.2 Error Propagation

1. **Network errors** → Retry with exponential backoff (2s, 4s, 8s, 16s)
2. **Auth errors** → Attempt token refresh, then re-auth
3. **Data errors** → Show user-friendly message, log to backend
4. **Critical errors** → Show error screen with retry button

### 11.3 User-Facing Messages

- Keep messages friendly and actionable
- Never show raw error codes or stack traces
- Provide retry option when possible
- Use FURG's personality for error messages (light roasts)

---

## 12. IMPLEMENTATION ORDER

### Phase 1: Foundation (Week 1-2)

1. **Project setup**
   - Xcode project with bundle ID
   - FastAPI backend skeleton
   - PostgreSQL database with initial schema
   - Docker Compose for local development

2. **Authentication**
   - Sign in with Apple integration
   - JWT token management
   - Keychain storage
   - Auth endpoints

3. **Core navigation**
   - MainTabView structure
   - Basic view scaffolding
   - Design system implementation

### Phase 2: Core Features (Week 3-4)

4. **API Client**
   - URLSession wrapper
   - Error handling
   - Token refresh logic

5. **Plaid Integration**
   - Link token creation
   - Bank connection flow
   - Transaction sync

6. **Dashboard**
   - Balance display
   - Recent transactions
   - Basic charts

7. **Transactions**
   - Transaction list
   - Search and filter
   - Category display

### Phase 3: Intelligence (Week 5-6)

8. **AI Chat**
   - Chat UI
   - Multi-model backend
   - Context building
   - Streaming responses

9. **Bill Detection**
   - Detection algorithm
   - Confidence scoring
   - Bill management UI

10. **Transaction Categorization**
    - Rule-based categorization
    - ML fallback
    - User corrections

### Phase 4: Savings Features (Week 7-8)

11. **Goals**
    - CRUD operations
    - Progress tracking
    - Milestone notifications

12. **Shadow Banking**
    - Hide/reveal money
    - Safety buffer enforcement

13. **Round-ups**
    - Configuration
    - Automatic calculation
    - Goal linking

### Phase 5: Advanced Features (Week 9-10)

14. **Subscriptions**
    - Detection
    - Management UI
    - Cancellation guides

15. **Spending Limits**
    - CRUD operations
    - Tracking
    - Notifications

16. **Forecast**
    - Projection algorithm
    - Visualization

### Phase 6: Shopping & Polish (Week 11-12)

17. **Shopping Assistant**
    - Chat interface
    - Deal search
    - Price tracking

18. **Achievements**
    - Badge system
    - Progress tracking

19. **Polish**
    - Error handling
    - Edge cases
    - Performance optimization
    - UI refinement

---

## Quality Checklist

- [x] Every feature has concrete acceptance criteria
- [x] Every screen has defined UI elements and states
- [x] Every model has complete property definitions
- [x] Every navigation path is specified
- [x] Every error case has a handling strategy
- [x] Implementation order has no circular dependencies
- [x] No "TBD" or "to be determined" in critical paths

---

*Document Version: 2.0*
*Generated: December 2024*
*For use with Claude AI autonomous implementation*
