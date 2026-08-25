# Handoff

Recommended executor for Task 2.5 review: Luna 5.6 Low
Reason: bounded QA/development infrastructure is implemented; Task 3 remains next.

## Architectural reset checkpoint
- Human-approved architectural reset: the first serious ACIDBLOOD version now
  targets the structural Galaxy Defense foundation documented in
  [`docs/GALAXY_FOUNDATION_SPEC.md`](GALAXY_FOUNDATION_SPEC.md).
- The Stage 1 v2 density/pressure experiment was explicitly discarded and is
  no longer part of the product baseline.
- Existing gameplay, stages, battlefield geometry, turret behavior, enemies,
  draft, and progression are legacy/current implementation only. They are
  disposable and impose no backward-compatibility constraint.
- `docs/SYSTEM_BLUEPRINT.md` remains current implemented technical truth; it is
  not the target design.
- Phase 0 is complete after this documentation checkpoint.
- Phase 1 planning is complete in [`docs/ACTIVE_IMPLEMENTATION_PLAN.md`](ACTIVE_IMPLEMENTATION_PLAN.md), which is now the execution authority.
- Phase 1 Task 1 is complete: the domain/test contracts now cover four empty
  slots, active Guardian state, exactly-once kill XP, configurable leveling,
  bounded drafts, and deterministic offers.
- Phase 1 Task 2 is implemented locally: the active battle scene now uses the
  fixed T1–T2–Guardian–T3–T4 line, with four empty runtime slots and the
  existing laterally movable Guardian.
- REVIEW GATE A is approved by human review.
- Task 2.5 provides isolated FRESH and BENCHMARK profiles. Launch FRESH with:
  `GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/playtest_fresh.sh`
  Launch BENCHMARK with:
  `GODOT=/Applications/Godot.app/Contents/MacOS/Godot tools/playtest_benchmark.sh`
  These are graphical human-playtest commands. Automated headless runs may
  add `--headless --time-scale 8` to the Godot invocation directly, using the
  explicit profile flags and report path.
- BENCHMARK v1 is the smallest evidence-backed evolved snapshot: 17 cores,
  stages 1 and 2 completed, `guardian_core` level 2, and `frost_protocol`
  level 1 (unlocking Frost); it has no persistent owned run cards. FRESH has
  zero cores, no completed stages, and no permanent upgrades.
- Each run writes one JSON report to the explicit path, or by default to
  `${TMPDIR:-/tmp}/acidblood-playtest-<profile>-<unix>.json`; reports are
  development artifacts outside tracked source.
- Current reports populate identity, seed/profile version, stage, outcome,
  elapsed time, kills, barricade state, peak population, Guardian movement
  episodes, Pulse count, and event history. XP/draft fields remain dormant until their
  owning tasks implement those systems.
- Approved pacing benchmark: a normal successful run near the approximately
  20-draft ceiling should tend toward approximately 5 minutes. This is a
  pacing target, not a rigid timer; XP curve, density, XP supply, wave timing,
  and draft cadence must be balanced together. Boss/special modes may differ;
  the exact XP curve remains tunable/UNVERIFIED.
- NEXT: `Task 3: Integrate deterministic kills, XP and level-up interruption`.
  Task 3 has not started and Phase 1 is not complete.

## Pass 08 factual checkpoint
- Infrastructure hardening is complete. GitHub Actions run `32760784952` is
  green for the static checks and canonical validation jobs. Godot `4.7.1`
  runs on clean Ubuntu; `tools/validate.sh` remains the full local authority.
- `gdlint`, check-only `gdformat`, and lightweight `pre-commit` hooks are
  active. Full validation is not required on every pre-commit invocation.
- The verified playable loop is Command/Home → Operations/Campaign → Battle →
  Report/Result → Operations, with sequential stage unlocks and local save.
- Battle is a perspective single-lane approach with a Barricade, Guardian
  behind it, four fixed numbered turret slots, and no branching path grammar.
- The current content has three data-driven turret families with two branches
  each, five enemy profiles, twenty cards, three permanent upgrade tracks, and
  thirty stages. Stages 1–2 are authored teaching/composition encounters;
  Stage 3 onward is predominantly generated/repeated wave grammar with stat
  scaling.
