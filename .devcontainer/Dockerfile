# --------------------------------------------------
# Dockerfile for the development container.
#
# This Dockerfile defines the development environment.
# It is based on a official devcontainer image (Debian Bookworm variant)
# and extends it with additional tools and configuration to ensure consistency
# across local development environments.
#
# If you prefer not to use the development container, install the required
# tools from .tool-versions locally and then run the repository setup through
# the nlobby4 interface:
#
# nlobby4 repository setup
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
  && mkdir -p /home/nlobby4/.npm \
  && chown -R nlobby4:nlobby4 /home/nlobby4/.npm \
  && printf '%s\n' 'nlobby4 ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/nlobby4 \
  && chmod 0440 /etc/sudoers.d/nlobby4

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -y install --no-install-recommends \
    curl \
    gawk \
    git-lfs \
    jq \
    yq \
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
ENV ACTIONLINT_SHA256_AMD64=023070a287cd8cccd71515fedc843f1985bf96c436b7effaecce67290e7e0757
ENV ACTIONLINT_SHA256_ARM64=401942f9c24ed71e4fe71b76c7d638f66d8633575c4016efd2977ce7c28317d0

RUN ACTIONLINT_ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
  && case "${ACTIONLINT_ARCH}" in \
    amd64) ACTIONLINT_SHA256="${ACTIONLINT_SHA256_AMD64}" ;; \
    arm64) ACTIONLINT_SHA256="${ACTIONLINT_SHA256_ARM64}" ;; \
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
  esac \
  && curl -fsSL "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_${ACTIONLINT_ARCH}.tar.gz" \
  -o /tmp/actionlint.tar.gz \
  && printf '%s  %s\n' "${ACTIONLINT_SHA256}" /tmp/actionlint.tar.gz | sha256sum -c - \
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
ENV ACT_SHA256_X86_64=0191d6f1f3b716b5c55820032605d05fc3c1cdbf581ebeff655019e5dd1524c0
ENV ACT_SHA256_ARM64=daa8679ba9615a74d2d0cec321dc593f21948a2a11bb65862b063d8b930f4bcb

RUN ACT_ARCH=$(uname -m | sed 's/aarch64/arm64/') \
  && case "${ACT_ARCH}" in \
    x86_64) ACT_SHA256="${ACT_SHA256_X86_64}" ;; \
    arm64) ACT_SHA256="${ACT_SHA256_ARM64}" ;; \
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
  esac \
  && curl -fsSL "https://github.com/nektos/act/releases/download/v${ACT_VERSION}/act_Linux_${ACT_ARCH}.tar.gz" \
  -o /tmp/act.tar.gz \
  && printf '%s  %s\n' "${ACT_SHA256}" /tmp/act.tar.gz | sha256sum -c - \
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
# To add language runtimes, add plugin metadata in .nlobby4.yml and requested
# runtime versions in .tool-versions. The Dockerfile installs whatever
# .tool-versions requires from the copied build snapshot.
# --------------------------

ENV ASDF_VERSION=0.18.1
ENV ASDF_DIR=/usr/local/asdf
ENV ASDF_DATA_DIR=/usr/local/asdf
ENV ASDF_MD5_AMD64=6c68f29f7cf16bf4a0cd2d50f464ccf0
ENV ASDF_MD5_ARM64=d3e22a5b51ab03a4770c74d9581370f1

RUN ARCH=$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') \
  && case "${ARCH}" in \
    amd64) ASDF_MD5="${ASDF_MD5_AMD64}" ;; \
    arm64) ASDF_MD5="${ASDF_MD5_ARM64}" ;; \
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;; \
  esac \
  && curl -fsSL "https://github.com/asdf-vm/asdf/releases/download/v${ASDF_VERSION}/asdf-v${ASDF_VERSION}-linux-${ARCH}.tar.gz" \
  -o /tmp/asdf.tar.gz \
  && printf '%s  %s\n' "${ASDF_MD5}" /tmp/asdf.tar.gz | md5sum -c - \
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

# --------------------------
# Install nlobby4 Orchestrator
#
# The nlobby4 orchestrator is a wrapper script that provides a unified interface
# for running commands across multiple projects in a repository. It is installed
# in /usr/local/bin so it is available to all users inside the container.
# --------------------------

COPY scripts/linux/commands/repository/orchestrator.sh /usr/local/bin/nlobby4
RUN chmod 0755 /usr/local/bin/nlobby4

# Copy orchestration inputs as a deterministic image-build snapshot
RUN mkdir -p /usr/local/share/nlobby4
COPY .nlobby4.yml /usr/local/share/nlobby4/.nlobby4.yml
COPY .tool-versions /usr/local/share/nlobby4/.tool-versions

# Provision image toolchains from the build snapshot, not the mounted workspace
RUN nlobby4 toolchain install \
  && chown -R nlobby4:nlobby4 /usr/local/asdf \
  && chmod -R 755 /usr/local/asdf
