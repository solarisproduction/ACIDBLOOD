# Asset Contract - future low-poly GLB production

Rules for Blender → GLB/glTF assets so they drop into the game without code
changes.

Assets must follow the product direction in `docs/ACIDBLOOD_DIRECTION.md`.
The target is late-1980s industrial contamination: analog machinery, chemical
infrastructure, concrete, oxidized metal, dirty glass, rubber, fluorescent
fixtures, biological growth, and functional warning colors. Avoid medieval
fantasy, clean modern sci-fi, and all-over neon cyberpunk.

## Global conventions
- 1 Godot unit = 1 meter. Apply all transforms before export; scale must be
  (1, 1, 1).
- +Y = up, **-Z = model forward** (direction of aim/travel).
- GLB (binary glTF) is the exchange format. One asset per file.
- Low-poly, flat-shaded look; vertex colors or a single small palette texture.
- Use restrained base materials first, then controlled accents: emergency red,
  industrial amber, chemical green, electric cyan, and old fluorescent white.

## Origins
- Guardian: at feet/base center.
- Enemies: at feet/base center.
- Turrets: centered on the base footprint (sits on a slot pad at y=0).
- Props/decorations: at logical ground contact point.

## Size references (placeholder primitives currently in use)
- Guardian ≈ 0.7 w × 1.3 h
- Grunt ≈ 0.7³ box, Brute ≈ 1.1–1.2, Boss ≈ 1.8–2.0
- Turret ≈ 1.1 footprint, ≈ 1.4 tall; slot pads are 1.3–1.5 across
- Defended objective placeholder spans roughly 10.2 × 2.2 h × 1.2 d at the
  bottom arena
  edge. Future art should read as a gate, barricade, containment wall, sealed
  access point, or industrial anchor rather than a medieval fortress.

## Replacement path (no gameplay-code changes)
Each data resource (`EnemyData`, `TurretData`, `GuardianData`) has a
`model_scene: PackedScene` export:
1. Import the GLB, save an inherited scene wrapping it (orientation fix-ups,
   material assignment stay inside this wrapper).
2. Assign that scene to `model_scene` on the `.tres`.
3. Runtime instances it under the actor's model root instead of generating
   primitives. HP bars, aiming (turret wrappers should expose their rotating
   head as the wrapper root or first child named appropriately) and gameplay
   are untouched.

Turret note: placeholder turrets rotate a generated head node. When a GLB
turret lands, either keep the whole wrapper static or extend `turret.gd` to
look up a `Head` node inside the wrapper — one small, isolated change.
