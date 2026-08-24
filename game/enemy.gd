class_name Enemy
extends Node3D
## Enemy runtime. One script for all archetypes; behavior comes from EnemyData
## (contact vs ranged attacker is data: attack_interval + stop_range).
## Placeholder model is generated from data unless data.model_scene is set.

const HP_BAR_WIDTH := 0.9
const CONTACT_ATTACK_INTERVAL := 0.7

var battle: Battle
var data: EnemyData
var spawn_index := 0
var hp := 0.0
var max_hp := 0.0

var is_frozen: bool = false

var _speed_scale := 1.0
var _slow_factor := 1.0
var _slow_time := 0.0
var _freeze_time := 0.0
var _stun_time := 0.0
var _armor_break_time := 0.0
var _armor_break_value := 0.0
var _expose_time := 0.0
var _expose_multiplier := 1.0
var _attack_timer := 0.0
var _attack_windup := 0.0
var _attacking_barricade := false
var _dead := false
var _hp_fill: MeshInstance3D
var _hp_text: Label3D
var _telegraph_orb: MeshInstance3D
var _boss_ring: MeshInstance3D
var _threat_crown: MeshInstance3D
var _main_body_mesh: MeshInstance3D
var _spitter_sac_mesh: MeshInstance3D
var _spitter_snout_mesh: MeshInstance3D
var _brute_tank_mesh: MeshInstance3D
var _brute_shoulder_left_mesh: MeshInstance3D
var _brute_shoulder_right_mesh: MeshInstance3D
var _hp_bar_width := HP_BAR_WIDTH
var _hp_fill_color := Color(0.35, 0.9, 0.3, 0.95)

@onready var model_root: Node3D = $ModelRoot

func setup(b: Battle, d: EnemyData, index: int, x: float, hp_scale: float, speed_scale: float) -> void:
	battle = b
	data = d
	spawn_index = index
	_speed_scale = speed_scale
	max_hp = d.max_hp * hp_scale
	hp = max_hp
	_attack_timer = d.attack_interval if d.attack_interval > 0.0 else CONTACT_ATTACK_INTERVAL
	_hp_fill_color = _threat_hp_color()
	position = Vector3(x, 0.0, ArenaLayout.SPAWN_Z)
	_build_model()
	_build_hp_bar()

# --- Rules interface (consumed by core/targeting.gd and Battle) ---------

func gameplay_pos() -> Vector3:
	return position

func is_alive() -> bool:
	return not _dead

func is_attacking_barricade() -> bool:
	return _attacking_barricade and not _dead

func armor() -> float:
	if _armor_break_time > 0.0:
		return maxf(0.0, data.armor - _armor_break_value)
	return data.armor

func damage_taken_multiplier() -> float:
	if _expose_time > 0.0:
		return _expose_multiplier
	return 1.0

func take_damage(amount: float, is_heavy_impact: bool = false) -> void:
	if _dead:
		return

	if is_frozen and is_heavy_impact:
		amount *= 2.0
		battle.trigger_shatter(self, amount)
		is_frozen = false
		_freeze_time = 0.0
	else:
		battle.trigger_enemy_hit(self, amount, is_heavy_impact)

	hp -= amount
	_update_hp_bar()
	if hp <= 0.0:
		_die(true)

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = minf(_slow_factor, factor)
	_slow_time = maxf(_slow_time, duration)
	if factor <= 0.55 and duration >= 1.5:
		_freeze_time = maxf(_freeze_time, duration)
		is_frozen = true

func apply_stun(duration: float) -> void:
	_stun_time = maxf(_stun_time, duration)

func apply_armor_break(amount: float, duration: float) -> void:
	_armor_break_value = maxf(_armor_break_value, amount)
	_armor_break_time = maxf(_armor_break_time, duration)

func apply_expose(multiplier: float, duration: float) -> void:
	_expose_multiplier = maxf(_expose_multiplier, multiplier)
	_expose_time = maxf(_expose_time, duration)

func apply_knockback(from: Vector3, distance: float) -> void:
	var push := gameplay_pos() - from
	push.y = 0.0
	if push.length_squared() <= 0.000001:
		return
	position += push.normalized() * distance

