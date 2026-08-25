# ACIDBLOOD Direction

This is the product identity source of truth. It should guide naming,
environment choices, enemy silhouettes, VFX language, UI mood, and future art
production. Gameplay systems still live in `core/`, `data/`, `game/`, and
`shell`; this document defines what those systems should gradually look and
feel like.

## Genre Contract

ACIDBLOOD is a tower defense game with roguelite draft/buildcraft. It is not an
exploration game, action adventure, survival horror, or room-based roguelite.
The journey is expressed through stages, waves, enemy ecology, arena
presentation, tower behavior, card choices, and campaign progression.

Theme must support the TD loop:

- the player defends a fixed objective in each battle
- enemy pressure comes through readable waves, roles, timings, and formations
- towers and the Guardian are the main tools for solving that pressure
- cards change build direction, not the genre
- environments give context to battles, not free exploration

When this document says "moving deeper" or "journey", read it as campaign
progression through increasingly contaminated sectors of one city.

## Core Premise

ACIDBLOOD takes place in an alternate late-1980s industrial future after a
biological, chemical, and technological catastrophe. The city did not explode;
it rotted while still standing.

The campaign moves through one coherent contaminated metropolis, not a
sequence of arbitrary videogame biomes. Industrial districts, laboratories,
sewers, hospitals, transport systems, residential blocks, and corporate
facilities should feel physically connected. Every stage should reveal another
layer of what happened through its arena, enemies, wave composition, objective,
and background details.

The central question is not "what monster lives here?" It is "what happened
here?"

## Design Principles

- ACIDBLOOD is a real tower-defense game enriched by roguelite draft/buildcraft.
- Player mastery comes from decisions, not passive stat inflation.
- Space, enemy composition, timing, targeting, and build choice must interact.
- Cards should preferably change behavior, tradeoffs, positioning, timing, or
  synergy rather than only increase output.
- Enemy roles should create tactical questions and combinations.
- Future tower, status, and damage families are not pre-approved content.
  They should be introduced only when they create a readable strategic
  relationship and fit ACIDBLOOD's physical and thematic language.
- Avoid arbitrary elemental taxonomies or hard-counter matrices merely because
  they are common videogame patterns.
- New gameplay concepts, names, and product-facing vocabulary require explicit
  product/design approval before implementation.
- Prefer proven tower-defense and game-development patterns over speculative
  abstraction.

## World Rules

- The world is industrial, analog, chemical, and physical.
- Technology belongs to the late 1980s imagined from inside that decade:
  CRTs, magnetic tape, cable phones, switch panels, warning labels, primitive
  robotics, fluorescent tubes, bulky servers, and mechanical security systems.
- Avoid clean modern cyberpunk. Neon exists only as functional contrast:
  emergency signs, pharmacy signs, old vending machines, warning beacons,
  abandoned nightlife, or active machinery.
- The city remains operational in fragments: machines hum, emergency circuits
  run, labs stay lit, pipes still carry unknown fluids.
- Story should be discovered through battle context and consequences in the
  environment, not through explanation first.

## Contamination

The contamination is biological, chemical, and technological at the same time.
It has no single clean form. It can read as rust, fungus, tissue, crystallized
chemical deposits, polluted water, cable-like growth, or organic matter growing
through machines.

The key visual question is:

Was this infected, or was it designed this way?

Use this rule when designing enemies, arenas, props, VFX, and future assets.
The more advanced the campaign becomes, the more the boundary between
catastrophe and intention should blur.

In tower-defense terms, contamination should become readable gameplay language:

- acid pools, runoff, or pressure leaks can explain damage-over-time and area
  denial
- electrical infection can explain chain damage, fields, stuns, and overloads
- hardened chemical crust or protective gear can explain armor
- unstable tissue, exposed organs, or cracked containment can explain
  vulnerability windows
- growth blocking machinery or corridors can explain lane pressure and
  encounter constraints

## Enemy Direction

Enemies are consequences of the environment, not fantasy monsters. They should
retain fragments of recognizable biology, equipment, clothing, job identity, or
animal ancestry.

- Grunt direction: former humans or small contaminated bodies, still readable
  as industrial victims.
- Runner direction: contaminated animal or worker bodies adapted for speed in
  tunnels and service corridors.
- Brute direction: large industrial exposure, swollen mass, protective gear,
  or chemical overgrowth.
- Spitter direction: pressure, tubing, bile, chemical spray, or respiratory
  mutation.
- Boss direction: a major local event, not just a bigger body. It should feel
  tied to a facility, experiment, or contamination source.

Disturbance should come from plausibility and descent from familiar things, not
from decorative extravagance.

Enemy design must stay role-first. A creature's theme should make its gameplay
job easier to read:

- fast enemies need clear runner silhouettes
- armored enemies need clear protection, mass, or hardened contamination
- ranged enemies need visible pressure sacs, tubing, nozzles, or posture
- bosses need explicit telegraphing and a rule that tests the current sector
- variants should teach wave composition, not only add visual variety

## First World

The first playable region should be an abandoned processing district:
factories, warehouses, loading yards, maintenance tunnels, chemical reservoirs,
security gates, and underground technical infrastructure.

