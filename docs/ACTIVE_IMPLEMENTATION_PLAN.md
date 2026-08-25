# Active Implementation Plan — Phase 1 Battle Foundation

This is the executable plan for Phase 1. It targets the structural benchmark in
`docs/GALAXY_FOUNDATION_SPEC.md`; the existing gameplay is legacy/current
implementation and is not a compatibility constraint. No Phase 1 code is part
of this planning checkpoint.

## Current implementation map

| Area | Current files | Disposition | Reason |
|---|---|---|---|
| Battle orchestration | `game/battle.gd`, `game/battle.tscn` | ADAPT | Retain scene flow, enemy lifecycle, draft pause, and result transitions while replacing legacy battle assumptions. |
| Arena and slots | `core/arena_layout.gd`, `game/arena.tscn` | REPLACE | The active geometry must become the fixed T1–T2–Guardian–T3–T4 line; old staggered/deep coordinates are disposable. |
| Guardian | `game/guardian.gd`, `game/guardian.tscn`, `data/guardian.tres`, `data/types/guardian_data.gd`, `data/types/weapon_data.gd` | ADAPT | Existing lateral movement and firing provide the required Guardian Rifle foundation without implementing the full future weapon model. |
| Turret runtime | `game/turret.gd`, `game/turret.tscn`, `data/types/turret_data.gd`, `data/turrets/cannon.tres` | ADAPT | Prove one fixed Impact Cannon lifecycle using the existing data-driven runtime. |
| Enemy and waves | `game/enemy.gd`, `game/wave_director.gd`, `data/types/{enemy_data,wave_data,spawn_group}.gd` | REUSE | Existing spawning, movement, death, and wave completion are sufficient inputs for deterministic XP and battle completion. |
| Run state and leveling | `core/run_state.gd`, `core/leveling.gd`, `data/types/stage_data.gd` | ADAPT | Add explicit slot state, configurable XP/draft limits, and exactly-once accounting while preserving the pure deterministic core. |
| Draft and cards | `core/draft.gd`, `data/types/{card_data,card_effect}.gd`, `data/cards/*`, `core/det_rng.gd` | ADAPT | Retain prerequisites, excludes, weighting, and seeded sampling; replace legacy card semantics needed for Phase 1 with explicit NEW TURRET and bounded normal choices. |
| Draft presentation | `game/battle_hud.gd`, `game/battle_ui.tscn` | ADAPT | Keep the existing pause/choice flow and make three-choice selection and turret installation explicit. |
| Shell/result flow | `autoload/game.gd`, `shell/{home,campaign,result}.gd`, matching scenes | REUSE | Existing navigation, save boundary, and result flow remain compatible with the foundation. |
| Tests and validation | `tests/acidblood_checks.gd`, `tests/gdunit/acidblood_behavioral.gd`, `tools/{validate.sh,run_gdunit.sh}` | ADAPT/REUSE | Replace obsolete gameplay assertions with Phase 1 contracts; preserve the mature harness and canonical validator. |

## Target Phase-1 file map

Create no new gameplay framework. Modify the existing convention-based files:

- `docs/ACTIVE_IMPLEMENTATION_PLAN.md` — this execution authority.
- `core/arena_layout.gd` — ordered defensive-line topology and movement bounds.
- `core/run_state.gd`, `core/leveling.gd` — slot lifecycle, XP, level-up and finite budget state.
- `data/types/stage_data.gd`, `data/types/card_data.gd`, `data/types/card_effect.gd` — minimal data/config seams.
- `data/guardian.tres`, `data/turrets/cannon.tres`, selected `data/cards/*` — Phase 1 content only.
- `game/arena.tscn`, `game/battle.gd`, `game/guardian.gd`, `game/turret.gd`, `game/battle_hud.gd` and corresponding scene files — runtime and presentation integration.
- `tests/acidblood_checks.gd`, `tests/gdunit/acidblood_behavioral.gd` — deterministic and behavioral coverage.
- `docs/HANDOFF.md`, `docs/ROADMAP.md`, `AGENTS.md` — authority integration.

