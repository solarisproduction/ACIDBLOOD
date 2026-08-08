#!/bin/bash
# Repository validation suite. Runs everything the environment supports and
# prints PASS / FAIL / SKIP per step. Exits non-zero if anything FAILs.
#
#   ./tools/validate.sh
#
# Override the Godot binary with:  GODOT=/path/to/godot ./tools/validate.sh

set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

FAIL=0
RESULTS=()

note() { RESULTS+=("$1  $2"); }

# Wall-clock watchdog (macOS has no `timeout`); relies on perl's alarm.
with_timeout() { perl -e 'alarm shift; exec @ARGV' "$@"; }

# --- 1. Locate Godot ---------------------------------------------------
GODOT="${GODOT:-}"
if [ -z "$GODOT" ]; then
    for candidate in godot godot4 /Applications/Godot.app/Contents/MacOS/Godot; do
        if command -v "$candidate" >/dev/null 2>&1; then GODOT="$candidate"; break; fi
    done
fi
if [ -z "$GODOT" ] || ! "$GODOT" --version >/dev/null 2>&1; then
    note "FAIL" "detect Godot executable (set GODOT=/path/to/godot)"
    echo "FAIL  detect Godot executable"
    exit 1
fi
note "PASS" "detect Godot executable ($("$GODOT" --version | head -1))"

# --- 2. Headless import / parse check ---------------------------------
IMPORT_OUT="$(with_timeout 300 "$GODOT" --headless --path "$ROOT" --import 2>&1)"
IMPORT_CODE=$?
if [ $IMPORT_CODE -ne 0 ] || echo "$IMPORT_OUT" | grep -qE "SCRIPT ERROR|Parse Error|Failed to load script"; then
    note "FAIL" "project import / script parse"
    echo "$IMPORT_OUT" | grep -E "ERROR|Parse Error" | head -20
    FAIL=1
else
    note "PASS" "project import / script parse"
fi

# --- 3. Core test suite (RNG, draft, save/load, campaign, data refs) ---
TEST_OUT="$(with_timeout 300 "$GODOT" --headless --path "$ROOT" --script res://tests/run_tests.gd 2>&1)"
TEST_CODE=$?
echo "$TEST_OUT" | grep -E "^\[|PASS|FAIL"
if [ $TEST_CODE -ne 0 ]; then
    note "FAIL" "core test suite (tests/run_tests.gd)"
    FAIL=1
else
    note "PASS" "core test suite ($(echo "$TEST_OUT" | grep -c '  PASS') checks)"
fi

# --- 4/5. Battle smoke tests (stage 1 and stage 2) ---------------------
for STAGE in 1 2; do
    SMOKE_OUT="$(with_timeout 300 "$GODOT" --headless --path "$ROOT" -- --smoke --smoke-stage=$STAGE 2>&1)"
    SMOKE_CODE=$?
    LINE="$(echo "$SMOKE_OUT" | grep "SMOKE_RESULT" | head -1)"
    if echo "$SMOKE_OUT" | grep -q "SCRIPT ERROR"; then
        note "FAIL" "battle smoke stage $STAGE (script errors)"
        echo "$SMOKE_OUT" | grep -A2 "SCRIPT ERROR" | head -12
        FAIL=1
    elif [ $SMOKE_CODE -eq 0 ] && [ -n "$LINE" ]; then
        note "PASS" "battle smoke stage $STAGE ($LINE)"
    else
        note "FAIL" "battle smoke stage $STAGE (exit $SMOKE_CODE)"
        echo "$SMOKE_OUT" | tail -10
        FAIL=1
    fi
done

# --- Report ------------------------------------------------------------
echo ""
echo "================ VALIDATION REPORT ================"
for r in "${RESULTS[@]}"; do echo "$r"; done
echo "==================================================="
if [ $FAIL -ne 0 ]; then
    echo "RESULT: FAIL"
    exit 1
fi
echo "RESULT: PASS"
exit 0
