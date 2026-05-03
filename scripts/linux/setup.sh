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
. "$SCRIPT_DIR/utils/check.sh"

echo "$INFO Setting up repository environment..."

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root
check_command git

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
# TODO: Uncomment if Git LFS is needed
# git lfs install
# echo "$OK Installed Git LFS"

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

# TODO: Install further dependencies as needed (e.g. Python, Ruby, Go, etc.)

echo "Environment setup complete! Repository is ready to use."
