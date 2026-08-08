class_name RunState
extends RefCounted
## All rule-relevant state for one battle run. Owned by the battle runtime but
## deliberately free of Node references so it can be driven by a simulator.

var stage_id: StringName
var run_seed: int = 0
var level: int = 1
var xp: int = 0
var kills: int = 0
var wave_index: int = 0            # 1-based; 0 = not started
var fortress_hp: float = 0.0
var fortress_base_max_hp: float = 100.0
var acquired: Dictionary = {}      # card id (StringName) -> count
var active_turrets: Array[StringName] = []  # turret id per occupied slot, in slot order
var mods := ModifierSet.new()
var draft_count: int = 0           # increments per draft, salts the draft RNG stream

func fortress_max_hp() -> float:
	return mods.value(&"fortress.max_hp", fortress_base_max_hp)

func acquire_card(id: StringName) -> void:
	acquired[id] = int(acquired.get(id, 0)) + 1

func grant_xp(amount: int) -> int:
	## Returns the number of level-ups triggered.
	xp += amount
	var ups := 0
	while xp >= Leveling.xp_required(level):
		xp -= Leveling.xp_required(level)
		level += 1
		ups += 1
	return ups
