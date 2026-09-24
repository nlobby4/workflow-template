#!/usr/bin/env bash

# --------------------------------------------------
# Formatting helpers for repository scripts.
#
# This script is not meant to be run directly,
# scripts relying on these helpers source this as needed.
# --------------------------------------------------

# Guard against direct execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "This file is meant to be sourced, not executed directly" >&2
  exit 1
fi

# Guard against multiple sourcing
[[ -n "${_FORMATTING_LOADED:-}" ]] && return
_FORMATTING_LOADED=1

# --------------------------
# Setup
# --------------------------

# Load dependent scripts
FORMATTING_UTILS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$FORMATTING_UTILS_DIR/../validation.sh"
_VISIBLE_WIDTH_SCRIPT="scripts/node/bin/visible-width.js"
_WRAP_LINES_SCRIPT="scripts/node/bin/wrap-lines.js"
readonly _VISIBLE_WIDTH_SCRIPT _WRAP_LINES_SCRIPT

# --------------------------
# Formatting
# --------------------------

status_labels=()
status_values=()

reset_status() {
  status_labels=()
  status_values=()
}

add_status() {
  local label="${1:-}"
  local value="${2:-}"

  status_labels+=("$label")
  status_values+=("$value")
}

print_status() {
  local max_label_width=0
  local label label_width
  local index

  for label in "${status_labels[@]}"; do
    label_width="${#label}"
    if [[ "$label_width" -gt "$max_label_width" ]]; then
      max_label_width="$label_width"
    fi
  done

  for index in "${!status_labels[@]}"; do
    printf '%-*s: %s\n' \
      "$max_label_width" \
      "${status_labels[$index]}" \
      "${status_values[$index]}"
  done
}

# Strip ANSI escape sequences from input text
strip_ansi() {
  local value="${1:-}"
  local bel=$'\a'
  local osc_start=$'\033]'
  local osc_st=$'\033\\'
  local csi_pattern=$'\033\\[[0-9;?]*[ -/]*[@-~]'
  local before rest after
  local bel_prefix st_prefix
  local bel_index st_index

  while [[ "$value" == *"$osc_start"* ]]; do
    before="${value%%"$osc_start"*}"
    rest="${value#*"$osc_start"}"
    bel_index=-1
    st_index=-1

    if [[ "$rest" == *"$bel"* ]]; then
      bel_prefix="${rest%%"$bel"*}"
      bel_index="${#bel_prefix}"
    fi

    if [[ "$rest" == *"$osc_st"* ]]; then
      st_prefix="${rest%%"$osc_st"*}"
      st_index="${#st_prefix}"
    fi

    if [[ "$bel_index" -lt 0 && "$st_index" -lt 0 ]]; then
      break
    fi

    if [[ "$st_index" -ge 0 ]] \
      && [[ "$bel_index" -lt 0 || "$st_index" -lt "$bel_index" ]]; then
      after="${rest#*"$osc_st"}"
    else
      after="${rest#*"$bel"}"
    fi

    value="${before}${after}"
  done

  while [[ "$value" =~ $csi_pattern ]]; do
    value="${value/${BASH_REMATCH[0]}/}"
  done

  printf '%s' "$value"
}

# Return one visible width per input after ANSI escape sequences are removed
visible_width() {
  local value
  local width_output
  local stripped_values=()

  for value in "$@"; do
    stripped_values+=("$(strip_ansi "$value")")
  done

  if [[ "${#stripped_values[@]}" -gt 0 ]] \
    && command -v node > /dev/null 2>&1 \
    && [[ -f "$_VISIBLE_WIDTH_SCRIPT" ]]; then
    if width_output="$(node "$_VISIBLE_WIDTH_SCRIPT" "${stripped_values[@]}" 2> /dev/null)"; then
      printf '%s\n' "$width_output"
      return
    fi
  fi

  for value in "${stripped_values[@]}"; do
    printf '%d\n' "${#value}"
  done
}

# Wrap lines to a target visible width when the Node helper is available
wrap_lines() {
  local width="${1:-}"
  local mode="${2:-}"
  local wrap_args=()

  if [[ "$width" =~ ^[0-9]+$ ]] \
    && [[ "$width" -gt 0 ]] \
    && command -v node > /dev/null 2>&1 \
    && [[ -f "$_WRAP_LINES_SCRIPT" ]]; then
    wrap_args=("$width")
    if [[ "$mode" == "hanging-status" ]]; then
      wrap_args+=("--hanging-status")
    fi

    node "$_WRAP_LINES_SCRIPT" "${wrap_args[@]}"
  else
    cat
  fi
}

# Return singular or plural label based on count
plural_label() {
  local count="${1:-0}"
  local singular="${2:-entry}"
  local plural="${3:-${singular}s}"

  if [[ "$singular" == *y ]]; then
    plural="${3:-${singular%y}ies}"
  fi

  if [[ "$count" -eq 1 ]]; then
    printf '%s' "$singular"
  else
    printf '%s' "$plural"
  fi
}

