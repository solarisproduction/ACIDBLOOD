class_name Turret
extends Node3D
## Turret runtime. One script for all archetypes; splash and slow behavior
## comes from TurretData. Stats resolve through Battle.stat() using the
## "turret.<id>.<stat>" path so upgrade cards affect every built instance.

func refresh_branch_visual() -> void:
	queue_free_children()
	_build_model()

var battle: Battle
var data: TurretData
var _cooldown := 0.0
var _head: Node3D

func setup(b: Battle, d: TurretData) -> void:
	battle = b
	data = d
	refresh_branch_visual()

func get_active_branch() -> TurretBranchData:
	var branch_id = battle.run_state.branch_for(data.id)
	if branch_id != "":
		return Catalog.turret_branch(branch_id)
	return null

func _stat(local: String, base: float) -> float:
	return battle.stat(StringName("turret.%s.%s" % [data.id, local]), base)

func _physics_process(delta: float) -> void:
	_cooldown -= delta
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
	Projectile.spawn_shot(battle, global_position + Vector3(0, 1.1, 0), target, {
		"damage": _stat("damage", data.damage),
		"speed": _stat("projectile_speed", data.projectile_speed),
		"splash_radius": _stat("splash_radius", data.splash_radius),
		"slow_factor": _stat("slow_factor", data.slow_factor),
		"slow_duration": _stat("slow_duration", data.slow_duration),
		"color": data.color,
		"radius": 0.14,
	})

func _build_model() -> void:
	if data.model_scene != null:
		add_child(data.model_scene.instantiate())
		return
	
	var branch = get_active_branch()
	var base_color = Color(0.4, 0.42, 0.48)
	var scale_factor = 1.0
	if branch != null:
		base_color = Color(0.0, 1.0, 0.0)  # Change to green if a branch is active
		scale_factor = 1.1  # Slightly increase the scale
	
	var base := CylinderMesh.new()
	base.top_radius = 0.45 * scale_factor
	base.bottom_radius = 0.55 * scale_factor
	base.height = 0.8 * scale_factor
	var base_mi := Visuals.mesh_instance(base, base_color)
	base_mi.position.y = 0.4 * scale_factor
	add_child(base_mi)
	
	_head = Node3D.new()
	_head.position.y = 1.0 * scale_factor
	add_child(_head)
	
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.5, 0.35, 0.9) * scale_factor
	var head_mi := Visuals.mesh_instance(head_mesh, data.color)
	head_mi.position.z = -0.1
	_head.add_child(head_mi)
