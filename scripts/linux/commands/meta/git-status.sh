#!/usr/bin/env bash

# --------------------------------------------------
# Git status metadata script.
#
# Reports Git setup, privacy, and freshness metadata for the current repository.
# This script is informational only and should not fail health checks.
#
# Usage:
# ./scripts/linux/commands/meta/git-status.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../utils/validation.sh"
. "$SCRIPT_DIR/../../utils/logging/formatting.sh"

# --------------------------
# Helpers
# --------------------------

is_github_private_email() {
  local email="${1:-}"
  [[ "$email" =~ ^[A-Za-z0-9._%+-]+@users\.noreply\.github\.com$ ]]
}

mask_email() {
  local email="${1:-}"
  local local_part domain

  if [[ -z "$email" || "$email" != *@* ]]; then
    printf '%s' "${email:-unset}"
    return
  fi

  local_part="${email%@*}"
  domain="${email#*@}"

  if [[ "$domain" == "users.noreply.github.com" ]]; then
    printf '%s' "***@$domain"
  elif [[ "${#local_part}" -le 1 ]]; then
    printf '%s' "*@$domain"
  else
    printf '%s' "${local_part:0:1}***@$domain"
  fi
}

mask_remote_url() {
  local remote_url="${1:-}"

  if [[ "$remote_url" =~ ^([^:]+://)([^/@]+@)(.+)$ ]]; then
    printf '%s' "${BASH_REMATCH[1]}***@${BASH_REMATCH[3]}"
  else
    printf '%s' "$remote_url"
  fi
}

add_branch_status() {
  local local_ref="$1"
  local remote_ref="$2"
  local label="$3"
  local behind_count

  behind_count="$(git rev-list --count "$local_ref..$remote_ref" 2> /dev/null || true)"
  [[ "$behind_count" =~ ^[0-9]+$ ]] || return

  if [[ "$behind_count" -gt 0 ]]; then
    add_status \
      "Git branch $label" \
      "$behind_count $(plural_label "$behind_count" "commit" "commits") behind $remote_ref"
  else
    add_status "Git branch $label" "up to date with $remote_ref"
  fi
}

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command git

current_branch="$(git branch --show-current)"
upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" 2> /dev/null || true)"
reset_status

# --------------------------
# Git identity
# --------------------------

git_name="$(git config --get user.name || true)"
git_email="$(git config --get user.email || true)"

add_status "Git user.name" "${git_name:-unset}"

if [[ -n "$git_email" ]]; then
  if is_github_private_email "$git_email"; then
    add_status \
      "Git user.email" \
      "$(mask_email "$git_email") (GitHub private noreply address)"
  else
    add_status \
      "Git user.email" \
      "$(mask_email "$git_email") (not a GitHub private noreply address)"
  fi
else
  add_status "Git user.email" "unset (privacy unavailable)"
fi

if [[ "$(git config --bool --get commit.gpgsign || true)" == "true" ]]; then
  signing_key="$(git config --get user.signingkey || true)"
  if [[ -n "$signing_key" ]]; then
    add_status "Git commit signing" "enabled with signing key ${signing_key:0:4}***"
  else
    add_status "Git commit signing" "enabled but user.signingkey is not configured"
  fi
else
  add_status "Git commit signing" "disabled"
fi

# --------------------------
# Git repository
# --------------------------

if git remote get-url origin > /dev/null 2>&1; then
  origin_url="$(git remote get-url origin)"
  add_status "Git origin remote" "$(mask_remote_url "$origin_url")"
else
  add_status "Git origin remote" "not configured"
fi

default_remote_ref="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2> /dev/null || true)"

# --------------------------
# Remote freshness
# --------------------------

reported_branch_ref=""
reported_upstream_ref=""
remote_checks_available=0

if git remote get-url origin > /dev/null 2>&1; then
  if ! git ls-remote --quiet origin HEAD > /dev/null 2>&1; then
    add_status "Git remote freshness" "origin unavailable; checks skipped"
  elif git fetch --quiet --prune origin > /dev/null 2>&1; then
    remote_checks_available=1
    [[ -n "$default_remote_ref" ]] || default_remote_ref="origin/main"
    default_branch_ref="${default_remote_ref#origin/}"

    if git show-ref --verify --quiet "refs/remotes/${default_remote_ref#refs/remotes/}" \
      && git show-ref --verify --quiet "refs/heads/$default_branch_ref"; then
      add_branch_status "$default_branch_ref" "$default_remote_ref" "$default_branch_ref"
      reported_branch_ref="$default_branch_ref"
      reported_upstream_ref="$default_remote_ref"
    else
      add_status \
        "Git remote freshness" \
        "unable to compare local default branch with $default_remote_ref"
    fi
  else
    add_status "Git remote freshness" "unable to fetch origin; checks skipped"
  fi
else
  add_status "Git remote freshness" "no origin remote configured; checks skipped"
fi

if [[ -n "$current_branch" && "$remote_checks_available" -eq 1 ]]; then
  if [[ -n "$upstream_ref" && "$current_branch" == "$reported_branch_ref" && "$upstream_ref" == "$reported_upstream_ref" ]]; then
    :
  elif [[ -n "$upstream_ref" ]]; then
    add_branch_status "HEAD" "$upstream_ref" "$current_branch"
  else
    add_status "Git branch $current_branch" "no upstream branch"
  fi
fi

print_status
