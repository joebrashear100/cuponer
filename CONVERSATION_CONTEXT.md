# Furg iOS App - Development Context

## Project Overview
Furg is a personal finance iOS app built with SwiftUI. The app helps users track spending, manage budgets, set savings goals, and get AI-powered financial insights.

## Current State (as of December 7, 2025)
- **Version:** 1.6 (Build 6)
- **Bundle ID:** com.furg.app
- **Team ID:** 49L3FP3ZKR
- **Deployment Target:** iOS 17.0
- **Xcode Version:** 16.4

## Key Features Implemented
1. **Dashboard View** - Net worth display, quick insights, financial health score
2. **Home View** - Spending power, quick actions, AI insights, recent activity
3. **Cash Flow View** - Income/spending analysis, trend charts, category breakdown
4. **Spending Dashboard** - Detailed spending analytics, budget tracking by category
5. **Goals View** - Savings goals with progress tracking
6. **Transactions List** - Full transaction history with detail sheets
7. **Settings** - Round-up settings, notifications, bank connections
8. **Offers View** - Deals and offers with website links
9. **Categories View** - Spending by category visualization

## Recent Changes (This Session)

### UI Fixes
1. Fixed green hue bleeding under net worth card - Added clipShape to sparkline
2. Fixed Income/Spending text overflow - Changed labels to "In"/"Out"/"Saved"
3. Fixed Cash Flow Trend tabs - Made compact full-width buttons
4. Added Savings bucket to CashFlowView
5. Fixed all sheet backgrounds with `.presentationBackground(Color.furgCharcoal)`

### New Features
1. **SpendingDashboardView** - Comprehensive spending analytics:
   - Timeframe selector (Week/Month/Quarter/Year)
   - Overview metrics cards
   - Spending trend chart
   - Budget progress bar
   - Category breakdown with per-category budgets
   - AI spending insights

2. **TransactionDetailSheet** - Shows full transaction details when tapping a transaction

### CI/CD Setup
- GitHub Actions workflow created: `.github/workflows/ios-testflight.yml`
- Setup script: `scripts/setup-github-secrets.sh`
- Documentation: `docs/TESTFLIGHT_SETUP.md`
- ExportOptions.plist for App Store distribution

## Pending Items

### Apple Developer Account
- Membership is being processed (24-48 hours)
- Once active, need to:
  1. Create Apple Distribution certificate
  2. Create App Store provisioning profile
  3. Register iPhone device
  4. Set up App Store Connect API key
  5. Add GitHub secrets for CI/CD

### Liquid Glass UI Redesign
- Requires Xcode 26 beta and iOS 26
- New APIs to use:
  - `.glassEffect()` modifier
  - `GlassEffectContainer`
  - `.buttonStyle(.glass)` and `.buttonStyle(.glassProminent)`
  - Bottom-positioned navigation
  - Floating glass controls

## Project Structure
```
ios/
├── Furg.xcodeproj/
├── Furg/
│   ├── App/
│   │   ├── FurgApp.swift
│   │   ├── Config.swift
│   │   └── DesignSystem.swift
│   ├── Models/
│   │   ├── Models.swift
│   │   ├── WishlistModels.swift
│   │   ├── GoalsModels.swift
│   │   └── SubscriptionModels.swift
│   ├── Services/
│   │   ├── APIClient.swift
│   │   ├── AuthManager.swift
│   │   ├── ChatManager.swift
│   │   ├── FinanceManager.swift
│   │   ├── FinanceKitManager.swift
│   │   ├── ForecastingManager.swift
│   │   ├── GoalsManager.swift
│   │   ├── KeychainService.swift
│   │   ├── PlaidManager.swift
│   │   ├── ReceiptScanner.swift
│   │   ├── RoundUpManager.swift
│   │   ├── SpendingLimitsManager.swift
│   │   ├── SubscriptionManager.swift
│   │   ├── ClaudeService.swift
│   │   └── WishlistManager.swift
│   ├── Views/
│   │   ├── AccountsView.swift
│   │   ├── AppleWalletView.swift
│   │   ├── BalanceView.swift
│   │   ├── CashFlowView.swift
│   │   ├── CategoriesView.swift
│   │   ├── ChatView.swift
│   │   ├── ConnectBankView.swift
│   │   ├── DashboardView.swift
│   │   ├── FinancingCalculatorView.swift
│   │   ├── ForecastView.swift
│   │   ├── GoalsView.swift
│   │   ├── HomeView.swift
│   │   ├── MainTabView.swift
│   │   ├── OffersView.swift
│   │   ├── OnboardingView.swift
│   │   ├── PurchasePlanView.swift
│   │   ├── ReceiptScanView.swift
│   │   ├── RoundUpSettingsView.swift
│   │   ├── SettingsView.swift
│   │   ├── SpendingAnalyticsView.swift
│   │   ├── SpendingDashboardView.swift
│   │   ├── SpendingLimitsView.swift
│   │   ├── SubscriptionsView.swift
│   │   ├── TransactionsView.swift
│   │   ├── TransactionsListView.swift
│   │   ├── WelcomeView.swift
│   │   └── WishlistView.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── Info.plist
│   └── Furg.entitlements
├── ExportOptions.plist
└── build/ (gitignored)
```

## Design System
- **Primary Colors:** furgMint, furgSeafoam, furgPistachio
- **Background:** furgCharcoal (dark)
- **Accents:** furgSuccess (green), furgWarning (yellow), furgDanger (red), furgInfo (blue)
- **Glass Effects:** Using `.ultraThinMaterial` and `.glassCard()` modifier
- **Animations:** Spring animations with AnimatedMeshBackground

## GitHub Repository
- URL: https://github.com/joebrashear100/cuponer
- Branch: main
- Latest commit includes all UI fixes and SpendingDashboardView

## API Endpoints (Backend)
- Base URL configured in Config.swift
- Plaid integration for bank connections
- Claude AI service for chat/insights

## Next Steps When Resuming
1. Check if Apple Developer membership is active
2. If active: Set up TestFlight deployment
3. Install Xcode 26 beta for Liquid Glass redesign
4. Implement real Liquid Glass UI with new APIs
5. Continue UI polish based on user feedback

## User Feedback Items Mentioned
- Credit factors should include more detailed data
- App should recognize better debit/credit card options based on spending
- Bill negotiation feature needed
- Clicking on savings rate should show detailed data
- Clicking on asset allocation should show allocation optimization
- Account details when clicking accounts
- Categories scrolling issue mentioned

## Technical Notes
- Using @AppStorage for local persistence
- EventKit integration for reminders
- os.log Logger for proper logging
- Pull-to-refresh on main views
- Sheet presentations with dark backgrounds
