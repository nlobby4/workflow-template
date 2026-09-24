#!/usr/bin/env node

/**
 * Runs one project compatibility gate command.
 *
 * Usage: node scripts/node/bin/gate/run.js <project> <command> [args...].
 *
 * @file Project gate command runner.
 *
 * @author sphoon
 */

import process from "node:process";

import {
  discoverProjectGates,
  findProjectGate,
  runAllProjectGateCommands,
  runProjectGateCommand,
} from "../../lib/project-gate.js";

const [project, command, ...args] = process.argv.slice(2);

if (!project || !command) {
  console.error("Usage: gate:run <project|--all> <command> [args...]");
  process.exit(64);
}

if (project === "--all") {
  try {
    await runAllProjectGateCommands(command, args);
  } catch (error) {
    console.error(error.message);
    process.exit(1);
  }

  process.exit(0);
}

const gates = discoverProjectGates();
const gate = findProjectGate(project, gates);

if (!gate) {
  console.error(`Project gate not found: ${project}`);
  process.exit(1);
}

try {
  await runProjectGateCommand(gate, command, args);
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
