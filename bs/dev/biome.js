#!/usr/bin/env -S npx nodejsscript

// depends on
const biome_cli = "node_modules/.bin/biome";

if ($.isMain(import.meta))
	$.api("[method]", true)
		.describe([
			"Formats/Lints the codebase using Biome.",
			"",
			"Methods:",
			"– Formatting (default)",
			"– Linting",
			"– All",
		])
		.option("--fix", "Apply fixes", false)
		.option("--verbose", "Verbose output", false)
		.action(function main(method = "Formatting", { fix, verbose } = {}) {
			$.is_verbose = verbose;
			biome(method, fix);
			$.exit(0);
		})
		.parse();

/**
 * @param {"Linting" | "Formatting" | "All"} method
 * @param {boolean} fix
 */
export function biome(method = "Formatting", fix = false) {
	const head = `Biome ${method}`;
	const isInteractive = !$.is_verbose && !$.isFIFO(1);
	const echoEnd = !isInteractive ? () => ({}) : (ok = false) => echo(`${ok ? "✓" : "✗"} ${head}`);
	if (isInteractive) echo.use("-R", `… ${head}`);
	try {
		const m = method === "Linting" ? "lint" : method === "Formatting" ? "format" : "check";
		const level = method === "Linting" ? "--diagnostic-level=error" : "";
		const f = fix ? "--write" : "";
		s.$("-FS").run`${biome_cli} ${m} ${f} --colors=force ${level}`;
		echoEnd(true);
	} catch (e) {
		echoEnd(false);
		echo(e.toString());
		$.exit(e.exitCode || 1);
	}
}
