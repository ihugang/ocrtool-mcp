#!/bin/bash
#
# Update the repository version source and version-linked source files.
#
# Usage:
#   ./scripts/bump-version.sh <version>
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

source "$ROOT_DIR/scripts/version.sh"

if [[ $# -ne 1 ]]; then
  echo "Usage: ./scripts/bump-version.sh <version>" >&2
  exit 1
fi

VERSION="$(normalize_version "$1")"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-.][A-Za-z0-9]+)?$ ]]; then
  echo "Invalid version: ${VERSION}" >&2
  exit 1
fi

write_repo_version "$VERSION"

perl -0pi -e "s/public static let serverVersion = \"[^\"]+\"/public static let serverVersion = \"${VERSION}\"/" \
  Sources/OCRToolMCPCore/OCRToolMCPServer.swift

echo "Bumped repository version to ${VERSION}"
echo "Updated:"
echo "- VERSION"
echo "- Sources/OCRToolMCPCore/OCRToolMCPServer.swift"
