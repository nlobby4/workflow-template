#!/usr/bin/env bash

# --------------------------------------------------
# Package script wrapper for md.sh.
#
# Usage:
# scripts/linux/commands/validation/lint/md.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

markdownlint-cli2
