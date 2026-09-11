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

Add as a dependency:
```bash
npm install @indigomultimediateam/indigo-bs --save-dev
```

Or link the `bs/` directory into your project:
```bash
ln -s node_modules/@indigomultimediateam/indigo-bs/bs ./bs
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

## Usage Patterns

### 1. As npm Dependency (Recommended)

```bash
npm install @indigomultimediateam/indigo-bs --save-dev
```

Then reference scripts directly:
```json
{
  "scripts": {
    "lint": "node ./node_modules/@indigomultimediateam/indigo-bs/bs/dev/lint.js",
    "format": "node ./node_modules/@indigomultimediateam/indigo-bs/bs/dev/biome.js Formatting --fix"
  }
}
```

### 2. Via Symlink

```bash
ln -s node_modules/@indigomultimediateam/indigo-bs/bs ./bs
ln -s node_modules/@indigomultimediateam/indigo-bs/biome.json ./
ln -s node_modules/@indigomultimediateam/indigo-bs/tsconfig.json ./
```

Then use as if local files:
```json
{
  "scripts": {
    "lint": "./bs/dev/lint.js"
  },
  "extends": "./tsconfig.json"
}
```

### 3. Copy Files Directly

For projects that prefer direct file copying:
```bash
cp node_modules/@indigomultimediateam/indigo-bs/bs/* ./bs/
cp node_modules/@indigomultimediateam/indigo-bs/*.json ./
```

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

