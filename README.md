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

<h1 align="center" style="padding-bottom: 0;">

![nlobby4][logo]![banner][banner]

[![founded][founded]](https://github.com/nlobby4)
[![npm][npm]](https://www.npmjs.com/org/nlobby4)
[![website][website]](https://nlobby4.org)
[![discord][discord]](https://discord.gg/flockmod/)
[![flockmod][flockmod]](https://flockmod.com/r/nlobby4)

</h1>

<!-- ? ############################################# -->
<!-- ? Description -->
<!-- TODO: Create a short repository description -->

This repository is a bare bones template for creating clean and consistent
repositories across the entire nlobby4 codebase. It includes reusable CI
workflows, dev container configuration, commit conventions and formatting rules.

This template is intended for repositories that want to use custom tools that do
not have their own specific template.

Please check out the other
[templates](https://github.com/orgs/nlobby4/repositories?q=template%3Atrue+archived%3Afalse)
first to see if there is already a more specific template that suits your needs.

<!-- ? ############################################# -->
<!-- ? URLs -->
<!-- markdownlint-disable MD013 -->

<!-- TODO: Update the URLs below to match your repository -->

<div align="center">
  <span>ⓘ <a href="https://nlobby4.org/news/">[NEWS]</a></span>
  <span> 🖂 <a href="mailto:contact@nlobby4.org">[CONTACT]</a></span>
  <span> 🖿 <a href="https://nlobby4.github.io/workflow-template/">[DEMO]</a></span>
  <span> ★ <a href="https://github.com/nlobby4/workflow-template/issues/new?template=feature.yml">[REQUEST FEATURE]</a></span>
  <span> &#x26A0;&#xFE0E; <a href="https://github.com/nlobby4/workflow-template/issues/new?template=bug.yml">[REPORT BUG]</a></span>
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
<!-- TODO: Write your basic readme markdown here -->
<!-- TODO: Add a "back to top" button and horizontal bar for every section -->
<!-- TODO: Update the table of contents accordingly -->

## Usage

There are two ways to use this template:

### A. Copy to an Existing Repository

If you already have an existing repository, copy and paste the specific files
you need, or
[download](https://github.com/nlobby4/workflow-template/archive/refs/heads/main.zip)
the repository as a ZIP file.

> [!IMPORTANT]
>
> Do not clone this repository directly unless you intend to contribute to the
> template itself.

### B. Start a New Repository

This repository is marked as a **template**, which allows you to select it when
creating a new repository within the organization via GitHub. For external
collaborators, use the **Use this template** button at the top right of this
page.

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

## What Is Included

| Path                                  | Purpose                                                               |
| ------------------------------------- | --------------------------------------------------------------------- |
| `.devcontainer/`                      | Dev container with Node.js via asdf, pre-installed VS Code extensions |
| `.github/workflows/ci-general.yml`    | Formatting, linting, spelling, audit, knip                            |
| `.github/workflows/ci-privileged.yml` | Label automation and dependency review on pull requests               |
| `.github/workflows/ci-release.yml`    | Automated semantic versioning and GitHub release via semantic-release |
| `.github/dependabot.yml`              | Weekly dependency updates for npm and GitHub Actions                  |
| `.github/labeler.yml`                 | Automatic PR labeling by branch name, title, and changed files        |
| `.github/CODEOWNERS`                  | Code ownership definitions                                            |
| `.github/CONTRIBUTING.md`             | Contribution guidelines                                               |
| `.husky/`                             | Git hooks for commit message validation and pre-commit checks         |
| `scripts/linux/setup.sh`              | Environment setup script for local development                        |
| `scripts/linux/package/release.sh`    | Release packaging script                                              |
| `commitlint.config.js`                | Conventional Commits enforcement                                      |
| `prettier.config.js`                  | Formatting rules across all file types                                |
| `.cspell.json`                        | Spell check configuration                                             |
| `knip.json`                           | Unused dependency and export detection                                |
| `release.config.js`                   | semantic-release configuration                                        |

> [!NOTE]
>
> If you are outside the organization you can checkout the
> [readme template](https://github.com/nlobby4/readme-template) for common
> GitHub markdown files and templates. These get applied to all repositories in
> the organization by default but not outside of it.

<p align="right">[<a href="#readme-top">back to top</a>]</p>

---

## Apply These Changes

After adding the template to your project, you will have to make some minor
adjustments. The files include `TODO:` comments with instructions for easy
lookup. These comments can be removed once you have acknowledged their purpose.

The following table outlines the files you should modify and the changes you
need to make:

| File                               | Change                                                                         |
| ---------------------------------- | ------------------------------------------------------------------------------ |
| `README.md`                        | Update contents                                                                |
| `LICENSE`                          | [Choose a license](https://choosealicense.com/)                                |
| `AUTHORS`                          | Add project authors                                                            |
| `ARCHITECTURE.md`                  | Create the architecture documentation                                          |
| `.gitignore`                       | [Choose a ignore template](https://github.com/github/gitignore)                |
| `.gitattributes`                   | [Choose a attributes template](https://github.com/gitattributes/gitattributes) |
| `.github/dependabot.yml`           | Add ignore rules if needed                                                     |
| `.github/labeler.yml`              | Update label rules to match your used tooling                                  |
| `.github/CODEOWNERS`               | Add code owners                                                                |
| `.github/CONTRIBUTING.md`          | Update contribution guidelines if needed                                       |
| `.github/workflows/ci-general.yml` | Add workflows for tests and new tools if needed                                |
| `.github/workflows/ci-release.yml` | Update release workflow if needed                                              |
| `.devcontainer/Dockerfile`         | Add additional asdf plugins for your language stack                            |
| `scripts/linux/setup.sh`           | Add any project-specific setup steps                                           |
| `scripts/linux/package/release.sh` | Adjust release packaging if needed                                             |
| `.prettierignore`                  | Add file extensions that should use a different formatter                      |
| `.tool-versions`                   | Add additional tools and versions for asdf                                     |
| `.cspell.json`                     | Add project-specific words if needed                                           |
| `package.json`                     | Update values and lint-staged configuration if needed                          |
| `release.config.js`                | Update release configuration if needed                                         |

> [!TIP]
>
> You can remove the `LICENSE` file if you are setting up a private repository
> and do not plan on publishing your code.

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
