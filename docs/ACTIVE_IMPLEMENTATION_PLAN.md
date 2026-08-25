# Phase 1.1 Pressure & Placement Calibration Plan

This is the executable plan for the approved Phase 1.1 calibration slice. It
does not authorize Phase 2 systems. The implementation must preserve the
current Phase 1 rules and use existing enemies, cards, slots, and runtime
telemetry.

## Product constraints

- Stage 1 remains the tutorial/grammar stage; Stage 2+ data is unchanged.
- Pressure increases through throughput, overlap, cadence, and composition;
  common-enemy HP is not globally inflated.
- The approximately 20-draft / approximately 5-minute result remains a
  coupled pacing target, not a hard timer or an exact XP curve.
- T1 – T2 – Guardian – T3 – T4 remains the defensive topology.
- The placement result is an in-world ghost flow; no modal slot picker remains
  active after the implementation task is complete.
- No WeaponDefinition, new damage-family, enemy-movement, mastery, Arsenal, or
  other Phase 2 architecture is part of this plan.

## Task A — Calibration telemetry and reproducible measurement

Purpose: make accelerated FRESH/BENCHMARK runs report simulated gameplay time,
population pressure, dead air, draft cadence, and existing progression data in
one compact JSON report.

Files:

- Modify: `core/playtest_telemetry.gd`, `autoload/game.gd`, `game/battle.gd`
- Modify: `tests/gdunit/acidblood_behavioral.gd`, `tests/acidblood_checks.gd`
- Test: `tools/validate.sh` runtime and isolated playtest invocations

Interfaces:

- `PlaytestTelemetry.advance_simulation(delta: float, live_population: int)`
  accumulates game-time and population integrals without writing per-frame
  events.
- `Game.record_playtest_simulation(delta: float, live_population: int)` forwards
  the sample to the active recorder.
- Playtest command-line options may enable autoplay/time scale for QA only;
  graphical helpers remain normal-speed and non-autoplay.

Checks:

- [x] Write failing tests for simulated time, deterministic population metrics,
  compact one-report output, and save isolation.
- [x] Run the narrow GdUnit tests and confirm the new fields are absent or
  incorrect before implementation.
- [x] Implement the accumulator and QA-only launcher options.
- [x] Run narrow tests, FRESH smoke, and BENCHMARK smoke; valid reports were
  produced with simulated-time and pressure metrics.
- [x] Run the full behavioral suite and `bash tools/validate.sh`.
- [x] Commit: `test: add Phase 1.1 calibration telemetry`

## Task B — Stage 1 throughput and pacing calibration

Purpose: test controlled several-fold Stage 1 pressure candidates and keep the
strongest evidence-backed authored encounter in the generator source.

Files:

- Modify: `tools/gen_stages.gd`
- Regenerate: `data/stages/stage_001.tres` only; Stage 2–30 must remain bytewise
  unchanged.
- Modify: `tests/gdunit/acidblood_behavioral.gd`, `tests/acidblood_checks.gd`

Interfaces:

- Stage 1 remains a six-wave `StageData` composed of existing Grunt, Runner,
  and Spitter `SpawnGroup` resources with authored lanes and overlap.
- The selected candidate is judged by telemetry fields from Task A, not by an
  exact multiplier encoded as a product rule.

Checks:

- [ ] Record the current 124-enemy / 260-XP / 8-draft baseline from the new
  report before changing stage data.
- [ ] Run two or three uncommitted candidate definitions and record enemy
  count, simulated duration, average/peak population, dead air, XP, drafts,
  Barricade, and outcome for each.
- [ ] Keep one selected candidate in `gen_stages.gd`, regenerate Stage 1, and
  verify generated-source ownership plus unchanged Stage 2–30 resources.
- [ ] Add structural tests for valid references, authored lane coverage,
  meaningful population, and the selected Stage 1 data contract without
  encoding subjective human balance as a brittle exact assertion.
- [ ] Run narrow tests, full GdUnit, both isolated profiles, canonical
  validation, and inspect runtime logs.
