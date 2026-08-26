# Roadmap

This is the single high-level sequencing authority. A phase listed here does
not authorize implementation by itself; the active plan and human review gate
are required.

## ACTIVE ROADMAP — GALAXY FOUNDATION RESET

### Phase 0 — Architectural Reset — COMPLETE

- Galaxy Foundation target persisted.
- Legacy gameplay classified as disposable with no compatibility requirement.
- Engineering foundation retained.

### Phase 1 — Battle Foundation — IMPLEMENTED + HUMAN-REVIEWED

- `T1 – T2 – Guardian – T3 – T4` defensive line.
- Active Guardian and four-slot lifecycle.
- Deterministic kill → XP → level-up → three-choice draft flow.
- NEW TURRET and Impact Cannon installation.
- Finite authored Stage 1 and result flow.
- FRESH/BENCHMARK isolated playtest harness.

### Phase 1.1 — Pressure & Placement Calibration — COMPLETE + HUMAN-APPROVED

The executable plan is now inactive because the automated slice is complete;
the human graphical review gate remains. The scope completed or dispositioned
is:

- several-fold higher, more continuous Stage 1 throughput using existing enemy
  types and fragile common enemies;
- coupled calibration of density, overlap, survivability, XP supply, XP curve,
  wave timing, draft cadence, and the approximately 20-draft / approximately
  5-minute successful-run target;
- whether approach depth/spacing should be compressed;
- whether added pressure creates genuine Guardian movement value;
- replacement of the modal slot picker with in-world ghost T1–T4 placement;
- normal-speed telemetry for population pressure, drafts, Guardian movement,
  and placement choices.

The human graphical run completed all six waves and won with 320 kills, 690 XP,
level 15, 14 drafts, Impact Cannon installed, and 34/100 final Barricade HP.
The denser version was judged substantially better. Guardian movement was not
needed and is not a local defect. Preserve this calibration while weapon
identity, projectile readability, and later enemy composition remain future
improvement surfaces.

### Horizontal Product Checkpoint 1 — First Product Slice — IMPLEMENTED; HUMAN GRAPHICAL REVIEW PENDING

This is the first bounded horizontal checkpoint in the single route. Its
purpose is to make the current loop read as one product using only systems that
already exist:

`Home / Campaign entry → Stage → Battle → Draft → Result → return`

Strict scope is navigation and transition ownership, current draft
presentation/readability, the Battle HUD information hierarchy, result clarity,
return flow, and a minimal reusable card presentation foundation only where
the repeated draft need justifies it. The current card work is a functional
portrait iteration, not final art direction.

Explicit exclusions are Shop, currencies, monetization, packs, Mastery, final
Arsenal/collection, duplicate economy, final rarity language, and fake locked
feature tabs. Deep meta remains Phase 5 work.

The current implementation provides a visible Campaign stage-entry surface,
real Home → Campaign → Battle → Draft → Result → Campaign ownership, a
reusable portrait draft card, current HUD hierarchy, and result/return clarity.
Automated and runtime validation pass. Final visual/product judgment remains a
human review gate; this checkpoint does not claim final art approval.

### Phase 2 — Weapon Architecture — FOUNDATION COMPLETE; HUMAN PLAYTEST PENDING

The current Guardian Rifle and Impact Cannon now use the shared
WeaponDefinition boundary with explicit Damage Family, Engagement Profile,
Attack Topology, and Targeting Policy. Guardian and Cannon presentation has a
representative readability pass. Tesla Coil and Disruption Field remain data
only legacy resources; their future mechanics are not started.

The next Phase 2 decision is gated on human playtest: deepen weapon identity if
the current proof is not readable, or begin the bounded Phase 3 draft-architecture
work if the foundation is healthy.

### Phase 3 — Draft Architecture — NEXT AFTER HUMAN WEAPON PLAYTEST

Full NEW TURRET, NORMAL, BREAKTHROUGH, CHAIN, and COMBO semantics with
prerequisites, exclusions, context, dead-choice protection, and deterministic
testing.

### Phase 4 — Enemy and Stage Architecture — FUTURE

Enemy Role + Affinity + Modifiers, soft counters, Stage Intel, and authored
Stages 1–5 onboarding.

### Phase 5 — Meta / Home / Arsenal

Weapon Mastery, collection states, acquisition/shop architecture, packs,
duplicates/Card Level, and economy design.

### Phase 6 — Arsenal Expansion

Fire, Energy, additional weapons, and additional enemy roles/compositions only
after the core architecture proves itself through playtesting.

## Deferred engineering decisions

- Debug Draw 3D remains approved for future combat/battlefield redesign when
  that need is implementation-approved.
- Mindustry remains reference material only.
- State Charts, LimboAI, Phantom Camera, and Sentry remain deferred until a
  demonstrated need exists.
- FUTURE RESEARCH: systematically decompose approximately 8–12 relevant
  mobile / TD / roguelite products across Home, Battle HUD, Draft, Arsenal,
  Upgrade, Stage Select, Result, Shop, Settings, rewards, and navigation.
  Record patterns such as hierarchy, card anatomy, rarity language,
  progression surfaces, gating, reward reveal, interaction choreography,
  encounter pacing, and buildcraft cadence. This is research direction only;
  no web research or template import is part of the current route.
