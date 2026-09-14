#!/usr/bin/env bash

# --------------------------------------------------
# Smoke test for the built package.
#
# Verifies that the ESM and/or CJS builds are importable and export at least
# one symbol after a production build.
#
# Usage:
#
# pnpm run build && bash scripts/linux/commands/tests/smoke.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

# Load dependent scripts
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../utils/validation.sh"

log_info "Running smoke test..."

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command node

if [ ! -d "dist" ]; then
  log_warning "No dist directory found, skipping smoke test"
  exit 0
fi

has_esm="false"
has_cjs="false"

if [ -f "dist/index.mjs" ]; then
  has_esm="true"
fi

if [ -f "dist/index.cjs" ]; then
  has_cjs="true"
fi

if [ "$has_esm" != "true" ] && [ "$has_cjs" != "true" ]; then
  log_error "No dist/index.mjs or dist/index.cjs found"
  exit 1
fi

# --------------------------
# Smoke tests
# --------------------------

if [ "$has_esm" = "true" ]; then
  node --input-type=module << 'EOF'
import * as esm from "./dist/index.mjs";
const keys = Object.keys(esm);
if (keys.length === 0) {
  console.error("ESM: no exports found");
  process.exit(1);
}
console.log("ESM OK:", keys);
EOF
else
  log_info "dist/index.mjs not found, skipping ESM smoke test"
fi

if [ "$has_cjs" = "true" ]; then
  node --eval "
const cjs = require('./dist/index.cjs');
const keys = Object.keys(cjs);
if (keys.length === 0) {
  console.error('CJS: no exports found');
  process.exit(1);
}
console.log('CJS OK:', keys);
"
else
  log_info "dist/index.cjs not found, skipping CJS smoke test"
fi

log_ok "Smoke test passed"
