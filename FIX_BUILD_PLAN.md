# Plan: Fix Cuponer iOS Build

## Problem Summary

The iOS project has **6 missing files** and **6 duplicate type definitions** preventing compilation.

---

## Issue 1: Missing Files (not in Xcode project)

These Swift files exist on disk but aren't added to the Xcode build target:

| File | Location | Purpose |
|------|----------|---------|
| `KeychainHelper.swift` | Services/ | Secure credential storage |
| `LifeModels.swift` | Models/ | UserFinancialProfile and life simulation models |
| `MerchantDetailView.swift` | Views/ | Merchant details UI |
| `PlotlyWaterfallView.swift` | Views/ | Waterfall chart visualization |
| `QuickDebtPaymentSheet.swift` | Views/ | Quick debt payment UI |
| `ToolsHubView.swift` | Views/ | Premium tools hub navigation |

**Fix approach:** Programmatically add file references to `project.pbxproj`

---

## Issue 2: Duplicate Type Definitions

These types are defined in multiple files, causing conflicts:

| Type | Files | Fix |
|------|-------|-----|
| `UserFinancialProfile` | Models.swift, LifeModels.swift, RecommendationEngine.swift | Keep in Models.swift, rename others |
| `StatBox` | Multiple views | Rename to unique names per context |
| `DebtSelectionRow` | Multiple views | Rename to unique names |
| `PlotlyWaterfallView` | Multiple files | Consolidate to one |
| `QuickDebtPaymentSheet` | Multiple files | Consolidate to one |
| `WaterfallChartWebView` | Multiple files | Consolidate to one |

**Fix approach:** Rename duplicate types with unique prefixes

---

## Execution Plan

### Step 1: Fix Duplicate Types (Code Changes)
1. Rename `UserFinancialProfile` in RecommendationEngine.swift → `RecommendationUserProfile` ✅ (already done)
2. Find and rename other duplicate `StatBox`, `DebtSelectionRow` definitions
3. Consolidate or rename waterfall chart types

### Step 2: Add Missing Files to Xcode Project
Option A: Script to modify project.pbxproj (risky, complex format)
Option B: Generate a helper script user runs in Xcode
Option C: Provide manual instructions

**Recommended: Option A** - I'll carefully add the file references programmatically

### Step 3: Verify & Test
1. Attempt build
2. Fix any remaining errors
3. Confirm app launches

### Step 4: Commit & Push
1. Commit all fixes
2. Push to main

---

## Estimated Changes

- **Files modified:** ~10-15 Swift files (type renames)
- **Project file:** Add 6 file references
- **Risk:** Low - mostly renaming and adding references

---

## Ready to Execute?

Say "go" to start fixing, or ask questions about the plan.
