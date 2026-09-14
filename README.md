<!-- ? ############################################# -->
<!-- ? Links -->

<!--
  Shields: https://shields.io/
  Unicode: https://www.amp-what.com/
  Spaces:  https://jkorpela.fi/chars/spaces.html
-->

<!-- ? ############################################# -->
<!-- ? Header -->

<a id="readme-top"></a>

<h1 align="center">

![nlobby4][logo]![banner][banner]

[![founded][founded]](https://github.com/nlobby4)
[![npm][npm]](https://www.npmjs.com/org/nlobby4)
[![website][website]](https://nlobby4.org)
[![discord][discord]](https://discord.gg/flockmod)
[![flockmod][flockmod]](https://flockmod.com/r/nlobby4)

</h1>

<!-- ? ############################################# -->
<!-- ? Description -->

This repository is a bare bones template for creating clean and consistent
repositories across the entire nlobby4 codebase. It includes reusable CI
workflows, dev container configuration, commit conventions, formatting rules,
scripted repository checks, and Git LFS media handling.

This template is intended for repositories that want to use custom tools that do
not have their own specific template. Node is used exclusively for CI tooling
and does not constrain the language or framework of the repository itself.

Please check out the other
[templates](https://github.com/orgs/nlobby4/repositories?q=template%3Atrue+archived%3Afalse)
first to see if there is already a more specific template that suits your needs.

<!-- ? ############################################# -->
<!-- ? URLs -->
<!-- markdownlint-disable MD013 -->

<div align="center">
  <span>ⓘ <a href="https://nlobby4.org/news/">[NEWS]</a></span>
  <span> 🖂 <a href="mailto:contact@nlobby4.org">[CONTACT]</a></span>
  <span> ★ <a href="https://github.com/nlobby4/workflow-template/issues/new?template=feature.yml">[REQUEST FEATURE]</a></span>
  <span> &#x26A0;&#xFE0E; <a href="https://github.com/nlobby4/workflow-template/issues/new?template=bug.yml">[REPORT BUG]</a></span>
</div>

<br>

<!-- markdownlint-enable MD013 -->
<!-- ? ############################################# -->
<!-- ? Table of Contents -->

<details>
  <summary>Table of Contents</summary>

  <ol>
    <li>
      <a href="#usage">Usage</a>
      <ul>
        <li><a href="#a-copy-to-an-existing-repository">A. Copy to an Existing Repository</a></li>
        <li><a href="#b-start-a-new-repository">B. Start a New Repository</a></li>
      </ul>
    </li>
    <li><a href="#dev-container">Dev Container</a></li>
    <li><a href="#what-is-included">What Is Included</a></li>
    <li><a href="#apply-these-changes">Apply These Changes</a></li>
    <li><a href="#for-outside-collaborators">For Outside Collaborators</a></li>
  </ol>

</details>

<!-- ? ############################################# -->
<!-- ? Main Area -->

## Usage

There are two ways to use this template:

### A. Copy to an Existing Repository

If you already have an existing repository, you can easily copy and paste the
specific files you need, or
[download](https://github.com/nlobby4/workflow-template/archive/refs/heads/main.zip)
the repository as a ZIP file.

### B. Start a New Repository

This repository is marked as a **template**, which allows you to select it when
creating a new repository within the organization via GitHub. For external
collaborators, use the **Use this template** button at the top right of this
page.

> [!IMPORTANT]
>
> Do not clone this repository directly unless you intend to contribute to the
> template itself.

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

## Development Setup

The recommended local setup path uses mise as the tool and task entry point:

```sh
mise trust
mise install --locked
mise run setup
```

The setup task installs the locked pnpm dependencies, configures the
repository-local Git settings, initializes Git LFS, restores executable bits,
and installs the Husky hooks.

To bypass mise task orchestration, install the tools declared in `mise.toml`
with your preferred method, install the dependencies, and invoke the setup
script directly:

```sh
pnpm install --frozen-lockfile --ignore-scripts
./scripts/linux/commands/repository/setup.sh
```

To configure only the Git integrations without running the setup script, use
their equivalent manual commands:

```sh
git config --local blame.ignoreRevsFile .git-blame-ignore-revs
git config --local commit.template .gitmessage
git lfs install --local
git lfs pull
```

The manual path must be repeated when the corresponding toolchain, dependencies,
or repository-local configuration changes.

Security and configuration checks are available through stable tasks:

```sh
mise run lint:secrets
mise run lint:secrets:staged
mise run lint:dockerfile
mise run lint:policy
mise run lint:toml
mise run lint:yaml
mise run devcontainer:sign
mise run devcontainer:verify
```

The equivalent `pnpm run` commands are also supported. Tasks prefixed with `ci:`
are internal workflow interfaces and may change with the workflows.

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

## Dev Container

The repository includes a Dev Container for local development. It provisions the
shared toolchain during the image build, installs root Node.js dependencies when
workspace content is available, runs repository and project setup when the
container is created, and runs `mise run doctor` when it starts.

### VS Code

Install the
[Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers),
open this repository in VS Code, and run **Dev Containers: Reopen in Container**
from the command palette.

To apply personal dotfiles, configure them in your VS Code user settings before
creating or rebuilding the container:

```json
{
  "dotfiles.installCommand": "install.sh",
  "dotfiles.repository": "your-github-id/your-dotfiles-repo",
  "dotfiles.targetPath": "~/dotfiles"
}
```

The Dev Containers extension clones that repository into the container and runs
the install command when the container is created. Keep dotfiles in user
settings rather than `.devcontainer/devcontainer.json`, because shell aliases,
Git identity, editor preferences, and prompt configuration are personal
customizations rather than project requirements.

### Dev Container CLI

Install the Dev Container CLI globally on your machine:

```sh
npm install -g @devcontainers/cli
```

Start the container:

```sh
devcontainer up --workspace-folder .
```

Start the container with personal dotfiles:

```sh
devcontainer up \
  --workspace-folder . \
  --dotfiles-repository https://github.com/your-github-id/your-dotfiles-repo.git \
  --dotfiles-target-path ~/dotfiles \
  --dotfiles-install-command install.sh
```

Unlike the VS Code Dev Containers extension, direct `devcontainer-cli` usage
does not automatically copy your local Git identity into the container. If you
use the CLI, make sure your dotfiles install script creates a usable
`~/.gitconfig`, or configure Git after the container starts:

```sh
devcontainer exec --workspace-folder . git config --global user.name "Your Name"
devcontainer exec --workspace-folder . git config --global user.email "you@example.com"
```

Rebuild the container from scratch:

```sh
devcontainer up --workspace-folder . --remove-existing-container --build-no-cache
```

Run a command inside the container:

```sh
devcontainer exec --workspace-folder . nlobby4 doctor
```

The Dev Container CLI is managed through `mise.toml` rather than installed as a
repository package. Running `mise install --locked` makes the pinned CLI
available for host-side `devcontainer:*` tasks. VS Code users can instead use
the Dev Containers extension directly.

For more information, see the
[VS Code Dev Containers dotfiles documentation](https://code.visualstudio.com/docs/devcontainers/containers#_personalizing-with-dotfile-repositories)
and the
[Dev Container CLI documentation](https://code.visualstudio.com/docs/devcontainers/devcontainer-cli).

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

## Markdown Authoring

The repository validates Markdown with markdownlint-cli2 and a custom GitHub
HTML compatibility rule. The rule reports unsupported raw HTML elements,
attributes, and URL protocols while preserving supported HTML and GFM syntax.
The same configuration is loaded by the VS Code markdownlint extension and CI.

Run style and compatibility validation:

```sh
pnpm run lint:md
```

Run the cmark-gfm conformance smoke test:

```sh
pnpm run lint:md:gfm
```

For fast offline preview, install the recommended VS Code extensions and run
**Markdown: Open Preview to the Side**. The built-in preview is styled with the
GitHub light or dark theme but remains a local approximation.

For a high-fidelity, live-reloading preview, install the GitHub CLI extension:

```sh
gh extension install yusukebe/gh-markdown-preview
pnpm run docs:preview:github -- README.md
```

The high-fidelity preview renders GFM through GitHub's Markdown API and
therefore requires network access. GitHub CLI extensions are third-party code;
review and trust the extension before installation.

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

## What Is Included

| Path                                                | Purpose                                                                                                                                               |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| `.nlobby4.yml`                                      | Central wrapper configuration for workspace defaults, toolchains, capabilities, implementations, and policy                                           |
| `.devcontainer/`                                    | Source-built dev container with system mise tools, Docker-in-Docker, VS Code extensions, and lifecycle health checks                                  |
| `.devcontainer/Dockerfile`                          | Reproducible dev-container image with system mise tools and pinned Debian inputs                                                                      |
| `scripts/linux/commands/repository/orchestrator.sh` | Source script installed as the `nlobby4` CLI inside the dev container; separates build-time toolchain provisioning from runtime project orchestration |
| `.github/workflows/ci-general.yml`                  | Root audit, formatting, schema, JavaScript, YAML, TOML, Markdown, shell, policy, spelling, and unused-dependency checks                               |
| `.github/workflows/pr-automation.yml`               | Label automation, dependency review, PR title linting                                                                                                 |
| `.github/workflows/ci-test.yml`                     | Test workflow running the test script specified in `package.json`                                                                                     |
| `.github/CODEOWNERS`                                | Code ownership definitions for automatic PR review assignments                                                                                        |
| `.github/dependabot.yml`                            | Weekly dependency updates for GitHub Actions and npm packages                                                                                         |
| `.github/labeler.yml`                               | Automatic PR labeling by branch name, title, and changed files                                                                                        |
| `.husky/`                                           | Git hooks for conventional commit message linting and lint-staged                                                                                     |
| `media/`                                            | Repository-owned media assets; binary assets are tracked with Git LFS, Markdown and SVG remain normal text files                                      |
| `scripts/linux/commands/repository/health.sh`       | Repository health check run by the dev container on startup                                                                                           |
| `scripts/linux/commands/repository/setup.sh`        | Environment setup script for local development                                                                                                        |
| `scripts/linux/commands/validation/attributes.sh`   | Git attributes verification script                                                                                                                    |
| `scripts/linux/commands/validation/dict.sh`         | Dictionary management script for cspell                                                                                                               |
| `scripts/linux/commands/validation/lfs.sh`          | Git LFS verification script for media attributes and pointer consistency                                                                              |
| `scripts/linux/commands/validation/shell.sh`        | Shell script linting wrapper for ShellCheck                                                                                                           |
| `scripts/linux/commands/meta/git-status.sh`         | Git configuration and remote status advisory script                                                                                                   |
| `scripts/linux/commands/meta/workspace-status.sh`   | Workspace context and dependency advisory script                                                                                                      |
| `scripts/linux/commands/misc/branding.sh`           | Startup branding output                                                                                                                               |
| `scripts/linux/commands/tests/smoke.sh`             | Optional smoke test for projects that build ESM or CJS output into `dist/`                                                                            |
| `scripts/linux/utils/functions.sh`                  | Utility functions for bash scripts                                                                                                                    |
| `.cspell.json`                                      | Spell check configuration                                                                                                                             |
| `.editorconfig`                                     | Editor formatting configuration                                                                                                                       |
| `.gitattributes`                                    | Line ending, diff, and Git LFS rules                                                                                                                  |
| `.markdownlint-cli2.jsonc`                          | Markdown rules, file discovery, exclusions, and custom-rule loading                                                                                   |
| `.yamllint.yaml`                                    | Generic YAML correctness and style rules compatible with Prettier and GitHub Actions                                                                  |
| `eslint.config.js`                                  | ESLint flat configuration scoped to repository-owned JavaScript automation                                                                            |
| `scripts/node/markdownlint/`                        | GitHub-compatible raw HTML policy and author-time markdownlint rule                                                                                   |
| `.shellcheckrc`                                     | Shared ShellCheck configuration used by CI, local scripts, and editor integrations                                                                    |
| `commitlint.config.js`                              | Conventional commit configuration with a commitizen prompt wizard                                                                                     |
| `prettier.config.js`                                | Formatting rules                                                                                                                                      |
| `knip.json`                                         | Unused dependency and export detection                                                                                                                |
| `project/semantic-release-example/`                 | Example wrapped project that owns semantic-release configuration and release packaging                                                                |

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

## Orchestration Boundary

The `nlobby4` CLI keeps image-build concerns separate from mounted workspace
concerns:

| Phase             | Command                     | Source of truth                                        |
| ----------------- | --------------------------- | ------------------------------------------------------ |
| Docker build      | `nlobby4 toolchain install` | Snapshot copied to `/usr/local/share/nlobby4`          |
| Container create  | `nlobby4 repository setup`  | Live mounted workspace                                 |
| Container create  | `nlobby4 project setup`     | Project compatibility gates                            |
| Container start   | `nlobby4 doctor`            | Live mounted workspace                                 |
| CI or development | `nlobby4 check <task>`      | Live mounted workspace and project compatibility gates |

Toolchain commands intentionally default to the copied build snapshot. They do
not switch to the mounted repository just because one is present. This keeps
Docker layer caching deterministic; workspace-based toolchain provisioning must
be requested explicitly with environment overrides.

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

## Apply These Changes

After using this template to start a new project, you will have to make some
minor adjustments. The files include `TODO:` comments with instructions for easy
lookup. These comments can be removed once you have acknowledged their purpose.

The following table outlines the files you should modify and the changes you
need to make:

| File                               | Change                                                                                      |
| ---------------------------------- | ------------------------------------------------------------------------------------------- |
| `.nlobby4.yml`                     | Add workspace defaults, capabilities, implementations, policy, and asdf plugin repositories |
| `project/<name>/.nlobby4.yml`      | Add project-specific setup, check, build, audit, and release command wiring                 |
| `.github/CODEOWNERS`               | Add code owners                                                                             |
| `.github/dependabot.yml`           | Add additional package ecosystems as needed                                                 |
| `.github/labeler.yml`              | Update label rules to match your used tooling                                               |
| `.github/workflows/ci-general.yml` | Add jobs for new tools if needed                                                            |
| `project/.gitignore`               | [Choose an ignore template](https://github.com/github/gitignore)                            |
| `.gitattributes`                   | [Choose an attributes template](https://github.com/gitattributes/gitattributes)             |
| `.gitignore`                       | Whitelist new configuration files and generated folders                                     |
| `.mailmap`                         | Alias your flockmod username                                                                |
| `mise.toml`                        | Add tools, versions, and developer-facing tasks for mise                                    |
| `mise.lock`                        | Lock mise-managed tool downloads and checksums                                              |
| `AUTHORS`                          | Add project maintainers                                                                     |
| `dictionary.txt`                   | Maintain a dictionary of project-specific words                                             |
| `LICENSE`                          | [Choose a license](https://choosealicense.com/)                                             |
| `package.json`                     | Update values and add scripts for new tools, tests and build                                |
| `pnpm-lock.yaml`                   | Update locked dependencies with pnpm                                                        |
| `README_TEMPLATE.md`               | Use this as the base for your own `README.md`                                               |
| `project/<name>/release.config.js` | Add project-owned semantic-release configuration only for projects that need it             |

> [!NOTE]
>
> The community markdown files and PR/issue templates are provided by the
> organizations [.github](https://github.com/nlobby4/.github) repository. If you
> need to adjust them, copy the respective file into the `.github` directory and
> make the necessary changes.

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

## For Outside Users

### Labeler

Ensure your repository has the following labels defined, as they are used by the
automated labeler and referenced in issue and PR templates. You can set these up
in the repositories issue tab:

`feat` `fix` `docs` `chore` `ci` `build` `refactor` `perf` `test` `style`
`revert` `breaking-change` `dependencies` `release`

### Releases

Release management is intentionally project-owned. The root wrapper keeps shared
commit conventions and can delegate a `release` command through a project-local
`.nlobby4.yml`, but semantic-release, Changesets, GoReleaser, Maven release
plugins, or other release tools should live inside the wrapped project that
needs them.

See `project/semantic-release-example/` for a project-local semantic-release
example.

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

<!-- ? ############################################# -->
<!-- ? Footer -->

<div align="right">

![footer][footer]

</div>

<!-- ? ############################################# -->
<!-- ? References -->

[logo]:
  https://media.githubusercontent.com/media/nlobby4/organization/refs/heads/main/project/repo/readme/logo-readme.png
[banner]:
  https://media.githubusercontent.com/media/nlobby4/organization/refs/heads/main/project/repo/readme/banner-readme.png
[footer]:
  https://media.githubusercontent.com/media/nlobby4/organization/refs/heads/main/project/repo/readme/footer-readme.png
[founded]: https://img.shields.io/badge/founded:2024-black?logo=github
[npm]: https://img.shields.io/badge/npm%20packages-black?logo=npm&color=000000
[website]:
  https://img.shields.io/badge/nlobby4.org-black?logo=firefoxbrowser&logoColor=white&color=000000
[discord]:
  https://img.shields.io/badge/discord-black?logo=discord&logoColor=white
[flockmod]: https://img.shields.io/badge/r/nlobby4-black
