class_name Enemy
extends Node3D
## Enemy runtime. One script for all archetypes; behavior comes from EnemyData
## (kamikaze vs ranged/attacker is data: attack_interval + stop_range).
## Placeholder model is generated from data unless data.model_scene is set.

const HP_BAR_WIDTH := 0.9

var battle: Battle
var data: EnemyData
var spawn_index := 0
var hp := 0.0
var max_hp := 0.0

var _speed_scale := 1.0
var _slow_factor := 1.0
var _slow_time := 0.0
var _attack_timer := 0.0
var _dead := false
var _hp_fill: MeshInstance3D

@onready var model_root: Node3D = $ModelRoot

func setup(b: Battle, d: EnemyData, index: int, x: float, hp_scale: float, speed_scale: float) -> void:
	battle = b
	data = d
	spawn_index = index
	_speed_scale = speed_scale
	max_hp = d.max_hp * hp_scale
	hp = max_hp
	_attack_timer = d.attack_interval
	position = Vector3(x, 0.0, ArenaLayout.SPAWN_Z)
	_build_model()
	_build_hp_bar()

# --- Rules interface (consumed by core/targeting.gd and Battle) ---------

func gameplay_pos() -> Vector3:
	return position

func is_alive() -> bool:
	return not _dead

func armor() -> float:
	return data.armor

func take_damage(amount: float) -> void:
	if _dead:
		return
	hp -= amount
	_update_hp_bar()
	if hp <= 0.0:
		_die(true)

func apply_slow(factor: float, duration: float) -> void:
	_slow_factor = minf(_slow_factor, factor)
	_slow_time = maxf(_slow_time, duration)

# --- Behavior -----------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _slow_time > 0.0:
		_slow_time -= delta
		if _slow_time <= 0.0:
			_slow_factor = 1.0
	var stop_z := ArenaLayout.FORTRESS_LINE_Z - data.stop_range
	if position.z < stop_z:
		var step := data.speed * _speed_scale * _slow_factor * delta
		position.z = minf(position.z + step, stop_z)
		return
	if data.attack_interval > 0.0:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer += data.attack_interval
			Projectile.spawn_fortress_shot(battle, gameplay_pos() + Vector3(0, 0.8, 0), data.fortress_damage, data.color)
	else:
		battle.damage_fortress(data.fortress_damage)
		_die(false)

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
		return
	var mesh: Mesh
	match data.shape:
		1:
			var cap := CapsuleMesh.new()
			cap.radius = 0.35
			cap.height = 1.0
			mesh = cap
		2:
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.4
			cyl.bottom_radius = 0.5
			cyl.height = 1.0
			mesh = cyl
		3:
			var sph := SphereMesh.new()
			sph.radius = 0.5
			sph.height = 1.0
			mesh = sph
		_:
			var box := BoxMesh.new()
			box.size = Vector3.ONE
			mesh = box
	var mi := Visuals.mesh_instance(mesh, data.color)
	mi.position.y = 0.5
	model_root.add_child(mi)
	model_root.scale = data.body_scale

func _build_hp_bar() -> void:
	var height := data.body_scale.y + 0.5
	var bar := Node3D.new()
	bar.name = "HPBar"
	bar.position = Vector3(0, height, 0)
	add_child(bar)
	var bg := MeshInstance3D.new()
	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(HP_BAR_WIDTH, 0.12)
	bg.mesh = bg_mesh
	bg.material_override = _bar_material(Color(0.1, 0.1, 0.1, 0.85), 0)
	bar.add_child(bg)
	_hp_fill = MeshInstance3D.new()
	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(HP_BAR_WIDTH, 0.08)
	_hp_fill.mesh = fill_mesh
	_hp_fill.material_override = _bar_material(Color(0.35, 0.9, 0.3, 0.95), 1)
	bar.add_child(_hp_fill)

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
	_hp_fill.position.x = -HP_BAR_WIDTH * 0.5 * (1.0 - ratio)
