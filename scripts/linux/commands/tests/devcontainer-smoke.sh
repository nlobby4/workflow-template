#!/usr/bin/env bash

# --------------------------------------------------
# End-to-end smoke test for the development container.
#
# Creates an isolated copy of the current working tree, performs a clean image
# build, runs the configured lifecycle commands, verifies the pinned tools and
# Docker access, then proves that dependencies can be restored offline from the
# persistent pnpm store volume.
#
# Run this script on the Docker host, not from inside a development container.
#
# Usage:
# mise run test:devcontainer
# pnpm run test:devcontainer
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

test_root=""
test_workspace=""
container_id=""
image_id=""
volume_names=()

cleanup() {
  local cleanup_status=0

  set +e

  if [[ -n "$container_id" ]]; then
    docker rm --force "$container_id" > /dev/null 2>&1 || cleanup_status=1
  fi

  for volume_name in "${volume_names[@]}"; do
    docker volume inspect "$volume_name" > /dev/null 2>&1 \
      && docker volume rm "$volume_name" > /dev/null 2>&1 \
      || cleanup_status=1
  done

  if [[ -n "$image_id" ]] && docker image inspect "$image_id" > /dev/null 2>&1; then
    docker image rm "$image_id" > /dev/null 2>&1 || cleanup_status=1
  fi

  case "$test_root" in
    "${TMPDIR:-/tmp}"/workflow-template-devcontainer-smoke.*)
      rm -rf -- "$test_root" || cleanup_status=1
      ;;
    "")
      ;;
    *)
      log_error "refusing to remove unexpected test path: $test_root"
      cleanup_status=1
      ;;
  esac

  if [[ "$cleanup_status" -ne 0 ]]; then
    log_warning "Some disposable smoke-test resources could not be removed"
  fi
}

trap cleanup EXIT

# --------------------------
# Pre-flight checks
# --------------------------

check_repository_root
check_command docker
check_command git
check_command jq
check_command mise
check_command pnpm
check_command tar

if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]; then
  log_error "run the devcontainer smoke test directly on the Docker host"
  exit 1
fi

docker info > /dev/null

# --------------------------
# Create isolated workspace
# --------------------------

test_root="$(mktemp -d "${TMPDIR:-/tmp}/workflow-template-devcontainer-smoke.XXXXXX")"
test_workspace="$test_root"

log_info "Copying the working tree to $test_workspace"

tar \
  --exclude='./.cache' \
  --exclude='./.generated' \
  --exclude='./.git' \
  --exclude='./node_modules' \
  --exclude='*/.cache' \
  --exclude='*/.generated' \
  --exclude='*/node_modules' \
  -cf - . \
  | tar -xf - -C "$test_workspace"

git -C "$test_workspace" init --quiet
git -C "$test_workspace" add --all

# --------------------------
# Build and create container
# --------------------------

log_info "Building and creating the disposable development container"

mise exec -- devcontainer up \
  --workspace-folder "$test_workspace" \
  --remove-existing-container \
  --build-no-cache \
  --frozen-lockfile

container_id="$(
  docker ps --all --quiet \
    --filter "label=devcontainer.local_folder=$test_workspace" \
    | head -n 1
)"

if [[ -z "$container_id" ]]; then
  log_error "development container was not created"
  exit 1
fi

image_id="$(docker inspect --format '{{.Image}}' "$container_id")"
privileged="$(docker inspect --format '{{.HostConfig.Privileged}}' "$container_id")"
[[ "$privileged" == "true" ]]
if ! volume_mounts="$(
  docker inspect \
    --format '{{range .Mounts}}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' \
    "$container_id"
)"; then
  log_error "could not inspect disposable container volumes"
  exit 1
fi
mapfile -t volume_names <<< "$volume_mounts"
pnpm_volume_name="$(
  docker inspect \
    --format '{{range .Mounts}}{{if eq .Destination "/home/nlobby4/.local/share/pnpm/store"}}{{println .Name}}{{end}}{{end}}' \
    "$container_id"
)"
if [[ ! "$pnpm_volume_name" =~ ^workflow-template-pnpm-v10-store-[0-9a-v]{52}$ ]]; then
  log_error "unexpected pnpm volume name: $pnpm_volume_name"
  exit 1
fi

