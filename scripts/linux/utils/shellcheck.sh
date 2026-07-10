#!/usr/bin/env bash

# --------------------------------------------------
# ShellCheck runner.
#
# Finds tracked and untracked shell scripts in the repository and runs
# ShellCheck using repository configuration from .shellcheckrc.
#
# Usage:
# ./scripts/linux/utils/shellcheck.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/functions.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root
check_command git
check_command shellcheck

# --------------------------
# Collect shell scripts
# --------------------------

shell_files=()
while IFS= read -r -d '' file; do
  [[ -f "$file" ]] || continue
  shell_files+=("$file")
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
