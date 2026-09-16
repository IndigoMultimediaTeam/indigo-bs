# bs: Build system based on executables
This project uses [jaandrle/bs: The simplest possible build system using executable/bash scripts](https://github.com/jaandrle/bs).

## Available executables

### bs/dev/lint.js [--fix|--verbose]
Runs Biome **linting** + TypeScript **type checking**.

### bs/dev/biome.js [Linting|Formatting|All] [--fix|--verbose]
Formats/Lints the codebase using [Biome](https://biomejs.dev/guides/getting-started/).

### bs/dev/codebase-analyzer [fallow-options]
Analyzes the codebase using [fallow](https://github.com/jaandrle/fallow).

#### bs/git/hooks/post-merge
Automatically runs `npm ci` when `package-lock.json` changes after a git merge.

#### bs/npm/hooks/prepare
NPM life-cycle script that registers git hooks path.

#### bs/npm/install-audit [package]
Audits npm package installations.

#### bs/npm/lint
Validates `package.json` lockfile consistency using [lockfile-lint](https://github.com/jaandrle/lockfile-lint).

#### bs/npm/update
Interactively updates dependencies using [npm-check-updates](https://github.com/raineorshine/npm-check-updates).
