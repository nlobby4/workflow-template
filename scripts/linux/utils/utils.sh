# This file is sourced, not executed

# --------------------------------------------------
# Utility functions for the repository scripts.
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
[ -n "${_UTIL_LOADED:-}" ] && return
_UTIL_LOADED=1

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

# Check if a file exists
check_file() {
  if [ ! -f "$1" ]; then
    echo "$ERROR file not found: $1" >&2
    exit 1
  fi
}

# Check if an array or value is not empty
check_not_empty() {
  if [ -z "${1:-}" ]; then
    echo "$ERROR $2" >&2
    exit 1
  fi
}

# Read a field from package.json and write it to stdout
json_field() {
  node -e "
    const p = JSON.parse(require('fs').readFileSync('$1', 'utf8'));
    const v = '$2'.split('.').reduce((o, k) => o?.[k], p);
    if (v === undefined) process.exit(1);
    process.stdout.write(String(v));
  " 2> /dev/null
}
