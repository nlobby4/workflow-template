# --------------------------------------------------
# Dockerfile for the development container.
#
# This Dockerfile defines the development environment.
# It is based on a official devcontainer image (Debian Bookworm variant)
# and extends it with additional tools and configuration to ensure consistency
# across local development environments.
#
# If you prefer not to use the development container,
# you can set up your local environment by running the setup script.
# Please note that the script does not automatically install required tools:
#
# ./scripts/linux/setup.sh
#
# For more information, see:
# https://github.com/devcontainers/images/tree/main/src/typescript-node
# https://containers.dev/supporting
# --------------------------------------------------

# syntax=docker/dockerfile:1

# --------------------------
# Base Image
# --------------------------

# Use the official Debian Bookworm image
ARG VARIANT="bookworm"
FROM mcr.microsoft.com/devcontainers/base:${VARIANT}

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -y install --no-install-recommends \
    # TODO: Enable git-lfs if needed
    # git-lfs \
    curl gawk \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# --------------------------
# Install ASDF
#
# ASDF is used to manage runtime versions (Node.js, etc.) across all
# contributors. The version is pinned here for reproducibility.
# To upgrade, update ASDF_VERSION and rebuild the image.
#
# ASDF_DIR and ASDF_DATA_DIR are set to a shared system path so all users
# inside the container (including the non-root "vscode" user) can access
# the installed runtimes without per-user installation.
#
# To add more language plugins, extend the RUN block below.
# --------------------------

ENV ASDF_VERSION=0.18.1
ENV ASDF_DIR=/usr/local/asdf
ENV ASDF_DATA_DIR=/usr/local/asdf

RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
  && curl -fsSL "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-${ARCH}.tar.gz" \
  -o /tmp/asdf.tar.gz \
  && tar -xzf /tmp/asdf.tar.gz -C /tmp \
  && mv /tmp/asdf /usr/local/bin/asdf \
  && rm /tmp/asdf.tar.gz \
  && chmod +x /usr/local/bin/asdf

# Non-login shell configuration for ASDF
RUN printf '%s\n' \
  'export ASDF_DIR=/usr/local/asdf' \
  'export ASDF_DATA_DIR=/usr/local/asdf' \
  'export PATH="${ASDF_DATA_DIR}/shims:${ASDF_DATA_DIR}/plugins:${PATH}"' \
  >> /etc/bash.bashrc

# Login shell configuration for ASDF
RUN printf '%s\n' \
  'export ASDF_DIR=/usr/local/asdf' \
  'export ASDF_DATA_DIR=/usr/local/asdf' \
  'export PATH="${ASDF_DATA_DIR}/shims:${ASDF_DATA_DIR}/plugins:${PATH}"' \
  > /etc/profile.d/asdf.sh \
  && chmod +x /etc/profile.d/asdf.sh

# Enable bash tab-completion for asdf commands.
RUN echo '. <(asdf completion bash)' >> /etc/bash.bashrc

# Install ASDF plugins and set permissions
# Available plugins: https://github.com/asdf-vm
#                    https://github.com/asdf-community
# TODO: Add needed plugins
RUN asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git \
  && chown -R vscode:vscode /usr/local/asdf \
  && chmod -R 755 /usr/local/asdf
