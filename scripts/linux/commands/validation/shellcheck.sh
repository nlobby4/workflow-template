#!/usr/bin/env bash

# --------------------------------------------------
# ShellCheck runner.
#
# Finds tracked and untracked shell scripts in the repository and runs
# ShellCheck using repository configuration from .shellcheckrc.
#
# Usage:
# ./scripts/linux/commands/validation/shellcheck.sh
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
check_command git
check_command shellcheck

# --------------------------
# Collect shell scripts
# --------------------------

shell_files=()
declare -A seen_shell_files

add_shell_file() {
  local file="${1:-}"

  [[ -n "$file" && -f "$file" ]] || return 0
  [[ -z "${seen_shell_files[$file]:-}" ]] || return 0

  shell_files+=("$file")
  seen_shell_files["$file"]=1
}

has_shell_shebang() {
  local file="${1:-}"
  local first_line

  [[ -n "$file" && -f "$file" ]] || return 1
  IFS= read -r first_line < "$file" || return 1

  [[ "$first_line" =~ ^'#!'.*(^|[/[:space:]])(ba)?sh([[:space:]]|$) ]]
}

while IFS= read -r -d '' file; do
  add_shell_file "$file"
done < <(
  git ls-files \
    --cached \
    --others \
    --exclude-standard \
    -z \
    -- \
    '*.sh' \
    '.husky/*' \
    ':!.husky/_/**'
)

while IFS= read -r -d '' file; do
  if has_shell_shebang "$file"; then
    add_shell_file "$file"
  fi
done < <(
  git ls-files \
    --cached \
    --others \
    --exclude-standard \
    -z \
    -- \
    ':!.husky/_/**'
)

if [[ "${#shell_files[@]}" -eq 0 ]]; then
  log_ok "No shell scripts found"
  exit 0
fi

# --------------------------
# ShellCheck
# --------------------------

log_info "Running ShellCheck on ${#shell_files[@]} shell scripts..."

shellcheck "${shell_files[@]}"

script_label="$(plural_label "${#shell_files[@]}" "script" "scripts")"
log_ok "ShellCheck passed for ${#shell_files[@]} shell $script_label"
