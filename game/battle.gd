class_name Battle
extends Node3D
## Generic battle orchestrator. Consumes any StageData; owns the RunState,
## enemy registry, centralized hit resolution, XP/draft flow and win/lose.
## Presentation nodes live under Arena/Actors; rules state lives in RunState.

const ENEMY_SCENE := preload("res://game/enemy.tscn")
const TURRET_SCENE := preload("res://game/turret.tscn")

@onready var main_light: DirectionalLight3D = $MainLight
@onready var camera_rig: Node3D = $CameraRig
@onready var slots_root: Node3D = $Arena/TowerSlots
@onready var enemies_root: Node3D = $Actors/Enemies
@onready var turrets_root: Node3D = $Actors/Turrets
@onready var projectiles_root: Node3D = $Actors/Projectiles
@onready var guardian: Guardian = $Actors/Guardian
@onready var wave_director: WaveDirector = $Runtime/WaveDirector
@onready var hud: BattleHUD = $UI/BattleHUD

var stage: StageData
var run_state: RunState
var enemies: Array[Enemy] = []       # alive Enemy nodes, spawn order preserved
var _slots: Array[Dictionary] = []   # {marker: Marker3D, turret: Turret or null}
var _spawn_counter := 0
var _wave_rng: DetRNG
var _pending_drafts := 0
var _draft_open := false
var _ended := false

func _ready() -> void:
	# Camera/light orientation is authored here (single place, avoids
	# hand-maintained transforms in the scene file).
	main_light.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	camera_rig.rotation_degrees = Vector3(-65.0, 0.0, 0.0)

	if Game.current_stage == null:
		# Direct scene launch from the editor: default to stage 1.
		Game.current_stage = Catalog.stage_by_index(1)
		Game.pending_seed = 12345
	stage = Game.current_stage

	run_state = RunState.new()
	run_state.stage_id = stage.id
	run_state.run_seed = Game.pending_seed
	run_state.fortress_base_max_hp = stage.fortress_hp
	_apply_permanent_bonuses()
	run_state.fortress_hp = run_state.fortress_max_hp()
	_wave_rng = DetRNG.new(DetRNG.derive(run_state.run_seed, "waves"))

	for marker in slots_root.get_children():
		if marker is Marker3D:
			_slots.append({"marker": marker, "turret": null})

	guardian.setup(self, Catalog.guardian())
	hud.setup(self)
	wave_director.configure(self, stage)
	_telemetry("run_start", {
		"stage_index": stage.index,
		"stage_id": String(stage.id),
		"seed": run_state.run_seed,
		"fortress_hp": run_state.fortress_hp,
	})

func _apply_permanent_bonuses() -> void:
	var upgrades := Catalog.perm_upgrades()
	var seen: Dictionary = {}
	for up in upgrades:
		if up.stat == &"" or seen.has(up.stat):
			continue
		seen[up.stat] = true
		var bonus := Game.progression.upgrade_stat_bonus(upgrades, up.stat)
		if bonus != 0.0:
			run_state.mods.add_flat(up.stat, bonus)

## Effective stat lookup — every combat number goes through here.
func stat(path: StringName, base: float) -> float:
	return run_state.mods.value(path, base)

func roll_spawn_x() -> float:
	return _wave_rng.randf_range(-ArenaLayout.SPAWN_X_RANGE, ArenaLayout.SPAWN_X_RANGE)

# --- Spawning -----------------------------------------------------------

func spawn_wave_enemy(enemy_id: StringName, spawn_x: float) -> void:
	var data := Catalog.enemy(enemy_id)
	if data == null:
		push_error("Battle: unknown enemy id %s" % enemy_id)
		return
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemies_root.add_child(enemy)
	enemy.setup(self, data, _spawn_counter, spawn_x, stage.hp_scale, stage.speed_scale)
	_spawn_counter += 1
	enemies.append(enemy)

# --- Combat resolution --------------------------------------------------

## Centralized hit application (guardian and turret projectiles).
## opts: splash_radius, slow_factor, slow_duration.
func apply_hit(target: Enemy, base_damage: float, opts: Dictionary = {}) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		return
	var splash: float = opts.get("splash_radius", 0.0)
	if splash > 0.0:
		var center: Vector3 = target.gameplay_pos()
		for e in enemies.duplicate():
			if is_instance_valid(e) and e.is_alive() \
					and e.gameplay_pos().distance_to(center) <= splash:
				_hit_single(e, base_damage, opts)
	else:
		_hit_single(target, base_damage, opts)

