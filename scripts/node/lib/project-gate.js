import { spawn, spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

import { parse as parseYaml } from "yaml";

const gateAdapterPath = [".nlobby4", "gate.sh"];
const orchestratorConfigPath = ".nlobby4.yml";
const projectConfigFileName = ".nlobby4.yml";
const ignoredDetectionDirectories = new Set([
  ".cache",
  ".git",
  "dist",
  "node_modules",
  "target",
  "vendor",
]);

/**
 * @typedef {object} GateCommand
 *
 * @property {string | undefined} description
 * @property {boolean | undefined} required
 * @property {string} run
 * @property {string | undefined} timeout
 * @property {string[]} tools
 */

/**
 * @typedef {object} ProjectGate
 *
 * @property {string} name
 * @property {string} path
 * @property {string} config
 * @property {string | undefined} adapter
 * @property {boolean} adapterExecutable
 * @property {Record<string, GateCommand>} commands
 * @property {string[]} detectedLanguages
 * @property {unknown} implementations
 * @property {unknown} policy
 * @property {unknown} configData
 */

/**
 * @typedef {object} ProjectGateResult
 *
 * @property {string | undefined} mechanism
 * @property {string | undefined} message
 * @property {"executed" | "skipped" | "warned"} status
 */

/**
 * Returns a POSIX-like relative path for display and matching.
 *
 * @param {string} value - Path value.
 *
 * @returns {string} Normalized path.
 */
function normalizePath(value) {
  return value.split(path.sep).join("/");
}

/**
 * Reads a YAML file.
 *
 * @param {string} file - YAML file path.
 *
 * @returns {unknown} Parsed YAML.
 */
function readYaml(file) {
  return parseYaml(fs.readFileSync(file, "utf8"));
}

/**
 * Converts a manifest command value to a normalized command object.
 *
 * @param {unknown} value - Manifest command value.
 *
 * @returns {GateCommand} Normalized command.
 */
function normalizeCommand(value) {
  if (typeof value === "string") {
    return {
      run: value,
      tools: [],
    };
  }

  if (value && typeof value === "object" && !Array.isArray(value)) {
    if (typeof value.run !== "string" || value.run.length === 0) {
      throw new TypeError("invalid gate command");
    }

    return {
      description:
        typeof value.description === "string" ? value.description : undefined,
      required:
        typeof value.required === "boolean" ? value.required : undefined,
      run: value.run,
      timeout: typeof value.timeout === "string" ? value.timeout : undefined,
      tools: Array.isArray(value.tools) ? value.tools : [],
    };
  }

  throw new TypeError("invalid gate command");
}

/**
 * Returns whether a value is a plain object.
 *
 * @param {unknown} value - Value to check.
 *
 * @returns {value is Record<string, unknown>} Whether value is a plain object.
 */
function isRecord(value) {
  return Boolean(value && typeof value === "object" && !Array.isArray(value));
}

/**
 * Returns whether a configured project path stays inside the workspace root.
 *
 * @param {unknown} value - Project path value.
 *
 * @returns {value is string} Whether the path is safe.
 */
function isSafeProjectPath(value) {
  if (typeof value !== "string" || value.length === 0) {
    return false;
  }

  return (
    !path.isAbsolute(value)
    && !value.split(/[\\/]/u).some((segment) => segment === "..")
  );
}

/**
 * Reads the root orchestrator configuration.
 *
 * @param {string} root - Repository root.
 *
 * @returns {unknown} Parsed configuration.
 */
export function readOrchestratorConfig(root) {
  const configFile = path.join(root, orchestratorConfigPath);

  if (!fs.existsSync(configFile)) {
    return {
      workspace: {
        projectRoot: "project",
      },
    };
  }

  return readYaml(configFile);
}

function pathExists(root, projectPath, relativePath) {
  return fs.existsSync(path.join(root, projectPath, relativePath));
}

/**
 * Returns whether a project has any file with the given extension.
 *
 * @param {string} directory - Project directory.
 * @param {string} extension - File extension.
 *
 * @returns {boolean} Whether a matching file exists.
 */
function hasExtension(directory, extension) {
  if (!fs.existsSync(directory)) {
    return false;
  }

  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (entry.isDirectory() && ignoredDetectionDirectories.has(entry.name)) {
      continue;
    }

    const entryPath = path.join(directory, entry.name);

    if (entry.isDirectory()) {
      if (hasExtension(entryPath, extension)) {
        return true;
      }
    } else if (entry.isFile() && entry.name.endsWith(extension)) {
      return true;
    }
  }

  return false;
}

