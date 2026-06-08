#!/usr/bin/env bash

# --------------------------------------------------
# Git attributes verification script.
#
# This script checks whether tracked files have a corresponding
# rule in .gitattributes (e.g. to enforce consistent text handling).
#
# Usage:
# ./scripts/linux/utils/attributes.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

# Load dependent scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/utils.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root
check_command git
check_file .gitattributes

# --------------------------
# Verification
# --------------------------

missing_attributes=$(git ls-files | git check-attr -a --stdin | grep 'text: auto' || printf '\n')

if [ -n "$missing_attributes" ]; then
  printf '%s\n%s\n' '.gitattributes rule missing for the following files:' "$missing_attributes"
else
  printf '%s\n' 'All files have a corresponding rule in .gitattributes'
fi
