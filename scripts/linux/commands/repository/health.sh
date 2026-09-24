#!/usr/bin/env bash

# --------------------------------------------------
# Repository health check script.
#
# Runs each verification script in isolation and reports
# a non-zero exit status if any check fails. A failed check does not
# prevent the remaining checks from running.
#
# Used by the development container during startup.
#
# Usage:
# ./scripts/linux/commands/repository/health.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
VALIDATION_DIR="$SCRIPT_DIR/../validation"
. "$SCRIPT_DIR/../../utils/validation.sh"
. "$SCRIPT_DIR/../../utils/logging/formatting.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command bash

# --------------------------
# Validation
# --------------------------

bash "$SCRIPT_DIR/branding.sh" || true
separator
printf '\n'
log_info "Checking repository health..."

checks=(
  dict.sh
  attributes.sh
  lfs.sh
)
readonly -a checks

overall_status=0
heading_underline=""
check_index=0

if [[ -n "$COLOR_RESET" ]]; then
  heading_underline=$'\033[4m'
fi

printf '\n'

for check in "${checks[@]}"; do
  check_path="$VALIDATION_DIR/$check"

  if [[ "$check_index" -gt 0 ]]; then
    printf '\n'
  fi

  printf '%s%s%s:%s\n' "$COLOR_CYAN" "$heading_underline" "$check" "$COLOR_RESET"
  check_index="$((check_index + 1))"

  if [[ ! -f "$check_path" ]]; then
    log_warning "$check is missing at $check_path"
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

printf '\n'

# --------------------------
# Summary
# --------------------------

printf '%s%s%s:%s\n' "$COLOR_CYAN" "$heading_underline" "summary" "$COLOR_RESET"

if [[ "$overall_status" -eq 0 ]]; then
  log_ok "All health checks passed"
else
  log_error "One or more health checks failed"
  log_info "See output above for details"
fi

separator
bash "$SCRIPT_DIR/info.sh" || true

exit "$overall_status"
