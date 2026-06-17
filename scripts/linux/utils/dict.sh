#!/usr/bin/env bash

# --------------------------------------------------
# Dictionary dead word checker.
#
# Checks every word in dictionary.txt against the project
# files (respecting .gitignore) and reports words that have
# no matches anywhere in the codebase.
#
# Dead words accumulate over renames, refactors, and deletions.
# Running this periodically keeps the dictionary clean.
#
# Usage:
# ./scripts/linux/utils/dict.sh
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
. "$SCRIPT_DIR/variables.sh"
. "$SCRIPT_DIR/utils.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root
check_command git

DICTIONARY="dictionary.txt"
check_file "$DICTIONARY"

# --------------------------
# Collect project files
# --------------------------

# Use git to collect all tracked and untracked files, respecting .gitignore
mapfile -t PROJECT_FILES < <(
  git ls-files --cached --others --exclude-standard \
    -- \
    ':!dictionary.txt' \
    ':!package-lock.json' \
    ':!docs/**' \
    | git check-attr --stdin binary \
    | awk -F': binary: ' '$2 != "set" { print $1 }' \
      2> /dev/null
)

if [ "${#PROJECT_FILES[@]}" -eq 0 ]; then
  echo "$ERROR no project files found" >&2
  exit 1
fi

# --------------------------
# Check each word
# --------------------------

dead_words=()
checked=0

while IFS= read -r line; do
  # Skip blank lines and comment lines starting with #
  [[ -z "$line" || "$line" == \#* ]] && {
    continue
  }

  word="$line"
  checked=$((checked + 1))

  # grep -r across collected files, case-insensitive, word-boundary match
  # -l stops at first match per file (fast), -F treats word as literal string
  # Redirect stdout to /dev/null, we only care about the exit code
  if ! grep -qlFi -- "$word" "${PROJECT_FILES[@]}" 2> /dev/null; then
    dead_words+=("$word")
  fi

done < "$DICTIONARY"

# --------------------------
# Report
# --------------------------

echo ""
echo "Checked $checked words across ${#PROJECT_FILES[@]} files"
echo ""

if [ "${#dead_words[@]}" -eq 0 ]; then
  echo "$OK All words in $DICTIONARY are used in the project"
  exit 0
fi

echo "$WARN ${#dead_words[@]} dead word(s) found in $DICTIONARY:"
echo ""

for word in "${dead_words[@]}"; do
  echo "  - $word"
done

echo ""
echo "Remove dead words from $DICTIONARY or verify spellings."
exit 1
