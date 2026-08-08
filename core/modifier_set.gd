class_name ModifierSet
extends RefCounted
## Flat additive + multiplicative modifiers keyed by stat path
## (e.g. "guardian.damage", "turret.bolt.damage", "fortress.max_hp").
## Effective value = (base + add) * mult.

var _mods: Dictionary = {}

func add_flat(stat: StringName, amount: float) -> void:
	var m: Dictionary = _mods.get_or_add(stat, {"add": 0.0, "mult": 1.0})
	m.add += amount

func multiply(stat: StringName, factor: float) -> void:
	var m: Dictionary = _mods.get_or_add(stat, {"add": 0.0, "mult": 1.0})
	m.mult *= factor

func value(stat: StringName, base: float) -> float:
	var m: Dictionary = _mods.get(stat, {"add": 0.0, "mult": 1.0})
	return (base + m.add) * m.mult
