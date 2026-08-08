class_name Guardian
extends Node3D
## Player-controlled Guardian: horizontal movement (keyboard + pointer),
## deterministic auto-targeting and auto-fire. All combat numbers resolve
## through Battle.stat() so cards and permanent upgrades apply uniformly.

var battle: Battle
var data: GuardianData
var _cooldown := 0.0

@onready var model: Node3D = $Model
@onready var muzzle: Marker3D = $Muzzle

func setup(b: Battle, d: GuardianData) -> void:
	battle = b
	data = d
	position = Vector3(0, 0, ArenaLayout.GUARDIAN_Z)
	for mi in model.find_children("*", "MeshInstance3D"):
		(mi as MeshInstance3D).material_override = Visuals.mat(d.color)

func move_speed() -> float:
	return battle.stat(&"guardian.move_speed", data.move_speed)

func _physics_process(delta: float) -> void:
	_move(delta)
	_combat(delta)

func _move(delta: float) -> void:
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
			position.x = move_toward(position.x, target_x, step)
	position.x = clampf(position.x, -ArenaLayout.GUARDIAN_X_LIMIT, ArenaLayout.GUARDIAN_X_LIMIT)

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
	var w := data.weapon
	var attack_range := battle.stat(&"guardian.range", w.attack_range)
	var target := Targeting.pick_target(battle.enemies, position, attack_range) as Enemy
	if target != null:
		var aim := target.gameplay_pos()
		var look := Vector3(aim.x, global_position.y, aim.z)
		if not look.is_equal_approx(global_position):
			model.look_at(look)
	if target == null or _cooldown > 0.0:
		return
	_cooldown = maxf(0.05, battle.stat(&"guardian.attack_interval", w.attack_interval))
	_fire(target, w)

func _fire(target: Enemy, w: WeaponData) -> void:
	var count := int(battle.stat(&"guardian.projectiles", float(w.projectile_count)))
	var cfg := {
		"damage": battle.stat(&"guardian.damage", w.damage),
		"speed": w.projectile_speed,
		"pierce": int(battle.stat(&"guardian.pierce", float(w.pierce))),
		"color": w.projectile_color,
	}
	var base_dir := (target.gameplay_pos() - muzzle.global_position)
	base_dir.y = 0.0
	base_dir = base_dir.normalized()
	for i in count:
		var angle := deg_to_rad(w.spread_degrees) * (i - (count - 1) * 0.5)
		var p := Projectile.new()
		p.battle = battle
		p.target = target if count == 1 else null
		p.speed = cfg.speed
		p.damage = cfg.damage
		p.pierce = cfg.pierce
		p.opts = cfg
		p.position = muzzle.global_position
		p._dir = base_dir.rotated(Vector3.UP, angle)
		p._add_mesh(cfg.color, 0.12)
		battle.projectiles_root.add_child(p)
