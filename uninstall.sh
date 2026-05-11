#!/bin/zsh
# Uninstaller for the Convert TS Quick Actions.

set -euo pipefail

SERVICES_DIR="${HOME}/Library/Services"
SERVICE_NAMES=(
  "Convert TS to MP4 (60 fps)"
  "Convert TS to MP4 (90 fps)"
  "Convert TS to MKV"
  "Convert TS to MP4"  # legacy name from before the 60/90 split
)

removed_any=0
for name in "${SERVICE_NAMES[@]}"; do
  workflow_dir="${SERVICES_DIR}/${name}.workflow"
  if [[ -d "$workflow_dir" ]]; then
    rm -rf "$workflow_dir"
    printf "\033[1;32m✓\033[0m Removed %s\n" "$workflow_dir"
    removed_any=1
  else
    printf "\033[1;33m!\033[0m Nothing to remove (%s does not exist)\n" "$workflow_dir"
  fi
done

if [[ $removed_any -eq 1 ]]; then
  /System/Library/CoreServices/pbs -flush  >/dev/null 2>&1 || true
  /System/Library/CoreServices/pbs -update >/dev/null 2>&1 || true
fi
