#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE:?IMAGE is required}"
: "${DIGEST:?DIGEST is required}"
: "${AMD64_DIGEST:?AMD64_DIGEST is required}"
: "${ARM64_DIGEST:?ARM64_DIGEST is required}"
cosign sign --yes "$IMAGE@$DIGEST"
cosign attest --yes --predicate .generated/devcontainer-amd64.spdx.json --type spdxjson "$IMAGE@$AMD64_DIGEST"
cosign attest --yes --predicate .generated/devcontainer-arm64.spdx.json --type spdxjson "$IMAGE@$ARM64_DIGEST"
