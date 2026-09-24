#!/usr/bin/env node

/**
 * Validates repository JSON Schemas and schema-backed config files.
 *
 * Usage: node scripts/node/bin/validate-schemas.js.
 *
 * @file Schema validation command.
 *
 * @author sphoon
 */

import process from "node:process";

import { validateSchemas } from "../lib/schema-validator.js";

const { failures, schemaCount, dataCount, externalSchemaCount } =
  validateSchemas();

if (failures.length > 0) {
  for (const failure of failures) {
    console.error(`${failure.file}: ${failure.message}`);
  }

  process.exit(1);
}

const externalSchemaSummary =
  externalSchemaCount === 0 ? "" : (
    ` Skipped ${externalSchemaCount} external schema-backed file${externalSchemaCount === 1 ? "" : "s"}.`
  );

console.log(
  `Validated ${schemaCount} schema file${schemaCount === 1 ? "" : "s"} and ${dataCount} local schema-backed config file${dataCount === 1 ? "" : "s"}.${externalSchemaSummary}`,
);
