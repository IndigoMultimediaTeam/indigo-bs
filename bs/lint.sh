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
		echo -e "$overwrite✗ failed: $script"
	fi
done

echo "… linting: exported files" >&2
declare -a files_wanted=()
scan_dir(){
	local -r dir="$1"
	for file in "$dir"/*; do
		if [[ -d "$file" ]]; then
			scan_dir "$file"
			continue
		fi
		files_wanted+=("$file")
	done
}
while read -r candidate; do
	if [[ 'add_item() {' == "$candidate" ]]; then
		continue
	fi
	read -r _ file _ <<< "$candidate"
	file=${file#\"}
	file=${file%\"}
	file=${file//\$SCRIPT_DIR\//}
	# shellcheck disable=SC2016
	if [[ "$file" == '$file' ]]; then
		continue
	fi
	files_wanted+=("$file")
done < <(grep add_item install.sh)
while read -r candidate; do
	if [[ 'discover_scripts() {' == "$candidate" ]]; then
		continue
	fi
	read -r _ dir _ <<< "$candidate"
	dir=${dir#\"}
	dir=${dir%\"}
	# shellcheck disable=SC2016
	if [[ "$dir" =~ '$dir' ]]; then
		continue
	fi
	scan_dir "$dir"
done < <(grep discover_scripts install.sh)

declare -a files_exported=()
while read -r candidate; do
	read -r _ file _ <<< "$candidate"
	file=${file#\"}
	file=${file/\",/}
	files_exported+=("$file")
done < <(npm pack --dry-run --json --silent)

declare -a files_missing=()
for file in "${files_wanted[@]}"; do
	if [[ ! " ${files_exported[*]} " =~ \ $file\  ]]; then
		files_missing+=("$file")
	fi
done

if [[ ${#files_missing[@]} -gt 0 ]]; then
	echo -e "$overwrite✗ passed: exported files" >&2
	printf '  %s\n' "${files_missing[@]}" >&2
	exit 1
fi
echo -e "$overwrite✓ passed: exported files" >&2