- Current combat feedback is a readable prototype skeleton: recoil, camera
  shake, impact/death bursts, lightning/frost telegraphs, and tracers exist;
  no audio or particle layer is implemented. The campaign still exposes
  prototype `DEV` controls.

## Infrastructure hardening history
- The workflow is intentionally independent of MCP, local editor caches, local
  saves, and local reports. GitHub/main remains authoritative, and GitHub CI
  does not replace Godot AI MCP editor/runtime inspection during development.
- Repository-owned validation helpers now use `${TMPDIR:-/tmp}` for temporary
  user-data and log paths, and `tools/run_safe.sh` resolves the repository from
  its own location instead of assuming the developer's Mac path.
- `tools/make_context_snapshot.sh` continues to write the canonical temporary
  `ACIDBLOOD_SESSION_CONTEXT.md` and optionally mirrors only that generated
  file into a detected local Dropbox `ACIDBLOOD Context` folder. GitHub/main
  remains the authoritative source of truth; Dropbox is only a read bridge for
  ChatGPT/session continuity and is never a project dependency.
- The previous clean-machine save/load and optional GdUnit log-copy failures
  were resolved by portable temporary paths and an ACIDBLOOD-owned guard; no
  vendor code was changed.

## Highest-leverage next design question
- Current gap: the single-lane, fixed-slot battlefield and mostly repeated
  generated waves provide limited spatial and encounter-structure decisions,
  even though tower branches and cards now provide substantial build choice.
- Question: How should the battlefield and encounter grammar create meaningful
  positioning and timing decisions from the existing tower, enemy, and card
  systems?

## What actually works (all verified this session)
- The project identity is `ACIDBLOOD`. Future player-facing naming, visual
  work, enemy direction, VFX, and art production should follow
  `docs/ACIDBLOOD_DIRECTION.md`: late-1980s industrial contamination, analog
  machinery, chemical/biological corruption, and a coherent rotting city
  rather than fantasy fortress language or clean neon cyberpunk.
- Full loop: Command → Operations → Battle → Report → Operations, with
  sequential stage unlocking and local save.
- Portrait 3D battle (perspective lane camera, Mobile renderer): Guardian
  moves/auto-targets/auto-fires; 5 enemy archetypes (infected worker/tunnel
  runner/hazmat brute/pressure spitter/boss) advance and pressure the
  barricade; 4 authored tower slots; 3 turret archetypes (bolt/cannon/frost)
  built via cards.
- Draft now uses tag-based synergy weighting, so cards reinforce the current
  build instead of appearing as isolated upgrades.
- Draft also responds to run context: low gate HP favors recovery, open
  slots favor structure, and active build tags are reinforced.
- Cannon and frost branch paths are now in place alongside bolt branches, so
  each turret family has two explicit specialization options with matching
  branch cards and runtime stat effects.
- Guardian active ability is implemented as a frontal pulse on Space, with
  stun/knockback and cooldown feedback in the battle HUD.
- Frozen + heavy impact now triggers shatter with burst damage, armor break,
  and short stun, using a data-driven reaction path.
- The first persistent-behavior direction slice is underway: Bolt now uses a
  data-driven instant lightning attack mode instead of a traveling sphere,
  with a short electric arc effect; the Bolt Chain branch now actually chains
  to up to two nearby targets with reduced damage and deterministic selection.
  Its branch/card grammar now names and explains the actual Chain Lightning
  behavior instead of describing a fire-rate-only upgrade.
- Bolt's second branch is now a real persistent behavior path instead of the
  earlier long-range placeholder: `bolt_field` seeds a short-lived electric
  zone on hit, repeatedly shocking enemies inside it with a simple ring/core
  telegraph. Bolt now has a clean branch split between chain coverage and
  area hold.
- Cannon's `Impact Cannon` branch now has a real direct-hit payload instead
  of being mostly a stat bundle: its shells always count as heavy impacts,
  briefly stagger the direct target, apply armor break, push enemies back a
  little, and use a slightly larger shell so the branch reads more clearly in
  motion.
