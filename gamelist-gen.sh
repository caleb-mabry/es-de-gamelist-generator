#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <input_path> <output_path> [--include-word WORD]"
    echo ""
    echo "  input_path     ROMs directory containing one subfolder per system"
    echo "  output_path    ES-DE gamelists directory"
    echo "  --include-word Only include files whose name contains WORD (case insensitive)"
    exit 1
}

[[ $# -lt 2 ]] && usage

INPUT="$1"
OUTPUT="$2"
INCLUDE_WORD=""

shift 2
while [[ $# -gt 0 ]]; do
    case "$1" in
        --include-word)
            [[ $# -lt 2 ]] && { echo "Error: --include-word requires a value"; exit 1; }
            INCLUDE_WORD="$2"
            shift 2
            ;;
        *) echo "Unknown argument: $1"; usage ;;
    esac
done

if [[ ! -d "$INPUT" ]]; then
    echo "Error: input path does not exist or is not a directory: $INPUT"
    exit 1
fi

found=0
for system_dir in "$INPUT"/*/; do
    [[ ! -d "$system_dir" ]] && continue
    found=1

    system_name=$(basename "$system_dir")
    out_dir="$OUTPUT/$system_name"
    mkdir -p "$out_dir"

    {
        echo "<gameList>"
        while IFS= read -r rom_file; do
            [[ ! -f "$system_dir/$rom_file" ]] && continue
            if [[ -n "$INCLUDE_WORD" ]]; then
                echo "$rom_file" | grep -qi "$INCLUDE_WORD" || continue
            fi
            name="${rom_file%.*}"
            echo "  <game>"
            echo "    <path>./$rom_file</path>"
            echo "    <name>$name</name>"
            echo "  </game>"
        done < <(ls "$system_dir" | sort)
        echo "</gameList>"
    } > "$out_dir/gamelist.xml"

    echo "Written: $out_dir/gamelist.xml"
done

if [[ $found -eq 0 ]]; then
    echo "No system subdirectories found in input path."
fi
