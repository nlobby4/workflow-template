#!/usr/bin/env bash

# --------------------------------------------------
# Environment setup script for the repository.
#
# This script configures git and necessary tools,
# making the environment match the repository's expected setup.
#
# This script is used by the development container,
# however it can also be run manually in a local environment if desired.
# Please note that the script does not automatically install required tools.
#
# Usage:
# ./scripts/linux/setup.sh
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
UTILS_DIR="$SCRIPT_DIR/utils"
. "$UTILS_DIR/functions.sh"

log_info "Setting up repository environment..."

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root
check_command git

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

# Check if git LFS is initialized, if not, initialize it
check_command git-lfs
if ! check_git_lfs; then
  log_info "Initializing git LFS..."
  git lfs install --local
  log_ok "Git LFS initialized"
fi

# --------------------------
# Tools
# --------------------------

# Install tool versions via asdf if running locally
# In a devcontainer, asdf install is handled by the Dockerfile
if [[ -z "${REMOTE_CONTAINERS:-}" ]] && [[ -z "${CODESPACES:-}" ]]; then
  if [[ ! -f .tool-versions ]]; then
    log_warning "No .tool-versions file found"
  elif ! command -v asdf > /dev/null 2>&1; then
    log_warning "asdf not found, tool versions must be installed manually"
  else
    log_info "Installing tool versions via asdf..."
    asdf install
    log_ok "Tool versions installed"
  fi
fi

# --------------------------
# Verification
# --------------------------

check_command node
check_command npm
check_command shellcheck
# TODO: Check for further tools

# Print the versions being used
log_info "Uses node version: $(node -v)"
log_info "Uses npm version: $(npm -v)"
log_info "Uses ShellCheck version: $(shellcheck --version | awk '/^version:/ { print $2 }')"
# TODO: Print versions of further tools

# --------------------------
# Dependencies
# --------------------------

# Install Node.js dependencies
if [[ -f package-lock.json ]]; then
  log_info "Installing Node.js dependencies with npm ci..."
  npm ci --silent
  log_ok "Node.js dependencies installed"
elif [[ -f package.json ]]; then
  log_info "Installing Node.js dependencies with npm install..."
  npm install --silent
  log_ok "Node.js dependencies installed"
fi

# TODO: Install further dependencies as needed

log_ok "Environment setup complete!"
