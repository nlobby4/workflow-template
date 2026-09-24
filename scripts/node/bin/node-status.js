#!/usr/bin/env node

/**
 * Reports Node.js dependency installation metadata as JSON status rows.
 *
 * Usage: node scripts/node/bin/node-status.js.
 *
 * @file Node.js metadata utility.
 *
 * @author sphoon
 */

import { spawnSync } from "node:child_process";
import fs from "node:fs";

const lockfilePath = "pnpm-lock.yaml";
const installedLockfilePath = "node_modules/.pnpm/lock.yaml";

/**
 * Builds Node.js status rows.
 *
 * @returns {{ label: string; value: string }[]} Status rows.
 */
function statusRows() {
  if (!fs.existsSync("package.json")) {
    return [];
  }

  const hasLockfile = fs.existsSync(lockfilePath);
  const hasNodeModules = fs.existsSync("node_modules");

  if (!hasLockfile) {
    return [
      {
        label: "Node.js dependencies",
        value:
          hasNodeModules ? "installed" : (
            'node_modules missing; run "pnpm install"'
          ),
      },
    ];
  }

  if (!hasNodeModules) {
    return [
      {
        label: "Node.js dependencies",
        value: "node_modules missing; run pnpm install --frozen-lockfile",
      },
    ];
  }

  const lockfileCheck = spawnSync(
    "pnpm",
    ["install", "--lockfile-only", "--frozen-lockfile", "--ignore-scripts"],
    { stdio: "ignore" },
  );

  if (lockfileCheck.error) {
    return [
      {
        label: "Node.js dependencies",
        value: "lockfile state could not be verified",
      },
    ];
  }

  if (lockfileCheck.status !== 0) {
    return [
      {
        label: "Node.js dependencies",
        value:
          'pnpm-lock.yaml does not match package manifests; run "pnpm install"',
      },
    ];
  }

  if (!fs.existsSync(installedLockfilePath)) {
    return [
      {
        label: "Node.js dependencies",
        value: "install state could not be verified",
      },
    ];
  }

  if (
    !fs
      .readFileSync(lockfilePath)
      .equals(fs.readFileSync(installedLockfilePath))
  ) {
    return [
      {
        label: "Node.js dependencies",
        value:
          'installed package versions do not match pnpm-lock.yaml; run "pnpm install --frozen-lockfile"',
      },
    ];
  }

  return [
    {
      label: "Node.js dependencies",
      value: "installed",
    },
  ];
}

console.log(JSON.stringify(statusRows()));
