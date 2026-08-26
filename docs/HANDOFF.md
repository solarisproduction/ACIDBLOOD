# Current Session Bridge

Recommended next executor: GPT-5.6 Luna Medium after the human graphical
review of the Phase 3 draft/buildcraft slice.

## Current truth

- Phase 1.1 Pressure & Placement is complete and human-approved. The selected
  Stage 1 calibration remains six waves, 320 enemies, 690 available XP, and
  the human completed it with 320 kills, 14 drafts, Impact Cannon installed,
  victory, and 34/100 final Barricade HP. No rebalance was made here.
- The current shell route is Home → Campaign stage entry → Battle → Draft /
  placement → Result → Campaign. Campaign uses real StageData briefing,
  intent, wave count, and salvage reward fields; it exposes no fake future
  systems.
- Draft presentation now uses reusable `game/draft_card.gd` units in a
  three-column portrait layout. BattleHUD remains the paused input owner;
  wave number/name stay internal and are hidden from the normal HUD.
- Guardian Rifle and Impact Cannon now use the shared `WeaponDefinition`
  resource boundary with explicit Physical family, engagement profile,
  topology, and targeting policy. Guardian remains direct/straight; Cannon
  remains heavy interval/group splash. Presentation is not damage authority.
- Phase 3 draft domain is implemented: 3 NEW TURRET, 8 NORMAL, 6
  BREAKTHROUGH, and 3 CHAIN cards are classified explicitly. COMBO is
  structurally supported but has no current content because no honest
  Guardian/Cannon coexistence card exists yet.
- `Draft.is_eligible` remains the single eligibility authority and now checks
  category validity, branch context, base prerequisites, qualifying path
  prerequisites, excludes, max stacks, unlocks, active-turret context, and
  runtime dead-choice blocks. Seeded offers remain deterministic.
- Draft cards use stable semantic identity accents/badges; focus adds a
  thicker border and neutral glow without changing the base category identity.
- Tesla Coil and Disruption Field mechanics and Phase 4 enemy/stage runtime
  architecture are not started. Phase 4 was audited read-only only.

## Validation snapshot

- Official local suite: 94 checks PASS.
- GdUnit4 behavioral pilot: 44 cases PASS, including shell controls,
  portrait draft layout, weapon contracts, Cannon splash, and the physical-key
  paused placement path.
- `bash tools/validate.sh`: PASS, including import, official suite, GdUnit,
  and smoke stages 1 and 2.
- Stage 1 resources and Stage 2–30 resources remain unchanged by this slice.
- Godot AI MCP had no connected editor session; local Godot 4.7.1 runtime was
  used for validation.

## Human graphical review

Start the project at its reference 720×1280 viewport:

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --path .
```

Then evaluate Home → Campaign stage entry → Deploy → Battle → several Draft
choices (including a Cannon branch when offered) → placement → Result →
Return. Also run the automated profiles:

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/playtest_fresh.sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/playtest_benchmark.sh
```

Judge only player-facing behavior: whether choices now feel like a build;
whether category labels/identity are readable; whether earlier choices affect
later choices; whether a BREAKTHROUGH feels important; whether CHAIN reads as
specialization; whether selection remains obvious without changing category
identity; and whether Stage 1 still feels good. Do not begin Phase 4 before
this review.

## Next decision

If buildcraft is legible and the Stage 1 run remains healthy, recommend
beginning Phase 4A Enemy Roles after the human review. If the human cannot
perceive meaningful build paths or category language, deepen/fix only Phase 3;
do not add Phase 4 content to compensate.

## Phase 4 readiness audit (read-only)

- `EnemyData` already exposes threat profile, speed, armor, contact/ranged
  attack timing, and presentation fields, but not a role/affinity/modifier
  composition contract. `Enemy` is still one runtime script; contact versus
  ranged behavior is implicit in `attack_interval` and `stop_range`, while
  slow, stun, armor-break, and expose are direct runtime methods.
- `StageData`, `WaveData`, and `SpawnGroup` already provide authored intent,
  wave timing, enemy ids, counts, and lanes. `WaveDirector` owns the finite
  wave state machine. Stage Intel and richer composition semantics do not exist.
- The likely future migration is 4A roles → 4B affinity/modifiers → 4C
  movement grammar → 4D composition → 4E Stage Intel → 4F Stage 2–5 teaching.
  Human design is still required for role vocabulary, counter readability,
  movement patterns, and stage-teaching rules. No Phase 4 runtime was added.

## Workspace state

The Phase 3 implementation is committed at `c94af0f`. This correction is
validated locally and is the next checkpoint; no lock file or staged changes
remain. From the repository root, the human can create and push the correction
with:

```bash
git add -A && git commit -m "fix: require breakthrough paths for chain cards" && git push origin HEAD:main
```

No destructive cleanup or Stage 1 retune is authorized.
