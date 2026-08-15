# Handoff

## What actually works (all verified this session)
- Full loop: Home → Campaign → Battle → Result (reward) → Campaign, with
  sequential stage unlocking and local save.
- Portrait 3D battle (orthographic tilted camera, Mobile renderer): Guardian
  moves/auto-targets/auto-fires; 5 enemy archetypes (grunt/runner/brute/
  ranged spitter/boss) advance and damage the fortress; 4 authored tower
  slots; 3 turret archetypes (bolt/cannon-splash/frost-slow) built via cards.
- Waves and stages fully from data; 30-stage campaign as generated StageData;
  stages 1–2 hand-tuned, both smoke-run through the same Battle scene.
- XP → level-up pauses combat → deterministic 3-card draft (weights,
  prerequisites, exclusions, stack limits, permanent-unlock gating, slots-full
  blocking). Cards change gameplay (stats, turret builds, heals).
- Permanent progression: cores from victories (reduced on repeat clears),
  3 upgrades (Fortress HP, Guardian Damage, Unlock Frost Turret),
  versioned JSON save/load.
- Dev tools: campaign Auto-Win Next + Reset Save (debug builds), `--smoke`
  autoplay, `--screenshot=` capture mode.

## Validation (last run: all PASS)
```
./tools/validate.sh
```
Runs: Godot detection → headless import/parse → 69-check core suite (RNG
determinism, draft rules, save/load, campaign traversal, data references,
content conventions, projectile collision coverage) → stage 1 + stage 2
headless battle smokes. Exits non-zero on failure.
Observed smoke baseline (seed 1337, stationary autoplay): stage 1 victory;
stage 2 loss at boss wave 4 — human play with movement/upgrades is easier.

For scene/UI changes, prefer the Godot/MCP workflow first: inspect/run/save
through Godot-aware tools, use runtime output to catch scene errors, then back
it up with `./tools/validate.sh`. Raw `.tscn` editing should be the fallback
when the MCP surface does not expose the exact scene operation needed.

## Launch
```
/Applications/Godot.app/Contents/MacOS/Godot --path "."        # run game
/Applications/Godot.app/Contents/MacOS/Godot --path "." -e     # open editor
```
Controls: A/D or ←/→ move; hold left mouse to steer toward pointer; click a
card on level-up. Balance overview:
`godot --headless --path . --script res://tools/balance_report.gd`.
That report is now the single quick-read for tuning: shared arena/combat
constants, unit bases, card inventory, permanent upgrades, and per-stage
wave/XP pacing.

## Important files
- `core/` rules · `data/` content · `game/` battle runtime · `shell/` screens
- `autoload/game.gd` app flow · `tests/run_tests.gd` suite
- `tools/gen_stages.gd` stage pipeline (edit + rerun; don't hand-edit
  `data/stages/*.tres`)
- Docs: `PROJECT_RULES.md`, `docs/SYSTEM_BLUEPRINT.md`, `docs/ASSET_CONTRACT.md`,
  `docs/DECISIONS.md`

## Known limitations
- Stages 3–30 are formula-scaled placeholders (structure real, tuning not).
- Catalog lists `res://data` via DirAccess — fine in editor/headless; exported
  builds will need a preload manifest.
- No SFX/particles/juice; placeholder primitives; single weapon; no pause
  menu; no run-in-progress save (runs are short by design).
- Guardian projectile spread uses straight (non-homing) shots when Multi Shot
  is taken; single shots home.
- Smoke timeout debugging exists for battle runs: if a smoke hangs, `Game`
  prints `SMOKE_DEBUG` with live enemy/projectile counts before quitting.

## Next highest-value step
Wire a first-run experience pass on stages 1–5: hand-author them in
`gen_stages.gd` (like 1–2), tune XP thresholds so stage 1 yields ~3 drafts,
and add hit/death feedback (flash + simple particles) — the systems are done;
readable feedback is the biggest gap to a testable build.