- Frost's `Crack Ice` branch now applies a real exposed-state payload instead
  of only implying “follow-up damage” in text: frost hits can mark targets
  with a short vulnerability window that amplifies subsequent damage from any
  source, while the branch still gives up some control uptime.
- Guardian fire has been replaced from chunky, lightly homing shots with a
  higher-cadence ballistic stream that preserves roughly the same base DPS:
  smaller bullets, faster travel, almost straight-line flight, and a compact
  mini-comet trail now make the weapon read more like a clean machine-gun
  burst.
- Placeholder turrets now separate family identity through both silhouette and
  fire response instead of color alone: bolt reads as a lighter electrical
  emitter with side coils, cannon as a heavier pressure barrel with recoil,
  and frost as a compact sprayer/tank unit with softer pressure feedback. The
  current goal is tactical readability in prototype conditions, not asset
  polish.
- Visible HUD wording has also been trimmed toward more direct game language:
  family labels now match what the player sees in-world (`Bolt`, `Cannon`,
  `Frost`, `Barricade`), the active ability reads as `Pulse`, and draft/slot
  prompts use simpler upgrade/deploy phrasing instead of more system-heavy
  wording.
- Player-facing tower naming is now standardized around simple base-unit
  labels: `Bolt Turret`, `Cannon Turret`, and `Frost Turret`. Player-facing
  defense text uses `Barricade` consistently as well, replacing earlier mixed
  uses of `Gate`, `Containment Wall`, `Arc Coil`, `Pressure Cannon`, and
  `Cryo Sprayer` in visible card/progression copy.
- The shell/meta screen now follows the same naming direction as battle:
  upgrade tracks read as `Barricade`, `Guardian`, and `Turrets`, the upgrade
  panel uses simpler operations language, and upgrade buttons distinguish
  `Upgrade` from one-time `Unlock` actions so the meta layer no longer speaks
  a different UI dialect from the run itself.
- The first encounter-design contract is now documented for the calibration
  slice: Stage 1 teaches lane reading, Runner leakage, and target priority;
  Stage 2 tests composition under Barricade pressure; Stage 3 tests whether
  Bolt, Cannon, and Frost form a meaningful formation. The contract requires
  observing the live run before changing numbers and forbids adding systems or
  enemies to compensate for a wave that can be fixed through composition,
  ordering, intervals, or telegraphing.
- The first live encounter observation is complete for Stages 1 and 2. Stage 1
  read clearly but resolved too safely to create a strong priority decision.
  Stage 2 produced distinct Brute/Runner/Spitter silhouettes and real boss
  pressure, taking the Barricade to 4/100 before a draft appeared. This
  revealed a concrete next issue: draft visibility must not compete with a
  nearly destroyed Barricade. No balance numbers were changed from this
  observation.
- Guardian mini-comet shots now use a black tip with a white trail, and the
  cosmetic tracers die on first enemy contact. There is no implicit pierce:
  if the weapon has `pierce = 0`, only explicit pierce content should ever
  allow a shot to continue through targets.
- Threat telegraphing is now data-driven by enemy profile: elites and bosses
  get stronger silhouettes, ranged enemies get a clearer pre-attack read, and
  bosses show explicit approach/down banners.
- Common hit/death feedback is now layered by threat level so basic enemies
  stay subtle while elites and bosses read more strongly.
- Enemy placeholder silhouettes now separate tactical roles more clearly even
  before final art: workers read as upright medium threats, tunnel runners as
  lower forward-leaning rushers, hazmat brutes as wider mass targets with back
  equipment weight, and spitters as ranged organisms with a visible frontal
  attack organ. The goal is functional combat reading first, not decorative
  model complexity.
- Brute and spitter danger reads now also have role-specific motion in the
  placeholder layer: brutes compress and throw more body weight into barricade
  contact, while spitters visibly swell/project forward during attack windup
  and release back on shot. This keeps prototype combat readable through pose
  and timing, not only through color labels or UI.
- Battle presentation scale is now data-driven in the Inspector for guardian,
  turrets, enemies, and projectile sizing.
- Waves and stages fully from data; 30-stage campaign now carries act-aware
  pacing metadata in `StageData`/`WaveData`, with stage 2 demoted from an
  early boss spike to an elite escort and boss warnings reserved for the real
  act climaxes.
