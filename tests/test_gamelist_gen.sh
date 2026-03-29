#!/usr/bin/env bash
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/gamelist-gen.sh"
PASS=0
FAIL=0

pass() { echo "PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL + 1)); }

assert_contains() {
    local file="$1" pattern="$2" label="$3"
    if grep -q "$pattern" "$file"; then
        pass "$label"
    else
        fail "$label (pattern '$pattern' not found in $file)"
    fi
}

assert_file_exists() {
    local file="$1" label="$2"
    if [[ -f "$file" ]]; then
        pass "$label"
    else
        fail "$label (file not found: $file)"
    fi
}

assert_not_contains() {
    local file="$1" pattern="$2" label="$3"
    if ! grep -q "$pattern" "$file"; then
        pass "$label"
    else
        fail "$label (unexpected pattern '$pattern' found in $file)"
    fi
}

# ---------------------------------------------------------------------------

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# --- test: generates gamelist.xml for a system ---
mkdir -p "$TMP/t1/roms/gb"
touch "$TMP/t1/roms/gb/Tetris.zip"
bash "$SCRIPT" "$TMP/t1/roms" "$TMP/t1/out"
assert_file_exists "$TMP/t1/out/gb/gamelist.xml" "creates gamelist.xml"

# --- test: correct XML structure ---
assert_contains "$TMP/t1/out/gb/gamelist.xml" "<gameList>"     "has <gameList> root"
assert_contains "$TMP/t1/out/gb/gamelist.xml" "<game>"         "has <game> element"
assert_contains "$TMP/t1/out/gb/gamelist.xml" "<path>./Tetris.zip</path>" "path uses ./ prefix"
assert_contains "$TMP/t1/out/gb/gamelist.xml" "<name>Tetris</name>"      "name strips extension"

# --- test: multiple systems ---
mkdir -p "$TMP/t2/roms/gb" "$TMP/t2/roms/dreamcast"
touch "$TMP/t2/roms/gb/Tetris.zip"
touch "$TMP/t2/roms/dreamcast/SonicAdventure.cdi"
bash "$SCRIPT" "$TMP/t2/roms" "$TMP/t2/out"
assert_file_exists "$TMP/t2/out/gb/gamelist.xml"         "creates gamelist for gb"
assert_file_exists "$TMP/t2/out/dreamcast/gamelist.xml"  "creates gamelist for dreamcast"

# --- test: multiple roms are sorted ---
mkdir -p "$TMP/t3/roms/nes"
touch "$TMP/t3/roms/nes/Zelda.nes" "$TMP/t3/roms/nes/Contra.nes" "$TMP/t3/roms/nes/Metroid.nes"
bash "$SCRIPT" "$TMP/t3/roms" "$TMP/t3/out"
contra_pos=$(grep -n "<name>Contra</name>" "$TMP/t3/out/nes/gamelist.xml" | cut -d: -f1)
metroid_pos=$(grep -n "<name>Metroid</name>" "$TMP/t3/out/nes/gamelist.xml" | cut -d: -f1)
zelda_pos=$(grep -n "<name>Zelda</name>" "$TMP/t3/out/nes/gamelist.xml" | cut -d: -f1)
if [[ $contra_pos -lt $metroid_pos && $metroid_pos -lt $zelda_pos ]]; then
    pass "roms are sorted alphabetically"
else
    fail "roms are sorted alphabetically"
fi

# --- test: subdirectories inside system folder are ignored ---
mkdir -p "$TMP/t4/roms/gb/subdir"
touch "$TMP/t4/roms/gb/Tetris.zip"
bash "$SCRIPT" "$TMP/t4/roms" "$TMP/t4/out"
assert_not_contains "$TMP/t4/out/gb/gamelist.xml" "subdir" "subdirectories inside system are ignored"

# --- test: empty system folder produces empty gameList ---
mkdir -p "$TMP/t5/roms/empty"
bash "$SCRIPT" "$TMP/t5/roms" "$TMP/t5/out"
assert_file_exists "$TMP/t5/out/empty/gamelist.xml" "empty system creates gamelist.xml"
assert_not_contains "$TMP/t5/out/empty/gamelist.xml" "<game>" "empty system has no <game> entries"

# --- test: output dirs are created if missing ---
mkdir -p "$TMP/t6/roms/gb"
touch "$TMP/t6/roms/gb/Tetris.zip"
bash "$SCRIPT" "$TMP/t6/roms" "$TMP/t6/deep/nested/out"
assert_file_exists "$TMP/t6/deep/nested/out/gb/gamelist.xml" "creates deep output dirs"

# --- test: invalid input path exits non-zero ---
if bash "$SCRIPT" "$TMP/nonexistent" "$TMP/out" 2>/dev/null; then
    fail "exits non-zero for invalid input path"
else
    pass "exits non-zero for invalid input path"
fi

# --- test: no system subdirs prints message ---
mkdir -p "$TMP/t7/roms"
touch "$TMP/t7/roms/orphan.zip"
output=$(bash "$SCRIPT" "$TMP/t7/roms" "$TMP/t7/out")
if echo "$output" | grep -q "No system subdirectories found"; then
    pass "prints message when no system subdirs"
else
    fail "prints message when no system subdirs"
fi

# ---------------------------------------------------------------------------

echo ""
echo "Results: $PASS passed, $FAIL failed"
[[ $FAIL -eq 0 ]]
