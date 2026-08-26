# Current Session Bridge

Recommended next executor: GPT-5.6 Luna Medium after human Phase 1.1 review.
Phase 2 remains gated.

## Current truth

- ACIDBLOOD is a deterministic 3D tower-defense game with roguelite drafts in
  a late-1980s industrial-contamination setting.
- Phase 1 Battle Foundation is implemented and human-reviewed.
- Phase 1.1 Pressure & Placement is automated-complete and human-review
  pending. Stage 1 remains the selected six-wave, 320-enemy calibration.
- The active Stage 1 pool uses existing Guardian/Cannon content;
  `build_cannon` is the NEW TURRET entry. Legacy Bolt/Frost content remains
  outside that pool.
- `Battle` owns placement state. `BattleHUD` runs with
  `PROCESS_MODE_ALWAYS`, shows an in-world non-attacking ghost on eligible
  T1–T4 slots, and handles arrows plus Space/Enter while paused. The old modal
  slot picker is removed.
- The placement cue is now two lines: `CHOOSE SLOT: T1 LEFT` followed by
  `← / → MOVE • SPACE CONFIRM`, updated for the current slot.
- The first horizontal product checkpoint is planned/gated in
  `docs/ROADMAP.md`; it is not active. Phase 2 is not started.

## Incident disposition

The reported FRESH sequence was reproduced through `draft_open` with no later
events when no placement input was supplied. That is the expected paused
interruption, not evidence of a wave-director failure. A scene-runner
integration test now drives the actual physical-key route: Space chooses the
`build_cannon` draft card, Right moves the placement ghost, and Space
confirms. It proves the queued draft, paused-state input, combat freeze, one
install, and resume. Separate behavioral tests cover occupied-slot skipping
and queued-draft ownership. The automated BENCHMARK smoke then records one
`turret_install`, all six `wave_start` events, and victory.

## Validation snapshot

- Local canonical suite: 88 checks PASS.
- GdUnit4 behavioral pilot: 33 cases PASS, including the physical-key
  placement regression.
- FRESH automated profile: isolated defeat before the first draft at 23.47
  simulated seconds; this remains balance evidence, not approval.
- BENCHMARK automated profile: isolated victory, 320 kills, 690 XP, 14 drafts,
  164 simulated seconds, 22.29 average live enemies, 71 peak, 4/100 final
  Barricade HP, and one turret installation.
- Stage 2–30 resources remained bytewise unchanged across the Phase 1.1
  history. `gen_stages.gd --only-stage=1` regenerated one identical Stage 1
  file and did not touch later stages.
- `bash tools/validate.sh` PASS; latest known CI before this session was
  `32915290388` PASS at `cf48ad9`.

## Human graphical gate

Run both commands at normal speed:

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/playtest_fresh.sh
GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/playtest_benchmark.sh
```

Evaluate opening pressure, first-draft timing, whether the placement ghost
and cue are self-evident, arrows/Space input, gameplay resumption, later waves,
density, Guardian relevance, normal-speed draft cadence, and portrait
readability. Do not start Phase 2 until this review is complete.

## Workspace note

The stabilization edits are present in the working tree but could not be
committed or pushed in the current environment because `.git/index.lock`
creation is denied. The next session must preserve those edits and create the
validated checkpoints before treating origin as updated.
