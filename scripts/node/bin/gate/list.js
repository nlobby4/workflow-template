#!/usr/bin/env node

/**
 * Lists project compatibility gates.
 *
 * Usage: node scripts/node/bin/gate/list.js.
 *
 * @file Project gate listing command.
 *
 * @author sphoon
 */

import {
  describeProjectGate,
  discoverProjectGates,
} from "../../lib/project-gate.js";

const gates = discoverProjectGates();

if (gates.length === 0) {
  console.log("No project gates found.");
  process.exit(0);
}

console.log("name\tpath\tmechanism\tlanguages\tcommands\tadapter");

for (const gate of gates) {
  const status = describeProjectGate(gate);
  const commands =
    status.commands.length > 0 ? status.commands.join(", ") : "-";
  const adapter = status.adapter || "-";
  const languages =
    status.detectedLanguages.length > 0 ?
      status.detectedLanguages.join(", ")
    : "-";

  console.log(
    `${status.name}\t${status.path}\t${status.mechanism}\t${languages}\t${commands}\t${adapter}`,
  );
}
