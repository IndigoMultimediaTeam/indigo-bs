#!/usr/bin/env bash

# @indigomultimediateam/indigo-bs installer
# Creates relative symlinks for shared configs and build scripts

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" || {
	echo "Failed to get script directory" >&2
	exit 1
}

# Function to create relative symlink
default_link() {
	local -r source="$1"
	local -r target="$2"

	if [[ ! -e "$source" ]]; then
		echo -e "${RED}✗${NC}  Source not found: $source" >&2
		return 1
	fi

	if [[ -e "$target" ]]; then
		echo -e "${YELLOW}⚠${NC}  $target already exists"
		return 1
	fi

	# Get relative path from target to source
	local target_dir
	target_dir="$(dirname "$target")"
	local relative_path
	relative_path="$(realpath --relative-to="$target_dir" "$source")"

	mkdir -p "$(dirname "$target")"

	ln -s "$relative_path" "$target"
	echo -e "${GREEN}✓${NC}  Created symlink: $target -> $relative_path"
	return 0
}

prompt_link() {
	local -r source="$1"
	local -r target="$2"

	local response overwrite
	read -p "Link $target ($target -> $source)? [y/N]: " -r response
	case "$response" in
		[yY][eE][sS]|[yY])
			if default_link "$source" "$target"; then
				return 0
			else
				read -p "  Overwrite? [y/N]: " -r overwrite
				case "$overwrite" in
					[yY][eE][sS]|[yY])
						rm -rf "$target"
						default_link "$source" "$target"
						return 0
						;;
					*)
						echo -e "${YELLOW}⚠${NC}  Skipped $target"
						return 0
						;;
				esac
			fi
			;;
		*)
			echo -e "${YELLOW}⚠${NC}  Skipped $target"
			return 0
			;;
	esac
}

extract_readme_section() {
	local -r source_file="$1"
	local -r pattern="$2"

	local line hashes
	local -i printing=0 level=0 cur_level=0

	while IFS= read -r line || [[ -n "$line" ]]; do
		if [[ "$line" =~ $pattern ]]; then
			hashes="${line%%[^#]*}"
			level=${#hashes}
			printing=1
			printf '%s\n' "$line"
			continue
		fi

		if (( printing )); then
			if [[ "$line" =~ ^#+[[:space:]] ]]; then
				hashes="${line%%[^#]*}"
				cur_level=${#hashes}
				if (( cur_level <= level )); then
					return 0
				fi
			fi
			printf '%s\n' "$line"
		fi
	done < "$source_file"
}

# create ./bs/README.md if needed
# copy head of $SCRIPT_DIR/bs/README.md to ./bs/README.md if needed
# copy `#* $file` section from $SCRIPT_DIR/bs/README.md to ./bs/README.md if needed
copy_readme_section() {
	local -r file="$1"
	local -r readme='bs/README.md'
	if [[ ! -e "./$readme" ]]; then
		mkdir -p ./bs
		head "$SCRIPT_DIR/$readme" -n 5 > ./bs/README.md
		echo -e "${GREEN}✓${NC}  Created ./$readme from template"
	fi

	# check if the specific section already exists in ./bs/README.md
	local -r relative_file="$(realpath "$file" --relative-to="$SCRIPT_DIR")"
	local -r relative_file_re="${relative_file//./\\.}"
	local -r section_pattern="^#+[[:space:]]+${relative_file_re}[[:space:]]*\$"

	if grep -qE "$section_pattern" "./$readme" 2>/dev/null; then
		return 0
	fi

	local -r source_readme="$SCRIPT_DIR/$readme"
	if [[ ! -e "$source_readme" ]]; then
		return 0
	fi

	local section
	section="$(extract_readme_section "$source_readme" "$section_pattern")"

	if [[ -z "$section" ]]; then
		echo -e "${YELLOW}⚠${NC}  No README section found for $relative_file" >&2
		return 1
	fi

	{
		echo ""
		echo "$section"
	} >> "./$readme"
	echo -e "${GREEN}✓${NC}  Added README section for $relative_file"
	return 0
}

prompt_dir(){
	local -r dir="$1"
	local -r path="$2"

	local response
	read -p "'$dir' directory not found in '$path'. Create it? [y/N]: " -r response
	case "$response" in
		[yY][eE][sS]|[yY])
			mkdir -p "$path/$dir"
			echo -e "${GREEN}✓${NC}  Created directory: $path/$dir"
			;;
		*)
			echo -e "${YELLOW}⚠${NC}  Skipped $path/$dir"
			return 1
			;;
	esac
}

process_scripts(){
	local -r dir="$1"
	local -r path="$2"

	if [[ ! -d "$path/$dir" ]]; then
		if ! prompt_dir "$dir" "$path"; then
			return 0
		fi
	fi

	local -r prev_shopt="$(shopt -p dotglob nullglob)"
	shopt -s dotglob nullglob

	for file in "$SCRIPT_DIR/$dir"/*; do
		if [[ "$SCRIPT_DIR/bs/README.md" == "$file" || "$SCRIPT_DIR/bs/lint.sh" == "$file" ]]; then
			continue
		fi
		if [[ -f "$file" ]]; then
			prompt_link "$file" "$path/$dir/$(basename "$file")"
			copy_readme_section "$file"
			continue
		fi

		if [[ -d "$file" ]]; then
			process_scripts "$dir/$(basename "$file")" "$path"
		fi
	done

	eval "$prev_shopt"
}

echo "============================================="
echo "  @indigomultimediateam/indigo-bs Installer  "
echo "============================================="
echo ""
echo "This script creates relative symlinks for shared configurations."
echo "Relative symlinks work cross-platform and avoid git false positives."
echo ""

# Link .editorconfig
prompt_link "$SCRIPT_DIR/.editorconfig" "./.editorconfig"
echo ""

process_scripts bs .
echo ""

echo "============================================"
echo "	Installation complete!"
echo "============================================"
echo ""
echo "You can now use the shared configs and build scripts."
echo "Run 'bs/npm/hooks/prepare' to set up git hooks."
