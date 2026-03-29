#!/bin/bash
#
# Install the bundled OCR skill into a target skill directory.
#
# Usage:
#   ./scripts/install-skill.sh codex
#   ./scripts/install-skill.sh claude
#   ./scripts/install-skill.sh /custom/skills/dir
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_DIR="${ROOT_DIR}/skill/ocr-workflow"

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Skill source not found: ${SOURCE_DIR}" >&2
  exit 1
fi

TARGET_INPUT="${1:-codex}"

case "$TARGET_INPUT" in
  codex)
    TARGET_DIR="${CODEX_HOME:-$HOME/.codex}/skills/ocr-workflow"
    ;;
  claude)
    TARGET_DIR="$HOME/.claude/skills/ocr-workflow"
    ;;
  *)
    TARGET_DIR="${TARGET_INPUT%/}/ocr-workflow"
    ;;
esac

mkdir -p "$(dirname "$TARGET_DIR")"
rm -rf "$TARGET_DIR"
cp -R "$SOURCE_DIR" "$TARGET_DIR"

echo "Installed ocr-workflow skill to ${TARGET_DIR}"
