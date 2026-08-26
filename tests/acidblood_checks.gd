@tool
class_name AcidbloodChecks
extends RefCounted

func run_all(sink) -> void:
	run_scripts_and_scenes_load(sink)
	run_rng_determinism(sink)
	run_draft_determinism(sink)
	run_draft_rules(sink)
	run_leveling_and_run_state(sink)
	run_slot_ordering(sink)
	run_combat(sink)
	run_stat_registry(sink)
	run_progression_save_load(sink)
	run_campaign_data(sink)
	run_data_references(sink)
	run_content_conventions(sink)

static func scratch_path(filename: String) -> String:
	var temp_root := OS.get_environment("TMPDIR")
	if temp_root.is_empty():
		temp_root = "/tmp"
	return temp_root.path_join(filename)

func _card_ids(cards: Array[CardData]) -> Array:
	var out := []
	for c in cards:
		out.append(c.id)
	return out

func run_scripts_and_scenes_load(sink) -> void:
	sink.section("scripts/scenes")
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
				if scr == null:
					bad.append(root.path_join(f))
			elif f.ends_with(".tscn"):
				var ps: PackedScene = load(root.path_join(f))
				if ps == null:
					bad.append(root.path_join(f))
	sink.check("all scripts parse and all scenes load (%s)" % [",".join(bad) if bad else "ok"], bad.is_empty())

func run_rng_determinism(sink) -> void:
	sink.section("rng")
	var a := DetRNG.new(42)
	var b := DetRNG.new(42)
	var same := true
	for i in 50:
		if a.randf() != b.randf() or a.randi_range(0, 1000) != b.randi_range(0, 1000):
			same = false
			break
	sink.check("same seed produces identical stream", same)
	var c := DetRNG.new(42)
	var d := DetRNG.new(43)
	var diff := false
	for i in 20:
		if c.randf() != d.randf():
			diff = true
			break
	sink.check("different seed produces different stream", diff)
	sink.check("derive() is stable", DetRNG.derive(7, "draft", 3) == DetRNG.derive(7, "draft", 3))
	sink.check("derive() separates salts", DetRNG.derive(7, "draft", 3) != DetRNG.derive(7, "waves", 3))

func run_draft_determinism(sink) -> void:
	sink.section("draft determinism")
	var catalog := Catalog.cards()
	var ctx := {"acquired": {}, "unlocks": {}, "blocked": []}
	var offer1 := Draft.generate_offer(catalog, ctx, DetRNG.new(DetRNG.derive(1337, "draft", 1)))
	var offer2 := Draft.generate_offer(catalog, ctx, DetRNG.new(DetRNG.derive(1337, "draft", 1)))
	sink.check("same seed + state => same offer", _card_ids(offer1) == _card_ids(offer2))
	sink.check("offer has 3 cards", offer1.size() == 3)
	var found_different := false
	for s in range(2, 30):
		var other := Draft.generate_offer(catalog, ctx, DetRNG.new(DetRNG.derive(s, "draft", 1)))
		if _card_ids(other) != _card_ids(offer1):
			found_different = true
			break
	sink.check("different seeds can produce different offers", found_different)
	var no_dupes := true
	for s in 40:
		var offer := Draft.generate_offer(catalog, ctx, DetRNG.new(s))
		var ids := _card_ids(offer)
		for id in ids:
			if ids.count(id) > 1:
				no_dupes = false
	sink.check("no duplicate cards in any single offer (40 seeds)", no_dupes)

