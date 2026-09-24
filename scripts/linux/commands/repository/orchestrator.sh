#!/usr/bin/env bash

# --------------------------------------------------
# nlobby4 orchestrator CLI.
#
# Toolchain commands intentionally default to the immutable Docker build
# snapshot in /usr/local/share/nlobby4. Runtime commands intentionally default
# to the mounted workspace.
# --------------------------------------------------

set -euo pipefail

readonly DEFAULT_SNAPSHOT_DIR="/usr/local/share/nlobby4"
readonly DEFAULT_WORKSPACE_DIR="${PWD}"

snapshot_dir="${NLOBBY4_SNAPSHOT_DIR:-$DEFAULT_SNAPSHOT_DIR}"
workspace_dir="${NLOBBY4_WORKSPACE_DIR:-$DEFAULT_WORKSPACE_DIR}"

snapshot_config="${NLOBBY4_CONFIG:-$snapshot_dir/.nlobby4.yml}"
snapshot_tool_versions="${NLOBBY4_TOOL_VERSIONS:-$snapshot_dir/.tool-versions}"

usage() {
  cat << 'USAGE'
Usage:
  nlobby4 toolchain install
  nlobby4 toolchain validate
  nlobby4 toolchain list
  nlobby4 repository setup
  nlobby4 project detect
  nlobby4 project setup
  nlobby4 check format
  nlobby4 check lint
  nlobby4 check test
  nlobby4 check build
  nlobby4 check audit
  nlobby4 check all
  nlobby4 add <project-name>
  nlobby4 doctor

Environment:
  NLOBBY4_SNAPSHOT_DIR    Build snapshot directory for toolchain commands.
  NLOBBY4_CONFIG          Build snapshot .nlobby4.yml path.
  NLOBBY4_TOOL_VERSIONS   Build snapshot .tool-versions path.
  NLOBBY4_WORKSPACE_DIR   Mounted workspace directory for runtime commands.
USAGE
}

die() {
  printf 'nlobby4: %s\n' "$*" >&2
  exit 1
}

require_command() {
  command -v "$1" > /dev/null 2>&1 || die "missing command: $1"
}

require_file() {
  [[ -f "$1" ]] || die "missing file: $1"
}

run_in_workspace() {
  cd "$workspace_dir"
  "$@"
}

toolchain_plugins() {
  awk 'NF && $1 !~ /^#/ {print $1}' "$snapshot_tool_versions"
}

toolchain_repository() {
  local plugin="$1"

  plugin="$plugin" yq -er \
    '.toolchains.asdf.plugins[env.plugin]' \
    "$snapshot_config"
}

toolchain_validate() {
  require_command awk
  require_command yq
  require_file "$snapshot_config"
  require_file "$snapshot_tool_versions"

  local plugin
  while read -r plugin; do
    [[ -n "$plugin" ]] || continue
    toolchain_repository "$plugin" > /dev/null \
      || die "missing asdf plugin repository in $snapshot_config: $plugin"
  done < <(toolchain_plugins)
}

toolchain_list() {
  toolchain_validate

  local plugin
  while read -r plugin; do
    [[ -n "$plugin" ]] || continue
    printf '%s\t%s\n' "$plugin" "$(toolchain_repository "$plugin")"
  done < <(toolchain_plugins)
}

toolchain_install() {
  toolchain_validate
  require_command asdf

  local asdf_data_dir="${ASDF_DATA_DIR:-${ASDF_DIR:-$HOME/.asdf}}"
  local plugin
  local repository

  mkdir -p "$asdf_data_dir"
  cp "$snapshot_tool_versions" "$asdf_data_dir/.tool-versions"

  while read -r plugin; do
    [[ -n "$plugin" ]] || continue
    repository="$(toolchain_repository "$plugin")"

    if asdf plugin list | awk -v plugin="$plugin" '$0 == plugin { found = 1 } END { exit found ? 0 : 1 }'; then
      continue
    fi

    asdf plugin add "$plugin" "$repository"
  done < <(toolchain_plugins)

  cd "$asdf_data_dir"
  asdf install
  asdf reshim
}

project_detect() {
  run_in_workspace pnpm run gate:list
}

repository_setup() {
  run_in_workspace bash scripts/linux/commands/repository/setup.sh
}

project_setup() {
  run_in_workspace pnpm run gate:run -- --all setup
}

check_run() {
  case "${1:-}" in
    all)
      run_in_workspace pnpm run gate:run -- --all format
      run_in_workspace pnpm run gate:run -- --all lint
      run_in_workspace pnpm run gate:run -- --all test
      run_in_workspace pnpm run gate:run -- --all build
      run_in_workspace pnpm run gate:run -- --all audit
      ;;
    audit)
      run_in_workspace pnpm run gate:run -- --all audit
      ;;
    build)
      run_in_workspace pnpm run gate:run -- --all build
      ;;
    format)
      run_in_workspace pnpm run gate:run -- --all format
      ;;
    lint)
      run_in_workspace pnpm run gate:run -- --all lint
      ;;
    test)
      run_in_workspace pnpm run gate:run -- --all test
      ;;
    *)
      usage
      exit 64
      ;;
  esac
}

doctor() {
  run_in_workspace bash scripts/linux/commands/repository/health.sh
}

add_project() {
  local project_name="${1:-}"
  local repository_root

  require_command git
  repository_root="$(git -C "$PWD" rev-parse --show-toplevel 2> /dev/null)" \
    || die "nlobby4 add must be run inside a git repository"

  cd "$repository_root"
  bash "$repository_root/scripts/linux/commands/repository/add-project.sh" "$project_name"
}

case "${1:-}" in
  toolchain)
    case "${2:-}" in
      install)
        toolchain_install
        ;;
      validate)
        toolchain_validate
        printf 'nlobby4: toolchain configuration is valid\n'
        ;;
      list)
        toolchain_list
        ;;
      *)
        usage
        exit 64
        ;;
    esac
    ;;
  repository)
    case "${2:-}" in
      setup)
        repository_setup
        ;;
      *)
        usage
        exit 64
        ;;
    esac
    ;;
  project)
    case "${2:-}" in
      detect)
        project_detect
        ;;
      setup)
        project_setup
        ;;
      *)
        usage
        exit 64
        ;;
    esac
    ;;
  check)
    check_run "${2:-}"
    ;;
  add)
    add_project "${2:-}"
    ;;
  doctor)
    doctor
    ;;
  -h | --help | help)
    usage
    ;;
  *)
    usage
    exit 64
    ;;
esac
