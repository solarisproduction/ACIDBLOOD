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
- Stage 1 is a finite six-wave authored encounter with 124 current enemies and
  the existing victory/defeat/result flow.

## Active Phase 1.1 plan

`docs/ACTIVE_IMPLEMENTATION_PLAN.md` is now the executable authority for the
approved Pressure & Placement Calibration slice. Tasks A–E cover simulated-time
telemetry, controlled Stage 1 pressure experiments, conservative spacing
calibration, in-world ghost placement, and integrated verification. Phase 2 is
not started.

Task A is complete. Reports now include simulated gameplay seconds, active and
dead-air seconds, active-pressure ratio, average/peak live population, draft
times/intervals, and the existing XP/result fields. Baseline automated reports:
`/private/tmp/phase11-baseline-fresh-1787702174.json` and
`/private/tmp/phase11-baseline-benchmark-1787702178.json`.

## Human Phase 1 review

The human played the graphical BENCHMARK Stage 1: 124 kills, 260 XP, level 9,
8 drafts, victory, and Barricade 100/100. One Cannon-focused build was enough;
Guardian repositioning was not meaningfully required. The direction is
approved, but current pressure is far below the Galaxy reference: the next
calibration should investigate a several-fold increase in continuous visible
throughput without locking an exact multiplier. Enemy volume, survivability,
spawn cadence, overlap, XP supply, thresholds, and draft pacing are coupled.

Approved future placement direction: selecting NEW TURRET returns to the
battlefield, shows a translucent ghost on an eligible numbered slot, lets the
player cycle T1–T4 with a minimal `Choose Slot` instruction, and confirms
in-world. The current modal picker is transitional and remains implemented.

Future enemy movement variation may be small, role-driven, data-driven, and
readable; random wandering is not approved. Stage 1 remains the grammar
tutorial, while later stages may become sophisticated quickly.

## Validation and playtest

- Baseline commit: `3a7d640`; the active plan checkpoint is currently
  uncommitted and must be committed before implementation continues.
- Latest CI: run `32876035890` PASS.
- Local canonical validation: 87 official checks, 25 GdUnit cases, runtime
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

- Current benchmark reached 8 drafts, not the approximately 20-draft pacing
  ceiling; accelerated smoke duration is not real pacing evidence.
- Exact Galaxy slot coordinates, formation behavior, XP curve, and draft order
  remain `UNVERIFIED`.
- In-world ghost placement is approved but not implemented.
- Legacy Bolt/Frost runtime and content remain outside the active Stage 1 pool.
- Phase 1.1 plan is active; implementation is not started. Phase 2 is not
  started.

## Exact next milestone

Execute **Task A — Calibration telemetry and reproducible measurement** from
`docs/ACTIVE_IMPLEMENTATION_PLAN.md`, then proceed through the approved task
sequence only. Do not begin Phase 2.