func run_draft_rules(sink) -> void:
	sink.section("draft rules")
	var catalog := Catalog.cards()
	var prereq_ok := true
	for s in 60:
		var offer := Draft.generate_offer(catalog, {"acquired": {}, "unlocks": {}, "blocked": []}, DetRNG.new(s))
		if _card_ids(offer).has(&"bolt_overcharge"):
			prereq_ok = false
	sink.check("prerequisite card never offered before its chain parent", prereq_ok)
	var ctx_with := {"acquired": {&"build_bolt": 1}, "unlocks": {}, "blocked": []}
	sink.check("prerequisite card eligible after parent acquired",
		Draft.is_eligible(Catalog.card(&"bolt_overcharge"), ctx_with))
	sink.check("exclusion blocks branched card",
		not Draft.is_eligible(Catalog.card(&"acidblood_core"), {"acquired": {&"overload_core": 1}, "unlocks": {}, "blocked": []}))
	sink.check("max_stacks blocks exhausted card",
		not Draft.is_eligible(Catalog.card(&"overload_core"), {"acquired": {&"overload_core": 1}, "unlocks": {}, "blocked": []}))
	sink.check("locked card ineligible without permanent unlock",
		not Draft.is_eligible(Catalog.card(&"build_frost"), {"acquired": {}, "unlocks": {}, "blocked": []}))
	sink.check("locked card eligible with permanent unlock",
		Draft.is_eligible(Catalog.card(&"build_frost"), {"acquired": {}, "unlocks": {&"frost_turret": true}, "blocked": []}))
	sink.check("Stage 1 eligible pool keeps Impact Cannon and excludes legacy turret builds",
		Draft.is_eligible(Catalog.card(&"build_cannon"), {"allowed_card_ids": [&"build_cannon"], "acquired": {}, "unlocks": {}, "blocked": []})
		and not Draft.is_eligible(Catalog.card(&"build_bolt"), {"allowed_card_ids": [&"build_cannon"], "acquired": {}, "unlocks": {}, "blocked": []})
		and not Draft.is_eligible(Catalog.card(&"build_frost"), {"allowed_card_ids": [&"build_cannon"], "acquired": {}, "unlocks": {}, "blocked": []}))
	sink.check("active turret blocks duplicate NEW TURRET choice",
		not Draft.is_eligible(Catalog.card(&"build_cannon"), {"active_turrets": [&"cannon"], "acquired": {&"build_cannon": 1}, "unlocks": {}, "blocked": []}))
	sink.check("blocked list removes card",
		not Draft.is_eligible(Catalog.card(&"build_bolt"), {"acquired": {}, "unlocks": {}, "blocked": [&"build_bolt"]}))
	sink.check("branch card eligible after bolt turret is built",
		Draft.is_eligible(Catalog.card(&"bolt_chain_protocol"), {"acquired": {&"build_bolt": 1}, "unlocks": {}, "blocked": []}))
	sink.check("cannon branch card eligible after cannon turret is built",
		Draft.is_eligible(Catalog.card(&"cannon_blast_protocol"), {"acquired": {&"build_cannon": 1}, "unlocks": {}, "blocked": []}))
	sink.check("frost branch card eligible after frost turret is built",
		Draft.is_eligible(Catalog.card(&"frost_control_protocol"), {"acquired": {&"build_frost": 1}, "unlocks": {}, "blocked": []}))
	sink.check("draft weights prefer active turret family",
		Draft._effective_weight(Catalog.card(&"bolt_chain_protocol"), {
			"acquired": {}, "unlocks": {}, "blocked": [],
			"preferred_categories": [&"bolt"],
		}, {}, 1) > Draft._effective_weight(Catalog.card(&"cannon_blast_protocol"), {
			"acquired": {}, "unlocks": {}, "blocked": [],
			"preferred_categories": [&"bolt"],
		}, {}, 1))
	sink.check("pure heal card blocked at full fortress hp",
		not Draft.is_eligible(Catalog.card(&"field_repairs"), {
			"acquired": {}, "unlocks": {}, "blocked": [],
			"fortress_hp": 100.0, "fortress_max_hp": 100.0,
		}))
	sink.check("pure heal card allowed when fortress is damaged",
		Draft.is_eligible(Catalog.card(&"field_repairs"), {
			"acquired": {}, "unlocks": {}, "blocked": [],
			"fortress_hp": 80.0, "fortress_max_hp": 100.0,
		}))
	sink.check("fortress recovery is classified as an emergency response",
		Draft.card_role(Catalog.card(&"field_repairs")) == &"emergency")
	var critical_ctx := {
		"acquired": {}, "unlocks": {}, "blocked": [],
		"fortress_hp": 20.0, "fortress_max_hp": 100.0,
		"critical_pressure": true, "draft_index": 3,
	}
	var critical_offer := Draft.generate_offer(catalog, critical_ctx, DetRNG.new(901), 3)
	var has_emergency := false
	for card in critical_offer:
		if Draft.card_role(card) == &"emergency":
			has_emergency = true
			break
	sink.check("critical draft guarantees an emergency response when eligible", has_emergency)
	var stable_a := _card_ids(Draft.generate_offer(catalog, critical_ctx, DetRNG.new(902), 3))
	var stable_b := _card_ids(Draft.generate_offer(catalog, critical_ctx, DetRNG.new(902), 3))
	sink.check("critical contextual draft remains deterministic", stable_a == stable_b)
	var runtime_blocked := Draft.runtime_blocked_cards(catalog, 0)
	sink.check("runtime blocking marks build cards when no slots are free",
		runtime_blocked.has(&"build_bolt") and runtime_blocked.has(&"build_cannon"))
	sink.check("runtime blocking clears when a slot is available",
		Draft.runtime_blocked_cards(catalog, 1).is_empty())
	var early_build_ok := true
	for s in 40:
		var early_offer := Draft.generate_offer(catalog, {
			"acquired": {}, "unlocks": {}, "blocked": [],
			"fortress_hp": 100.0, "fortress_max_hp": 100.0,
			"draft_index": 1,
		}, DetRNG.new(s))
		var has_build := false
		for card in early_offer:
			if Draft.card_role(card) == &"build":
				has_build = true
				break
		if not has_build:
			early_build_ok = false
			break
	sink.check("early draft guarantees a build option when one is eligible", early_build_ok)
	var variety_ok := true
	for s in 80:
		var offer := Draft.generate_offer(catalog, {
			"acquired": {}, "unlocks": {}, "blocked": [],
			"fortress_hp": 100.0, "fortress_max_hp": 100.0,
			"draft_index": 1,
		}, DetRNG.new(DetRNG.derive(s, "draft", 1)))
		if offer.size() < 3:
			continue
		var categories := {}
		for card in offer:
			categories[Draft.card_category(card)] = true
		if categories.size() <= 1:
			variety_ok = false
			break
	sink.check("early draft avoids 3 cards from one category when alternatives exist", variety_ok)

