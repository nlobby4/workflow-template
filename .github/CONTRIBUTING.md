<!-- ? ############################################# -->
<!-- ? Header -->

<h1 align="center">

![nlobby4][logo]![contributing][banner]

</h1>

<!-- ? ############################################# -->
<!-- ? Main Area -->

**Thank you for your interest in contributing!**

Please follow these guidelines to ensure a smooth contribution process:

<!-- TODO: Update the contribution guidelines if needed -->

- **Open an issue** to discuss your proposed changes before you start working on
  them. This helps us understand the scope and impact of your contribution.
- **Fork the repository** and create your feature branch from `main`, or create
  a branch directly if you have write access to the repository. Use the
  conventional branch naming format matching your commit type:
  `type/short-description`.
- **Use the dev container** during development if it is provided.
- **Use [conventional commit](https://www.conventionalcommits.org/)** messages.
  You can use `npm run commit` to help you format your commit messages
  correctly.
- **Open a pull request** with a clear description of your changes.
- **Add tests** for new features or bug fixes when possible.
- **Follow the [Code of Conduct](./CODE_OF_CONDUCT.md)**

---

## Code Quality

The following checks run automatically on pull requests to `main` and must pass:

| Check        | Tool         | Description                     |
| ------------ | ------------ | ------------------------------- |
| Formatting   | Prettier     | Code style consistency          |
| Markdown     | markdownlint | Markdown structure and style    |
| Spelling     | cspell       | Spelling across all files       |
| Commits      | commitlint   | Conventional Commits compliance |
| Dependencies | knip         | Unused dependencies and exports |
| Audit        | npm audit    | Known vulnerability scanning    |

You can run all checks locally before pushing:

```sh
npm run check
```

---

<!-- ? ############################################# -->
<!-- ? Footer -->

<div align="right">

![footer][footer]

</div>

<!-- ? ############################################# -->
<!-- ? References -->

[logo]:
  https://media.githubusercontent.com/media/nlobby4/organization/refs/heads/main/project/repo/contributing/logo-contributing.png
[banner]:
  https://media.githubusercontent.com/media/nlobby4/organization/refs/heads/main/project/repo/contributing/banner-contributing.png
[footer]:
  https://media.githubusercontent.com/media/nlobby4/organization/refs/heads/main/project/repo/contributing/footer-contributing.png