It should still be recognizable. The contamination begins as peripheral
evidence: growth behind pipes, wrong anatomy in a carcass, sealed lab doors
inside ordinary industry, fluid that appears to move. Later regions can let
those anomalies become architecture.

This means the current prototype arena should evolve first toward:

- industrial service road instead of fantasy road
- processing-yard or loading-lane tower pads instead of medieval pads
- fortress concept replaced by a gate, barricade, containment wall, vehicle, or
  sealed access point
- towers treated as analog defense machines, chemical sprayers, field coils,
  pressure cannons, or improvised industrial devices

The first world should teach the TD grammar clearly before becoming strange:

- straight lanes can be service roads, conveyor corridors, drain channels, or
  loading paths
- tower slots can be anchor plates, maintenance mounts, power sockets, or
  security hardpoints
- wave starts can be gates, tunnel mouths, collapsed street openings, sewer
  grates, loading doors, or lab exits
- the defended objective can be a containment gate, barricade, control room,
  sealed access, or industrial vehicle
- early contamination should mostly support readability, not hide combat

## Visual Language

The base material vocabulary is limited:

- concrete
- painted steel
- oxidized metal
- dirty glass
- rubber
- plastic
- ceramic tile
- fluorescent tubes
- industrial liquid
- biological tissue
- accumulated dirt

Architecture carries the image. Large masses, circulation, and functional
objects come before props and detail. Avoid making the world a collage of
cyberpunk assets.

The current gameplay structural north star is the approved Galaxy Defense
foundation in [`GALAXY_FOUNDATION_SPEC.md`](GALAXY_FOUNDATION_SPEC.md). That
benchmark guides structure only; ACIDBLOOD's industrial contamination identity
remains the visual and product expression.

## Color

The base palette is restrained:

- charcoal
- cold concrete
- oxidized steel
- dirty beige
- petroleum green
- hospital green
- brown-black rust
- desaturated blue

Controlled accent colors should have function:

- emergency red: danger, alarm, boss/threat
- industrial amber: machinery, warning, interactable systems
- chemical green: acid, contamination, toxic pools
- electric cyan: power, electricity, active tech
- occasional magenta: rare synthetic or corporate residue
- old fluorescent white: labs, hospitals, harsh utility light

Do not let the game become uniformly neon. Color should mean something.

## Light

Darkness is architectural. Some spaces are lit by failed industrial systems,
some by emergency circuits, some by daylight through collapse, some by
contaminated liquid, and some barely at all.

Combat readability still wins over mood. In gameplay, silhouette and hit
feedback must remain legible from the current camera.

## Tower And Weapon Translation

Tower identity should be grounded in industrial equipment rather than fantasy
elements:

- Bolt: electrical coils, capacitors, cables, CRT interference, field arcs,
  overloaded panels, chain conduction.
- Cannon: pressure machinery, pneumatic impact, industrial shells, ruptures,
  concussive bursts, containment cracking.
- Frost: coolant leaks, cryogenic spray, brittle chemical crystallization,
  slowing fields, exposed surfaces.
- Guardian weapon: compact improvised firearm or security-system weapon, with
  clear black/white ballistic readability in the prototype.

Branch names and VFX should describe the physical behavior first. Good tower
branches feel like different industrial failure modes or machine settings, not
abstract RPG upgrades.

## Campaign Translation

The campaign should read as a descent through city infrastructure while staying
stage-based:

- Act 1: recognizable industry, processing yards, gates, maintenance roads,
  early runoff and small mutations.
- Act 2: deeper infrastructure, pump stations, sewers, hospitals, transit
  connections, stronger ecological specialization.
- Act 3: laboratories, containment systems, experimentation, machine/organism
  boundary collapse.
- Late game: technology and biology become hard to separate, but encounters
  remain readable TD tests.

Do not add exploration mechanics to express this journey. Use stage names,
briefings, arena dressing, enemy sets, boss rules, and wave pacing.

## Prototype Translation

Until real assets exist, prototype changes should still move in this direction:

- Remove visible legacy fantasy language.
- Shift placeholder colors toward concrete, steel, rust, petroleum green,
  chemical green, emergency red, amber, and fluorescent white.
- Make VFX functional: acid, pressure, electricity, chemical rupture, impact,
  exposure, containment failure.
- Use simple industrial forms first: slabs, pipes, tanks, vents, grates,
  control boxes, hazard stripes, cable bundles, reservoir shapes.
- Keep backend mechanics simple and data-driven; let presentation carry theme.
- Preserve the current tower-defense controls and loop. Theme work should not
  introduce movement goals, loot rooms, exploration nodes, or unrelated
  progression systems.

## Naming Rules

Prefer names that imply industrial infrastructure, contamination, and analog
systems.

Good directions:

- Processing Yard
- Service Gate
- Drain Channel
- Pump Station
- Containment Line
- Pressure Deck
- Reservoir Access
- Control Annex
- Chemical Runoff
- Lab Intake

Avoid future names that feel medieval, fantasy, clean sci-fi, or generic
neon-cyberpunk unless they are intentionally being replaced.
