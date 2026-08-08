# System Blueprint (as implemented)

## Layers

```
core/    rules, no Node deps          data/         content
├─ det_rng.gd     seeded RNG streams  ├─ types/     Resource classes
├─ draft.gd       card offer logic    ├─ enemies/   5 archetypes (.tres)
├─ targeting.gd   deterministic aim   ├─ turrets/   3 archetypes
├─ combat.gd      damage math         ├─ cards/     14 cards
├─ leveling.gd    XP curve            ├─ weapons/, guardian.tres
├─ modifier_set.gd stat mods          ├─ progression/ 3 permanent upgrades
├─ run_state.gd   per-run state       └─ stages/    30 generated StageData
├─ progression.gd persistent save
├─ catalog.gd     data registry       autoload/game.gd  app flow singleton
└─ arena_layout.gd gameplay geometry

game/  battle runtime                 shell/  screens
├─ battle.tscn/.gd  orchestrator     ├─ home.tscn/.gd      + upgrade shop
├─ wave_director.gd wave lifecycle   ├─ campaign.tscn/.gd  30 stages + dev tools
├─ guardian, enemy, turret,          └─ result.tscn/.gd    reward step
│  projectile (.gd [+ .tscn])
├─ battle_hud.gd    HUD + draft UI   tests/run_tests.gd    44 headless checks
└─ visuals.gd       material cache   tools/  validate.sh, gen_stages.gd,
                                             balance_report.gd
```

## Flow

Home → Campaign → Battle(StageData) → Result → Campaign. `Game` (autoload)
owns `Progression`, hands `current_stage` + `pending_seed` to Battle, and
receives `end_run(victory, stats)`.

## Battle internals

- `Battle` builds a `RunState` (seed, XP, level, fortress HP, acquired cards,
  `ModifierSet`). Every combat number resolves via `Battle.stat(path, base)`.
- `WaveDirector` consumes `StageData.waves` with accumulated physics delta;
  wave N+1 starts `post_delay` after wave N clears; last clear → victory.
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
progression), prerequisites, excludes, and a runtime `blocked` list (build
cards when all 4 slots are full). Weighted sample without replacement.

## Persistence

`Progression` (cores, completed stages, upgrade levels) → versioned JSON in
`user://`. Catalog = known content; unlock flags = permanent unlocks; RunState
= current-run eligibility/acquisition. Sequential stage unlocking derived from
completed list.
