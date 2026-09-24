#!/usr/bin/env node

/**
 * Wraps stdin lines to a target terminal display width.
 *
 * Usage: printf "text\n" | node scripts/node/bin/wrap-lines.js 80. Usage:
 * printf "Label: text\n" | node scripts/node/bin/wrap-lines.js 80
 * --hanging-status.
 *
 * @file Visible-width line wrapping utility.
 *
 * @author sphoon
 */

import stringWidth from "string-width";
import wrapAnsi from "wrap-ansi";

const width = Number.parseInt(process.argv[2] ?? "", 10);
const hangingStatus = process.argv.includes("--hanging-status");

if (!Number.isInteger(width) || width < 1) {
  process.exit(1);
}

const input = await new Promise((resolve, reject) => {
  let data = "";

  process.stdin.setEncoding("utf8");
  process.stdin.on("data", (chunk) => {
    data += chunk;
  });
  process.stdin.on("end", () => resolve(data));
  process.stdin.on("error", reject);
});

const lines =
  input.endsWith("\n") ? input.slice(0, -1).split("\n") : input.split("\n");

/**
 * Wraps text to the configured display width.
 *
 * @param {string} value - Text to wrap.
 *
 * @returns {string[]} Wrapped lines.
 */
function wrapText(value) {
  return wrapAnsi(value, width, {
    hard: true,
    trim: true,
    wordWrap: true,
  }).split("\n");
}

/**
 * Wraps one line to the configured display width.
 *
 * @param {string} line - Line to wrap.
 *
 * @returns {string[]} Wrapped lines.
 */
function wrapLine(line) {
  if (stringWidth(line) <= width) {
    return [line];
  }

  if (!hangingStatus) {
    return wrapText(line);
  }

  const statusMatch = /^([^:]+:\s)(.+)$/u.exec(line);
  if (!statusMatch) {
    return wrapText(line);
  }

  const [, prefix, value] = statusMatch;
  const prefixWidth = stringWidth(prefix);
  const valueWidth = width - prefixWidth;

  if (valueWidth < 1) {
    return wrapText(line);
  }

  const wrappedValue = wrapAnsi(value, valueWidth, {
    hard: true,
    trim: true,
    wordWrap: true,
  }).split("\n");

  const hangingIndent = " ".repeat(prefixWidth);

  return wrappedValue.map((wrappedLine, index) =>
    index === 0 ? `${prefix}${wrappedLine}` : `${hangingIndent}${wrappedLine}`,
  );
}

console.log(lines.flatMap(wrapLine).join("\n"));
