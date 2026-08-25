#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
godot_binary="${GODOT:-godot}"
report_path="${TMPDIR:-/tmp}/acidblood-playtest-benchmark-$$.json"
exec "$godot_binary" --path "$repo_dir" -- --playtest=BENCHMARK --playtest-seed=22001 --playtest-report="$report_path"
