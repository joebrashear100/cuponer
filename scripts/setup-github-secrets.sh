#!/bin/bash

# ============================================
# Furg iOS - GitHub Secrets Setup Script
# ============================================
# This script helps you generate the base64-encoded
# secrets needed for GitHub Actions CI/CD
# ============================================

set -e

echo "========================================"
echo "  Furg iOS - GitHub Secrets Generator  "
echo "========================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Output directory
OUTPUT_DIR="$HOME/Desktop/FurgGitHubSecrets"
mkdir -p "$OUTPUT_DIR"

echo -e "${YELLOW}This script will help you generate secrets for GitHub Actions.${NC}"
echo ""

# ============================================
# Step 1: Certificate
# ============================================
echo -e "${GREEN}Step 1: Distribution Certificate${NC}"
echo "--------------------------------------------"
echo "Looking for your Apple Distribution certificate..."
echo ""

# Find distribution certificates
CERT_NAME=$(security find-identity -v -p codesigning | grep "Apple Distribution" | head -1 | sed 's/.*"\(.*\)".*/\1/')

if [ -z "$CERT_NAME" ]; then
    echo -e "${RED}No Apple Distribution certificate found!${NC}"
    echo "Please ensure you have a valid distribution certificate in Keychain."
    echo ""
    echo "To create one:"
    echo "1. Go to https://developer.apple.com/account/resources/certificates"
    echo "2. Create a new 'Apple Distribution' certificate"
    echo "3. Download and install it"
    exit 1
fi

echo -e "Found certificate: ${GREEN}$CERT_NAME${NC}"
echo ""

read -p "Enter a password to protect the exported certificate: " -s CERT_PASSWORD
echo ""

P12_PATH="$OUTPUT_DIR/certificate.p12"
echo "Exporting certificate to $P12_PATH..."

# Export the certificate
security export -k ~/Library/Keychains/login.keychain-db -t identities -f pkcs12 -P "$CERT_PASSWORD" -o "$P12_PATH" 2>/dev/null || {
    echo -e "${YELLOW}Trying alternative export method...${NC}"
    security find-identity -v -p codesigning
    echo ""
    echo -e "${RED}Please manually export your certificate:${NC}"
    echo "1. Open Keychain Access"
    echo "2. Find 'Apple Distribution: ...' certificate"
    echo "3. Right-click → Export"
    echo "4. Save as .p12 with a password"
    echo "5. Place it at: $P12_PATH"
    echo ""
    read -p "Press Enter when done..."
}

if [ -f "$P12_PATH" ]; then
    CERT_BASE64=$(base64 -i "$P12_PATH")
    echo "$CERT_BASE64" > "$OUTPUT_DIR/CERTIFICATE_P12.txt"
    echo -e "${GREEN}✓ Certificate exported and encoded${NC}"
    echo ""
    echo "CERTIFICATE_PASSWORD: $CERT_PASSWORD"
    echo "$CERT_PASSWORD" > "$OUTPUT_DIR/CERTIFICATE_PASSWORD.txt"
fi

# ============================================
# Step 2: Provisioning Profile
# ============================================
echo ""
echo -e "${GREEN}Step 2: Provisioning Profile${NC}"
echo "--------------------------------------------"
echo "Looking for App Store provisioning profiles..."
echo ""

PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"
PROFILE_PATH=""

