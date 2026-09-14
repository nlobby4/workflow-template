import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";

import Ajv from "ajv";
import { parse as parseYaml, stringify as stringifyYaml } from "yaml";

import {
  describeProjectGate,
  discoverProjectGates,
  runProjectGateCommand,
} from "./project-gate.js";

function baseConfig() {
  return {
    capabilities: {
      checks: {
        audit: "auto",
        build: "auto",
        format: "auto",
        lint: "auto",
        test: "auto",
      },
    },
    implementations: {
      languages: {
        node: {
          enabled: "auto",
        },
      },
    },
    policy: {
      qualityGate: {
        checks: {
          audit: "auto",
          build: "auto",
          format: "auto",
          lint: "auto",
          test: "auto",
        },
        failOnWarnings: false,
        missingConfig: "skip",
        missingTools: "skip",
        mode: "permissive",
      },
    },
    toolchains: {
      asdf: {
        enabled: true,
        pluginPolicy: "install-missing",
        plugins: {
          nodejs: "https://github.com/asdf-vm/asdf-nodejs.git",
        },
        toolVersions: {
          mode: "validate",
          path: ".tool-versions",
        },
      },
    },
    version: 1,
    workspace: {
      cacheDirectory: ".cache",
      container: {
        dockerOutsideOfDocker: true,
        enabled: true,
        projectDirectory: "project",
      },
      projectMode: "auto",
      projectRoot: "project",
    },
  };
}

function validateSchemaConfig(config) {
  const schema = JSON.parse(
    fs.readFileSync("schemas/nlobby4.schema.json", "utf8"),
  );
  const ajv = new Ajv({
    allErrors: true,
    strict: false,
  });
  const validate = ajv.compile(schema);
  const valid = validate(config);

  return {
    errors: validate.errors ?? [],
    valid,
  };
}

function validateProjectSchemaConfig(config) {
  const schema = JSON.parse(
    fs.readFileSync("schemas/nlobby4-project.schema.json", "utf8"),
  );
  const ajv = new Ajv({
    allErrors: true,
    strict: false,
  });
  const validate = ajv.compile(schema);
  const valid = validate(config);

  return {
    errors: validate.errors ?? [],
    valid,
  };
}

function makeWorkspace(config) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "nlobby4-gate-"));
  const rootConfig = parseYaml(config);
  const projects = rootConfig.projects;

  if (projects && typeof projects === "object" && !Array.isArray(projects)) {
    delete rootConfig.projects;

    for (const [name, projectConfig] of Object.entries(projects)) {
      if (
        projectConfig
        && typeof projectConfig === "object"
        && !Array.isArray(projectConfig)
        && typeof projectConfig.path === "string"
        && !projectConfig.path.includes("..")
      ) {
        const projectDirectory = path.join(root, projectConfig.path);
        const localConfig = {
          version: 1,
          ...projectConfig,
          name,
        };

        delete localConfig.path;
        fs.mkdirSync(projectDirectory, {
          recursive: true,
        });
        fs.writeFileSync(
          path.join(projectDirectory, ".nlobby4.yml"),
          stringifyYaml(localConfig),
        );
      } else {
        rootConfig.projects = {
          ...(rootConfig.projects ?? {}),
          [name]: projectConfig,
        };
      }
    }
  }

  fs.writeFileSync(path.join(root, ".nlobby4.yml"), stringifyYaml(rootConfig));

  return root;
}

function makeProject(root, projectPath) {
  fs.mkdirSync(path.join(root, projectPath), {
    recursive: true,
  });
}

