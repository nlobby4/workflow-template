#!/usr/bin/env bash

# --------------------------------------------------
# Environment setup script for the repository.
#
# This script configures git and necessary tools,
# making the environment match the repository's expected setup.
#
# The recommended entry point is the mise task, which installs locked
# dependencies before running this script:
#
# mise run setup
#
# To bypass mise task orchestration, install the tools from mise.toml and the
# pnpm dependencies first, then run this script directly:
#
# mise install --locked
# pnpm install --frozen-lockfile
# bash scripts/linux/commands/repository/setup.sh
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
. "$SCRIPT_DIR/../../utils/logging/formatting.sh"

log_info "Setting up repository environment..."

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command git
check_file "$SCRIPT_DIR/repair.sh"

# --------------------------
# Configuration
# --------------------------

# Configure git blame to ignore specific revisions
check_file .git-blame-ignore-revs
git config blame.ignoreRevsFile .git-blame-ignore-revs
log_ok "Configured blame.ignoreRevsFile"

# Configure commit message template
check_file .gitmessage
git config commit.template .gitmessage
log_ok "Configured commit.template"

# Repair repository-local configuration
bash "$SCRIPT_DIR/repair.sh"

# --------------------------
# Tools
# --------------------------

# Ensure the locked repository toolchain is present. Dev Container images
# preinstall it, so this is normally a fast no-op during container creation.
if [[ ! -f mise.toml ]]; then
  log_warning "No mise.toml file found"
elif ! command -v mise > /dev/null 2>&1; then
  log_warning "mise not found; tool versions must be installed manually"
else
  log_info "Installing locked tool versions via mise..."
  mise install --locked
  log_ok "Tool versions installed"
fi

# --------------------------
# Verification
# --------------------------

check_command node
check_command pnpm
check_command actionlint
check_command act
check_command cmark-gfm
check_command shellcheck
check_command trivy
check_command cosign
check_command gitleaks
check_command hadolint
check_command conftest

# Print the versions being used
log_info "Uses node version: $(node -v)"
log_info "Uses pnpm version: $(pnpm --version)"
log_info "Uses actionlint version: $(actionlint -version)"
log_info "Uses act version: $(act --version | awk '{ print $3 }')"
log_info "Uses cmark-gfm version: $(cmark-gfm --version | head -n 1)"
log_info "Uses Git LFS version: $(git lfs version | awk '{ print $1 }')"
log_info "Uses ShellCheck version: $(shellcheck --version | awk '/^version:/ { print $2 }')"
log_info "Uses Trivy version: $(trivy --version | awk '/^Version:/ { print $2 }')"
log_info "Uses Cosign version: $(cosign version --json | jq -r .gitVersion)"
log_info "Uses Gitleaks version: $(gitleaks version)"
log_info "Uses Hadolint version: $(hadolint --version | awk '{ print $NF }')"
log_info "Uses Conftest version: $(conftest --version | awk '/^Conftest:/ { print $2 }')"

log_ok "Environment setup complete!"
