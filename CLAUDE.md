# Claude Development Guide for Cuponer

**Last Updated:** December 2024
**Project:** Cuponer iOS + Backend
**Type:** FinTech mobile app with AI assistant

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture & Structure](#architecture--structure)
3. [Git Workflow (Distributed)](#git-workflow-distributed)
4. [Build & Deployment](#build--deployment)
5. [UI Verification System](#ui-verification-system)
6. [Token Optimization](#token-optimization)
7. [Common Pitfalls](#common-pitfalls)
8. [SwiftUI Development & Debugging](#swiftui-development--debugging)
9. [Decision Framework](#decision-framework)

---

## Project Overview

**Cuponer** is a chat-first financial AI app with a roasting personality.

**Tech Stack:**
- **iOS:** Swift + SwiftUI (Xcode 15+)
- **Backend:** Python (FastAPI) + PostgreSQL
- **Design System:** V2 Midnight Emerald (dark theme, emerald green, coral accents)
- **State Management:** SwiftUI @StateObject, EnvironmentObject
- **Auth:** JWT tokens (stored in Keychain, NOT UserDefaults)

**Core Features:**
- Budget tracking & visualization
- Smart spending alerts
- AI chat financial advisor
- Plaid bank integration
- Goal tracking
- Receipt scanning (OCR)
- Bill reminders
- Subscription management
- Wishlist & offers
- Card recommendations
- Merchant intelligence
- Investment portfolio tracking
- Life integration features

---

## Architecture & Structure

### iOS Project (`/ios/Furg`)

```
Furg/
├── App/
│   ├── FurgApp.swift              ← Main entry point
│   ├── AppDelegate.swift           ← Push notifications, lifecycle
│   ├── DesignSystem.swift          ← Colors, fonts, gradients
│   ├── Config.swift                ← Configuration
│   └── EnvironmentSetup.swift      ← Manager initialization
│
├── Views/
│   ├── V2/                         ← Modern gesture-based UI (IN DEVELOPMENT)
│   │   └── [V2 views being rebuilt]
│   │
│   ├── MainTabView.swift           ← Current main navigation
│   ├── ToolsHubView.swift          ← Premium features hub
│   ├── HomeView.swift              ← Dashboard
│   ├── DashboardView.swift         ← Dashboard alternative
│   ├── ChatView.swift              ← AI assistant
│   ├── GoalsView.swift             ← Goals tracking
│   ├── DealsSearchView.swift       ← Deals/offers
│   ├── DealsView.swift             ← Deals alternative
│   ├── ShoppingChatView.swift      ← Shopping assistant
│   ├── CardRecommendationsView.swift
│   ├── MerchantIntelligenceView.swift
│   ├── InvestmentPortfolioView.swift
│   ├── LifeIntegrationView.swift
│   ├── [40+ other feature views]
│   └── Components/                 ← Reusable UI components
│
├── Services/
│   ├── AuthManager.swift           ← Auth state, Keychain tokens
│   ├── FinanceManager.swift        ← Transaction, budget, category data
│   ├── ChatManager.swift           ← AI chat state
│   ├── PlaidManager.swift          ← Bank connections
│   ├── DealsManager.swift          ← Deals/offers
│   ├── ShoppingAssistantManager.swift
│   ├── APIClient.swift             ← Backend API communication
│   ├── KeychainService.swift       ← Secure credential storage
│   ├── [20+ other managers]
│   └── KeychainHelper.swift        ← Additional Keychain utilities (NEW)
│
└── Models/
    ├── Models.swift
    ├── DealsModels.swift
    ├── LifeModels.swift
    └── [Other data models]
```

### Backend (`/backend`)

```
backend/
├── main.py                 ← FastAPI app, routes, CORS
├── database.py             ← PostgreSQL models, queries
├── services/               ← Business logic
│   ├── chat_v2.py
│   ├── context_cache.py
│   ├── deals_service.py
│   ├── gemini_service.py
│   ├── grok_service.py
│   ├── model_router.py
│   └── openai_shopping.py
├── .env                    ← Config (DEBUG=false, DATABASE_URL, etc)
└── requirements.txt        ← Dependencies
```

---

## Git Workflow (Distributed)

**CRITICAL:** You work from multiple locations (local machine + GitHub web interface + other machines).

### ✅ Always Do This

**Before starting work:**
```bash
git fetch origin                    # See what's on GitHub
git status                          # Check local state
git branch -vv                      # See tracking relationship
```

**When pulling origin changes:**
```bash
git fetch origin
git pull origin main --no-ff        # Merge (not rebase) to preserve history
```

**Before pushing:**
```bash
git fetch origin                    # Make sure you have latest
git diff origin/main...HEAD         # Review what you're pushing
git push                            # Push your commits
```

### ❌ Never Do This

- ❌ Force push to main/master (`git push --force`)
- ❌ Hard reset without confirming (`git reset --hard`)
- ❌ Rebase public branches that others use
- ❌ Merge with uncommitted changes
- ❌ Start work without `git fetch origin` first

### Branch Strategy

**For feature work:**
```bash
git fetch origin                    # Get latest first
git checkout -b feature/description
# Make commits, push daily
git push -u origin feature/description
# Create PR on GitHub
```

**Divergence Warning:**
If `git status` shows "your branch and origin have diverged":
1. **STOP** - Don't force push
2. **`git fetch origin`** - See what's different
3. **`git log main..origin/main --oneline`** - See what you don't have
4. **`git pull origin main --no-ff`** - Merge (not rebase) to fix

### Why This Matters

**Previous Issue:** Local and origin diverged (you 12 commits ahead, origin 31 ahead). This caused 62 merge conflicts when trying to merge because both had modified the same files.

**Prevention:**
- Fetch before starting work
- Pull regularly if working across machines
- Use feature branches for major work
- Merge (--no-ff) instead of rebase on shared branches
- Push daily to avoid long divergences

---

## Build & Deployment

### Local Build

**Clean build (use this when things are broken):**
```bash
xcodebuild clean -scheme Furg
rm -rf ~/Library/Developer/Xcode/DerivedData/Furg*
xcodebuild build -scheme Furg -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

**Incremental build:**
```bash
xcodebuild build -scheme Furg -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

**Install on simulator:**
```bash
xcodebuild install -scheme Furg -destination "platform=iOS Simulator,name=iPhone 16 Pro"
```

### Common Issues

| Problem | Solution |
|---------|----------|
| Old app shows on simulator | Clean derived data + uninstall app + rebuild |
| "Cannot find X in scope" | File not in Xcode project target |
| Build succeeds but crashes | Check console logs, likely runtime error in a view |
| Type errors with managers | Check if manager is in EnvironmentObject chain |

### Credentials & Secrets

**CRITICAL SECURITY:**
- ✅ JWT tokens → Keychain (KeychainHelper.swift, KeychainService.swift)
- ✅ API keys → Environment variables
- ✅ Sensitive data → Keychain only
- ❌ NEVER store in UserDefaults
- ❌ NEVER hardcode secrets
- ❌ NEVER commit .env files with real values

---

## UI Verification System

**Automated view testing to catch bugs before manual testing.**

### Overview

The UI Verification System provides automated checks for SwiftUI views to ensure they:
- Render without crashing
- Have expected interactive elements
- Properly manage state
- Include navigation when needed

### Files

- **UIVerifier.swift** - Core verification logic (`Furg/Utils/UIVerifier.swift`)
- **UIVerificationTests.swift** - Test cases for all views (`FurgTests/UIVerificationTests.swift`)

### Setup

1. **Add UIVerifier.swift to Xcode project:**
   - Open Furg.xcodeproj in Xcode
   - Right-click on the "Furg" group → "Add Files to Furg..."
   - Select `Furg/Utils/UIVerifier.swift`
   - Ensure "Furg" target is checked

2. **Add UIVerificationTests.swift to test target:**
   - If no test target exists, create one: File → New → Target → Unit Testing Bundle
   - Add `FurgTests/UIVerificationTests.swift` to the test target
   - Ensure it imports `@testable import Furg`

### Usage - MANDATORY WORKFLOW

**After creating or modifying ANY SwiftUI view:**

1. **Add view to UIVerificationTests.swift:**
   ```swift
   func testYourNewView() {
       let financeManager = FinanceManager()

       let view = YourNewView()
           .environmentObject(financeManager)

       UIVerifier.verifyView(view, name: "YourNewView")
   }
   ```

2. **Run verification:**
   ```bash
   xcodebuild test -scheme Furg -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
   ```

3. **Review output and report to user:**
   ```
   ==================================================
   🔍 UI VERIFICATION: YourNewView
   ==================================================
   ✅ RENDER CHECK: View renders without crash
   ✅ NAVIGATION: NavigationLink detected
   ✅ INTERACTIVITY: Button elements detected
   ⚠️  INPUT: No TextField elements found
   ✅ STATE: @State variables detected
   ==================================================
   ✅ VERIFICATION COMPLETE: YourNewView
   ==================================================
   ```

### Verification Checks

| Check | Meaning | Action if Missing |
|-------|---------|-------------------|
| **RENDER CHECK** | View instantiates without crash | ❌ Critical - fix immediately |
| **NAVIGATION** | Has NavigationLink | ⚠️  OK if not a navigation view |
| **INTERACTIVITY** | Has Button/Tap elements | ⚠️  OK if static display |
| **INPUT** | Has TextField/TextEditor | ℹ️  Only needed for input views |
| **DATA** | Has List/ForEach | ℹ️  Only needed for collection views |
| **STATE** | Has @State/@StateObject | ℹ️  Only needed for stateful views |

### When to Verify

**Always verify after:**
- Creating a new view file
- Adding navigation between views
- Modifying view structure or layout
- Adding/removing interactive elements
- Changing state management

**Never skip verification** - even for "small" changes.

### Critical Rules

1. ✅ **ALWAYS include verification output** in your response to the user
2. ✅ **STOP and ask for help** if verification fails - don't ignore errors
3. ✅ **Update UIVerificationTests.swift** every time you create a new view
4. ✅ **Run verification BEFORE** telling the user the work is complete
5. ❌ **NEVER skip verification** - even for trivial changes

### Example - Good Workflow

```
User: "Add a new settings view"

Claude: "I've created SettingsView.swift. Running verification...

UI Verification Results:
==================================================
🔍 UI VERIFICATION: SettingsView
==================================================
✅ RENDER CHECK: View renders without crash
✅ NAVIGATION: NavigationLink detected
✅ INTERACTIVITY: Button elements detected
✅ STATE: @State variables detected
==================================================
✅ VERIFICATION COMPLETE: SettingsView
==================================================

The view successfully passes all verification checks."
```

### Example - Bad Workflow (Don't Do This)

```
User: "Add a new settings view"

Claude: "Here's SettingsView.swift [provides code]"
// ❌ No verification run
// ❌ No verification output included
```

---

## Token Optimization

**Use the Project MCP** to avoid re-reading files and re-running commands.

### MCP v2 Functions Available

1. **`cache-and-return-file(path)`**
   - Returns file from cache, auto-invalidates on change
   - Saves 800+ tokens vs reading raw file

2. **`indexed-search(pattern)`**
   - Search codebase index instead of grep
   - Saves 300+ tokens per search

3. **`get-git-state-smart()`**
   - Returns git state with auto-fetch every 30 min
   - Saves 200+ tokens per check

4. **`build-file-index` / `query-file-index`**
   - Instant file lookups instead of glob
   - Saves 350+ tokens per operation

5. **`index-swift-code`**
   - Index Swift code structure for fast searches
   - Saves 400+ tokens per complex search

### Session Token Savings

**Without MCP:** 11,000 tokens for typical 2-hour session
**With MCP v2:** 1,500 tokens (86% savings)

---

## Common Pitfalls

### ⚠️ The Merge Divergence Problem

**What happens:** Local and origin develop in parallel, causing conflicts when merging.

**How to prevent:**
- Run `git fetch origin` before starting work
- Run `git pull origin main` periodically if working across machines
- Use feature branches for major changes
- Merge with `--no-ff` instead of rebase
- Push work daily

### ⚠️ File Not In Xcode Project

**Problem:** File created on disk but not added to Xcode project → "Cannot find X in scope"

**Solution:**
- Always add new files in Xcode (Xcode UI adds to pbxproj automatically)
- Or manually edit: Project → Furg target → Build Phases → Compile Sources

### ⚠️ Stale Simulator Cache

**Problem:** Old app shows on simulator even after fresh build

**Solution:**
```bash
xcrun simctl uninstall "iPhone 16 Pro" com.furg.app
rm -rf ~/Library/Developer/Xcode/DerivedData/Furg*
# Then rebuild
```

### ⚠️ Force Unwraps in Code

**Status:** 553 force unwraps (`!`) exist (medium priority to reduce)

**Don't add more.** When fixing code:
- Use `guard let`, `if let`, or `try?` instead
- Use nil coalescing (`??`)
- Only force unwrap if guaranteed (rare)

---

## SwiftUI Development & Debugging

### 🔍 View Not Rendering (But No Build Error)

**Common Causes:**

1. **Animation opacity starting at 0**
   ```swift
   // ❌ BAD - View starts invisible
   Text("Money Flow")
       .opacity(animate ? 1 : 0)  // Starts at 0 on load

   // ✅ GOOD - Use offset animation instead
   Text("Money Flow")
       .offset(y: animate ? 0 : 20)  // Still visible, just moved
   ```

2. **Missing frame constraints**
   ```swift
   // ❌ BAD - VStack may collapse if content is empty
   VStack(spacing: 8) {
       // content...
   }  // No explicit frame

   // ✅ GOOD - Set minimum height
   VStack(spacing: 8) {
       // content...
   }
   .frame(minHeight: 80)
   ```

3. **View removed from hierarchy**
   - Check the parent VStack/HStack still includes the section
   - Comment out other sections to isolate the problem
   - Use `.border(.red, width: 1)` temporarily to see layout bounds

**Debugging Steps:**
1. Add temporary `.border(.red, width: 1)` to see if view has space
2. Check Animation closures - remove animations temporarily to see underlying layout
3. Verify `.padding()` isn't collapsing the view
4. Use SwiftUI Preview if possible to test in isolation

### 📦 View Hierarchy & Component Replacement

**When replacing a component with a new one:**

1. **Remove the old view completely** - don't leave orphaned code
   ```swift
   // ❌ BAD - Old section left in code
   balanceTrendSection
   spendingBreakdownChart  // Remove this completely

   // ✅ GOOD - Replace, not append
   moneyFlowChart  // Single new section
   ```

2. **Verify parent VStack includes the new component**
   ```swift
   VStack(spacing: 28) {
       headerSection
       heroBalanceSection
       moneyFlowChart        // ✅ Listed here
       weeklyComparisonChart
       // ...
   }
   ```

3. **Check for duplicate struct definitions**
   - If two files define `PlotlyWaterfallView`, one will cause ambiguous use error
   - Use `grep -r "struct PlotlyWaterfallView"` to find duplicates
   - Keep one canonical version, delete the rest

### 🔄 Build Caching Issues

**When code changes don't appear after rebuild:**

1. **First, clean derived data:**
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/Furg*
   ```

2. **Do a clean build:**
   ```bash
   xcodebuild clean -scheme Furg
   xcodebuild build -scheme Furg -destination "platform=iOS Simulator,name=iPhone 16 Pro"
   ```

3. **If still not working, restart simulator:**
   ```bash
   xcrun simctl shutdown "iPhone 16 Pro"
   sleep 2
   xcrun simctl boot "iPhone 16 Pro"
   sleep 8  # Wait for boot
   ```

**When to clean:**
- After adding/removing files from Xcode project
- After large refactors
- When Preview shows old UI
- When simulator shows outdated app

### 🎨 Design System Versions

**CRITICAL:** Do not mix DesignSystem.swift and DesignSystemV2.swift

- **DesignSystem.swift** - Current live system (use this)
  - Colors: `Color.furgSuccess`, `Color.furgDanger`, `Color.furgWarning`, `Color.furgMint`
  - Established in app, tested, safe

- **DesignSystemV2.swift** - In development (don't use yet)
  - Colors: `Color.v2CategoryFood`, etc. (not in current system)
  - References undefined colors → compile errors
  - For future work only

**When adding UI:**
1. Check DesignSystem.swift for existing colors
2. Use those colors only
3. Don't reference V2 colors in non-V2 views

### 📐 Component Architecture

**When designing new dashboard components:**

1. **Understand the parent view structure first**
   - Check how other components are positioned
   - Match spacing and padding conventions
   - Review existing color palette

2. **Build sections as computed properties**
   ```swift
   private var moneyFlowChart: some View {
       VStack(alignment: .leading, spacing: 12) {
           // Self-contained section
       }
   }
   ```

3. **Test in isolation**
   - Add `.border(.red)` to verify layout
   - Check all color references exist
   - Verify data sources are mocked/real

4. **When replacing existing component:**
   - Remove the old section from body VStack
   - Delete the old computed property
   - Verify build succeeds
   - Test on simulator

---

## Decision Framework

### When Implementing Features

1. **Does this already exist?**
   - Search with IndexedSearch (MCP)
   - Check Models/ for similar types
   - Check existing managers

2. **What manager owns this?**
   - Budget/spending → FinanceManager
   - AI chat → ChatManager
   - Deals/shopping → DealsManager
   - Bank data → PlaidManager
   - etc.

3. **Where should this live?**
   - UI: Add to MainTabView or ToolsHubView
   - Backend: Add to appropriate service
   - Models: Define in Models.swift

4. **How do I prevent merge conflicts?**
   - Create feature branch
   - Don't modify same files as others
   - Push daily
   - Sync main regularly with `git pull origin main --no-ff`

### When Troubleshooting

1. **Build fails:** Check error, use GetBuildErrorCache()
2. **App crashes:** Check console, identify specific view
3. **Git conflicts:** Abort merge, understand divergence, resolve carefully
4. **Performance slow:** Profile with Xcode Instruments
5. **Token usage high:** Use MCP caching functions

---

## MCP Setup Notes

**MCP v2 is installed** with these tools:
- cache-and-return-file
- indexed-search
- get-git-state-smart
- build-file-index + query-file-index
- index-swift-code

**Quick start:**
```
"Build the file index"
"Search for Dashboard"
"Get git state"
```

See ios/MCP_V2_TOOLS.md for full documentation.

---

## Working Session Checklist

### Start of Session
- [ ] `git fetch origin`
- [ ] `git status`
- [ ] Query git state with MCP
- [ ] Ask user about priorities

### During Development
- [ ] Use MCP for file reads
- [ ] Use MCP for searches
- [ ] Make atomic commits
- [ ] Push to feature branch daily
- [ ] Sync main if needed (`git pull origin main --no-ff`)

### Before Pushing
- [ ] `git diff origin/main...HEAD`
- [ ] Check build status
- [ ] `git fetch origin` (confirm no divergence)
- [ ] Push to feature branch

### End of Session
- [ ] Push all changes
- [ ] Document accomplishments
- [ ] Flag blockers
- [ ] Suggest next steps

---

## Quick Reference

### Important Files

- **Entry Point:** `Furg/App/FurgApp.swift`
- **Navigation:** `Furg/Views/MainTabView.swift`, `ToolsHubView.swift`
- **Design System:** `Furg/App/DesignSystem.swift`
- **Managers:** `Furg/Services/` (40+ managers)
- **Backend Config:** `backend/.env`
- **Database:** `backend/database.py`

### Emergency Commands

```bash
# See what's on origin but not local
git fetch origin && git log main..origin/main --oneline

# See what's local but not on origin
git log origin/main..main --oneline

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Merge with full history
git pull origin main --no-ff
```

---

## Key Decisions Made

### JWT Token Storage
- **Changed from:** UserDefaults (insecure)
- **Changed to:** Keychain (secure)
- **Files:** KeychainHelper.swift, KeychainService.swift

### Git Strategy
- **Use:** Feature branches + merge commits (--no-ff)
- **Avoid:** Force push, rebase on shared branches
- **Reason:** Preserves history, prevents divergence issues

### MCP Usage
- **Do:** Use for file caching, indexed search, git state
- **Don't:** Use for one-off commands or new files
- **Savings:** 86% token reduction per session

---

## Version History

| Date | Change |
|------|--------|
| Dec 14, 2024 | Added SwiftUI Development & Debugging section |
| | Documented view rendering issues (animation opacity, frame constraints) |
| | Added component replacement patterns and hierarchy debugging |
| | Documented design system version separation (v1 vs v2) |
| | Added build cache management procedures |
| Dec 2024 | Reset from diverged state, added CLAUDE.md + KeychainHelper |
| | Documented distributed workflow, MCP v2, common pitfalls |
| | Established clean main from origin with premium features |
