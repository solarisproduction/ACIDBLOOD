class_name Battle
extends Node3D
## Generic battle orchestrator. Consumes any StageData; owns the RunState,
## enemy registry, centralized hit resolution, XP/draft flow and win/lose.
## Presentation nodes live under Arena/Actors; rules state lives in RunState.

const ENEMY_SCENE := preload("res://game/enemy.tscn")
const TURRET_SCENE := preload("res://game/turret.tscn")

@onready var main_light := $MainLight as DirectionalLight3D
@onready var camera_rig := $CameraRig as Node3D
@onready var slots_root := $Arena/TowerSlots as Node3D
@onready var enemies_root := $Actors/Enemies as Node3D
@onready var turrets_root := $Actors/Turrets as Node3D
@onready var projectiles_root := $Actors/Projectiles as Node3D
@onready var effects_root := $Effects as Node3D
@onready var fortress_root := $Arena/Fortress as Node3D
@onready var guardian := $Actors/Guardian as Guardian
@onready var wave_director = $Runtime/WaveDirector
@onready var hud := $UI/BattleHUD as BattleHUD

var stage: StageData
var run_state: RunState
var enemies: Array[Enemy] = []       # alive Enemy nodes, spawn order preserved
var _slots: Array[Dictionary] = []   # {marker: Marker3D, turret: Turret or null}
var _spawn_counter := 0
var _wave_rng: DetRNG
var _pending_drafts := 0
var _draft_open := false
var _active_offer: Array[CardData] = []
var _pending_build_turret_id: StringName = &""
var _placement_open := false
var _placement_turret_id: StringName = &""
var _placement_slot_index := -1
var _placement_ghost: Turret
var _ended := false
var _field_effects: Array[Dictionary] = []
var _next_barricade_alert_msec := 0
var _last_barricade_hit_msec := -10000
var _draft_hold_banner_msec := 0
var _peak_enemy_count := 0

func _ready() -> void:
	# Camera/light orientation is authored here (single place, avoids
	# hand-maintained transforms in the scene file).
	main_light.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	camera_rig.rotation_degrees = Vector3(-43.0, 0.0, 0.0)

	if Game.current_stage == null:
		# Direct scene launch from the editor: default to stage 1.
		Game.current_stage = Catalog.stage_by_index(1)
		Game.pending_seed = 12345
	stage = Game.current_stage

	run_state = RunState.new()
	run_state.stage_id = stage.id
	run_state.run_seed = Game.pending_seed
	## Gate HP comes only from the stage base plus permanent upgrades.
	run_state.fortress_base_max_hp = stage.fortress_hp
	_apply_permanent_bonuses()
	run_state.fortress_hp = run_state.fortress_max_hp()
	_wave_rng = DetRNG.new(DetRNG.derive(run_state.run_seed, "waves"))

	for marker in slots_root.get_children():
		if marker is Marker3D:
			_slots.append({"marker": marker, "turret": null})

	guardian.setup(self, Catalog.guardian())
	hud.setup(self)
	hud.set_level_up_ready(false, 0)
	wave_director.configure(self, stage)
	hud.show_stage_intro(stage)
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

func roll_spawn_x(lane: StringName = &"random") -> float:
	if lane == &"left":
		return _wave_rng.randf_range(-ArenaLayout.SPAWN_X_RANGE, -0.9)
	if lane == &"center":
		return _wave_rng.randf_range(-0.9, 0.9)
	if lane == &"right":
		return _wave_rng.randf_range(0.9, ArenaLayout.SPAWN_X_RANGE)
	return _wave_rng.randf_range(-ArenaLayout.SPAWN_X_RANGE, ArenaLayout.SPAWN_X_RANGE)

func _physics_process(delta: float) -> void:
	Game.record_playtest_simulation(delta, enemies.size())
	_update_lightning_fields(delta)
	if not _ended and _pending_drafts > 0 and not _draft_open and not get_tree().paused:
		if not _barricade_under_pressure() or _barricade_critical():
			_open_next_draft()

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
	_peak_enemy_count = maxi(_peak_enemy_count, enemies.size())
	if data.is_boss:
		hud.show_threat_banner("%s Approaches" % data.display_name)

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

func trigger_shatter(origin: Enemy, base_damage: float) -> void:
	if not is_instance_valid(origin) or not origin.is_alive():
		return
	var origin_pos := origin.gameplay_pos()
	_spawn_status_burst(origin_pos + Vector3(0, 0.5, 0), Color(0.72, 0.94, 1.0), 0.42, 0.16)
	origin.apply_armor_break(maxf(1.0, base_damage * 0.5), 2.5)
	origin.apply_stun(0.2)
	for e in enemies.duplicate():
		if e == origin:
			continue
		if not is_instance_valid(e) or not e.is_alive():
			continue
		if e.gameplay_pos().distance_to(origin_pos) > 1.6:
			continue
		_hit_single(e, base_damage * 0.55, {})
		e.apply_stun(0.35)

