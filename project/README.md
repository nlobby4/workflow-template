# project/

This folder contains the actual project code. A project exposes itself to the
wrapper by adding a project-local `.nlobby4.yml` file.

## Dependency and image ownership

Each project owns and installs its ecosystem-specific dependencies. For example,
a JavaScript or TypeScript project declares ESLint in its own package manifest
rather than relying on the root Dev Container to provide it.

Projects may include their own Dockerfile when they need a dedicated build or
runtime image. Those images can be built and tested with the root Dev
Container's isolated Docker-in-Docker daemon. Project-specific tools and image
requirements should remain at this layer unless they become universal repository
infrastructure.

## Add a Project

1. Create or copy the project into a subdirectory:

   ```text
   project/my-app/
   ```

2. Add a project specification from anywhere inside the repository:

   ```bash
   nlobby4 add my-app
   ```

   If `inquirer` is already available in the repository dependency tree, this
   command uses an interactive questionnaire. Otherwise it falls back to shell
   prompts.

   The command creates the project folder if needed, or uses the existing folder
   when it already exists. It then writes:

   ```text
   project/my-app/.nlobby4.yml
   ```

   ```yaml
   # yaml-language-server: $schema=../../schemas/nlobby4-project.schema.json

   version: 1
   name: my-app
   type: app
   description: My application.

   language:
     primary: javascript

   tools:
     packageManager: npm

   commands:
     setup:
       run: npm ci --ignore-scripts
       required: true
       tools:
         - npm
     test:
       run: npm test
       required: false
       tools:
         - npm
     build:
       run: npm run build
       required: true
       tools:
         - npm
     dev:
       run: npm run dev
       required: false
       tools:
         - npm

   paths:
     sources:
       - src/**/*
     tests:
       - test/**/*
     config:
       - package.json
       - package-lock.json
   ```

3. Verify the wrapper can discover the project:

   ```bash
   npm run gate:list
   ```

4. Run project commands through the wrapper:

   ```bash
   npm run gate:run -- my-app setup
   npm run gate:run -- my-app test
   npm run gate:run -- my-app build
   ```

5. If this project should be the default project used by root `npm test`, update
   the root `package.json` script:

   ```json
   {
     "scripts": {
       "test:project": "npm run gate:run -- my-app test"
     }
   }
   ```

Keep project-local build outputs, dependency folders, and generated files
ignored by the project-level `.gitignore`. Update the root `.gitignore` only
when the wrapper itself needs to track a new root-level file or directory.

## Commands and Tools

Project commands are the compatibility surface consumed by the wrapper. Keep the
command body project-native, and use `tools` to declare executables the wrapper
should check before running the command.

```yaml
commands:
  test:
    run: cargo test --all-features
    required: true
    tools:
      - cargo
```

`required: true` means a missing declared tool fails the gate. `required: false`
uses the repository-level `missingTools` policy from `.nlobby4.yml`.

If a project needs more translation than direct commands can provide, add an
executable adapter:

```text
project/my-app/.nlobby4/gate.sh
```

The adapter receives the requested command name as its first argument, followed
by any extra arguments passed through the wrapper.

## Dependency Caches

The devcontainer currently mounts only the root npm cache because the wrapper
itself uses npm during setup:

```text
/home/nlobby4/.npm
```

Language-specific caches should be enabled only when the wrapped project or its
adapter installs dependencies for that ecosystem. Add extra devcontainer mounts
only when a project repeatedly benefits from preserving that package-manager
cache across container rebuilds.

| Ecosystem | Cache path                      |
| --------- | ------------------------------- |
| Python    | `/home/nlobby4/.cache/pip`      |
| uv        | `/home/nlobby4/.cache/uv`       |
| Rust      | `/home/nlobby4/.cargo/registry` |
| Rust      | `/home/nlobby4/.cargo/git`      |
| Go        | `/home/nlobby4/go/pkg/mod`      |
| Gradle    | `/home/nlobby4/.gradle/caches`  |
| Maven     | `/home/nlobby4/.m2/repository`  |

Repository-local tool caches belong under `.cache/`, such as `.cache/general`.
Home-directory package-manager caches belong in devcontainer mounts when they
are needed.
