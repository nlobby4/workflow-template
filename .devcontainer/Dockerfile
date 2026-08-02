# --------------------------------------------------
# Dockerfile for the development container.
#
# This Dockerfile defines the development environment.
# It is based on a official devcontainer image (Debian Bookworm variant)
# and extends it with additional tools and configuration to ensure consistency
# across local development environments.
#
# If you prefer not to use the development container,
# you can set up your local environment by running the setup script,
# and manually configuring the tool versions as specified in .tool-versions.
# Please note that the script does not automatically install required tools:
#
# ./scripts/linux/setup.sh
#
# For more information, see:
# https://github.com/devcontainers/images
# https://containers.dev/supporting
# --------------------------------------------------

# syntax=docker/dockerfile:1

# --------------------------
# Base Image
# --------------------------

# Use the official Debian Bookworm image
ARG VARIANT="bookworm"
FROM mcr.microsoft.com/devcontainers/base:${VARIANT}

# Rename the default devcontainer user while preserving its UID, permissions,
# sudo access, and home-directory ownership from the base image.
RUN groupmod --new-name nlobby4 vscode \
  && usermod --login nlobby4 --home /home/nlobby4 --move-home vscode \
  && printf '%s\n' 'nlobby4 ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/nlobby4 \
  && chmod 0440 /etc/sudoers.d/nlobby4

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -y install --no-install-recommends \
    curl \
    gawk \
    git-lfs \
    jq \
    pipx \
    shellcheck \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# --------------------------
# Install Zizmor
#
# Zizmor audits GitHub Actions workflows for security issues.
# The version is pinned here for reproducibility.
# To upgrade, update ZIZMOR_VERSION and rebuild the image.
# --------------------------

ENV ZIZMOR_VERSION=1.26.1
ENV PIPX_HOME=/opt/pipx
ENV PIPX_BIN_DIR=/usr/local/bin

RUN pipx install "zizmor==${ZIZMOR_VERSION}"

# --------------------------
# Install Actionlint
#
# Actionlint validates GitHub Actions workflow files locally and in CI.
# The version is pinned here for reproducibility.
# To upgrade, update ACTIONLINT_VERSION and rebuild the image.
# --------------------------

ENV ACTIONLINT_VERSION=1.7.7

RUN ACTIONLINT_ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
  && case "${ACTIONLINT_ARCH}" in \
    amd64 | arm64) ;; \
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
  esac \
  && curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_${ACTIONLINT_ARCH}.tar.gz" \
  -o /tmp/actionlint.tar.gz \
  && tar -xzf /tmp/actionlint.tar.gz -C /tmp actionlint \
  && install -m 0755 /tmp/actionlint /usr/local/bin/actionlint \
  && rm -f /tmp/actionlint.tar.gz /tmp/actionlint

# --------------------------
# Install Act
#
# Act runs GitHub Actions workflows locally against a Docker runtime.
# The version is pinned here for reproducibility.
# To upgrade, update ACT_VERSION and rebuild the image.
# --------------------------

ENV ACT_VERSION=0.2.89

RUN ACT_ARCH=$(uname -m | sed 's/aarch64/arm64/') \
  && case "${ACT_ARCH}" in \
    x86_64 | arm64) ;; \
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
  esac \
  && curl -fsSL "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/act_Linux_${ACT_ARCH}.tar.gz" \
  -o /tmp/act.tar.gz \
  && tar -xzf /tmp/act.tar.gz -C /tmp act \
  && install -m 0755 /tmp/act /usr/local/bin/act \
  && rm -f /tmp/act.tar.gz /tmp/act

# --------------------------
# Install ASDF
#
# ASDF is used to manage runtime versions (Node.js, etc.) across all
# contributors. The version is pinned here for reproducibility.
# To upgrade, update ASDF_VERSION and rebuild the image.
#
# ASDF_DIR and ASDF_DATA_DIR are set to a shared system path so all users
# inside the container (including the non-root "nlobby4" user) can access
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
RUN asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

# Install tools
COPY .tool-versions /usr/local/asdf/.tool-versions

RUN cd /usr/local/asdf && asdf install \
  && asdf reshim \
  && chown -R nlobby4:nlobby4 /usr/local/asdf \
  && chmod -R 755 /usr/local/asdf
