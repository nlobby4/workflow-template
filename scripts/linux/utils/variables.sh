#!/usr/bin/env bash

# --------------------------------------------------
# Shared variables for shell scripts in this repository.
#
# This script is not meant to be run directly,
# scripts relying on these variables source this as needed.
# --------------------------------------------------

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This file is meant to be sourced, not executed directly" >&2
  exit 1
fi

# Guard against multiple sourcing
[[ -n "${_VARIABLES_LOADED:-}" ]] && return
_VARIABLES_LOADED=1

# --------------------------
# Variables
# --------------------------

if [[ -z "${NO_COLOR:-}" ]] \
  && [[ -t 1 || "${GITHUB_ACTIONS:-}" == "true" ]] \
  && [[ "${TERM:-}" != "dumb" ]] \
  && [[ "${CI:-}" != "true" || "${GITHUB_ACTIONS:-}" == "true" ]]; then

  COLOR_GREEN=$'\033[0;32m'
  COLOR_RED=$'\033[0;31m'
  COLOR_YELLOW=$'\033[0;33m'
  COLOR_CYAN=$'\033[0;36m'
  COLOR_RESET=$'\033[0m'

  readonly COLOR_GREEN COLOR_RED COLOR_YELLOW COLOR_CYAN COLOR_RESET

  OK="${COLOR_GREEN}✓ Success:${COLOR_RESET}"
  ERROR="${COLOR_RED}✗ Error:${COLOR_RESET}"
  WARN="${COLOR_YELLOW}⚠ Warning:${COLOR_RESET}"
  INFO="${COLOR_CYAN}i Info:${COLOR_RESET}"
else
  OK="[OK]:"
  ERROR="[ERROR]:"
  WARN="[WARN]:"
  INFO="[INFO]:"
fi

readonly OK ERROR WARN INFO
