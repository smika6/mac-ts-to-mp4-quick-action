#!/bin/zsh
# Uninstaller for the "Convert TS to MP4" Quick Action.

set -euo pipefail

SERVICE_NAME="Convert TS to MP4"
WORKFLOW_DIR="${HOME}/Library/Services/${SERVICE_NAME}.workflow"

if [[ -d "$WORKFLOW_DIR" ]]; then
  rm -rf "$WORKFLOW_DIR"
  /System/Library/CoreServices/pbs -flush  >/dev/null 2>&1 || true
  /System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
  printf "\033[1;32m✓\033[0m Removed %s\n" "$WORKFLOW_DIR"
else
  printf "\033[1;33m!\033[0m Nothing to remove (%s does not exist)\n" "$WORKFLOW_DIR"
fi
