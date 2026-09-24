#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE:?IMAGE is required}"
: "${DIGEST:?DIGEST is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"
manifest="$(docker buildx imagetools inspect --raw "$IMAGE@$DIGEST")"
amd64="$(jq --exit-status --raw-output '.manifests[] | select(.platform.os == "linux" and .platform.architecture == "amd64") | .digest' <<< "$manifest")"
arm64="$(jq --exit-status --raw-output '.manifests[] | select(.platform.os == "linux" and .platform.architecture == "arm64") | .digest' <<< "$manifest")"
printf 'amd64=%s\narm64=%s\n' "$amd64" "$arm64" >> "$GITHUB_OUTPUT"
