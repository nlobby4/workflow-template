#!/usr/bin/env bash

# --------------------------------------------------
# Validation helpers for repository scripts.
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
[[ -n "${_VALIDATION_LOADED:-}" ]] && return
_VALIDATION_LOADED=1

# --------------------------
# Setup
# --------------------------

# Load dependent scripts
VALIDATION_UTILS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$VALIDATION_UTILS_DIR/logging/logging.sh"

# --------------------------
# Validation
# --------------------------

# Check if a command is available in PATH
check_command() {
  local command_name="${1:-}"

  if [[ -z "$command_name" ]]; then
    log_error "missing required argument: command name"
    return 1
  fi

  command -v "$command_name" > /dev/null 2>&1 || {
    log_error "$command_name is required but was not found in PATH"
    return 1
  }
}

# Check if a required argument is provided
check_argument() {
  local value="${1:-}"
  local name="${2:-argument}"

  if [[ -z "$value" ]]; then
    log_error "missing required argument: $name"
    return 1
  fi
}

# Check if a regular file exists
check_file() {
  local file="${1:-}"

  if [[ -z "$file" ]]; then
    log_error "missing required argument: file path"
    return 1
  fi

  [[ -f "$file" ]] || {
    log_error "file not found: $file"
    return 1
  }
}

# Check if a directory exists
check_directory() {
  local directory="${1:-}"

  if [[ -z "$directory" ]]; then
    log_error "missing required argument: directory path"
    return 1
  fi

  [[ -d "$directory" ]] || {
    log_error "directory not found: $directory"
    return 1
  }
}

# Check if a path exists
check_path() {
  local path="${1:-}"

  if [[ -z "$path" ]]; then
    log_error "missing required argument: path"
    return 1
  fi

  [[ -e "$path" ]] || {
    log_error "path not found: $path"
    return 1
  }
}

# Check if a symlink exists, including broken symlinks
check_symlink() {
  local symlink="${1:-}"

  if [[ -z "$symlink" ]]; then
    log_error "missing required argument: symlink path"
    return 1
  fi

  [[ -L "$symlink" ]] || {
    log_error "symlink not found: $symlink"
    return 1
  }
}

# Check if a symlink exists and its target exists
check_resolved_symlink() {
  local symlink="${1:-}"

  check_symlink "$symlink" || return 1

  [[ -e "$symlink" ]] || {
    log_error "symlink target not found: $symlink"
    return 1
  }
}

# Check if the current directory is inside a git repository
check_git_repo() {
  check_command git || return 1
  git rev-parse --is-inside-work-tree > /dev/null 2>&1 || {
    log_error "not inside a git repository"
    return 1
  }
}

# Check if the git lfs subcommand is available
check_git_lfs() {
  check_command git || return 1

  git lfs version > /dev/null 2>&1 || {
    log_error "git lfs is required but was not found"
    return 1
  }
}

# Check if git LFS is configured for this repository
check_git_lfs_configured() {
  check_git_repo || return 1
  check_git_lfs || return 1

  git config --local --get filter.lfs.clean > /dev/null 2>&1 || {
    log_error "git lfs is not initialized for this repository"
    return 1
  }
}

# Check if the script is run from the repository root
check_repository_root() {
  check_command git || return 1

  local repository_root current_dir

  repository_root="$(git rev-parse --show-toplevel 2> /dev/null)" || {
    log_error "not inside a git repository"
    return 1
  }

  repository_root="$(cd "$repository_root" && pwd -P)"
  current_dir="$(pwd -P)"

  if [[ "$current_dir" != "$repository_root" ]]; then
    log_error "run this script from repository root: expected $repository_root, got $current_dir"
    return 1
  fi
}
