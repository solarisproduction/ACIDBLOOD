class_name Combat
extends RefCounted
## Centralized damage math so it can be tested and simulated headlessly.

const MIN_DAMAGE := 1.0
const MIN_ATTACK_INTERVAL := 0.05

static func damage_after_armor(amount: float, armor: float, affinity_multiplier: float = 1.0) -> float:
	var family_adjusted_damage := amount * maxf(0.01, affinity_multiplier)
	return maxf(MIN_DAMAGE, family_adjusted_damage - armor)
