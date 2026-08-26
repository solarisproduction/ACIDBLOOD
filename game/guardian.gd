class_name Guardian
extends Node3D
## Player-controlled Guardian: horizontal movement (keyboard + pointer),
## deterministic auto-targeting and auto-fire. All combat numbers resolve
## through Battle.stat() so cards and permanent upgrades apply uniformly.

var battle: Battle
var data: GuardianData
var _cooldown := 0.0
var _visual_cooldown := 0.0
var _visual_step := 0
var _ability_cooldown := 0.0
var _space_was_down := false
var _recoil := 0.0
var movement_events := 0
var pulse_uses := 0
var _movement_axis := 0.0

@onready var model: Node3D = $Model
@onready var muzzle: Marker3D = $Model/Muzzle
@onready var body_mesh: MeshInstance3D = $Model/Body
@onready var arm_left_mesh: MeshInstance3D = $Model/ArmLeft
@onready var arm_right_mesh: MeshInstance3D = $Model/ArmRight
@onready var gun_mesh: MeshInstance3D = $Model/Gun
@onready var gun_barrel_mesh: MeshInstance3D = $Model/GunBarrel
@onready var gun_mag_mesh: MeshInstance3D = $Model/GunMag

var _body_base_position := Vector3.ZERO
var _arm_left_base_rotation := Vector3.ZERO
var _arm_right_base_rotation := Vector3.ZERO
var _gun_base_position := Vector3.ZERO
var _gun_barrel_base_position := Vector3.ZERO
var _gun_mag_base_position := Vector3.ZERO

func setup(b: Battle, d: GuardianData) -> void:
	battle = b
	data = d
	position = Vector3(0, 0, ArenaLayout.GUARDIAN_Z)
	if d.model_scene != null:
		for child in model.get_children():
			child.queue_free()
		model.add_child(d.model_scene.instantiate())
	else:
		_apply_placeholder_materials()
	model.scale = Vector3.ONE * d.presentation_scale
	_cache_placeholder_pose()

func _apply_placeholder_materials() -> void:
	var body_color := data.color
	var armor_color := body_color.darkened(0.18)
	var weapon_color := Color(0.1, 0.12, 0.14, 1.0)
	var gear_color := Color(0.2, 0.22, 0.18, 1.0)
	for mi in model.find_children("*", "MeshInstance3D"):
		var mesh := mi as MeshInstance3D
		var node_name := mesh.name.to_lower()
		if node_name.contains("gun"):
			mesh.material_override = Visuals.mat(weapon_color)
		elif node_name.contains("backpack"):
			mesh.material_override = Visuals.mat(gear_color)
		elif node_name.contains("arm") or node_name.contains("leg") or node_name.contains("hips"):
			mesh.material_override = Visuals.mat(armor_color)
		else:
			mesh.material_override = Visuals.mat(body_color)

func move_speed() -> float:
	return battle.stat(&"guardian.move_speed", data.move_speed)

func _physics_process(delta: float) -> void:
	_ability_cooldown = maxf(0.0, _ability_cooldown - delta)
	_move(delta)
	_combat(delta)
	_ability(delta)
	_update_placeholder_recoil(delta)

func _move(delta: float) -> void:
	var previous_x := position.x
	var axis := 0.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		axis -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		axis += 1.0
	var step := move_speed() * delta
	if axis != 0.0:
		position.x += axis * step
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var target_x := _pointer_world_x()
		if not is_nan(target_x):
			axis = signf(target_x - position.x)
			position.x = move_toward(position.x, target_x, step)
	position.x = clampf(position.x, -ArenaLayout.GUARDIAN_X_LIMIT, ArenaLayout.GUARDIAN_X_LIMIT)
	var new_episode := _record_movement_axis(axis)
	if absf(position.x - previous_x) > 0.001 and new_episode:
		battle.record_playtest_event("guardian_move", {"x": snappedf(position.x, 0.01)})

func _record_movement_axis(axis: float) -> bool:
	var normalized := signf(axis)
	if normalized == 0.0:
		_movement_axis = 0.0
		return false
	var started := _movement_axis == 0.0 or _movement_axis != normalized
	if _movement_axis == 0.0 or _movement_axis != normalized:
		movement_events += 1
	_movement_axis = normalized
	return started

## Projects the pointer onto the y=0 gameplay plane; NAN when unavailable.
func _pointer_world_x() -> float:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return NAN
	var mouse := get_viewport().get_mouse_position()
	var origin := cam.project_ray_origin(mouse)
	var dir := cam.project_ray_normal(mouse)
	if absf(dir.y) < 0.0001:
		return NAN
	var t := -origin.y / dir.y
	return (origin + dir * t).x

