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

# --- Spawning -----------------------------------------------------------

func spawn_wave_enemy(enemy_id: StringName) -> void:
	var data := Catalog.enemy(enemy_id)
	if data == null:
		push_error("Battle: unknown enemy id %s" % enemy_id)
		return
	var x := _wave_rng.randf_range(-ArenaLayout.SPAWN_X_RANGE, ArenaLayout.SPAWN_X_RANGE)
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemies_root.add_child(enemy)
	enemy.setup(self, data, _spawn_counter, x, stage.hp_scale, stage.speed_scale)
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
	hud.update_fortress()
	if run_state.fortress_hp <= 0.0:
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
	hud.update_wave(index, total)

func on_stage_cleared() -> void:
	_end(true)

func _end(victory: bool) -> void:
	if _ended:
		return
	_ended = true
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
		_draft_open = true
		get_tree().paused = true
		hud.show_draft(offer)
		return
	_draft_open = false
	get_tree().paused = false

func draft_context() -> Dictionary:
	var blocked: Array[StringName] = []
	if _free_slot().is_empty():
		for card in Catalog.cards():
			for eff in card.effects:
				if eff.op == CardEffect.Op.UNLOCK_TURRET:
					blocked.append(card.id)
					break
	return {
		"acquired": run_state.acquired,
		"unlocks": Game.progression.unlock_flags(Catalog.perm_upgrades()),
		"blocked": blocked,
	}

func on_card_chosen(card: CardData) -> void:
	run_state.acquire_card(card.id)
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

func _free_slot() -> Dictionary:
	for slot in _slots:
		if slot.turret == null:
			return slot
	return {}

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
