#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMP_ROOT="${TMPDIR:-/tmp}"
OUT="${TEMP_ROOT%/}/ACIDBLOOD_SESSION_CONTEXT.md"

section() {
	printf '\n## %s\n\n' "$1" >> "$OUT"
}

write_file() {
	local label="$1"
	local path="$2"
	section "$label"
	printf '```text\n' >> "$OUT"
	sed -n '1,260p' "$ROOT/$path" >> "$OUT"
	printf '\n```\n' >> "$OUT"
}

find_dropbox_root() {
	local home_dir="${HOME:-}"
	local candidate

	[ -n "$home_dir" ] || return 0

	local candidates=(
		"$home_dir/Dropbox"
		"$home_dir/Dropbox (Personal)"
		"$home_dir/Dropbox (Company)"
		"$home_dir/Library/CloudStorage/Dropbox"
		"$home_dir/Library/CloudStorage/Dropbox (Personal)"
		"$home_dir/Library/CloudStorage/Dropbox (Company)"
	)

	for candidate in "${candidates[@]}"; do
		if [ -d "$candidate" ] && [ -w "$candidate" ]; then
			printf '%s\n' "$candidate"
			return 0
		fi
	done

	for candidate in "$home_dir/Library/CloudStorage" "$home_dir"; do
		if [ -d "$candidate" ]; then
			while IFS= read -r dropbox_root; do
				if [ -w "$dropbox_root" ]; then
					printf '%s\n' "$dropbox_root"
					return 0
				fi
			done < <(find "$candidate" -maxdepth 1 -type d -name 'Dropbox*' -print 2>/dev/null)
		fi
	done
}

export_to_dropbox() {
	local dropbox_root
	local export_dir

	dropbox_root="$(find_dropbox_root)"
	[ -n "$dropbox_root" ] || return 0

	export_dir="$dropbox_root/ACIDBLOOD Context"
	if ! mkdir -p "$export_dir"; then
		printf 'warning: Dropbox context export skipped (cannot create %s)\n' "$export_dir" >&2
		return 0
	fi
	if ! cp -f "$OUT" "$export_dir/ACIDBLOOD_SESSION_CONTEXT.md"; then
		printf 'warning: Dropbox context export skipped (cannot copy snapshot)\n' >&2
	fi
}

{
	printf '# ACIDBLOOD Session Context\n\n'
	printf 'Generated: %s\n\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"

	section "Project identity"
	printf -- '- Repository: ACIDBLOOD / TD Game System\n'
	printf -- '- Godot target: 4.7.1\n'
	printf -- '- Canonical MCP: Godot AI MCP\n'
	printf -- '- Canonical local validation: bash tools/validate.sh\n'
	printf -- '- Canonical behavioral CLI: ./tools/run_gdunit.sh --godot_binary "$GODOT" --headless --ignoreHeadlessMode -a res://tests/gdunit/\n'
printf -- '- Current validation layers: 94-check core suite, 44-case GdUnit4 behavioral pilot, runtime smoke stages 1 and 2\n'

	section "Git state"
	printf -- '- Branch: %s\n' "$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
	printf -- '- HEAD: %s\n' "$(git -C "$ROOT" rev-parse HEAD)"
	printf -- '- Status:\n'
	git -C "$ROOT" status --short | sed 's/^/  /'
	printf '\n'
	printf -- '- Recent commits:\n'
	git -C "$ROOT" log --oneline --decorate -5 | sed 's/^/  /'

	section "Validation summary"
	printf -- '- tools/validate.sh: Godot detection → headless import/parse → 94-check suite → 44-case GdUnit4 behavioral pilot → smoke stage 1 → smoke stage 2\n'
	printf -- '- GdUnit4 reports: res://reports/ (gitignored)\n'
	printf -- '- Shared suite entry points: tests/acidblood_suite_runner.tscn, tests/run_tests.gd, tests/test_acidblood.gd\n'

	write_file "AGENTS.md" "AGENTS.md"
	write_file "PROJECT_RULES.md" "PROJECT_RULES.md"
	write_file "docs/HANDOFF.md" "docs/HANDOFF.md"
	write_file "docs/SYSTEM_BLUEPRINT.md" "docs/SYSTEM_BLUEPRINT.md"
	write_file "docs/ROADMAP.md" "docs/ROADMAP.md"
	write_file "docs/ACIDBLOOD_DIRECTION.md" "docs/ACIDBLOOD_DIRECTION.md"

	section "Compact repository tree"
	printf '```text\n'
	printf '.\n'
	printf '├── AGENTS.md\n'
	printf '├── PROJECT_RULES.md\n'
	printf '├── README.md\n'
	printf '├── addons/\n'
	printf '│   ├── godot_ai/\n'
	printf '│   └── gdUnit4/\n'
	printf '├── autoload/\n'
	printf '├── core/\n'
	printf '├── data/\n'
	printf '├── docs/\n'
	printf '│   ├── ACIDBLOOD_DIRECTION.md\n'
	printf '│   ├── ASSET_CONTRACT.md\n'
	printf '│   ├── HANDOFF.md\n'
	printf '│   ├── ROADMAP.md\n'
	printf '│   └── SYSTEM_BLUEPRINT.md\n'
	printf '├── game/\n'
	printf '├── shell/\n'
	printf '├── tests/\n'
	printf '│   ├── acidblood_suite_runner.tscn\n'
	printf '│   ├── run_tests.gd\n'
	printf '│   ├── test_acidblood.gd\n'
	printf '│   └── gdunit/\n'
	printf '└── tools/\n'
	printf '    ├── make_context_snapshot.sh\n'
	printf '    └── validate.sh\n'
	printf '```\n'
} > "$OUT"

export_to_dropbox
printf '%s\n' "$OUT"