No files are planned for deletion in Phase 1. Obsolete gameplay resources remain
available until a later approved replacement slice removes them. Vendored files,
CI, and validation tooling are preserved.

## Dependency order and review gates

Tasks are ordered so each completed task has a narrow testable contract. Human
approval is required at Review Gate A, Review Gate B, and the final review;
future executors must not push past those gates automatically.

### Task 1: Freeze the Phase 1 domain contract and test harness

Purpose: establish typed, deterministic contracts for the four slots, Guardian
activation, XP accounting, level-up budget, and seeded three-card offers before
scene work begins.

Files:
- Create: none.
- Modify: `core/run_state.gd`, `core/leveling.gd`, `data/types/stage_data.gd`, `data/types/card_data.gd`, `data/types/card_effect.gd`.
- Test: `tests/acidblood_checks.gd`, `tests/gdunit/acidblood_behavioral.gd`.
- Delete: none.

Interfaces:
- Consumes: enemy XP values, stage configuration, card catalog, and `DetRNG`.
- Produces: four `EMPTY` slot records, exactly-once XP transaction, configurable XP thresholds, `draft_count`/`max_draft_choices`, and a deterministic offer contract returning exactly three valid choices when the pool permits.

- [x] Write failing tests for four empty slots, Guardian-active state, exactly-once XP, threshold crossing, finite budget, and same-seed offer equality.
- [x] Run the narrow GdUnit/static checks and record the expected failures against the legacy state model.
- [x] Implement the minimum typed state/configuration; keep Phase 2 weapon axes and full card categories out.
- [x] Run the narrow tests and require PASS, including no duplicate XP transaction.
- [x] Run legacy-independent regression checks for save serialization and deterministic RNG.
- [x] Runtime/manual verification is not required for this pure-domain task.
- [x] Commit with `feat: define Phase 1 battle foundation contracts`.

### Task 2: Build the defensive line and Guardian foundation

Purpose: replace the active staggered arena with the readable fixed lineup
`T1 – T2 – GUARDIAN – T3 – T4`, with all turret slots empty and Guardian
movement/firing active at stage start.

Files:
- Create: none.
- Modify: `core/arena_layout.gd`, `game/arena.tscn`, `game/guardian.gd`, `game/guardian.tscn`, `data/guardian.tres`, `game/battle.gd`.
- Test: `tests/gdunit/acidblood_behavioral.gd`, `tests/acidblood_checks.gd`.
- Delete: none.

Interfaces:
- Consumes: the Task 1 slot state and current enemy target/firing interfaces.
- Produces: ordered fixed slot markers, Guardian start/limit coordinates, active Guardian Rifle firing, and a battle-ready empty defensive line.

- [x] Write failing behavioral tests for marker order/positions, empty runtime slots, Guardian active at frame one, and lateral clamp limits.
- [x] Run the narrow scene/GdUnit tests and require failure on the old staggered topology.
- [x] Implement the minimum scene and orchestration replacement; do not add turret repositioning or new weapon systems.
- [x] Run the narrow tests and require PASS plus clean parse/runtime logs.
- [x] Run Guardian and battle regression tests.
- [x] Perform the Review Gate A manual playtest: field framing, T1 T2 G T3 T4 readability, movement feel, and structural resemblance.
- [x] Commit only after human approval with `feat: establish Phase 1 defensive line`.

### Task 2.5: Reproducible playtest harness

Purpose: provide isolated, reproducible FRESH and BENCHMARK Stage 1 runs with
one structured telemetry report, without implementing Task 3 progression.