func run_leveling_and_run_state(sink) -> void:
	sink.section("leveling/run state")
	var monotonic := true
	for lvl in range(1, 30):
		if Leveling.xp_required(lvl + 1) <= Leveling.xp_required(lvl):
			monotonic = false
	sink.check("xp curve is monotonically increasing", monotonic)
	var rs := RunState.new()
	var ups := rs.grant_xp(Leveling.xp_required(1) + Leveling.xp_required(2))
	sink.check("grant_xp triggers chained level-ups", ups == 2 and rs.level == 3)
	rs.set_branch(&"bolt", &"bolt_chain")
	sink.check("run state stores chosen turret branch", rs.branch_for(&"bolt") == &"bolt_chain")
	rs.mods.add_flat(&"fortress.max_hp", 30.0)
	sink.check("fortress max hp respects modifiers", rs.fortress_max_hp() == 130.0)
	var ms := ModifierSet.new()
	ms.add_flat(&"x", 2.0)
	ms.multiply(&"x", 1.5)
	sink.check("modifier math: (base+add)*mult", is_equal_approx(ms.value(&"x", 4.0), 9.0))

func run_slot_ordering(sink) -> void:
	sink.section("slots")
	sink.check("slot helper keeps defensive-line names",
		ArenaLayout.slot_display_name(0) == "T1 Left"
		and ArenaLayout.slot_display_name(1) == "T2 Left"
		and ArenaLayout.slot_display_name(2) == "T3 Right"
		and ArenaLayout.slot_display_name(3) == "T4 Right")
	sink.check("slot picker uses visual order 1,2,3,4",
		ArenaLayout.slot_pick_order() == [0, 1, 2, 3])
	var scene := load("res://game/arena.tscn") as PackedScene
	var root := scene.instantiate()
	var slots := root.get_node("TowerSlots")
	var labels := [
		(slots.get_node("Slot01/Number01") as Label3D).text,
		(slots.get_node("Slot02/Number02") as Label3D).text,
		(slots.get_node("Slot03/Number03") as Label3D).text,
		(slots.get_node("Slot04/Number04") as Label3D).text,
	]
	sink.check("arena pads are labeled T1,T2,T3,T4 to match the defensive line", labels == ["T1", "T2", "T3", "T4"])
	root.free()

