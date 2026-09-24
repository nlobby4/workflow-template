#!/usr/bin/env bash

# --------------------------------------------------
# Package script wrapper for check.sh.
#
# Usage:
# scripts/linux/commands/validation/format/check.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

prettier . --check --cache --cache-location .cache/general/prettier/.prettiercache --cache-strategy content
