# This file is sourced, not executed

# --------------------------------------------------
# Shared variables for shell scripts in this repository.
# --------------------------------------------------

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This file is meant to be sourced, not executed directly." >&2
  exit 1
fi

# Guard against multiple sourcing
[ -n "${_VARIABLES_LOADED:-}" ] && return
_VARIABLES_LOADED=1

# --------------------------
# Variables
# --------------------------

if { [ -t 1 ] && [ -t 2 ]; } || [ -n "${GITHUB_ACTIONS:-}" ]; then
  COLOR_GREEN=$'\033[0;32m'
  COLOR_RED=$'\033[0;31m'
  COLOR_YELLOW=$'\033[0;33m'
  COLOR_CYAN=$'\033[0;36m'
  COLOR_RESET=$'\033[0m'

  OK="${COLOR_GREEN}✓ Success:${COLOR_RESET}"
  ERROR="${COLOR_RED}✗ Error:${COLOR_RESET}"
  WARN="${COLOR_YELLOW}⚠ Warning:${COLOR_RESET}"
  INFO="${COLOR_CYAN}i Info:${COLOR_RESET}"
else
  OK="[OK]:"
  ERROR="[ERROR]:"
  WARN="[WARN]:"
  INFO="[INFO]:"
fi

# Export variables to survive sub-shells
export OK ERROR WARN INFO
