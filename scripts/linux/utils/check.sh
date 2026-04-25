# This file is sourced, not executed

# --------------------------------------------------
# Check functions for the repository scripts.
#
# This script is sourced by other scripts to provide check functions.
#
# This script is not meant to be run directly,
# scripts relying on these functions source this as needed.
# --------------------------------------------------

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This file is meant to be sourced, not executed directly." >&2
  exit 1
fi

# Guard against multiple sourcing
[ -n "${_CHECK_LOADED:-}" ] && return
_CHECK_LOADED=1

# Load dependent scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/variables.sh"

# --------------------------
# Functions
# --------------------------

# Check if a command is available in PATH
check_command() {
  if ! command -v "$1" > /dev/null 2>&1; then
    echo "$ERROR $1 is required but was not found in PATH" >&2
    exit 1
  fi
}

# Check if a required argument is provided
check_argument() {
  if [ -z "${1:-}" ]; then
    echo "$ERROR $2 argument is required but was not provided" >&2
    exit 1
  fi
}

# Check if the script is run from the project root
check_project_root() {
  if [ ! -f package.json ]; then
    echo "$ERROR run this script from repository root" >&2
    exit 1
  fi
}

# Check which supported version manager is available
check_node_version_manager() {
  if command -v asdf > /dev/null 2>&1; then
    if ! asdf plugin list 2> /dev/null | grep -qx 'nodejs'; then
      echo "$ERROR asdf is configured but the nodejs plugin was not found" >&2
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

# TODO: Add checks for other version managers as needed (e.g. pyenv, rbenv, etc.)
