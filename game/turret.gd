class_name Turret
extends Node3D
## Turret runtime. One script for all archetypes; splash and slow behavior
## comes from TurretData. Stats resolve through Battle.stat() using the
## "turret.<id>.<stat>" path so upgrade cards affect every built instance.

func refresh_branch_visual() -> void:
	for child in get_children():
		child.queue_free()
	_build_model()

var battle: Battle
var data: TurretData
var _cooldown := 0.0
var _head: Node3D
var _visual_recoil := 0.0
var _base_mesh: MeshInstance3D
var _body_mesh: MeshInstance3D
var _barrel_mesh: MeshInstance3D
var _coil_left_mesh: MeshInstance3D
var _coil_right_mesh: MeshInstance3D
var _tank_mesh: MeshInstance3D

func setup(b: Battle, d: TurretData) -> void:
	battle = b
	data = d
	scale = Vector3.ONE * d.presentation_scale
	refresh_branch_visual()

func get_active_branch() -> TurretBranchData:
	var branch_id = battle.run_state.branch_for(data.id)
	if branch_id != "":
		return Catalog.turret_branch(branch_id)
	return null

func get_attack_mode() -> StringName:
	var branch := get_active_branch()
	if branch != null and branch.attack_mode != &"":
		return branch.attack_mode
	return data.attack_mode

func _stat(local: String, base: float) -> float:
	return battle.stat(StringName("turret.%s.%s" % [data.id, local]), base)

func _physics_process(delta: float) -> void:
	_cooldown -= delta
	_update_visual_feedback(delta)
	var attack_range := _stat("range", data.attack_range)
	var target := Targeting.pick_target(battle.enemies, position, attack_range) as Enemy
	if target == null:
		return
	var aim := target.gameplay_pos()
	if _head != null:
		var look := Vector3(aim.x, _head.global_position.y, aim.z)
		if not look.is_equal_approx(_head.global_position):
			_head.look_at(look)
	if _cooldown > 0.0:
		return
	_cooldown = maxf(Combat.MIN_ATTACK_INTERVAL, _stat("attack_interval", data.attack_interval))
	_trigger_visual_fire()
	var shot_cfg := {
		"damage": _stat("damage", data.damage),
		"speed": _stat("projectile_speed", data.projectile_speed),
		"projectile_radius": _stat("projectile_radius", data.projectile_radius),
		"splash_radius": _stat("splash_radius", data.splash_radius),
		"slow_factor": _stat("slow_factor", data.slow_factor),
		"slow_duration": _stat("slow_duration", data.slow_duration),
		"heavy_impact": target.is_frozen,
		"color": data.color,
		"radius": _stat("projectile_radius", data.projectile_radius),
		"projectile_visual": _default_projectile_visual(),
	}
	var branch := get_active_branch()
	if branch != null:
		shot_cfg["heavy_impact"] = bool(shot_cfg["heavy_impact"]) or branch.force_heavy_impact
		if branch.projectile_visual != &"":
			shot_cfg["projectile_visual"] = branch.projectile_visual
	if get_attack_mode() == &"lightning" or get_attack_mode() == &"lightning_chain" or get_attack_mode() == &"lightning_field":
		if branch != null:
			shot_cfg["chain_count"] = branch.chain_count
			shot_cfg["chain_range"] = branch.chain_range
			shot_cfg["chain_damage_factor"] = branch.chain_damage_factor
			shot_cfg["field_radius"] = branch.field_radius
			shot_cfg["field_duration"] = branch.field_duration
			shot_cfg["field_tick_interval"] = branch.field_tick_interval
			shot_cfg["field_damage_factor"] = branch.field_damage_factor
		Projectile.spawn_lightning_shot(battle, global_position + Vector3(0, 1.1, 0), target, shot_cfg)
	else:
		if branch != null:
			shot_cfg["impact_stun_duration"] = branch.impact_stun_duration
			shot_cfg["impact_armor_break"] = branch.impact_armor_break
			shot_cfg["impact_armor_break_duration"] = branch.impact_armor_break_duration
			shot_cfg["impact_knockback"] = branch.impact_knockback
			shot_cfg["expose_damage_multiplier"] = branch.expose_damage_multiplier
			shot_cfg["expose_duration"] = branch.expose_duration
		Projectile.spawn_shot(battle, global_position + Vector3(0, 1.1, 0), target, shot_cfg)

func _build_model() -> void:
	if data.model_scene != null:
		add_child(data.model_scene.instantiate())
		return
	
	var branch = get_active_branch()
	var base_color = Color(0.4, 0.42, 0.48)
	var scale_factor = 1.0
	if branch != null:
		base_color = _branch_accent_color(branch)
		scale_factor = 1.1
	
	_build_placeholder_family_model(base_color, scale_factor)

