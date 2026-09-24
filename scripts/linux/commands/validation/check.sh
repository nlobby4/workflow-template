#!/usr/bin/env bash

# --------------------------------------------------
# Package script wrapper for repository validation.
#
# Runs root validation scripts directly. Project-specific build systems belong
# under project/ and are invoked through project gates.
#
# Usage:
# scripts/linux/commands/validation/check.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

pnpm run format:check -- "$@"
pnpm run lint -- "$@"
pnpm run test -- "$@"
pnpm run deps:unused -- "$@"
pnpm run audit -- "$@"
