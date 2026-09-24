#!/usr/bin/env bash

# --------------------------------------------------
# Workspace metadata script.
#
# Reports workspace context metadata.
# This script is informational only.
#
# Usage:
# ./scripts/linux/commands/meta/workspace-status.sh
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
. "$SCRIPT_DIR/../../utils/logging/formatting.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command uname

# --------------------------
# Helpers
# --------------------------

detect_workspace_environment() {
  if [[ "${CODESPACES:-}" == "true" ]]; then
    printf '%s' "GitHub Codespaces"
  elif [[ -n "${REMOTE_CONTAINERS:-}" || -n "${DEVCONTAINER:-}" ]]; then
    printf '%s' "VS Code Dev Container"
  elif [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    printf '%s' "Container"
  else
    printf '%s' "Local shell"
  fi
}

detect_os_name() {
  local os_name

  if [[ -f /etc/os-release ]]; then
    check_command awk || return 1
    os_name="$(awk -F= '$1 == "PRETTY_NAME" { gsub(/^"|"$/, "", $2); print $2 }' /etc/os-release)"
    printf '%s' "${os_name:-unavailable}"
  else
    uname -s
  fi
}

# --------------------------
# Workspace context
# --------------------------

workspace_environment="$(detect_workspace_environment)"
reset_status

add_status "Workspace operating system" "$(detect_os_name)"
add_status "Workspace environment" "$workspace_environment"

if [[ "$workspace_environment" == "GitHub Codespaces" ]]; then
  if [[ -n "${CODESPACE_NAME:-}" ]]; then
    add_status "Codespace name" "$CODESPACE_NAME"
  else
    add_status "Codespace name" "unavailable"
  fi
fi

add_status "Workspace path" "$(pwd -P)"

print_status
