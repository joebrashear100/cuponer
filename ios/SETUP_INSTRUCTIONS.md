# FURG iOS App - Setup Instructions

**Get FURG on your phone tonight!** Follow these step-by-step instructions.

## Prerequisites

1. **Mac with Xcode** installed (Xcode 15+ recommended)
   - Download from App Store if you don't have it: [Download Xcode](https://apps.apple.com/us/app/xcode/id497799835)

2. **Apple ID** for development
   - You can use your personal Apple ID (free)
   - No paid developer account needed for testing on your own device

3. **iPhone** with USB cable
   - iOS 17+ recommended

4. **Backend running** (from the previous setup)
   - Make sure the backend is running on your Mac: `cd backend && docker-compose up -d`
   - Or run it manually: `python main.py`

---

## Step 1: Create Xcode Project (10 minutes)

### 1.1 Open Xcode

```bash
open -a Xcode
```

### 1.2 Create New Project

1. Click "Create New Project"
2. Select **iOS** → **App**
3. Click **Next**

### 1.3 Project Settings

- **Product Name**: `Furg`
- **Team**: Select your Apple ID (click "Add Account" if needed)
- **Organization Identifier**: `com.yourname` (use your name, e.g., `com.joe`)
- **Bundle Identifier**: Will auto-fill as `com.yourname.Furg`
- **Interface**: **SwiftUI**
- **Language**: **Swift**
- **Storage**: None
- **Include Tests**: Uncheck both boxes

Click **Next**, then choose the `/home/user/cuponer/ios` folder and click **Create**.

### 1.4 Delete Template Files

Xcode created some template files we don't need. Delete these:

1. Right-click on `FurgApp.swift` in the template (if it exists) → Delete → Move to Trash
2. Right-click on `ContentView.swift` (if it exists) → Delete → Move to Trash

---

## Step 2: Add Source Files (5 minutes)

### 2.1 Add All Swift Files

1. In Xcode, right-click on the **Furg** folder in the Project Navigator (left sidebar)
2. Select **Add Files to "Furg"...**
3. Navigate to `/home/user/cuponer/ios/Furg/`
4. Select **ALL folders**: `App`, `Models`, `Services`, `Views`
5. Make sure these options are checked:
   - ✅ "Copy items if needed"
   - ✅ "Create groups"
   - ✅ Add to targets: Furg
6. Click **Add**

### 2.2 Add Info.plist

1. Right-click on the **Furg** folder again
2. Select **Add Files to "Furg"...**
3. Navigate to `/home/user/cuponer/ios/Furg/Resources/`
4. Select `Info.plist`
5. Click **Add**

### 2.3 Set Info.plist Location

1. Click on the **Furg** project in the Project Navigator (blue icon at top)
2. Select the **Furg** target
3. Go to the **Build Settings** tab
4. Search for "Info.plist"
5. Under "Packaging", set **Info.plist File** to: `Furg/Resources/Info.plist`

---

## Step 3: Enable Sign in with Apple (3 minutes)

### 3.1 Add Capability

1. Click on the **Furg** project (blue icon)
2. Select the **Furg** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** button
5. Search for and add: **Sign in with Apple**

### 3.2 Configure Signing

1. Under **Signing**, make sure:
   - ✅ **Automatically manage signing** is checked
   - **Team**: Your Apple ID team is selected
   - **Bundle Identifier**: Shows `com.yourname.Furg`

---

## Step 4: Update Backend URL (2 minutes)

### 4.1 Find Your Mac's IP Address

```bash
# On your Mac, run this command:
ipconfig getifaddr en0
```

This will show your local IP, like `192.168.1.100`.

### 4.2 Update Config.swift

1. In Xcode, open `App/Config.swift`
2. Find the line that says:
   ```swift
   static let baseURL = "http://localhost:8000"
   ```
3. Change it to use your Mac's IP:
   ```swift
   static let baseURL = "http://192.168.1.100:8000"  // Use YOUR IP here
   ```
4. Press **Cmd+S** to save

**Why?** Your phone can't access "localhost" - it needs your Mac's actual network IP.

---

## Step 5: Build and Run (5 minutes)

### 5.1 Connect Your iPhone

1. Plug your iPhone into your Mac with USB cable
2. **On your iPhone**: When "Trust This Computer?" appears, tap **Trust**
3. Enter your iPhone passcode if prompted

### 5.2 Select Your iPhone

1. In Xcode, at the top, click the device selector (next to the Play button)
2. Under "iOS Devices", select your iPhone's name

### 5.3 Build and Run

1. Click the **Play button** (▶️) or press **Cmd+R**
2. Xcode will build the app (this takes 1-2 minutes the first time)
3. **First time only**: On your iPhone, go to:
   - **Settings** → **General** → **VPN & Device Management**
   - Tap on your Apple ID
   - Tap **Trust "[Your Apple ID]"**
   - Tap **Trust** again to confirm
4. Go back to Xcode and press **Play** again

### 5.4 Wait for Installation

- Xcode will install the app on your phone
- You'll see "Running Furg on [Your iPhone]" in Xcode
- The app should launch automatically!

---

