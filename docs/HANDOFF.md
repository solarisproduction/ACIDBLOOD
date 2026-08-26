# Current Session Bridge

Recommended next executor: GPT-5.6 Luna Medium after the human graphical
review of the Phase 4 enemy foundation.

## Current truth

- Phase 1.1 Pressure & Placement, Horizontal Product Checkpoint 1, Phase 2
  Weapon Foundation, and Phase 3 Draft Architecture are complete and human
  reviewed. Stage 1 remains six authored waves, 320 enemies, 690 available XP,
  and a 20-draft run budget; no pressure rebalance was made here.
- The current route remains Home → Campaign → Battle → Draft/placement →
  Result → Campaign. The draft still has one eligibility authority,
  deterministic offers, explicit categories, and CHAIN cards that require
  both their qualifying BREAKTHROUGH card and selected branch context.
- Phase 4A–4C are implemented for the current roster. EnemyData now owns
  explicit role, neutral-by-default family affinity, validated modifiers, and
  movement pattern. Current roles are Grunt=FRONTLINE, Runner=IMPACT,
  Spitter=RANGED, Brute=SIEGE, and Tyrant=BOSS. Runner uses bounded
  deterministic WEAVE; the other current roster entries remain DIRECT.
- Existing Brute/Tyrant armor remains the only armor mitigation system and is
  identified as ARMORED. Weapon Damage Family reaches the central hit resolver,
  but no non-neutral affinity is active in Stage 1. No Stage Intel or Stage
  2–5 redesign is implemented.

## Validation snapshot

- Official local suite: 98 checks PASS.
- GdUnit4 behavioral pilot: 49 cases PASS, including enemy contracts,
  neutral/soft affinity resolution, deterministic bounded movement, ranged
  stop behavior, Phase 3 path gating, weapons, Cannon splash, and paused
  placement input.
- `bash tools/validate.sh`: PASS, including import, official suite, GdUnit,
  and Stage 1/2 runtime smoke.
- Isolated FRESH seed 11001 and BENCHMARK seed 22001 both completed Stage 1
  with 320 kills, 690 XP, level 15, 14 drafts, and victory. FRESH ended at
  6/100 Barricade HP; BENCHMARK ended at 100/100. Both runs emitted all six
  `wave_start` events and no runtime error signatures.
- Stage 1 resources and Stage 2–30 resources remain unchanged. FRESH and
  BENCHMARK profile runs must remain isolated from the normal save.
- Godot AI MCP had no connected editor session; local Godot 4.7.1 runtime was
  used with explicit writable log files for isolated headless runs.

## Human graphical review

Start the project at the reference 720×1280 viewport:

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --path .
```

Judge only player-facing behavior: whether Grunt, Runner, and Spitter have
distinct readable jobs without labels; whether Runner creates a different
urgency than Grunt; whether Spitter creates a different spatial/timing
problem; whether movement looks intentional; whether dense combat remains
legible; whether Cannon and Guardian targeting remain understandable; whether
Stage 1 is more interesting without becoming arbitrary; and whether Guardian
movement begins to have a natural reason to exist.

Do not redesign Stage 2–5 or add Stage Intel before this review.

## Next decision

If roles, movement, targeting, and Stage 1 readability are healthy, proceed to
the next bounded Phase 4 stage-architecture decision (4E/4F planning after
human review). If a player-facing distinction is unclear, refine only the
specific Phase 4 behavior identified by the review.

## Workspace state

Phase 4 automated scope is complete pending the human graphical gate. No Phase
4E Stage Intel runtime, Stage 2–5 redesign, or Phase 5 work is started.
