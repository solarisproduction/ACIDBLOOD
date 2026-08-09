extends SceneTree
## Headless test/validation suite (no framework dependency).
## Run: godot --headless --path . --script res://tests/run_tests.gd
## Exits non-zero on any failure.

var _failures := 0
var _checks := 0

func _initialize() -> void:
	test_scripts_and_scenes_load()
	test_rng_determinism()
	test_draft_determinism()
	test_draft_rules()
	test_leveling_and_run_state()
	test_combat()
	test_stat_registry()
	test_progression_save_load()
	test_campaign_data()
	test_data_references()
	print("")
	if _failures > 0:
		print("TESTS FAILED: %d of %d checks failed" % [_failures, _checks])
		quit(1)
	else:
		print("ALL TESTS PASSED (%d checks)" % _checks)
		quit(0)

func check(name: String, cond: bool) -> void:
	_checks += 1
	if cond:
		print("  PASS  %s" % name)
	else:
		_failures += 1
		print("  FAIL  %s" % name)

# ------------------------------------------------------------------

func test_scripts_and_scenes_load() -> void:
	print("[scripts/scenes]")
	var roots := ["res://core", "res://data/types", "res://game", "res://shell", "res://autoload", "res://tools"]
	var bad := []
	for root in roots:
		var dir := DirAccess.open(root)
		if dir == null:
			bad.append(root)
			continue
		for f in dir.get_files():
			if f.ends_with(".gd"):
				var scr: Script = load(root.path_join(f))
				if scr == null or not scr.can_instantiate():
					bad.append(root.path_join(f))
			elif f.ends_with(".tscn"):
				var ps: PackedScene = load(root.path_join(f))
				if ps == null:
					bad.append(root.path_join(f))
	check("all scripts parse and all scenes load (%s)" % [",".join(bad) if bad else "ok"], bad.is_empty())

func test_rng_determinism() -> void:
	print("[rng]")
	var a := DetRNG.new(42)
	var b := DetRNG.new(42)
	var same := true
	for i in 50:
		if a.randf() != b.randf() or a.randi_range(0, 1000) != b.randi_range(0, 1000):
			same = false
			break
	check("same seed produces identical stream", same)
	var c := DetRNG.new(42)
	var d := DetRNG.new(43)
	var diff := false
	for i in 20:
		if c.randf() != d.randf():
			diff = true
			break
	check("different seed produces different stream", diff)
	check("derive() is stable", DetRNG.derive(7, "draft", 3) == DetRNG.derive(7, "draft", 3))
	check("derive() separates salts", DetRNG.derive(7, "draft", 3) != DetRNG.derive(7, "waves", 3))

func _card_ids(cards: Array[CardData]) -> Array:
	var out := []
	for c in cards:
		out.append(c.id)
	return out

func test_draft_determinism() -> void:
	print("[draft determinism]")
	var catalog := Catalog.cards()
	var ctx := {"acquired": {}, "unlocks": {}, "blocked": []}
	var offer1 := Draft.generate_offer(catalog, ctx, DetRNG.new(DetRNG.derive(1337, "draft", 1)))
	var offer2 := Draft.generate_offer(catalog, ctx, DetRNG.new(DetRNG.derive(1337, "draft", 1)))
	check("same seed + state => same offer", _card_ids(offer1) == _card_ids(offer2))
	check("offer has 3 cards", offer1.size() == 3)
	var found_different := false
	for s in range(2, 30):
		var other := Draft.generate_offer(catalog, ctx, DetRNG.new(DetRNG.derive(s, "draft", 1)))
		if _card_ids(other) != _card_ids(offer1):
			found_different = true
			break
	check("different seeds can produce different offers", found_different)
	var no_dupes := true
	for s in 40:
		var offer := Draft.generate_offer(catalog, ctx, DetRNG.new(s))
		var ids := _card_ids(offer)
		for id in ids:
			if ids.count(id) > 1:
				no_dupes = false
	check("no duplicate cards in any single offer (40 seeds)", no_dupes)

