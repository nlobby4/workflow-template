#!/usr/bin/env bash
set -euo pipefail

: "${OWNER:?OWNER is required}"
: "${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}"
: "${GITHUB_RUN_ATTEMPT:?GITHUB_RUN_ATTEMPT is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

owner="${OWNER,,}"
image="ghcr.io/$owner/workflow-template-devcontainer"
candidate="candidate-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
devcontainer build --workspace-folder . --frozen-lockfile \
  --platform linux/amd64,linux/arm64 --image-name "$image:$candidate" --push
digest="$(docker buildx imagetools inspect "$image:$candidate" --format '{{.Manifest.Digest}}')"
printf 'image=%s\ndigest=%s\n' "$image" "$digest" >> "$GITHUB_OUTPUT"