/**
 * Returns whether one language implementation matches a project directory.
 *
 * @param {string} root - Repository root.
 * @param {string} projectPath - Project path relative to root.
 * @param {unknown} implementation - Language implementation metadata.
 *
 * @returns {boolean} Whether the implementation matches.
 */
function detectsLanguage(root, projectPath, implementation) {
  if (!isRecord(implementation) || implementation.enabled === false) {
    return false;
  }

  const projectDirectory = path.join(root, projectPath);
  const detect = isRecord(implementation.detect) ? implementation.detect : {};
  const files = Array.isArray(detect.files) ? detect.files : [];
  const directories =
    Array.isArray(detect.directories) ? detect.directories : [];
  const extensions = Array.isArray(detect.extensions) ? detect.extensions : [];

  return (
    files.some((file) => pathExists(root, projectPath, file))
    || directories.some((directory) => pathExists(root, projectPath, directory))
    || extensions.some((extension) => hasExtension(projectDirectory, extension))
  );
}

/**
 * Detects matching language implementations for a project.
 *
 * @param {string} root - Repository root.
 * @param {string} projectPath - Project path relative to root.
 * @param {unknown} implementations - Orchestrator implementation metadata.
 *
 * @returns {string[]} Matching language names.
 */
function detectLanguages(root, projectPath, implementations) {
  const languages =
    isRecord(implementations) && isRecord(implementations.languages) ?
      implementations.languages
    : {};

  return Object.entries(languages)
    .filter(([, implementation]) =>
      detectsLanguage(root, projectPath, implementation),
    )
    .map(([language]) => language);
}

/**
 * Returns the configured project root.
 *
 * @param {unknown} config - Root orchestrator configuration.
 *
 * @returns {string} Project root path.
 */
function projectRootPath(config) {
  const projectRoot = config?.workspace?.projectRoot;
  return typeof projectRoot === "string" && projectRoot.length > 0 ?
      projectRoot
    : "project";
}

/**
 * Reads one project-local gate configuration.
 *
 * @param {string} file - Project-local config file.
 *
 * @returns {Record<string, unknown>} Parsed project config.
 */
function readProjectConfig(file) {
  const config = readYaml(file);

  if (!isRecord(config)) {
    throw new Error(`invalid project config: ${file}`);
  }

  return config;
}

/**
 * Returns project-local config candidates for the configured project root.
 *
 * @param {string} root - Repository root.
 * @param {unknown} config - Root orchestrator configuration.
 *
 * @returns {{ file: string; name: string; path: string }[]} Project config
 *   candidates.
 */
function projectConfigCandidates(root, config) {
  const projectRoot = projectRootPath(config);
  const projectRootDirectory = path.join(root, projectRoot);
  const candidates = [];
  const rootProjectConfig = path.join(
    projectRootDirectory,
    projectConfigFileName,
  );

  if (fs.existsSync(rootProjectConfig)) {
    candidates.push({
      file: rootProjectConfig,
      name: path.basename(projectRoot),
      path: projectRoot,
    });
  }

  if (!fs.existsSync(projectRootDirectory)) {
    return candidates;
  }

  for (const entry of fs.readdirSync(projectRootDirectory, {
    withFileTypes: true,
  })) {
    if (!entry.isDirectory()) {
      continue;
    }

    const projectConfig = path.join(
      projectRootDirectory,
      entry.name,
      projectConfigFileName,
    );

    if (fs.existsSync(projectConfig)) {
      candidates.push({
        file: projectConfig,
        name: entry.name,
        path: normalizePath(path.join(projectRoot, entry.name)),
      });
    }
  }

  return candidates;
}

/**
 * Loads one project gate from a project-local configuration file.
 *
 * @param {string} root - Repository root.
 * @param {string} defaultName - Project gate name inferred from path.
 * @param {string} defaultPath - Project path relative to root.
 * @param {string} configFile - Project-local config file.
 * @param {unknown} projectConfig - Project gate configuration.
 * @param {unknown} policy - Orchestrator policy config.
 * @param {unknown} implementations - Orchestrator implementation config.
 *
 * @returns {ProjectGate} Project gate.
 */
