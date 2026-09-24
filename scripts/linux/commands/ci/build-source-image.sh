#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE:?IMAGE is required}"
mkdir -p .generated
devcontainer build --workspace-folder . --no-cache --frozen-lockfile --image-name "$IMAGE"
docker push "$IMAGE"
