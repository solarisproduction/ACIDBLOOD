class_name Combat
extends RefCounted
## Centralized damage math so it can be tested and simulated headlessly.

const MIN_DAMAGE := 1.0
const MIN_ATTACK_INTERVAL := 0.05

static func damage_after_armor(amount: float, armor: float) -> float:
	return maxf(MIN_DAMAGE, amount - armor)
