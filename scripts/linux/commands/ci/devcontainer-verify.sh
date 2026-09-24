#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE:?IMAGE is required}"
: "${DIGEST:?DIGEST is required}"
: "${AMD64_DIGEST:?AMD64_DIGEST is required}"
: "${ARM64_DIGEST:?ARM64_DIGEST is required}"
: "${COSIGN_IDENTITY:?COSIGN_IDENTITY is required}"
issuer="${COSIGN_OIDC_ISSUER:-https://token.actions.githubusercontent.com}"
cosign verify --certificate-identity "$COSIGN_IDENTITY" --certificate-oidc-issuer "$issuer" "$IMAGE@$DIGEST"
cosign verify-attestation --certificate-identity "$COSIGN_IDENTITY" --certificate-oidc-issuer "$issuer" --type slsaprovenance "$IMAGE@$DIGEST"
cosign verify-attestation --certificate-identity "$COSIGN_IDENTITY" --certificate-oidc-issuer "$issuer" --type spdxjson "$IMAGE@$AMD64_DIGEST"
cosign verify-attestation --certificate-identity "$COSIGN_IDENTITY" --certificate-oidc-issuer "$issuer" --type spdxjson "$IMAGE@$ARM64_DIGEST"