func test_draft_rules() -> void:
	print("[draft rules]")
	var catalog := Catalog.cards()
	# Prerequisites: bolt_overcharge must never appear without build_bolt.
	var prereq_ok := true
	for s in 60:
		var offer := Draft.generate_offer(catalog, {"acquired": {}, "unlocks": {}, "blocked": []}, DetRNG.new(s))
		if _card_ids(offer).has(&"bolt_overcharge"):
			prereq_ok = false
	check("prerequisite card never offered before its chain parent", prereq_ok)
	# With the prerequisite acquired it becomes eligible.
	var ctx_with := {"acquired": {&"build_bolt": 1}, "unlocks": {}, "blocked": []}
	check("prerequisite card eligible after parent acquired",
		Draft.is_eligible(Catalog.card(&"bolt_overcharge"), ctx_with))
	# Exclusions: overload_core blocks bastion_core and vice versa.
	check("exclusion blocks branched card",
		not Draft.is_eligible(Catalog.card(&"bastion_core"), {"acquired": {&"overload_core": 1}, "unlocks": {}, "blocked": []}))
	# Acquisition limits.
	check("max_stacks blocks exhausted card",
		not Draft.is_eligible(Catalog.card(&"overload_core"), {"acquired": {&"overload_core": 1}, "unlocks": {}, "blocked": []}))
	# Permanent unlock gating.
	check("locked card ineligible without permanent unlock",
		not Draft.is_eligible(Catalog.card(&"build_frost"), {"acquired": {}, "unlocks": {}, "blocked": []}))
	check("locked card eligible with permanent unlock",
		Draft.is_eligible(Catalog.card(&"build_frost"), {"acquired": {}, "unlocks": {&"frost_turret": true}, "blocked": []}))
	# Runtime blocking (e.g. slots full).
	check("blocked list removes card",
		not Draft.is_eligible(Catalog.card(&"build_bolt"), {"acquired": {}, "unlocks": {}, "blocked": [&"build_bolt"]}))

func test_leveling_and_run_state() -> void:
	print("[leveling/run state]")
	var monotonic := true
	for lvl in range(1, 30):
		if Leveling.xp_required(lvl + 1) <= Leveling.xp_required(lvl):
			monotonic = false
	check("xp curve is monotonically increasing", monotonic)
	var rs := RunState.new()
	var ups := rs.grant_xp(Leveling.xp_required(1) + Leveling.xp_required(2))
	check("grant_xp triggers chained level-ups", ups == 2 and rs.level == 3)
	rs.mods.add_flat(&"fortress.max_hp", 30.0)
	check("fortress max hp respects modifiers", rs.fortress_max_hp() == 130.0)
	var ms := ModifierSet.new()
	ms.add_flat(&"x", 2.0)
	ms.multiply(&"x", 1.5)
	check("modifier math: (base+add)*mult", is_equal_approx(ms.value(&"x", 4.0), 9.0))

func test_combat() -> void:
	print("[combat]")
	check("armor reduces damage", Combat.damage_after_armor(10.0, 3.0) == 7.0)
	check("damage floor holds", Combat.damage_after_armor(2.0, 50.0) == Combat.MIN_DAMAGE)

func test_stat_registry() -> void:
	print("[stat registry]")
	check("known guardian stat valid", StatRegistry.is_valid(&"guardian.damage"))
	check("known fortress stat valid", StatRegistry.is_valid(&"fortress.max_hp"))
	check("known turret stat valid", StatRegistry.is_valid(&"turret.cannon.splash_radius"))
	check("guardian typo rejected", not StatRegistry.is_valid(&"guardian.damge"))
	check("unknown turret rejected", not StatRegistry.is_valid(&"turret.fake.damage"))
	check("unknown turret stat rejected", not StatRegistry.is_valid(&"turret.bolt.fake_stat"))

