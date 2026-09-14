#!/usr/bin/env bash

# --------------------------------------------------
# Initialize an nlobby4 project specification.
#
# Usage:
# nlobby4 add <project-name>
#
# The command can run from anywhere inside the repository. It creates
# project/<project-name> when needed and writes
# project/<project-name>/.nlobby4.yml.
# If inquirer is already available in the repository Node dependency tree, the
# script uses it for prompts. Otherwise it falls back to shell prompts.
# --------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../../utils/functions.sh"

project_name="${1:-}"

check_argument "$project_name" "project name"
check_command git
check_command mkdir
check_command node
check_command sed
check_command realpath

repo_root="$(git rev-parse --show-toplevel 2> /dev/null)" || {
  log_error "not inside a git repository"
  exit 1
}

cd "$repo_root"

if [[ ! "$project_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
  log_error "project name must start with a letter or number and contain only letters, numbers, dots, underscores, or hyphens"
  exit 64
fi

project_root="$repo_root/project"
target_directory="$project_root/$project_name"
target_file="$target_directory/.nlobby4.yml"
template_file="$repo_root/scripts/linux/resources/templates/nlobby4-project.yml"
schema_file="$repo_root/schemas/nlobby4-project.schema.json"

check_file "$template_file"
check_file "$schema_file"

if [[ -e "$target_file" ]]; then
  log_error "$target_file already exists"
  exit 1
fi

mkdir -p "$target_directory"
schema_path="$(realpath --relative-to="$target_directory" "$schema_file")"

shell_prompt() {
  local variable_name="$1"
  local prompt="$2"
  local default_value="$3"
  local value

  if [[ -t 0 ]]; then
    read -r -p "$prompt [$default_value]: " value
  else
    value=""
  fi

  printf -v "$variable_name" '%s' "${value:-$default_value}"
}

inquirer_available() {
  node --input-type=module -e "import('inquirer')" > /dev/null 2>&1
}

load_answers_with_inquirer() {
  local answers

  answers="$(
    PROJECT_NAME="$project_name" node --input-type=module << 'NODE'
import process from "node:process";
import inquirer from "inquirer";

const projectName = process.env.PROJECT_NAME;
const shellQuote = (value) => `'${String(value).replaceAll("'", "'\\''")}'`;

async function main() {
  const answers = await inquirer.prompt([
    {
      default: "app",
      message: "Project type",
      name: "PROJECT_TYPE",
      type: "input",
    },
    {
      default: `Project specification for ${projectName}.`,
      message: "Description",
      name: "PROJECT_DESCRIPTION",
      type: "input",
    },
    {
      choices: ["generic", "node", "rust", "go", "python", "java", "cpp"],
      default: "generic",
      message: "Primary language",
      name: "PROJECT_LANGUAGE",
      type: "list",
    },
    {
      default: "npm",
      message: "Package manager or main tool",
      name: "PROJECT_PACKAGE_MANAGER",
      type: "input",
    },
    {
      default: "echo \"No project setup command configured\"",
      message: "Setup command",
      name: "SETUP_COMMAND",
      type: "input",
    },
    {
      default: "echo \"No project format command configured\"",
      message: "Format command",
      name: "FORMAT_COMMAND",
      type: "input",
    },
    {
      default: "echo \"No project lint command configured\"",
      message: "Lint command",
      name: "LINT_COMMAND",
      type: "input",
    },
    {
      default: "echo \"No project test command configured\"",
      message: "Test command",
      name: "TEST_COMMAND",
      type: "input",
    },
    {
      default: "echo \"No project build command configured\"",
      message: "Build command",
      name: "BUILD_COMMAND",
      type: "input",
    },
    {
      default: "**/*",
      message: "Source path glob",
      name: "SOURCE_PATH",
      type: "input",
    },
    {
      default: "test/**/*",
      message: "Test path glob",
      name: "TEST_PATH",
      type: "input",
    },
    {
      default: "package.json",
      message: "Config path",
      name: "CONFIG_PATH",
      type: "input",
    },
  ]);

  for (const [key, value] of Object.entries(answers)) {
    console.log(`${key}=${shellQuote(value)}`);
  }
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
NODE
  )"

  eval "$answers"
}

load_answers_with_shell() {
  shell_prompt PROJECT_TYPE "Project type" "app"
  shell_prompt PROJECT_DESCRIPTION "Description" "Project specification for $project_name."
  shell_prompt PROJECT_LANGUAGE "Primary language" "generic"
  shell_prompt PROJECT_PACKAGE_MANAGER "Package manager or main tool" "npm"
  shell_prompt SETUP_COMMAND "Setup command" "echo \"No project setup command configured\""
  shell_prompt FORMAT_COMMAND "Format command" "echo \"No project format command configured\""
  shell_prompt LINT_COMMAND "Lint command" "echo \"No project lint command configured\""
  shell_prompt TEST_COMMAND "Test command" "echo \"No project test command configured\""
  shell_prompt BUILD_COMMAND "Build command" "echo \"No project build command configured\""
  shell_prompt SOURCE_PATH "Source path glob" "**/*"
  shell_prompt TEST_PATH "Test path glob" "test/**/*"
  shell_prompt CONFIG_PATH "Config path" "package.json"
}

yaml_quote() {
  local value="$1"

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

sed_replacement() {
  local value

  value="$(yaml_quote "$1")"
  value="${value//\\/\\\\}"
  value="${value//&/\\&}"
  value="${value//|/\\|}"

  printf '%s' "$value"
}

command_tool() {
  local command_value="$1"

  if [[ "$command_value" =~ ^[[:space:]]*([[:alnum:]_.-]+) ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
  else
    printf 'sh'
  fi
}

if inquirer_available && [[ -t 0 ]]; then
  load_answers_with_inquirer
else
  load_answers_with_shell
fi

SETUP_TOOL="$(command_tool "$SETUP_COMMAND")"
FORMAT_TOOL="$(command_tool "$FORMAT_COMMAND")"
LINT_TOOL="$(command_tool "$LINT_COMMAND")"
TEST_TOOL="$(command_tool "$TEST_COMMAND")"
BUILD_TOOL="$(command_tool "$BUILD_COMMAND")"

sed \
  -e "s|__SCHEMA_PATH__|$(sed_replacement "$schema_path")|g" \
  -e "s|__PROJECT_NAME__|$(sed_replacement "$project_name")|g" \
  -e "s|__PROJECT_TYPE__|$(sed_replacement "$PROJECT_TYPE")|g" \
  -e "s|__PROJECT_DESCRIPTION__|$(sed_replacement "$PROJECT_DESCRIPTION")|g" \
  -e "s|__PROJECT_LANGUAGE__|$(sed_replacement "$PROJECT_LANGUAGE")|g" \
  -e "s|__PROJECT_PACKAGE_MANAGER__|$(sed_replacement "$PROJECT_PACKAGE_MANAGER")|g" \
  -e "s|__SETUP_COMMAND__|$(sed_replacement "$SETUP_COMMAND")|g" \
  -e "s|__SETUP_TOOL__|$(sed_replacement "$SETUP_TOOL")|g" \
  -e "s|__FORMAT_COMMAND__|$(sed_replacement "$FORMAT_COMMAND")|g" \
  -e "s|__FORMAT_TOOL__|$(sed_replacement "$FORMAT_TOOL")|g" \
  -e "s|__LINT_COMMAND__|$(sed_replacement "$LINT_COMMAND")|g" \
  -e "s|__LINT_TOOL__|$(sed_replacement "$LINT_TOOL")|g" \
  -e "s|__TEST_COMMAND__|$(sed_replacement "$TEST_COMMAND")|g" \
  -e "s|__TEST_TOOL__|$(sed_replacement "$TEST_TOOL")|g" \
  -e "s|__BUILD_COMMAND__|$(sed_replacement "$BUILD_COMMAND")|g" \
  -e "s|__BUILD_TOOL__|$(sed_replacement "$BUILD_TOOL")|g" \
  -e "s|__SOURCE_PATH__|$(sed_replacement "$SOURCE_PATH")|g" \
  -e "s|__TEST_PATH__|$(sed_replacement "$TEST_PATH")|g" \
  -e "s|__CONFIG_PATH__|$(sed_replacement "$CONFIG_PATH")|g" \
  "$template_file" > "$target_file"

log_ok "Created $target_file"