- Stages 11–29 received a light balance pass to keep the middle of the
  campaign readable and moving: the non-boss stretch now sits slightly lower
  on enemy HP/speed pressure, while the boss pivots at 10/20/30 stay intact.
- The battle HUD and campaign screen now surface act number, stage intent, and
  stage briefings so the macro-flow is readable outside the editor.
- XP → level-up pauses combat → deterministic 3-card draft (weights,
  prerequisites, exclusions, stack limits, permanent-unlock gating, slots-full
  blocking). Cards change gameplay (stats, turret builds, heals).
- Draft and build placement are keyboard-first: arrows move focus and
  `Space`/`Enter` confirm the choice. Build cards now open an explicit slot
  picker instead of auto-placing into the next free slot.
- For the 4 tower pads, the numbered pad surface is the source of truth for
  placement. The picker follows the same explicit `1 → 2 → 3 → 4` order, so
  the scene and the HUD stay aligned without camera inference. The slot picker
  now also shows the front/back line legend so the player learns the spatial
  grammar directly in the draft flow.
- The main battle surface has now been pushed one step closer to ACIDBLOOD's
  first-world target without changing gameplay geometry: the arena reads more
  like a processing yard/service road with a containment gate, industrial
  shoulder strips, warning markers, and technical yard props instead of a
  neutral lane plus fantasy-adjacent objective.
- A follow-up presentation pass is still needed on the defended objective
  itself: from the gameplay camera it now sits in a more industrial context,
  but the gate silhouette still competes with the HUD and bottom framing, so
  future work should improve objective prominence through camera-safe shaping
  rather than extra decorative clutter.
- The battle camera is no longer locked to a near-zenith orthographic read.
  The current presentation direction now assumes a perspective lane with more
  visible depth, a longer approach, and a simple backfield spawn origin so
  enemies can be seen coming from farther away. This helps narrative pressure
  and forward reading, but it also creates a new composition constraint: the
  top HUD currently overlaps the newly visible backfield, so future iteration
  should treat arena depth and HUD framing as one presentation problem.
- The defended objective has now been pushed down toward a lower barricade
  read instead of a tall gate mass, while the enemy approach extends farther
  into a rear industrial building so the spawn pressure visually comes from a
  place. This is the current direction for the first-world arena: a longer
  service road, low containment barricade near the player, and a hostile
  industrial source at the far end.
- Stage 1 of the barricade conversion is now in place: the defended objective
  is player-facing as `Barricade`, and the guardian now stands behind it in
  the arena composition.
- Stage 2 of the barricade conversion is now in place: contact enemies no
  longer die on touch. They stop at the barricade line, remain alive there,
  and apply repeated barricade damage until they are killed or the run is
  lost. Ranged attackers still use their stop range / attack cadence model.
- The first readability pass for barricade pressure is also in: barricade
  damage now raises a short `Barricade Under Attack` banner, contact attackers
  spawn impact feedback directly on the barricade line, and enemies in contact
  lean forward slightly so their attack state reads more clearly in the lane.
- Draft timing now distinguishes routine pressure from a critical emergency:
  during non-critical barricade attacks, level-ups remain queued and the run
  continues; when the Barricade is at or below 35% HP and under active
  pressure, the draft opens immediately and pauses the tree. Critical offers
  guarantee an eligible fortress-recovery card while preserving the remaining
  build/pivot choices through deterministic weighted selection. The HUD marks
  the state as `Emergency response available` and labels recovery cards as
  `EMERGENCY`; normal cards remain build/choice/passive options. This keeps the
  pressure meaningful without making the player read a strategic draft while
  the objective continues taking damage.
- The Guardian silhouette has now been pulled one step away from pure
  placeholder geometry and toward ACIDBLOOD's industrial-defense direction:
  the runtime model reads as a squat defender with torso, head, shoulder mass,
  backpack, and a more explicit forward weapon profile. This is still simple
  prototype geometry, but it now communicates "human defender behind a
  barricade" more clearly in the live camera.
- The Guardian placeholder now also respects weapon direction more honestly:
  the rifle points up-lane, the muzzle marker sits at the barrel tip instead
  of behind the body, and the placeholder material pass separates body/gear/
  weapon values so the silhouette reads as a human operator with a dark rifle
  rather than a single cyan blob.
