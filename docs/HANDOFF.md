# Current Session Bridge

Recommended next executor: GPT-5.6 Luna Medium after the human graphical
review of the product slice and Phase 2 weapon foundation.

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
- Tesla Coil and Disruption Field mechanics, Phase 3 draft architecture, and
  Phase 4 enemy/stage architecture are not started.

## Validation snapshot

- Official local suite: 89 checks PASS.
- GdUnit4 behavioral pilot: 37 cases PASS, including shell controls,
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

Then evaluate Home → Campaign stage entry → Deploy → Battle → first Draft →
placement → Result → Return. Also run the automated profiles:

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/playtest_fresh.sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/playtest_benchmark.sh
```

Judge whether the route feels connected, the Campaign entry is legible, three
cards read immediately, the portrait layout fits, wave labels are safely out
of the normal HUD, placement remains obvious, Result/Return is clear, and
Guardian versus Cannon reads through cadence, travel, weight, impact, and
splash without visual noise. Do not begin Phase 3 before this review.

## Next decision

If the weapon proof is readable and the route is coherent, choose whether to
begin the bounded Phase 3 draft-architecture milestone. If Guardian/Cannon
identity or the product route is not yet readable, deepen only that approved
Phase 2 foundation before starting Phase 3.

## Workspace state

The implementation is locally validated but not committed in this executor:
the managed macOS workspace denies creation of `.git/index.lock`. The next
human terminal should commit the current tracked and untracked mission files
as one checkpoint: `feat: connect product slice and weapon foundation`, then
push `main` and inspect CI.
