#!/bin/bash
#
# Notarization script for ocrtool-mcp
# Usage:
#   Method 1 (Keychain Profile): ./scripts/notarize.sh <zip-path> [profile-name]
#   Method 2 (Environment Vars): ./scripts/notarize.sh <zip-path>
#
# Prerequisites:
# 1. Binary must be signed (run scripts/sign.sh first)
#
# Method 1: Keychain Profile (Recommended)
#   - Setup once: xcrun notarytool store-credentials "AC_PASSWORD" --apple-id "..." --team-id "..." --password "..."
#   - Usage: ./scripts/notarize.sh archive.zip AC_PASSWORD
#
# Method 2: Environment Variables
#   - Set: export APPLE_ID="..." APPLE_TEAM_ID="..." APPLE_APP_PASSWORD="..."
#   - Usage: ./scripts/notarize.sh archive.zip
#

set -e

ARCHIVE_PATH="$1"
KEYCHAIN_PROFILE="${2}"  # Optional: keychain profile name
APPLE_ID="${APPLE_ID}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-6X2HSWDZCR}"
APPLE_APP_PASSWORD="${APPLE_APP_PASSWORD}"

echo "🍎 Starting notarization process..."

# Check if archive exists
if [ ! -f "$ARCHIVE_PATH" ]; then
    echo "❌ Error: Archive not found at $ARCHIVE_PATH"
    echo ""
    echo "Usage: ./scripts/notarize.sh <archive-path> [keychain-profile]"
    exit 1
fi

echo "📦 Uploading to Apple for notarization..."

# Method 1: Use keychain profile if provided
if [ -n "$KEYCHAIN_PROFILE" ]; then
    echo "🔐 Using keychain profile: $KEYCHAIN_PROFILE"
    xcrun notarytool submit "$ARCHIVE_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait

# Method 2: Use environment variables
elif [ -n "$APPLE_ID" ] && [ -n "$APPLE_APP_PASSWORD" ]; then
    echo "🔐 Using environment variables"
    xcrun notarytool submit "$ARCHIVE_PATH" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID" \
        --password "$APPLE_APP_PASSWORD" \
        --wait
else
    echo "❌ Error: Either provide keychain profile or set environment variables"
    echo ""
    echo "Method 1 (Recommended):"
    echo "  Setup: xcrun notarytool store-credentials \"AC_PASSWORD\" \\"
    echo "           --apple-id \"your@email.com\" \\"
    echo "           --team-id \"6X2HSWDZCR\" \\"
    echo "           --password \"xxxx-xxxx-xxxx-xxxx\""
    echo "  Usage: ./scripts/notarize.sh <archive> AC_PASSWORD"
    echo ""
    echo "Method 2:"
    echo "  export APPLE_ID=\"your@email.com\""
    echo "  export APPLE_APP_PASSWORD=\"xxxx-xxxx-xxxx-xxxx\""
    echo "  ./scripts/notarize.sh <archive>"
    echo ""
    echo "Get App-Specific Password from: https://appleid.apple.com/account/manage"
    exit 1
fi

echo ""
echo "✅ Notarization complete!"
echo ""
echo "To verify notarization:"
echo "  spctl --assess --verbose <binary-path>"
echo ""
echo "To staple the notarization ticket (for .dmg or .app):"
echo "  xcrun stapler staple <path-to-file>"
