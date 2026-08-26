class_name Targeting
extends RefCounted
## Deterministic target selection. Candidates must expose:
##   gameplay_pos() -> Vector3   (y is ignored)
##   spawn_index    -> int       (unique, monotonically increasing per spawn)
##   is_alive()     -> bool
## Rule: among alive candidates within range of origin, pick the one most
## advanced toward the fortress (largest z); ties break on lowest spawn_index.

static func pick_target(candidates: Array, origin: Vector3, max_range: float, policy: StringName = &"most_advanced") -> Object:
	# The current game has one proven policy. Passing it explicitly keeps the
	# choice on the weapon boundary without inventing unsupported tactics.
	if policy != &"most_advanced":
		return null
	var best: Object = null
	var best_z := -INF
	var best_index := 0x7FFFFFFF
	var range_sq := max_range * max_range
	for c in candidates:
		if not c.is_alive():
			continue
		var p: Vector3 = c.gameplay_pos()
		var dx := p.x - origin.x
		var dz := p.z - origin.z
		if dx * dx + dz * dz > range_sq:
			continue
		if p.z > best_z or (p.z == best_z and c.spawn_index < best_index):
			best = c
			best_z = p.z
			best_index = c.spawn_index
	return best
