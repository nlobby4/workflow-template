#!/usr/bin/env bash

# --------------------------------------------------
# GitHub Actions workflow validation script.
#
# Finds tracked and untracked GitHub Actions workflow files
# and validates them with actionlint.
#
# Usage:
# ./scripts/linux/commands/validation/actionlint.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

# Load dependent scripts
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../utils/validation.sh"
. "$SCRIPT_DIR/../../utils/logging/formatting.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command actionlint
check_command git

# --------------------------
# Collect workflow files
# --------------------------

workflow_files=()
while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  workflow_files+=("$file")
done < <(
  git ls-files \
    --cached \
    --others \
    --exclude-standard \
    -z \
    -- \
    ".github/workflows/*.yaml" \
    ".github/workflows/*.yml"
)

if [[ "${#workflow_files[@]}" -eq 0 ]]; then
  log_ok "No GitHub Actions workflows found"
  exit 0
fi

# --------------------------
# Actionlint
# --------------------------

log_info "Running actionlint on ${#workflow_files[@]} GitHub Actions workflows..."

actionlint "${workflow_files[@]}"

workflow_label="$(plural_label "${#workflow_files[@]}" "workflow" "workflows")"
log_ok "actionlint passed for ${#workflow_files[@]} GitHub Actions $workflow_label"