func trigger_enemy_hit(enemy: Enemy, amount: float, is_heavy_impact: bool) -> void:
	if not is_instance_valid(enemy) or not enemy.is_alive():
		return
	var profile := enemy.data.threat_profile if enemy.data != null else 0
	var impact_scale := clampf(amount / maxf(1.0, enemy.max_hp), 0.06, 0.24)
	var radius := 0.08 + impact_scale * 0.75
	var duration := 0.06 + impact_scale * 0.28
	var color := enemy.data.color if enemy.data != null else Color.WHITE
	match profile:
		0:
			color = color.lightened(0.08)
		1:
			color = color.lightened(0.14)
		2:
			color = color.lightened(0.20)
		3:
			color = color.lightened(0.26)
	if is_heavy_impact:
		radius *= 1.45
		duration *= 1.2
		color = color.lightened(0.10)
	if profile == 1:
		radius *= 1.03
	if profile == 2:
		radius *= 1.16
		duration *= 1.08
	if profile == 3:
		radius *= 1.34
		duration *= 1.2
	var body_pos := enemy.gameplay_pos() + Vector3(0, 0.34, 0)
	var ground_pos := enemy.gameplay_pos() + Vector3(0, 0.06, 0)
	_spawn_status_burst(body_pos, color, radius * 0.72, duration * 0.78)
	_spawn_impact_burst(ground_pos, color, is_heavy_impact or profile >= 2, false, profile)

