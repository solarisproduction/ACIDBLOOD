# Galaxy Foundation Specification

Status: approved target product architecture for the first serious version of
ACIDBLOOD, Galaxy Defense: Fortress TD structural benchmark.

This document describes the target architecture, not the current game.
`docs/SYSTEM_BLUEPRINT.md` remains the current implemented technical truth.
The existing gameplay implementation is legacy/disposable and may be replaced;
there is no backward-compatibility requirement for it. Git/GitHub, CI,
`tools/validate.sh`, GdUnit, Godot AI MCP 3.1.5, static tooling, deterministic
testing, documentation authority, and fitting generic core infrastructure
remain the engineering foundation.

The benchmark is structural only. Never copy proprietary code, assets, names,
audio, visuals, or protected creative expression. Publicly known or directly
observed benchmark behavior is preferred over arbitrary invention. Unknown
behavior is `UNVERIFIED` until researched or confirmed; it must not be filled
with a convenient invented mechanic.

## 1. Core battlefield

The defensive lineup is:

`T1 – T2 – GUARDIAN – T3 – T4`

- Guardian is the movable defensive unit.
- Four turret positions form the fixed defensive lineup.
- Existing staggered/deep ACIDBLOOD slots are legacy.
- Longitudinal strategy should primarily come from weapon engagement behavior,
  not turrets occupying different depths.
- Turrets are acquired progressively through the in-run draft.
- A run begins with Guardian active and turret slots initially unfilled.
- Arbitrary mid-battle turret repositioning is not assumed.
- Pre-battle/home formation configuration may exist following the benchmark;
  exact behavior is `UNVERIFIED` until confirmed.

## 2. Run economy and level-ups

The initial benchmark loop is:

`kills → run XP/energy → level up → 3 card choices → choose 1 → continue`

- Normal stages have a finite draft/level-up budget.
- The initial benchmark is approximately 20 choices per stage, subject to
  later balance validation.
- Dense hordes and frequent kills feed build evolution.
- New turret acquisition competes with deepening existing weapons.
- Stage pacing controls level-up timing; level-ups should not be evenly spaced
  merely by elapsed time.

## 3. Weapon model

Weapon identity is data-driven and separated into independent axes:

`WeaponDefinition = Damage Family + Engagement Profile + Attack Topology + Targeting Policy + control + evolution + requirements`

Provisional Damage Families: Physical, Electric, Force Field, Fire, Energy.
They are structural names and may later become ACIDBLOOD-specific language.

Engagement Profiles: `EARLY`, `FULL`, `MID/LATE`, `FORTRESS`, `ROAMING`,
`FIELD`.

Attack Topology examples: Direct, Single Target, Splash, Piercing/Line,
Bounce/Chain, Persistent Field, Homing, Periodic Global.

Targeting Policy is explicit per weapon. Universal “most advanced enemy” is
not the design default.

## 4. Initial arsenal

These are provisional functional names and roles:

- **Guardian Rifle** — Physical, movable Guardian weapon, broad emergency
  contribution, with its own targeting policy.
- **Impact Cannon** — Physical, old Cannon reinterpretation/replacement,
  MID/LATE or FORTRESS role, splash/group value, possible knockback/heavy
  impact evolutions.
- **Tesla Coil** — Electric, old Bolt reinterpretation/replacement, local
  MID/LATE/FORTRESS defensive burst, possible bounce, chain, explosion, or
  paralysis/stun evolution.
- **Disruption Field** — Force Field, old Frost reinterpretation/replacement,
  MID/LATE FIELD control through slow/control and possible duration, width,
  damage, exposure/amplification, and field evolutions.

Fire and Energy remain conceptual placeholders. Their final content is not
approved.

## 5. Draft architecture

Approved categories:

- `NEW TURRET` — adds a weapon/turret to the active run.
- `NORMAL` — improves or adjusts existing behavior, potentially with tradeoffs.
- `BREAKTHROUGH` — materially changes behavior or topology.
- `CHAIN` — requires previous choices and deepens a trajectory.
- `COMBO` — requires compatible systems/weapons and connects them.

