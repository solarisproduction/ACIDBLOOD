extends SceneTree
## Prints every balance-relevant number from the data catalog in one place.
## Run: godot --headless --path . --script res://tools/balance_report.gd

func _initialize() -> void:
	var g := Catalog.guardian()
	var w := g.weapon
	print("=== GUARDIAN ===")
	print("  move_speed=%.1f  damage=%.1f  interval=%.2f  range=%.1f  proj_speed=%.1f" %
		[g.move_speed, w.damage, w.attack_interval, w.attack_range, w.projectile_speed])
	print("=== FORTRESS ===")
	print("  base_max_hp=%.0f" % RunState.new().fortress_base_max_hp)
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
		print("  %-18s w=%-4.0f stacks=%d pre=%s excl=%s lock=%s :: %s" %
			[c.id, c.weight, c.max_stacks, c.prerequisites, c.excludes, c.requires_unlock, ", ".join(bits)])
	print("=== PERMANENT UPGRADES ===")
	for up in Catalog.perm_upgrades():
		print("  %-18s max=%d cost=%d+%d/lvl stat=%s +%.1f/lvl flag=%s" %
			[up.id, up.max_level, up.base_cost, up.cost_step, up.stat, up.value_per_level, up.unlock_flag])
	print("=== STAGES ===")
	for s in Catalog.stages():
		var enemy_total := 0
		for wave in s.waves:
			for grp in wave.groups:
				enemy_total += grp.count
		print("  %02d %-14s waves=%d enemies=%-3d hp_scale=%.2f speed_scale=%.2f reward=%d" %
			[s.index, s.display_name, s.waves.size(), enemy_total, s.hp_scale, s.speed_scale, s.reward_cores])
	quit(0)
