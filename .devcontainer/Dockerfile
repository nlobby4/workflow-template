# --------------------------------------------------
# Dockerfile for the development container.
#
# This Dockerfile defines the development environment.
# It is based on Micros*ft's official Dev Containers base image for Debian
# Bookworm and extends it with additional tools and configuration to ensure
# consistency across local development environments.
#
# The multi-architecture Dockerfile BuildKit frontend is pinned by digest while
# retaining its major tag as a human-readable update channel. Review and refresh
# the tag and digest together when updating the BuildKit frontend.
#
# The development container provisions tools during its image build and runs
# repository setup automatically when it is created. For the equivalent
# managed local path, install mise and run:
#
# mise trust
# mise install --locked
# mise run setup
#
# To invoke the underlying repository setup script directly instead of the
# mise task, run:
#
# bash scripts/linux/commands/repository/setup.sh
#
# For more information, see:
# https://mise.jdx.dev/
# https://github.com/devcontainers/images
# https://containers.dev/supporting
# --------------------------------------------------

# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32

# --------------------------
# Base Image
# --------------------------

# Use the Micros*ft Dev Containers Debian Bookworm image. The complete tag and
# immutable OCI index digest are owned by this FROM instruction so Docker
# tooling and Dependabot can detect and update the dependency directly.
FROM mcr.microsoft.com/devcontainers/base:bookworm@sha256:86165cfc170e9b2aa8df90b847127eea97b08eb9987021e6e6ec6c3a96545d7c

ARG TARGETARCH

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV PATH="/home/nlobby4/.local/share/mise/shims:/usr/local/share/mise/shims:${PATH}"

# Copy the canonical version manifest before its dependent layers.
# Update versions when their corresponding dependencies change.
COPY .devcontainer/versions.env /usr/local/share/devcontainer/versions.env

# Remove every inherited APT source before configuring the dated Debian snapshot,
# so future base-image sources cannot remain enabled accidentally.
RUN . /usr/local/share/devcontainer/versions.env \
  && rm -f \
    /etc/apt/sources.list \
    /etc/apt/sources.list.d/*.list \
    /etc/apt/sources.list.d/*.sources \
  && printf '%s\n' \
    'Types: deb' \
    "URIs: https://snapshot.debian.org/archive/debian/${DEBIAN_SNAPSHOT}" \
    'Suites: bookworm bookworm-updates' \
    'Components: main' \
    'Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg' \
    'Check-Valid-Until: no' \
    '' \
    'Types: deb' \
    "URIs: https://snapshot.debian.org/archive/debian-security/${DEBIAN_SNAPSHOT}" \
    'Suites: bookworm-security' \
    'Components: main' \
    'Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg' \
    'Check-Valid-Until: no' \
    > /etc/apt/sources.list.d/debian.sources

# Rename the default user while preserving its UID and home ownership.
# Remove inherited sudo membership and policy;
# Image provisioning remains build-time.
RUN groupmod --new-name nlobby4 vscode \
  && usermod --login nlobby4 --home /home/nlobby4 --move-home vscode \
  && if id -nG nlobby4 | grep -qw sudo; then gpasswd --delete nlobby4 sudo; fi \
  && rm -f /etc/sudoers.d/vscode /etc/sudoers.d/nlobby4 \
  && mkdir -p /home/nlobby4/.cache /home/nlobby4/.local/share/pnpm/store \
  && chown -R nlobby4:nlobby4 /home/nlobby4/.cache /home/nlobby4/.local

# Install direct Debian dependencies at exact versions from the dated snapshot.
# Transitive packages are resolved from the same immutable package index.
RUN . /usr/local/share/devcontainer/versions.env \
  && DEBIAN_FRONTEND=noninteractive apt-get update \
  && apt-get -y install --no-install-recommends \
    cmark-gfm="${CMARK_GFM_VERSION}" curl="${CURL_VERSION}" \
    gawk="${GAWK_VERSION}" git-lfs="${GIT_LFS_VERSION}" \
    jq="${JQ_VERSION}" yq="${YQ_VERSION}" \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# --------------------------
# Install mise
#
# mise manages runtime versions and repository tasks. System installations make
# the image-provided tools available to every user while keeping user-managed
# tool installations separate.
#
# mise.toml and mise.lock own the tools installed through mise.
#
# The bootstrap version is stored in versions.env, and checksums.sha256
# authenticates the amd64 and arm64 binaries.
# --------------------------

COPY .devcontainer/checksums.sha256 /usr/local/share/devcontainer/checksums.sha256

RUN . /usr/local/share/devcontainer/versions.env \
  && case "${TARGETARCH}" in \
  amd64) MISE_ARCH=x64 ;; \
  arm64) MISE_ARCH=arm64 ;; \
  *) echo "Unsupported target architecture: ${TARGETARCH}" >&2; exit 1 ;; \
  esac \
  && MISE_ASSET="mise-v${MISE_VERSION}-linux-${MISE_ARCH}" \
  && curl --fail --location --show-error --silent --retry 5 \
  --retry-all-errors --connect-timeout 15 --max-time 300 \
  "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/${MISE_ASSET}" \
  -o "/tmp/${MISE_ASSET}" \
  && MISE_SHA256="$(awk -v asset="${MISE_ASSET}" '$2 == asset { print $1 }' /usr/local/share/devcontainer/checksums.sha256)" \
  && test -n "${MISE_SHA256}" \
  && printf '%s  %s\n' "${MISE_SHA256}" "/tmp/${MISE_ASSET}" \
  | sha256sum --check --strict - \
  && install -m 0755 "/tmp/${MISE_ASSET}" /usr/local/bin/mise \
  && rm "/tmp/${MISE_ASSET}"

# Provision system toolchains from the locked mise configuration copied into the
# image. mise automatically discovers /usr/local/share/mise/installs at runtime.
COPY mise.toml /usr/local/share/mise/mise.toml
COPY mise.lock /usr/local/share/mise/mise.lock

RUN --mount=type=cache,target=/root/.cache/mise,sharing=locked \
  mise trust /usr/local/share/mise/mise.toml \
  && mise --cd /usr/local/share/mise install --system --locked \
  && chmod -R u=rwX,go=rX /usr/local/share/mise