# --- Behavior -----------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _freeze_time > 0.0:
		_freeze_time -= delta
		if _freeze_time <= 0.0:
			_freeze_time = 0.0
			is_frozen = false
		return
	if _stun_time > 0.0:
		_stun_time -= delta
		if _stun_time <= 0.0:
			_stun_time = 0.0
		return
	if _slow_time > 0.0:
		_slow_time -= delta
		if _slow_time <= 0.0:
			_slow_factor = 1.0
	if _armor_break_time > 0.0:
		_armor_break_time -= delta
		if _armor_break_time <= 0.0:
			_armor_break_time = 0.0
			_armor_break_value = 0.0
	if _expose_time > 0.0:
		_expose_time -= delta
		if _expose_time <= 0.0:
			_expose_time = 0.0
			_expose_multiplier = 1.0
	_update_barricade_attack_pose(delta)
	if _attack_windup > 0.0:
		_attack_windup -= delta
		_pulse_telegraph(_attack_windup)
		if _attack_windup <= 0.0:
			_attack_windup = 0.0
			_resolve_barricade_attack()
			if _telegraph_orb != null:
				_telegraph_orb.visible = false
		return
	var stop_z := ArenaLayout.FORTRESS_LINE_Z - data.stop_range
	if position.z < stop_z:
		var step := data.speed * _speed_scale * _slow_factor * delta
		position.z = minf(position.z + step, stop_z)
		_attacking_barricade = false
		return
	_attacking_barricade = true
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = data.attack_interval if data.attack_interval > 0.0 else CONTACT_ATTACK_INTERVAL
		_attack_windup = 0.42
		if _telegraph_orb != null:
			_telegraph_orb.visible = true

func _die(killed: bool) -> void:
	if _dead:
		return
	_dead = true
	battle.notify_enemy_died(self, killed)
	queue_free()

# --- Placeholder presentation ------------------------------------------

func _build_model() -> void:
	if data.model_scene != null:
		model_root.add_child(data.model_scene.instantiate())
		_build_threat_markers()
		return
	if data.attack_interval > 0.0:
		_build_spitter_placeholder()
	elif data.threat_profile >= 2:
		_build_brute_placeholder()
	elif data.shape == 1:
		_build_runner_placeholder()
	else:
		_build_worker_placeholder()
	model_root.scale = data.body_scale
	_build_threat_markers()

func _build_worker_placeholder() -> void:
	var torso := BoxMesh.new()
	torso.size = Vector3(0.62, 0.72, 0.32)
	var torso_mi := Visuals.mesh_instance(torso, data.color)
	torso_mi.position = Vector3(0, 0.55, 0)
	model_root.add_child(torso_mi)
	_main_body_mesh = torso_mi
	var head := BoxMesh.new()
	head.size = Vector3(0.26, 0.22, 0.22)
	var head_mi := Visuals.mesh_instance(head, data.color.lightened(0.12))
	head_mi.position = Vector3(0, 1.05, -0.04)
	model_root.add_child(head_mi)
	var arm := BoxMesh.new()
	arm.size = Vector3(0.12, 0.48, 0.12)
	var left_arm := Visuals.mesh_instance(arm, data.color.darkened(0.1))
	left_arm.position = Vector3(-0.26, 0.54, -0.03)
	left_arm.rotation_degrees = Vector3(0, 0, 12)
	model_root.add_child(left_arm)
	var right_arm := Visuals.mesh_instance(arm, data.color.darkened(0.1))
	right_arm.position = Vector3(0.26, 0.5, -0.03)
	right_arm.rotation_degrees = Vector3(0, 0, -18)
	model_root.add_child(right_arm)

func _build_runner_placeholder() -> void:
	var body := CapsuleMesh.new()
	body.radius = 0.24
	body.height = 0.72
	var body_mi := Visuals.mesh_instance(body, data.color)
	body_mi.position = Vector3(0, 0.34, 0.02)
	body_mi.rotation_degrees = Vector3(82, 0, 0)
	model_root.add_child(body_mi)
	_main_body_mesh = body_mi
	var head := SphereMesh.new()
	head.radius = 0.13
	head.height = 0.26
	var head_mi := Visuals.mesh_instance(head, data.color.lightened(0.08))
	head_mi.position = Vector3(0, 0.45, -0.28)
	model_root.add_child(head_mi)
	var leg := BoxMesh.new()
	leg.size = Vector3(0.11, 0.38, 0.11)
	var left_leg := Visuals.mesh_instance(leg, data.color.darkened(0.12))
	left_leg.position = Vector3(-0.14, 0.18, 0.18)
	left_leg.rotation_degrees = Vector3(42, 0, 0)
	model_root.add_child(left_leg)
	var right_leg := Visuals.mesh_instance(leg, data.color.darkened(0.12))
	right_leg.position = Vector3(0.14, 0.12, 0.12)
	right_leg.rotation_degrees = Vector3(-18, 0, 0)
	model_root.add_child(right_leg)