func _branch_accent_color(branch: TurretBranchData) -> Color:
	match branch.id:
		&"bolt_chain":
			return Color(0.30, 0.88, 0.52)
		&"bolt_field":
			return Color(0.42, 0.82, 1.0)
		&"cannon_blast":
			return Color(1.0, 0.70, 0.28)
		&"cannon_impact":
			return Color(1.0, 0.40, 0.20)
		&"frost_control":
			return Color(0.58, 0.86, 1.0)
		&"frost_expose":
			return Color(0.75, 0.92, 1.0)
	return data.color.lightened(0.18)

func _default_projectile_visual() -> StringName:
	match data.id:
		&"frost":
			return &"ice_shard"
	return &"orb"

func _build_placeholder_family_model(base_color: Color, scale_factor: float) -> void:
	match data.id:
		&"bolt":
			_build_bolt_model(base_color, scale_factor)
		&"cannon":
			_build_cannon_model(base_color, scale_factor)
		&"frost":
			_build_frost_model(base_color, scale_factor)
		_:
			_build_generic_model(base_color, scale_factor)

func _build_generic_model(base_color: Color, scale_factor: float) -> void:
	var base := CylinderMesh.new()
	base.top_radius = 0.45 * scale_factor
	base.bottom_radius = 0.55 * scale_factor
	base.height = 0.8 * scale_factor
	_base_mesh = Visuals.mesh_instance(base, base_color)
	_base_mesh.position.y = 0.4 * scale_factor
	add_child(_base_mesh)
	_head = Node3D.new()
	_head.position.y = 1.0 * scale_factor
	add_child(_head)
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.5, 0.35, 0.9) * scale_factor
	_body_mesh = Visuals.mesh_instance(head_mesh, data.color)
	_body_mesh.position.z = -0.1
	_head.add_child(_body_mesh)

func _build_bolt_model(base_color: Color, scale_factor: float) -> void:
	var base := CylinderMesh.new()
	base.top_radius = 0.38 * scale_factor
	base.bottom_radius = 0.5 * scale_factor
	base.height = 0.78 * scale_factor
	_base_mesh = Visuals.mesh_instance(base, base_color)
	_base_mesh.position.y = 0.39 * scale_factor
	add_child(_base_mesh)
	_head = Node3D.new()
	_head.position.y = 0.98 * scale_factor
	add_child(_head)
	var core_mesh := CylinderMesh.new()
	core_mesh.top_radius = 0.2 * scale_factor
	core_mesh.bottom_radius = 0.24 * scale_factor
	core_mesh.height = 0.42 * scale_factor
	_body_mesh = Visuals.mesh_instance(core_mesh, data.color)
	_body_mesh.rotation_degrees.z = 90
	_head.add_child(_body_mesh)
	var coil_mesh := BoxMesh.new()
	coil_mesh.size = Vector3(0.1, 0.36, 0.54) * scale_factor
	_coil_left_mesh = Visuals.mesh_instance(coil_mesh, base_color.lightened(0.08))
	_coil_left_mesh.position = Vector3(-0.22 * scale_factor, 0.0, -0.06 * scale_factor)
	_head.add_child(_coil_left_mesh)
	_coil_right_mesh = Visuals.mesh_instance(coil_mesh, base_color.lightened(0.08))
	_coil_right_mesh.position = Vector3(0.22 * scale_factor, 0.0, -0.06 * scale_factor)
	_head.add_child(_coil_right_mesh)
	var prong_mesh := BoxMesh.new()
	prong_mesh.size = Vector3(0.08, 0.08, 0.26) * scale_factor
	_barrel_mesh = Visuals.mesh_instance(prong_mesh, data.color.lightened(0.1))
	_barrel_mesh.position = Vector3(0, 0.0, -0.42 * scale_factor)
	_head.add_child(_barrel_mesh)

