# Current Session Bridge

Recommended executor: GPT-5.6 Luna XHIGH / ULTRA HIGH for this autonomous
calibration mission; future routine implementation can return to Luna Medium.
Reason: Phase 1.1 requires controlled balance experiments, spatial/runtime
integration, and review-quality evidence.

## Product and implementation state

- ACIDBLOOD is a 3D tower-defense game with deterministic roguelite drafts in
  a late-1980s industrial-contamination setting.
- The target architecture is [`GALAXY_FOUNDATION_SPEC.md`](GALAXY_FOUNDATION_SPEC.md).
  The current implementation is recorded in [`SYSTEM_BLUEPRINT.md`](SYSTEM_BLUEPRINT.md).
- Phase 1 Battle Foundation is implemented and human-reviewed.
- Stage 1 starts with an active Guardian and four empty slots in
  `T1 – T2 – Guardian – T3 – T4`.
- Kills award run XP exactly once; level-ups pause combat and present three
  deterministic eligible choices; the run budget is 20 choices.
- Stage 1 can offer `build_cannon` as NEW TURRET and install one Impact Cannon
  into an empty slot. Bolt/Frost build cards remain legacy resources but are
  excluded from the active Stage 1 pool.
- Stage 1 is a finite six-wave authored encounter with the selected 320-enemy
  calibration, existing victory/defeat/result flow, and unchanged Stage 2–30
  data.

## Active Phase 1.1 plan

`docs/ACTIVE_IMPLEMENTATION_PLAN.md` is the executable authority for the
approved Pressure & Placement Calibration slice. Tasks A–D now cover
simulated-time telemetry, selected Stage 1 pressure, rejected spacing
compression candidates, and implemented in-world ghost placement. Task E is
the remaining integrated review. Phase 2 is not started.

Task A is complete. Reports now include simulated gameplay seconds, active and
dead-air seconds, active-pressure ratio, average/peak live population, draft
times/intervals, and the existing XP/result fields. Baseline automated reports:
`/private/tmp/phase11-baseline-fresh-1787702174.json` and
`/private/tmp/phase11-baseline-benchmark-1787702178.json`.

Task B selected the generated-source candidate with 320 enemies, 690 available
XP, 14 automated drafts, 164 simulated seconds, average live population 22.29,
peak 71, 93.8% active-pressure ratio, and 4/100 automated final Barricade HP.
Candidate evidence remains in `/private/tmp/phase11-candidate-a-benchmark-3.json`,
`/private/tmp/phase11-candidate-b-benchmark.json`, and
`/private/tmp/phase11-candidate-c-benchmark.json`.

## Human Phase 1 review

The human played the graphical BENCHMARK Stage 1: 124 kills, 260 XP, level 9,
8 drafts, victory, and Barricade 100/100. One Cannon-focused build was enough;
Guardian repositioning was not meaningfully required. The direction is
approved, but current pressure is far below the Galaxy reference: the next
calibration should investigate a several-fold increase in continuous visible
throughput without locking an exact multiplier. Enemy volume, survivability,
spawn cadence, overlap, XP supply, thresholds, and draft pacing are coupled.

Approved placement direction is now implemented: selecting NEW TURRET returns
to the battlefield, shows a translucent non-attacking ghost on an eligible
numbered slot, lets the player cycle T1–T4 with a minimal `Choose Slot`
instruction, and confirms in-world while the same draft pause remains active.

Future enemy movement variation may be small, role-driven, data-driven, and
readable; random wandering is not approved. Stage 1 remains the grammar
tutorial, while later stages may become sophisticated quickly.

## Validation and playtest

- Baseline for this slice: `3a7d640`; plan and implementation checkpoints are
  committed sequentially as each validated task lands.
- Latest CI: run `32876035890` PASS.
- Local canonical validation: 88 official checks, 31 GdUnit cases, runtime
  smoke, and error-log inspection PASS.
- FRESH launch:
  `GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/playtest_fresh.sh`
- BENCHMARK launch:
  `GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/playtest_benchmark.sh`
- These graphical commands require human interaction. Headless smoke runs use
  isolated profiles and write one JSON report under `${TMPDIR:-/tmp}`; they do
  not touch the normal persistent save.
- Current benchmark telemetry is available at
  `/private/tmp/phase1-final-benchmark.json`.

## Known limitations

- The selected automated benchmark reaches 14 drafts, still below the
  approximately 20-draft pacing ceiling; accelerated smoke duration is not real
  human pacing evidence.
- Exact Galaxy slot coordinates, formation behavior, XP curve, and draft order
  remain `UNVERIFIED`.
- The baseline 22.8-unit approach geometry is retained. Tested 20.0-unit and
  21.5-unit compression candidates caused early BENCHMARK defeat, so spacing
  remains a human visual-review question.
- The new ghost placement flow is automated-test verified but still needs
  human graphical feel review.
- Legacy Bolt/Frost runtime and content remain outside the active Stage 1 pool.
- Phase 1.1 Tasks A–D are implemented or dispositioned; Task E remains. Phase 2
  is not started.

## Exact next milestone

Execute **Task E — Integrated Phase 1.1 verification and handoff** from
`docs/ACTIVE_IMPLEMENTATION_PLAN.md`. Then request the human graphical
Phase 1.1 playtest; do not begin Phase 2.