- The Guardian placeholder now carries a minimal firing pose/recoil layer in
  runtime as well: body and weapon meshes kick back briefly on real shots and
  settle automatically, so the burst reads less like a static emitter and more
  like a person bracing and firing a compact automatic weapon.
- Permanent progression: salvage from victories (reduced on repeat clears),
  3 upgrades (Containment Plating, Guardian Damage, Unlock Frost Turret),
  versioned JSON save/load.
- Gate HP is fixed by the stage base value plus permanent upgrade
  investment; it does not auto-scale with stage difficulty.
- Dev tools: campaign Auto-Win Next + Reset Save (debug builds), `--smoke`
  autoplay, `--screenshot=` capture mode.
- Godot MCP remains the required validation path for gameplay work: inspect in
  the editor, run the project, and confirm changes in the live battle scene
  instead of editing by code alone.

## Validation (last run: smoke PASS)
```
./tools/validate.sh
```
Runs: Godot detection → headless import/parse → 83-check core suite (RNG
determinism, draft rules, save/load, campaign traversal, data references,
content conventions, projectile collision coverage) → GdUnit4 behavioral
pilot → stage 1 + stage 2 runtime smokes. Exits non-zero on failure.
Observed current baseline: `./tools/validate.sh` passed end-to-end this
session, including parse/load, the 83-check suite, the GdUnit4 pilot, and the
runtime smoke stages.
The canonical behavioral suite uses `./tools/run_gdunit.sh --godot_binary
"$GODOT" --headless --ignoreHeadlessMode -a res://tests/gdunit/`.
Reports land under `res://reports/` and are ignored in git.
Additional Godot MCP smoke checks continue to be useful for live runtime
behavior after scene changes.

## Discarded legacy experiment: Stage 1 density iteration
- Stage 1 was increased from 29 enemies across 3 sparse waves to 124 enemies
  across 6 authored waves. Existing grunt, runner, and spitter identities are
  preserved; no global HP or weapon changes were made. This experiment was
  discarded during the architectural reset and is not an active baseline.
- Groups now use deterministic authored left/center/right spawn bands. The
  rhythm progresses from an opening and directional reinforcement through a
  release, mixed pressure, population surge, and climax.
- An autoplay runtime pass won with 124 kills, 7 cards, four turrets, and no
  Barricade loss. Normal-speed duration still needs human-paced confirmation.
- Unresolved gameplay question: does the higher population create meaningful
  lateral and timing decisions for a human player, or mostly increase visual
  throughput?

## Known limitations
- The macro-flow baseline is in place; any later tuning should be treated as
  normal balance work, not missing implementation.
- Catalog lists `res://data` via DirAccess — fine in editor/headless; exported
  builds will need a preload manifest.
- No SFX/particles/juice; placeholder primitives; no pause
  menu; no run-in-progress save (runs are short by design).
- Guardian projectile spread uses straight (non-homing) shots when Multi Shot
  is taken; single shots home.
- Smoke timeout debugging exists for battle runs: if a smoke hangs, `Game`
  prints `SMOKE_DEBUG` with live enemy/projectile counts before quitting.
- If a macOS headless run crashes before the helper comes up, it is an engine
  issue until proved otherwise; do not rewrite gameplay logic to compensate for
  that validation failure alone.

## Backlog

Future work now lives in [`docs/ROADMAP.md`](docs/ROADMAP.md).

## External agent handoff

When another terminal agent takes over this repository:

- have it read `AGENTS.md`, `PROJECT_RULES.md`, `docs/HANDOFF.md`, and `docs/ROADMAP.md` first
- have it treat `docs/ACIDBLOOD_DIRECTION.md` as the source of truth for theme,
  naming, art direction, and prototype visual choices
- ask it to analyze the project state before editing anything
- ask it to return one concrete plan for the current slice in a single long execution
- keep it constrained to what the docs already say; do not let it invent new product rules, new systems, or new docs unless the repository explicitly needs them
- keep the game as the source of truth: prefer in-engine validation for Godot work, and keep changes aligned with real tower-defense practice
