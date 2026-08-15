class_name Progression
extends RefCounted
## Permanent, locally persisted progression: currency, permanent upgrade
## levels, and campaign completion. JSON save with a version field.

const SAVE_VERSION := 1
const DEFAULT_PATH := "user://bastion_vale_save.json"
const REPEAT_REWARD_FACTOR := 0.3

var cores: int = 0
var completed_stages: Array[String] = []
var upgrade_levels: Dictionary = {}  # upgrade id (String) -> int level
## Where save() writes by default; smoke tests point this at a scratch file.
var save_path: String = DEFAULT_PATH

func is_stage_completed(stage_id: StringName) -> bool:
	return String(stage_id) in completed_stages

## Stage 1 is always unlocked; stage N unlocks when stage N-1 is completed.
## `ordered_stage_ids` is the campaign order.
func is_stage_unlocked(index: int, ordered_stage_ids: Array) -> bool:
	if index <= 0:
		return true
	return String(ordered_stage_ids[index - 1]) in completed_stages

## Applies a victory. Returns the cores actually awarded (first clear pays
## full reward, repeat clears pay a fraction).
func apply_victory(stage_id: StringName, reward_cores: int) -> int:
	var award := reward_cores
	if is_stage_completed(stage_id):
		award = int(ceil(reward_cores * REPEAT_REWARD_FACTOR))
	else:
		completed_stages.append(String(stage_id))
	cores += award
	return award

func upgrade_level(id: StringName) -> int:
	return int(upgrade_levels.get(String(id), 0))

func upgrade_cost(up: PermUpgradeData) -> int:
	return up.base_cost + up.cost_step * upgrade_level(up.id)

func owns_upgrade(id: StringName) -> bool:
	return upgrade_level(id) > 0

func meets_requirements(up: PermUpgradeData) -> bool:
	for req in up.requires_nodes:
		if not owns_upgrade(req):
			return false
	return true

func can_buy_upgrade(up: PermUpgradeData) -> bool:
	return upgrade_level(up.id) < up.max_level \
		and cores >= upgrade_cost(up) \
		and meets_requirements(up)

func buy_upgrade(up: PermUpgradeData) -> bool:
	if not can_buy_upgrade(up):
		return false
	cores -= upgrade_cost(up)
	upgrade_levels[String(up.id)] = upgrade_level(up.id) + 1
	return true

## Permanent unlock flags derived from upgrades (consumed by card eligibility).
func unlock_flags(upgrades: Array[PermUpgradeData]) -> Dictionary:
	var flags: Dictionary = {}
	for up in upgrades:
		if up.unlock_flag != &"" and upgrade_level(up.id) > 0:
			flags[up.unlock_flag] = true
	return flags

## Total flat bonus this upgrade family contributes to its stat.
func upgrade_stat_bonus(upgrades: Array[PermUpgradeData], stat: StringName) -> float:
	var total := 0.0
	for up in upgrades:
		if up.stat == stat:
			total += up.value_per_level * upgrade_level(up.id)
	return total

func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"cores": cores,
		"completed_stages": completed_stages,
		"upgrade_levels": upgrade_levels,
	}

func save(path: String = "") -> bool:
	if path.is_empty():
		path = save_path
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Progression: cannot open %s for writing" % path)
		return false
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	return true

static func load_or_new(path: String = DEFAULT_PATH) -> Progression:
	var p := Progression.new()
	p.save_path = path
	if not FileAccess.file_exists(path):
		return p
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return p
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Progression: save file unreadable, starting fresh")
		return p
	var d: Dictionary = parsed
	p.cores = int(d.get("cores", 0))
	for s in d.get("completed_stages", []):
		p.completed_stages.append(String(s))
	var ups: Dictionary = d.get("upgrade_levels", {})
	for k in ups:
		p.upgrade_levels[String(k)] = int(ups[k])
	return p
