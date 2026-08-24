# System Blueprint (as implemented)

## Layers

```
core/    rules, no Node deps          data/         content
├─ det_rng.gd     seeded RNG streams  ├─ types/     Resource classes
├─ draft.gd       card offer logic    ├─ enemies/   5 archetypes (.tres)
├─ targeting.gd   deterministic aim   ├─ turrets/   3 archetypes
├─ combat.gd      damage math         ├─ cards/     20 cards
├─ leveling.gd    XP curve            ├─ weapons/, guardian.tres
├─ modifier_set.gd stat mods          ├─ progression/ 3 permanent upgrades
├─ run_state.gd   per-run state       └─ stages/    30 generated StageData
├─ progression.gd persistent save
├─ catalog.gd     data registry       autoload/game.gd  app flow singleton
└─ arena_layout.gd gameplay geometry

game/  battle runtime                 shell/  screens
├─ battle.tscn/.gd  orchestrator     ├─ home.tscn/.gd      + upgrade shop
├─ wave_director.gd wave lifecycle   ├─ campaign.tscn/.gd  30 stages + dev tools
├─ guardian, enemy, turret,          └─ result.tscn/.gd    report step
│  projectile (.gd [+ .tscn])
├─ battle_hud.gd    HUD + draft UI   tests/run_tests.gd    83 headless checks
│                                      tests/gdunit/      GdUnit4 behavioral pilot
└─ visuals.gd       material cache   tools/  validate.sh, gen_stages.gd,
                                             balance_report.gd
```

## Flow

Command → Operations → Battle(StageData) → Report → Operations. `Game` (autoload)
owns `Progression`, hands `current_stage` + `pending_seed` to Battle, and
receives `end_run(victory, stats)`.

## Battle internals

- `Battle` builds a `RunState` (seed, XP, level, gate HP, acquired cards,
  `ModifierSet`). Every combat number resolves via `Battle.stat(path, base)`.
- `WaveDirector` consumes `StageData.waves` with accumulated physics delta;
  wave N+1 starts `post_delay` after wave N clears; last clear → victory.
  Spawn lane randomness comes only from `Battle.roll_spawn_x()`.
- Enemies: one script; kamikaze vs stationary-attacker is data
  (`attack_interval`, `stop_range`). Slow status lives on the enemy.
- Targeting rule (core): most-advanced alive enemy in range, ties by lowest
  spawn index — deterministic and inspectable.
- Hits resolve centrally in `Battle.apply_hit` (armor, splash, slow).
- Kills → XP → `RunState.grant_xp` may return multiple level-ups; drafts
  queue, tree pauses, HUD shows 3 cards (overlay is `process_mode ALWAYS`).

## Determinism

Run seed → `DetRNG.derive(seed, "waves")` for spawn X positions and
`DetRNG.derive(seed, "draft", draft_index)` per draft. Same seed + state =
same offers/spawns (covered by tests). Physics at fixed 60 Hz.

## Draft eligibility

`Draft.is_eligible`: max_stacks, `requires_unlock` (permanent flags from
progression), prerequisites, excludes, full-HP heal suppression, and a runtime
`blocked` list (build cards when all 4 slots are full). Offer generation also
applies light early-run quality guardrails: guarantee a `Build` option in the
first drafts when available and avoid single-category collapses when valid
alternatives exist. Weighted sample without replacement.

## Persistence

`Progression` (salvage, completed stages, upgrade levels) → versioned JSON in
`user://`. Catalog = known content; unlock flags = permanent unlocks; RunState
= current-run eligibility/acquisition. Sequential stage unlocking derived from
completed list.

## Scene editing practice

For UI and presentation work, prefer Godot-aware scene operations and runtime
validation through the Godot/MCP bridge before falling back to manual `.tscn`
editing. Keep the split clear:
- scene graph/layout/presentation: Godot scene workflow first
- gameplay rules/data/logic: `.gd` and `.tres`

## Art-production practice

`game/arena.tscn` is the environmental and slot-layout baseline; it may become
the calibration scene for representative assets once that need is real. Validate
visual work at the gameplay camera and preserve gameplay semantics when
replacing placeholder models.

## Required workflow

Any Godot-related edit, inspection, or validation must go through the Godot AI
MCP tools when they are available. The engine is part of the editing workflow:
inspect in-editor, run in-engine, and confirm parse/runtime state before
declaring the change complete.

## Operational tuning

Use `tools/balance_report.gd` as the first tuning surface. It prints:
- shared geometry and combat floors (`ArenaLayout`, `Combat`)
- guardian / enemy / turret bases
- card categories / roles and permanent upgrades
- per-stage wave pacing with enemy count, total XP, and projected level-ups

## Why this shape

These are the core implementation choices the project currently relies on:

- Rules live in `core/` as `RefCounted` so headless tests and simulators stay
  possible.
- Stats flow through path-based modifiers instead of per-entity upgrade fields.
- Cards stay in a small effect vocabulary unless a new op is truly necessary.
- Stages are generated into committed `.tres` files rather than hand-edited.
- Combat uses distance checks over the enemy registry instead of physics
  bodies.
- RNG comes from `DetRNG.derive(seed, salt, index)` so streams stay isolated.
- Enemy variants are data, not subclass trees.
- Camera and light setup stay in `battle.gd` for now because they are stable,
  scene-level transforms that rarely need editor tweaking.
- Smoke runs live in the shipped autoload so the real game loop is what gets
  tested.
