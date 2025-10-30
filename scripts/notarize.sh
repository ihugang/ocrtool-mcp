#!/bin/bash
#
# Notarization script for ocrtool-mcp
# Usage: ./scripts/notarize.sh <zip-or-dmg-path>
#
# Prerequisites:
# 1. Binary must be signed (run scripts/sign.sh first)
# 2. Set environment variables:
#    export APPLE_ID="your@email.com"
#    export APPLE_TEAM_ID="6X2HSWDZCR"
#    export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"  # App-Specific Password
#

set -e

ARCHIVE_PATH="$1"
APPLE_ID="${APPLE_ID}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-6X2HSWDZCR}"
APPLE_APP_PASSWORD="${APPLE_APP_PASSWORD}"

echo "🍎 Starting notarization process..."

# Check if archive exists
if [ ! -f "$ARCHIVE_PATH" ]; then
    echo "❌ Error: Archive not found at $ARCHIVE_PATH"
    exit 1
fi

# Check environment variables
if [ -z "$APPLE_ID" ] || [ -z "$APPLE_APP_PASSWORD" ]; then
    echo "❌ Error: APPLE_ID and APPLE_APP_PASSWORD must be set"
    echo ""
    echo "Example:"
    echo "  export APPLE_ID=\"your@email.com\""
    echo "  export APPLE_APP_PASSWORD=\"xxxx-xxxx-xxxx-xxxx\""
    echo ""
    echo "Get App-Specific Password from: https://appleid.apple.com/account/manage"
    exit 1
fi

echo "📦 Uploading to Apple for notarization..."
xcrun notarytool submit "$ARCHIVE_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$APPLE_TEAM_ID" \
    --password "$APPLE_APP_PASSWORD" \
    --wait

echo ""
echo "✅ Notarization complete!"
echo ""
echo "To staple the notarization ticket (for .dmg or .app):"
echo "  xcrun stapler staple <path-to-file>"
