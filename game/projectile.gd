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
var is_heavy_impact: bool = false
var can_home := true
var cosmetic_only := false

var _dir := Vector3.FORWARD
var _age := 0.0
var _hit_ids: Dictionary = {}
var _impact_visual_emitted := false

func setup(heavy_impact: bool = false) -> void:
	self.is_heavy_impact = heavy_impact

static func spawn_shot(b: Battle, from: Vector3, tgt: Enemy, cfg: Dictionary) -> void:
	var p := Projectile.new()
	p.battle = b
	p.target = tgt
	p.speed = cfg.get("speed", 12.0)
	p.damage = cfg.get("damage", 1.0)
	p.pierce = cfg.get("pierce", 0)
	p.opts = cfg
	p.setup(cfg.get("heavy_impact", false))
	p.can_home = cfg.get("can_home", true)
	p.position = from
	p._dir = (tgt.gameplay_pos() + Vector3(0, 0.5, 0) - from).normalized()
	p._add_mesh(cfg.get("color", Color.WHITE), cfg.get("radius", 0.12), cfg.get("projectile_visual", &"orb"))
	b.projectiles_root.add_child(p)

static func spawn_lightning_shot(b: Battle, from: Vector3, tgt: Enemy, cfg: Dictionary) -> void:
	if not is_instance_valid(tgt) or not tgt.is_alive():
		return
	var shot_damage: float = cfg.get("damage", 1.0)
	var hit_opts := cfg.duplicate()
	# Lightning is an immediate hit: there is no travel time or projectile body.
	b.apply_hit(tgt, shot_damage, hit_opts)
	b.spawn_lightning_arc(from, tgt.gameplay_pos() + Vector3(0, 0.5, 0), cfg.get("color", Color.WHITE), 0.10)
	var field_duration: float = cfg.get("field_duration", 0.0)
	var field_radius: float = cfg.get("field_radius", 0.0)
	var field_tick_interval: float = cfg.get("field_tick_interval", 0.0)
	var field_damage_factor: float = cfg.get("field_damage_factor", 0.0)
	if field_duration > 0.0 and field_radius > 0.0 and field_tick_interval > 0.0 and field_damage_factor > 0.0:
		b.spawn_lightning_field(
			tgt.gameplay_pos(),
			field_radius,
			field_duration,
			field_tick_interval,
			shot_damage * field_damage_factor,
			cfg.get("color", Color.WHITE)
		)

	var hit_ids := {tgt.get_instance_id(): true}
	var chain_count: int = cfg.get("chain_count", 0)
	var chain_range: float = cfg.get("chain_range", 1.8)
	var chain_factor: float = cfg.get("chain_damage_factor", 0.55)
	var previous_pos := tgt.gameplay_pos()
	for i in range(chain_count):
		var next := _pick_chain_target(b, previous_pos, chain_range, hit_ids)
		if next == null:
			break
		hit_ids[next.get_instance_id()] = true
		b.apply_hit(next, shot_damage * chain_factor, hit_opts)
		b.spawn_lightning_arc(previous_pos + Vector3(0, 0.5, 0), next.gameplay_pos() + Vector3(0, 0.5, 0), cfg.get("color", Color.WHITE), 0.12)
		previous_pos = next.gameplay_pos()

static func _pick_chain_target(b: Battle, origin: Vector3, max_range: float, hit_ids: Dictionary) -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for candidate in b.enemies:
		if not is_instance_valid(candidate) or not candidate.is_alive() or hit_ids.has(candidate.get_instance_id()):
			continue
		var distance := origin.distance_to(candidate.gameplay_pos())
		if distance > max_range:
			continue
		if distance < best_distance or (is_equal_approx(distance, best_distance) and candidate.spawn_index < best.spawn_index):
			best = candidate
			best_distance = distance
	return best

static func spawn_fortress_shot(b: Battle, from: Vector3, dmg: float, color: Color, radius: float = 0.16) -> void:
	var p := Projectile.new()
	p.battle = b
	p.hits_fortress = true
	p.speed = 8.0
	p.damage = dmg
	p.position = from
	p._dir = (ArenaLayout.FORTRESS_CENTER - from).normalized()
	p._add_mesh(color, radius, &"orb")
	b.projectiles_root.add_child(p)

func _add_mesh(color: Color, radius: float, visual: StringName = &"orb") -> void:
	match visual:
		&"guardian_comet":
			_add_guardian_comet_mesh(color, radius)
		&"impact_shell":
			_add_impact_shell_mesh(color, radius)
		&"ice_shard":
			_add_ice_shard_mesh(color, radius, 1.0)
		&"ice_shard_control":
			_add_ice_shard_mesh(color.lightened(0.04), radius * 1.08, 0.86)
		&"ice_shard_expose":
			_add_ice_shard_mesh(color.lightened(0.14), radius * 0.88, 1.32)
		_:
			var sphere := SphereMesh.new()
			sphere.radius = radius
			sphere.height = radius * 2.0
			add_child(Visuals.mesh_instance(sphere, color, true))

