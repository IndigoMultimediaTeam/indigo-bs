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

# ---------------------------------------------------------------------------
# Discovered link items (parallel arrays)
# ---------------------------------------------------------------------------
declare -a ITEM_SOURCE=()
declare -a ITEM_TARGET=()
declare -a ITEM_LABEL=()
declare -a ITEM_SELECTED=()

add_item() {
	local -r source="$1" target="$2" label="$3"
	ITEM_SOURCE+=("$source")
	ITEM_TARGET+=("$target")
	ITEM_LABEL+=("$label")
	ITEM_SELECTED+=(1) # selected by default; user can deselect
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

	# Directory must exist before realpath can compute a relative path into it
	local target_dir
	target_dir="$(dirname "$target")"
	mkdir -p "$target_dir"

	local relative_path
	relative_path="$(realpath --relative-to="$target_dir" "$source")"

	ln -s "$relative_path" "$target"
	echo -e "${GREEN}✓${NC}  Created symlink: $target -> $relative_path"
	return 0
}

extract_readme_section() {
	local -r source_file="$1"
	local -r pattern="$2"

	local line hashes
	local -i printing=0 level=0 cur_level=0

	# `level` captures the heading depth of the matched (section start) line.
	# We print the matched line, then keep printing every subsequent line
	# until we reach another heading whose level is equal or higher
	# (i.e. a sibling or parent — `cur_level <= level`). Child headings
	# (deeper nesting, larger `cur_level`) are kept as part of the section.
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
# copy head of $SCRIPT_DIR/bs-shared/README.md to ./bs/README.md if needed
# copy `#* $file` section from $SCRIPT_DIR/bs-shared/README.md to ./bs/README.md if needed
copy_readme_section() {
	local -r file="$1"
	local -r readme='bs/README.md'
	if [[ ! -e "./$readme" ]]; then
		mkdir -p ./bs
		head "$SCRIPT_DIR/bs-shared/README.md" -n 5 > ./"$readme"
		echo -e "${GREEN}✓${NC}  Created ./$readme from template"
	fi

	# check if the specific section already exists in ./bs/README.md
	local -r relative_file="$(realpath --relative-to="$SCRIPT_DIR" "$file")"
	local -r relative_file_re="${relative_file//./\\.}"
	local -r section_pattern="^#+[[:space:]]+${relative_file_re/bs-shared\//bs\/}.*\$"

	if grep -qE "$section_pattern" "./$readme" 2>/dev/null; then
		return 0
	fi

	local -r source_readme="$SCRIPT_DIR/bs-shared/README.md"
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

# ---------------------------------------------------------------------------
# Discovery: walk bs-shared/ and collect every candidate link (source -> target)
# without touching the filesystem or prompting.
# ---------------------------------------------------------------------------
discover_scripts() {
	local -r dir="$1"
	local -r path="$2"
	local -r dir_target="${3:-$dir}"

	local prev_shopt
	prev_shopt="$(shopt -p dotglob nullglob)"
	shopt -s dotglob nullglob

	for file in "$SCRIPT_DIR/$dir"/*; do
		if [[ "$SCRIPT_DIR/bs-shared/README.md" == "$file" ]]; then
			continue
		fi

		if [[ -f "$file" ]]; then
			local target
			target="$path/$dir_target/$(basename "$file")"
			add_item "$file" "$target" "$dir/$(basename "$file")"
			continue
		fi

		if [[ -d "$file" ]]; then
			discover_scripts "$dir/$(basename "$file")" "$path" "$dir_target/$(basename "$file")"
		fi
	done

	eval "$prev_shopt"
}

# ---------------------------------------------------------------------------
# Interactive selection UI
# ---------------------------------------------------------------------------

print_list() {
	local i note
	for i in "${!ITEM_LABEL[@]}"; do
		local mark=" "
		(( ITEM_SELECTED[i] )) && mark="x"
		note=""
		if [[ -e "${ITEM_TARGET[i]}" ]]; then
			note="${YELLOW}⚠${NC}$note"
		fi
		if [[ ! -d "$(dirname "${ITEM_TARGET[i]}")" ]]; then
			note="∄$note"
		fi
		if [[ -n "$note" ]]; then
			note="  $note"
		fi
		printf "  %2d. [%s] %s%s\n" \
			"$((i + 1))" "$mark" "${ITEM_LABEL[i]} -> ${ITEM_TARGET[i]}" "$(echo -e "$note")"
	done
}

print_list_only() {
	local i
	for i in "${!ITEM_LABEL[@]}"; do
		echo "$SCRIPT_DIR/${ITEM_LABEL[i]}"
	done
}

toggle_selection_range() {
	local start="$1"
	local end="$2"
	if (( start > end )); then
		local tmp=$start
		start=$end
		end=$tmp
	fi

	for (( n = start; n <= end; n++ )); do
		if (( n >= 1 && n <= ${#ITEM_LABEL[@]} )); then
			ITEM_SELECTED[n - 1]=$(( 1 - ITEM_SELECTED[n - 1] ))
		fi
	done
}
toggle_selection() {
	local -r input="$1"
	local token start end n

	for token in $input; do
		if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
			toggle_selection_range "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
		elif  [[ "$token" =~ ^-([0-9]+)$ ]]; then
			toggle_selection_range 1 "${BASH_REMATCH[1]}"
		elif [[ "$token" =~ ^([0-9]+)-$ ]]; then
			toggle_selection_range "${BASH_REMATCH[1]}" "${#ITEM_LABEL[@]}"
		elif [[ "$token" =~ ^[0-9]+$ ]]; then
			if (( token >= 1 && token <= ${#ITEM_LABEL[@]} )); then
				ITEM_SELECTED[token - 1]=$(( 1 - ITEM_SELECTED[token - 1] ))
			fi
		else
			echo -e "${RED}✗${NC}  Ignoring invalid selection: $token" >&2
		fi
	done
}

selection_step() {
	local sel_input
	while true; do
		echo ""
		echo "Select what to link:"
		print_list
		echo ""
		echo "  Toggle: numbers/ranges, e.g. '1 3 5' or '1-5'/'-5'/'5-'"
		echo -e "  ${YELLOW}⚠ will overwrite existing file${NC}"
		echo -e "  ∄ directory will be created"
		echo "  Leave blank and press enter when done"
		read -rp "> " sel_input

		[[ -z "$sel_input" ]] && break
		toggle_selection "$sel_input"
	done
}

# Returns 0 to proceed with install, 1 to go back to selection
confirmation_step() {
	echo ""
	echo "Confirm the following actions:"
	print_list

	local any_selected=0 i
	for i in "${!ITEM_SELECTED[@]}"; do
		if (( ITEM_SELECTED[i] )); then
			any_selected=1
			break
		fi
	done
	if (( ! any_selected )); then
		echo ""
		echo -e "${YELLOW}⚠${NC}  Nothing selected — nothing will happen."
	fi

	echo ""
	local confirm
	read -rp "Proceed with installation? [y/N/b=back]: " confirm
	case "$confirm" in
		[yY][eE][sS]|[yY])
			return 0
			;;
		[bB]|back|BACK)
			return 1
			;;
		*)
			echo "Aborted."
			exit 0
			;;
	esac
}

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

print_usage() {
	local -r script="$(basename "${BASH_SOURCE[0]}")"
	cat <<EOF
@indigomultimediateam/indigo-bs installer

Creates relative symlinks for shared configs and build scripts (.editorconfig
and everything under bs-shared/) into the current project. Relative symlinks work
cross-platform and avoid git false positives.

Usage:
  $script [options]

Options:
  -h, --help          Show this help message and exit
  -l, --list          List discovered items with their source paths and exit
  -s, --select SPEC   Choose items non-interactively, skipping the selection
                      screen. SPEC uses the same syntax as the interactive
                      prompt (see below), e.g. "1-5 7" or "all 3".
  -y, --yes           Skip the confirmation screen and proceed automatically.
                      Combine with --select for a fully non-interactive run.

Without --select, you'll be shown a numbered list of items to link and asked
which ones to include:
  Toggle:     numbers/ranges, e.g. '1 3 5' or '1-5'
  Leave blank and press enter when done

Without --yes, you'll then see a confirmation screen listing exactly what
will be linked (with a warning for anything that would overwrite an existing
file). Answer 'b' there to go back and change your selection.

Examples:
  $script --list
  $script --select "1-5 7" --yes
EOF
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
	local select_arg="" auto_yes=0 list_only=0

	while [[ $# -gt 0 ]]; do
		case "$1" in
			-h|--help)
				print_usage
				exit 0
				;;
			-l|--list)
				list_only=1
				;;
			-s|--select)
				shift
				if [[ $# -eq 0 ]]; then
					echo -e "${RED}✗${NC}  --select requires an argument" >&2
					exit 1
				fi
				select_arg="$1"
				;;
			--select=*)
				select_arg="${1#*=}"
				;;
			-y|--yes)
				auto_yes=1
				;;
			*)
				echo -e "${RED}✗${NC}  Unknown option: $1" >&2
				print_usage
				exit 1
				;;
		esac
		shift
	done

	if (( !list_only )); then
		echo "============================================="
		echo "  @indigomultimediateam/indigo-bs Installer  "
		echo "============================================="
		echo ""
		echo "This script creates relative symlinks for shared configurations."
		echo "Relative symlinks work cross-platform and avoid git false positives."
		echo "Run with --help for more details."
	fi

	add_item "$SCRIPT_DIR/.editorconfig" "./.editorconfig" ".editorconfig"
	discover_scripts .github . .github
	discover_scripts bs-shared . bs

	if (( list_only )); then
		print_list_only
		exit 0
	fi

	if [[ -n "$select_arg" ]]; then
		local i
		for i in "${!ITEM_LABEL[@]}"; do ITEM_SELECTED[i]=0; done
		toggle_selection "$select_arg"
	else
		selection_step
	fi

	if (( auto_yes )); then
		echo ""
		echo "Proceeding non-interactively with:"
		print_list
	else
		while ! confirmation_step; do
			selection_step
		done
	fi

	echo ""
	local i source target
	for i in "${!ITEM_LABEL[@]}"; do
		if (( ITEM_SELECTED[i] )); then
			source="${ITEM_SOURCE[i]}"
			target="${ITEM_TARGET[i]}"

			# Guard against an empty target (defensive) and refuse to delete
			# anything that isn't a file or symlink, so a stray directory or
			# unexpected entry can't be wiped by the rm below.
			[[ -n "$target" ]] || { echo -e "${RED}✗${NC}  Empty target, skipping" >&2; continue; }
			if [[ -L "$target" || -f "$target" ]]; then
				rm -f "$target"
			elif [[ -e "$target" ]]; then
				echo -e "${YELLOW}⚠${NC}  Refusing to overwrite non-file: $target" >&2
				continue
			fi
			default_link "$source" "$target"

			if [[ "$source" == "$SCRIPT_DIR/bs-shared/"* ]]; then
				copy_readme_section "$source"
			fi
		fi
	done

	echo ""
	echo "============================================"
	echo "	Installation complete!"
	echo "============================================"
	echo ""
	echo "You can now use the shared configs and build scripts."

	# Only hint about the git hooks setup if the user actually selected it.
	local prepare_selected=0 i
	for i in "${!ITEM_LABEL[@]}"; do
		if (( ITEM_SELECTED[i] )) && [[ "${ITEM_LABEL[i]}" == "npm/hooks/prepare" ]]; then
			prepare_selected=1
			break
		fi
	done
	if (( prepare_selected )); then
		echo "Run 'bs/npm/hooks/prepare' to set up git hooks."
	fi
}

main "$@"
