#!/usr/bin/env bash

# --------------------------------------------------
# Script to package the project for distribution.
#
# This script is used by semantic release to create
# a tar.gz archive, which gets uploaded as part of
# the release assets on GitHub.
#
# Packaging is optional, if no dist directory is found
# after the build step, the script exits gracefully and
# no archive is created.
#
# If the package is public (private is not set to true in package.json),
# @semantic-release/npm runs the prepare script (which triggers the build)
# before this script is called, so the build is skipped here.
# If the package is private, the build is run here if defined.
#
# You can run this script manually to verify the packaging process,
# but ensure the project has been built first:
#
# npm run build && ./scripts/linux/package/release.sh <version>
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

# Load dependent scripts
. "$(dirname "${BASH_SOURCE[0]}")/../utils/variables.sh"
. "$(dirname "${BASH_SOURCE[0]}")/../utils/utils.sh"

# Get the release version from the first argument
version="${1:-}"

echo "Packaging project for distribution..."

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root
check_argument "$version" "release version"
check_command mktemp
check_command tar
check_command node
check_command npm

# --------------------------
# Package
# --------------------------

# If the package is public, @semantic-release/npm runs the prepare script
# (which triggers the build) before this script is called. If the package
# is private, npm publishing is skipped and the build is run here if defined.
is_private="$(json_field package.json private || echo "false")"

if [ "$is_private" = "true" ]; then
  build_script="$(json_field package.json scripts.build || echo "")"
  if [ -n "$build_script" ]; then
    echo "Running build..."
    npm run build
  fi
fi

# Require dist folder to exist, skip gracefully if not present
if [ ! -d "dist" ]; then
  echo "$WARN No dist directory found, skipping packaging"
  exit 0
fi

# Use the package name (sanitized) as the archive base name
package_name="$(json_field package.json name || echo "")"
archive_base_name="${package_name:-project}"
archive_base_name="${archive_base_name#@}"
archive_base_name="${archive_base_name//\//-}"
archive_base_name="$(printf '%s' "$archive_base_name" | tr -cs 'A-Za-z0-9._-' '-')"
archive_base_name="${archive_base_name%-}"

# Falls back to "project" if the package name is empty
if [ -z "$archive_base_name" ]; then
  archive_base_name="project"
fi

# Create a temporary directory for the archive and clean up on exit
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT
tmp_archive="$tmp_dir/${archive_base_name}-v${version}.tar.gz"

# Create release archive from dist
echo "Archiving dist directory..."
tar -czf "$tmp_archive" -C dist .

# Move archive to project root
archive_path="${archive_base_name}-v${version}.tar.gz"
mv "$tmp_archive" "$archive_path"

echo "$OK Created $archive_path"
