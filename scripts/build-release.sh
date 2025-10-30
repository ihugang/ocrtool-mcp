#!/bin/bash
#
# Complete build, sign, and notarize script for ocrtool-mcp
# Usage: ./scripts/build-release.sh [version]
#
# This script will:
# 1. Build universal binary
# 2. Sign the binary
# 3. Create release archive
# 4. Notarize (if keychain profile exists)
# 5. Generate checksums
#

set -e

VERSION="${1:-$(git describe --tags --abbrev=0 2>/dev/null || echo "dev")}"
VERSION="${VERSION#v}"  # Remove 'v' prefix if present

APP_NAME="ocrtool-mcp"
CERT_ID="Developer ID Application: Hangzhou Gravity Cyberinfo Co.,Ltd (6X2HSWDZCR)"
KEYCHAIN_PROFILE="AC_PASSWORD"  # Optional: change to your profile name

echo "🚀 Building ${APP_NAME} v${VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Step 1: Clean previous builds
echo ""
echo "🧹 Cleaning previous builds..."
rm -rf .build/apple

# Step 2: Build universal binary
echo ""
echo "🏗️  Building universal binary..."
swift build -c release --arch arm64 --arch x86_64

# Step 3: Verify build
echo ""
echo "🔍 Verifying binary..."
BINARY_PATH=".build/apple/Products/Release/${APP_NAME}"
file "$BINARY_PATH"
lipo -info "$BINARY_PATH"

# Step 4: Sign binary
echo ""
echo "🔏 Signing binary..."
codesign --sign "$CERT_ID" \
    --options runtime \
    --timestamp \
    --force \
    "$BINARY_PATH"

# Verify signature
codesign --verify --verbose "$BINARY_PATH"

# Step 5: Create release directory and files
echo ""
echo "📦 Creating release files..."
mkdir -p release
cp "$BINARY_PATH" "release/${APP_NAME}-v${VERSION}-universal"

# Create tar.gz archive
cd release
tar -czf "${APP_NAME}-v${VERSION}-universal-macos.tar.gz" "${APP_NAME}-v${VERSION}-universal"
cd ..

# Step 6: Generate checksums
echo ""
echo "🔐 Generating checksums..."
cd release
shasum -a 256 "${APP_NAME}-v${VERSION}-universal" > checksums.txt
shasum -a 256 "${APP_NAME}-v${VERSION}-universal-macos.tar.gz" >> checksums.txt
cat checksums.txt
cd ..

# Step 7: Notarize (optional, if keychain profile exists)
echo ""
echo "📨 Checking for notarization setup..."
if xcrun notarytool list-profiles 2>/dev/null | grep -q "$KEYCHAIN_PROFILE"; then
    echo "✓ Keychain profile found: $KEYCHAIN_PROFILE"
    echo ""
    read -p "Do you want to notarize the binary? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cd release
        zip -r "${APP_NAME}-v${VERSION}-universal.zip" "${APP_NAME}-v${VERSION}-universal"

        echo "📤 Submitting for notarization..."
        xcrun notarytool submit "${APP_NAME}-v${VERSION}-universal.zip" \
            --keychain-profile "$KEYCHAIN_PROFILE" \
            --wait

        echo ""
        echo "🔍 Verifying notarization..."
        spctl --assess --verbose "${APP_NAME}-v${VERSION}-universal" || true

        rm "${APP_NAME}-v${VERSION}-universal.zip"
        cd ..
    fi
else
    echo "⚠️  No keychain profile found. Skipping notarization."
    echo ""
    echo "To setup notarization:"
    echo "  xcrun notarytool store-credentials \"$KEYCHAIN_PROFILE\" \\"
    echo "    --apple-id \"your@email.com\" \\"
    echo "    --team-id \"6X2HSWDZCR\" \\"
    echo "    --password \"xxxx-xxxx-xxxx-xxxx\""
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Build complete!"
echo ""
echo "📁 Release files:"
ls -lh release/
echo ""
echo "📋 Next steps:"
echo "  1. Test the binary: release/${APP_NAME}-v${VERSION}-universal --help"
echo "  2. Create GitHub release: gh release create v${VERSION}"
echo "  3. Upload files to GitHub release"
echo "  4. Update Homebrew formula with new version and SHA256"