func _build_cannon_model(base_color: Color, scale_factor: float) -> void:
	var base := CylinderMesh.new()
	base.top_radius = 0.46 * scale_factor
	base.bottom_radius = 0.6 * scale_factor
	base.height = 0.86 * scale_factor
	_base_mesh = Visuals.mesh_instance(base, base_color)
	_base_mesh.position.y = 0.43 * scale_factor
	add_child(_base_mesh)
	_head = Node3D.new()
	_head.position.y = 1.02 * scale_factor
	add_child(_head)
	var cradle_mesh := BoxMesh.new()
	cradle_mesh.size = Vector3(0.56, 0.28, 0.42) * scale_factor
	_body_mesh = Visuals.mesh_instance(cradle_mesh, data.color.darkened(0.08))
	_head.add_child(_body_mesh)
	var barrel_mesh := BoxMesh.new()
	barrel_mesh.size = Vector3(0.22, 0.22, 0.92) * scale_factor
	_barrel_mesh = Visuals.mesh_instance(barrel_mesh, data.color)
	_barrel_mesh.position = Vector3(0, 0.04 * scale_factor, -0.54 * scale_factor)
	_head.add_child(_barrel_mesh)
	var tank_mesh := CylinderMesh.new()
	tank_mesh.top_radius = 0.1 * scale_factor
	tank_mesh.bottom_radius = 0.12 * scale_factor
	tank_mesh.height = 0.42 * scale_factor
	_tank_mesh = Visuals.mesh_instance(tank_mesh, Color(0.2, 0.2, 0.2, 1))
	_tank_mesh.position = Vector3(0, -0.1 * scale_factor, 0.2 * scale_factor)
	_tank_mesh.rotation_degrees.z = 90
	_head.add_child(_tank_mesh)

func _build_frost_model(base_color: Color, scale_factor: float) -> void:
	var base := CylinderMesh.new()
	base.top_radius = 0.42 * scale_factor
	base.bottom_radius = 0.52 * scale_factor
	base.height = 0.8 * scale_factor
	_base_mesh = Visuals.mesh_instance(base, base_color)
	_base_mesh.position.y = 0.4 * scale_factor
	add_child(_base_mesh)
	_head = Node3D.new()
	_head.position.y = 1.0 * scale_factor
	add_child(_head)
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.44, 0.34, 0.58) * scale_factor
	_body_mesh = Visuals.mesh_instance(body_mesh, data.color)
	_head.add_child(_body_mesh)
	var nozzle_mesh := BoxMesh.new()
	nozzle_mesh.size = Vector3(0.16, 0.16, 0.54) * scale_factor
	_barrel_mesh = Visuals.mesh_instance(nozzle_mesh, data.color.lightened(0.12))
	_barrel_mesh.position = Vector3(0, 0.02 * scale_factor, -0.42 * scale_factor)
	_head.add_child(_barrel_mesh)
	var tank_mesh := BoxMesh.new()
	tank_mesh.size = Vector3(0.22, 0.42, 0.24) * scale_factor
	_tank_mesh = Visuals.mesh_instance(tank_mesh, Color(0.74, 0.9, 1.0, 1.0))
	_tank_mesh.position = Vector3(0, 0.02 * scale_factor, 0.26 * scale_factor)
	_head.add_child(_tank_mesh)

func _trigger_visual_fire() -> void:
	_visual_recoil = 1.0

func _update_visual_feedback(delta: float) -> void:
	_visual_recoil = move_toward(_visual_recoil, 0.0, delta * 10.0)
	if _head == null:
		return
	match data.id:
		&"bolt":
			_update_bolt_feedback()
		&"cannon":
			_update_cannon_feedback()
		&"frost":
			_update_frost_feedback()

func _update_bolt_feedback() -> void:
	var r := _visual_recoil
	if _coil_left_mesh != null:
		_coil_left_mesh.scale = Vector3(1.0, 1.0 + r * 0.18, 1.0 + r * 0.1)
	if _coil_right_mesh != null:
		_coil_right_mesh.scale = Vector3(1.0, 1.0 + r * 0.18, 1.0 + r * 0.1)
	if _body_mesh != null:
		_body_mesh.scale = Vector3.ONE + Vector3(r * 0.08, r * 0.08, 0)
	if _barrel_mesh != null:
		_barrel_mesh.position.z = -0.42 * scale.x - r * 0.04

func _update_cannon_feedback() -> void:
	var r := _visual_recoil
	if _head != null:
		_head.position.z = -r * 0.12
	if _barrel_mesh != null:
		_barrel_mesh.position.z = -0.54 * scale.x + r * 0.1
	if _tank_mesh != null:
		_tank_mesh.scale = Vector3(1.0 + r * 0.04, 1.0 - r * 0.08, 1.0 + r * 0.04)

func _update_frost_feedback() -> void:
	var r := _visual_recoil
	if _head != null:
		_head.position.z = -r * 0.04
	if _barrel_mesh != null:
		_barrel_mesh.scale = Vector3(1.0, 1.0, 1.0 + r * 0.18)
		_barrel_mesh.position.z = -0.42 * scale.x - r * 0.03
	if _tank_mesh != null:
		_tank_mesh.scale = Vector3(1.0 + r * 0.06, 1.0 + r * 0.1, 1.0 + r * 0.06)
