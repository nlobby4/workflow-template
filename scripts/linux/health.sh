#!/usr/bin/env bash

# --------------------------------------------------
# Repository health check script.
#
# Runs each repository verification script in isolation and reports
# a non-zero exit status if any check fails. A failed check does not
# prevent the remaining checks from running.
#
# Used by the development container during startup.
#
# Usage:
# ./scripts/linux/health.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/utils"
. "$UTILS_DIR/functions.sh"

log_info "Checking repository health..."

check_project_root
check_command bash

# --------------------------
# Run checks
# --------------------------

checks=(
  dict.sh
  attributes.sh
  lfs.sh
)
readonly -a checks

overall_status=0

for check in "${checks[@]}"; do
  check_path="$UTILS_DIR/$check"

  separator
  log_info "Running $check..."

  if ! check_file "$check_path"; then
    overall_status=1
    continue
  fi

  # Invoking Bash creates an isolated process for each check
  if bash "$check_path"; then
    log_ok "$check passed"
  else
    log_error "$check reported issues"
    overall_status=1
  fi
done

# --------------------------
# Summary
# --------------------------

separator

if [[ "$overall_status" -eq 0 ]]; then
  log_ok "All health checks passed"
else
  log_error "One or more health checks failed"
  log_info "See output above for details"
fi

exit "$overall_status"
