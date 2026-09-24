#!/usr/bin/env bash
set -euo pipefail

hadolint --config .hadolint.yaml .devcontainer/Dockerfile
hadolint --config .hadolint.yaml policy/fixtures/dockerfile/valid.Dockerfile

if hadolint --config .hadolint.yaml policy/fixtures/dockerfile/invalid.Dockerfile > /dev/null 2>&1; then
  echo "invalid Dockerfile fixture unexpectedly passed" >&2
  exit 1
fi
