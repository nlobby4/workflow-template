/**
 * This configuration enforces commit messages to maintain a consistent machine
 * readable format, which can be used for automatic changelog generation. It
 * extends the standard configuration and defines custom rules for commit types,
 * scopes, and message formatting.
 *
 * Commitlint uses the prompt configuration to provide an interactive commit
 * message wizard that enforces the same rules. Run the following command to use
 * the commit message wizard:
 *
 *     npm run commit
 *
 * @file Commitlint configuration file.
 *
 * @author sphoon
 */

/**
 * @type {import("@commitlint/types").UserConfig}
 *
 * @see https://commitlint.js.org/reference/configuration.html
 */
export default {
  defaultIgnores: true,
  extends: ["@commitlint/config-conventional"],
  formatter: "@commitlint/format",
  helpUrl: "https://www.conventionalcommits.org/en/v1.0.0/#summary",
  prompt: {
    messages: {
      skip: "(press enter to skip)",
      max: "upper %d chars",
      min: "%d chars at least",
      emptyWarning: "can not be empty",
      upperLimitWarning: "over limit",
      lowerLimitWarning: "below limit",
    },
    questions: {
      type: {
        description: "Select the type of change you are committing",
        enum: {
          feat: {
            description: "A new feature",
            title: "Features",
            emoji: "✨",
          },
          fix: {
            description: "A bug fix",
            title: "Bug Fixes",
            emoji: "🐛",
          },
          docs: {
            description: "Documentation only changes",
            title: "Documentation",
            emoji: "📚",
          },
          style: {
            description: "Changes that do not affect the meaning of the code",
            title: "Styles",
            emoji: "🧽",
          },
          refactor: {
            description:
              "A code change that neither fixes a bug nor adds a feature",
            title: "Code Refactoring",
            emoji: "📦",
          },
          perf: {
            description: "A code change that improves performance",
            title: "Performance Improvements",
            emoji: "🔥",
          },
          test: {
            description: "Adding missing tests or correcting existing tests",
            title: "Tests",
            emoji: "🚨",
          },
          build: {
            description:
              "Changes that affect the build system or external dependencies",
            title: "Builds",
            emoji: "🔨",
          },
          ci: {
            description: "Changes to CI configuration files and scripts",
            title: "Continuous Integration",
            emoji: "⚙️",
          },
          chore: {
            description: "Other changes that do not modify src or test files",
            title: "Chores",
            emoji: "🧹",
          },
          revert: {
            description: "Reverts a previous commit",
            title: "Reverts",
            emoji: "🗑",
          },
        },
      },
      scope: {
        description:
          "What is the scope of this change (e.g. src, scripts, meta)",
        enum: {
          assets: {
            description: "Static assets",
            title: "assets",
          },
          ci: {
            description: "CI configuration",
            title: "ci",
          },
          deps: {
            description: "Production dependencies",
            title: "deps",
          },
          "deps-dev": {
            description: "Development dependencies",
            title: "deps-dev",
          },
          docs: {
            description: "Documentation",
            title: "docs",
          },
          meta: {
            description: "Repository meta files",
            title: "meta",
          },
          release: {
            description: "Release tooling",
            title: "release",
          },
          scripts: {
            description: "Repository scripts",
            title: "scripts",
          },
          src: {
            description: "Source code",
            title: "src",
          },
          templates: {
            description: "Templates",
            title: "templates",
          },
          tests: {
            description: "Tests",
            title: "tests",
          },
        },
      },
      subject: {
        description:
          "Write a short, imperative tense description of the change",
      },
      body: {
        description: "Provide a longer description of the change",
      },
      isBreaking: {
        description: "Are there any breaking changes?",
      },
      breakingBody: {
        description:
          "A BREAKING CHANGE commit requires a body. Please enter a longer description of the commit itself",
      },
      breaking: {
        description: "Describe the breaking changes",
      },
      isIssueAffected: {
        description: "Does this change affect any open issues?",
      },
      issuesBody: {
        description:
          "If issues are closed, the commit requires a body. Please enter a longer description of the commit",
      },
      issues: {
        description: "Add issue references (e.g. fix #123, re #123)",
      },
    },
  },
  rules: {
    "type-enum": [
      2,
      "always",
      [
        "build",
        "chore",
        "ci",
        "docs",
        "feat",
        "fix",
        "perf",
        "refactor",
        "revert",
        "style",
        "test",
      ],
    ],
    "type-case": [2, "always", "lower-case"],
    "type-empty": [2, "never"],
    "scope-enum": [
      2,
      "always",
      [
        "assets",
        "ci",
        "deps",
        "deps-dev",
        "docs",
        "meta",
        "release",
        "scripts",
        "src",
        "templates",
        "tests",
      ],
    ],
    "scope-case": [2, "always", "kebab-case"],
    "subject-empty": [2, "never"],
    "subject-case": [
      2,
      "never",
      ["sentence-case", "start-case", "pascal-case", "upper-case"],
    ],
    "subject-full-stop": [2, "never", "."],
    "header-max-length": [2, "always", 72],
    "body-max-line-length": [1, "always", 100],
    "footer-max-line-length": [1, "always", 100],
    "footer-leading-blank": [1, "always"],
    "no-empty-scope": [2, "always"],
  },
  plugins: [
    {
      rules: {
        "no-empty-scope": ({ header }) => [
          !header.includes("():"),
          "Scope cannot be empty. Use 'type: subject' or 'type(scope): subject'.",
        ],
      },
    },
  ],
};