func run_combat(sink) -> void:
	sink.section("combat")
	sink.check("armor reduces damage", Combat.damage_after_armor(10.0, 3.0) == 7.0)
	sink.check("damage floor holds", Combat.damage_after_armor(2.0, 50.0) == Combat.MIN_DAMAGE)
	sink.check("minimum attack interval constant is sane", is_equal_approx(Combat.MIN_ATTACK_INTERVAL, 0.05))
	sink.check("projectile segment hit catches stationary targets crossed between frames",
		Projectile._segment_hits_enemy(Vector3(0, 0, 4), Vector3(0, 0, -1), Vector3(0, 0, 1.8)))
	sink.check("projectile fortress segment detects crossing without exact endpoint overlap",
		Projectile._segment_reaches_fortress(
			Vector3(0.0, 0.8, 6.7),
			Vector3(0.0, 0.8, 7.9)
		))

func run_stat_registry(sink) -> void:
	sink.section("stat registry")
	sink.check("known guardian stat valid", StatRegistry.is_valid(&"guardian.damage"))
	sink.check("known fortress stat valid", StatRegistry.is_valid(&"fortress.max_hp"))
	sink.check("known turret stat valid", StatRegistry.is_valid(&"turret.cannon.splash_radius"))
	sink.check("guardian typo rejected", not StatRegistry.is_valid(&"guardian.damge"))
	sink.check("unknown turret rejected", not StatRegistry.is_valid(&"turret.fake.damage"))
	sink.check("unknown turret stat rejected", not StatRegistry.is_valid(&"turret.bolt.fake_stat"))

func run_progression_save_load(sink) -> void:
	sink.section("progression save/load")
	var path := scratch_path("acidblood-test_save_tmp.json")
	var p := Progression.new()
	p.cores = 17
	p.completed_stages = ["stage_001", "stage_002"]
	p.upgrade_levels = {"guardian_core": 2, "frost_protocol": 1}
	sink.check("save() succeeds", p.save(path))
	var q := Progression.load_or_new(path)
	sink.check("cores survive save/load", q.cores == 17)
	sink.check("campaign progress survives save/load", q.completed_stages == ["stage_001", "stage_002"])
	sink.check("permanent upgrades survive save/load",
		q.upgrade_level(&"guardian_core") == 2 and q.upgrade_level(&"frost_protocol") == 1)
	var flags := q.unlock_flags(Catalog.perm_upgrades())
	sink.check("unlock flags derived from saved upgrades", bool(flags.get(&"frost_turret", false)))
	sink.check("upgrade stat bonus computed",
		q.upgrade_stat_bonus(Catalog.perm_upgrades(), &"guardian.damage") == 2.0)
	var fake_req := PermUpgradeData.new()
	fake_req.id = &"fake_req"
	fake_req.requires_nodes = [&"guardian_core"]
	var locked_progression := Progression.new()
	locked_progression.cores = 999
	sink.check("upgrade requirements block purchase until parent is owned",
		not locked_progression.can_buy_upgrade(fake_req))
	q.cores = 999
	sink.check("owned prerequisite satisfies requirement", q.can_buy_upgrade(fake_req))
	DirAccess.remove_absolute(path)

func run_campaign_data(sink) -> void:
	sink.section("campaign")
	var stages := Catalog.stages()
	sink.check("campaign has 30 stages", stages.size() == 30)
	var indices_ok := true
	for i in stages.size():
		if stages[i].index != i + 1:
			indices_ok = false
	sink.check("stage indices are 1..30 in order", indices_ok)
	var ids := Catalog.ordered_stage_ids()
	sink.check("stage ids unique", ids.size() == 30)
	var p := Progression.new()
	sink.check("stage 1 unlocked from start", p.is_stage_unlocked(0, ids))
	sink.check("stage 2 locked from start", not p.is_stage_unlocked(1, ids))
	p.apply_victory(ids[0], 5)
	sink.check("completing stage 1 unlocks stage 2", p.is_stage_unlocked(1, ids))
	sink.check("stage 3 still locked", not p.is_stage_unlocked(2, ids))
	var first := p.cores
	var repeat_award := p.apply_victory(ids[0], 5)
	sink.check("repeat clear pays reduced reward", repeat_award < 5 and repeat_award > 0 and p.cores == first + repeat_award)
	var t := Progression.new()
	var traversal_ok := true
	for i in stages.size():
		if not t.is_stage_unlocked(i, ids):
			traversal_ok = false
			break
		t.apply_victory(ids[i], stages[i].reward_cores)
	var path := scratch_path("acidblood-test_campaign_tmp.json")
	t.save(path)
	var t2 := Progression.load_or_new(path)
	sink.check("auto-win traversal unlocks all 30 stages in order", traversal_ok and t.completed_stages.size() == 30)
	sink.check("full campaign completion survives save/load", t2.completed_stages.size() == 30 and t2.cores == t.cores)
	DirAccess.remove_absolute(path)

