#!/bin/bash
#
# Verify version references that should stay aligned with VERSION.
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/version.sh"

VERSION="$(read_repo_version)"
EXPECTED="public static let serverVersion = \"${VERSION}\""

if ! grep -Fq "$EXPECTED" Sources/OCRToolMCPCore/OCRToolMCPServer.swift; then
  echo "Mismatch: Sources/OCRToolMCPCore/OCRToolMCPServer.swift does not match VERSION=${VERSION}" >&2
  exit 1
fi

PINNED_FILES=(
  "README.md"
  "README.zh.md"
  "docs/CODE_SIGNING.md"
  "Sources/OCRToolMCP/main.swift"
  "test/python/rename_images_by_ocr.py"
)

for file in "${PINNED_FILES[@]}"; do
  if grep -Fq "$VERSION" "$file"; then
    echo "Unexpected pinned repository version ${VERSION} found in ${file}" >&2
    exit 1
  fi
done

echo "Version consistency check passed for VERSION=${VERSION}"
