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
 * 5. CI runs on the pull request to verify code quality.
 * 6. On merge your changes are squashed and the PR title is turned into the commit
 *    message that will be used in the next release changelog.
 * 7. Trigger the CI Release workflow manually (workflow_dispatch) on the target
 *    branch (main/beta/alpha) after accumulating commits for the release.
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
 * **Commit Types and Version Triggers:**
 *
 * The conventionalcommits preset is used so that release rules and changelog
 * sections can be configured explicitly. The following commit types are used to
 * determine the version bump and included in the changelog.
 *
 * - Breaking change: major - a breaking API change.
 * - Feat: minor - a new feature.
 * - Fix: patch - a bug fix.
 * - Perf: patch - a performance improvement.
 *
 * Breaking changes (BREAKING CHANGE footer or ! suffix) always trigger a major
 * release regardless of type.
 *
 * Types not listed above (chore, docs, style, refactor, test, ci, build) are
 * hidden from the changelog.
 *
 * **Publishing to npm**
 *
 * Before this workflow can publish to the npm registry, a one-time setup on
 * npmjs.com is required:
 *
 * 1. Publish the first version of the package manually (trusted publishing can
 *    only be configured on an existing package).
 * 2. On npmjs.com, navigate to your package settings to the trusted publishers
 *    section and add a new trusted publisher with the following values:
 *
 *    - Publisher: `GitHub Actions`
 *    - Organization: `nlobby4`
 *    - Repository: `<your repo name>`
 *    - Workflow: `ci-release.yml`
 *    - Environment: (leave blank)
 * 3. Ensure `package.json` includes a "repository" field whose "url" matches your
 *    GitHub repository URL exactly.
 *
 * @file Semantic release configuration file.
 *
 * @author sphoon
 */

/** @see https://semantic-release.gitbook.io/semantic-release/usage/configuration */
export default {
  // Branches on which releases are triggered, push is skipped on other branches
  branches: [
    "main",
    { name: "beta", prerelease: true },
    { name: "alpha", prerelease: true },
  ],
  tagFormat: "v${version}",
  // Order of plugins is important
  plugins: [
    // Analyze commit messages to determine the next version
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
    // Generate release notes based on commits since the last release
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
    // Bump version in package.json and package-lock.json
    // TODO: set npmPublish to true if you want to publish to npm registry.
    ["@semantic-release/npm", { npmPublish: false }],
    // Create a tar.gz archive of the dist directory if a build script is defined.
    [
      "@semantic-release/exec",
      {
        prepareCmd:
          "bash scripts/linux/package/release.sh ${nextRelease.version}",
      },
    ],
    // Update the changelog file with the new release notes
    ["@semantic-release/changelog", { changelogFile: "CHANGELOG.md" }],
    // Create git tag and commit updated changelog, bumped package.json and lockfile
    [
      "@semantic-release/git",
      {
        assets: ["CHANGELOG.md", "package.json", "package-lock.json"],
        message:
          "chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}",
      },
    ],
    // Create a GitHub release and upload the generated archive as a release asset
    [
      "@semantic-release/github",
      {
        assets: [
          {
            path: "*-v*.tar.gz",
          },
        ],
      },
    ],
  ],
};
