# ES-DE Gamelist Generator

Generates `gamelist.xml` files for [ES-DE](https://es-de.org/) from a directory of ROMs.

## Shell Script (no dependencies — works on Steam Deck)

```bash
chmod +x gamelist-gen.sh
./gamelist-gen.sh <input_path> <output_path>
```

**Example:**

```bash
./gamelist-gen.sh /run/media/mmcblk0p1/ROMs /home/deck/.emulationstation/gamelists
```

**Run tests:**

```bash
bash tests/test_gamelist_gen.sh
```

## Python (requires Python 3.10+ and Poetry)

### Installation

```bash
poetry install
```

### Usage

```bash
poetry run gamelist-gen <input_path> <output_path>
```

**Example:**

```bash
poetry run gamelist-gen /mnt/nas/roms/ROMs /Es-De/gamelists
```

**Run tests:**

```bash
poetry run pytest
```

---

Both options scan each system subfolder (e.g. `ROMs/gb`, `ROMs/dreamcast`) and create:

```
gamelists/
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