func _build_brute_placeholder() -> void:
	var torso := BoxMesh.new()
	torso.size = Vector3(0.88, 0.98, 0.46)
	var torso_mi := Visuals.mesh_instance(torso, data.color)
	torso_mi.position = Vector3(0, 0.7, 0)
	model_root.add_child(torso_mi)
	_main_body_mesh = torso_mi
	var head := BoxMesh.new()
	head.size = Vector3(0.3, 0.24, 0.24)
	var head_mi := Visuals.mesh_instance(head, data.color.lightened(0.1))
	head_mi.position = Vector3(0, 1.28, -0.02)
	model_root.add_child(head_mi)
	var shoulder := BoxMesh.new()
	shoulder.size = Vector3(0.26, 0.26, 0.34)
	var left_shoulder := Visuals.mesh_instance(shoulder, data.color.darkened(0.16))
	left_shoulder.position = Vector3(-0.47, 0.84, 0)
	model_root.add_child(left_shoulder)
	_brute_shoulder_left_mesh = left_shoulder
	var right_shoulder := Visuals.mesh_instance(shoulder, data.color.darkened(0.16))
	right_shoulder.position = Vector3(0.47, 0.84, 0)
	model_root.add_child(right_shoulder)
	_brute_shoulder_right_mesh = right_shoulder
	var tank := CylinderMesh.new()
	tank.top_radius = 0.18
	tank.bottom_radius = 0.2
	tank.height = 0.54
	var tank_mi := Visuals.mesh_instance(tank, Color(0.18, 0.2, 0.16, 1.0))
	tank_mi.position = Vector3(0, 0.8, 0.3)
	tank_mi.rotation_degrees = Vector3(90, 0, 0)
	model_root.add_child(tank_mi)
	_brute_tank_mesh = tank_mi

func _build_spitter_placeholder() -> void:
	var body := CylinderMesh.new()
	body.top_radius = 0.34
	body.bottom_radius = 0.42
	body.height = 0.72
	var body_mi := Visuals.mesh_instance(body, data.color)
	body_mi.position = Vector3(0, 0.42, 0.04)
	model_root.add_child(body_mi)
	_main_body_mesh = body_mi
	var sac := SphereMesh.new()
	sac.radius = 0.2
	sac.height = 0.4
	var sac_mi := Visuals.mesh_instance(sac, Color(0.75, 0.95, 0.42, 1.0))
	sac_mi.position = Vector3(0, 0.62, 0.12)
	model_root.add_child(sac_mi)
	_spitter_sac_mesh = sac_mi
	var snout := BoxMesh.new()
	snout.size = Vector3(0.16, 0.16, 0.38)
	var snout_mi := Visuals.mesh_instance(snout, data.color.darkened(0.14))
	snout_mi.position = Vector3(0, 0.52, -0.34)
	snout_mi.rotation_degrees = Vector3(-10, 0, 0)
	model_root.add_child(snout_mi)
	_spitter_snout_mesh = snout_mi
	var leg := BoxMesh.new()
	leg.size = Vector3(0.1, 0.28, 0.1)
	var left_leg := Visuals.mesh_instance(leg, data.color.darkened(0.18))
	left_leg.position = Vector3(-0.18, 0.12, 0.1)
	model_root.add_child(left_leg)
	var right_leg := Visuals.mesh_instance(leg, data.color.darkened(0.18))
	right_leg.position = Vector3(0.18, 0.12, 0.1)
	model_root.add_child(right_leg)

