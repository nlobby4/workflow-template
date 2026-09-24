#!/usr/bin/env bash

# --------------------------------------------------
# Repository repair script.
#
# Repairs repository-local configuration that can be recreated safely.
# Currently this repairs Git configuration, Git LFS, cache directories,
# executable bits for local scripts and Husky hook setup when available.
#
# Usage:
# ./scripts/linux/commands/repository/repair.sh
# --------------------------------------------------

# Exit immediately if a command exits with a non-zero status
# Treat unset variables as an error and exit immediately
# Prevent errors in a pipeline from being masked
set -euo pipefail

# --------------------------
# Setup
# --------------------------

# Load dependent scripts
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../utils/validation.sh"
. "$SCRIPT_DIR/../../utils/logging/formatting.sh"

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command chmod
check_command find
check_command git
check_git_lfs
check_command id
check_command mkdir
check_command tr
check_command wc

# --------------------------
# Git
# --------------------------

# Repair repository-local Git configuration
check_file .git-blame-ignore-revs
git config blame.ignoreRevsFile .git-blame-ignore-revs
log_ok "Configured blame.ignoreRevsFile"

check_file .gitmessage
git config commit.template .gitmessage
log_ok "Configured commit.template"

# --------------------------
# Git LFS
# --------------------------

# Repair Git LFS configuration and downloaded objects
log_info "Repairing Git LFS configuration..."
if ! git config --local --get filter.lfs.clean > /dev/null 2>&1; then
  log_info "Initializing Git LFS..."
  if git lfs install --local > /dev/null 2>&1; then
    log_ok "Git LFS initialized"
  else
    log_warning "Git LFS hook installation could not be completed"
    log_info "Existing Git hooks were left unchanged"
    log_info "Configuring Git LFS filters without changing hooks..."
    git config --local filter.lfs.clean "git-lfs clean -- %f"
    git config --local filter.lfs.smudge "git-lfs smudge -- %f"
    git config --local filter.lfs.process "git-lfs filter-process"
    git config --local filter.lfs.required true
    log_ok "Git LFS filters configured"
  fi
else
  log_ok "Git LFS already initialized"
fi

lfs_file_count="$(git lfs ls-files --name-only | wc -l | tr -d '[:space:]')"
if [[ "$lfs_file_count" -gt 0 ]]; then
  lfs_file_label="$(plural_label "$lfs_file_count" "file" "files")"
  log_info "Downloading $lfs_file_count Git LFS $lfs_file_label..."
  if git lfs pull; then
    log_ok "Git LFS files downloaded"
    if git lfs checkout; then
      log_ok "Git LFS working tree files checked out"
    else
      log_warning "Git LFS working tree files could not be checked out"
    fi
  else
    log_warning "Git LFS files could not be downloaded"
  fi
fi

# --------------------------
# Cache directories
# --------------------------

# Recreate local tool cache directories used by repository scripts and CI
mkdir -p .cache/general/cspell .cache/general/knip .cache/general/prettier .cache/local .cache/test
log_ok "Cache directories are available"

# Repair the mounted pnpm store volume used by the Dev Container. Named Docker
# volumes can be created as root, but pnpm runs as the remote user.
pnpm_store="${PNPM_STORE_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/pnpm/store}"
if [[ -d "$pnpm_store" && ! -w "$pnpm_store" ]]; then
  if command -v sudo > /dev/null 2>&1; then
    log_info "Repairing pnpm store ownership at $pnpm_store..."
    sudo chown -R "$(id -u):$(id -g)" "$pnpm_store"
    log_ok "pnpm store ownership repaired"
  else
    log_warning "pnpm store is not writable and sudo is unavailable: $pnpm_store"
  fi
fi

# --------------------------
# Executable bits
# --------------------------

# Restore executable bits that are commonly lost when copying the template
script_count=0
while IFS= read -r -d '' file; do
  chmod +x "$file"
  script_count="$((script_count + 1))"
done < <(
  find scripts -type f -name '*.sh' -print0
)

hook_count=0
if [[ -d .husky ]]; then
  while IFS= read -r -d '' file; do
    chmod +x "$file"
    hook_count="$((hook_count + 1))"
  done < <(
    find .husky -maxdepth 1 -type f -print0
  )
fi

script_label="$(plural_label "$script_count" "script" "scripts")"
hook_label="$(plural_label "$hook_count" "hook" "hooks")"
log_ok "Executable bits repaired for $script_count shell $script_label and $hook_count Husky $hook_label"

# --------------------------
# Husky
# --------------------------

# Reinstall Husky hooks when the local dependency is already installed
if [[ -d .husky ]]; then
  if [[ -x node_modules/.bin/husky ]]; then
    if node_modules/.bin/husky > /dev/null 2>&1; then
      log_ok "Husky hooks repaired"
    else
      log_warning "Husky hooks could not be repaired"
    fi
  else
    log_info "Skipping Husky repair because node_modules/.bin/husky is unavailable"
  fi
fi

log_ok "Repository repair complete"
