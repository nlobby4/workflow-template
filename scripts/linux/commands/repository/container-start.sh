#!/usr/bin/env bash

# Wait for the isolated Docker-in-Docker daemon before running health checks.

# Exit on command errors and unset variables, and propagate pipeline failures.
set -euo pipefail

for attempt in {1..30}; do
  if docker version > /dev/null 2>&1; then
    exec mise run doctor
  fi
  if [[ "$attempt" -eq 30 ]]; then
    printf 'Docker-in-Docker did not become ready within 30 seconds\n' >&2
    exit 1
  fi
  sleep 1
done
