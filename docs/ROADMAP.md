# Roadmap

This is the single living backlog for future gameplay and presentation work.
If something is not needed for the current run loop, it belongs here and not
spread across other docs.

The project is already past the basic prototype stage. The next phase is not
about adding more isolated features; it is about consolidating the existing
systems into a clearer tower-defense identity and a safer production process.

## Product direction

ACIDBLOOD is a tower defense whose spatial and temporal strategy is enriched
by roguelite buildcraft, set inside a late-1980s industrial contamination
world. A new feature earns priority when it creates a meaningful decision -
positioning, timing, composition, target priority, risk, or commitment - rather
than only a larger numerical result.

The theme source of truth is [`docs/ACIDBLOOD_DIRECTION.md`](ACIDBLOOD_DIRECTION.md).
New gameplay presentation should move toward analog industrial machinery,
chemical/biological contamination, and a coherent city anatomy. Avoid fantasy
fortress language and clean neon cyberpunk unless a task explicitly replaces
legacy placeholder content.

The next systemic work should balance three layers: run decisions (cards and
branches), spatial decisions (slots, coverage, formations), and temporal
decisions (investment, control windows, wave reaction). The run layer is ahead;
deepen the battlefield before adding horizontal content.

## What enters this roadmap

- progression and draft shaping
- tower identity and specialization
- stage/enemy/boss pacing
- presentation, UX, and readability
- validation workflow and safe implementation order

## What stays out for now

- reducing the campaign back to a smaller slice
- parallel systems that do not feed the current run loop
- per-card or per-tower scripts when data can express the same thing
- raw stat inflation as the main form of progression
- any redesign that breaks the current `core` / `data` / `game` / `shell`
  separation

## P0 - foundation and process

- Safe implementation loop
  - Read the target docs before editing.
  - Extend schemas first, then content, then rules, then runtime, then shell.
  - Validate the change in Godot through the editor/runtime path when scenes,
    nodes, or live behavior are involved.
  - If a local validator step fails, classify it by the actual output before
    changing gameplay code. Keep tooling failures and gameplay regressions
    separate.
  - Keep code and data changes small enough to inspect in one pass.
  - Prefer `data/types/` and `data/*.tres` over one-off scripts.
  - For ambiguous spatial UI, make the level itself explicit with labels or
    numbers before trying to infer ordering from transforms or camera angles.
- Feature-quality gate
  - Before a non-trivial feature, identify its decision, tradeoff, failure
    case, player-facing information, interaction with current systems, and
    data-driven implementation path.
  - Defer features that only add numerical output or isolated complexity.
- Visual foundations
  - When touching visuals or imports, validate from the gameplay camera and
    improve only durable conventions: scale, silhouette, pivot, material reuse,
    or readability.
  - When a prototype visual is touched, nudge it toward ACIDBLOOD: concrete,
    steel, rust, petroleum/hospital green, chemical accents, fluorescent
    utility light, analog machinery, pipes, tanks, vents, control boxes, or
    contaminated biological material.
  - Do not begin a global art pass; establish the calibration scene only when
    representative assets or repeated visual decisions make it useful.
- Structural consistency
  - Keep the current layer split intact.
  - Keep gameplay logic in `core/`, content in `data/`, orchestration in
    `game/`, and screens in `shell/`.
  - Keep deterministic behavior where the game is already deterministic.
- First investida gate
  - Start implementation only after the target slice has: a clear schema
    change, a clear content migration, a clear runtime rule, and a validation
    step.
  - If those four pieces are not obvious, the slice is too large.

## P1 - tactical identity

- Current baseline
  - The first-pass tower specialization layer is already live: bolt, cannon,
    and frost each have two exclusive branches.
  - Future work here should deepen those identities, improve teaching and
    readability, and only add new tower families if the current trio stops
    carrying enough strategic variety.
- Positioning as a real decision
  - Define a spatial grammar for slots, paths, and coverage before adding more
    tower families or map content.
  - Each slot should favor a role in a formation, not be simply better or
    worse: precision lines, area curves, crossings, control zones, execution
    zones, and competing lane coverage.
  - Validate positional tradeoffs through actual encounters, not theory alone.
- Existing family depth
  - Bolt is flow, precision, and execution; Cannon is impact, area, and
    prediction; Frost shapes field state and enables the other families.
  - Deepen real branch tradeoffs and family relationships before adding a
    fourth family. Frost control, Cannon payoff, and Bolt priority should form
    optional formations, never mandatory combo chains.
- Tower identity over numbers
  - Each tower should feel like a different answer to the same pressure.
  - Behavior and payoff matter more than small damage deltas.

