/**
 * Semantic release is installed in the CI environment with a pinned version as
 * it is not truly a dev dependency, local installation is discouraged.
 *
 * **Release Process:**
 *
 * 1. Create a new branch from main (or alpha/beta for pre-releases).
 * 2. Make commits using conventional commit messages by running `npm run commit`.
 * 3. Push your branch to the remote repository.
 * 4. Open a pull request to merge your branch.
 * 5. CI runs on the pull request to verify code quality and tests.
 * 6. After approval, merge the pull request into the target branch.
 * 7. CI runs on the target branch and triggers semantic-release.
 * 8. Semantic-release analyzes commits, determines the next version, updates the
 *    changelog, packages the project, bumps the version, creates a git tag, and
 *    publishes the release to the targets.
 *
 * **Branches:**
 *
 * - Main: regular releases.
 * - Beta: pre-releases (e.g. 1.0.0-beta.1)
 * - Alpha: pre-releases (e.g. 1.0.0-alpha.1)
 *
 * **Commit Types and Release Triggers:**
 *
 * The conventionalcommits preset is used so that release rules and changelog
 * sections can be configured explicitly. The following types trigger a
 * release:
 *
 * - Feat: minor — a new feature.
 * - Fix: patch — a bug fix.
 * - Perf: patch — a performance improvement.
 *
 * Breaking changes (BREAKING CHANGE footer or ! suffix) always trigger a major
 * release regardless of type.
 *
 * Types not listed above (chore, docs, style, refactor, test, ci, build) do not
 * trigger a release and are hidden from the changelog by default.
 *
 * @file Semantic release configuration file.
 *
 * @author sphoon
 */

/** @see https://semantic-release.gitbook.io/semantic-release/usage/configuration */
export default {
  // Branches on which releases are triggered
  branches: [
    "main",
    { name: "beta", prerelease: true },
    { name: "alpha", prerelease: true },
  ],
  // Order of plugins to run during the release process
  plugins: [
    // Analyze commit messages to determine the next version.
    // Uses the conventionalcommits preset so that release rules can be
    // configured explicitly. Rules are evaluated top-to-bottom; the first
    // match wins. Breaking changes always produce a major bump regardless
    // of the matched rule.
    [
      "@semantic-release/commit-analyzer",
      {
        preset: "conventionalcommits",
        releaseRules: [
          { type: "feat", release: "minor" },
          { type: "fix", release: "patch" },
          { type: "perf", release: "patch" },
        ],
      },
    ],
    // Generate release notes based on commits since the last release.
    // Uses the conventionalcommits preset with an explicit types list so
    // that noise types (chore, docs, etc.) are hidden from the changelog.
    [
      "@semantic-release/release-notes-generator",
      {
        preset: "conventionalcommits",
        presetConfig: {
          types: [
            { type: "feat", section: "Features", hidden: false },
            { type: "fix", section: "Bug Fixes", hidden: false },
            { type: "perf", section: "Performance", hidden: false },
            { type: "chore", section: "Chores", hidden: true },
            { type: "docs", section: "Documentation", hidden: true },
            { type: "style", section: "Styles", hidden: true },
            { type: "refactor", section: "Refactoring", hidden: true },
            { type: "test", section: "Tests", hidden: true },
            { type: "ci", section: "CI", hidden: true },
            { type: "build", section: "Build", hidden: true },
          ],
        },
      },
    ],
    // Bump version in package.json and package-lock.json.
    // TODO: set npmPublish true if you want to publish to npm registry.
    ["@semantic-release/npm", { npmPublish: false }],
    // Package the project for distribution by creating a tar.gz archive of
    // the entire project (excluding ignored files). The next release version
    // is passed as the first argument to the script.
    [
      "@semantic-release/exec",
      {
        prepareCmd:
          "bash scripts/linux/package/release.sh ${nextRelease.version}",
      },
    ],
    // Update the changelog file with the new release notes
    ["@semantic-release/changelog", { changelogFile: "CHANGELOG.md" }],
    // Commit changelog, bumped package.json and lockfile, then create git tag
    [
      "@semantic-release/git",
      {
        assets: ["CHANGELOG.md", "package.json", "package-lock.json"],
        message:
          "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}",
      },
    ],
    // Create a GitHub release and upload the packaged project as a release asset
    [
      "@semantic-release/github",
      {
        assets: [
          {
            path: "release/project-dist-v${nextRelease.version}.tar.gz",
            label: "project-dist-v${nextRelease.version}.tar.gz",
          },
        ],
      },
    ],
  ],
};