func spawn_weapon_impact(at: Vector3, color: Color, splash_radius: float) -> void:
	## Presentation-only weapon feedback. Damage and splash membership have
	## already been resolved by apply_hit before this is called.
	_spawn_impact_burst(at + Vector3(0, 0.06, 0), color, true, false, 2)
	if splash_radius <= 0.0 or effects_root == null or not is_inside_tree():
		return
	var fx := Node3D.new()
	effects_root.add_child(fx)
	fx.global_position = at + Vector3(0, 0.03, 0)
	var ring := CylinderMesh.new()
	ring.top_radius = 0.12
	ring.bottom_radius = 0.12
	ring.height = 0.035
	var ring_mi := Visuals.mesh_instance(ring, color.lightened(0.22), true)
	ring_mi.rotation_degrees.x = 90.0
	fx.add_child(ring_mi)
	fx.scale = Vector3(0.18, 0.18, 0.18)
	var target_scale := maxf(1.0, splash_radius / 0.12)
	var tween := create_tween()
	tween.tween_property(fx, "scale", Vector3(target_scale, 0.35, target_scale), 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(fx.queue_free)

func trigger_enemy_death(enemy: Enemy, killed: bool) -> void:
	if not is_instance_valid(enemy):
		return
	var profile := enemy.data.threat_profile if enemy.data != null else 0
	var color := Color(0.95, 0.95, 0.95)
	var radius := 0.18
	var duration := 0.11
	match profile:
		1:
			color = Color(1.0, 0.88, 0.3)
			radius = 0.24
			duration = 0.14
		2:
			color = Color(1.0, 0.66, 0.28)
			radius = 0.36
			duration = 0.20
			if killed and enemy.data != null:
				hud.show_threat_banner("%s Down" % enemy.data.display_name, 0.95)
		3:
			color = Color(1.0, 0.48, 0.22)
			radius = 0.52
			duration = 0.28
			if killed and enemy.data != null:
				hud.show_threat_banner("%s Down" % enemy.data.display_name, 1.25)
	var death_body_pos := enemy.gameplay_pos() + Vector3(0, 0.38, 0)
	var death_ground_pos := enemy.gameplay_pos() + Vector3(0, 0.06, 0)
	_spawn_status_burst(death_body_pos, color, radius * 0.82, duration * 0.88)
	_spawn_impact_burst(death_ground_pos, color, true, killed, profile)
	if profile == 2:
		_shake_camera(1.2 if killed else 0.6)
	if profile == 3:
		_shake_camera(4.0 if killed else 2.0)

func trigger_guardian_wave(origin: Vector3, lane_width: float, lane_length: float, stun_duration: float, knockback: float) -> void:
	var lane_center := origin + Vector3(0, 0.25, -lane_length * 0.5)
	_spawn_lane_burst(lane_center, Color(0.45, 0.9, 1.0), lane_width, lane_length, 0.2)
	for e in enemies.duplicate():
		if not is_instance_valid(e) or not e.is_alive():
			continue
		if absf(e.position.x - origin.x) > lane_width * 0.5:
			continue
		if e.position.z > origin.z or e.position.z < origin.z - lane_length:
			continue
		e.apply_stun(stun_duration)
		e.apply_knockback(origin, knockback)

func spawn_lightning_field(center: Vector3, radius: float, duration: float, tick_interval: float, damage: float, color: Color) -> void:
	if effects_root == null or not is_inside_tree():
		return
	var fx := Node3D.new()
	effects_root.add_child(fx)
	fx.global_position = center
	var ring := CylinderMesh.new()
	ring.top_radius = radius
	ring.bottom_radius = radius
	ring.height = 0.05
	var ring_mi := Visuals.mesh_instance(ring, color.darkened(0.12), true)
	ring_mi.rotation_degrees.x = 90.0
	fx.add_child(ring_mi)
	var core := SphereMesh.new()
	core.radius = radius * 0.16
	core.height = core.radius * 2.0
	var core_mi := Visuals.mesh_instance(core, color.lightened(0.10), true)
	core_mi.position.y = 0.08
	fx.add_child(core_mi)
	fx.scale = Vector3.ONE * 0.25
	var tween := create_tween()
	tween.tween_property(fx, "scale", Vector3.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_field_effects.append({
		"center": center,
		"radius": radius,
		"remaining": duration,
		"tick_interval": tick_interval,
		"tick_timer": tick_interval,
		"damage": damage,
		"color": color,
		"fx": fx,
		"ring": ring_mi,
		"core": core_mi,
	})

func spawn_frost_pulse(center: Vector3, color: Color, radius: float, duration: float) -> void:
	if effects_root == null or not is_inside_tree():
		return
	var fx := Node3D.new()
	effects_root.add_child(fx)
	fx.global_position = center + Vector3(0, 0.04, 0)
	var ring := CylinderMesh.new()
	ring.top_radius = radius
	ring.bottom_radius = radius
	ring.height = 0.04
	var ring_mi := Visuals.mesh_instance(ring, color.lightened(0.10), true)
	ring_mi.rotation_degrees.x = 90.0
	fx.add_child(ring_mi)
	fx.scale = Vector3.ONE * 0.3
	var tween := create_tween()
	tween.tween_property(fx, "scale", Vector3.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ring_mi, "scale", Vector3.ONE * 1.2, duration)
	tween.tween_callback(fx.queue_free)

func _update_lightning_fields(delta: float) -> void:
	if _field_effects.is_empty():
		return
	for i in range(_field_effects.size() - 1, -1, -1):
		var field := _field_effects[i]
		field["remaining"] = float(field["remaining"]) - delta
		field["tick_timer"] = float(field["tick_timer"]) - delta
		if float(field["tick_timer"]) <= 0.0:
			field["tick_timer"] = float(field["tick_interval"])
			_tick_lightning_field(field)
		if float(field["remaining"]) <= 0.0:
			var fx := field.get("fx") as Node3D
			if is_instance_valid(fx):
				fx.queue_free()
			_field_effects.remove_at(i)
			continue
		_field_effects[i] = field

func _tick_lightning_field(field: Dictionary) -> void:
	var center: Vector3 = field.get("center", Vector3.ZERO)
	var radius: float = field.get("radius", 0.0)
	var damage: float = field.get("damage", 0.0)
	var color: Color = field.get("color", Color.WHITE)
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy) or not enemy.is_alive():
			continue
		if enemy.gameplay_pos().distance_to(center) > radius:
			continue
		_hit_single(enemy, damage, {})
		spawn_lightning_arc(
			center + Vector3(0, 0.2, 0),
			enemy.gameplay_pos() + Vector3(0, 0.5, 0),
			color,
			0.08
		)
	var ring := field.get("ring") as MeshInstance3D
	var core := field.get("core") as MeshInstance3D
	if is_instance_valid(ring):
		ring.scale = Vector3.ONE * 0.92
		var ring_tween := create_tween()
		ring_tween.tween_property(ring, "scale", Vector3.ONE * 1.06, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ring_tween.tween_property(ring, "scale", Vector3.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if is_instance_valid(core):
		core.scale = Vector3.ONE * 0.9
		var core_tween := create_tween()
		core_tween.tween_property(core, "scale", Vector3.ONE * 1.25, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		core_tween.tween_property(core, "scale", Vector3.ONE, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _spawn_lane_burst(center: Vector3, color: Color, width: float, length: float, duration: float) -> void:
	if effects_root == null:
		return
	var fx := Node3D.new()
	effects_root.add_child(fx)
	fx.global_position = center
	var wave := CapsuleMesh.new()
	wave.radius = width * 0.22
	wave.height = maxf(0.2, length - wave.radius * 2.0)
	var mi := Visuals.mesh_instance(wave, color, true)
	fx.add_child(mi)
	mi.rotation_degrees.x = 90.0
	mi.position.z = -length * 0.25
	var head := SphereMesh.new()
	head.radius = width * 0.26
	head.height = head.radius * 2.0
	var head_mi := Visuals.mesh_instance(head, color.lightened(0.15), true)
	head_mi.position.z = -length * 0.48
	fx.add_child(head_mi)
	fx.scale = Vector3.ONE * 0.18
	var tween := create_tween()
	tween.tween_property(fx, "scale", Vector3.ONE * 1.05, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mi, "scale", Vector3.ONE * 1.08, duration)
	tween.parallel().tween_property(head_mi, "scale", Vector3.ONE * 1.18, duration)
	tween.tween_callback(fx.queue_free)

func _hit_single(target: Enemy, base_damage: float, opts: Dictionary) -> void:
	var slow_factor: float = opts.get("slow_factor", 1.0)
	if slow_factor < 1.0:
		target.apply_slow(slow_factor, opts.get("slow_duration", 0.0))
	var expose_multiplier: float = opts.get("expose_damage_multiplier", 1.0)
	var expose_duration: float = opts.get("expose_duration", 0.0)
	var damage_family: StringName = opts.get("damage_family", &"")
	var resolved_damage := Combat.damage_after_armor(
		base_damage,
		target.armor(),
		target.damage_affinity_multiplier(damage_family)
	) * target.damage_taken_multiplier()
	target.take_damage(
		resolved_damage,
		opts.get("heavy_impact", false)
	)
	if expose_multiplier > 1.0 and expose_duration > 0.0 and is_instance_valid(target) and target.is_alive():
		target.apply_expose(expose_multiplier, expose_duration)
		_spawn_status_burst(target.gameplay_pos() + Vector3(0, 0.55, 0), Color(0.78, 0.94, 1.0), 0.16, 0.08)

func apply_impact_payload(target: Enemy, from: Vector3, opts: Dictionary) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		return
	var stun_duration: float = opts.get("impact_stun_duration", 0.0)
	var armor_break: float = opts.get("impact_armor_break", 0.0)
	var armor_break_duration: float = opts.get("impact_armor_break_duration", 0.0)
	var knockback: float = opts.get("impact_knockback", 0.0)
	if stun_duration > 0.0:
		target.apply_stun(stun_duration)
	if armor_break > 0.0 and armor_break_duration > 0.0:
		target.apply_armor_break(armor_break, armor_break_duration)
	if knockback > 0.0:
		target.apply_knockback(from, knockback)

func damage_fortress(amount: float) -> void:
	if _ended:
		return
	trigger_fortress_hit(amount)
	run_state.fortress_hp = maxf(0.0, run_state.fortress_hp - amount)
	var now_msec := Time.get_ticks_msec()
	_last_barricade_hit_msec = now_msec
	if now_msec >= _next_barricade_alert_msec:
		hud.show_threat_banner("Barricade Under Attack", 0.75)
		_next_barricade_alert_msec = now_msec + 1100
	_telemetry("fortress_hit", {
		"amount": amount,
		"fortress_hp": run_state.fortress_hp,
		"wave": run_state.wave_index,
	})
	hud.update_fortress()
	hud.flash_fortress_hit(amount, run_state.fortress_max_hp())
	if run_state.fortress_hp <= 0.0:
		_shake_camera(amount)
		hud.show_threat_banner("Containment Breached", 1.6)
		_end(false)

func heal_fortress(amount: float) -> void:
	run_state.fortress_hp = minf(run_state.fortress_max_hp(), run_state.fortress_hp + amount)
	hud.update_fortress()

func trigger_fortress_hit(amount: float) -> void:
	if fortress_root == null:
		return
	var ratio := clampf(amount / maxf(1.0, run_state.fortress_max_hp()), 0.0, 0.35)
	var pulse := 1.0 + ratio * 0.12
	var tween := create_tween()
	tween.tween_property(fortress_root, "scale", Vector3.ONE * pulse, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(fortress_root, "scale", Vector3.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_spawn_impact_burst(ArenaLayout.FORTRESS_CENTER + Vector3(0, 1.0, 0), Color(0.95, 0.72, 0.28), ratio >= 0.10, true, 3)
	if ratio >= 0.08:
		_shake_camera(amount * 0.5)

func trigger_barricade_contact(at: Vector3, intensity: float = 1.0) -> void:
	var clamped := clampf(intensity, 0.0, 1.0)
	_spawn_impact_burst(at + Vector3(0, 0.08, 0), Color(0.96, 0.78, 0.34), clamped >= 0.45, false, 1)
	if clamped >= 0.25:
		_spawn_status_burst(at + Vector3(0, 0.22, 0), Color(0.98, 0.86, 0.46), 0.12 + clamped * 0.10, 0.07 + clamped * 0.05)

## Called by Enemy on death. killed=false means it reached the fortress.
func notify_enemy_died(enemy: Enemy, killed: bool) -> void:
	enemies.erase(enemy)
	trigger_enemy_death(enemy, killed)
	if _ended or not killed:
		return
	var kill_result := run_state.award_kill(StringName("enemy_%d" % enemy.spawn_index), enemy.data.xp)
	if not bool(kill_result.get("accepted", false)):
		return
	var xp_amount := int(kill_result.get("xp", 0))
	var level_ups := int(kill_result.get("level_ups", 0))
	_telemetry("xp_gain", {
		"amount": xp_amount,
		"total_xp": run_state.total_xp_earned,
		"level": run_state.level,
		"kills": run_state.kills,
	})
	hud.update_xp()
	if level_ups > 0:
		_telemetry("level_up", {
			"count": level_ups,
			"level": run_state.level,
			"pending_level_ups": _pending_drafts + level_ups,
		})
		_queue_drafts(level_ups)

# --- Wave / stage lifecycle --------------------------------------------

func preview_wave(index: int, total: int, wave: WaveData) -> void:
	var suffix: String = ""
	suffix = wave.display_label()
	if suffix.is_empty() and wave.intent != &"":
		suffix = wave.intent_label()
	hud.update_wave(index, total, suffix)
	if wave.intent == &"elite" or wave.intent == &"boss":
		hud.show_threat_banner("%s Incoming" % wave.banner_text(), maxf(1.2, wave.pre_wave_delay))

func on_wave_started(index: int, total: int, wave: WaveData) -> void:
	run_state.wave_index = index
	var suffix: String = ""
	suffix = wave.display_label()
	if suffix.is_empty() and wave.intent != &"":
		suffix = wave.intent_label()
	_telemetry("wave_start", {
		"wave": index,
		"total_waves": total,
		"wave_label": wave.display_label(),
		"wave_intent": String(wave.intent),
		"level": run_state.level,
		"kills": run_state.kills,
		"fortress_hp": run_state.fortress_hp,
		"cards": run_state.acquired.keys(),
	})
	hud.update_wave(index, total, suffix)

func on_stage_cleared() -> void:
	_end(true)

func _end(victory: bool) -> void:
	if _ended:
		return
	_ended = true
	if victory:
		hud.show_threat_banner("Stage Cleared", 1.8)
	else:
		hud.show_threat_banner("Run Failed", 1.8)
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
	if Game.playtest_active:
		Game.finish_playtest(&"victory" if victory else &"defeat", {
			"kills": run_state.kills,
			"total_xp": run_state.total_xp_earned,
			"final_level": run_state.level,
			"pending_level_ups": _pending_drafts,
			"fortress_hp": run_state.fortress_hp,
			"peak_simultaneous_enemies": _peak_enemy_count,
			"guardian_movement_events": guardian.movement_events,
			"pulse_uses": guardian.pulse_uses,
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
	var available_budget := maxi(0, run_state.max_draft_choices - run_state.draft_count - _pending_drafts)
	_pending_drafts += mini(count, available_budget)
	hud.set_level_up_ready(_pending_drafts > 0, _pending_drafts)
	if not _draft_open:
		if _barricade_under_pressure() and not _barricade_critical():
			_maybe_show_draft_hold_banner()
		else:
			_open_next_draft()

func _open_next_draft() -> void:
	if _barricade_under_pressure() and not _barricade_critical():
		_maybe_show_draft_hold_banner()
		return
	while _pending_drafts > 0:
		_pending_drafts -= 1
		if not run_state.consume_draft_choice():
			continue
		hud.set_level_up_ready(_pending_drafts > 0, _pending_drafts)
		var rng := DetRNG.new(DetRNG.derive(run_state.run_seed, "draft", run_state.draft_count))
		var offer := Draft.generate_offer(Catalog.cards(), draft_context(), rng, 3)
		if offer.is_empty():
			continue
		var offer_ids: Array[String] = []
		var offer_titles: Array[String] = []
		var offer_categories: Array[String] = []
		for card in offer:
			offer_ids.append(String(card.id))
			offer_titles.append(card.title)
			offer_categories.append(String(Draft.semantic_category(card)))
		_telemetry("draft_open", {
			"draft_index": run_state.draft_count,
			"level": run_state.level,
			"wave": run_state.wave_index,
			"offer_ids": offer_ids,
			"offer_titles": offer_titles,
			"offer_categories": offer_categories,
			"pending_level_ups": _pending_drafts,
		})
		_draft_open = true
		_active_offer = offer.duplicate()
		hud.set_level_up_ready(false, _pending_drafts)
		get_tree().paused = true
		hud.show_draft(offer)
		return
	_draft_open = false
	hud.set_level_up_ready(false, 0)
	get_tree().paused = false

func _barricade_under_pressure() -> bool:
	var now_msec := Time.get_ticks_msec()
	if now_msec - _last_barricade_hit_msec < 900:
		return true
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.is_attacking_barricade():
			return true
	return false

func _barricade_critical() -> bool:
	if run_state == null:
		return false
	var max_hp := run_state.fortress_max_hp()
	if max_hp <= 0.0:
		return false
	return run_state.fortress_hp / max_hp <= 0.35

func _maybe_show_draft_hold_banner() -> void:
	var now_msec := Time.get_ticks_msec()
	if now_msec < _draft_hold_banner_msec:
		return
	hud.show_threat_banner("Level Up Ready", 0.7)
	_draft_hold_banner_msec = now_msec + 1200

func draft_context() -> Dictionary:
	var blocked := Draft.runtime_blocked_cards(Catalog.cards(), _available_slot_count())
	return {
		"acquired": run_state.acquired,
		"unlocks": Game.progression.unlock_flags(Catalog.perm_upgrades()),
		"blocked": blocked,
		"slots_available": _available_slot_count(),
		"active_turrets": run_state.active_turrets,
		"chosen_branches": run_state.chosen_branches,
		"chosen_branch_cards": run_state.chosen_branch_cards,
		"preferred_families": _draft_preferred_families(),
		"fortress_hp": run_state.fortress_hp,
		"fortress_max_hp": run_state.fortress_max_hp(),
		"under_pressure": _barricade_under_pressure(),
		"critical_pressure": _barricade_under_pressure() and _barricade_critical(),
		"pressure_ratio": run_state.fortress_hp / maxf(1.0, run_state.fortress_max_hp()),
		"draft_index": run_state.draft_count + 1,
		"allowed_card_ids": _stage_allowed_card_ids(),
	}

func _stage_allowed_card_ids() -> Array[StringName]:
	if stage.index != 1:
		return []
	return [
		&"build_cannon", &"sharp_rounds", &"rapid_trigger", &"split_shot",
		&"long_barrel", &"overload_core", &"piercing_rounds",
		&"cannon_blast_protocol", &"cannon_impact_protocol", &"cannon_shockwave",
	]

func _draft_preferred_families() -> Array[StringName]:
	var families: Array[StringName] = []
	var has_front := false
	var has_rear := false
	for slot in _slots:
		if slot.get("turret") == null:
			continue
		var marker := slot.get("marker") as Marker3D
		if marker == null:
			continue
		if marker.position.z >= -1.0:
			has_front = true
		else:
			has_rear = true
	if has_rear:
		families.append(&"bolt")
		families.append(&"frost")
	if has_front:
		families.append(&"cannon")
	if families.is_empty():
		families.append(&"bolt")
		families.append(&"cannon")
	return families

func on_card_chosen(card: CardData) -> void:
	if not _draft_open or not _active_offer.has(card):
		return
	_active_offer.clear()
	run_state.acquire_card(card.id)
	_telemetry("card_chosen", {
		"draft_index": run_state.draft_count,
		"card_id": String(card.id),
		"card_title": card.title,
		"category": String(Draft.semantic_category(card)),
		"weapon_family": String(Draft.weapon_family(card)),
		"wave": run_state.wave_index,
		"level": run_state.level,
		"acquired_count": int(run_state.acquired.get(card.id, 0)),
		"pending_level_ups": _pending_drafts,
	})
	apply_card(card)
	hud.hide_draft()
	hud.update_fortress()
	hud.set_level_up_ready(_pending_drafts > 0, _pending_drafts)
	if _pending_build_turret_id != &"":
		var pending_turret := Catalog.turret(_pending_build_turret_id)
		if pending_turret == null:
			push_warning("Battle: unknown pending turret %s" % _pending_build_turret_id)
			_pending_build_turret_id = &""
			hud.hide_overlay()
			_open_next_draft()
			return
		_begin_turret_placement(pending_turret)
		return
	hud.hide_overlay()
	get_tree().paused = false
	_open_next_draft()

func apply_card(card: CardData) -> void:
	for eff in card.effects:
		match eff.op:
			CardEffect.Op.ADD_STAT:
				run_state.mods.add_flat(eff.stat, eff.value)
			CardEffect.Op.MULTIPLY_STAT:
				run_state.mods.multiply(eff.stat, eff.value)
			CardEffect.Op.UNLOCK_TURRET:
				_pending_build_turret_id = eff.target
			CardEffect.Op.HEAL_FORTRESS:
				heal_fortress(eff.value)
			CardEffect.Op.APPLY_BRANCH:
				_apply_branch(eff.target, card.id)

func _apply_branch(branch_id: StringName, card_id: StringName = &"") -> void:
	var branch = Catalog.turret_branch(branch_id)
	if branch == null:
		push_warning("Battle: cannot apply unknown branch %s" % branch_id)
		return
	var current: StringName = run_state.branch_for(branch.turret_id)
	if current != &"":
		if current != branch.id:
			push_warning("Battle: turret %s already has branch %s" % [branch.turret_id, current])
		return
	for blocked in branch.excludes_branches:
		if run_state.branch_for(branch.turret_id) == blocked:
			push_warning("Battle: branch %s blocked by %s" % [branch.id, blocked])
			return
	run_state.set_branch(branch.turret_id, branch.id)
	run_state.record_branch_card(card_id)
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

func is_placement_open() -> bool:
	return _placement_open

func placement_slot_index() -> int:
	return _placement_slot_index

func _begin_turret_placement(turret: TurretData) -> void:
	var first_slot := _first_empty_slot()
	if first_slot < 0:
		push_warning("Battle: no empty slot available for %s" % turret.id)
		_pending_build_turret_id = &""
		hud.hide_overlay()
		get_tree().paused = false
		_open_next_draft()
		return
	_placement_open = true
	_placement_turret_id = turret.id
	_placement_slot_index = first_slot
	_placement_ghost = TURRET_SCENE.instantiate()
	turrets_root.add_child(_placement_ghost)
	_placement_ghost.setup(self, turret)
	_placement_ghost.set_preview_visual()
	_update_placement_ghost()
	hud.show_placement(turret, _placement_slot_index)

func _first_empty_slot() -> int:
	for slot_index in ArenaLayout.slot_pick_order():
		if slot_index >= 0 and slot_index < _slots.size() and _slots[slot_index].turret == null:
			return slot_index
	return -1

func move_placement_selection(direction: int) -> bool:
	if not _placement_open or direction == 0:
		return false
	var order: Array[int] = ArenaLayout.slot_pick_order()
	var current_order := order.find(_placement_slot_index)
	if current_order < 0:
		return false
	var step := 1 if direction > 0 else -1
	for offset in range(1, order.size() + 1):
		var candidate_order := posmod(current_order + step * offset, order.size())
		var candidate_index := order[candidate_order]
		if candidate_index < 0 or candidate_index >= _slots.size():
			continue
		if _slots[candidate_index].turret != null:
			continue
		_placement_slot_index = candidate_index
		_update_placement_ghost()
		hud.update_placement(_placement_slot_index)
		return true
	return false

func confirm_turret_placement() -> bool:
	if not _placement_open or _placement_turret_id == &"":
		return false
	if not _build_turret_at_slot(_placement_turret_id, _placement_slot_index):
		return false
	if is_instance_valid(_placement_ghost):
		_placement_ghost.queue_free()
	_placement_ghost = null
	_placement_open = false
	_placement_turret_id = &""
	_placement_slot_index = -1
	_pending_build_turret_id = &""
	hud.hide_placement()
	get_tree().paused = false
	_open_next_draft()
	return true

func _update_placement_ghost() -> void:
	if not is_instance_valid(_placement_ghost):
		return
	if _placement_slot_index < 0 or _placement_slot_index >= _slots.size():
		return
	var marker := _slots[_placement_slot_index].marker as Marker3D
	if marker != null:
		_placement_ghost.global_position = marker.global_position

func _build_turret_at_slot(turret_id: StringName, slot_index: int) -> bool:
	var data := Catalog.turret(turret_id)
	if data == null:
		push_warning("Battle: cannot build unknown turret %s" % turret_id)
		return false
	if slot_index < 0 or slot_index >= _slots.size():
		push_warning("Battle: invalid slot index %d for turret %s" % [slot_index, turret_id])
		return false
	var slot := _slots[slot_index]
	if slot.turret != null:
		push_warning("Battle: slot %d already occupied" % slot_index)
		return false
	if not run_state.install_turret(turret_id, slot_index):
		push_warning("Battle: domain slot %d rejected turret %s" % [slot_index, turret_id])
		return false
	var turret: Turret = TURRET_SCENE.instantiate()
	turrets_root.add_child(turret)
	turret.global_position = (slot.marker as Marker3D).global_position
	turret.setup(self, data)
	slot.turret = turret
	_telemetry("turret_install", {
		"turret_id": String(turret_id),
		"slot_index": slot_index,
		"occupied_slots": run_state.active_turrets,
		"remaining_slots": run_state.available_slot_count(),
	})
	return true

func _spawn_status_burst(at: Vector3, color: Color, radius: float, duration: float) -> void:
	if effects_root == null or not is_inside_tree():
		return
	var fx := Node3D.new()
	effects_root.add_child(fx)
	fx.global_position = at
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := Visuals.mesh_instance(mesh, color, true)
	fx.add_child(mi)
	fx.scale = Vector3(0.24, 0.30, 0.24)
	var tween := create_tween()
	tween.tween_property(fx, "scale", Vector3.ONE * 0.72, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(mi, "scale", Vector3(1.0, 1.28, 1.0), duration)
	tween.tween_callback(fx.queue_free)

func spawn_lightning_arc(from: Vector3, to: Vector3, color: Color, duration: float) -> void:
	if effects_root == null or not is_inside_tree():
		return
	var fx := Node3D.new()
	effects_root.add_child(fx)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var direction := to - from
	var side := Vector3.UP.cross(direction).normalized()
	if side.length_squared() <= 0.0001:
		side = Vector3.RIGHT
	var steps := 6
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var point := from.lerp(to, t)
		if i > 0 and i < steps:
			var offset := sin(float(i) * 19.0) * 0.11
			point += side * offset
		mesh.surface_add_vertex(point)
	mesh.surface_end()
	var material := StandardMaterial3D.new()
	material.albedo_color = color.lightened(0.25)
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.2
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	effects_root.add_child(mi)
	var tween := create_tween()
	tween.tween_property(mi, "scale", Vector3.ONE * 1.08, duration)
	tween.tween_callback(fx.queue_free)
	tween.tween_callback(mi.queue_free)

func _spawn_impact_burst(at: Vector3, color: Color, heavy: bool, fatal: bool, profile: int) -> void:
	if effects_root == null or not is_inside_tree():
		return
	var fx := Node3D.new()
	effects_root.add_child(fx)
	fx.global_position = at
	var core := SphereMesh.new()
	core.radius = 0.12 if not heavy else 0.18
	core.height = core.radius * 2.0
	var core_mi := Visuals.mesh_instance(core, color.lightened(0.12), true)
	core_mi.position.y = 0.10 if not heavy else 0.14
	fx.add_child(core_mi)
	var ring := CylinderMesh.new()
	ring.top_radius = 0.28 if not heavy else 0.42
	ring.bottom_radius = ring.top_radius
	ring.height = 0.03 if not heavy else 0.05
	var ring_color := color.lightened(0.24)
	var ring_mi := Visuals.mesh_instance(ring, ring_color, true)
	ring_mi.rotation_degrees.x = 90.0
	ring_mi.position.y = 0.02
	fx.add_child(ring_mi)
	var spark_count := 1 if not heavy else 3
	if fatal:
		spark_count += 2
	if profile >= 2:
		spark_count += 1
	for i in range(spark_count):
		var spark := CylinderMesh.new()
		spark.top_radius = 0.02
		spark.bottom_radius = 0.04 if heavy else 0.03
		spark.height = 0.38 if not heavy else 0.68
		var spark_mi := Visuals.mesh_instance(spark, ring_color, true)
		spark_mi.rotation_degrees = Vector3(90.0, float(i) * 24.0 + (10.0 if heavy else 0.0), float(i) * 13.0)
		spark_mi.position = Vector3(0, 0.06, 0)
		fx.add_child(spark_mi)
	fx.scale = Vector3(0.18, 0.12, 0.18)
	var tween := create_tween()
	var scale_target := 1.15 if not fatal else 1.3
	tween.tween_property(fx, "scale", Vector3(scale_target, 0.38 if not heavy else 0.44, scale_target), 0.09 if not heavy else 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(core_mi, "scale", Vector3.ONE * (1.22 if not heavy else 1.42), 0.09 if not heavy else 0.12)
	tween.parallel().tween_property(ring_mi, "scale", Vector3(1.55 if not heavy else 2.05, 1.0, 1.55 if not heavy else 2.05), 0.11 if not heavy else 0.15)
	tween.tween_callback(fx.queue_free)

func _shake_camera(amount: float) -> void:
	if camera_rig == null or not is_inside_tree():
		return
	var magnitude = minf(0.5, amount / 10.0)
	var base_position := camera_rig.position
	var tween = create_tween()
	tween.tween_property(camera_rig, "position", base_position + Vector3(magnitude, 0, 0), 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera_rig, "position", base_position + Vector3(-magnitude, 0, 0), 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(camera_rig, "position", base_position, 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN_OUT)

func _telemetry(event_name: String, payload: Dictionary = {}) -> void:
	var out := payload.duplicate(true)
	out["event"] = event_name
	out["stage"] = stage.index if stage != null else -1
	print("RUN_TLM %s" % JSON.stringify(out))
	if Game.playtest_active:
		Game.record_playtest_event(event_name, out)

func record_playtest_event(event_name: String, payload: Dictionary = {}) -> void:
	if Game.playtest_active:
		Game.record_playtest_event(event_name, payload)

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
		"field_count": _field_effects.size(),
		"turret_count": turrets_root.get_child_count(),
		"tree_paused": get_tree().paused,
	}
