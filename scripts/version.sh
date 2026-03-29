#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION_FILE="${ROOT_DIR}/VERSION"

normalize_version() {
  local raw="${1:-}"
  echo "${raw#v}"
}

read_repo_version() {
  if [[ ! -f "$VERSION_FILE" ]]; then
    echo "VERSION file not found at ${VERSION_FILE}" >&2
    return 1
  fi

  tr -d '[:space:]' < "$VERSION_FILE"
}

write_repo_version() {
  local version
  version="$(normalize_version "${1:-}")"

  if [[ -z "$version" ]]; then
    echo "Version must not be empty" >&2
    return 1
  fi

  printf '%s\n' "$version" > "$VERSION_FILE"
}