Files:
- Create: `core/playtest_profile.gd`, `core/playtest_telemetry.gd`.
- Modify: `autoload/game.gd`, `game/battle.gd`, `game/guardian.gd`,
  `tests/gdunit/acidblood_behavioral.gd`, `docs/HANDOFF.md`,
  `docs/SYSTEM_BLUEPRINT.md`.
- Test: `tests/gdunit/acidblood_behavioral.gd`.
- Delete: none.

Interfaces:
- Consumes: explicit profile id/version, seed, stage id, and injected transient
  `Progression` state.
- Produces: isolated runtime initialization and one JSON report under
  `${TMPDIR:-/tmp}` containing run identity, outcome, elapsed time, kills,
  barricade state, peak population, Guardian events, and dormant future
  progression fields.

- [x] Write failing tests for profile isolation, seeded initialization, save isolation, and one-report telemetry.
- [x] Run the narrow GdUnit tests and confirm failure before adding the harness.
- [x] Implement typed FRESH/BENCHMARK profiles and transient progression injection.
- [x] Implement event-based JSON telemetry without adding XP/draft gameplay.
- [x] Run narrow behavioral tests and confirm PASS.
- [x] Run one FRESH and one BENCHMARK headless runtime smoke with isolated report paths.
- [x] Record the approximately 20-draft / approximately 5-minute normal-stage pacing benchmark as a tunable target; exact XP curve remains UNVERIFIED.
- [x] Commit with `test: add reproducible playtest harness`; do not push before review.

### Task 3: Integrate deterministic kills, XP and level-up interruption

Purpose: connect enemy death to one XP award and a bounded level-up transition
without changing enemy identity or global combat balance.

Files:
- Create: none.
- Modify: `game/battle.gd`, `game/enemy.gd`, `game/wave_director.gd`, `core/run_state.gd`, `game/battle_hud.gd`.
- Test: `tests/gdunit/acidblood_behavioral.gd`, `tests/acidblood_checks.gd`.
- Delete: none.

Interfaces:
- Consumes: enemy death signal/callback, Task 1 XP thresholds and draft budget.
- Produces: one XP transaction per enemy, level-up pause/state, and a request for a three-choice draft.

- [x] Write failing tests for duplicate death notification, XP threshold transition, pause/resume, and budget exhaustion.
- [x] Run focused tests and require failure before changing the battle callback.
- [x] Implement one authoritative death transaction and explicit level-up state transitions.
- [x] Run focused tests and require PASS with no double-counted kills or XP.
- [x] Run wave, result-flow, save-state, and deterministic regression tests.
- [x] Verify a short runtime stage can kill Guardian targets and open a draft without log errors.
- [x] Commit with `feat: connect battle kills to run progression`.

### Task 4: Implement the Phase 1 three-choice draft contract

Purpose: adapt the existing deterministic draft to return exactly three valid
choices, preserve useful eligibility rules, and enforce the finite normal-stage
budget without implementing full Phase 3 semantics.

Files:
- Create: none.
- Modify: `core/draft.gd`, `data/types/card_data.gd`, `data/types/card_effect.gd`, selected `data/cards/*`, `game/battle_hud.gd`, `game/battle_ui.tscn`.
- Test: `tests/gdunit/acidblood_behavioral.gd`, `tests/acidblood_checks.gd`.
- Delete: none.

Interfaces:
- Consumes: seeded `DetRNG`, run eligibility, occupied/empty slot count, and Task 3 level-up requests.
- Produces: three distinct eligible choices, one committed selection, deterministic repeatability, and no offer after the configured maximum.

- [x] Write failing tests for exactly three choices, eligibility, no duplicates, one selection, same-seed equality, and finite budget.
- [x] Run the focused draft tests and require failure against legacy build/choice inference where applicable.
- [x] Implement the minimum explicit Phase 1 category/eligibility fields; retain prerequisites, excludes, max stacks, weights, and context.
- [x] Run focused draft/UI tests and require PASS.
- [x] Run the full draft and save/load regression subset.
- [x] Verify the UI pauses battle, displays three choices, and resumes after selection.
- [x] Commit with `feat: add bounded Phase 1 draft flow`.