func _hit_single(target: Enemy, base_damage: float, opts: Dictionary) -> void:
	var slow_factor: float = opts.get("slow_factor", 1.0)
	if slow_factor < 1.0:
		target.apply_slow(slow_factor, opts.get("slow_duration", 0.0))
	target.take_damage(Combat.damage_after_armor(base_damage, target.armor()))

func damage_fortress(amount: float) -> void:
	if _ended:
		return
	run_state.fortress_hp = maxf(0.0, run_state.fortress_hp - amount)
	_telemetry("fortress_hit", {
		"amount": amount,
		"fortress_hp": run_state.fortress_hp,
		"wave": run_state.wave_index,
	})
	hud.update_fortress()
	if run_state.fortress_hp <= 0.0:
		_shake_camera(amount)
		_end(false)

func heal_fortress(amount: float) -> void:
	run_state.fortress_hp = minf(run_state.fortress_max_hp(), run_state.fortress_hp + amount)
	hud.update_fortress()

## Called by Enemy on death. killed=false means it reached the fortress.
func notify_enemy_died(enemy: Enemy, killed: bool) -> void:
	enemies.erase(enemy)
	if _ended or not killed:
		return
	run_state.kills += 1
	var level_ups := run_state.grant_xp(enemy.data.xp)
	hud.update_xp()
	if level_ups > 0:
		_queue_drafts(level_ups)

# --- Wave / stage lifecycle --------------------------------------------

func on_wave_started(index: int, total: int) -> void:
	run_state.wave_index = index
	_telemetry("wave_start", {
		"wave": index,
		"total_waves": total,
		"level": run_state.level,
		"kills": run_state.kills,
		"fortress_hp": run_state.fortress_hp,
		"cards": run_state.acquired.keys(),
	})
	hud.update_wave(index, total)

func on_stage_cleared() -> void:
	_end(true)

func _end(victory: bool) -> void:
	if _ended:
		return
	_ended = true
	_telemetry("run_end", {
		"victory": victory,
		"stage_index": stage.index,
		"wave": run_state.wave_index,
		"level": run_state.level,
		"kills": run_state.kills,
		"fortress_hp": run_state.fortress_hp,
		"cards": run_state.acquired,
		"branches": run_state.chosen_branches,
		"turrets": run_state.active_turrets,
	})
	get_tree().paused = false
	Game.end_run(victory, {
		"kills": run_state.kills,
		"wave": run_state.wave_index,
		"level": run_state.level,
		"fortress_hp": run_state.fortress_hp,
		"cards": run_state.acquired.size(),
	})

# --- Card draft ---------------------------------------------------------

func _queue_drafts(count: int) -> void:
	_pending_drafts += count
	if not _draft_open:
		_open_next_draft()

func _open_next_draft() -> void:
	while _pending_drafts > 0:
		_pending_drafts -= 1
		run_state.draft_count += 1
		var rng := DetRNG.new(DetRNG.derive(run_state.run_seed, "draft", run_state.draft_count))
		var offer := Draft.generate_offer(Catalog.cards(), draft_context(), rng, 3)
		if offer.is_empty():
			continue
		var offer_ids: Array[String] = []
		var offer_titles: Array[String] = []
		for card in offer:
			offer_ids.append(String(card.id))
			offer_titles.append(card.title)
		_telemetry("draft_open", {
			"draft_index": run_state.draft_count,
			"level": run_state.level,
			"wave": run_state.wave_index,
			"offer_ids": offer_ids,
			"offer_titles": offer_titles,
		})
		_draft_open = true
		get_tree().paused = true
		hud.show_draft(offer)
		return
	_draft_open = false
	get_tree().paused = false

func draft_context() -> Dictionary:
	var blocked := Draft.runtime_blocked_cards(Catalog.cards(), _available_slot_count())
	return {
		"acquired": run_state.acquired,
		"unlocks": Game.progression.unlock_flags(Catalog.perm_upgrades()),
		"blocked": blocked,
		"fortress_hp": run_state.fortress_hp,
		"fortress_max_hp": run_state.fortress_max_hp(),
		"draft_index": run_state.draft_count + 1,
	}

