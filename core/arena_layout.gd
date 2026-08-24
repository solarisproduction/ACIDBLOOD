class_name ArenaLayout
extends RefCounted
## Shared gameplay-plane geometry. Gameplay is 2D on the X/Z plane (Y up):
## enemies spawn at SPAWN_Z (top of screen) and advance toward +Z where the
## barricade sits. All values are world units (1 unit = 1 meter).

const HALF_WIDTH := 4.5
const SPAWN_Z := -16.0
const FORTRESS_LINE_Z := 6.8      # enemies contact the barricade here
const FORTRESS_CENTER := Vector3(0.0, 0.6, 7.6)
const GUARDIAN_Z := 8.7
const GUARDIAN_X_LIMIT := 3.4
const SPAWN_X_RANGE := 2.8        # spawn x is rolled in [-range, +range]

const SLOT_PICK_ORDER: Array[int] = [2, 3, 0, 1]
const SLOT_DISPLAY_NAMES: Array[String] = [
	"Back Left",
	"Back Right",
	"Front Left",
	"Front Right",
]

static func slot_display_name(index: int) -> String:
	if index >= 0 and index < SLOT_DISPLAY_NAMES.size():
		return SLOT_DISPLAY_NAMES[index]
	return "Slot %d" % (index + 1)

static func slot_pick_order() -> Array[int]:
	return SLOT_PICK_ORDER.duplicate()
