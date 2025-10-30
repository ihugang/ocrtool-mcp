#!/bin/bash
#
# Code signing script for ocrtool-mcp
# Usage: ./scripts/sign.sh <binary-path>
#

set -e

BINARY_PATH="${1:-.build/apple/Products/Release/ocrtool-mcp}"
IDENTITY="Developer ID Application: Hangzhou Gravity Cyberinfo Co.,Ltd (6X2HSWDZCR)"

echo "🔐 Signing binary: $BINARY_PATH"

# Check if binary exists
if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Error: Binary not found at $BINARY_PATH"
    exit 1
fi

# Sign the binary
codesign --sign "$IDENTITY" \
    --options runtime \
    --timestamp \
    --force \
    "$BINARY_PATH"

echo "✅ Binary signed successfully"

# Verify signature
echo "🔍 Verifying signature..."
codesign --verify --verbose "$BINARY_PATH"
codesign --display --verbose=4 "$BINARY_PATH"

echo ""
echo "✅ Code signing complete!"
