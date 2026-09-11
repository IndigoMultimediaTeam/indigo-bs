# bs: Build system based on executables
This project uses [jaandrle/bs: The simplest possible build system using executable/bash scripts](https://github.com/jaandrle/bs).

## Available executables

### Development

#### bs/dev/lint.js
Runs Biome **linting** + TypeScript **type checking**.

**Options**:
- `--fix`: Apply automatic fixes
- `--verbose`: Show detailed output

#### bs/dev/biome.js
Formats/Lints the codebase using [Biome](https://biomejs.dev/guides/getting-started/).

**Usage**:
```bash
bs/dev/biome.js [method]
```

**Methods**:
- `Formatting` (default) - Format code
- `Linting` - Lint code
- `All` - Run both formatting and linting

**Options**:
- `--fix`: Apply automatic fixes
- `--verbose`: Show detailed output

#### bs/dev/codebase-analyzer
Analyzes the codebase using [fallow](https://github.com/jaandrle/fallow).

**Usage**:
```bash
bs/dev/codebase-analyzer [fallow-options]
```

### Git Hooks

#### bs/git/hooks/post-merge
Automatically runs `npm ci` when `package-lock.json` changes after a git merge.

### NPM Scripts

#### bs/npm/hooks/prepare
NPM life-cycle script that registers git hooks path.

#### bs/npm/install-audit
Audits npm package installations.

**Usage**:
```bash
bs/npm/install-audit [package]
```

#### bs/npm/lint
Validates `package.json` lockfile consistency using [lockfile-lint](https://github.com/jaandrle/lockfile-lint).

**Usage**:
```bash
bs/npm/lint
```

#### bs/npm/update
Interactively updates dependencies using [npm-check-updates](https://github.com/raineorshine/npm-check-updates).

**Usage**:
```bash
bs/npm/update
```

**Options**:
- Updates are grouped by type
- 7-day cooldown period between update checks

