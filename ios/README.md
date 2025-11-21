# FURG iOS App

**Chat-first financial AI with roasting personality**

This is the iOS app for FURG. It connects to the backend API and provides a native SwiftUI interface.

## Quick Start

**Want to get this on your phone tonight?** See [SETUP_INSTRUCTIONS.md](./SETUP_INSTRUCTIONS.md) for a complete step-by-step guide (30 minutes).

## Features

- ✅ **Sign in with Apple** - Secure authentication
- ✅ **Real-time Chat** - Talk to FURG's roasting personality
- ✅ **Balance Dashboard** - View total, visible, and hidden balances
- ✅ **Transaction History** - See all your spending with categorization
- ✅ **Bill Detection** - Automatically detect recurring bills
- ✅ **Money Hiding** - Hide money from yourself with safety checks
- ✅ **Plaid Integration** - Connect multiple banks (optional)
- ✅ **Profile Management** - Update your info and settings

## Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**
- **Backend running** (see `../backend/`)

## Project Structure

```
Furg/
├── App/
│   ├── FurgApp.swift          # Main app entry point
│   └── Config.swift            # Configuration
├── Models/
│   └── Models.swift            # Data models
├── Services/
│   ├── AuthManager.swift       # Authentication
│   ├── APIClient.swift         # API communication
│   ├── ChatManager.swift       # Chat functionality
│   ├── FinanceManager.swift    # Financial data
│   └── PlaidManager.swift      # Bank connections
├── Views/
│   ├── WelcomeView.swift       # Sign in screen
│   ├── MainTabView.swift       # Tab bar
│   ├── ChatView.swift          # Chat interface
│   ├── BalanceView.swift       # Balance dashboard
│   ├── TransactionsView.swift  # Transactions list
│   └── SettingsView.swift      # Settings
└── Resources/
    └── Info.plist              # App configuration
```

## Setup Summary

1. **Create Xcode project** (10 min)
2. **Add source files** (5 min)
3. **Configure signing** (3 min)
4. **Update backend URL** (2 min)
5. **Build and run** (5 min)

**Total**: ~25-30 minutes

See [SETUP_INSTRUCTIONS.md](./SETUP_INSTRUCTIONS.md) for detailed steps.

## Configuration

### Backend URL

Update the backend URL in `App/Config.swift`:

```swift
// Development (local)
static let baseURL = "http://YOUR_MAC_IP:8000"

// Production
static let baseURL = "https://api.furg.app"
```

**Important**: Use your Mac's IP address, not "localhost", when testing on a physical device.

Find your Mac's IP:
```bash
ipconfig getifaddr en0
```

## Building

### Debug Build

```bash
# In Xcode:
# 1. Select your device
# 2. Press Cmd+R
```

### Release Build

```bash
# In Xcode:
# 1. Product → Archive
# 2. Distribute App → Development
```

## Testing on Device

1. Connect iPhone via USB
2. Select device in Xcode
3. Build and run (Cmd+R)
4. **First time**: Trust developer in iPhone Settings

## Features Walkthrough

### Sign In
- Uses Sign in with Apple
- No password needed
- Secure JWT authentication

### Chat
- Natural language conversation
- FURG's roasting personality
- Command handling (intensity mode, hide money, etc.)
- Full conversation history

### Balance
- Real-time balance from Plaid
- Hidden vs visible balance
- Safety buffer calculation
- Quick hide/reveal actions

### Transactions
- Last 7/30/90 days
- Spending breakdown by category
- Bill detection status
- Transaction details

### Settings
- Profile management
- Connect/manage banks
- Savings goal setup
- Intensity mode selection
- Sign out

## Dependencies

### Required
- **SwiftUI** (built-in)
- **AuthenticationServices** (built-in)

### Optional
- **LinkKit** (for Plaid)
  - Install via SPM: `https://github.com/plaid/plaid-link-ios`

## Troubleshooting

### Build Errors

**"Cannot find type 'ChatMessage'"**
- Make sure all files in `Models/` are added to the target

**"Module 'LinkKit' not found"**
- Add Plaid LinkKit via Swift Package Manager
- Or comment out `import LinkKit` if not using Plaid

### Runtime Errors

**"Cannot connect to backend"**
- Check backend is running: `curl http://YOUR_IP:8000/health`
- Verify IP address in `Config.swift`
- Make sure iPhone and Mac are on same WiFi

**"Untrusted Developer"**
- Settings → General → VPN & Device Management
- Tap your Apple ID → Trust

### Authentication Issues

**"Failed to authenticate with Apple"**
- Make sure Sign in with Apple capability is added
- Check your Apple ID is signed in to Xcode
- Try again - sometimes Apple's servers are slow

## Architecture

### MVVM Pattern
- **Models**: Data structures
- **Views**: SwiftUI UI components
- **ViewModels**: Services (@ObservableObject managers)

### State Management
- `@Published` properties for reactive updates
- `@EnvironmentObject` for dependency injection
- Async/await for API calls

### Networking
- URLSession for HTTP
- Codable for JSON
- JWT Bearer token authentication

## Code Statistics

- **Total Lines**: ~2,500
- **Swift Files**: 14
- **Views**: 6
- **Services**: 5
- **Models**: 30+

## Next Steps

### Add Features
- [ ] HealthKit integration
- [ ] Shortcuts/Siri integration
- [ ] Background sync
- [ ] Push notifications
- [ ] Apple Watch app
- [ ] Widgets

### Improve UX
- [ ] Animations and transitions
- [ ] Error state views
- [ ] Loading skeletons
- [ ] Pull to refresh
- [ ] Dark mode support

### Testing
- [ ] Unit tests for services
- [ ] UI tests for views
- [ ] Integration tests
- [ ] TestFlight beta

## Contributing

See main [CONTRIBUTING.md](../CONTRIBUTING.md)

## License

See [LICENSE](../LICENSE)

---

**Built with Swift and SwiftUI** 🔥
