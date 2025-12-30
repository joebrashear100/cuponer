# Cuponer Comprehensive TODO List

**Generated:** December 30, 2024
**Total Items:** 32

Risk Legend:
- 🟢 **Low Risk** - Safe for headless, minimal chance of breaking changes
- 🟡 **Medium Risk** - Headless possible but review recommended
- 🔴 **High Risk** - Requires human oversight or manual steps

---

## 🔧 BUILD & PROJECT CONFIGURATION

| # | Task | Headless Risk | Notes |
|---|------|---------------|-------|
| 1 | **Fix 6 duplicate type definitions** | 🟢 Low | Rename: `StatBox`, `DebtSelectionRow`, `PlotlyWaterfallView`, `QuickDebtPaymentSheet`, `UserFinancialProfile`, `WaterfallChartWebView` |
| 2 | **Add 6 missing files to Xcode project** | 🔴 High | Requires Xcode UI or complex pbxproj editing |
| 3 | **Fix LifeSimulator.swift UserFinancialProfile reference** | 🟢 Low | Import or use correct type |
| 4 | **Resolve MainTabView ToolsHubView reference** | 🟢 Low | Depends on #2 being done first |

---

## 🧪 TESTING

| # | Task | Headless Risk | Notes |
|---|------|---------------|-------|
| 5 | **Create backend test suite** | 🟢 Low | No tests exist; create `backend/tests/` with pytest |
| 6 | **Add API endpoint tests for 83 endpoints** | 🟢 Low | Test each endpoint in `main.py` |
| 7 | **Add integration tests for Plaid flow** | 🟡 Medium | Requires mock Plaid responses |
| 8 | **Create iOS unit tests** | 🟡 Medium | Test managers and business logic |
| 9 | **Add UI snapshot tests** | 🔴 High | Requires simulator and Xcode |

---

## 🔐 SECURITY

| # | Task | Headless Risk | Notes |
|---|------|---------------|-------|
| 10 | **Migrate 60 UserDefaults usages to Keychain where sensitive** | 🟡 Medium | Audit each usage for sensitivity |
| 11 | **Remove hardcoded password in docker-compose.yml** | 🟢 Low | Use environment variable reference |
| 12 | **Add input validation to all 83 API endpoints** | 🟡 Medium | Prevent injection attacks |
| 13 | **Implement rate limiting on auth endpoints** | 🟢 Low | `rate_limiter.py` exists, wire it up |
| 14 | **Add API key rotation mechanism** | 🟡 Medium | Backend config change |

---

## 🚀 PERFORMANCE

| # | Task | Headless Risk | Notes |
|---|------|---------------|-------|
| 15 | **Refactor TransactionsListView.swift (2208 lines)** | 🟡 Medium | Split into smaller components |
| 16 | **Refactor HomeView.swift (1900 lines)** | 🟡 Medium | Extract sub-views |
| 17 | **Refactor AccountsView.swift (1639 lines)** | 🟡 Medium | Extract sub-views |
| 18 | **Optimize MerchantIntelligenceManager (1446 lines)** | 🟡 Medium | Consider lazy loading, caching |
| 19 | **Add database query pagination** | 🟢 Low | Backend `database.py` (1429 lines) |

---

## ✨ FEATURES (Incomplete/TODO Items)

| # | Task | Headless Risk | Notes |
|---|------|---------------|-------|
| 20 | **Implement QuickDebtPaymentSheet submit** | 🟢 Low | Wire to `DebtPayoffManager.recordPayment` |
| 21 | **Implement MainTabView refresh logic** | 🟢 Low | Add pull-to-refresh |
| 22 | **Implement notification navigation** | 🟢 Low | Wire notification tap to view |
| 23 | **Implement EnhancedRoundUpsView toggles** | 🟢 Low | Connect to transaction manager |
| 24 | **Complete widget data sync** | 🟡 Medium | Widgets exist but need live data |

---

## ♿ ACCESSIBILITY & LOCALIZATION

| # | Task | Headless Risk | Notes |
|---|------|---------------|-------|
| 25 | **Add accessibility labels (only 1 exists)** | 🟢 Low | Add `accessibilityLabel` to 1072 Text elements |
| 26 | **Localize 1072 hardcoded strings** | 🟡 Medium | Create `Localizable.strings`, replace `Text("...")` |
| 27 | **Add VoiceOver support for charts** | 🟡 Medium | Custom accessibility for Swift Charts |

---

## 📚 DOCUMENTATION

| # | Task | Headless Risk | Notes |
|---|------|---------------|-------|
| 28 | **Add API documentation (OpenAPI/Swagger)** | 🟢 Low | FastAPI auto-generates, just enable |
| 29 | **Document 46 manager classes** | 🟢 Low | Add docstrings explaining purpose |
| 30 | **Create architecture diagram** | 🟡 Medium | Document iOS ↔ Backend ↔ DB flow |

---

## 🏗️ INFRASTRUCTURE

| # | Task | Headless Risk | Notes |
|---|------|---------------|-------|
| 31 | **Add GitHub Actions for backend tests** | 🟢 Low | CI workflow for Python tests |
| 32 | **Fix iOS TestFlight workflow** | 🔴 High | Requires Apple credentials, certs |

---

## Summary by Risk Level

| Risk | Count | Suitable for Headless? |
|------|-------|------------------------|
| 🟢 Low | 18 | Yes - run autonomously |
| 🟡 Medium | 11 | Yes with review after |
| 🔴 High | 3 | No - requires manual steps |

---

## Recommended Headless Execution Order

### Phase 1: Foundation (can run now)
```
1. Fix duplicate type definitions
3. Fix LifeSimulator reference
5. Create backend test suite
11. Remove hardcoded password
20-23. Implement incomplete features
```

### Phase 2: Quality (after build works)
```
6. Add API tests
10. Migrate sensitive UserDefaults
15-18. Refactor large files
25. Add accessibility labels
```

### Phase 3: Polish (human oversight)
```
26. Localization
28-30. Documentation
7-8. Integration/unit tests
```

### Must Do Manually
```
2. Add files to Xcode (requires Xcode UI)
9. UI snapshot tests (requires simulator)
32. TestFlight workflow (requires certs)
```