test("discovers command-backed project gates", () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
projects:
  app:
    path: project/app
    commands:
      test: echo "tested"
`);
  makeProject(root, "project/app");

  const [gate] = discoverProjectGates(root);
  const status = describeProjectGate(gate);

  assert.equal(status.name, "app");
  assert.equal(status.path, "project/app");
  assert.equal(status.mechanism, "commands");
  assert.deepEqual(status.commands, ["test"]);
  assert.equal(status.adapter, "");
});

test("schema allows command-backed project gates", () => {
  assert.equal(validateSchemaConfig(baseConfig()).valid, true);

  const result = validateProjectSchemaConfig({
    version: 1,
    ...{
      commands: {
        test: {
          run: "echo tested",
          tools: ["echo"],
        },
      },
    },
  });

  assert.equal(result.valid, true, JSON.stringify(result.errors));
});

test("schema allows adapter-only project gates", () => {
  assert.equal(validateSchemaConfig(baseConfig()).valid, true);

  const result = validateProjectSchemaConfig({
    version: 1,
  });

  assert.equal(result.valid, true, JSON.stringify(result.errors));
});

test("discovers adapter-only project gates", () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
projects:
  app:
    path: project/app
`);
  const adapter = path.join(root, "project/app/.nlobby4/gate.sh");

  makeProject(root, "project/app/.nlobby4");
  fs.writeFileSync(adapter, "#!/usr/bin/env bash\nexit 0\n");
  fs.chmodSync(adapter, 0o755);

  const [gate] = discoverProjectGates(root);
  const status = describeProjectGate(gate);

  assert.equal(status.mechanism, "adapter");
  assert.deepEqual(status.commands, []);
  assert.equal(status.adapter, "project/app/.nlobby4/gate.sh");
});

test("discovers language-adapter project gates", () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
implementations:
  languages:
    toy:
      enabled: auto
      adapter: true
      detect:
        files:
          - toy.project
      commands:
        test: printf language > result.txt
projects:
  app:
    path: project/app
`);

  makeProject(root, "project/app");
  fs.writeFileSync(path.join(root, "project/app/toy.project"), "");

  const [gate] = discoverProjectGates(root);
  const status = describeProjectGate(gate);

  assert.equal(status.mechanism, "language-adapter");
  assert.deepEqual(status.detectedLanguages, ["toy"]);
});

test("runs concrete language adapter commands", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
implementations:
  languages:
    toy:
      enabled: auto
      adapter: true
      detect:
        files:
          - toy.project
      commands:
        test: printf language > result.txt
projects:
  app:
    path: project/app
`);
  const result = path.join(root, "project/app/result.txt");

  makeProject(root, "project/app");
  fs.writeFileSync(path.join(root, "project/app/toy.project"), "");

  const [gate] = discoverProjectGates(root);
  const run = await runProjectGateCommand(gate, "test", [], root);

  assert.equal(run.mechanism, "language-adapter:toy");
  assert.equal(fs.readFileSync(result, "utf8"), "language");
});

test("runs explicit project commands before language adapter commands", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
implementations:
  languages:
    toy:
      enabled: auto
      adapter: true
      detect:
        files:
          - toy.project
      commands:
        test: printf language > result.txt
projects:
  app:
    path: project/app
    commands:
      test: printf command > result.txt
`);
  const result = path.join(root, "project/app/result.txt");

  makeProject(root, "project/app");
  fs.writeFileSync(path.join(root, "project/app/toy.project"), "");

  const [gate] = discoverProjectGates(root);
  const run = await runProjectGateCommand(gate, "test", [], root);

  assert.equal(run.mechanism, "commands");
  assert.equal(fs.readFileSync(result, "utf8"), "command");
});

test("does not run language commands unless adapter fallback is enabled", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: skip
implementations:
  languages:
    toy:
      enabled: auto
      adapter: false
      detect:
        files:
          - toy.project
      commands:
        test: printf language > result.txt
projects:
  app:
    path: project/app
`);

  makeProject(root, "project/app");
  fs.writeFileSync(path.join(root, "project/app/toy.project"), "");

  const [gate] = discoverProjectGates(root);
  const status = describeProjectGate(gate);
  const run = await runProjectGateCommand(gate, "test", [], root);

  assert.equal(status.mechanism, "missing");
  assert.equal(run.status, "skipped");
});

