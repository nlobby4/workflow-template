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

if [ -t 2 ]; then
  OK="✓ Success:"
  ERROR="✗ Error:"
  WARN="⚠ Warning:"
  INFO="i Info:"
else
  OK="[OK]:"
  ERROR="[ERROR]:"
  WARN="[WARN]:"
  INFO="[INFO]:"
fi

# Export variables to survive sub-shells
export OK ERROR WARN INFO