### Task 5: Add NEW TURRET and Impact Cannon slot lifecycle

Purpose: prove that a draft choice can install the first turret into one empty
fixed slot, while rejecting duplicate installation and enforcing four-slot
capacity.

Files:
- Create: none.
- Modify: `core/run_state.gd`, `game/battle.gd`, `game/turret.gd`, `game/turret.tscn`, `data/types/turret_data.gd`, `data/turrets/cannon.tres`, selected `data/cards/*`, `game/battle_hud.gd`.
- Test: `tests/gdunit/acidblood_behavioral.gd`, `tests/acidblood_checks.gd`.
- Delete: none.

Interfaces:
- Consumes: explicit NEW TURRET card result and empty slot lifecycle.
- Produces: Impact Cannon activation, one-time occupancy, four-slot capacity enforcement, and deterministic slot selection/confirmation.

- [x] Write failing tests for empty-slot occupation, occupied-slot rejection, four-slot capacity, and Cannon firing after installation.
- [x] Run focused tests and require failure before implementing installation.
- [x] Implement the minimum install transaction and scene spawn; do not add Tesla, Disruption Field, or free repositioning.
- [x] Run focused tests and require PASS, including a deterministic slot result.
- [x] Run turret, draft, battle completion, and save-state regressions.
- [x] Perform automated Review Gate B: kill cadence, level-up cadence, interruption flow, turret appearance/activation, and structural benchmark feel. Human Gate B remains pending.
- [x] Commit with `feat: add Phase 1 new turret lifecycle` under the authorized autonomous checkpoint; human Gate B remains pending.

### Task 6: Complete the finite playable Stage 1 foundation

Purpose: connect the foundation to a finite stage with normal victory/defeat
and result flow, using only Guardian Rifle and Impact Cannon content.

Files:
- Create: none.
- Modify: `data/stages/stage_001.tres`, `game/battle.gd`, `game/wave_director.gd`, `shell/result.gd` only if compatibility requires it, `tests/gdunit/acidblood_behavioral.gd`, `tests/acidblood_checks.gd`.
- Test: `tests/gdunit/acidblood_behavioral.gd`, `tests/acidblood_checks.gd`.
- Delete: none.

Interfaces:
- Consumes: completed line, Guardian, XP/draft, and Cannon lifecycle.
- Produces: a deterministic finite Stage 1 run with victory/defeat/result transitions and no parse, compile, or runtime errors.

- [ ] Write failing completion tests for victory, defeat, result handoff, and draft-budget exhaustion.
- [ ] Run the focused battle tests and require failure before stage integration.
- [ ] Implement the minimum authored Stage 1 resource and completion wiring; do not add new content systems or rebalance later stages.
- [ ] Run focused tests and require PASS with clean error logs.
- [ ] Run all GdUnit behavior, canonical validation, static checks, and runtime smoke.
- [ ] Perform the FINAL PHASE-1 REVIEW with a complete manual Stage 1 playthrough.
- [ ] Commit with `feat: complete Phase 1 battle foundation` only after human approval.

## Validation and review contract

Every task starts with its narrow test. At the appropriate checkpoints run:
`bash tools/validate.sh`, the GdUnit behavioral suite, static checks, runtime
smoke, `git diff --check`, and targeted log inspection. Final Phase 1 approval
requires all of those plus a manual Stage 1 playthrough and a clean worktree.
No task may claim success from an exit code without checking parse/runtime logs.

## Explicitly unverified benchmark behavior

The exact Galaxy pre-battle formation configuration, precise slot coordinates,
draft eligibility/order details, and exact XP curve are UNVERIFIED. Phase 1
uses only the approved structural contracts and data-driven values; it must not
invent those benchmark details or implement Phase 2–6 systems to compensate.
