class_name StatRegistry
extends RefCounted

const GUARDIAN_STATS: Array[StringName] = [
	&"guardian.move_speed",
	&"guardian.damage",
	&"guardian.attack_interval",
	&"guardian.range",
	&"guardian.projectiles",
	&"guardian.pierce",
]

const FORTRESS_STATS: Array[StringName] = [
	&"fortress.max_hp",
]

const TURRET_LOCAL_STATS: Array[StringName] = [
	&"damage",
	&"attack_interval",
	&"range",
	&"projectile_speed",
	&"splash_radius",
	&"slow_factor",
	&"slow_duration",
]

static func is_valid(path: StringName) -> bool:
	if path in GUARDIAN_STATS or path in FORTRESS_STATS:
		return true

	var text := String(path)

	if not text.begins_with("turret."):
		return false

	var parts := text.split(".")

	if parts.size() != 3:
		return false

	var turret_id := StringName(parts[1])
	var local_stat := StringName(parts[2])

	if Catalog.turret(turret_id) == null:
		return false

	return local_stat in TURRET_LOCAL_STATS
