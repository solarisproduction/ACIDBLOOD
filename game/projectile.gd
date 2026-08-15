class_name Projectile
extends Node3D
## Lightweight projectile: no physics body, distance-based hit resolution
## against the battle's enemy registry (or the fortress for enemy shots).
## Homes on its target while the target lives; after a pierce hit it
## continues in a straight line.

const HIT_RADIUS := 0.4
const LIFETIME := 5.0

var battle: Battle
var speed := 12.0
var damage := 1.0
var pierce := 0
var opts: Dictionary = {}     # splash_radius / slow_factor / slow_duration
var target: Enemy = null
var hits_fortress := false

var _dir := Vector3.FORWARD
var _age := 0.0
var _hit_ids: Dictionary = {}

static func spawn_shot(b: Battle, from: Vector3, tgt: Enemy, cfg: Dictionary) -> void:
	var p := Projectile.new()
	p.battle = b
	p.target = tgt
	p.speed = cfg.get("speed", 12.0)
	p.damage = cfg.get("damage", 1.0)
	p.pierce = cfg.get("pierce", 0)
	p.opts = cfg
	p.position = from
	p._dir = (tgt.gameplay_pos() + Vector3(0, 0.5, 0) - from).normalized()
	p._add_mesh(cfg.get("color", Color.WHITE), cfg.get("radius", 0.12))
	b.projectiles_root.add_child(p)

static func spawn_fortress_shot(b: Battle, from: Vector3, dmg: float, color: Color) -> void:
	var p := Projectile.new()
	p.battle = b
	p.hits_fortress = true
	p.speed = 8.0
	p.damage = dmg
	p.position = from
	p._dir = (ArenaLayout.FORTRESS_CENTER - from).normalized()
	p._add_mesh(color, 0.16)
	b.projectiles_root.add_child(p)

func _add_mesh(color: Color, radius: float) -> void:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	add_child(Visuals.mesh_instance(sphere, color, true))

func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	if hits_fortress:
		var prev := position
		position += _dir * speed * delta
		if _segment_reaches_fortress(prev, position):
			battle.damage_fortress(damage)
			queue_free()
		return
	# Home while the locked target lives; fly straight afterwards.
	if is_instance_valid(target) and target.is_alive() and not _hit_ids.has(target.get_instance_id()):
		_dir = (target.gameplay_pos() + Vector3(0, 0.5, 0) - position).normalized()
	var prev := position
	position += _dir * speed * delta
	# Duplicate: apply_hit can synchronously erase killed enemies mid-loop.
	for e in battle.enemies.duplicate():
		if not is_instance_valid(e) or not e.is_alive():
			continue
		if _hit_ids.has(e.get_instance_id()):
			continue
		if _segment_hits_enemy(prev, position, e.gameplay_pos()):
			_hit_ids[e.get_instance_id()] = true
			battle.apply_hit(e, damage, opts)
			if pierce <= 0:
				queue_free()
				return
			pierce -= 1
	if absf(position.x) > ArenaLayout.HALF_WIDTH + 4.0 \
			or position.z < ArenaLayout.SPAWN_Z - 3.0 or position.z > 12.0:
		queue_free()

static func _segment_hits_enemy(from: Vector3, to: Vector3, enemy_pos: Vector3) -> bool:
	return _point_segment_distance_sq_xz(enemy_pos, from, to) <= HIT_RADIUS * HIT_RADIUS

static func _segment_reaches_fortress(from: Vector3, to: Vector3) -> bool:
	return _point_segment_distance_sq_xz(ArenaLayout.FORTRESS_CENTER, from, to) <= 0.16

static func _point_segment_distance_sq_xz(point: Vector3, from: Vector3, to: Vector3) -> float:
	var seg := Vector2(to.x - from.x, to.z - from.z)
	var rel := Vector2(point.x - from.x, point.z - from.z)
	var len_sq := seg.length_squared()
	if len_sq <= 0.000001:
		return rel.length_squared()
	var t := clampf(rel.dot(seg) / len_sq, 0.0, 1.0)
	var closest := Vector2(from.x, from.z) + seg * t
	var dx := point.x - closest.x
	var dz := point.z - closest.y
	return dx * dx + dz * dz
