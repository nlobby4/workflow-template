#!/bin/bash

# --------------------------------------------------
# Environment setup script for the repository.
#
# This script configures git and necessary tools,
# making the environment match the repository's expected setup.
#
# This script is used by the development container,
# however it can also be run manually in a local environment if desired.
# Please note that the script does not automatically install required tools:
#
# chmod +x scripts/linux/setup.sh
# ./scripts/linux/setup.sh
# --------------------------------------------------

echo "Setting up repository environment..."

# --------------------------
# Setup
# --------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# Load dependent scripts
. "$(dirname "$0")/utils/variables.sh"
. "$(dirname "$0")/utils/check.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root
check_command git
# TODO: Enable git lfs if needed
# check_command git-lfs

# Require either asdf or nvm
# If both asdf and nvm are present, asdf takes precedence.
uses_asdf=false
uses_nvm=false

manager=$(check_node_version_manager)
if [ "$manager" = "asdf" ]; then
  uses_asdf=true
elif [ "$manager" = "nvm" ]; then
  uses_nvm=true
fi

# Warn if the expected version file is missing for the active manager.
if $uses_asdf; then
  [ -f .tool-versions ] || echo "$WARN .tool-versions file is missing." >&2
elif $uses_nvm; then
  [ -f .nvmrc ] || echo "$WARN .nvmrc file is missing." >&2
fi

# --------------------------
# Configuration
# --------------------------

# Configure git blame to ignore specific revisions
git config blame.ignoreRevsFile .git-blame-ignore-revs
echo "$OK Configured blame.ignoreRevsFile"

# Configure commit message template
git config commit.template .gitmessage
echo "$OK Configured commit.template"

# Install Git LFS (Large File Storage)
# TODO: Enable git lfs if needed
# git lfs install
# echo "$OK Installed Git LFS"

# Set node version using asdf or nvm
if $uses_asdf; then
  asdf install
  asdf reshim
  echo "$OK Installed node versions with asdf"
elif $uses_nvm; then
  nvm install
  echo "$OK Installed node version with nvm"
fi

# --------------------------
# Verification
# --------------------------

check_command node
check_command npm

# Print the versions being used
echo "Uses node version: $(node -v)"
echo "Uses npm version: $(npm -v)"

# --------------------------
# Dependencies
# --------------------------

# Install Node.js dependencies
if [ -f package-lock.json ]; then
  echo "Installing Node.js dependencies with npm ci..."
  npm ci --loglevel=error
  echo "$OK Node.js dependencies installed"
elif [ -f package.json ]; then
  echo "Installing Node.js dependencies with npm install..."
  npm install --loglevel=error
  echo "$OK Node.js dependencies installed"
fi

echo "Environment setup complete! Repository is ready to use."
