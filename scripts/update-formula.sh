#!/bin/bash
#
# Update Formula/ocrtool-mcp.rb to point at a GitHub Release archive.
#
# Usage:
#   ./scripts/update-formula.sh <version> <archive-sha256>
#

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: ./scripts/update-formula.sh <version> <archive-sha256>"
  exit 1
fi

VERSION="${1#v}"
ARCHIVE_SHA="$2"
APP_NAME="ocrtool-mcp"
ARCHIVE_NAME="${APP_NAME}-v${VERSION}-universal-macos.tar.gz"
UNIVERSAL_NAME="${APP_NAME}-v${VERSION}-universal"
FORMULA_PATH="$(cd "$(dirname "$0")/.." && pwd)/Formula/${APP_NAME}.rb"

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
