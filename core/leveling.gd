class_name Leveling
extends RefCounted
## XP curve. Level starts at 1.

static func xp_required(level: int, thresholds: Array[int] = []) -> int:
	if not thresholds.is_empty():
		return thresholds[clampi(level - 1, 0, thresholds.size() - 1)]
	return 10 + 6 * (level - 1)
