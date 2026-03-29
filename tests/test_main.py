import xml.etree.ElementTree as ET
from pathlib import Path

import pytest

from gamelist_generator.main import generate_gamelist, main


# ---------------------------------------------------------------------------
# generate_gamelist
# ---------------------------------------------------------------------------

def test_generates_gamelist_xml(tmp_path):
    rom_dir = tmp_path / "gb"
    rom_dir.mkdir()
    (rom_dir / "Tetris.zip").touch()
    (rom_dir / "SuperMarioLand.zip").touch()

    output_dir = tmp_path / "gamelists" / "gb"
    generate_gamelist(rom_dir, output_dir)

    assert (output_dir / "gamelist.xml").exists()


def test_xml_structure(tmp_path):
    rom_dir = tmp_path / "gb"
    rom_dir.mkdir()
    (rom_dir / "Tetris.zip").touch()

    output_dir = tmp_path / "out" / "gb"
    generate_gamelist(rom_dir, output_dir)

    tree = ET.parse(output_dir / "gamelist.xml")
    root = tree.getroot()

    assert root.tag == "gameList"
    games = root.findall("game")
    assert len(games) == 1
    assert games[0].find("path").text == "./Tetris.zip"
    assert games[0].find("name").text == "Tetris"


def test_multiple_roms(tmp_path):
    rom_dir = tmp_path / "dreamcast"
    rom_dir.mkdir()
    for name in ["SonicAdventure.cdi", "CrazyTaxi.cdi", "JetGrind.cdi"]:
        (rom_dir / name).touch()

    output_dir = tmp_path / "out" / "dreamcast"
    generate_gamelist(rom_dir, output_dir)

    tree = ET.parse(output_dir / "gamelist.xml")
    names = [g.find("name").text for g in tree.getroot().findall("game")]
    assert names == ["CrazyTaxi", "JetGrind", "SonicAdventure"]  # sorted


def test_empty_rom_dir(tmp_path):
    rom_dir = tmp_path / "empty"
    rom_dir.mkdir()

    output_dir = tmp_path / "out" / "empty"
    generate_gamelist(rom_dir, output_dir)

    tree = ET.parse(output_dir / "gamelist.xml")
    assert tree.getroot().findall("game") == []


def test_subdirectories_in_rom_dir_are_ignored(tmp_path):
    rom_dir = tmp_path / "gb"
    rom_dir.mkdir()
    (rom_dir / "Tetris.zip").touch()
    (rom_dir / "subdir").mkdir()  # should not appear in output

    output_dir = tmp_path / "out" / "gb"
    generate_gamelist(rom_dir, output_dir)

    tree = ET.parse(output_dir / "gamelist.xml")
    games = tree.getroot().findall("game")
    assert len(games) == 1
    assert games[0].find("name").text == "Tetris"


def test_path_uses_dot_slash_prefix(tmp_path):
    rom_dir = tmp_path / "nes"
    rom_dir.mkdir()
    (rom_dir / "Contra.nes").touch()

    output_dir = tmp_path / "out" / "nes"
    generate_gamelist(rom_dir, output_dir)

    tree = ET.parse(output_dir / "gamelist.xml")
    path_text = tree.getroot().find("game/path").text
    assert path_text.startswith("./")


def test_output_dir_is_created_if_missing(tmp_path):
    rom_dir = tmp_path / "gb"
    rom_dir.mkdir()
    (rom_dir / "Tetris.zip").touch()

    output_dir = tmp_path / "deep" / "nested" / "gb"
    assert not output_dir.exists()

    generate_gamelist(rom_dir, output_dir)

    assert output_dir.is_dir()


# ---------------------------------------------------------------------------
# main (CLI)
# ---------------------------------------------------------------------------

def test_main_creates_gamelist_for_each_system(tmp_path):
    roms = tmp_path / "roms"
    for system in ["gb", "dreamcast"]:
        (roms / system).mkdir(parents=True)
        (roms / system / "Game.zip").touch()

    gamelists = tmp_path / "gamelists"

    main_args = [str(roms), str(gamelists)]
    import sys
    original_argv = sys.argv
    sys.argv = ["gamelist-gen"] + main_args
    try:
        main()
    finally:
        sys.argv = original_argv

    assert (gamelists / "gb" / "gamelist.xml").exists()
    assert (gamelists / "dreamcast" / "gamelist.xml").exists()


def test_main_invalid_input_path(tmp_path, capsys):
    import sys
    sys.argv = ["gamelist-gen", str(tmp_path / "nonexistent"), str(tmp_path / "out")]
    with pytest.raises(SystemExit):
        main()


def test_main_no_system_subdirs(tmp_path, capsys):
    roms = tmp_path / "roms"
    roms.mkdir()
    # No subdirectories — only files
    (roms / "orphan.zip").touch()

    import sys
    sys.argv = ["gamelist-gen", str(roms), str(tmp_path / "out")]
    main()

    captured = capsys.readouterr()
    assert "No system subdirectories found" in captured.out