function loadProjectGate(
  root,
  defaultName,
  defaultPath,
  configFile,
  projectConfig,
  policy,
  implementations,
) {
  if (!isRecord(projectConfig) || !isSafeProjectPath(defaultPath)) {
    throw new Error(`invalid project path for ${defaultName}`);
  }

  const name =
    typeof projectConfig.name === "string" && projectConfig.name.length > 0 ?
      projectConfig.name
    : defaultName;
  const projectPath = path.join(root, defaultPath);
  const adapter = path.join(projectPath, ...gateAdapterPath);
  const adapterExists = fs.existsSync(adapter);
  const adapterExecutable =
    adapterExists && Boolean(fs.statSync(adapter).mode & 0o111);
  const commands = {};

  for (const [commandName, command] of Object.entries(
    projectConfig.commands ?? {},
  )) {
    commands[commandName] = normalizeCommand(command);
  }

  return {
    name,
    path: normalizePath(defaultPath),
    config: normalizePath(path.relative(root, configFile)),
    adapter:
      adapterExists ? normalizePath(path.relative(root, adapter)) : undefined,
    adapterExecutable,
    commands,
    detectedLanguages: detectLanguages(root, defaultPath, implementations),
    implementations,
    policy,
    configData: projectConfig,
  };
}

/**
 * Discovers project gates below the repository project root.
 *
 * @param {string} root - Repository root.
 *
 * @returns {ProjectGate[]} Project gates.
 */
export function discoverProjectGates(root = process.cwd()) {
  const config = readOrchestratorConfig(root);
  const projectLocalGates = projectConfigCandidates(root, config).map(
    (candidate) =>
      loadProjectGate(
        root,
        candidate.name,
        candidate.path,
        candidate.file,
        readProjectConfig(candidate.file),
        config.policy,
        config.implementations,
      ),
  );
  const legacyRootGates = Object.entries(config.projects ?? {}).map(
    ([name, projectConfig]) =>
      loadProjectGate(
        root,
        name,
        projectConfig.path,
        path.join(root, orchestratorConfigPath),
        projectConfig,
        config.policy,
        config.implementations,
      ),
  );

  return [...projectLocalGates, ...legacyRootGates].sort((a, b) =>
    a.name.localeCompare(b.name),
  );
}

/**
 * Finds one project gate by name or path.
 *
 * @param {string} selector - Gate name or path.
 * @param {ProjectGate[]} gates - Discovered gates.
 *
 * @returns {ProjectGate | undefined} Matching gate.
 */
export function findProjectGate(selector, gates = discoverProjectGates()) {
  return gates.find((gate) => gate.name === selector || gate.path === selector);
}

/**
 * Returns a deterministic summary of one project gate integration.
 *
 * @param {ProjectGate} gate - Project gate.
 *
 * @returns {{
 *   adapter: string;
 *   commands: string[];
 *   detectedLanguages: string[];
 *   mechanism: string;
 *   name: string;
 *   path: string;
 * }}
 *   Gate status.
 */
export function describeProjectGate(gate) {
  const commands = Object.keys(gate.commands).sort();

  return {
    adapter:
      gate.adapter ?
        gate.adapterExecutable ?
          gate.adapter
        : `${gate.adapter} (not executable)`
      : "",
    commands,
    detectedLanguages: gate.detectedLanguages,
    mechanism:
      gate.adapterExecutable ? "adapter"
      : commands.length > 0 ? "commands"
      : (
        gate.detectedLanguages.some((language) =>
          hasConcreteLanguageCommand(gate, language),
        )
      ) ?
        "language-adapter"
      : gate.adapter ? "invalid-adapter"
      : "missing",
    name: gate.name,
    path: gate.path,
  };
}

/**
 * Returns configured language names for a project in deterministic priority
 * order.
 *
 * @param {ProjectGate} gate - Project gate.
 *
 * @returns {string[]} Language names.
 */
function projectLanguages(gate) {
  const language =
    isRecord(gate.configData.language) ? gate.configData.language : {};
  const primary =
    typeof language.primary === "string" && language.primary !== "generic" ?
      [language.primary]
    : [];
  const secondary = Array.isArray(language.secondary) ? language.secondary : [];

  return [...new Set([...primary, ...secondary, ...gate.detectedLanguages])];
}

/**
 * Returns a concrete language implementation command, if configured.
 *
 * @param {ProjectGate} gate - Project gate.
 * @param {string} language - Language name.
 * @param {string} commandName - Command name.
 *
 * @returns {GateCommand | undefined} Language command.
 */
