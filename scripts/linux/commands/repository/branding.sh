#!/usr/bin/env bash

# --------------------------------------------------
# Repository branding script.
#
# Prints the local banner used before repository health checks.
#
# Usage:
# ./scripts/linux/commands/repository/branding.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../utils/validation.sh"

BANNER_FILE="scripts/linux/resources/banner.ansi"
ANSI_PATTERN=$'\x1B\\[[0-9;?]*[ -/]*[@-~]'

# --------------------------
# Branding
# --------------------------

[[ -f "$BANNER_FILE" ]] || exit 0

printf '\n'

if [[ -n "${ASCII_ONLY:-}" ]]; then
  printf 'nlobby4\n'
elif [[ -n "${NO_COLOR:-}" ]] \
  || [[ "${TERM:-}" == "dumb" ]] \
  || [[ "${CI:-}" == "true" && "${GITHUB_ACTIONS:-}" != "true" ]] \
  || [[ ! -t 1 ]]; then
  check_command sed || exit 0
  sed -E "s/${ANSI_PATTERN}//g" "$BANNER_FILE"
else
  cat "$BANNER_FILE"
fi

printf '\n'

exit 0
