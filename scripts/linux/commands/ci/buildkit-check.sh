#!/usr/bin/env bash
set -euo pipefail

docker build --check --file .devcontainer/Dockerfile .