# List available profiles
if [ -d "$PROFILES_DIR" ]; then
    echo "Available profiles:"
    for profile in "$PROFILES_DIR"/*.mobileprovision; do
        if [ -f "$profile" ]; then
            PROFILE_NAME=$(security cms -D -i "$profile" 2>/dev/null | plutil -extract Name raw - 2>/dev/null || echo "Unknown")
            PROFILE_TYPE=$(security cms -D -i "$profile" 2>/dev/null | plutil -extract Entitlements.get-task-allow raw - 2>/dev/null || echo "distribution")
            echo "  - $PROFILE_NAME ($(basename "$profile"))"

            # Check if this is an App Store profile for our app
            if [[ "$PROFILE_NAME" == *"Furg"* ]] || [[ "$PROFILE_NAME" == *"App Store"* ]]; then
                PROFILE_PATH="$profile"
            fi
        fi
    done
fi

if [ -z "$PROFILE_PATH" ]; then
    echo ""
    echo -e "${YELLOW}No matching provisioning profile found automatically.${NC}"
    echo ""
    echo "Please create an App Store provisioning profile:"
    echo "1. Go to https://developer.apple.com/account/resources/profiles"
    echo "2. Create new profile → App Store"
    echo "3. Select App ID: com.furg.app"
    echo "4. Select your Distribution certificate"
    echo "5. Download and double-click to install"
    echo ""
    read -p "Enter the full path to your .mobileprovision file: " PROFILE_PATH
fi

if [ -f "$PROFILE_PATH" ]; then
    PROFILE_BASE64=$(base64 -i "$PROFILE_PATH")
    echo "$PROFILE_BASE64" > "$OUTPUT_DIR/PROVISIONING_PROFILE.txt"
    echo -e "${GREEN}✓ Provisioning profile encoded${NC}"
else
    echo -e "${RED}Provisioning profile not found at: $PROFILE_PATH${NC}"
fi

# ============================================
# Step 3: Export Options
# ============================================
echo ""
echo -e "${GREEN}Step 3: Export Options Plist${NC}"
echo "--------------------------------------------"

EXPORT_OPTIONS_PATH="$(dirname "$0")/../ios/ExportOptions.plist"
if [ -f "$EXPORT_OPTIONS_PATH" ]; then
    EXPORT_BASE64=$(base64 -i "$EXPORT_OPTIONS_PATH")
    echo "$EXPORT_BASE64" > "$OUTPUT_DIR/EXPORT_OPTIONS_PLIST.txt"
    echo -e "${GREEN}✓ Export options encoded${NC}"
else
    echo -e "${YELLOW}ExportOptions.plist not found, using default...${NC}"
fi

# ============================================
# Step 4: Keychain Password
# ============================================
echo ""
echo -e "${GREEN}Step 4: Keychain Password${NC}"
echo "--------------------------------------------"
KEYCHAIN_PASS=$(openssl rand -base64 32)
echo "$KEYCHAIN_PASS" > "$OUTPUT_DIR/KEYCHAIN_PASSWORD.txt"
echo -e "${GREEN}✓ Random keychain password generated${NC}"

# ============================================
# Summary
# ============================================
echo ""
echo "========================================"
echo -e "${GREEN}  Setup Complete!${NC}"
echo "========================================"
echo ""
echo "Generated files are in: $OUTPUT_DIR"
echo ""
echo "Now you need to:"
echo ""
echo -e "${YELLOW}1. Create App Store Connect API Key:${NC}"
echo "   → Go to: https://appstoreconnect.apple.com/access/api"
echo "   → Click 'Generate API Key'"
echo "   → Name: 'GitHub Actions'"
echo "   → Access: 'App Manager'"
echo "   → Download the .p8 file (SAVE IT - one time download!)"
echo "   → Note the Key ID and Issuer ID"
echo ""
echo -e "${YELLOW}2. Add these secrets to GitHub:${NC}"
echo "   → Go to: https://github.com/joebrashear100/cuponer/settings/secrets/actions"
echo "   → Add each secret:"
echo ""
echo "   CERTIFICATE_P12          → Contents of $OUTPUT_DIR/CERTIFICATE_P12.txt"
echo "   CERTIFICATE_PASSWORD     → Contents of $OUTPUT_DIR/CERTIFICATE_PASSWORD.txt"
echo "   PROVISIONING_PROFILE     → Contents of $OUTPUT_DIR/PROVISIONING_PROFILE.txt"
echo "   EXPORT_OPTIONS_PLIST     → Contents of $OUTPUT_DIR/EXPORT_OPTIONS_PLIST.txt"
echo "   KEYCHAIN_PASSWORD        → Contents of $OUTPUT_DIR/KEYCHAIN_PASSWORD.txt"
echo "   APP_STORE_CONNECT_API_KEY_ID      → Your API Key ID"
echo "   APP_STORE_CONNECT_API_ISSUER_ID   → Your Issuer ID"
echo "   APP_STORE_CONNECT_API_KEY_CONTENT → Contents of your .p8 file"
echo ""
echo -e "${GREEN}3. Create the app in App Store Connect (if not done):${NC}"
echo "   → Go to: https://appstoreconnect.apple.com/apps"
echo "   → Click '+' → New App"
echo "   → Bundle ID: com.furg.app"
echo "   → Name: Furg"
echo ""
echo "Once all secrets are added, push to main and the workflow will run!"
echo ""
