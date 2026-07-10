#!/usr/bin/env bash

# --------------------------------------------------
# Dictionary dead word checker.
#
# Checks dictionary.txt against project files
# and reports words with no matches in the codebase as "dead words".
# Also detects duplicate dictionary entries.
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

SCRIPT_FILE="${BASH_SOURCE[0]}"
SCRIPT_PARENT="$(dirname "$SCRIPT_FILE")"
SCRIPT_DIR="$(cd "$SCRIPT_PARENT" && pwd)"
. "$SCRIPT_DIR/functions.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root
check_command git
check_command grep
check_command xargs

DICTIONARY="dictionary.txt"
readonly DICTIONARY
check_file "$DICTIONARY"

# --------------------------
# Parse dictionary
# --------------------------

dictionary_words=()
unique_words=()
duplicate_words=()
duplicate_lines=()
duplicate_first_lines=()
declare -A seen_words=()
declare -A first_seen_lines=()

line_no=0

while IFS= read -r line || [[ -n "$line" ]]; do
  line_no=$((line_no + 1))

  line="${line%$'\r'}"
  word="${line#"${line%%[![:space:]]*}"}"
  word="${word%"${word##*[![:space:]]}"}"

  [[ -z "$word" || "$word" == \#* ]] && continue

  dictionary_words+=("$word")

  if [[ -n "${seen_words[$word]:-}" ]]; then
    duplicate_words+=("$word")
    duplicate_lines+=("$line_no")
    first_line="${first_seen_lines[$word]}"
    duplicate_first_lines+=("$first_line")
  else
    seen_words["$word"]="$line_no"
    first_seen_lines["$word"]="$line_no"
    unique_words+=("$word")
  fi
done < "$DICTIONARY"

if [[ "${#dictionary_words[@]}" -eq 0 ]]; then
  log_ok "$DICTIONARY has no active entries"
  exit 0
fi

# --------------------------
# Collect project files
# --------------------------

PROJECT_FILES="$(mktemp)"
trap 'rm -f "$PROJECT_FILES"' EXIT

while IFS= read -r -d '' path \
  && IFS= read -r -d '' attribute \
  && IFS= read -r -d '' value; do
  if [[ "$attribute" == "binary" && "$value" != "set" ]]; then
    printf '%s\0' "$path" >> "$PROJECT_FILES"
  fi
done < <(
  git ls-files \
    --cached \
    --others \
    --exclude-standard \
    -z \
    -- \
    ":!$DICTIONARY" \
    ':!package-lock.json' \
    ':!docs/**' \
    | git check-attr -z --stdin binary
)

if [[ ! -s "$PROJECT_FILES" ]]; then
  log_error "no project files found"
  exit 1
fi

# --------------------------
# Check each word
# --------------------------

dead_words=()
dead_lines=()
checked_words=0
for word in "${unique_words[@]}"; do
  checked_words=$((checked_words + 1))

  if ! xargs -0 -r grep -qlFi \
    -- "$word" \
    < "$PROJECT_FILES" \
    2> /dev/null; then
    dead_words+=("$word")
    dead_lines+=("${first_seen_lines[$word]}")
  fi
done

# --------------------------
# Report
# --------------------------

status=0

for i in "${!duplicate_words[@]}"; do
  word="${duplicate_words[$i]}"
  line_no="${duplicate_lines[$i]}"
  first_line="${duplicate_first_lines[$i]}"

  log_warning \
    "$word -> duplicate entry in $DICTIONARY" \
    "(line $line_no," \
    "first seen on line $first_line)"
  status=1
done

for i in "${!dead_words[@]}"; do
  word="${dead_words[$i]}"
  line_no="${dead_lines[$i]}"

  log_warning \
    "$word -> not found in project files" \
    "(line $line_no)"
  status=1
done

if [[ "$status" -eq 0 ]]; then
  entry_label="$(
    plural_label \
      "$checked_words" \
      "dictionary entry" \
      "dictionary entries"
  )"

  log_ok \
    "All $checked_words active $entry_label" \
    "in $DICTIONARY are used and unique"
else
  dead_count="${#dead_words[@]}"
  duplicate_count="${#duplicate_words[@]}"
  dead_label="$(
    plural_label \
      "$dead_count" \
      "dead word" \
      "dead words"
  )"
  duplicate_label="$(
    plural_label \
      "$duplicate_count" \
      "duplicate entry" \
      "duplicate entries"
  )"

  log_info \
    "$dead_count $dead_label," \
    "$duplicate_count $duplicate_label" \
    "found in $DICTIONARY"
fi

exit "$status"
