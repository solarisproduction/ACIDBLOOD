extends SceneTree
## Prints every balance-relevant number from the data catalog in one place.
## Run: godot --headless --path . --script res://tools/balance_report.gd

func _initialize() -> void:
	var g := Catalog.guardian()
	var w := g.weapon
	print("=== SHARED TUNING ===")
	print("  arena half_width=%.1f spawn_z=%.1f fortress_line_z=%.1f guardian_z=%.1f spawn_x_range=%.1f" %
		[ArenaLayout.HALF_WIDTH, ArenaLayout.SPAWN_Z, ArenaLayout.FORTRESS_LINE_Z, ArenaLayout.GUARDIAN_Z, ArenaLayout.SPAWN_X_RANGE])
	print("  combat min_damage=%.2f min_attack_interval=%.2f" %
		[Combat.MIN_DAMAGE, Combat.MIN_ATTACK_INTERVAL])
	print("=== GUARDIAN ===")
	print("  move_speed=%.1f  damage=%.1f  interval=%.2f  range=%.1f  proj_speed=%.1f" %
		[g.move_speed, w.damage, w.attack_interval, w.attack_range, w.projectile_speed])
	print("=== FORTRESS ===")
	print("  base_max_hp=%.0f (StageData.fortress_hp, stage 1 shown)" % Catalog.stage_by_index(1).fortress_hp)
	print("=== XP CURVE (level: xp to next) ===")
	var curve := ""
	for lvl in range(1, 11):
		curve += "%d:%d  " % [lvl, Leveling.xp_required(lvl)]
	print("  " + curve)
	print("=== ENEMIES ===")
	for id in Catalog.enemies():
		var e: EnemyData = Catalog.enemy(id)
		print("  %-12s hp=%-6.1f speed=%-4.1f armor=%-4.1f xp=%-3d fort_dmg=%-5.1f atk_int=%-4.1f stop=%-4.1f boss=%s" %
			[e.id, e.max_hp, e.speed, e.armor, e.xp, e.fortress_damage, e.attack_interval, e.stop_range, e.is_boss])
	print("=== TURRETS ===")
	for id in Catalog.turrets():
		var t: TurretData = Catalog.turret(id)
		print("  %-8s dmg=%-5.1f interval=%-5.2f range=%-4.1f splash=%-4.1f slow=%.2f/%.1fs" %
			[t.id, t.damage, t.attack_interval, t.attack_range, t.splash_radius, t.slow_factor, t.slow_duration])
	print("=== CARDS ===")
	for c in Catalog.cards():
		var bits := []
		for eff in c.effects:
			bits.append("%s %s %s%.2f" % [CardEffect.Op.keys()[eff.op], eff.stat if eff.stat else eff.target,
				"x" if eff.op == CardEffect.Op.MULTIPLY_STAT else "+", eff.value])
		print("  %-18s cat=%-9s role=%-8s w=%-4.0f stacks=%d pre=%s excl=%s lock=%s :: %s" %
			[c.id, Draft.card_category(c), Draft.card_role(c), c.weight, c.max_stacks, c.prerequisites, c.excludes, c.requires_unlock, ", ".join(bits)])
	print("=== CARD SUMMARY ===")
	var categories := {}
	var roles := {}
	for c in Catalog.cards():
		var category := String(Draft.card_category(c))
		var role := String(Draft.card_role(c))
		categories[category] = int(categories.get(category, 0)) + 1
		roles[role] = int(roles.get(role, 0)) + 1
	print("  by category: %s" % categories)
	print("  by role: %s" % roles)
	print("=== PERMANENT UPGRADES ===")
	for up in Catalog.perm_upgrades():
		print("  %-18s max=%d cost=%d+%d/lvl stat=%s +%.1f/lvl flag=%s" %
			[up.id, up.max_level, up.base_cost, up.cost_step, up.stat, up.value_per_level, up.unlock_flag])
	print("=== STAGES ===")
	for s in Catalog.stages():
		var enemy_total := 0
		var total_xp := 0
		var wave_bits := []
		for wave in s.waves:
			var wave_enemies := 0
			var wave_xp := 0
			for grp in wave.groups:
				enemy_total += grp.count
				wave_enemies += grp.count
				var enemy := Catalog.enemy(grp.enemy_id)
				if enemy != null:
					wave_xp += grp.count * enemy.xp
			total_xp += wave_xp
			wave_bits.append("W%d:%de/%dxp" % [wave_bits.size() + 1, wave_enemies, wave_xp])
		var level_ups := _project_level_ups(total_xp)
		print("  %02d %-14s waves=%d enemies=%-3d xp=%-3d lvl_ups=%-2d hp_scale=%.2f speed_scale=%.2f reward=%d :: %s" %
			[s.index, s.display_name, s.waves.size(), enemy_total, total_xp, level_ups, s.hp_scale, s.speed_scale, s.reward_cores, " ".join(wave_bits)])
	quit(0)

func _project_level_ups(total_xp: int) -> int:
	var level := 1
	var xp := total_xp
	var ups := 0
	while xp >= Leveling.xp_required(level):
		xp -= Leveling.xp_required(level)
		level += 1
		ups += 1
	return ups