func _build_threat_markers() -> void:
	if data.threat_profile >= 2:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.74 * data.body_scale.x
		ring.outer_radius = 0.90 * data.body_scale.x
		ring.rings = 24
		ring.ring_segments = 16
		var ring_color := Color(0.95, 0.72, 0.18) if data.threat_profile == 2 else Color(1.0, 0.58, 0.16)
		_boss_ring = Visuals.mesh_instance(ring, ring_color, true)
		_boss_ring.rotation_degrees.x = 90.0
		_boss_ring.position = Vector3(0, 0.03, 0)
		add_child(_boss_ring)
	if data.threat_profile == 3:
		var crown := CylinderMesh.new()
		crown.top_radius = 0.16
		crown.bottom_radius = 0.24
		crown.height = 0.08
		_threat_crown = Visuals.mesh_instance(crown, Color(1.0, 0.8, 0.25), true)
		_threat_crown.position = Vector3(0, data.body_scale.y + 0.72, 0)
		model_root.add_child(_threat_crown)
	if data.attack_interval > 0.0:
		var orb := SphereMesh.new()
		orb.radius = 0.16
		orb.height = 0.32
		var orb_color := Color(1.0, 0.64, 0.18) if data.threat_profile != 1 else Color(1.0, 0.85, 0.25)
		_telegraph_orb = Visuals.mesh_instance(orb, orb_color, true)
		_telegraph_orb.position = Vector3(0, data.body_scale.y + 0.45, 0.1)
		_telegraph_orb.visible = data.threat_profile == 1
		model_root.add_child(_telegraph_orb)

func _pulse_telegraph(windup_left: float) -> void:
	if _telegraph_orb == null:
		return
	var windup_progress := 1.0 - clampf(windup_left / 0.42, 0.0, 1.0)
	var pulse := 1.0 + windup_progress * 0.55
	_telegraph_orb.scale = Vector3.ONE * pulse
	_update_attack_read_pose(windup_progress)
	if data.is_boss and _boss_ring != null:
		_boss_ring.scale = Vector3.ONE * (1.0 + windup_progress * 0.12)

func _update_barricade_attack_pose(delta: float) -> void:
	if model_root == null:
		return
	var target_pitch := -18.0 if _attacking_barricade else 0.0
	var target_z := -0.06 if _attacking_barricade else 0.0
	if data.threat_profile >= 2 and data.attack_interval <= 0.0:
		target_pitch = -26.0 if _attacking_barricade else 0.0
		target_z = -0.11 if _attacking_barricade else 0.0
	model_root.rotation_degrees.x = lerpf(model_root.rotation_degrees.x, target_pitch, minf(1.0, delta * 10.0))
	model_root.position.z = lerpf(model_root.position.z, target_z, minf(1.0, delta * 10.0))
	if _main_body_mesh != null:
		_main_body_mesh.scale = _main_body_mesh.scale.lerp(Vector3.ONE, minf(1.0, delta * 9.0))
	if _spitter_sac_mesh != null:
		_spitter_sac_mesh.scale = _spitter_sac_mesh.scale.lerp(Vector3.ONE, minf(1.0, delta * 8.0))
	if _spitter_snout_mesh != null:
		_spitter_snout_mesh.scale = _spitter_snout_mesh.scale.lerp(Vector3.ONE, minf(1.0, delta * 10.0))
		_spitter_snout_mesh.position.z = lerpf(_spitter_snout_mesh.position.z, -0.34, minf(1.0, delta * 10.0))
	if data.threat_profile >= 2 and _brute_tank_mesh != null:
		_brute_tank_mesh.rotation_degrees.x = lerpf(_brute_tank_mesh.rotation_degrees.x, 90.0 + target_pitch * 0.35, minf(1.0, delta * 8.0))
		_brute_shoulder_left_mesh.position.z = lerpf(_brute_shoulder_left_mesh.position.z, -0.05 if _attacking_barricade else 0.0, minf(1.0, delta * 9.0))
		_brute_shoulder_right_mesh.position.z = lerpf(_brute_shoulder_right_mesh.position.z, -0.05 if _attacking_barricade else 0.0, minf(1.0, delta * 9.0))

func _threat_hp_color() -> Color:
	if data.threat_profile == 1:
		return Color(1.0, 0.82, 0.25, 0.95)
	if data.threat_profile == 2:
		return Color(1.0, 0.62, 0.24, 0.95)
	if data.threat_profile == 3:
		return Color(1.0, 0.38, 0.22, 0.95)
	return Color(0.35, 0.9, 0.3, 0.95)

func _fire_fortress_shot() -> void:
	Projectile.spawn_fortress_shot(
		battle,
		gameplay_pos() + Vector3(0, 0.8, 0),
		data.fortress_damage,
		data.color,
		data.fortress_projectile_radius
	)

