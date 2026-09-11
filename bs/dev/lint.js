#!/usr/bin/env -S npx nodejsscript
import { describeFromReadme } from "../.common.js";
import { biome } from "./biome.js";

// depends on
const tsc = "node_modules/.bin/tsc";

if ($.isMain(import.meta))
	$.api("", true)
		.describe(describeFromReadme())
		.option("--fix", "Apply fixes", false)
		.option("--verbose", "Verbose output", false)
		.action(function main({ fix, verbose } = {}) {
			$.is_verbose = verbose;
			lintFE(fix);
			$.exit(0);
		})
		.parse();

export function lintFE(fix = false) {
	biome("Linting", fix);
	const isInteractive = !$.is_verbose && !$.isFIFO(1);
	try {
		if (isInteractive) echo.use("-R", "… Typechecking");
		s.$("-FS").run`${tsc} --noEmit`;
		if (isInteractive) echo("✓ Typechecking");
	} catch (e) {
		if (isInteractive) echo("✗ Typechecking");
		echo(e.toString());
		$.exit(e.exitCode || 1);
	}
}
