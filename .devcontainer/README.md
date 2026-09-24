# Development container

This repository builds its development container from source and publishes the
same reviewed configuration as a signed, multi-architecture GHCR image. Local
development does not depend on the published image.

The setup is intended for trusted repositories on single-user development
systems. It has been validated with Hadolint, BuildKit checks, and the complete
Docker-backed smoke test.

## Security boundary

The container uses Docker-in-Docker with dedicated daemon-storage volumes. It
does not mount the host Docker socket, so workspace processes cannot ask the
host daemon to create privileged containers or mount arbitrary host paths.

Docker-in-Docker requires a privileged outer container and is not a hard kernel
security boundary. Run untrusted repositories and contributions in a disposable
VM, Codespace, or equivalent host-level sandbox.

Daily development runs as the non-root `nlobby4` user. The inherited sudo policy
is removed, and operating-system provisioning happens only during the reviewed
image build. Repository dependency installation uses `--ignore-scripts` to
reduce lifecycle-script risk.

## Configuration ownership

| Dependency                                                                                                                          | Canonical owner                                  | Update mechanism                   |
| ----------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ | ---------------------------------- |
| Node.js, pnpm, Dev Container CLI, ShellCheck, Trivy, Act, Actionlint, Zizmor, Cosign, Gitleaks, Hadolint, Conftest, Tombi, yamllint | `mise.toml` and `mise.lock`                      | Renovate or reviewed mise update   |
| JavaScript packages                                                                                                                 | `package.json` and `pnpm-lock.yaml`              | Renovate or pnpm                   |
| Docker-in-Docker Feature, Docker, and Buildx                                                                                        | `devcontainer.json` and `devcontainer-lock.json` | Renovate and Dev Container CLI     |
| Base image                                                                                                                          | Dockerfile `FROM`                                | Renovate Dockerfile manager        |
| Dockerfile frontend                                                                                                                 | Dockerfile `# syntax` directive                  | Renovate or reviewed digest update |
| Debian snapshot and packages                                                                                                        | `versions.env`                                   | Reviewed update                    |
| Direct-download checksums                                                                                                           | `checksums.sha256`                               | Reviewed upstream hashes           |
| GitHub Actions and service images                                                                                                   | Workflow declarations                            | Renovate                           |

The Dockerfile directly downloads only the mise bootstrap binary. Repository
tools, including Act, Actionlint, and Zizmor, are installed with
`mise install --system --locked` from `mise.toml` and checksum-locked in
`mise.lock`.

System tools live under `/usr/local/share/mise/installs`, outside user home
directories. Mise discovers them automatically, including when a Dev Container
client mounts a home directory. Developers can install additional versions in
their normal user mise directory without changing the image-provided
installation globally. User shims precede system shims on `PATH`, so a developer
can intentionally override an image-provided tool for their account. Mise and
its embedded npm backend use a locked BuildKit cache mount while installing; the
completed system tool installations are self-contained, so disposable download
and package-store data is not retained in the final image.

The mise bootstrap selects its binary from BuildKit's target-platform argument,
so multi-platform builds follow the requested image architecture rather than the
architecture reported by the build executor.

User and system mise shims are on `PATH`, so tools work consistently in
interactive shells, login shells, CI processes, and editor integrations without
modifying global shell initialization files.

## Project ownership boundary

The root Dev Container provides the shared repository, CI, security, and
Docker-in-Docker toolchain. Root ESLint validates only this template's own
JavaScript automation. Projects under `project/` still own their ecosystem and
application dependencies, including their own ESLint configuration when needed.

A project may also contain its own Dockerfile when its build or runtime warrants
one. That Dockerfile is built and exercised through the root container's
isolated Docker-in-Docker daemon; it does not extend the root Dev Container by
default. This keeps dependency and image management at the narrowest applicable
project layer.

## Docker and Compose

The official Docker-in-Docker Feature owns the inner Docker installation. Its
`dockerDashComposeVersion: "none"` option disables the separate legacy
`docker-compose` download. The selected Moby path still installs the Compose v2
plugin, which is verified against the isolated inner daemon by the smoke test.

The Feature-controlled Moby and Compose package boundary is intentionally
accepted. Docker and Buildx remain explicitly pinned, and completed images are
scanned in CI.

## Persistent state and resources

The pnpm store uses a volume whose name contains `${devcontainerId}`. The name
is stable for a workspace and distinct across separate clones and working trees,
so their package caches and cleanup ownership do not collide.

Docker-in-Docker has separate persistent volumes for its daemon state. These
volumes and the pnpm store are disposable caches, not backups. Remove this
workspace's container, image, volumes, and repository cache with:

```bash
mise run devcontainer:clear
```

The container does not enforce CPU or memory limits. `hostRequirements` records
recommended capacity only, and an init process handles signal forwarding and
zombie reaping.

## Lifecycle

On creation, the Dev Container CLI:

1. builds the Dockerfile;
2. applies the integrity-locked Docker-in-Docker Feature;
3. starts the isolated Docker daemon;
4. mounts the workspace and workspace-specific pnpm store;
5. trusts the repository mise configuration; and
6. runs `mise run setup`.

On every start, `container-start.sh` waits for the inner Docker daemon and then
runs `mise run doctor`.

## Commands

Use mise as the stable developer interface:

```bash
mise run devcontainer:up
mise run devcontainer:rebuild
mise run devcontainer:clear
mise run devcontainer:shell
mise run devcontainer:doctor
mise run devcontainer:scan
mise run devcontainer:sign
mise run devcontainer:verify
mise run lint:secrets
mise run lint:secrets:staged
mise run lint:dockerfile
mise run lint:policy
mise run lint:toml
mise run lint:yaml
mise run test:devcontainer
```

Equivalent `pnpm run` commands remain available. The `ci:*` package tasks are
internal workflow interfaces rather than developer APIs.

### Validation scope

- `lint:secrets` scans complete reachable Git history with redacted findings.
- `lint:secrets:staged` scans staged changes before `lint-staged`.
- `lint:dockerfile` runs warning-level Hadolint checks against the real
  Dockerfile and verifies valid and deliberately invalid fixtures.
- `lint:policy` applies Conftest policies to live configuration and fixtures.
- `lint:toml` runs Tombi against `mise.toml` and validates mise task
  definitions.
- `lint:yaml` runs strict yamllint checks against root-owned YAML files.
- `lint:js` runs ESLint against root-owned JavaScript automation.
- `devcontainer:scan` performs vulnerability, secret, and SBOM analysis.
- `test:devcontainer` performs a clean build and complete runtime smoke test.

Conftest requires a non-root remote user, init, no host Docker socket mount,
locked Feature versions from approved registries, digest-pinned workflow service
images, least-privilege workflow permissions, and immutable external action
references. Organizational software-license policy is intentionally separate.

## Updating dependencies

### mise-managed tools

1. Update `mise.toml`.
2. Run `mise lock`.
3. Review the platform URLs, checksums, and provenance in `mise.lock`.
4. Run the repository checks and `mise run test:devcontainer`.

Renovate has a native mise manager and can propose tool updates. Lockfile
regeneration requires a Renovate execution environment that is permitted to run
mise safely. The mise bootstrap version in `versions.env` is separate and needs
a custom Renovate rule or reviewed manual update together with both architecture
checksums.

### Dockerfile inputs

1. Update the Debian snapshot or package version in `versions.env`.
2. When updating mise itself, obtain the official AMD64 and ARM64 hashes.
3. Update `checksums.sha256` using canonical `sha256sum` formatting.
4. Review base-image and Dockerfile-frontend digest changes.
5. Run `pnpm run lint:devcontainer`, `mise run lint:dockerfile`, and
   `mise run test:devcontainer`.

Never accept an unknown checksum merely to make validation pass.

Direct Debian packages remain exactly versioned against the dated snapshot, but
the Dockerfile does not allow package downgrades. If the pinned base image is
newer than the selected snapshot packages, the build fails and the two inputs
must be reviewed together.

### Dev Container Feature

1. Update the Feature or its options in `devcontainer.json`.
2. Run `devcontainer upgrade --workspace-folder .`.
3. Review `devcontainer-lock.json`.
4. Run the clean smoke test.

CI uses the frozen Feature lockfile, so validation cannot silently accept a
resolution that has not been reviewed.

## CI and publication

General CI installs only the tools needed by each job. Workflow `run` steps call
repository-owned pnpm tasks; pinned actions remain responsible for GitHub-hosted
operations such as checkout, caching, authentication, attestations, and artifact
transfer.

The Dev Container workflow performs:

1. native AMD64 and ARM64 builds and smoke tests;
2. Dockerfile build-policy checks;
3. candidate image builds and registry publication;
4. vulnerability and secret scans;
5. per-platform runtime and compressed-size verification;
6. SPDX JSON SBOM generation;
7. promotion to a commit tag;
8. provenance and SBOM attestations; and
9. keyless Cosign signing and verification.

## Smoke-test coverage

The disposable-container smoke test verifies:

- an uncached image build and lifecycle setup;
- exact mise-managed tool versions, including Tombi and yamllint;
- non-root execution and unavailable sudo;
- absence of the host Docker socket;
- inner-Docker and Compose operation;
- init and volume configuration;
- workspace-specific pnpm volume naming;
- container restart behavior;
- offline pnpm restoration; and
- cleanup of disposable resources.

## Next steps

The Dockerfile is complete for its current responsibilities. Planned maintenance
and optional architectural improvements are:

1. Configure Renovate for mise tool updates and reviewed `mise.lock`
   regeneration.
2. Automate reviewed updates of the mise bootstrap version and its AMD64/ARM64
   checksums.
3. Keep the base-image and Dockerfile-frontend digests current through Renovate
   or another reviewed update workflow.
4. Complete native AMD64 and ARM64 CI publication testing in the target
   registry.
5. Promote the exact native smoke-tested platform images instead of rebuilding
   them for publication.
6. Offer an optional consumer configuration pinned to a signed GHCR image digest
   while retaining this source-build configuration for image development.
7. Monitor image size and persistent cache growth as the monorepo expands.
8. Add inexpensive version and Docker-isolation assertions to `mise run doctor`;
   keep destructive and clean-build assertions in the smoke test.

No internal-mirror or upstream-outage-resilience work is planned. Clean builds
are expected to use the normal upstream registries and package services.

Docker-in-Docker remains the accepted implementation for trusted development
workloads. Its privileged outer-container requirement is documented rather than
tracked as a defect.