func on_card_chosen(card: CardData) -> void:
	run_state.acquire_card(card.id)
	_telemetry("card_chosen", {
		"draft_index": run_state.draft_count,
		"card_id": String(card.id),
		"card_title": card.title,
		"wave": run_state.wave_index,
		"level": run_state.level,
		"acquired_count": int(run_state.acquired.get(card.id, 0)),
	})
	apply_card(card)
	hud.hide_draft()
	hud.update_fortress()
	_open_next_draft()

func apply_card(card: CardData) -> void:
	for eff in card.effects:
		match eff.op:
			CardEffect.Op.ADD_STAT:
				run_state.mods.add_flat(eff.stat, eff.value)
			CardEffect.Op.MULTIPLY_STAT:
				run_state.mods.multiply(eff.stat, eff.value)
			CardEffect.Op.UNLOCK_TURRET:
				_build_turret(eff.target)
			CardEffect.Op.HEAL_FORTRESS:
				heal_fortress(eff.value)
			CardEffect.Op.APPLY_BRANCH:
				_apply_branch(eff.target)

func _apply_branch(branch_id: StringName) -> void:
	var branch = Catalog.turret_branch(branch_id)
	if branch == null:
		push_warning("Battle: cannot apply unknown branch %s" % branch_id)
		return
	var current := run_state.branch_for(branch.turret_id)
	if current != &"":
		if current != branch.id:
			push_warning("Battle: turret %s already has branch %s" % [branch.turret_id, current])
		return
	for blocked in branch.excludes_branches:
		if run_state.branch_for(branch.turret_id) == blocked:
			push_warning("Battle: branch %s blocked by %s" % [branch.id, blocked])
			return
	run_state.set_branch(branch.turret_id, branch.id)
	for eff in branch.effects:
		match eff.op:
			CardEffect.Op.ADD_STAT:
				run_state.mods.add_flat(eff.stat, eff.value)
			CardEffect.Op.MULTIPLY_STAT:
				run_state.mods.multiply(eff.stat, eff.value)
			_:
				push_warning("Battle: unsupported branch effect op %s on %s" % [eff.op, branch.id])
	
	for slot in _slots:
		if slot.turret != null:
			slot.turret.refresh_branch_visual()

func _free_slot() -> Dictionary:
	for slot in _slots:
		if slot.turret == null:
			return slot
	return {}

func _available_slot_count() -> int:
	var count := 0
	for slot in _slots:
		if slot.turret == null:
			count += 1
	return count

func _build_turret(turret_id: StringName) -> void:
	var data := Catalog.turret(turret_id)
	var slot := _free_slot()
	if data == null or slot.is_empty():
		push_warning("Battle: cannot build turret %s" % turret_id)
		return
	var turret: Turret = TURRET_SCENE.instantiate()
	turrets_root.add_child(turret)
	turret.global_position = (slot.marker as Marker3D).global_position
	turret.setup(self, data)
	slot.turret = turret
	run_state.active_turrets.append(turret_id)

func _shake_camera(amount: float) -> void:
	var magnitude = minf(0.5, amount / 10.0)
	var tween = create_tween()
	tween.tween_property(camera_rig, "translation", camera_rig.translation + Vector3(magnitude, 0, 0), 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera_rig, "translation", camera_rig.translation + Vector3(-magnitude, 0, 0), 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera_rig, "translation", camera_rig.translation, 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)

func _telemetry(event_name: String, payload: Dictionary = {}) -> void:
	var out := payload.duplicate(true)
	out["event"] = event_name
	out["stage"] = stage.index if stage != null else -1
	print("RUN_TLM %s" % JSON.stringify(out))

func debug_snapshot() -> Dictionary:
	var enemy_rows := []
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		enemy_rows.append({
			"id": String(enemy.data.id),
			"x": snappedf(enemy.position.x, 0.01),
			"z": snappedf(enemy.position.z, 0.01),
			"hp": snappedf(enemy.hp, 0.01),
		})
	return {
		"ended": _ended,
		"wave": run_state.wave_index if run_state != null else -1,
		"level": run_state.level if run_state != null else -1,
		"fortress_hp": snappedf(run_state.fortress_hp, 0.01) if run_state != null else -1.0,
		"enemies_alive": enemy_rows,
		"enemy_count": enemy_rows.size(),
		"projectile_count": projectiles_root.get_child_count(),
		"turret_count": turrets_root.get_child_count(),
		"tree_paused": get_tree().paused,
	}