# Create a separator line based on terminal width
separator() {
  local width line rule
  width="$(tput cols 2> /dev/null || echo 60)"

  if [[ ! "$width" =~ ^[0-9]+$ ]] || [[ "$width" -lt 1 ]]; then
    width=60
  fi

  if [[ -z "${ASCII_ONLY:-}" ]]; then
    rule="─"
  else
    rule="-"
  fi

  printf -v line '%*s' "$width" ''
  printf '%s\n' "${line// /$rule}"
}

# Create a box around the contents of a file with a title
print_box() {
  local title="${1:-}"
  local file="${2:-}"
  local requested_width="${3:-}"
  local max_width="${4:-}"
  local wrap_mode="${5:-}"
  local content_width=0
  local requested_content_width=0
  local max_content_width=0
  local terminal_width
  local line padding top_fill line_width title_width
  local top_left top_right bottom_left bottom_right horizontal vertical
  local raw_lines=()
  local lines=()
  local widths=()
  local width_inputs=()
  local index

  check_argument "$title" "box title" || return 1
  check_argument "$file" "box content file" || return 1

  if [[ -n "$requested_width" ]]; then
    if [[ ! "$requested_width" =~ ^[0-9]+$ ]] || [[ "$requested_width" -lt 4 ]]; then
      log_error "box width must be a number greater than or equal to 4"
      return 1
    fi

    requested_content_width="$((requested_width - 4))"
  fi

  if [[ -n "$max_width" ]]; then
    if [[ ! "$max_width" =~ ^[0-9]+$ ]] || [[ "$max_width" -lt 4 ]]; then
      log_error "box maximum width must be a number greater than or equal to 4"
      return 1
    fi

    max_content_width="$((max_width - 4))"
  elif [[ -n "$requested_width" ]]; then
    max_content_width="$requested_content_width"
  else
    terminal_width="$(tput cols 2> /dev/null || true)"
  fi

  if [[ "${terminal_width:-}" =~ ^[0-9]+$ ]] && [[ "$terminal_width" -ge 4 ]]; then
    max_content_width="$((terminal_width - 4))"
  fi

  if [[ "$requested_content_width" -gt "$max_content_width" ]]; then
    max_content_width="$requested_content_width"
  fi

  if [[ "$file" != "-" ]]; then
    check_file "$file" || return 1
  fi

  if [[ -z "${ASCII_ONLY:-}" ]]; then
    top_left="┌"
    top_right="┐"
    bottom_left="└"
    bottom_right="┘"
    horizontal="─"
    vertical="│"
  else
    top_left="+"
    top_right="+"
    bottom_left="+"
    bottom_right="+"
    horizontal="-"
    vertical="|"
  fi

  width_inputs+=("$title")
  if [[ "$file" == "-" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
      raw_lines+=("$line")
    done
  else
    while IFS= read -r line || [[ -n "$line" ]]; do
      raw_lines+=("$line")
    done < "$file"
  fi

  lines=("${raw_lines[@]}")
  width_inputs+=("${lines[@]}")

  mapfile -t widths < <(visible_width "${width_inputs[@]}")
  title_width="${widths[0]:-0}"

  if [[ "$((title_width + 2))" -gt "$max_content_width" ]]; then
    max_content_width="$((title_width + 2))"
  fi

  if [[ "$max_content_width" -gt 0 ]]; then
    lines=()
    width_inputs=("$title")

    if [[ "${#raw_lines[@]}" -gt 0 ]]; then
      while IFS= read -r line || [[ -n "$line" ]]; do
        lines+=("$line")
        width_inputs+=("$line")
      done < <(
        printf '%s\n' "${raw_lines[@]}" | wrap_lines "$max_content_width" "$wrap_mode"
      )
    fi

    mapfile -t widths < <(visible_width "${width_inputs[@]}")
  fi

  for ((index = 0; index < ${#lines[@]}; index += 1)); do
    line_width="${widths[index + 1]:-0}"
    if [[ "$line_width" -gt "$content_width" ]]; then
      content_width="$line_width"
    fi
  done

  if [[ "$((title_width + 2))" -gt "$content_width" ]]; then
    content_width="$((title_width + 2))"
  fi

  if [[ "$requested_content_width" -gt "$content_width" ]]; then
    content_width="$requested_content_width"
  fi

  printf -v top_fill '%*s' "$((content_width - title_width - 1))" ''
  printf '%s%s %s %s%s\n' "$top_left" "$horizontal" "$title" "${top_fill// /$horizontal}" "$top_right"

  for ((index = 0; index < ${#lines[@]}; index += 1)); do
    line="${lines[index]}"
    line_width="${widths[index + 1]:-0}"
    printf '%s %s%*s %s\n' "$vertical" "$line" "$((content_width - line_width))" '' "$vertical"
  done

  printf -v padding '%*s' "$((content_width + 2))" ''
  printf '%s%s%s\n' "$bottom_left" "${padding// /$horizontal}" "$bottom_right"
}