func test_progression_save_load() -> void:
	print("[progression save/load]")
	var path := "user://test_save_tmp.json"
	var p := Progression.new()
	p.cores = 17
	p.completed_stages = ["stage_001", "stage_002"]
	p.upgrade_levels = {"guardian_core": 2, "frost_protocol": 1}
	check("save() succeeds", p.save(path))
	var q := Progression.load_or_new(path)
	check("cores survive save/load", q.cores == 17)
	check("campaign progress survives save/load", q.completed_stages == ["stage_001", "stage_002"])
	check("permanent upgrades survive save/load",
		q.upgrade_level(&"guardian_core") == 2 and q.upgrade_level(&"frost_protocol") == 1)
	var flags := q.unlock_flags(Catalog.perm_upgrades())
	check("unlock flags derived from saved upgrades", bool(flags.get(&"frost_turret", false)))
	check("upgrade stat bonus computed",
		q.upgrade_stat_bonus(Catalog.perm_upgrades(), &"guardian.damage") == 2.0)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_campaign_data() -> void:
	print("[campaign]")
	var stages := Catalog.stages()
	check("campaign has 30 stages", stages.size() == 30)
	var indices_ok := true
	for i in stages.size():
		if stages[i].index != i + 1:
			indices_ok = false
	check("stage indices are 1..30 in order", indices_ok)
	var ids := Catalog.ordered_stage_ids()
	check("stage ids unique", ids.size() == 30)
	var p := Progression.new()
	check("stage 1 unlocked from start", p.is_stage_unlocked(0, ids))
	check("stage 2 locked from start", not p.is_stage_unlocked(1, ids))
	p.apply_victory(ids[0], 5)
	check("completing stage 1 unlocks stage 2", p.is_stage_unlocked(1, ids))
	check("stage 3 still locked", not p.is_stage_unlocked(2, ids))
	var first := p.cores
	var repeat_award := p.apply_victory(ids[0], 5)
	check("repeat clear pays reduced reward", repeat_award < 5 and repeat_award > 0 and p.cores == first + repeat_award)
	# Developer traversal: sequentially auto-win every stage; the whole
	# campaign must unlock in order and survive a save/load round trip.
	var t := Progression.new()
	var traversal_ok := true
	for i in stages.size():
		if not t.is_stage_unlocked(i, ids):
			traversal_ok = false
			break
		t.apply_victory(ids[i], stages[i].reward_cores)
	var path := "user://test_campaign_tmp.json"
	t.save(path)
	var t2 := Progression.load_or_new(path)
	check("auto-win traversal unlocks all 30 stages in order", traversal_ok and t.completed_stages.size() == 30)
	check("full campaign completion survives save/load", t2.completed_stages.size() == 30 and t2.cores == t.cores)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_data_references() -> void:
	print("[data references]")
	var bad := []
	for stage in Catalog.stages():
		if stage.waves.is_empty():
			bad.append("%s has no waves" % stage.id)
		for wave in stage.waves:
			if wave.groups.is_empty():
				bad.append("%s has empty wave" % stage.id)
			for g in wave.groups:
				if Catalog.enemy(g.enemy_id) == null:
					bad.append("%s references unknown enemy %s" % [stage.id, g.enemy_id])
				if g.count <= 0:
					bad.append("%s group with count<=0" % stage.id)
	check("all stage/wave/enemy references resolve (%s)" % [",".join(bad) if bad else "ok"], bad.is_empty())
	bad = []
	var card_ids := []
	for card in Catalog.cards():
		card_ids.append(card.id)
	for card in Catalog.cards():
		for pre in card.prerequisites:
			if not card_ids.has(pre):
				bad.append("%s prereq %s missing" % [card.id, pre])
		for ex in card.excludes:
			if not card_ids.has(ex):
				bad.append("%s exclude %s missing" % [card.id, ex])
		for eff in card.effects:
			match eff.op:
				CardEffect.Op.ADD_STAT, CardEffect.Op.MULTIPLY_STAT:
					if eff.stat == &"":
						bad.append("%s stat effect without stat" % card.id)
					elif not StatRegistry.is_valid(eff.stat):
						bad.append("%s invalid stat %s" % [card.id, eff.stat])
				CardEffect.Op.UNLOCK_TURRET:
					if Catalog.turret(eff.target) == null:
						bad.append("%s unlocks unknown turret %s" % [card.id, eff.target])
	for up in Catalog.perm_upgrades():
		if up.stat != &"" and not StatRegistry.is_valid(up.stat):
			bad.append("%s invalid permanent stat %s" % [up.id, up.stat])
	check("card + permanent stat graph valid (%s)" % [",".join(bad) if bad else "ok"], bad.is_empty())
	check("at least 4 enemy archetypes", Catalog.enemies().size() >= 4)
	check("at least 3 turret archetypes", Catalog.turrets().size() >= 3)
	check("guardian data + weapon present", Catalog.guardian() != null and Catalog.guardian().weapon != null)
	check("3 permanent upgrades", Catalog.perm_upgrades().size() == 3)
