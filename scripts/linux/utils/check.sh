#!/bin/bash

# --------------------------------------------------
# Check functions for the repository scripts.
#
# This script is sourced by other scripts to provide check functions.
#
# This script is not meant to be run directly,
# scripts relying on these functions source this as needed.
# --------------------------------------------------

# Check if a command is available in PATH
check_command() {
  if ! command -v "$1" > /dev/null 2>&1; then
    echo "$ERROR $1 is required but was not found in PATH" >&2
    exit 1
  fi
}

# Check if a required argument is provided
check_argument() {
  if [ -z "$1" ]; then
    echo "$ERROR $2 argument is required but was not provided" >&2
    exit 1
  fi
}

# Check if the project is run from project root
check_project_root() {
  if [ ! -f package.json ]; then
    echo "$ERROR run this script from repository root" >&2
    exit 1
  fi
}

# Check which of the supported node version managers is available
check_node_version_manager() {
  if command -v asdf > /dev/null 2>&1; then
    # Check for the nodejs plugin
    if ! asdf plugin list | grep -qx 'nodejs'; then
      echo "$ERROR asdf is configured but nodejs plugin is not found" >&2
      exit 1
    fi
    echo "asdf"
  elif command -v nvm > /dev/null 2>&1; then
    echo "nvm"
  else
    echo "$ERROR asdf or nvm is required but not found in PATH" >&2
    exit 1
  fi
}
