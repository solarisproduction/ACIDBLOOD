class_name Leveling
extends RefCounted
## XP curve. Level starts at 1.

static func xp_required(level: int) -> int:
	return 10 + 6 * (level - 1)
