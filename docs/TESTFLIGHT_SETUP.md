# Furg iOS - TestFlight CI/CD Setup Guide

This guide will help you set up automatic TestFlight deployments whenever you push code to GitHub.

## Overview

Once set up, the workflow is:
1. You push code to `main` branch on GitHub
2. GitHub Actions automatically builds the app
3. The app is uploaded to TestFlight
4. You get a notification on your iPhone to install the update

## Prerequisites

- Apple Developer Account ($99/year) - https://developer.apple.com
- App Store Connect access - https://appstoreconnect.apple.com

---

## Step 1: Run the Setup Script

On your Mac, run:

```bash
cd ~/cuponer
./scripts/setup-github-secrets.sh
```

This will:
- Export your distribution certificate
- Encode your provisioning profile
- Generate other required secrets
- Create files on your Desktop in `FurgGitHubSecrets` folder

---

## Step 2: Create App Store Connect API Key

1. Go to [App Store Connect API Keys](https://appstoreconnect.apple.com/access/api)
2. Click **"Generate API Key"**
3. Fill in:
   - **Name:** `GitHub Actions`
   - **Access:** `App Manager`
4. Click **Generate**
5. **IMPORTANT:** Download the `.p8` file immediately (you can only download it once!)
6. Note down:
   - **Issuer ID** (shown at the top of the page)
   - **Key ID** (shown next to your key name)

---

## Step 3: Create the App in App Store Connect

If you haven't already:

1. Go to [App Store Connect Apps](https://appstoreconnect.apple.com/apps)
2. Click **"+"** → **"New App"**
3. Fill in:
   - **Platforms:** iOS
   - **Name:** Furg
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** com.furg.app
   - **SKU:** furg-app (or any unique identifier)
4. Click **Create**

---

## Step 4: Create Distribution Certificate (if needed)

If you don't have an Apple Distribution certificate:

1. Go to [Certificates](https://developer.apple.com/account/resources/certificates/list)
2. Click **"+"** to create a new certificate
3. Select **"Apple Distribution"**
4. Follow the instructions to create a CSR and upload it
5. Download and double-click to install

---

## Step 5: Create App Store Provisioning Profile

1. Go to [Provisioning Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Click **"+"** to create a new profile
3. Select **"App Store"** under Distribution
4. Select your App ID: `com.furg.app`
5. Select your Distribution certificate
6. Name it: `Furg App Store`
7. Download and double-click to install

---

## Step 6: Add Secrets to GitHub

1. Go to your repo: https://github.com/joebrashear100/cuponer/settings/secrets/actions
2. Click **"New repository secret"** for each of these:

| Secret Name | Where to Get It |
|-------------|-----------------|
| `CERTIFICATE_P12` | Contents of `~/Desktop/FurgGitHubSecrets/CERTIFICATE_P12.txt` |
| `CERTIFICATE_PASSWORD` | Contents of `~/Desktop/FurgGitHubSecrets/CERTIFICATE_PASSWORD.txt` |
| `PROVISIONING_PROFILE` | Contents of `~/Desktop/FurgGitHubSecrets/PROVISIONING_PROFILE.txt` |
| `EXPORT_OPTIONS_PLIST` | Contents of `~/Desktop/FurgGitHubSecrets/EXPORT_OPTIONS_PLIST.txt` |
| `KEYCHAIN_PASSWORD` | Contents of `~/Desktop/FurgGitHubSecrets/KEYCHAIN_PASSWORD.txt` |
| `APP_STORE_CONNECT_API_KEY_ID` | The Key ID from Step 2 |
| `APP_STORE_CONNECT_API_ISSUER_ID` | The Issuer ID from Step 2 |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | The entire contents of your `.p8` file |

---

## Step 7: Test the Workflow

1. Make any small change to a file in the `ios/` folder
2. Commit and push to `main`
3. Go to [Actions](https://github.com/joebrashear100/cuponer/actions) to watch the build
4. Once complete, check TestFlight on your iPhone!

---

## Troubleshooting

### Build fails with signing error
- Ensure your provisioning profile matches the bundle ID (`com.furg.app`)
- Make sure the certificate used to create the profile is the one you exported

### Upload fails to TestFlight
- Verify your API key has "App Manager" access
- Ensure the app exists in App Store Connect with matching bundle ID

### Profile not found
- Re-download your provisioning profile from Apple Developer portal
- Run the setup script again

---

## Manual Trigger

You can also manually trigger a build:
1. Go to [Actions](https://github.com/joebrashear100/cuponer/actions)
2. Select "iOS Build & TestFlight"
3. Click "Run workflow"

---

## Files Created

- `.github/workflows/ios-testflight.yml` - The CI/CD workflow
- `ios/ExportOptions.plist` - Build export configuration
- `scripts/setup-github-secrets.sh` - Helper script for generating secrets
