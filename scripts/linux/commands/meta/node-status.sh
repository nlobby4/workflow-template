#!/usr/bin/env bash

# --------------------------------------------------
# Node.js metadata script.
#
# Reports Node.js dependency installation metadata for repositories that use
# package.json.
#
# Usage:
# ./scripts/linux/commands/meta/node-status.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
NODE_STATUS_SCRIPT="scripts/node/bin/node-status.js"
. "$SCRIPT_DIR/../../utils/functions.sh"
. "$SCRIPT_DIR/../../utils/logging/formatting.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command jq
check_command node
check_file "$NODE_STATUS_SCRIPT"
reset_status

# --------------------------
# Dependency install state
# --------------------------

if [[ -f package.json ]] \
  && git_upstream_paths_changed ':(glob)**/package.json' ':(glob)**/pnpm-lock.yaml' ':(glob)**/pnpm-workspace.yaml'; then
  if [[ -f pnpm-lock.yaml ]]; then
    add_status "Node.js dependencies" "remote branch has dependency changes; pull and run pnpm install --frozen-lockfile"
  else
    add_status "Node.js dependencies" "remote branch has dependency changes; pull and run \"pnpm install\""
  fi
else
  while IFS=$'\t' read -r label value; do
    add_status "$label" "$value"
  done < <(
    node "$NODE_STATUS_SCRIPT" \
      | jq -r '.[] | [.label, .value] | @tsv'
  )
fi

print_status
