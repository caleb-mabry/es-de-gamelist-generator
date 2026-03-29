#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <input_path> <output_path>"
    echo ""
    echo "  input_path   ROMs directory containing one subfolder per system"
    echo "  output_path  ES-DE gamelists directory"
    exit 1
}

[[ $# -ne 2 ]] && usage

INPUT="$1"
OUTPUT="$2"

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