function languageCommand(gate, language, commandName) {
  const languages =
    isRecord(gate.implementations) && isRecord(gate.implementations.languages) ?
      gate.implementations.languages
    : {};
  const implementation = languages[language];

  if (
    !isRecord(implementation)
    || implementation.enabled === false
    || implementation.adapter !== true
  ) {
    return undefined;
  }

  const commands =
    isRecord(implementation.commands) ? implementation.commands : {};
  const command = commands[commandName];

  if (typeof command === "string" || isRecord(command)) {
    return normalizeCommand(command);
  }

  return undefined;
}

/**
 * Returns whether a language implementation has at least one concrete command.
 *
 * @param {ProjectGate} gate - Project gate.
 * @param {string} language - Language name.
 *
 * @returns {boolean} Whether a concrete command exists.
 */
function hasConcreteLanguageCommand(gate, language) {
  const languages =
    isRecord(gate.implementations) && isRecord(gate.implementations.languages) ?
      gate.implementations.languages
    : {};
  const implementation = languages[language];

  if (!isRecord(implementation) || implementation.adapter !== true) {
    return false;
  }

  const commands =
    isRecord(implementation.commands) ? implementation.commands : {};

  return Object.values(commands).some(
    (command) => typeof command === "string" || isRecord(command),
  );
}

/**
 * Resolves a concrete language adapter command for a project capability.
 *
 * @param {ProjectGate} gate - Project gate.
 * @param {string} commandName - Command name.
 *
 * @returns {{ command: GateCommand; language: string } | undefined} Language
 *   command.
 */
function resolveLanguageCommand(gate, commandName) {
  for (const language of projectLanguages(gate)) {
    const command = languageCommand(gate, language, commandName);

    if (command) {
      return {
        command,
        language,
      };
    }
  }

  return undefined;
}

/**
 * Returns the configured policy for a missing project capability.
 *
 * @param {ProjectGate} gate - Project gate.
 * @param {string} commandName - Command name.
 *
 * @returns {"skip" | "warn" | "fail"} Missing capability behavior.
 */
function missingCapabilityPolicy(gate, commandName) {
  const qualityGate = gate.policy?.qualityGate;
  const checkPolicy = qualityGate?.checks?.[commandName];

  if (checkPolicy === false) {
    return "skip";
  }

  if (checkPolicy === true) {
    return "fail";
  }

  return qualityGate?.missingConfig ?? "fail";
}

/**
 * Returns the configured policy for a missing required tool.
 *
 * @param {ProjectGate} gate - Project gate.
 *
 * @returns {"skip" | "warn" | "fail"} Missing tool behavior.
 */
function missingToolsPolicy(gate) {
  return gate.policy?.qualityGate?.missingTools ?? "fail";
}

/**
 * Returns whether warnings should fail the quality gate.
 *
 * @param {ProjectGate} gate - Project gate.
 *
 * @returns {boolean} Whether warnings should fail.
 */
function failOnWarnings(gate) {
  return gate.policy?.qualityGate?.failOnWarnings === true;
}

/**
 * Applies skip, warn, or fail policy to a non-executable condition.
 *
 * @param {ProjectGate} gate - Project gate.
 * @param {"skip" | "warn" | "fail"} action - Policy action.
 * @param {string} message - Diagnostic message.
 *
 * @returns {{ status: "skipped" | "warned"; message: string }} Result when
 *   execution is not required.
 */
function handlePolicy(gate, action, message) {
  if (action === "skip") {
    console.log(`Skipping ${gate.name}: ${message}`);
    return {
      message,
      status: "skipped",
    };
  }

  if (action === "warn" && !failOnWarnings(gate)) {
    console.warn(`Warning: ${message}`);
    return {
      message,
      status: "warned",
    };
  }

  throw new Error(message);
}

/**
 * Handles a missing project capability according to quality-gate policy.
 *
 * @param {ProjectGate} gate - Project gate.
 * @param {string} commandName - Command name.
 *
 * @returns {{ status: "skipped" | "warned"; message: string }} Result when
 *   execution is not required.
 */
function handleMissingCapability(gate, commandName) {
  const action = missingCapabilityPolicy(gate, commandName);
  const message = `${gate.name} does not define gate command: ${commandName}`;

  return handlePolicy(gate, action, message);
}

/**
 * Returns explicit tool requirements for a command.
 *
 * @param {GateCommand} command - Command to check.
 *
 * @returns {string[]} Tool names.
 */
function commandTools(command) {
  return command.tools.filter((tool) => typeof tool === "string" && tool);
}

/**
 * Returns whether an executable is available from a project directory.
 *
 * @param {string} executable - Executable name or path.
 * @param {string} cwd - Project directory.
 *
 * @returns {boolean} Whether executable is available.
 */