## P2 - build formation and draft quality

- Build tags and archetypes
  - Organize cards around tags such as shock, impact, frost, support, economy,
    and containment.
  - Every card should either open a build, deepen it, bridge two builds, or
    patch a weakness.
- Draft shaping
  - Keep deterministic selection.
  - Add weighting that rewards commitment to current tags and tower branches.
  - Preserve pivot options so the draft does not lock the player too early.
  - Avoid dead offers when the runtime context already makes them useless.
- Card grammar
  - Keep titles short and game-like: source + effect for stat cards, family +
    branch for specialization cards, and plain action verbs for build/recovery.
  - Keep descriptions effect-first and avoid repeating UI badges in the body.
  - Do not restate `Choose 1`, unlock gates, or slot-pick instructions in the
    description when the HUD already shows them.
- Offer quality
  - Guarantee at least one structural option early when the pool allows it.
  - Do not let the offer pool collapse into one category unless the context
    truly demands it.
  - Keep rerolls or similar pressure-release tools inside the game, not in an
    external meta screen.

## P3 - enemies, encounters, and bosses

- Enemy roles
  - Make each enemy do one clear job.
  - Combine roles to create interesting encounters instead of merely adding
    more HP or speed.
- Encounter contract for the current calibration slice
  - Stage 1 (`Processing Yard`) is the onboarding encounter: Grunts establish
    the basic lane, Runners introduce leak pressure, and Spitters introduce a
    target-priority problem. Its question is: can the player read the threat
    and build a basic answer with the available slots?
  - Stage 2 (`Service Gate`) is the first composition test: Runners, Brutes,
    and Spitters must create different priorities without requiring a new
    system. Its question is: can the player protect the Barricade while
    choosing what must die first?
  - Stage 3 (`Drain Channel 3`) is the first formation test: the existing
    enemy families should pressure coverage, control, and follow-up damage.
    Its question is: does the player's Bolt/Cannon/Frost formation produce a
    meaningful answer, or is one family silently mandatory?
  - Every calibration wave must have one dominant tactical question, one
    readable failure mode, and one plausible answer using current towers and
    branches. Do not add enemy types or systems to solve a problem that can be
    answered by composition, ordering, intervals, or telegraphing.
  - The first implementation pass should record observed results before
    changing numbers. Tuning is allowed only when the live run shows that the
    intended question is not being asked clearly.
  - Stage 1 density direction is approved: preserve weapon potency and use
    roughly 100+ disposable enemies, authored rhythm, and explicit left/
    center/right group pressure to target a readable 150–180 second horde
    defense. Do not apply this density change to Stage 2 or later in this
    slice.
- First live observation
  - Before the density iteration, Stage 1 completed without Barricade damage
    and resolved so quickly that its final mixture read more like a damage
    check than a meaningful target-priority decision. The HUD labels and
    silhouettes were legible; the approved density slice addresses the pacing
    and population gap without changing weapon or enemy HP fundamentals.
  - Stage 2 made the roles more distinct in motion: the larger purple Brute,
    small fast Runners, and green Spitters were visually separable. Its Elite
    Escort did create real Barricade pressure, reducing the objective to
    4/100 before the next draft appeared. This confirms that Stage 2 can test
    pressure, but also exposes a priority conflict: a normal strategic draft
    can compete with a nearly destroyed Barricade. The next slice must keep
    strategic choices readable while allowing a critical-state emergency
    response before tuning enemy numbers or moving to Stage 3.
  - The boss threat marker remains visually ambiguous at close range: the
    orange arc can read as part of the boss body instead of an external
    telegraph. This is recorded as a presentation follow-up, not changed in
    the encounter pass.
- Stage pacing
  - Build the campaign around introduce → combine → pressure → invert → test.
  - Use early stages to teach one idea at a time and middle stages to combine
    tactical questions rather than only scaling statistics.
  - Use boss stages to test learned systems through encounter rules, phases,
    escorts, lane pressure, or priority shifts — not only more HP.
- Boss design
  - Bosses should be encounter rules, not just larger enemies.
  - Reserve the strongest telegraphing and threat escalation for elite and
    boss moments.

## P4 - game feel and presentation

- Theme migration
  - Replace legacy fantasy language as touched. Internal code names can remain
    stable only when renaming them would add more risk than value.
  - First-world presentation should become an abandoned processing district:
    service road, loading yard, containment gate, pump/pipe infrastructure,
    chemical runoff, security fixtures, and peripheral biological growth.
  - Reframe the defended objective away from "fortress" in visible language
    over time: gate, barricade, containment wall, sealed access, or convoy
    anchor are better ACIDBLOOD directions.
