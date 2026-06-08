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
. "$SCRIPT_DIR/utils/variables.sh"
. "$SCRIPT_DIR/utils/utils.sh"

echo "$INFO Setting up repository environment..."

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root

# --------------------------
# Configuration
# --------------------------

# Check if git is initialized, if not, initialize it
if ! check_git; then
  echo "$INFO Initializing git repository..."
  git init
  echo "$OK Git repository initialized"
fi

# Configure git blame to ignore specific revisions
check_file .git-blame-ignore-revs
git config blame.ignoreRevsFile .git-blame-ignore-revs
echo "$OK Configured blame.ignoreRevsFile"

# Configure commit message template
check_file .gitmessage
git config commit.template .gitmessage
echo "$OK Configured commit.template"

# --------------------------
# Tools
# --------------------------

# Install tool versions via asdf if running locally
# In a devcontainer, asdf install is handled by the Dockerfile
if [ -z "${REMOTE_CONTAINERS:-}" ] && [ -z "${CODESPACES:-}" ]; then
  if [ ! -f .tool-versions ]; then
    echo "$WARN No .tool-versions file found"
  elif ! command -v asdf &> /dev/null; then
    echo "$WARN asdf not found, tool versions must be installed manually"
  else
    echo "$INFO Installing tool versions via asdf..."
    asdf install
    echo "$OK Tool versions installed"
  fi
fi

# --------------------------
# Verification
# --------------------------

check_command node
check_command npm
# TODO: Check for further tools

# Print the versions being used
echo "$INFO Uses node version: $(node -v)"
echo "$INFO Uses npm version: $(npm -v)"
# TODO: Print versions of further tools

# --------------------------
# Dependencies
# --------------------------

# Install Node.js dependencies
if [ -f package-lock.json ]; then
  echo "$INFO Installing Node.js dependencies with npm ci..."
  npm ci --silent
  echo "$OK Node.js dependencies installed"
elif [ -f package.json ]; then
  echo "$INFO Installing Node.js dependencies with npm install..."
  npm install --silent
  echo "$OK Node.js dependencies installed"
fi

# TODO: Install further dependencies as needed

echo "$OK Environment setup complete!"
