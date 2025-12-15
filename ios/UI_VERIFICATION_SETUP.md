# UI Verification System - Setup Guide

## Quick Start

This automated verification system catches view rendering issues before manual testing.

## Files Created

1. **`Furg/Utils/UIVerifier.swift`** - Verification logic
2. **`FurgTests/UIVerificationTests.swift`** - Test cases

## Setup Steps

### Step 1: Add UIVerifier.swift to Xcode Project

1. Open `Furg.xcodeproj` in Xcode
2. Right-click on the **Furg** folder in the Project Navigator
3. Select **"Add Files to Furg..."**
4. Navigate to `Furg/Utils/UIVerifier.swift`
5. Make sure **"Furg" target is checked**
6. Click **Add**

### Step 2: Create Test Target (if needed)

If you don't have a test target:

1. In Xcode: **File → New → Target**
2. Select **Unit Testing Bundle**
3. Name it **FurgTests**
4. Click **Finish**

### Step 3: Add Test File to Test Target

1. Right-click on the **FurgTests** folder (or create it)
2. Select **"Add Files to FurgTests..."**
3. Navigate to `FurgTests/UIVerificationTests.swift`
4. Make sure **"FurgTests" target is checked**
5. Click **Add**

### Step 4: Verify Setup

Run tests to verify everything works:

```bash
xcodebuild test -scheme Furg -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

You should see output like:

```
==================================================
🔍 UI VERIFICATION: MainTabView
==================================================
✅ RENDER CHECK: View renders without crash
✅ INTERACTIVITY: Button elements detected
✅ STATE: @State variables detected
==================================================
✅ VERIFICATION COMPLETE: MainTabView
==================================================
```

## How to Use

### When Creating a New View

After creating `YourNewView.swift`, add a test:

```swift
// In UIVerificationTests.swift

func testYourNewView() {
    let financeManager = FinanceManager()

    let view = YourNewView()
        .environmentObject(financeManager)

    UIVerifier.verifyView(view, name: "YourNewView")
}
```

Then run:

```bash
xcodebuild test -scheme Furg -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Understanding the Output

| Symbol | Meaning |
|--------|---------|
| ✅ | Check passed |
| ⚠️ | Warning (may be OK) |
| ❌ | Critical failure |

**Critical Checks:**
- **RENDER CHECK** - Must pass, or view won't display
- **INTERACTIVITY** - Should have buttons/taps if interactive
- **STATE** - Should have @State if view manages state

**Optional Checks:**
- **NAVIGATION** - Only needed if view navigates
- **INPUT** - Only needed if view has text fields
- **DATA** - Only needed if view displays lists

## Common Issues

### "Cannot find 'UIVerifier' in scope"

UIVerifier.swift not added to Xcode project. Follow Step 1 above.

### "No such module 'Furg'"

Test target not properly configured. Make sure:
1. FurgTests target exists
2. UIVerificationTests.swift is in FurgTests target
3. `@testable import Furg` is at the top of the test file

### "Missing required environment objects"

Add required managers when creating the view in tests:

```swift
let view = YourView()
    .environmentObject(FinanceManager())
    .environmentObject(ChatManager())
    // etc.
```

## Benefits

- **Catch crashes before manual testing** - Know immediately if a view won't render
- **Verify structure** - Ensure views have expected elements
- **Regression detection** - Tests fail if you break existing views
- **Documentation** - Tests show how to properly create each view

## Workflow Integration

**For Claude:** After creating or modifying ANY view, always:

1. Add test to `UIVerificationTests.swift`
2. Run tests
3. Include verification output in response to user
4. Fix any failures before considering work complete

See `/Users/joebrashear/cuponer/CLAUDE.md` for full documentation.
