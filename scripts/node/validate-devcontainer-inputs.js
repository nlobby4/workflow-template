import fs from "node:fs";

const read = (path) => fs.readFileSync(path, "utf8");
const failures = [];
const fail = (message) => failures.push(message);

const versionLines = read(".devcontainer/versions.env")
  .split("\n")
  .filter((line) => line && !line.startsWith("#"));
const values = Object.fromEntries(
  versionLines.map((line) => {
    const separator = line.indexOf("=");
    return [line.slice(0, separator), line.slice(separator + 1)];
  }),
);
const expectedVariables = [
  "DEBIAN_SNAPSHOT",
  "CMARK_GFM_VERSION",
  "CURL_VERSION",
  "GAWK_VERSION",
  "GIT_LFS_VERSION",
  "JQ_VERSION",
  "YQ_VERSION",
  "MISE_VERSION",
];

for (const line of versionLines) {
  if (!/^[A-Z][A-Z0-9_]*=\S+$/.test(line)) {
    fail(`invalid version entry: ${line}`);
  }
}
for (const name of expectedVariables) {
  if (!values[name]) fail(`missing version entry: ${name}`);
}
for (const name of Object.keys(values)) {
  if (!expectedVariables.includes(name)) fail(`stale version entry: ${name}`);
}
if (!/^\d{8}T\d{6}Z$/.test(values.DEBIAN_SNAPSHOT ?? "")) {
  fail("DEBIAN_SNAPSHOT must use YYYYMMDDTHHMMSSZ format");
}

const checksums = new Map();
for (const [index, line] of read(".devcontainer/checksums.sha256")
  .split("\n")
  .entries()) {
  if (!line || line.startsWith("#")) continue;
  if (!/^[a-f0-9]{64} {2}\S+$/.test(line)) {
    fail(`invalid checksum entry on line ${index + 1}`);
    continue;
  }
  const [hash, filename] = line.split("  ");
  if (checksums.has(filename)) fail(`duplicate checksum: ${filename}`);
  checksums.set(filename, hash);
}

const expectedArtifacts = [
  `mise-v${values.MISE_VERSION}-linux-x64`,
  `mise-v${values.MISE_VERSION}-linux-arm64`,
];

for (const filename of expectedArtifacts) {
  if (!checksums.has(filename)) fail(`missing checksum: ${filename}`);
}
for (const filename of checksums.keys()) {
  if (!expectedArtifacts.includes(filename))
    fail(`stale checksum: ${filename}`);
}

if (failures.length) {
  for (const message of failures) {
    console.error(`Dev Container input error: ${message}`);
  }
  process.exit(1);
}

console.log("Dev Container version and checksum inputs are valid");
