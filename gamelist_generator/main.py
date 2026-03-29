import argparse
import xml.etree.ElementTree as ET
from pathlib import Path
from xml.dom import minidom


def generate_gamelist(rom_dir: Path, output_dir: Path) -> None:
    root = ET.Element("gameList")

    for rom_file in sorted(rom_dir.iterdir()):
        if rom_file.is_file():
            game = ET.SubElement(root, "game")
            ET.SubElement(game, "path").text = f"./{rom_file.name}"
            ET.SubElement(game, "name").text = rom_file.stem

    output_dir.mkdir(parents=True, exist_ok=True)
    output_file = output_dir / "gamelist.xml"

    xml_str = minidom.parseString(ET.tostring(root, encoding="unicode")).toprettyxml(indent="  ")
    # Remove the extra XML declaration added by toprettyxml
    lines = xml_str.splitlines(keepends=True)
    pretty = "".join(lines[1:])

    output_file.write_text(pretty, encoding="utf-8")
    print(f"Written: {output_file}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate ES-DE gamelist.xml files from ROM directories")
    parser.add_argument("input", help="Path to the ROMs directory (contains subfolders per system)")
    parser.add_argument("output", help="Path to the ES-DE gamelists directory")
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.is_dir():
        parser.error(f"Input path does not exist or is not a directory: {input_path}")

    system_dirs = [d for d in sorted(input_path.iterdir()) if d.is_dir()]

    if not system_dirs:
        print("No system subdirectories found in input path.")
        return

    for system_dir in system_dirs:
        generate_gamelist(system_dir, output_path / system_dir.name)


if __name__ == "__main__":
    main()
