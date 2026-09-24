#!/usr/bin/env bash

# --------------------------------------------------
# Utility functions for the repository scripts.
#
# This script is not meant to be run directly,
# scripts relying on these functions source this as needed.
# --------------------------------------------------

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This file is meant to be sourced, not executed directly" >&2
  exit 1
fi

# Guard against multiple sourcing
[[ -n "${_FUNCTIONS_LOADED:-}" ]] && return
_FUNCTIONS_LOADED=1

# --------------------------
# Setup
# --------------------------

# Load dependent scripts
FUNCTIONS_UTILS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$FUNCTIONS_UTILS_DIR/validation.sh"

# --------------------------
# Functions
# --------------------------

# Read a jq path from a json file and write it to stdout
json_field() {
  local file="${1:-}"
  local json_path="${2:-}"
  local filter

  check_argument "$file" "json file" || return 1
  check_argument "$json_path" "json path" || return 1
  check_command jq || return 1
  check_file "$file" || return 1

  case "$json_path" in
    .*)
      filter="$json_path"
      ;;
    *)
      filter=".$json_path"
      ;;
  esac

  jq -r "
    path($filter) as \$json_path
    | if \$json_path == [] then
        .
      elif any(paths; . == \$json_path) then
        getpath(\$json_path)
      else
        \"\" | halt_error(1)
      end
  " "$file"
}

# Check whether the current branch upstream changed any of the given paths
git_upstream_paths_changed() {
  local upstream_ref merge_base diff_status

  [[ "$#" -gt 0 ]] || return 1
  check_command git || return 1

  upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2> /dev/null || true)"
  [[ -n "$upstream_ref" ]] || return 1
  git rev-parse --verify --quiet "$upstream_ref^{commit}" > /dev/null || return 1

  merge_base="$(git merge-base HEAD "$upstream_ref" 2> /dev/null)" || return 1

  if git diff --quiet "$merge_base..$upstream_ref" -- "$@" 2> /dev/null; then
    return 1
  else
    diff_status="$?"
  fi

  case "$diff_status" in
    1)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}
