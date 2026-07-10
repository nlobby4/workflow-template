#!/usr/bin/env bash

# --------------------------------------------------
# Git attributes verification script.
#
# This script checks whether tracked files have a corresponding
# rule in .gitattributes (e.g. to enforce consistent text handling)
# and detects overlapping rules.
#
# Usage:
# ./scripts/linux/utils/attributes.sh
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
. "$SCRIPT_DIR/functions.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_project_root
check_command git
check_file .gitattributes

# --------------------------
# Verification
# --------------------------

missing_attributes=()
while IFS= read -r -d '' path \
  && IFS= read -r -d '' attribute \
  && IFS= read -r -d '' value; do
  if [[ "$attribute" == "text" && "$value" == "auto" ]]; then
    missing_attributes+=("$path")
  fi
done < <(git ls-files -z | git check-attr -z --stdin -a)

if [[ "${#missing_attributes[@]}" -gt 0 ]]; then
  printf '%s %s\n' "$WARN" '.gitattributes rule missing for the following files:'
  printf '%s\n' "${missing_attributes[@]}"
else
  printf '%s %s\n' "$OK" 'All files have a corresponding rule in .gitattributes'
fi

# --------------------------
# Overlap detection
# --------------------------

# Rewrites each .gitattributes pattern with a unique marker attribute
# (ov_rule_N=set) and supplies it to git as an *additional* attributes
# file via -c core.attributesFile, leaving the real .gitattributes
# untouched. For every tracked file, `git check-attr --all` then
# reveals exactly which marker(s) fired, i.e. which original patterns
# matched that file. Broad rules are allowed to overlap with more specific
# rules; only multiple equally most-specific matches are reported.

pattern_specificity() {
  local pattern="${1:-}"
  local literal="$pattern"
  local without_slashes="$pattern"

  literal="${literal//\*/}"
  literal="${literal//\?/}"
  literal="${literal//\[/}"
  literal="${literal//\]/}"

  without_slashes="${without_slashes//\//}"

  # Prefer path-specific rules, then rules with more literal characters.
  printf '%d\n' "$(((${#pattern} - ${#without_slashes}) * 1000 + ${#literal}))"
}

tmp_rules="$(mktemp)"
trap 'rm -f "$tmp_rules"' EXIT

line_no=0
patterns=()
declare -A pattern_by_line=()
declare -A pattern_score_by_line=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line_no=$((line_no + 1))
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue
  [[ "$line" =~ ^[[:space:]]*# ]] && continue

  pattern="${line%%[[:space:]]*}"

  patterns+=("$line_no:$pattern")
  pattern_by_line["$line_no"]="$pattern"
  pattern_score_by_line["$line_no"]="$(pattern_specificity "$pattern")"
  printf '%s ov_rule_%d=set\n' "$pattern" "$line_no" >> "$tmp_rules"
done < .gitattributes

if [[ "${#patterns[@]}" -eq 0 ]]; then
  printf '%s %s\n' "$INFO" 'No non-default patterns found in .gitattributes.'
else
  status=0
  declare -A file_rules=()
  while IFS= read -r -d '' path \
    && IFS= read -r -d '' attribute \
    && IFS= read -r -d '' value; do
    [[ "$value" == "set" ]] || continue
    [[ "$attribute" == ov_rule_* ]] || continue
    file_rules["$path"]+="${attribute#ov_rule_} "
  done < <(git ls-files -z \
    ':!.gitattributes' \
    | git -c core.attributesFile="$tmp_rules" check-attr -z --all --stdin)

  found_overlap=0
  for path in "${!file_rules[@]}"; do
    rule_list=()
    read -ra rule_list <<< "${file_rules[$path]}"
    if [[ "${#rule_list[@]}" -gt 1 ]]; then
      max_score=-1
      max_rules=()
      for rule_number in "${rule_list[@]}"; do
        rule_score="${pattern_score_by_line[$rule_number]}"
        if [[ "$rule_score" -gt "$max_score" ]]; then
          max_score="$rule_score"
          max_rules=("$rule_number")
        elif [[ "$rule_score" -eq "$max_score" ]]; then
          max_rules+=("$rule_number")
        fi
      done

      # Matching a broad rule and a more specific rule is intentional. Only
      # report when multiple most-specific rules still compete for the file.
      [[ "${#max_rules[@]}" -gt 1 ]] || continue

      found_overlap=1
      status=1
      desc=""
      for rule_number in "${max_rules[@]}"; do
        desc+="line $rule_number ('${pattern_by_line[$rule_number]}') "
      done
      printf '%s %s -> matched by %s\n' "$WARN" "$path" "$desc"
    fi
  done

  if [[ "$found_overlap" -eq 0 ]]; then
    printf '%s %s\n' "$OK" 'No overlapping .gitattributes rules detected.'
  fi

  exit "$status"
fi