func _resolve_barricade_attack() -> void:
	if data.attack_interval > 0.0:
		if _spitter_sac_mesh != null:
			_spitter_sac_mesh.scale = Vector3(0.86, 0.86, 1.2)
		if _spitter_snout_mesh != null:
			_spitter_snout_mesh.scale = Vector3(1.0, 1.0, 1.18)
		_fire_fortress_shot()
	else:
		if data.threat_profile >= 2 and _main_body_mesh != null:
			_main_body_mesh.scale = Vector3(1.06, 0.94, 1.12)
		battle.trigger_barricade_contact(gameplay_pos(), clampf(data.fortress_damage / 10.0, 0.2, 1.0))
		battle.damage_fortress(data.fortress_damage)

func _update_attack_read_pose(windup_progress: float) -> void:
	if _spitter_sac_mesh != null:
		var sac_pulse := 1.0 + windup_progress * 0.32
		_spitter_sac_mesh.scale = Vector3(1.0 + windup_progress * 0.08, 1.0 + windup_progress * 0.08, sac_pulse)
	if _spitter_snout_mesh != null:
		_spitter_snout_mesh.scale = Vector3.ONE + Vector3(0.0, 0.0, windup_progress * 0.22)
		_spitter_snout_mesh.position.z = -0.34 - windup_progress * 0.05
	if data.threat_profile >= 2 and data.attack_interval <= 0.0 and _main_body_mesh != null:
		var brute_push := 1.0 + windup_progress * 0.08
		_main_body_mesh.scale = Vector3(1.0, 1.0 - windup_progress * 0.04, brute_push)

func _build_hp_bar() -> void:
	var emphasized := data.threat_profile >= 2 or data.is_boss
	_hp_bar_width = 0.9 if not emphasized else 1.16
	var height := data.body_scale.y + (0.5 if not emphasized else 0.72)
	var bar := Node3D.new()
	bar.name = "HPBar"
	bar.position = Vector3(0, height, 0)
	add_child(bar)
	var bg := MeshInstance3D.new()
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(_hp_bar_width, 0.12 if not emphasized else 0.14)
	bg.mesh = bg_mesh
	bg.material_override = _bar_material(Color(0.1, 0.1, 0.1, 0.85), 0)
	bar.add_child(bg)
	_hp_fill = MeshInstance3D.new()
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(_hp_bar_width, 0.08 if not emphasized else 0.1)
	_hp_fill.mesh = fill_mesh
	_hp_fill.material_override = _bar_material(_hp_fill_color, 1)
	bar.add_child(_hp_fill)
	if emphasized:
		_hp_text = Label3D.new()
		_hp_text.text = "%d/%d" % [ceili(hp), ceili(max_hp)]
		_hp_text.font_size = 20 if data.threat_profile == 3 else 16
		_hp_text.outline_size = 4
		_hp_text.modulate = Color(1, 1, 1, 0.96)
		_hp_text.position = Vector3(0, 0.12, 0)
		bar.add_child(_hp_text)

static var _bar_mats: Dictionary = {}

static func _bar_material(color: Color, priority: int) -> StandardMaterial3D:
	var key := color.to_html()
	if not _bar_mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.no_depth_test = true
		m.render_priority = priority
		_bar_mats[key] = m
	return _bar_mats[key]

func _update_hp_bar() -> void:
	if _hp_fill == null:
		return
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	_hp_fill.scale.x = maxf(ratio, 0.001)
	_hp_fill.position.x = 0.0
	var danger := 1.0 - ratio
	var hp_color := Color(0.35, 0.9, 0.3, 0.95).lerp(Color(1.0, 0.78, 0.22, 0.95), danger * 0.55)
	if data.threat_profile == 2:
		hp_color = Color(1.0, 0.70, 0.24, 0.95).lerp(Color(0.92, 0.38, 0.16, 0.95), danger * 0.35)
	if data.threat_profile == 3:
		hp_color = Color(1.0, 0.48, 0.22, 0.95).lerp(Color(0.86, 0.12, 0.12, 0.95), danger * 0.4)
	_hp_fill.material_override = _bar_material(hp_color, 1)
	if _hp_text != null:
		_hp_text.text = "%d/%d" % [ceili(hp), ceili(max_hp)]
