#!/usr/bin/env bash

# --------------------------------------------------
# Logging functions for repository scripts.
#
# This script is not meant to be run directly,
# scripts relying on these helpers source this as needed.
# --------------------------------------------------

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This file is meant to be sourced, not executed directly" >&2
  exit 1
fi

# Guard against multiple sourcing
[[ -n "${_LOGGING_LOADED:-}" ]] && return
_LOGGING_LOADED=1

# --------------------------
# Logging
# --------------------------

COLOR_GREEN=""
COLOR_RED=""
COLOR_YELLOW=""
COLOR_CYAN=""
COLOR_RESET=""

if [[ -z "${NO_COLOR:-}" ]] \
  && [[ -t 1 || "${GITHUB_ACTIONS:-}" == "true" ]] \
  && [[ "${TERM:-}" != "dumb" ]] \
  && [[ "${CI:-}" != "true" || "${GITHUB_ACTIONS:-}" == "true" ]]; then

  COLOR_GREEN=$'\033[0;32m'
  COLOR_RED=$'\033[0;31m'
  COLOR_YELLOW=$'\033[0;33m'
  COLOR_CYAN=$'\033[0;36m'
  COLOR_RESET=$'\033[0m'
fi

readonly \
  COLOR_GREEN \
  COLOR_RED \
  COLOR_YELLOW \
  COLOR_CYAN \
  COLOR_RESET

if [[ -z "${ASCII_ONLY:-}" ]]; then
  OK="${COLOR_GREEN}✓ SUCCESS:${COLOR_RESET}"
  ERROR="${COLOR_RED}✗ ERROR:${COLOR_RESET}"
  WARN="${COLOR_YELLOW}⚠ WARNING:${COLOR_RESET}"
  INFO="${COLOR_CYAN}i INFO:${COLOR_RESET}"
else
  OK="${COLOR_GREEN}[OK]:${COLOR_RESET}"
  ERROR="${COLOR_RED}[ERROR]:${COLOR_RESET}"
  WARN="${COLOR_YELLOW}[WARN]:${COLOR_RESET}"
  INFO="${COLOR_CYAN}[INFO]:${COLOR_RESET}"
fi

readonly OK ERROR WARN INFO

log_ok() { printf '%s %s\n' "$OK" "$*"; }
log_info() { printf '%s %s\n' "$INFO" "$*"; }
log_warning() { printf '%s %s\n' "$WARN" "$*"; }
log_error() { printf '%s %s\n' "$ERROR" "$*" >&2; }
