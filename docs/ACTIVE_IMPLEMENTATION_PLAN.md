# Active Implementation Plan

Status: INACTIVE — Phase 3 automated implementation complete; human review pending.

## Gates

- Phase 1.1 is human-approved; preserve Stage 1's six-wave, 320-enemy
  calibration.
- Phase 2 Weapon Foundation is implemented; preserve Guardian Rifle and
  Impact Cannon behavior.
- Phase 4 runtime implementation is out of scope.
- No economy, rerolls, rarity, new weapons, new enemies, or speculative card
  mechanics.

## Tasks

- **3A — Draft domain foundation — COMPLETE:** make NEW TURRET, NORMAL, BREAKTHROUGH,
   CHAIN, and COMBO explicit in card data; classify current content honestly.
- **3B — Eligibility and choice quality — COMPLETE:** keep one core eligibility
   authority, add context/dead-choice protection, and prove deterministic
   offers under identical and changed run state.
- **3C — Build paths and synergy — COMPLETE:** make the existing Cannon branch a tested
   BREAKTHROUGH path, use honest prerequisite-driven CHAIN content, and keep
   COMBO structurally supported without speculative Stage 1 content.
- **3D — Card semantic language — COMPLETE:** show stable category identity separately
   from focus/selection in the existing DraftCard at 720×1280.
- **3E — Run-level validation — COMPLETE:** add compact category/build-path telemetry
   and deterministic Guardian/Cannon scenarios without changing Stage 1 data.
- **3F — Integrated review — COMPLETE:** inspect for duplicate authorities and Phase 4
   leakage, perform a read-only Phase 4 readiness audit, update authorities,
   and run the complete validation suite.

## Completion gate

Automated Phase 3 is green. Human Phase 3 graphical review remains pending.
Completed detail belongs in Git history; current runtime
truth belongs in `docs/SYSTEM_BLUEPRINT.md`, sequencing in `docs/ROADMAP.md`,
and the immediate bridge in `docs/HANDOFF.md`.
