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
WARNINGS=()

note() { RESULTS+=("$1  $2"); }
warn() { WARNINGS+=("WARN  $1"); }

classify_failure() {
    local phase="$1"
    local output="$2"
    if printf '%s' "$output" | grep -qE "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script"; then
        case "$phase" in
            import) printf 'parse/import failure' ;;
            test) printf 'editor bootstrap failure' ;;
            smoke) printf 'game runtime failure' ;;
            *) printf '%s failure' "$phase" ;;
        esac
        return
    fi
    case "$phase" in
        test) printf 'test failure' ;;
        smoke) printf 'smoke failure' ;;
        *) printf '%s failure' "$phase" ;;
    esac
}

has_fatal_project_errors() {
    printf '%s' "$1" | grep -qE "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script"
}

has_boot_context_ok() {
    printf '%s' "$1" | grep -qE '^BOOT_CONTEXT .*game_available=true '
}

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

# --- 1b. Worktree hygiene ---------------------------------------------
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    DIRTY_COUNT="$(git status --short | wc -l | tr -d ' ')"
    if [ "${DIRTY_COUNT:-0}" -gt 0 ]; then
        warn "git worktree has $DIRTY_COUNT changed/untracked paths"
    else
        note "PASS" "git worktree clean"
    fi
fi

# --- 2. Headless import / parse check ---------------------------------
TEMP_ROOT="${TMPDIR:-/tmp}"
VALIDATION_USER_DIR="${TEMP_ROOT%/}/acidblood-validate-user"
VALIDATION_LOG="${TEMP_ROOT%/}/acidblood-validate-godot.log"
mkdir -p "$VALIDATION_USER_DIR"
IMPORT_OUT="$(with_timeout 300 "$GODOT" --headless --log-file "$VALIDATION_LOG" --user-data-dir "$VALIDATION_USER_DIR" --path "$ROOT" --import 2>&1)"
IMPORT_CODE=$?
if [ $IMPORT_CODE -ne 0 ] || has_fatal_project_errors "$IMPORT_OUT"; then
    note "FAIL" "$(classify_failure import "$IMPORT_OUT")"
    echo "$IMPORT_OUT" | grep -E "ERROR|Parse Error" | head -20
    FAIL=1
else
    note "PASS" "project import / script parse"
fi

# --- 3. Core test suite (RNG, draft, save/load, campaign, data refs) ---
TEST_OUT="$(with_timeout 300 "$GODOT" --headless --log-file "$VALIDATION_LOG" --user-data-dir "$VALIDATION_USER_DIR" --path "$ROOT" --scene res://tests/acidblood_suite_runner.tscn 2>&1)"
TEST_CODE=$?
echo "$TEST_OUT" | grep -E "^\[|PASS|FAIL"
if [ $TEST_CODE -ne 0 ] || has_fatal_project_errors "$TEST_OUT" || ! has_boot_context_ok "$TEST_OUT"; then
    if ! has_boot_context_ok "$TEST_OUT"; then
        note "FAIL" "editor/bootstrap failure (tests/acidblood_suite_runner.tscn)"
    else
        note "FAIL" "$(classify_failure test "$TEST_OUT") (tests/acidblood_suite_runner.tscn)"
    fi
    if has_fatal_project_errors "$TEST_OUT"; then
        echo "$TEST_OUT" | grep -E "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script" | head -20
    fi
    if ! has_boot_context_ok "$TEST_OUT"; then
        echo "$TEST_OUT" | grep -E "^BOOT_CONTEXT|^BOOT_FAILURE" | head -20
    fi
    FAIL=1
else
    note "PASS" "official suite ($(echo "$TEST_OUT" | grep -c '  PASS') checks via tests/acidblood_suite_runner.tscn)"
fi

# --- 4. GdUnit4 behavioral pilot --------------------------------------
GDUNIT_OUT="$(with_timeout 300 "$ROOT/tools/run_gdunit.sh" --godot_binary "$GODOT" --headless --ignoreHeadlessMode -a res://tests/gdunit/ 2>&1)"
GDUNIT_CODE=$?
echo "$GDUNIT_OUT" | grep -E "PASS|FAIL|ERROR|warning|Running"
if [ $GDUNIT_CODE -ne 0 ] || has_fatal_project_errors "$GDUNIT_OUT"; then
    note "FAIL" "$(classify_failure test "$GDUNIT_OUT") (GdUnit4 behavioral pilot)"
    if has_fatal_project_errors "$GDUNIT_OUT"; then
        echo "$GDUNIT_OUT" | grep -E "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script" | head -20
    fi
    FAIL=1
else
    note "PASS" "GdUnit4 behavioral suite (res://tests/gdunit)"
fi

# --- 5/6. Battle smoke tests (stage 1 and stage 2) ---------------------
for STAGE in 1 2; do
    SMOKE_OUT="$(with_timeout 300 "$GODOT" --headless --log-file "$VALIDATION_LOG" --user-data-dir "$VALIDATION_USER_DIR" --path "$ROOT" -- --smoke --smoke-stage=$STAGE 2>&1)"
    SMOKE_CODE=$?
    LINE="$(echo "$SMOKE_OUT" | grep "SMOKE_RESULT" | head -1)"
    if has_fatal_project_errors "$SMOKE_OUT"; then
        note "FAIL" "$(classify_failure smoke "$SMOKE_OUT") stage $STAGE"
        echo "$SMOKE_OUT" | grep -E "SCRIPT ERROR|Parse Error|Compile Error|Failed to load script" | head -12
        FAIL=1
    elif [ $SMOKE_CODE -eq 0 ] && [ -n "$LINE" ]; then
        note "PASS" "RUNTIME SMOKE PASS stage $STAGE (simulation result: $LINE)"
    else
        note "FAIL" "$(classify_failure smoke "$SMOKE_OUT") stage $STAGE (exit $SMOKE_CODE)"
        echo "$SMOKE_OUT" | tail -10
        FAIL=1
    fi
done

# --- Report ------------------------------------------------------------
echo ""
echo "================ VALIDATION REPORT ================"
for r in "${RESULTS[@]}"; do echo "$r"; done
if [ "${#WARNINGS[@]}" -gt 0 ]; then
    for w in "${WARNINGS[@]}"; do echo "$w"; done
fi
echo "==================================================="
if [ $FAIL -ne 0 ]; then
    echo "RESULT: FAIL"
    exit 1
fi
echo "RESULT: PASS"
exit 0
