$.env.FORCE_COLOR = 1;
$.configAssign({ fatal: true });
export const pathBs = $.pathFromURL(import.meta.url);

import { relative } from "node:path";
export function describeFromReadme() {
	if (!$.includes("--help")) return "";
	const readme = s.cat(pathBs`./README.md`);
	const name = relative(pathBs`..`, $[0]);
	const section_start = new RegExp(`^#+ ${name}.*$`);
	const section_end = /^#+ .*$/;
	let curr = false;
	const out = [];
	for (const line of readme.split("\n")) {
		if (!curr && section_start.test(line)) {
			curr = true;
			continue;
		}
		if (curr && section_end.test(line)) break;
		if (curr) out.push(line);
	}
	return out;
}
