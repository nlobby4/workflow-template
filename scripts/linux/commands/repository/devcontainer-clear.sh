#!/usr/bin/env bash

# --------------------------------------------------
# Development container cache cleanup script.
#
# Removes only the current workspace's development container, its image and
# named volumes, and the repository-local cache contents. Unrelated Docker
# resources and generated project output are left unchanged.
#
# Usage:
# mise run devcontainer:clear
# pnpm run devcontainer:clear
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

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command docker

if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]; then
  log_error "run Dev Container cleanup directly on the Docker host"
  exit 1
fi

docker info > /dev/null

workspace="$PWD"
workspace_name="$(basename -- "$workspace")"
cache_directory="$workspace/.cache"

case "$cache_directory" in
  "$workspace/.cache") ;;
  *)
    log_error "refusing to clear unexpected cache path: $cache_directory"
    exit 1
    ;;
esac

# --------------------------
# Resolve workspace resources
# --------------------------

container_output="$(
  docker ps --all --quiet \
    --filter "label=devcontainer.local_folder=$workspace"
)"
mapfile -t container_ids <<< "$container_output"

declare -A volume_ids=()
declare -A image_ids=()

for container_id in "${container_ids[@]}"; do
  [[ -n "$container_id" ]] || continue

  image_id="$(docker inspect --format '{{.Image}}' "$container_id")"
  image_ids["$image_id"]=1

  volume_output="$(
    docker inspect \
      --format '{{range .Mounts}}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' \
      "$container_id"
  )"
  while IFS= read -r volume_id; do
    [[ -n "$volume_id" ]] || continue
    volume_ids["$volume_id"]=1
  done <<< "$volume_output"
done

# --------------------------
# Remove workspace resources
# --------------------------

log_info "Clearing cached Dev Container resources for $workspace_name..."

for container_id in "${container_ids[@]}"; do
  [[ -n "$container_id" ]] || continue
  docker rm --force "$container_id" > /dev/null
  log_ok "Removed development container $container_id"
done

for volume_id in "${!volume_ids[@]}"; do
  docker volume rm "$volume_id" > /dev/null
  log_ok "Removed development container volume $volume_id"
done

for image_id in "${!image_ids[@]}"; do
  if docker image rm "$image_id" > /dev/null; then
    log_ok "Removed development container image $image_id"
  else
    log_warning "Image remains in use and was not removed: $image_id"
  fi
done

if [[ -d "$cache_directory" ]]; then
  find "$cache_directory" -mindepth 1 -delete
fi
mkdir -p \
  "$cache_directory/general/cspell" \
  "$cache_directory/general/knip" \
  "$cache_directory/general/prettier" \
  "$cache_directory/general/trivy" \
  "$cache_directory/local" \
  "$cache_directory/test"
log_ok "Cleared and recreated repository cache directories"

log_ok "Development container caches cleared"
