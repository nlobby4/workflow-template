#!/usr/bin/env bash
set -euo pipefail

: "${IMAGE:?IMAGE is required}"
: "${AMD64_DIGEST:?AMD64_DIGEST is required}"
: "${ARM64_DIGEST:?ARM64_DIGEST is required}"
for platform in amd64 arm64; do
  if [[ "$platform" == amd64 ]]; then digest="$AMD64_DIGEST"; else digest="$ARM64_DIGEST"; fi
  bytes="$(docker buildx imagetools inspect --raw "$IMAGE@$digest" | jq '[.layers[].size] | add')"
  test "$bytes" -lt 2147483648
  docker run --rm --platform "linux/$platform" --entrypoint bash "$IMAGE@$digest" -lc '
    set -euo pipefail
    mise_version="$(awk -F "=" "/^min_version/ { gsub(/[ \"\r]/, \"\", \$2); print \$2 }" /usr/local/share/mise/mise.toml)"
    node_version="$(awk -F "\"" "\$1 == \"node = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    pnpm_version="$(awk -F "\"" "\$2 == \"npm:pnpm\" { print \$4 }" /usr/local/share/mise/mise.toml)"
    shellcheck_version="$(awk -F "\"" "\$1 == \"shellcheck = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    trivy_version="$(awk -F "\"" "\$1 == \"trivy = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    act_version="$(awk -F "\"" "\$1 == \"act = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    actionlint_version="$(awk -F "\"" "\$1 == \"actionlint = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    zizmor_version="$(awk -F "\"" "\$1 == \"zizmor = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    cosign_version="$(awk -F "\"" "\$1 == \"cosign = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    gitleaks_version="$(awk -F "\"" "\$1 == \"gitleaks = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    hadolint_version="$(awk -F "\"" "\$1 == \"hadolint = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    conftest_version="$(awk -F "\"" "\$1 == \"conftest = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    tombi_version="$(awk -F "\"" "\$1 == \"tombi = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    yamllint_version="$(awk -F "\"" "\$1 == \"yamllint = \" { print \$2 }" /usr/local/share/mise/mise.toml)"
    test "$(id --user nlobby4)" -ne 0
    ! runuser --user nlobby4 -- sudo --non-interactive true
    test ! -e /workspace
    test ! -e /workspaces
    test "$(node --version)" = "v$node_version"
    test "$(pnpm --version)" = "$pnpm_version"
    test "$(mise --version | awk "{ print \$1 }")" = "$mise_version"
    test "$(actionlint --version | head -n 1)" = "$actionlint_version"
    test "$(act --version)" = "act version $act_version"
    test "$(zizmor --version)" = "zizmor $zizmor_version"
    test "$(shellcheck --version | awk "/^version:/ { print \$2 }")" = "$shellcheck_version"
    test "$(trivy --version | awk "/^Version:/ { print \$2 }")" = "$trivy_version"
    test "$(cosign version --json | jq -r .gitVersion)" = "v$cosign_version"
    test "$(gitleaks version)" = "$gitleaks_version"
    test "$(hadolint --version | awk "{ print \$NF }")" = "$hadolint_version"
    test "$(conftest --version | awk "/^Conftest:/ { print \$2 }")" = "$conftest_version"
    test "$(tombi --version | awk "{ print \$2 }")" = "$tombi_version"
    test "$(yamllint --version | awk "{ print \$2 }")" = "$yamllint_version"
  '
done