# --------------------------
# Runtime verification
# --------------------------

log_info "Verifying the container runtime and persistent pnpm store"

# shellcheck disable=SC1091
. "$test_workspace/.devcontainer/versions.env"

NODE_VERSION="$(awk -F '"' '$1 == "node = " { print $2 }' "$test_workspace/mise.toml")"
PNPM_VERSION="$(awk -F '"' '$2 == "npm:pnpm" { print $4 }' "$test_workspace/mise.toml")"
SHELLCHECK_VERSION="$(awk -F '"' '$1 == "shellcheck = " { print $2 }' "$test_workspace/mise.toml")"
TRIVY_VERSION="$(awk -F '"' '$1 == "trivy = " { print $2 }' "$test_workspace/mise.toml")"
ACT_VERSION="$(awk -F '"' '$1 == "act = " { print $2 }' "$test_workspace/mise.toml")"
ACTIONLINT_VERSION="$(awk -F '"' '$1 == "actionlint = " { print $2 }' "$test_workspace/mise.toml")"
ZIZMOR_VERSION="$(awk -F '"' '$1 == "zizmor = " { print $2 }' "$test_workspace/mise.toml")"
COSIGN_VERSION="$(awk -F '"' '$1 == "cosign = " { print $2 }' "$test_workspace/mise.toml")"
GITLEAKS_VERSION="$(awk -F '"' '$1 == "gitleaks = " { print $2 }' "$test_workspace/mise.toml")"
HADOLINT_VERSION="$(awk -F '"' '$1 == "hadolint = " { print $2 }' "$test_workspace/mise.toml")"
CONFTEST_VERSION="$(awk -F '"' '$1 == "conftest = " { print $2 }' "$test_workspace/mise.toml")"
TOMBI_VERSION="$(awk -F '"' '$1 == "tombi = " { print $2 }' "$test_workspace/mise.toml")"
YAMLLINT_VERSION="$(awk -F '"' '$1 == "yamllint = " { print $2 }' "$test_workspace/mise.toml")"
DOCKER_VERSION="$(jq --raw-output '.features[] | .version' "$test_workspace/.devcontainer/devcontainer.json")"
DOCKER_BUILDX_VERSION="$(jq --raw-output '.features[] | .mobyBuildxVersion' "$test_workspace/.devcontainer/devcontainer.json")"