test("applies missingTools policy to language adapter commands", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
    missingTools: skip
implementations:
  languages:
    toy:
      enabled: auto
      adapter: true
      detect:
        files:
          - toy.project
      commands:
        test:
          run: nlobby4-missing-tool-for-test --version
          tools:
            - nlobby4-missing-tool-for-test
projects:
  app:
    path: project/app
`);

  makeProject(root, "project/app");
  fs.writeFileSync(path.join(root, "project/app/toy.project"), "");

  const [gate] = discoverProjectGates(root);
  const run = await runProjectGateCommand(gate, "test", [], root);

  assert.equal(run.status, "skipped");
  assert.match(run.message, /requires missing tool/);
});

test("applies missingTools policy to configured project commands", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
    missingTools: skip
projects:
  app:
    path: project/app
    commands:
      test:
        run: nlobby4-missing-tool-for-test --version
        tools:
          - nlobby4-missing-tool-for-test
`);

  makeProject(root, "project/app");

  const [gate] = discoverProjectGates(root);
  const run = await runProjectGateCommand(gate, "test", [], root);

  assert.equal(run.status, "skipped");
  assert.match(run.message, /requires missing tool/);
});

test("required commands fail when explicit tools are missing", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
    missingTools: skip
projects:
  app:
    path: project/app
    commands:
      test:
        run: nlobby4-missing-tool-for-test --version
        required: true
        tools:
          - nlobby4-missing-tool-for-test
`);

  makeProject(root, "project/app");

  const [gate] = discoverProjectGates(root);

  await assert.rejects(
    runProjectGateCommand(gate, "test", [], root),
    /requires missing tool/,
  );
});

test("fails warnings when failOnWarnings is true", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: warn
    failOnWarnings: true
projects:
  app:
    path: project/app
`);

  makeProject(root, "project/app");

  const [gate] = discoverProjectGates(root);

  await assert.rejects(
    runProjectGateCommand(gate, "test", [], root),
    /app does not define gate command: test/,
  );
});

test("rejects project paths that leave the workspace", () => {
  const root = makeWorkspace(`
version: 1
projects:
  app:
    path: ../app
`);

  assert.throws(() => discoverProjectGates(root), /invalid project path/);
});

test("non-executable project adapters do not silently fall through", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
projects:
  app:
    path: project/app
    commands:
      test: printf command > result.txt
`);
  const adapter = path.join(root, "project/app/.nlobby4/gate.sh");

  makeProject(root, "project/app/.nlobby4");
  fs.writeFileSync(adapter, "#!/usr/bin/env bash\nexit 0\n");
  fs.chmodSync(adapter, 0o644);

  const [gate] = discoverProjectGates(root);

  await assert.rejects(
    runProjectGateCommand(gate, "test", [], root),
    /adapter is not executable/,
  );
});

test("runs project-local adapters before configured commands", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
projects:
  app:
    path: project/app
    commands:
      test: echo "command" > result.txt
`);
  const adapter = path.join(root, "project/app/.nlobby4/gate.sh");
  const result = path.join(root, "project/app/result.txt");

  makeProject(root, "project/app/.nlobby4");
  fs.writeFileSync(
    adapter,
    "#!/usr/bin/env bash\nprintf '%s' \"$1\" > result.txt\n",
  );
  fs.chmodSync(adapter, 0o755);

  const [gate] = discoverProjectGates(root);
  await runProjectGateCommand(gate, "test", [], root);

  assert.equal(fs.readFileSync(result, "utf8"), "test");
});

test("skips missing commands when missingConfig is skip", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: skip
projects:
  app:
    path: project/app
`);
  makeProject(root, "project/app");

  const [gate] = discoverProjectGates(root);
  const result = await runProjectGateCommand(gate, "test", [], root);

  assert.equal(result.status, "skipped");
});

test("fails missing commands when missingConfig is fail", async () => {
  const root = makeWorkspace(`
version: 1
policy:
  qualityGate:
    missingConfig: fail
projects:
  app:
    path: project/app
`);
  makeProject(root, "project/app");

  const [gate] = discoverProjectGates(root);

  await assert.rejects(
    runProjectGateCommand(gate, "test", [], root),
    /app does not define gate command: test/,
  );
});
