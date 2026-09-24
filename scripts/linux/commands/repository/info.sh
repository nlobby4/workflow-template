#!/usr/bin/env bash

# --------------------------------------------------
# Repository startup information script.
#
# Runs repository metadata checks and prints each output in a summary box.
#
# Usage:
# ./scripts/linux/commands/repository/info.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DIR="scripts/linux/commands"
META_DIR="$COMMANDS_DIR/meta"
. "$SCRIPT_DIR/../../utils/validation.sh"
. "$SCRIPT_DIR/../../utils/logging/formatting.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command bash
check_command mktemp

# --------------------------
# Run metadata checks
# --------------------------

meta_checks=(
  workspace-status.sh
  git-status.sh
  node-status.sh
)
readonly -a meta_checks

info_tmp_dir="$(mktemp -d)"
terminal_width="$(tput cols 2> /dev/null || true)"
box_width=0
meta_outputs=()
meta_titles=()
trap 'rm -rf "$info_tmp_dir"' EXIT

for check in "${meta_checks[@]}"; do
  check_path="$META_DIR/$check"
  check_name="${check%.sh}"
  check_title="${check_name//-/ }"
  meta_output="$info_tmp_dir/$check_name.log"
  max_content_width=0

  if [[ ! -f "$check_path" ]]; then
    printf '%s: script not found\n' "$check_name" >> "$meta_output"
  elif ! bash "$check_path" >> "$meta_output" 2>&1; then
    printf '%s: reported metadata issues\n' "$check_name" >> "$meta_output"
  fi

  title_width="$(visible_width "$check_title")"
  max_content_width="$((title_width + 2))"

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_width="$(visible_width "$line")"
    if [[ "$line_width" -gt "$max_content_width" ]]; then
      max_content_width="$line_width"
    fi
  done < "$meta_output"

  required_box_width="$((max_content_width + 4))"
  if [[ "$required_box_width" -gt "$box_width" ]]; then
    box_width="$required_box_width"
  fi

  meta_titles+=("$check_title")
  meta_outputs+=("$meta_output")
done

if [[ "$terminal_width" =~ ^[0-9]+$ ]] \
  && [[ "$terminal_width" -ge 4 ]] \
  && [[ "$box_width" -gt "$terminal_width" ]]; then
  box_width="$terminal_width"
fi

for index in "${!meta_outputs[@]}"; do
  if [[ "$box_width" -ge 4 ]]; then
    print_box "${meta_titles[$index]}" "${meta_outputs[$index]}" "$box_width" "" "hanging-status"
  else
    print_box "${meta_titles[$index]}" "${meta_outputs[$index]}" "" "" "hanging-status"
  fi
done

exit 0