## Step 6: Test the App (2 minutes)

### 6.1 Sign In

1. The app should show the welcome screen
2. Tap **Sign in with Apple**
3. Authenticate with Face ID/Touch ID
4. You're in!

### 6.2 Test Chat

1. Go to the **Chat** tab
2. Type: "What's my balance?"
3. FURG should respond!

### 6.3 Try Other Features

- **Balance tab**: View your balance (will be $0 initially)
- **Activity tab**: See transactions (empty until you connect a bank)
- **Settings tab**: Update your profile

---

## Troubleshooting

### Problem: "Untrusted Developer"

**Solution**: Go to iPhone Settings → General → VPN & Device Management → Trust your Apple ID

### Problem: "Failed to verify code signature"

**Solution**:
1. Go to Xcode → Signing & Capabilities
2. Click your Team dropdown, select "Add Account"
3. Sign in with your Apple ID
4. Select your team again

### Problem: "Cannot connect to localhost"

**Solution**: You need to use your Mac's IP address, not localhost.
1. Find your Mac's IP: `ipconfig getifaddr en0`
2. Update `Config.swift` with that IP
3. Rebuild the app

### Problem: Build errors about missing frameworks

**Solution**: Make sure you added all files correctly in Step 2

### Problem: "Command CodeSign failed"

**Solution**:
1. Go to Xcode → Preferences → Accounts
2. Click your Apple ID
3. Click "Download Manual Profiles"
4. Try building again

### Problem: Backend not responding

**Solution**:
1. Make sure backend is running: `curl http://localhost:8000/health`
2. Make sure your iPhone and Mac are on the same WiFi network
3. Try accessing from your phone's browser: `http://YOUR_MAC_IP:8000/health`

---

## Optional: Add Plaid (if you want to connect real banks)

### Install Plaid LinkKit

1. In Xcode, go to **File** → **Add Package Dependencies**
2. Enter this URL: `https://github.com/plaid/plaid-link-ios`
3. Click **Add Package**
4. Select **LinkKit** and click **Add Package**

### Update PlaidManager.swift

1. Open `Services/PlaidManager.swift`
2. Uncomment the line: `// import LinkKit`
3. Uncomment the Plaid Link code in `presentPlaidLink()`

Now you can connect real banks!

---

## Next Steps

### Test with Real Data

1. **Connect a bank** (Settings tab → Connected Banks)
2. **Run bill detection** (Activity tab → Detect Bills)
3. **Chat with FURG** about your spending
4. **Try hiding money** (Balance tab → Hide Money)

### Customize

1. **Change roasting intensity**: Chat → "Set intensity to insanity"
2. **Set savings goal**: Settings → Savings Goal
3. **Update profile**: Settings → Edit Profile

### Deploy Backend

If you want to use the app away from your Mac:

1. Deploy backend to Fly.io (see `docs/DEPLOYMENT.md`)
2. Update `Config.swift` with production URL
3. Rebuild app

---

## Summary: What You Built

🎉 **Congratulations!** You now have a fully functional iOS app with:

- ✅ Sign in with Apple authentication
- ✅ Real-time chat with FURG's roasting personality
- ✅ Balance dashboard with hide/reveal functionality
- ✅ Transaction history and spending breakdown
- ✅ Bill detection from transaction patterns
- ✅ Settings and profile management
- ✅ Plaid integration (optional)

**Total time**: ~30 minutes from zero to app on your phone!

---

## Files Created

Here's what we built:

```
ios/Furg/
├── App/
│   ├── FurgApp.swift          # Main app entry point
│   └── Config.swift            # Configuration and API endpoints
├── Models/
│   └── Models.swift            # All data models (30+ structs)
├── Services/
│   ├── AuthManager.swift       # Sign in with Apple
│   ├── APIClient.swift         # Backend communication
│   ├── ChatManager.swift       # Chat functionality
│   ├── FinanceManager.swift    # Balance, transactions, bills
│   └── PlaidManager.swift      # Bank connections
├── Views/
│   ├── WelcomeView.swift       # Sign in screen
│   ├── MainTabView.swift       # Tab bar
│   ├── ChatView.swift          # Main chat interface
│   ├── BalanceView.swift       # Balance dashboard
│   ├── TransactionsView.swift  # Transaction list
│   └── SettingsView.swift      # Settings and profile
└── Resources/
    └── Info.plist              # App configuration
```

**Total code**: ~2,500 lines of Swift
**Total views**: 6 complete screens
**Total services**: 5 managers
**Total models**: 30+ data structures

---

## Quick Command Reference

```bash
# Find your Mac's IP
ipconfig getifaddr en0

# Check backend is running
curl http://localhost:8000/health

# Start backend
cd backend && docker-compose up -d

# View backend logs
docker-compose logs -f backend
```

---

## Support

**Issues?** Check:
1. Backend is running (`curl http://localhost:8000/health`)
2. iPhone and Mac on same WiFi
3. Used Mac's IP address, not "localhost"
4. Trusted your Apple ID on iPhone

**Still stuck?** Review the Troubleshooting section above.

---

**Enjoy roasting with FURG!** 🔥

*"Your money, but smarter than you."*
