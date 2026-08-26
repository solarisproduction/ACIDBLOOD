# Active Implementation Plan

Status: COMPLETE — Horizontal Product Checkpoint 1 and the bounded Phase 2
weapon-foundation slice are implemented and locally validated.

## Gates and boundaries

- Phase 1.1 human review is approved: six waves, victory, 320 kills, 690 XP,
  level 15, 14 drafts, Impact Cannon installed, and 34/100 final Barricade HP.
- Preserve the selected 320-enemy Stage 1 calibration; do not retune pressure.
- Phase 3 draft architecture and Phase 4 enemy/stage architecture are not
  part of this plan.
- No fake Home features, economy, monetization, final rarity, or meta systems.

## Completed tasks

1. Phase 1.1 closure — record the approved human verdict and verify the
   current Stage 1 balance remains unchanged.
2. Horizontal Product Checkpoint 1 — connect the real Home/Campaign stage
   entry, Battle, Draft, Result, and return route; improve only current
   player-facing ownership, result clarity, and portrait readability.
3. Phase 2 weapon foundation — promote the current Guardian weapon boundary
   into a shared WeaponDefinition contract and migrate Guardian Rifle plus
   Impact Cannon while preserving stat paths, cards, branches, and targeting
   determinism.
4. Weapon/projectile readability — give Guardian and Cannon distinct current
   projectile/impact presentation without making presentation authoritative or
   changing damage timing.
5. Integrated validation and handoff — run narrow tests, full GdUnit, the
   canonical validator, FRESH/BENCHMARK smoke, shell/combat checks, portrait
   startup checks, log scans, diff checks, and prepare the human playtest.

## Next gate

Phase 1.1 human review is complete. The next human decision is graphical
review of the connected shell and weapon readability. Phase 2 is foundation
complete, not fully complete; Phase 3 and Phase 4 remain unstarted.