func run_data_references(sink) -> void:
	sink.section("data references")
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
	sink.check("all stage/wave/enemy references resolve (%s)" % [",".join(bad) if bad else "ok"], bad.is_empty())
	var stage_one := Catalog.stage_by_index(1)
	var stage_one_count := 0
	var stage_one_lanes_ok := true
	for wave in stage_one.waves:
		for g in wave.groups:
			stage_one_count += g.count
			if not ["random", "left", "center", "right"].has(String(g.lane).to_lower()):
				stage_one_lanes_ok = false
	sink.check("stage 1 horde structure stays authored and laterally distributed",
			stage_one.waves.size() == 6 and stage_one_count >= 100 and stage_one_lanes_ok)
	sink.check("stage 1 has finite calibrated pacing and draft budget",
			stage_one.max_draft_choices == 20 and stage_one_count >= 300)
	bad = []
	var card_ids := []
	for card in Catalog.cards():
		card_ids.append(card.id)
	var branch_ids := []
	for branch in Catalog.turret_branches().values():
		branch_ids.append(branch.id)
	var expected_branch_ids := [&"bolt_chain", &"bolt_field", &"cannon_blast", &"cannon_impact", &"frost_control", &"frost_expose"]
	var expected_branches_ok := true
	for branch_id in expected_branch_ids:
		if not branch_ids.has(branch_id):
			expected_branches_ok = false
			bad.append("missing branch %s" % branch_id)
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
				CardEffect.Op.APPLY_BRANCH:
					if not branch_ids.has(eff.target):
						bad.append("%s applies unknown branch %s" % [card.id, eff.target])
	for up in Catalog.perm_upgrades():
		if up.track == &"":
			bad.append("%s missing track" % up.id)
		for req in up.requires_nodes:
			var found_req := false
			for item in Catalog.perm_upgrades():
				if item.id == req:
					found_req = true
					break
			if not found_req:
				bad.append("%s requires missing upgrade %s" % [up.id, req])
		if up.stat != &"" and not StatRegistry.is_valid(up.stat):
			bad.append("%s invalid permanent stat %s" % [up.id, up.stat])
	var cards_missing_tags := []
	for card in Catalog.cards():
		if card.tags.is_empty():
			cards_missing_tags.append(String(card.id))
		for tag in card.tags:
			if tag == &"":
				bad.append("%s has empty tag" % card.id)
	sink.check("card + permanent stat graph valid (%s)" % [",".join(bad) if bad else "ok"], bad.is_empty())
	sink.check("all cards have at least one build tag (%s)" % [",".join(cards_missing_tags) if cards_missing_tags else "ok"], cards_missing_tags.is_empty())
	bad = []
	for branch in Catalog.turret_branches().values():
		if Catalog.turret(branch.turret_id) == null:
			bad.append("%s targets unknown turret %s" % [branch.id, branch.turret_id])
		for ex in branch.excludes_branches:
			if not branch_ids.has(ex):
				bad.append("%s excludes missing branch %s" % [branch.id, ex])
		for eff in branch.effects:
			match eff.op:
				CardEffect.Op.ADD_STAT, CardEffect.Op.MULTIPLY_STAT:
					if eff.stat == &"":
						bad.append("%s branch effect without stat" % branch.id)
					elif not StatRegistry.is_valid(eff.stat):
						bad.append("%s invalid branch stat %s" % [branch.id, eff.stat])
				_:
					bad.append("%s has unsupported branch op %s" % [branch.id, eff.op])
	sink.check("turret branch graph valid (%s)" % [",".join(bad) if bad else "ok"], bad.is_empty())
	sink.check("at least 4 enemy archetypes", Catalog.enemies().size() >= 4)
	sink.check("at least 3 turret archetypes", Catalog.turrets().size() >= 3)
	sink.check("6 turret branches", Catalog.turret_branches().size() == 6 and expected_branches_ok)
	var bolt_data: TurretData = Catalog.turret(&"bolt")
	var bolt_chain: TurretBranchData = Catalog.turret_branch(&"bolt_chain")
	var bolt_field: TurretBranchData = Catalog.turret_branch(&"bolt_field")
	var cannon_impact: TurretBranchData = Catalog.turret_branch(&"cannon_impact")
	var frost_expose: TurretBranchData = Catalog.turret_branch(&"frost_expose")
	sink.check("bolt uses lightning attack mode", bolt_data != null and bolt_data.attack_mode == &"lightning")
	sink.check("bolt chain has real chain behavior data",
		bolt_chain != null
		and bolt_chain.attack_mode == &"lightning_chain"
		and bolt_chain.chain_count == 2
		and bolt_chain.chain_range > 0.0
		and bolt_chain.chain_damage_factor < 1.0)
	sink.check("bolt field has persistent zone behavior data",
		bolt_field != null
		and bolt_field.attack_mode == &"lightning_field"
		and bolt_field.field_radius > 0.0
		and bolt_field.field_duration > 0.0
		and bolt_field.field_tick_interval > 0.0
		and bolt_field.field_damage_factor > 0.0)
	sink.check("cannon impact has direct-hit payload data",
		cannon_impact != null
		and cannon_impact.force_heavy_impact
		and cannon_impact.impact_stun_duration > 0.0
		and cannon_impact.impact_armor_break > 0.0
		and cannon_impact.impact_armor_break_duration > 0.0
		and cannon_impact.impact_knockback > 0.0)
	sink.check("frost expose has vulnerability payload data",
		frost_expose != null
		and frost_expose.expose_damage_multiplier > 1.0
		and frost_expose.expose_duration > 0.0
		and frost_expose.projectile_visual == &"ice_shard_expose")
	sink.check("guardian data + weapon present", Catalog.guardian() != null and Catalog.guardian().weapon != null)
	sink.check("3 permanent upgrades", Catalog.perm_upgrades().size() == 3)

