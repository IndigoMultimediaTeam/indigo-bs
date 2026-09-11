#!/usr/bin/env bash

# Lint shell scripts using shellcheck
# Usage: bs/lint.sh [script1.sh script2.sh ...]

if ! command -v shellcheck &>/dev/null; then
	echo "⚠ shellcheck not installed" >&2
	exit 1
fi

SCRIPTS=${*:-install.sh bs/lint.sh}

lint(){
	script="$1"
	bash -n "$script"
	shellcheck --color --external-sources -x "$script"
}

declare -r overwrite='\e[1A\e[K'
for script in $SCRIPTS; do
	echo "… linting: $script" >&2

	if [[ ! -f "$script" ]]; then
		echo -e "$overwrite⚠ not found: $script" >&2
		continue
	fi

	if lint "$script"; then
		echo -e "$overwrite✓ passed: $script" >&2
	else
		echo -e "$overwrite✗ passed: $script"
	fi
done