func _add_guardian_comet_mesh(color: Color, radius: float) -> void:
	var head := SphereMesh.new()
	head.radius = radius
	head.height = radius * 2.0
	var head_mi := Visuals.mesh_instance(head, Color(0.08, 0.08, 0.08), true)
	add_child(head_mi)
	var trail := CapsuleMesh.new()
	trail.radius = radius * 0.36
	trail.height = radius * 5.8
	var trail_mi := Visuals.mesh_instance(trail, color.lightened(0.32), true)
	trail_mi.rotation_degrees.x = 90.0
	trail_mi.position.z = radius * 1.9
	add_child(trail_mi)

func _add_impact_shell_mesh(color: Color, radius: float) -> void:
	var shell := SphereMesh.new()
	shell.radius = radius * 1.25
	shell.height = radius * 2.5
	var shell_mi := Visuals.mesh_instance(shell, color.darkened(0.12), true)
	add_child(shell_mi)
	var band := TorusMesh.new()
	band.inner_radius = radius * 0.72
	band.outer_radius = radius * 0.92
	var band_mi := Visuals.mesh_instance(band, color.lightened(0.28), true)
	band_mi.rotation_degrees.x = 90.0
	add_child(band_mi)

func _add_ice_shard_mesh(color: Color, radius: float, length_scale: float) -> void:
	var shard := PrismMesh.new()
	shard.left_to_right = radius * 1.7
	shard.size = Vector3(radius * 1.2, radius * 2.4, radius * 6.2 * length_scale)
	var shard_mi := Visuals.mesh_instance(shard, color, true)
	shard_mi.rotation_degrees.x = 90.0
	shard_mi.rotation_degrees.z = 90.0
	add_child(shard_mi)
	var core := SphereMesh.new()
	core.radius = radius * 0.45
	core.height = core.radius * 2.0
	var core_mi := Visuals.mesh_instance(core, color.lightened(0.20), true)
	core_mi.position.z = radius * 1.2
	add_child(core_mi)

func _physics_process(delta: float) -> void:
	_age += delta
	if _age > LIFETIME:
		queue_free()
		return
	var prev := position
	if hits_fortress:
		position += _dir * speed * delta
		if _segment_reaches_fortress(prev, position):
			battle.damage_fortress(damage)
			queue_free()
		return
	# Home while the locked target lives; fly straight afterwards.
	if can_home and is_instance_valid(target) and target.is_alive() and not _hit_ids.has(target.get_instance_id()):
		_dir = (target.gameplay_pos() + Vector3(0, 0.5, 0) - position).normalized()
	if _dir.length_squared() > 0.0001:
		look_at(position + _dir, Vector3.UP)
	prev = position
	position += _dir * speed * delta
	if cosmetic_only:
		for e in battle.enemies:
			if not is_instance_valid(e) or not e.is_alive():
				continue
			if _segment_hits_enemy(prev, position, e.gameplay_pos()):
				queue_free()
				return
		if absf(position.x) > ArenaLayout.HALF_WIDTH + 4.0 \
				or position.z < ArenaLayout.SPAWN_Z - 3.0 or position.z > 12.0:
			queue_free()
		return
	# Duplicate: apply_hit can synchronously erase killed enemies mid-loop.
	for e in battle.enemies.duplicate():
		if not is_instance_valid(e) or not e.is_alive():
			continue
		if _hit_ids.has(e.get_instance_id()):
			continue
		if _segment_hits_enemy(prev, position, e.gameplay_pos()):
			_hit_ids[e.get_instance_id()] = true
			var impact_pos: Vector3 = e.gameplay_pos()
			var hit_opts := opts.duplicate()
			hit_opts["heavy_impact"] = self.is_heavy_impact
			battle.apply_hit(e, damage, hit_opts)
			battle.apply_impact_payload(e, prev, hit_opts)
			if not _impact_visual_emitted and opts.get("impact_visual", &"none") == &"splash_ring":
				_impact_visual_emitted = true
				battle.spawn_weapon_impact(impact_pos, opts.get("color", Color.WHITE), opts.get("splash_radius", 0.0))
			if StringName(opts.get("projectile_visual", &"")) == &"ice_shard_control":
				battle.spawn_frost_pulse(e.gameplay_pos(), opts.get("color", Color.WHITE), 0.55, 0.12)
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