func run_content_conventions(sink) -> void:
	sink.section("content conventions")
	var bad := []
	var duplicate_titles := []
	var duplicate_ids := []
	var seen_titles := {}
	var seen_ids := {}
	for card in Catalog.cards():
		var id_text := String(card.id)
		var title_text := card.title
		var description_text := card.description
		if id_text == "" or id_text != id_text.strip_edges():
			bad.append("%s invalid id formatting" % id_text)
		if title_text.strip_edges() == "":
			bad.append("%s missing title" % id_text)
		if description_text.strip_edges() == "":
			bad.append("%s missing description" % id_text)
		if title_text != title_text.strip_edges():
			bad.append("%s title has edge whitespace" % id_text)
		if description_text != description_text.strip_edges():
			bad.append("%s description has edge whitespace" % id_text)
		if seen_ids.has(card.id):
			duplicate_ids.append(id_text)
		seen_ids[card.id] = true
		if seen_titles.has(card.title):
			duplicate_titles.append(card.title)
		seen_titles[card.title] = true
		var unlock_ops := 0
		var branch_ops := 0
		for eff in card.effects:
			if eff.op == CardEffect.Op.UNLOCK_TURRET:
				unlock_ops += 1
			elif eff.op == CardEffect.Op.APPLY_BRANCH:
				branch_ops += 1
		var is_build_title := title_text.begins_with("Build: ") or title_text.begins_with("Deploy: ")
		if unlock_ops > 0 and not is_build_title:
			bad.append("%s build card title should start with Build: or Deploy:" % id_text)
		if branch_ops > 0 and not title_text.contains("Branch: "):
			bad.append("%s branch card title should include Branch:" % id_text)
		if unlock_ops == 0 and is_build_title:
			bad.append("%s uses build/deploy title without build effect" % id_text)
		if branch_ops == 0 and title_text.contains("Branch: "):
			bad.append("%s uses Branch: title without branch effect" % id_text)
		for ex in card.excludes:
			var excluded_card := Catalog.card(ex)
			if excluded_card == null:
				continue
			if not excluded_card.excludes.has(card.id):
				bad.append("%s excludes %s but not vice versa" % [card.id, ex])
	sink.check("card content conventions valid (%s)" % [",".join(bad) if bad else "ok"], bad.is_empty())
	sink.check("card ids unique (%s)" % [",".join(duplicate_ids) if duplicate_ids else "ok"], duplicate_ids.is_empty())
	sink.check("card titles unique (%s)" % [",".join(duplicate_titles) if duplicate_titles else "ok"], duplicate_titles.is_empty())
