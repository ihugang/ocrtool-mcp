#!/bin/bash
#
# Build, optionally sign/notarize, and package a release for ocrtool-mcp.
#
# Usage:
#   ./scripts/build-release.sh [version]
#
# Environment variables:
#   APP_NAME               Default: ocrtool-mcp
#   OUTPUT_DIR             Default: release
#   SIGN_IDENTITY          Developer ID identity. If empty, signing is skipped.
#   NOTARIZE              auto | always | never   Default: auto
#   KEYCHAIN_PROFILE       Default: AC_PASSWORD
#   APPLE_ID               Optional fallback for notarization
#   APPLE_TEAM_ID          Optional fallback for notarization
#   APPLE_APP_PASSWORD     Optional fallback for notarization
#   UPDATE_FORMULA         true | false           Default: true
#   RUN_TESTS              true | false           Default: true
#

set -euo pipefail

VERSION_INPUT="${1:-${VERSION:-$(git describe --tags --abbrev=0 2>/dev/null || echo "dev")}}"
VERSION="${VERSION_INPUT#v}"

APP_NAME="${APP_NAME:-ocrtool-mcp}"
OUTPUT_DIR="${OUTPUT_DIR:-release}"
SIGN_IDENTITY="${SIGN_IDENTITY-Developer ID Application: Hangzhou Gravity Cyberinfo Co.,Ltd (6X2HSWDZCR)}"
NOTARIZE_MODE="${NOTARIZE:-auto}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-AC_PASSWORD}"
APPLE_TEAM_ID="${APPLE_TEAM_ID:-6X2HSWDZCR}"
UPDATE_FORMULA="${UPDATE_FORMULA:-true}"
RUN_TESTS="${RUN_TESTS:-true}"

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

UNIVERSAL_NAME="${APP_NAME}-v${VERSION}-universal"
ARCHIVE_NAME="${UNIVERSAL_NAME}-macos.tar.gz"
ZIP_NAME="${UNIVERSAL_NAME}.zip"
BINARY_PATH=".build/apple/Products/Release/${APP_NAME}"
ARCHIVE_PATH="${OUTPUT_DIR}/${ARCHIVE_NAME}"
UNIVERSAL_PATH="${OUTPUT_DIR}/${UNIVERSAL_NAME}"
CHECKSUMS_PATH="${OUTPUT_DIR}/checksums.txt"
METADATA_PATH="${OUTPUT_DIR}/release-metadata.json"
FORMULA_PATH="Formula/${APP_NAME}.rb"

echo "Building ${APP_NAME} v${VERSION}"

rm -rf .build/apple "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

if [[ "$RUN_TESTS" == "true" ]]; then
  swift test
fi

swift build -c release --arch arm64 --arch x86_64

file "$BINARY_PATH"
lipo -info "$BINARY_PATH"

SIGNING_PERFORMED="false"
if [[ -n "$SIGN_IDENTITY" ]] && security find-identity -v -p codesigning 2>/dev/null | grep -Fq "$SIGN_IDENTITY"; then
  echo "Signing binary with identity: $SIGN_IDENTITY"
  codesign --sign "$SIGN_IDENTITY" \
    --options runtime \
    --timestamp \
    --force \
    "$BINARY_PATH"
  codesign --verify --verbose "$BINARY_PATH"
  SIGNING_PERFORMED="true"
else
  echo "Signing skipped: identity not available in current keychain."
fi

cp "$BINARY_PATH" "$UNIVERSAL_PATH"

tar -czf "$ARCHIVE_PATH" -C "$OUTPUT_DIR" "$UNIVERSAL_NAME"

ARCHIVE_SHA="$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')"
BINARY_SHA="$(shasum -a 256 "$UNIVERSAL_PATH" | awk '{print $1}')"

{
  echo "${BINARY_SHA}  ${UNIVERSAL_NAME}"
  echo "${ARCHIVE_SHA}  ${ARCHIVE_NAME}"
} > "$CHECKSUMS_PATH"

NOTARIZATION_PERFORMED="false"
if [[ "$NOTARIZE_MODE" != "never" ]]; then
  SHOULD_NOTARIZE="false"

  if [[ "$NOTARIZE_MODE" == "always" ]]; then
    SHOULD_NOTARIZE="true"
  elif [[ "$SIGNING_PERFORMED" == "true" ]]; then
    if xcrun notarytool list-profiles 2>/dev/null | grep -Fq "$KEYCHAIN_PROFILE"; then
      SHOULD_NOTARIZE="true"
    elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" ]]; then
      SHOULD_NOTARIZE="true"
    fi
  fi

  if [[ "$SHOULD_NOTARIZE" == "true" ]]; then
    (
      cd "$OUTPUT_DIR"
      zip -q -r "$ZIP_NAME" "$UNIVERSAL_NAME"
    )

    if xcrun notarytool list-profiles 2>/dev/null | grep -Fq "$KEYCHAIN_PROFILE"; then
      xcrun notarytool submit "${OUTPUT_DIR}/${ZIP_NAME}" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait
    else
      xcrun notarytool submit "${OUTPUT_DIR}/${ZIP_NAME}" \
        --apple-id "${APPLE_ID}" \
        --team-id "${APPLE_TEAM_ID}" \
        --password "${APPLE_APP_PASSWORD}" \
        --wait
    fi

    spctl --assess --verbose "$UNIVERSAL_PATH" || true
    rm -f "${OUTPUT_DIR}/${ZIP_NAME}"
    NOTARIZATION_PERFORMED="true"
  else
    echo "Notarization skipped."
  fi
fi

cat > "$METADATA_PATH" <<EOF
{
  "name": "${APP_NAME}",
  "version": "${VERSION}",
  "binary": "${UNIVERSAL_NAME}",
  "archive": "${ARCHIVE_NAME}",
  "archiveSha256": "${ARCHIVE_SHA}",
  "binarySha256": "${BINARY_SHA}",
  "signed": ${SIGNING_PERFORMED},
  "notarized": ${NOTARIZATION_PERFORMED}
}
EOF

if [[ "$UPDATE_FORMULA" == "true" && "$VERSION" != "dev" ]]; then
  cat > "$FORMULA_PATH" <<EOF
class OcrtoolMcp < Formula
  desc "macOS native OCR MCP server powered by the Vision framework"
  homepage "https://github.com/ihugang/ocrtool-mcp"
  url "https://github.com/ihugang/ocrtool-mcp/releases/download/v${VERSION}/${ARCHIVE_NAME}"
  sha256 "${ARCHIVE_SHA}"
  license "MIT"

  depends_on :macos

  def install
    bin.install "${UNIVERSAL_NAME}" => "ocrtool-mcp"
  end

  test do
    assert_match "OCRToolMCP Help", shell_output("#{bin}/ocrtool-mcp --help")
  end
end
EOF
  echo "Updated ${FORMULA_PATH}"
fi

echo
echo "Release artifacts:"
ls -lh "$OUTPUT_DIR"
echo
echo "Checksums:"
cat "$CHECKSUMS_PATH"
