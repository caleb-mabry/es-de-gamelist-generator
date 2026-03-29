# ES-DE Gamelist Generator

Generates `gamelist.xml` files for [ES-DE](https://es-de.org/) from a directory of ROMs.

## Requirements

- Python 3.10+
- [Poetry](https://python-poetry.org/)

## Installation

```bash
poetry install
```

## Usage

```bash
poetry run gamelist-gen <input_path> <output_path>
```

**Arguments:**

| Argument | Description |
|---|---|
| `input` | Path to your ROMs directory (contains one subfolder per system) |
| `output` | Path to your ES-DE `gamelists` directory |

**Example:**

```bash
poetry run gamelist-gen /mnt/nas/roms/ROMs /Es-De/gamelists
```

This will scan each system subfolder (e.g. `/mnt/nas/roms/ROMs/gb`, `/mnt/nas/roms/ROMs/dreamcast`) and create:

```
/Es-De/gamelists/
  gb/
    gamelist.xml
  dreamcast/
    gamelist.xml
  ...
```

## Output Format

```xml
<gameList>
  <game>
    <path>./SomeGame.zip</path>
    <name>SomeGame</name>
  </game>
</gameList>
```