- Feedback hierarchy
  - Keep common events subtle.
  - Reserve the strongest feedback for deaths, boss hits, major reactions, and
    victory/defeat.
  - Extend the existing hit/death hierarchy to audio and future VFX passes.
- Readability
  - Make combat readable at a glance before making it flashy.
  - Prioritize threat communication over decoration.
- Presentation growth
  - Add visual and audio polish only where it clarifies state or reinforces
    impact.
  - Establish visual grammar gradually: gameplay-camera readability, scale,
    silhouette, basic material families, value hierarchy, pivots, and import
    hygiene come before final asset detail.

## P5 - UX and accessibility

- UI chunking
  - Compress dense stats into fewer readable groups.
  - Keep the interface simple enough to parse quickly.
- Battle controls
  - Keep draft choice and turret placement keyboard-first.
  - Use arrows plus `Space`/`Enter` as the primary interaction path.
  - Keep mouse/touch available, but do not design around it as the main path.
  - Minimize the control count so the same flow stays viable on mobile.
- Shell flow
  - Keep the home, campaign, battle, and result screens understandable at a
    glance.
  - Make stage intent and progression readable outside the editor.
- Accessibility
  - Keep future HUD additions responsive to the live viewport.
  - Prefer container-based layouts and scrolling where content grows.

## P6 - meta progression

- Meta tracks
  - `Containment`: durability and safety nets.
  - `Command`: rerolls, draft quality, and early flexibility.
  - `Engineering`: branch unlocks and system unlocks.
- Meta philosophy
  - Meta progression should unlock options, not become mandatory grind.
  - It should improve choice quality more than raw power.
  - It should support the run rather than replace it.

## P7 - future expansion

- Larger elemental reaction set
  - Only after the base reaction model is stable.
  - Add combinations only if they stay readable and high-value.
- More content
  - More cards, more branches, more stages, more enemy combinations.
  - New content must still fit the current rules, not force a parallel model.
- Longer-term systems
  - Run save
  - Daily challenges
  - Alternate modes
  - Rankings
  - Narrative expansion
  - Online features only if they are genuinely needed

## Tooling adoption state

### NOW

- Return to gameplay/product development. The infrastructure hardening slice
  is complete: clean Ubuntu CI runs the static job and the canonical
  `tools/validate.sh` job.

### Completed infrastructure slice

- `godot-gdscript-toolkit` 4.5.0 is pinned by commit in
  `.pre-commit-config.yaml`; `gdlint` and check-only `gdformat` are active on
  the bounded clean `data/types/` adoption boundary.
- `pre-commit` 4.3.0 is pinned in clean CI and runs lightweight whitespace,
  EOF, `gdlint`, and `gdformat --check` hooks. Full `tools/validate.sh` is not
  required on every pre-commit invocation.
- Existing legacy lint/format violations remain bounded adoption debt. Never
  mass-run formatter write mode or add broad suppression merely for green CI.
- Do not start another infrastructure initiative in this slice.

### Preserved combat-development and reference decisions

- `Debug Draw 3D` is approved when combat/battlefield work begins. Its purpose
  is runtime visualization of relevant spatial combat information such as
  turret ranges, targeting, splash/impact areas, enemy paths/path progress,
  spawn points, choke regions, stop distances, knockback, and zones/status
  areas. It is not generic base infrastructure; reconsider/install it when
  combat/battlefield redesign becomes active.
- Mature open-source game implementations such as `Mindustry` are reference
  only for studying data-driven patterns; never copy product design directly.
- Defer `State Charts` until a proven need exists; defer `LimboAI` until a
  proven need exists; defer `Phantom Camera` until a later camera need; and
  defer `Sentry` until an external QA/release need.

## Current implementation notes

- The current project already supports deterministic waves, card draft, build
  cards, turret branches, frozen/heavy-impact logic, a Guardian active pulse,
  bottom HUD cooldown feedback, tag-based draft synergy, and context-aware
  draft weighting.
- The base shatter reaction is implemented: frozen enemies take a heavy-impact
  burst with armor break, stun, and a visual pulse.
- New work should extend those systems first before adding parallel systems.
- Prefer data-driven additions in `data/types/` and `data/*.tres` over new
  one-off scripts.

## Ready for the first investida when

- the next slice has one clear target
- the required schema change is known
- the affected content is known
- the runtime rule is known
- the validation path is known
- the slice can be completed without changing the project structure

Completed items are moved to [`docs/HANDOFF.md`](docs/HANDOFF.md) so this file
stays limited to remaining work.
