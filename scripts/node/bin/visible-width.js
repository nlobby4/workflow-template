#!/usr/bin/env node

/**
 * Prints the terminal display width for each provided argument.
 *
 * Usage: node scripts/node/bin/visible-width.js "text"
 *
 * @file Visible width utility.
 *
 * @author sphoon
 */

import stringWidth from "string-width";

for (const value of process.argv.slice(2)) {
  console.log(stringWidth(value ?? ""));
}
