# @indigomultimediateam/indigo-bs

Shared configuration and build system utilities for Indigo projects.

## Overview

This package provides reusable configurations and build scripts that can be shared across multiple projects via npm dependency or direct file linking.

## Shared Configurations

### TypeScript Configs

Extendable TypeScript configurations for different environments:

- **`./biome.json`** - Biome code formatter and linter configuration
- **`./tsconfig.json`** - Base TypeScript configuration
- **`./tsconfig.react.json`** - TypeScript configuration for React projects

Usage in your project:
```json
{
  "extends": "@indigomultimediateam/indigo-bs/tsconfig.json"
}
```

### Editor Config

- **`./.editorconfig`** - Shared editor configuration (can be linked or copied)

## Build System (bs/)

A collection of executable scripts for consistent build, development, and maintenance workflows.

### Installation

#### Option 1: Using the Install Script (Recommended)

Run the install script to create relative symlinks for both configs and build scripts:
```bash
# From your project root, after installing the package as a dependency
./node_modules/@indigomultimediateam/indigo-bs/install.sh
```

The script discovers all files under `bs/` and `.editorconfig`, then presents
you with an interactive selection interface. You can accept symlinks for most
scripts while keeping local overrides for customized ones — declining a file
simply skips it, leaving the rest of the install untouched.

**Interactive features:**
- Toggle individual items or ranges (e.g., `1 3 5` or `1-5`)
- Existing files are marked with ⚠ (will be overwritten if selected)
- Missing directories are marked with ∄ (will be created)
- Type `b` at confirmation to go back and change your selection

**Non-interactive install:** for CI or scripted bootstraps on a clean checkout,
use the `--select` and `--yes` flags:
```bash
# Select specific items by number
./node_modules/@indigomultimediateam/indigo-bs/install.sh --select "1-5 7" --yes

# Select all items
./node_modules/@indigomultimediateam/indigo-bs/install.sh --select all --yes
```

You can also list discovered items without installing:
```bash
./node_modules/@indigomultimediateam/indigo-bs/install.sh --list
```

**Note:** The script also automatically maintains a local `bs/README.md` by
copying relevant sections from the source documentation for each script you link.

**Benefits of relative symlinks:**
- Cross-platform compatibility (works on Windows, macOS, Linux)
- No git false positives for file changes

**Re-running the script:** existing symlinks (or files) are reported and left
alone unless explicitly selected for overwrite, so re-running after an update
is safe — it won't clobber local customizations without asking first.

#### Option 2: Manual Symlinks

Add as a dependency:
```bash
npm install @indigomultimediateam/indigo-bs --save-dev
```
For the same per-file flexibility as the install script (able to override
any one script under `bs/` without breaking the rest):
```bash
PKG=node_modules/@indigomultimediateam/indigo-bs

mkdir -p bs/dev bs/git/hooks bs/npm/hooks

# bs/dev/* and bs/npm/* are 2 directories deep -> ../..
ln -rs "$PKG"/bs/dev/biome.js bs/dev/biome.js
ln -rs "$PKG"/bs/dev/codebase-analyzer bs/dev/codebase-analyzer
ln -rs "$PKG"/bs/dev/lint.js bs/dev/lint.js
ln -rs "$PKG"/bs/npm/install-audit bs/npm/install-audit
ln -rs "$PKG"/bs/npm/lint bs/npm/lint
ln -rs "$PKG"/bs/npm/update bs/npm/update

# bs/git/hooks/* and bs/npm/hooks/* are 3 directories deep -> ../../..
ln -rs "$PKG"/bs/git/hooks/post-merge bs/git/hooks/post-merge
ln -rs "$PKG"/bs/npm/hooks/prepare bs/npm/hooks/prepare
```

#### Option 3: Copy Files Directly

Add as a dependency:
```bash
npm install @indigomultimediateam/indigo-bs --save-dev
```

For projects that prefer direct file copying:
```bash
cp node_modules/@indigomultimediateam/indigo-bs/bs/* ./bs/
cp node_modules/@indigomultimediateam/indigo-bs/.editorconfig ./
cp node_modules/@indigomultimediateam/indigo-bs/*.json ./
```

### Available Scripts

See [bs/README.md](./bs/README.md) for complete documentation of all available build scripts.

#### Quick Reference

| Script | Purpose |
|--------|---------|
| `bs/dev/lint.js [--fix|--verbose]` | Run Biome **linting** + TypeScript **type checking** |
| `bs/dev/biome.js [Linting|Formatting|All] [--fix|--verbose]` | Format/lint codebase using [Biome](https://biomejs.dev/guides/getting-started/) |
| `bs/dev/codebase-analyzer [fallow-options]` | Analyze codebase using [fallow](https://github.com/jaandrle/fallow) |
| `bs/git/hooks/post-merge` | Automatically runs `npm ci` when `package-lock.json` changes after a git merge |
| `bs/npm/hooks/prepare` | NPM life-cycle script that registers git hooks path |
| `bs/npm/install-audit [package]` | Audit npm package installations |
| `bs/npm/lint` | Validate `package.json` lockfile consistency using [lockfile-lint](https://github.com/jaandrle/lockfile-lint) |
| `bs/npm/update` | Interactively update dependencies using [npm-check-updates](https://github.com/raineorshine/npm-check-updates) |

## Dependencies

This package requires the following peer dependencies:
- `nodejsscript` (~1) - For running JavaScript-based build scripts
- `typescript` (~7.0) - For TypeScript type checking

And includes these dependencies:
- `@biomejs/biome` (~2.5) - Code formatting and linting
- `fallow` (~3.22) - Codebase analysis
- `lockfile-lint` (~5.0) - Lockfile validation
- `npq` (~2.0) - Package installation auditing
- `npm-check-updates` (~16.14) - Dependency updates

## Related

- [tsconfig/bases](https://github.com/tsconfig/bases) - TSConfigs to extend for various runtime environments