# The single-quoted script must expand only inside the development container.
# shellcheck disable=SC2016
mise exec -- devcontainer exec \
  --workspace-folder "$test_workspace" \
  --remote-env "EXPECTED_NODE_VERSION=$NODE_VERSION" \
  --remote-env "EXPECTED_PNPM_VERSION=$PNPM_VERSION" \
  --remote-env "EXPECTED_SHELLCHECK_VERSION=$SHELLCHECK_VERSION" \
  --remote-env "EXPECTED_TRIVY_VERSION=$TRIVY_VERSION" \
  --remote-env "EXPECTED_COSIGN_VERSION=$COSIGN_VERSION" \
  --remote-env "EXPECTED_GITLEAKS_VERSION=$GITLEAKS_VERSION" \
  --remote-env "EXPECTED_HADOLINT_VERSION=$HADOLINT_VERSION" \
  --remote-env "EXPECTED_CONFTEST_VERSION=$CONFTEST_VERSION" \
  --remote-env "EXPECTED_TOMBI_VERSION=$TOMBI_VERSION" \
  --remote-env "EXPECTED_YAMLLINT_VERSION=$YAMLLINT_VERSION" \
  --remote-env "EXPECTED_MISE_VERSION=$MISE_VERSION" \
  --remote-env "EXPECTED_ACTIONLINT_VERSION=$ACTIONLINT_VERSION" \
  --remote-env "EXPECTED_ACT_VERSION=$ACT_VERSION" \
  --remote-env "EXPECTED_ZIZMOR_VERSION=$ZIZMOR_VERSION" \
  --remote-env "EXPECTED_DOCKER_VERSION=$DOCKER_VERSION" \
  --remote-env "EXPECTED_BUILDX_VERSION=$DOCKER_BUILDX_VERSION" \
  bash -lc '
    set -euo pipefail

    [[ "$(id --user)" -ne 0 ]]
    [[ "$(stat --format %u .)" == "$(id --user)" ]]
    [[ "$(ps --pid 1 --format comm=)" =~ ^(docker-init|tini)$ ]]
    ! sudo -n true
    [[ ! -S /var/run/docker-host.sock ]]
    [[ "$(node --version)" == "v$EXPECTED_NODE_VERSION" ]]
    [[ "$(pnpm --version)" == "$EXPECTED_PNPM_VERSION" ]]
    [[ "$(shellcheck --version | awk "/^version:/ { print \$2 }")" == "$EXPECTED_SHELLCHECK_VERSION" ]]
    [[ "$(trivy --version | awk "/^Version:/ { print \$2 }")" == "$EXPECTED_TRIVY_VERSION" ]]
    [[ "$(cosign version --json | jq -r .gitVersion | sed "s/^v//")" == "$EXPECTED_COSIGN_VERSION" ]]
    [[ "$(gitleaks version)" == "$EXPECTED_GITLEAKS_VERSION" ]]
    [[ "$(hadolint --version | awk "{ print \$NF }")" == "$EXPECTED_HADOLINT_VERSION" ]]
    [[ "$(conftest --version | awk "/^Conftest:/ { print \$2 }")" == "$EXPECTED_CONFTEST_VERSION" ]]
    [[ "$(tombi --version | awk "{ print \$2 }")" == "$EXPECTED_TOMBI_VERSION" ]]
    [[ "$(yamllint --version | awk "{ print \$2 }")" == "$EXPECTED_YAMLLINT_VERSION" ]]
    [[ "$(mise --version | awk "{ print \$1 }")" == "$EXPECTED_MISE_VERSION" ]]
    [[ -z "${MISE_DATA_DIR:-}" ]]
    [[ "$(mise where node)" == /usr/local/share/mise/installs/node/* ]]
    [[ ":$PATH:" == *":/home/nlobby4/.local/share/mise/shims:/usr/local/share/mise/shims:"* ]]
    [[ ! -e /usr/local/share/mise/cache ]]
    [[ "$(actionlint --version | head -n 1)" == "$EXPECTED_ACTIONLINT_VERSION" ]]
    [[ "$(act --version)" == "act version $EXPECTED_ACT_VERSION" ]]
    [[ "$(zizmor --version)" == "zizmor $EXPECTED_ZIZMOR_VERSION" ]]
    [[ "$(docker --version)" == Docker\ version\ "$EXPECTED_DOCKER_VERSION"-* ]]
    [[ "$(docker buildx version)" == *"$EXPECTED_BUILDX_VERSION"* ]]
    [[ "$(pnpm store path)" == "/home/nlobby4/.local/share/pnpm/store/v10" ]]
    [[ -w "/home/nlobby4/.local/share/pnpm/store" ]]

    findmnt --mountpoint "/home/nlobby4/.local/share/pnpm/store" > /dev/null
    docker version > /dev/null
    docker compose version | tee /tmp/docker-compose-version.txt
    printf "services:\n  daemon:\n    image: hello-world\n" > /tmp/compose.yml
    docker compose --project-name devcontainer-smoke --file /tmp/compose.yml up --detach
    docker compose --project-name devcontainer-smoke --file /tmp/compose.yml down
    mise run doctor
  '

# --------------------------
# Restart verification
# --------------------------

log_info "Restarting the container and re-running lifecycle health checks"

docker stop "$container_id" > /dev/null
mise exec -- devcontainer up \
  --workspace-folder "$test_workspace" \
  --expect-existing-container \
  --frozen-lockfile > /dev/null

mise exec -- devcontainer exec \
  --workspace-folder "$test_workspace" \
  bash -lc 'docker version > /dev/null && mise run doctor > /dev/null'

# --------------------------
# Offline store verification
# --------------------------

log_info "Reinstalling dependencies offline from the persistent pnpm store"

rm -rf -- "$test_workspace/node_modules"

mise exec -- devcontainer exec \
  --workspace-folder "$test_workspace" \
  bash -lc \
  'pnpm install --offline --frozen-lockfile --ignore-scripts --silent'

if [[ ! -d "$test_workspace/node_modules" ]]; then
  log_error "offline dependency installation did not create node_modules"
  exit 1
fi

log_ok "Development container smoke test passed"
