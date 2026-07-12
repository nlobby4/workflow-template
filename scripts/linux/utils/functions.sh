#!/usr/bin/env bash

# --------------------------------------------------
# Utility functions for the repository scripts.
#
# This script is not meant to be run directly,
# scripts relying on these functions source this as needed.
# --------------------------------------------------

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This file is meant to be sourced, not executed directly." >&2
  exit 1
fi

# Guard against multiple sourcing
[[ -n "${_FUNCTIONS_LOADED:-}" ]] && return
_FUNCTIONS_LOADED=1

# Load dependent scripts
_FUNCTIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$_FUNCTIONS_DIR/variables.sh"
unset _FUNCTIONS_DIR

# --------------------------
# Functions
# --------------------------

# Logging
log_ok() { printf '%s %s\n' "$OK" "$*"; }
log_info() { printf '%s %s\n' "$INFO" "$*"; }
log_warning() { printf '%s %s\n' "$WARN" "$*"; }
log_error() { printf '%s %s\n' "$ERROR" "$*" >&2; }

# Check if a command is available in PATH
check_command() {
  local command_name="${1:-}"

  if [[ -z "$command_name" ]]; then
    log_error "missing required argument: command name"
    return 1
  fi

  command -v "$command_name" > /dev/null 2>&1 || {
    log_error "$command_name is required but was not found in PATH"
    return 1
  }
}

# Check if a required argument is provided
check_argument() {
  local value="${1:-}"
  local name="${2:-argument}"

  if [[ -z "$value" ]]; then
    log_error "missing required argument: $name"
    return 1
  fi
}

# Return singular or plural label based on count
plural_label() {
  local count="${1:-0}"
  local singular="${2:-entry}"
  local plural="${3:-${singular}s}"

  if [[ "$singular" == *y ]]; then
    plural="${3:-${singular%y}ies}"
  fi

  if [[ "$count" -eq 1 ]]; then
    printf '%s' "$singular"
  else
    printf '%s' "$plural"
  fi
}

# Check if a file exists
check_file() {
  local file="${1:-}"

  if [[ -z "$file" ]]; then
    log_error "missing required argument: file path"
    return 1
  fi

  [[ -f "$file" ]] || {
    log_error "file not found: $file"
    return 1
  }
}

# Check if the current directory is inside a git repository
check_git_repo() {
  check_command git || return 1
  git rev-parse --is-inside-work-tree > /dev/null 2>&1
}

# Check if git LFS is initialized for this repository
check_git_lfs() {
  check_git_repo || return 1
  check_command git-lfs || return 1
  git config --local --get filter.lfs.clean > /dev/null 2>&1
}

# Check if the script is run from the project root
check_project_root() {
  check_command git || return 1

  local project_root current_dir

  project_root="$(git rev-parse --show-toplevel 2> /dev/null)" || {
    log_error "not inside a git repository"
    return 1
  }

  project_root="$(cd "$project_root" && pwd -P)"
  current_dir="$(pwd -P)"

  if [[ "$current_dir" != "$project_root" ]]; then
    log_error "run this script from repository root"
    return 1
  fi
}

# Read a field from a json file and write it to stdout
json_field() {
  local file="${1:-}"
  local key="${2:-}"

  check_argument "$file" "json file" || return 1
  check_argument "$key" "json field" || return 1
  check_command jq || return 1
  check_file "$file" || return 1

  jq -r -e --arg key "$key" '
    getpath($key | split("."))
  ' "$file" || return 1
}

separator() {
  local width line
  width="$(tput cols 2> /dev/null || echo 60)"

  if [[ ! "$width" =~ ^[0-9]+$ ]] || [[ "$width" -lt 1 ]]; then
    width=60
  fi

  printf -v line '%*s' "$width" ''
  printf '%s\n' "${line// /─}"
}
