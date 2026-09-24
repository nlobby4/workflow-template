#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE:?IMAGE is required}"
: "${DIGEST:?DIGEST is required}"
: "${GITHUB_SHA:?GITHUB_SHA is required}"
docker buildx imagetools create --tag "$IMAGE:${GITHUB_SHA}" "$IMAGE@$DIGEST"
promoted="$(docker buildx imagetools inspect "$IMAGE:${GITHUB_SHA}" --format '{{.Manifest.Digest}}')"
test "$promoted" = "$DIGEST"
