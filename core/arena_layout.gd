class_name ArenaLayout
extends RefCounted
## Shared gameplay-plane geometry. Gameplay is 2D on the X/Z plane (Y up):
## enemies spawn at SPAWN_Z (top of screen) and advance toward +Z where the
## fortress sits. All values are world units (1 unit = 1 meter).

const HALF_WIDTH := 4.5
const SPAWN_Z := -9.0
const FORTRESS_LINE_Z := 6.8      # enemies contact the fortress here
const FORTRESS_CENTER := Vector3(0.0, 0.6, 7.6)
const GUARDIAN_Z := 5.2
const GUARDIAN_X_LIMIT := 3.4
const SPAWN_X_RANGE := 2.8        # spawn x is rolled in [-range, +range]