function executableExists(executable, cwd) {
  if (executable.includes("/")) {
    return fs.existsSync(path.resolve(cwd, executable));
  }

  return (
    spawnSync("command", ["-v", executable], {
      cwd,
      shell: true,
      stdio: "ignore",
    }).status === 0
  );
}

/**
 * Applies missingTools policy for a language adapter command.
 *
 * @param {ProjectGate} gate - Project gate.
 * @param {GateCommand} command - Command to check.
 * @param {string} cwd - Project directory.
 *
 * @returns {{ status: "skipped" | "warned"; message: string } | undefined}
 *   Result when execution should not continue.
 */
function handleMissingTools(gate, command, cwd) {
  const missingTool = commandTools(command).find(
    (tool) => !executableExists(tool, cwd),
  );

  if (!missingTool) {
    return undefined;
  }

  const action = command.required === true ? "fail" : missingToolsPolicy(gate);

  return handlePolicy(
    gate,
    action,
    `${gate.name} requires missing tool: ${missingTool}`,
  );
}

/**
 * Runs a shell command in a project path.
 *
 * @param {string} command - Command to run.
 * @param {string} cwd - Working directory.
 *
 * @returns {Promise<void>} Resolves when command succeeds.
 */
function runShellCommand(command, cwd) {
  return new Promise((resolve, reject) => {
    const child = spawn(command, {
      cwd,
      env: process.env,
      shell: true,
      stdio: "inherit",
    });

    child.on("error", reject);
    child.on("exit", (code, signal) => {
      if (code === 0) {
        resolve();
        return;
      }

      reject(
        new Error(
          signal ?
            `command exited from signal ${signal}`
          : `command exited with code ${code}`,
        ),
      );
    });
  });
}

/**
 * Runs a project gate command.
 *
 * @param {ProjectGate} gate - Project gate.
 * @param {string} commandName - Command name.
 * @param {string[]} args - Extra command arguments.
 * @param {string} root - Repository root.
 *
 * @returns {Promise<void>} Resolves when command succeeds.
 */
export async function runProjectGateCommand(
  gate,
  commandName,
  args = [],
  root = process.cwd(),
) {
  const projectPath = path.join(root, gate.path);
  const adapter = gate.adapter ? path.join(root, gate.adapter) : undefined;

  if (adapter && gate.adapterExecutable) {
    await runShellCommand(
      `${JSON.stringify(adapter)} ${[commandName, ...args].map((arg) => JSON.stringify(arg)).join(" ")}`,
      projectPath,
    );
    return {
      mechanism: "adapter",
      status: "executed",
    };
  }

  if (adapter) {
    return handlePolicy(
      gate,
      missingCapabilityPolicy(gate, commandName),
      `${gate.name} adapter is not executable: ${gate.adapter}`,
    );
  }

  const command = gate.commands[commandName];
  if (command) {
    const missingToolsResult = handleMissingTools(gate, command, projectPath);

    if (missingToolsResult) {
      return missingToolsResult;
    }

    await runShellCommand(
      [command.run, ...args.map((arg) => JSON.stringify(arg))].join(" "),
      projectPath,
    );

    return {
      mechanism: "commands",
      status: "executed",
    };
  }

  const languageAdapter = resolveLanguageCommand(gate, commandName);

  if (languageAdapter) {
    const missingToolsResult = handleMissingTools(
      gate,
      languageAdapter.command,
      projectPath,
    );

    if (missingToolsResult) {
      return missingToolsResult;
    }

    await runShellCommand(
      [
        languageAdapter.command.run,
        ...args.map((arg) => JSON.stringify(arg)),
      ].join(" "),
      projectPath,
    );

    return {
      mechanism: `language-adapter:${languageAdapter.language}`,
      status: "executed",
    };
  }

  return handleMissingCapability(gate, commandName);
}

/**
 * Runs one command for every discovered project gate.
 *
 * @param {string} commandName - Command name.
 * @param {string[]} args - Extra command arguments.
 * @param {string} root - Repository root.
 *
 * @returns {Promise<void>} Resolves when all required commands succeed.
 */
export async function runAllProjectGateCommands(
  commandName,
  args = [],
  root = process.cwd(),
) {
  const gates = discoverProjectGates(root);

  if (gates.length === 0) {
    throw new Error("No project gates found.");
  }

  for (const gate of gates) {
    await runProjectGateCommand(gate, commandName, args, root);
  }
}