func _combat(delta: float) -> void:
	_cooldown -= delta
	_visual_cooldown -= delta
	var w := data.weapon
	var attack_range := battle.stat(&"guardian.range", w.attack_range)
	var target := Targeting.pick_target(battle.enemies, position, attack_range, w.targeting_policy) as Enemy
	if target != null:
		var aim := target.gameplay_pos()
		var look := Vector3(aim.x, global_position.y, aim.z)
		if not look.is_equal_approx(global_position):
			model.look_at(look)
	if target == null:
		_visual_step = 0
		return
	var real_interval: float = maxf(Combat.MIN_ATTACK_INTERVAL, battle.stat(&"guardian.attack_interval", w.attack_interval))
	var tracer_count: int = maxi(1, w.visual_tracers_per_shot)
	var visual_interval: float = real_interval / float(tracer_count)
	if _visual_cooldown > 0.0:
		return
	_visual_cooldown = visual_interval
	var deals_damage: bool = _visual_step == 0
	if deals_damage and _cooldown > 0.0:
		_visual_step = (_visual_step + 1) % tracer_count
		return
	if deals_damage:
		_cooldown = real_interval
		_trigger_placeholder_recoil()
	_fire(target, w, deals_damage)
	_visual_step = (_visual_step + 1) % tracer_count

func _fire(target: Enemy, w: WeaponDefinition, deals_damage: bool) -> void:
	var count := int(battle.stat(&"guardian.projectiles", float(w.projectile_count)))
	var cfg := {
		"damage": battle.stat(&"guardian.damage", w.damage) if deals_damage else 0.0,
		"damage_family": w.damage_family,
		"speed": w.projectile_speed,
		"pierce": int(battle.stat(&"guardian.pierce", float(w.pierce))) if deals_damage else 0,
		"color": w.projectile_color,
		"radius": w.projectile_radius,
		"projectile_visual": w.projectile_visual,
		"attack_topology": w.attack_topology,
		"impact_visual": w.impact_visual,
		"can_home": false,
	}
	var base_dir := (target.gameplay_pos() - muzzle.global_position)
	base_dir.y = 0.0
	base_dir = base_dir.normalized()
	for i in count:
		var angle := deg_to_rad(w.spread_degrees) * (i - (count - 1) * 0.5)
		var p := Projectile.new()
		p.battle = battle
		p.target = null
		p.speed = cfg.speed
		p.damage = cfg.damage
		p.pierce = cfg.pierce
		p.opts = cfg
		p.can_home = cfg.can_home
		p.cosmetic_only = not deals_damage
		p.position = muzzle.global_position
		p._dir = base_dir.rotated(Vector3.UP, angle)
		p._add_mesh(cfg.color, cfg.radius, cfg.projectile_visual)
		battle.projectiles_root.add_child(p)

func _ability(delta: float) -> void:
	var pressed := Input.is_physical_key_pressed(KEY_SPACE)
	if pressed and not _space_was_down and _ability_cooldown <= 0.0:
		pulse_uses += 1
		battle.record_playtest_event("pulse_use", {"x": snappedf(position.x, 0.01)})
		_ability_cooldown = maxf(1.0, data.ability_cooldown)
		battle.trigger_guardian_wave(
			global_position,
			data.ability_lane_width,
			data.ability_lane_length,
			data.ability_stun_duration,
			data.ability_knockback
		)
	_space_was_down = pressed

func ability_cooldown_remaining() -> float:
	return _ability_cooldown

func ability_cooldown_total() -> float:
	return maxf(1.0, data.ability_cooldown)

func _cache_placeholder_pose() -> void:
	_body_base_position = body_mesh.position
	_arm_left_base_rotation = arm_left_mesh.rotation_degrees
	_arm_right_base_rotation = arm_right_mesh.rotation_degrees
	_gun_base_position = gun_mesh.position
	_gun_barrel_base_position = gun_barrel_mesh.position
	_gun_mag_base_position = gun_mag_mesh.position

func _trigger_placeholder_recoil() -> void:
	_recoil = 1.0

func _update_placeholder_recoil(delta: float) -> void:
	_recoil = move_toward(_recoil, 0.0, delta * 12.0)
	var kick := _recoil
	body_mesh.position = _body_base_position + Vector3(0, 0, 0.045 * kick)
	arm_left_mesh.rotation_degrees = _arm_left_base_rotation + Vector3(-8.0 * kick, 0, -3.0 * kick)
	arm_right_mesh.rotation_degrees = _arm_right_base_rotation + Vector3(-10.0 * kick, 0, 2.0 * kick)
	gun_mesh.position = _gun_base_position + Vector3(0, 0.015 * kick, 0.12 * kick)
	gun_barrel_mesh.position = _gun_barrel_base_position + Vector3(0, 0.015 * kick, 0.14 * kick)
	gun_mag_mesh.position = _gun_mag_base_position + Vector3(0, 0.01 * kick, 0.08 * kick)
