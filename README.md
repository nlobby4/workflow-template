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
[![discord][discord]](https://discord.gg/flockmod/)
[![flockmod][flockmod]](https://flockmod.com/r/nlobby4)

</h1>

<!-- ? ############################################# -->
<!-- ? Description -->

This repository is a bare bones template for creating clean and consistent
repositories across the entire nlobby4 codebase. It includes reusable CI
workflows, dev container configuration, commit conventions and formatting rules.

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
  <span> ★ <a href="../../issues/new?template=feature.yml">[REQUEST FEATURE]</a></span>
  <span> &#x26A0;&#xFE0E; <a href="../../issues/new?template=bug.yml">[REPORT BUG]</a></span>
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
specific files you need, or [download](../../archive/refs/heads/main.zip) the
repository as a ZIP file.

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

## What Is Included

| Path                                  | Purpose                                                                                                           |
| ------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| `.devcontainer/`                      | Dev container with Node.js via asdf, pre-installed VS Code extensions                                             |
| `.devcontainer/Dockerfile`            | Base image for the dev container with asdf and Node.js setup                                                      |
| `.github/workflows/ci-general.yml`    | Audit (npm), formatting (prettier), linting (markdownlint), spelling (cspell), unused dependency detection (knip) |
| `.github/workflows/ci-privileged.yml` | Label automation, dependency review, PR title linting                                                             |
| `.github/workflows/ci-release.yml`    | Release workflow with semantic versioning via semantic-release                                                    |
| `.github/workflows/ci-test.yml`       | Test workflow running the test script specified in `package.json`                                                 |
| `.github/CODEOWNERS`                  | Code ownership definitions for automatic PR review assignments                                                    |
| `.github/dependabot.yml`              | Weekly dependency updates for GitHub Actions and npm packages                                                     |
| `.github/labeler.yml`                 | Automatic PR labeling by branch name, title, and changed files                                                    |
| `.husky/`                             | Git hooks for conventional commit message linting and lint-staged                                                 |
| `scripts/linux/package/release.sh`    | Release packaging script                                                                                          |
| `scripts/linux/utils/attributes.sh`   | Git attributes verification script                                                                                |
| `scripts/linux/utils/dict.sh`         | Dictionary management script for cspell                                                                           |
| `scripts/linux/utils/utils.sh`        | Utility functions for bash scripts                                                                                |
| `scripts/linux/utils/variables.sh`    | Common variables for bash scripts                                                                                 |
| `scripts/linux/setup.sh`              | Environment setup script for local development                                                                    |
| `.cspell.json`                        | Spell check configuration                                                                                         |
| `.editorconfig`                       | Editor formatting configuration                                                                                   |
| `.markdownlint.json`                  | Markdown linting rules                                                                                            |
| `commitlint.config.js`                | Conventional commit configuration with a commitizen prompt wizard                                                 |
| `prettier.config.js`                  | Formatting rules                                                                                                  |
| `knip.json`                           | Unused dependency and export detection                                                                            |
| `release.config.js`                   | Semantic-release configuration                                                                                    |

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

## Apply These Changes

After using this template to start a new project, you will have to make some
minor adjustments. The files include `TODO:` comments with instructions for easy
lookup. These comments can be removed once you have acknowledged their purpose.

The following table outlines the files you should modify and the changes you
need to make:

| File                               | Change                                                                          |
| ---------------------------------- | ------------------------------------------------------------------------------- |
| `.devcontainer/Dockerfile`         | Add additional asdf plugins for your language stack                             |
| `.github/CODEOWNERS`               | Add code owners                                                                 |
| `.github/dependabot.yml`           | Add ignore rules if needed                                                      |
| `.github/labeler.yml`              | Update label rules to match your used tooling                                   |
| `.github/workflows/ci-general.yml` | Add jobs for new tools if needed                                                |
| `project/.gitignore`               | [Choose an ignore template](https://github.com/github/gitignore)                |
| `scripts/linux/setup.sh`           | Add any project-specific setup steps                                            |
| `.gitattributes`                   | [Choose an attributes template](https://github.com/gitattributes/gitattributes) |
| `.gitignore`                       | Whitelist new configuration files and generated folders                         |
| `.mailmap`                         | Alias your flockmod username                                                    |
| `.tool-versions`                   | Add additional tools and their versions for asdf                                |
| `AUTHORS`                          | Add project maintainers                                                         |
| `dictionary.txt`                   | Maintain a dictionary of project-specific words                                 |
| `LICENSE`                          | [Choose a license](https://choosealicense.com/)                                 |
| `package.json`                     | Update values and add scripts for new tools, tests and build                    |
| `README_TEMPLATE.md`               | Use this as the base for your own `README.md`                                   |
| `release.config.js`                | Configure npm publishing if needed                                              |

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

### Semantic Release

We are using a GitHub App for authentication in the release workflow, as
semantic-release does not work on protected branches with the default
`GITHUB_TOKEN`. For simplicity, you can either remove the release workflow, or
follow
[this guide](https://gist.github.com/fq-stong/4e75263d42846eabd55376bc70081b5c)
to setup your own GitHub App and add the necessary secrets to your repository.

> [!IMPORTANT]
>
> The provided release workflow will not work outside of the nlobby4
> organization

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
