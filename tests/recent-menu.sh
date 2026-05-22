#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE_FILE="$ROOT_DIR/src/main.m"

require_source() {
    local pattern="$1"
    local message="$2"

    if ! grep -Fq "$pattern" "$SOURCE_FILE"; then
        printf 'Missing recent menu behavior: %s\n' "$message" >&2
        exit 1
    fi
}

require_source 'Open Recent' 'File menu should expose an Open Recent submenu.'
require_source '@selector(openRecentDocument:)' 'Recent menu items should open selected recent documents.'
require_source '@selector(clearRecentDocuments:)' 'Recent menu should include a Clear Menu action.'
require_source 'recentDocumentURLs' 'Recent menu should be populated from NSDocumentController.'

printf 'Recent menu source checks passed.\n'
