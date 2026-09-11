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

The script links `.editorconfig` and then walks the `bs/` directory, prompting
you individually for **each file** it finds (not the directory as a whole).
This means you can accept a symlink for most scripts while keeping a local
override for one you've customized — declining a file just skips it and
leaves the rest of the install untouched.

The script is interactive and expects a terminal; it isn't currently safe to
run unattended in CI or as an npm `postinstall` hook.

**Non-interactive install:** for CI or scripted bootstraps on a clean checkout,
pipe `yes` into the script to auto-confirm every prompt:
```bash
yes | ./node_modules/@indigomultimediateam/indigo-bs/install.sh
```
This also auto-confirms *overwrites*, so only use it on a fresh checkout —
running it against an existing setup may silently replace files you meant to keep.

**Benefits of relative symlinks:**
- Cross-platform compatibility (works on Windows, macOS, Linux)
- No git false positives for file changes

**Re-running the script:** existing symlinks (or files) are reported as
"already exists" and left alone unless you explicitly confirm an overwrite,
so re-running after an update is safe — it won't clobber local
customizations without asking first.

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
| `bs/dev/lint.js` | Run Biome linting + TypeScript type checking |
| `bs/dev/biome.js` | Format/lint codebase using Biome |
| `bs/dev/codebase-analyzer` | Analyze codebase using fallow |
| `bs/npm/hooks/prepare` | Register git hooks path |
| `bs/npm/install-audit` | Audit npm package installations |
| `bs/npm/lint` | Validate lockfile consistency |
| `bs/npm/update` | Interactively update dependencies |
| `bs/git/hooks/post-merge` | Auto-run `npm ci` on package-lock.json changes |

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
