class_name DetRNG
extends RefCounted
## Deterministic RNG stream. All gameplay randomness must flow through an
## instance of this class seeded explicitly from the run seed.

var _rng := RandomNumberGenerator.new()

func _init(seed_value: int) -> void:
	_rng.seed = seed_value

## Derives a child seed from a base seed plus a purpose salt, so independent
## systems (draft, waves) consume independent streams.
static func derive(base_seed: int, salt: String, index: int = 0) -> int:
	return hash("%d:%s:%d" % [base_seed, salt, index])

func randf() -> float:
	return _rng.randf()

func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)

func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)

## Picks an index from an array of non-negative weights. Returns -1 if all
## weights are zero or the array is empty.
func weighted_index(weights: Array[float]) -> int:
	var total := 0.0
	for w in weights:
		total += maxf(w, 0.0)
	if total <= 0.0:
		return -1
	var roll := _rng.randf() * total
	for i in weights.size():
		roll -= maxf(weights[i], 0.0)
		if roll < 0.0:
			return i
	return weights.size() - 1