- [ ] Commit: `feat: calibrate Stage 1 pressure and pacing`

## Task C — Conservative battlefield-space calibration

Purpose: test whether a small approach-depth compression improves interaction
continuity while preserving the defensive line and all combat boundaries.

Files:

- Modify only if evidence supports it: `core/arena_layout.gd`,
  `game/arena.tscn`, `game/battle.gd`, and relevant behavioral tests
- Test: runtime screenshot/smoke and defensive-line geometry assertions

Interfaces:

- `ArenaLayout` remains the single source for spawn, barricade, Guardian, and
  lateral clamp coordinates used by runtime code.
- Slot order and four-slot topology do not change.

Checks:

- [ ] Measure baseline spawn-to-barricade distance and capture the existing
  camera view if useful.
- [ ] Test one conservative compression candidate and compare runtime metrics
  and visual framing.
- [ ] Keep the candidate only if enemy travel, barricade contact, Guardian
  clamp, slot topology, and runtime checks remain valid; otherwise record no
  geometry change and leave the baseline intact.
- [ ] Commit a spatial change only when the evidence justifies it:
  `feat: calibrate Stage 1 battlefield spacing`.

## Task D — In-world ghost turret placement

Purpose: replace the legacy modal slot picker with a paused battlefield
placement continuation owned by the same draft interruption.

Files:

- Modify: `game/battle.gd`, `game/battle_hud.gd`, `game/turret.gd`
- Modify: `game/battle_ui.tscn` only if a minimal instruction node is needed
- Modify: `tests/gdunit/acidblood_behavioral.gd`, `tests/acidblood_checks.gd`

Interfaces:

- Battle owns `_placement_open`, `_placement_turret_id`, `_placement_slot_index`,
  and a non-attacking ghost instance.
- HUD exposes `show_placement(turret: TurretData, slot_index: int)` and
  `hide_placement()`; it does not create a second slot-selection modal.
- Keyboard arrows cycle the ordered empty T1–T4 slots, and Space/Enter calls
  `Battle.confirm_turret_placement()`.

Checks:

- [ ] Write failing behavioral tests for placement ownership, ghost state,
  valid-slot cycling, occupied-slot skipping, confirm installation, and
  pause/resume sequencing.
- [ ] Run the narrow tests and confirm the old modal path fails the new
  contract.
- [ ] Implement the smallest ghost material/presentation and keyboard path.
- [ ] Run narrow tests, full GdUnit, FRESH/BENCHMARK automated smoke, and a
  graphical-safe launch check.
- [ ] Commit: `feat: replace modal turret placement with in-world ghost`

## Task E — Integrated Phase 1.1 verification and handoff

Purpose: review the selected calibration and placement implementation against
the approved scope, remove experiment artifacts, and package a human review
build without starting Phase 2.

Files:

- Modify only as needed for factual truth: `docs/SYSTEM_BLUEPRINT.md`,
  `docs/HANDOFF.md`, `docs/ROADMAP.md`
- Test: all existing validation and both graphical launch helpers

Checks:

- [ ] Confirm failed candidate data is absent from Git and Stage 2–30 are
  unchanged.
- [ ] Run the full GdUnit suite, `bash tools/validate.sh`, FRESH/BENCHMARK
  reports, save-isolation checks, `git diff --check`, and error-log scan.
- [ ] Review the final diff for Phase 2 leakage, duplicate state ownership,
  nondeterministic draft behavior, and generated-file mistakes.
- [ ] Update current technical truth and handoff with automated evidence,
  human-playtest pending status, and exact graphical commands.
- [ ] Commit: `docs: package Phase 1.1 calibration review`
- [ ] Push each validated checkpoint and inspect its GitHub Actions run.

## Review status

- Phase 1: implemented and human-reviewed.
- Task A: complete; baseline reports are available under `/private/tmp`.
- Phase 1.1 automated gate: pending execution of Tasks B–E.
- Human Phase 1.1 graphical playtest: required after the selected build.
- Phase 2: not started and blocked until Phase 1.1 human review.
