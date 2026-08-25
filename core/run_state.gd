class_name RunState
extends RefCounted
## All rule-relevant state for one battle run. Owned by the battle runtime but
## deliberately free of Node references so it can be driven by a simulator.
## Guardian rules state is fully derived: GuardianData/WeaponData bases +
## `mods` (guardian.* stat paths). Its position is presentation-only and
## lives on the Guardian node.

var stage_id: StringName
var run_seed: int = 0
var level: int = 1
var xp: int = 0
var total_xp_earned: int = 0
var kills: int = 0
var wave_index: int = 0            # 1-based; 0 = not started
var fortress_hp: float = 0.0
var fortress_base_max_hp: float = 100.0
var acquired: Dictionary = {}      # card id (StringName) -> count
var active_turrets: Array[StringName] = []  # turret id per occupied slot, in slot order
const DEFENSIVE_SLOT_COUNT := 4
var turret_slots: Array[StringName] = [&"", &"", &"", &""]
var guardian_active: bool = true
var max_draft_choices: int = 20
var run_xp_thresholds: Array[int] = []
var _awarded_kills: Dictionary = {}
var chosen_branches: Dictionary = {}  # turret id (StringName) -> branch id (StringName)
var mods := ModifierSet.new()
var draft_count: int = 0           # increments per draft, salts the draft RNG stream

func available_slot_count() -> int:
	var available := 0
	for turret_id in turret_slots:
		if turret_id == &"":
			available += 1
	return available

func install_turret(turret_id: StringName, slot_index: int) -> bool:
	if turret_id == &"" or slot_index < 0 or slot_index >= turret_slots.size():
		return false
	if turret_slots[slot_index] != &"" or turret_id in turret_slots:
		return false
	turret_slots[slot_index] = turret_id
	active_turrets.clear()
	for installed_id in turret_slots:
		if installed_id != &"":
			active_turrets.append(installed_id)
	return true

func grant_kill_xp(kill_id: StringName, amount: int) -> int:
	return int(award_kill(kill_id, amount).get("level_ups", 0))

func award_kill(kill_id: StringName, amount: int) -> Dictionary:
	if kill_id == &"" or _awarded_kills.has(kill_id):
		return {"accepted": false, "xp": 0, "level_ups": 0}
	_awarded_kills[kill_id] = true
	kills += 1
	var level_ups := grant_xp(amount)
	return {"accepted": true, "xp": maxi(0, amount), "level_ups": level_ups}

func consume_draft_choice() -> bool:
	if draft_count >= max_draft_choices:
		return false
	draft_count += 1
	return true

func fortress_max_hp() -> float:
	return mods.value(&"fortress.max_hp", fortress_base_max_hp)

func acquire_card(id: StringName) -> void:
	acquired[id] = int(acquired.get(id, 0)) + 1

func set_branch(turret_id: StringName, branch_id: StringName) -> void:
	chosen_branches[turret_id] = branch_id

func branch_for(turret_id: StringName) -> StringName:
	return chosen_branches.get(turret_id, &"")

func grant_xp(amount: int) -> int:
	## Returns the number of level-ups triggered.
	var awarded := maxi(0, amount)
	total_xp_earned += awarded
	xp += awarded
	var ups := 0
	while xp >= Leveling.xp_required(level, run_xp_thresholds):
		xp -= Leveling.xp_required(level, run_xp_thresholds)
		level += 1
		ups += 1
	return ups

func to_dict() -> Dictionary:
	return {
		"level": level,
		"xp": xp,
		"total_xp_earned": total_xp_earned,
		"kills": kills,
		"draft_count": draft_count,
	}
