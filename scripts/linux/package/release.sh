#!/bin/bash

# --------------------------------------------------
# Script to package the project for distribution.
#
# This script is used by semantic release to create
# a tar.gz archive, which gets uploaded as part of
# the release assets on GitHub.
#
# You can run this script manually to verify the packaging process:
#
# chmod +x scripts/linux/package/release.sh
# ./scripts/linux/package/release.sh <version>
# --------------------------------------------------

echo "Packaging project for distribution..."

# --------------------------
# Setup
# --------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# Load helper functions
. "$(dirname "${BASH_SOURCE[0]}")/../utils/variables.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../utils/check.sh"

# Get the release version from the first argument
version="${1:-}"

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root
check_argument "$version" "release version"
check_command tar

# --------------------------
# Package
# --------------------------

# Prepare the release directory and archive path
mkdir -p release
archive_path="release/project-dist-v${version}.tar.gz"

# Remove any existing archive for this version
rm -f "$archive_path"

# TODO: This template does not include a build step. The entire project is
# archived as-is. If your project requires a build (e.g. compiling TypeScript,
# bundling assets), replace this section with your build command and point the
# tar command at the build output directory instead.
#
# Example for a project with a build step:
#   check_command npm
#   npm run build:prod
#   if [ ! -d dist ]; then
#     echo "$ERROR dist directory was not generated" >&2
#     exit 1
#   fi
#   tar -czf "$archive_path" -C dist .

# Create a tar.gz archive of the entire project.
tar --exclude='release' -czf "$archive_path" .

if [ ! -f "$archive_path" ]; then
  echo "$ERROR archive was not created at $archive_path" >&2
  exit 1
fi

# Print the result
echo "$OK Created $archive_path"