Normal improves. Breakthrough transforms. Chain deepens. Combo connects.

Retain useful existing strengths where they fit: prerequisites, exclusions,
max stacks, context weighting, dead-choice protection, and deterministic
testability. Drafts may modify targeting or secondary engagement behavior but
must not erase a weapon’s base identity.

## 6. Collection, mastery, and card states

Keep these progression concepts separate:

- Campaign progression unlocks weapons/content availability over time.
- Weapon Mastery unlocks deeper card families/tiers for that weapon.
- Home/Arsenal acquisition obtains specific cards through a benchmark-like
  acquisition system.
- Owned collection is the persistent card inventory.
- Run eligibility is owned card plus prerequisites and context.

Approved persistent states: `LOCKED`, `DISCOVERABLE`, `OWNED`, `RUN-ELIGIBLE`,
`ACTIVE`. Availability is gradual; early campaigns must not expose every card.
Home/Arsenal should eventually support meaningful random acquisition,
rotating opportunities, or packs rather than a wholly deterministic catalog.
Exact currencies, economy, probabilities, pity systems, and monetization are
not approved and must not be invented.

## 7. Duplicates and card level

Duplicates advance the level of the same card. Card Level improves parameters
of the same known behavior and is not the primary unlock for a new mechanic.
New mechanics come from acquiring cards, Breakthroughs, Chains, Combos, and
Mastery/content progression. Fully maximized duplicates may eventually convert
to another resource, but that economy is not designed yet.

## 8. Enemy architecture

`Enemy = Role + Damage Affinity + Modifiers`

EnemyDefinition separates role/behavior, damage affinity, modifiers,
movement/engagement behavior, and elite/boss modifiers. Structural role
vocabulary includes frontline/contact, impact, siege, ranged, support,
protector, spawner, elite, and boss. Modifier vocabulary includes fast,
armored, shielded, regenerating, and enraged.

Use soft counters. A normal enemy may have a main weakness and later a
resistance. Elites have no trivial weakness and combine resistance with
meaningful special behavior. Bosses are not trivialized by one Damage Family;
their answer is the overall build. Exact percentages are not approved.

## 9. Stage intel and stage model

Before entry, Stage Intel should communicate expected enemy types/composition,
relevant weaknesses/resistances, and important ranged/support/elite/boss
threats without revealing exact spawn timing.

`Stage Intel → expectation → build/draft decisions → combat → learning/result`

Stage content is authored composition rather than endless stat scaling.
StageDefinition should conceptually support approximate duration, allowed roster,
roles, affinities, waves/beats, elite/boss content, density/intensity, and
rewards/unlocks.

## 10. Initial onboarding arc

- Stage 1: Guardian Rifle + Impact Cannon; teach kill → XP → draft → defense.
- Stage 2: unlock/teach Tesla Coil.
- Stage 3: consolidate and differentiate Cannon versus Tesla; no required new
  weapon.
- Stage 4: unlock/teach Disruption Field.
- Stage 5: first combined Physical + Electric + Force Field test.

Exact numerical balance is not locked. The principle is `Teach → Test →
Combine`. Fire/Energy campaign timing is not approved.

## 11. Product principles

Preserve: Decision > result; Interaction > quantity; Tradeoff > linear upgrade;
Formation > filling slots; Function > stats; Legibility > spectacle; Mastery >
grind; Reusable systems > exceptions.

ACIDBLOOD should become a real tower defense enriched by roguelite buildcraft,
not roguelite stat upgrades inside a TD shell. Maintain three decision layers:
build/run, battlefield/spatial, and temporal. Do not add quantity before
quality.

## 12. Implementation strategy

This is a clean product reset over the existing engineering foundation. Prefer
replacement over compatibility adapters when legacy abstractions conflict with
this model. Preserve mature infrastructure and fitting deterministic/core
systems; do not rewrite unrelated infrastructure. Old gameplay remains in the
repository until an explicit implementation plan calls for replacement.

No gameplay implementation is authorized by this specification checkpoint.
