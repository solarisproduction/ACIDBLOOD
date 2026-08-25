#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_binary="${GODOT:-godot}"
report_path="${TMPDIR:-/tmp}/acidblood-playtest-fresh-$$.json"
exec "$godot_binary" --path "$repo_dir" -- --playtest=FRESH --playtest-seed=11001 --playtest-report="$report_path"
