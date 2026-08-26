@tool
class_name AcidbloodBehavioralSuite
extends GdUnitTestSuite

const BattleScene := preload("res://game/battle.tscn")
const TurretScene := preload("res://game/turret.tscn")
const HomeScene := preload("res://shell/home.tscn")
const CampaignScene := preload("res://shell/campaign.tscn")
const ResultScene := preload("res://shell/result.tscn")
const StageDataScript := preload("res://data/types/stage_data.gd")
const WaveDataScript := preload("res://data/types/wave_data.gd")
const PlaytestProfileScript := preload("res://core/playtest_profile.gd")
const PlaytestTelemetryScript := preload("res://core/playtest_telemetry.gd")

var _saved_game_stage
var _saved_game_seed := 0
var _saved_game_autoplay := false
var _saved_game_progression

func before_test() -> void:
	_saved_game_stage = Game.current_stage
	_saved_game_seed = Game.pending_seed
	_saved_game_autoplay = Game.autoplay
	_saved_game_progression = Game.progression
	Game.current_stage = _make_test_stage()
	Game.pending_seed = 1337
	Game.autoplay = false
	var fresh_progression := Progression.new()
	fresh_progression.save_path = "user://gdunit-behavioral-save.json"
	Game.progression = fresh_progression

func after_test() -> void:
	Game.current_stage = _saved_game_stage
	Game.pending_seed = _saved_game_seed
	Game.autoplay = _saved_game_autoplay
	Game.progression = _saved_game_progression

func test_phase1_run_starts_with_empty_line_and_active_guardian() -> void:
	var run := RunState.new()
	assert_int(run.turret_slots.size()).is_equal(4)
	assert_array(run.turret_slots).is_equal([&"", &"", &"", &""])
	assert_bool(run.guardian_active).is_true()

func test_phase1_kill_xp_is_awarded_once_and_crosses_threshold() -> void:
	var run := RunState.new()
	var first := run.grant_kill_xp(&"enemy-001", 10)
	var duplicate := run.grant_kill_xp(&"enemy-001", 10)
	assert_int(first).is_equal(1)
	assert_int(duplicate).is_equal(0)
	assert_int(run.level).is_equal(2)

func test_task3_xp_overflow_and_multiple_levels_are_deterministic() -> void:
	var first := RunState.new()
	first.run_xp_thresholds = [10, 10, 10]
	var second := RunState.new()
	second.run_xp_thresholds = [10, 10, 10]
	var first_levels := first.grant_xp(25)
	var second_levels := second.grant_xp(25)
	assert_int(first_levels).is_equal(2)
	assert_int(first.level).is_equal(3)
	assert_int(first.xp).is_equal(5)
	assert_int(first.total_xp_earned).is_equal(25)
	assert_int(second_levels).is_equal(first_levels)
	assert_dict(second.to_dict()).is_equal(first.to_dict())

func test_task3_duplicate_battle_death_callback_awards_one_kill_and_xp() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	battle.spawn_wave_enemy(&"grunt", 0.0)
	var enemy := battle.enemies.back() as Enemy
	battle.notify_enemy_died(enemy, true)
	battle.notify_enemy_died(enemy, true)
	assert_int(battle.run_state.kills).is_equal(1)
	assert_int(battle.run_state.total_xp_earned).is_equal(enemy.data.xp)

func test_task3_draft_budget_limits_pending_level_ups() -> void:
	var run := RunState.new()
	run.max_draft_choices = 2
	assert_bool(run.consume_draft_choice()).is_true()
	assert_bool(run.consume_draft_choice()).is_true()
	assert_bool(run.consume_draft_choice()).is_false()

func test_task4_selection_consumes_one_interruption_and_resumes() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	var card := Catalog.card(&"field_repairs")
	battle._active_offer = [card]
	battle._draft_open = true
	battle._pending_drafts = 0
	get_tree().paused = true
	battle.on_card_chosen(card)
	battle.on_card_chosen(card)
	assert_int(int(battle.run_state.acquired.get(card.id, 0))).is_equal(1)
	assert_int(battle._pending_drafts).is_equal(0)
	assert_bool(battle._draft_open).is_false()
	assert_bool(get_tree().paused).is_false()

func test_task4_queued_interruption_opens_next_offer_without_duplicate_selection() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	var card := Catalog.card(&"field_repairs")
	battle._active_offer = [card]
	battle._draft_open = true
	battle._pending_drafts = 2
	get_tree().paused = true
	battle.on_card_chosen(card)
	assert_int(int(battle.run_state.acquired.get(card.id, 0))).is_equal(1)
	assert_int(battle._pending_drafts).is_equal(1)
	assert_bool(battle._draft_open).is_true()
	assert_bool(get_tree().paused).is_true()

func test_task5_stage1_draft_restricts_legacy_turrets_and_keeps_cannon() -> void:
	var offer := Draft.generate_offer(Catalog.cards(), {
		"allowed_card_ids": [&"build_cannon", &"sharp_rounds", &"rapid_trigger", &"split_shot", &"long_barrel", &"overload_core", &"piercing_rounds"],
		"acquired": {}, "unlocks": {}, "blocked": [], "draft_index": 1,
		"fortress_hp": 100.0, "fortress_max_hp": 100.0,
	}, DetRNG.new(77), 3)
	var ids := _card_ids(offer)
	assert_bool(ids.has(&"build_cannon")).is_true()
	assert_bool(ids.has(&"build_bolt")).is_false()
	assert_bool(ids.has(&"build_frost")).is_false()
	assert_int(offer.size()).is_equal(3)

func test_task5_cannon_install_updates_runtime_and_domain_slot_once() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	assert_bool(battle._build_turret_at_slot(&"cannon", 0)).is_true()
	assert_str(String(battle.run_state.turret_slots[0])).is_equal("cannon")
	assert_int(battle.run_state.available_slot_count()).is_equal(3)
	assert_bool(battle._build_turret_at_slot(&"cannon", 0)).is_false()
	assert_bool(Draft.is_eligible(Catalog.card(&"build_cannon"), {
		"acquired": {&"build_cannon": 1}, "active_turrets": [&"cannon"],
		"unlocks": {}, "blocked": [],
	})).is_false()

func test_phase1_new_turret_capacity_and_duplicate_occupancy() -> void:
	var run := RunState.new()
	assert_bool(run.install_turret(&"cannon", 0)).is_true()
	assert_bool(run.install_turret(&"cannon", 0)).is_false()
	assert_bool(run.install_turret(&"cannon", 1)).is_false()
	for slot_index in range(1, 4):
		assert_bool(run.install_turret(StringName("turret_%d" % slot_index), slot_index)).is_true()
	assert_int(run.available_slot_count()).is_equal(0)
	assert_bool(run.install_turret(&"cannon", 0)).is_false()

func test_task11_new_turret_uses_paused_in_world_placement() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	var card := Catalog.card(&"build_cannon")
	battle._active_offer = [card]
	battle._draft_open = true
	get_tree().paused = true
	battle.on_card_chosen(card)
	assert_bool(battle.has_method("is_placement_open")).is_true()
	assert_bool(bool(battle.call("is_placement_open"))).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_bool(battle.hud.has_method("show_placement")).is_true()
	assert_bool(battle.hud.has_method("show_slot_picker")).is_false()
	assert_bool(battle.hud.draft_layer.visible).is_false()
	var ghost = battle.get("_placement_ghost")
	assert_bool(is_instance_valid(ghost)).is_true()
	assert_int(int(battle.call("placement_slot_index"))).is_equal(0)

func test_task11_placement_skips_occupied_slots_and_confirm_resumes() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	assert_bool(battle._build_turret_at_slot(&"bolt", 0)).is_true()
	var card := Catalog.card(&"build_cannon")
	battle._active_offer = [card]
	battle._draft_open = true
	get_tree().paused = true
	battle.on_card_chosen(card)
	assert_int(int(battle.call("placement_slot_index"))).is_equal(1)
	var right_key := InputEventKey.new()
	right_key.keycode = KEY_RIGHT
	right_key.pressed = true
	battle.hud._unhandled_input(right_key)
	assert_int(int(battle.call("placement_slot_index"))).is_equal(2)
	assert_bool(bool(battle.call("move_placement_selection", -1))).is_true()
	assert_int(int(battle.call("placement_slot_index"))).is_equal(1)
	assert_bool(bool(battle.call("move_placement_selection", -1))).is_true()
	assert_int(int(battle.call("placement_slot_index"))).is_equal(3)
	assert_bool(bool(battle.call("move_placement_selection", 1))).is_true()
	assert_int(int(battle.call("placement_slot_index"))).is_equal(1)
	assert_bool(bool(battle.call("confirm_turret_placement"))).is_true()
	assert_str(String(battle.run_state.turret_slots[1])).is_equal("cannon")
	assert_bool(bool(battle.call("is_placement_open"))).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_bool(is_instance_valid(battle.get("_placement_ghost"))).is_false()

func test_task11_real_input_path_reaches_placement_while_tree_paused() -> void:
	var boot := await _boot_battle()
	var runner := boot["runner"] as GdUnitSceneRunner
	var battle := boot["battle"] as Battle
	battle.on_wave_started(1, battle.stage.waves.size(), battle.stage.waves[0])
	battle.run_state.run_xp_thresholds = [2]
	battle.spawn_wave_enemy(&"grunt", 0.0)
	var level_up_enemy := battle.enemies.back() as Enemy
	battle.spawn_wave_enemy(&"grunt", 0.0)
	var enemy := battle.enemies.back() as Enemy
	var position_before_pause := enemy.global_position
	battle.notify_enemy_died(level_up_enemy, true)
	level_up_enemy.queue_free()
	await runner.simulate_frames(1)
	assert_int(battle.run_state.level).is_equal(2)
	assert_int(battle.run_state.total_xp_earned).is_equal(2)
	assert_bool(battle._draft_open).is_true()
	assert_int(battle._active_offer.size()).is_equal(3)
	assert_bool(_card_ids(battle._active_offer).has(&"build_cannon")).is_true()
	assert_bool(get_tree().paused).is_true()
	await runner.simulate_key_pressed(KEY_SPACE)
	await runner.await_input_processed()
	assert_bool(bool(battle.call("is_placement_open"))).is_true()
	assert_str(battle.hud.placement_hint.text).is_equal("CHOOSE SLOT: T1 LEFT\n← / → MOVE • SPACE CONFIRM")
	assert_int(int(battle.call("placement_slot_index"))).is_equal(0)
	await runner.simulate_frames(4)
	assert_bool(enemy.global_position.is_equal_approx(position_before_pause)).is_true()
	assert_int(battle.run_state.wave_index).is_equal(1)
	assert_int(battle.run_state.active_turrets.size()).is_equal(0)
	assert_bool(get_tree().paused).is_true()
	await runner.simulate_key_pressed(KEY_RIGHT)
	await runner.await_input_processed()
	assert_int(int(battle.call("placement_slot_index"))).is_equal(1)
	await runner.simulate_key_pressed(KEY_SPACE)
	await runner.await_input_processed()
	await runner.simulate_frames(2)
	assert_str(String(battle.run_state.turret_slots[1])).is_equal("cannon")
	assert_array(battle.run_state.active_turrets).is_equal([&"cannon"])
	assert_int(battle.get_node("Actors/Turrets").get_child_count()).is_equal(1)
	assert_bool(bool(battle.call("is_placement_open"))).is_false()
	assert_bool(battle._draft_open).is_false()
	assert_bool(get_tree().paused).is_false()
	await runner.simulate_key_pressed(KEY_SPACE)
	await runner.await_input_processed()
	assert_array(battle.run_state.active_turrets).is_equal([&"cannon"])

func test_horizontal_slice_has_real_shell_entry_result_and_return_controls() -> void:
	var home := HomeScene.instantiate()
	var campaign := CampaignScene.instantiate()
	var result := ResultScene.instantiate()
	assert_object(home.get_node("Margin/VBox/PlayButton")).is_valid()
	assert_object(campaign.get_node("Margin/VBox/Scroll/StageGrid")).is_valid()
	assert_object(campaign.get_node("Margin/VBox/StageEntry/Margin/VBox/DeployButton")).is_valid()
	assert_object(result.get_node("Center/Panel/Margin/VBox/ContinueButton")).is_valid()
	assert_object(result.get_node("Center/Panel/Margin/VBox/RetryButton")).is_valid()
	assert_str(Game.HOME_SCENE).is_equal("res://shell/home.tscn")
	assert_str(Game.CAMPAIGN_SCENE).is_equal("res://shell/campaign.tscn")
	assert_str(Game.BATTLE_SCENE).is_equal("res://game/battle.tscn")
	assert_str(Game.RESULT_SCENE).is_equal("res://shell/result.tscn")
	home.free()
	campaign.free()
	result.free()

func test_draft_cards_use_portrait_grid_and_keep_wave_data_internal() -> void:
	var boot := await _boot_battle()
	var runner := boot["runner"] as GdUnitSceneRunner
	var battle := boot["battle"] as Battle
	var offer: Array[CardData] = [
		Catalog.card(&"build_cannon"),
		Catalog.card(&"sharp_rounds"),
		Catalog.card(&"overload_core"),
	]
	battle.hud.show_draft(offer)
	await runner.simulate_frames(2)
	assert_bool(battle.hud.wave_label.visible).is_false()
	assert_int(battle.hud.cards_box.columns).is_equal(3)
	assert_int(battle.hud.cards_box.get_child_count()).is_equal(3)
	for child in battle.hud.cards_box.get_children():
		var card_button := child as Button
		assert_object(card_button).is_valid()
		assert_float(card_button.custom_minimum_size.x).is_greater(0.0)
		assert_float(card_button.custom_minimum_size.y).is_greater_equal(400.0)
	battle.hud.hide_draft()

func test_phase2_current_guardian_and_cannon_have_explicit_weapon_contracts() -> void:
	var guardian_weapon := Catalog.guardian().weapon
	var cannon_weapon := Catalog.turret(&"cannon").weapon
	assert_object(guardian_weapon).is_valid()
	assert_object(cannon_weapon).is_valid()
	assert_bool(guardian_weapon.contract_valid()).is_true()
	assert_bool(cannon_weapon.contract_valid()).is_true()
	assert_str(String(guardian_weapon.id)).is_equal("guardian_rifle")
	assert_str(String(cannon_weapon.id)).is_equal("impact_cannon")
	assert_str(String(guardian_weapon.damage_family)).is_equal("Physical")
	assert_str(String(cannon_weapon.damage_family)).is_equal("Physical")
	assert_str(String(guardian_weapon.engagement_profile)).is_equal("ROAMING")
	assert_str(String(cannon_weapon.engagement_profile)).is_equal("FORTRESS")
	assert_str(String(guardian_weapon.attack_topology)).is_equal("Direct")
	assert_str(String(cannon_weapon.attack_topology)).is_equal("Splash")
	assert_str(String(guardian_weapon.targeting_policy)).is_equal("most_advanced")
	assert_str(String(cannon_weapon.targeting_policy)).is_equal("most_advanced")
	assert_float(cannon_weapon.splash_radius).is_greater(0.0)
	assert_str(String(cannon_weapon.projectile_visual)).is_equal("impact_shell")

func test_phase2_cannon_weapon_splash_preserves_group_hit_behavior() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	var cannon_weapon := Catalog.turret(&"cannon").weapon
	battle.spawn_wave_enemy(&"grunt", 0.0)
	var primary := battle.enemies.back() as Enemy
	battle.spawn_wave_enemy(&"grunt", 0.0)
	var neighbor := battle.enemies.back() as Enemy
	battle.spawn_wave_enemy(&"grunt", 0.0)
	var outside := battle.enemies.back() as Enemy
	primary.position = Vector3(0.0, 0.0, 0.0)
	neighbor.position = Vector3(0.8, 0.0, 0.0)
	outside.position = Vector3(2.4, 0.0, 0.0)
	var neighbor_hp := neighbor.hp
	var outside_hp := outside.hp
	battle.apply_hit(primary, cannon_weapon.damage * 0.5, {
		"splash_radius": cannon_weapon.splash_radius,
		"attack_topology": cannon_weapon.attack_topology,
	})
	assert_float(neighbor.hp).is_less(neighbor_hp)
	assert_float(outside.hp).is_equal_approx(outside_hp, 0.001)

func test_phase3_active_cards_have_explicit_honest_categories() -> void:
	var expected := {
		&"build_cannon": &"NEW_TURRET",
		&"build_bolt": &"NEW_TURRET",
		&"build_frost": &"NEW_TURRET",
		&"sharp_rounds": &"NORMAL",
		&"rapid_trigger": &"NORMAL",
		&"split_shot": &"NORMAL",
		&"long_barrel": &"NORMAL",
		&"overload_core": &"NORMAL",
		&"piercing_rounds": &"NORMAL",
		&"field_repairs": &"NORMAL",
		&"acidblood_core": &"NORMAL",
		&"cannon_shockwave": &"CHAIN",
		&"bolt_overcharge": &"CHAIN",
		&"frost_deep_chill": &"CHAIN",
		&"cannon_blast_protocol": &"BREAKTHROUGH",
		&"cannon_impact_protocol": &"BREAKTHROUGH",
		&"bolt_chain_protocol": &"BREAKTHROUGH",
		&"bolt_field_protocol": &"BREAKTHROUGH",
		&"frost_control_protocol": &"BREAKTHROUGH",
		&"frost_expose_protocol": &"BREAKTHROUGH",
	}
	assert_int(Catalog.cards().size()).is_equal(expected.size())
	for card_id in expected:
		var card := Catalog.card(card_id)
		assert_object(card).is_valid()
		assert_bool(card.category_valid()).is_true()
		assert_str(String(card.category)).is_equal(String(expected[card_id]))

func test_phase3_invalid_category_and_combo_prerequisites_are_rejected() -> void:
	var invalid := CardData.new()
	invalid.id = &"invalid_phase3_category"
	invalid.category = &"NOT_A_DRAFT_CATEGORY"
	assert_bool(invalid.category_valid()).is_false()
	assert_bool(Draft.is_eligible(invalid, {"acquired": {}, "unlocks": {}, "blocked": []})).is_false()
	var malformed_breakthrough := CardData.new()
	malformed_breakthrough.id = &"malformed_breakthrough"
	malformed_breakthrough.category = &"BREAKTHROUGH"
	assert_bool(malformed_breakthrough.category_valid()).is_true()
	assert_bool(malformed_breakthrough.category_contract_valid()).is_false()
	assert_bool(Draft.is_eligible(malformed_breakthrough, {"acquired": {}, "unlocks": {}, "blocked": []})).is_false()

	var combo := CardData.new()
	combo.id = &"synthetic_guardian_cannon_combo"
	combo.category = &"COMBO"
	combo.prerequisites = [&"build_cannon", &"overload_core"]
	assert_bool(Draft.is_eligible(combo, {
		"acquired": {&"build_cannon": 1}, "unlocks": {}, "blocked": [],
	})).is_false()
	assert_bool(Draft.is_eligible(combo, {
		"acquired": {&"build_cannon": 1, &"overload_core": 1},
		"unlocks": {}, "blocked": [],
	})).is_true()

func test_phase3_breakthrough_and_chain_paths_respect_branch_context() -> void:
	var base_context := {
		"acquired": {&"build_cannon": 1},
		"unlocks": {}, "blocked": [], "active_turrets": [&"cannon"],
	}
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_blast_protocol"), base_context)).is_true()
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_impact_protocol"), base_context)).is_true()
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_shockwave"), base_context)).is_false()
	var blast_context := base_context.duplicate(true)
	blast_context["acquired"] = {&"build_cannon": 1, &"cannon_blast_protocol": 1}
	blast_context["chosen_branches"] = {&"cannon": &"cannon_blast"}
	blast_context["chosen_branch_cards"] = [&"cannon_blast_protocol"]
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_blast_protocol"), blast_context)).is_false()
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_impact_protocol"), blast_context)).is_false()
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_shockwave"), blast_context)).is_true()
	var impact_context := base_context.duplicate(true)
	impact_context["acquired"] = {&"build_cannon": 1, &"cannon_impact_protocol": 1}
	impact_context["chosen_branches"] = {&"cannon": &"cannon_impact"}
	impact_context["chosen_branch_cards"] = [&"cannon_impact_protocol"]
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_blast_protocol"), impact_context)).is_false()
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_impact_protocol"), impact_context)).is_false()
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_shockwave"), impact_context)).is_true()

func test_phase3_all_chain_cards_require_a_qualifying_breakthrough_path() -> void:
	var cases := [
		[&"bolt_overcharge", &"build_bolt", &"bolt_chain_protocol", &"bolt_chain"],
		[&"frost_deep_chill", &"build_frost", &"frost_control_protocol", &"frost_control"],
	]
	for item in cases:
		var chain_id: StringName = item[0]
		var build_id: StringName = item[1]
		var branch_card_id: StringName = item[2]
		var branch_id: StringName = item[3]
		var before := {
			"acquired": {build_id: 1},
			"unlocks": {}, "blocked": [],
		}
		assert_bool(Draft.is_eligible(Catalog.card(chain_id), before)).is_false()
		var after := {
			"acquired": {build_id: 1, branch_card_id: 1},
			"unlocks": {}, "blocked": [],
			"chosen_branches": {String(build_id).trim_prefix("build_"): branch_id},
			"chosen_branch_cards": [branch_card_id],
		}
		assert_bool(Draft.is_eligible(Catalog.card(chain_id), after)).is_true()

func test_phase3_cannon_breakthrough_chain_offer_is_deterministic() -> void:
	var path_context := {
		"acquired": {&"build_cannon": 1},
		"unlocks": {}, "blocked": [], "active_turrets": [&"cannon"],
		"draft_index": 3,
	}
	var first := Draft.generate_offer(Catalog.cards(), path_context, DetRNG.new(9137), 3)
	var second := Draft.generate_offer(Catalog.cards(), path_context, DetRNG.new(9137), 3)
	assert_array(_card_ids(first)).is_equal(_card_ids(second))
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_blast_protocol"), path_context)).is_true()
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_shockwave"), path_context)).is_false()
	var after_breakthrough := path_context.duplicate(true)
	after_breakthrough["acquired"] = {&"build_cannon": 1, &"cannon_blast_protocol": 1}
	after_breakthrough["chosen_branches"] = {&"cannon": &"cannon_blast"}
	after_breakthrough["chosen_branch_cards"] = [&"cannon_blast_protocol"]
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_blast_protocol"), after_breakthrough)).is_false()
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_impact_protocol"), after_breakthrough)).is_false()
	assert_bool(Draft.is_eligible(Catalog.card(&"cannon_shockwave"), after_breakthrough)).is_true()

func test_phase3_category_metadata_does_not_change_seeded_offer_order() -> void:
	var first: Array[CardData] = []
	var second: Array[CardData] = []
	for i in range(5):
		var a := CardData.new()
		a.id = StringName("metadata_card_%d" % i)
		a.weight = 10.0 + i
		a.category = &"NORMAL"
		first.append(a)
		var b := CardData.new()
		b.id = a.id
		b.weight = a.weight
		b.category = &"COMBO" if i == 0 else &"NORMAL"
		second.append(b)
	var first_offer := Draft.generate_offer(first, {}, DetRNG.new(7331), 3)
	var second_offer := Draft.generate_offer(second, {}, DetRNG.new(7331), 3)
	assert_array(_card_ids(first_offer)).is_equal(_card_ids(second_offer))

func test_phase3_card_focus_preserves_category_identity_channel() -> void:
	var card := DraftCard.new()
	card.setup(Catalog.card(&"cannon_blast_protocol"), "BREAKTHROUGH", "CANNON", Color("b65742"), Color(0.2, 0.12, 0.08, 0.96), 210.0)
	var normal := card.get_theme_stylebox("normal") as StyleBoxFlat
	var focus := card.get_theme_stylebox("focus") as StyleBoxFlat
	assert_float(normal.border_color.r).is_equal_approx(Color("b65742").r, 0.001)
	assert_float(normal.border_color.g).is_equal_approx(Color("b65742").g, 0.001)
	assert_float(normal.border_color.b).is_equal_approx(Color("b65742").b, 0.001)
	assert_float(focus.border_color.r).is_equal_approx(normal.border_color.r, 0.001)
	assert_float(focus.border_color.g).is_equal_approx(normal.border_color.g, 0.001)
	assert_float(focus.border_color.b).is_equal_approx(normal.border_color.b, 0.001)
	assert_int(focus.get_border_width(SIDE_TOP)).is_greater(normal.get_border_width(SIDE_TOP))
	card.free()

func test_task11_placement_keeps_queued_level_up_owned_by_next_draft() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	var card := Catalog.card(&"build_cannon")
	battle._active_offer = [card]
	battle._draft_open = true
	battle._pending_drafts = 1
	get_tree().paused = true
	battle.on_card_chosen(card)
	assert_bool(bool(battle.call("is_placement_open"))).is_true()
	assert_bool(bool(battle.call("confirm_turret_placement"))).is_true()
	assert_bool(bool(battle.call("is_placement_open"))).is_false()
	assert_bool(battle._draft_open).is_true()
	assert_bool(get_tree().paused).is_true()

func test_phase1_offer_is_three_choices_and_seeded() -> void:
	var catalog: Array[CardData] = []
	for card_index in range(4):
		var card := CardData.new()
		card.id = StringName("phase1_card_%d" % card_index)
		card.category = &"NEW_TURRET" if card_index == 0 else &"NORMAL"
		card.max_stacks = 1
		catalog.append(card)
	var first := Draft.generate_offer(catalog, {"draft_index": 1}, DetRNG.new(99), 3)
	var second := Draft.generate_offer(catalog, {"draft_index": 1}, DetRNG.new(99), 3)
	assert_int(first.size()).is_equal(3)
	assert_array(_card_ids(first)).is_equal(_card_ids(second))

func test_phase1_draft_budget_is_finite() -> void:
	var run := RunState.new()
	assert_int(run.max_draft_choices).is_equal(20)
	for _i in range(20):
		assert_bool(run.consume_draft_choice()).is_true()
	assert_bool(run.consume_draft_choice()).is_false()

func test_task6_stage1_is_finite_and_result_shell_is_available() -> void:
	var stage := Catalog.stage_by_index(1)
	assert_object(stage).is_valid()
	assert_int(stage.waves.size()).is_equal(6)
	assert_int(stage.max_draft_choices).is_equal(20)
	var enemy_count := 0
	for wave in stage.waves:
		for group in wave.groups:
			enemy_count += group.count
	assert_int(enemy_count).is_greater_equal(300)
	var result_scene := load("res://shell/result.tscn") as PackedScene
	assert_object(result_scene).is_valid()
	var result := result_scene.instantiate()
	assert_object(result.get_node("Center/Panel/Margin/VBox/ContinueButton")).is_valid()
	assert_object(result.get_node("Center/Panel/Margin/VBox/RetryButton")).is_valid()
	result.free()

func test_task11_stage1_calibration_has_continuous_multilane_pressure() -> void:
	var stage := Catalog.stage_by_index(1)
	var enemy_count := 0
	var multi_group_waves := 0
	var authored_lanes: Dictionary = {}
	for wave in stage.waves:
		if wave.groups.size() >= 2:
			multi_group_waves += 1
		for group in wave.groups:
			enemy_count += group.count
			authored_lanes[String(group.lane)] = true
	assert_int(stage.waves.size()).is_equal(6)
	assert_int(enemy_count).is_greater_equal(300)
	assert_int(multi_group_waves).is_greater_equal(4)
	assert_bool(authored_lanes.has("left")).is_true()
	assert_bool(authored_lanes.has("center")).is_true()
	assert_bool(authored_lanes.has("right")).is_true()

func test_task2_defensive_line_is_ordered_around_guardian() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	var markers: Array[Node] = battle.slots_root.get_children()
	assert_int(markers.size()).is_equal(4)
	for index in range(markers.size()):
		assert_str(markers[index].name).is_equal("Slot%02d" % (index + 1))
		assert_float((markers[index] as Marker3D).position.z).is_equal_approx(ArenaLayout.GUARDIAN_Z, 0.001)
	assert_float((markers[0] as Marker3D).position.x).is_less((markers[1] as Marker3D).position.x)
	assert_float((markers[1] as Marker3D).position.x).is_less(0.0)
	assert_float((markers[2] as Marker3D).position.x).is_greater(0.0)
	assert_float((markers[2] as Marker3D).position.x).is_less((markers[3] as Marker3D).position.x)

func test_task2_battle_starts_with_empty_slots_and_active_guardian() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	assert_int(battle._slots.size()).is_equal(4)
	for slot in battle._slots:
		assert_object(slot["turret"]).is_null()
	assert_object(battle.guardian).is_valid()
	assert_float(battle.guardian.position.z).is_equal_approx(ArenaLayout.GUARDIAN_Z, 0.001)

func test_task2_guardian_clamps_to_lateral_limits() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	assert_bool(battle.has_method("record_playtest_event")).is_true()
	battle.guardian.position.x = 100.0
	battle.guardian._move(0.0)
	assert_float(battle.guardian.position.x).is_equal_approx(ArenaLayout.GUARDIAN_X_LIMIT, 0.001)
	battle.guardian.position.x = -100.0
	battle.guardian._move(0.0)
	assert_float(battle.guardian.position.x).is_equal_approx(-ArenaLayout.GUARDIAN_X_LIMIT, 0.001)

func test_task25_fresh_profile_isolated_from_persistent_progression() -> void:
	var persistent := Progression.new()
	persistent.cores = 17
	persistent.completed_stages = ["stage_001"]
	var before := persistent.to_dict()
	var profile: Dictionary = PlaytestProfileScript.build(&"FRESH", 111)
	var injected: Progression = PlaytestProfileScript.progression_for(profile)
	assert_int(injected.cores).is_equal(0)
	assert_array(injected.completed_stages).is_empty()
	assert_dict(persistent.to_dict()).is_equal(before)

func test_task25_benchmark_profile_applies_representative_state_and_is_distinct() -> void:
	var fresh := PlaytestProfileScript.progression_for(PlaytestProfileScript.build(&"FRESH", 111))
	var benchmark_profile: Dictionary = PlaytestProfileScript.build(&"BENCHMARK", 222)
	var benchmark := PlaytestProfileScript.progression_for(benchmark_profile)
	assert_int(benchmark.cores).is_equal(17)
	assert_array(benchmark.completed_stages).contains_exactly(["stage_001", "stage_002"])
	assert_int(benchmark.upgrade_level(&"guardian_core")).is_equal(2)
	assert_int(benchmark.upgrade_level(&"frost_protocol")).is_equal(1)
	assert_bool(fresh.to_dict() == benchmark.to_dict()).is_false()
	var repeat := PlaytestProfileScript.progression_for(PlaytestProfileScript.build(&"BENCHMARK", 222))
	assert_bool(repeat.to_dict() == benchmark.to_dict()).is_true()

func test_task25_guardian_telemetry_counts_movement_episodes() -> void:
	var boot := await _boot_battle()
	var guardian := (boot["battle"] as Battle).guardian
	guardian._record_movement_axis(1.0)
	guardian._record_movement_axis(1.0)
	guardian._record_movement_axis(0.0)
	guardian._record_movement_axis(-1.0)
	assert_int(guardian.movement_events).is_equal(2)

func test_task25_draft_selection_resumes_when_pressure_delays_next_draft() -> void:
	var boot := await _boot_battle()
	var battle := boot["battle"] as Battle
	battle._pending_drafts = 0
	battle._last_barricade_hit_msec = Time.get_ticks_msec()
	battle._active_offer = [Catalog.card(&"field_repairs")]
	battle._draft_open = true
	get_tree().paused = true
	battle.on_card_chosen(Catalog.card(&"field_repairs"))
	assert_bool(get_tree().paused).is_false()

func test_task25_benchmark_initialization_is_seeded_and_versioned() -> void:
	var first: Dictionary = PlaytestProfileScript.build(&"BENCHMARK", 222)
	var second: Dictionary = PlaytestProfileScript.build(&"BENCHMARK", 222)
	assert_dict(first).is_equal(second)
	assert_str(first["profile_version"]).is_equal("benchmark-v1")
	assert_int(int(first["seed"])).is_equal(222)

func test_task25_telemetry_writes_one_profiled_report() -> void:
	var temp_root := OS.get_environment("TMPDIR")
	if temp_root.is_empty():
		temp_root = "/tmp"
	var path := temp_root.path_join("acidblood-task25-test-report.json")
	var profile: Dictionary = PlaytestProfileScript.build(&"FRESH", 333)
	var telemetry: PlaytestTelemetry = PlaytestTelemetryScript.new()
	telemetry.begin(profile, &"stage_001", path)
	telemetry.finish(&"victory", {"kills": 4, "peak_simultaneous_enemies": 2, "elapsed_seconds": 1.25})
	telemetry.finish(&"defeat", {"kills": 99})
	var report := JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	assert_str(report["profile"]).is_equal("FRESH")
	assert_int(int(report["seed"])).is_equal(333)
	assert_str(report["outcome"]).is_equal("victory")
	assert_float(report["elapsed_seconds"]).is_equal_approx(1.25, 0.001)
	assert_int(int(report["kills"])).is_equal(4)
	assert_int(int(report["peak_simultaneous_enemies"])).is_equal(2)

func test_task11_telemetry_reports_simulated_time_and_population_pressure() -> void:
	var temp_root := OS.get_environment("TMPDIR")
	if temp_root.is_empty():
		temp_root = "/tmp"
	var path := temp_root.path_join("acidblood-task11-metrics-test.json")
	var profile: Dictionary = PlaytestProfileScript.build(&"FRESH", 444)
	var telemetry: PlaytestTelemetry = PlaytestTelemetryScript.new()
	telemetry.begin(profile, &"stage_001", path)
	telemetry.advance_simulation(0.5, 2)
	telemetry.advance_simulation(0.5, 0)
	telemetry.advance_simulation(0.5, 1)
	telemetry.record_event("draft_open", {"draft_index": 1})
	telemetry.finish(&"victory", {"kills": 3})
	var report := JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	assert_float(float(report["simulated_gameplay_seconds"])).is_equal_approx(1.5, 0.001)
	assert_float(float(report["active_combat_seconds"])).is_equal_approx(1.0, 0.001)
	assert_float(float(report["dead_air_seconds"])).is_equal_approx(0.5, 0.001)
	assert_float(float(report["active_pressure_ratio"])).is_equal_approx(2.0 / 3.0, 0.001)
	assert_float(float(report["average_live_enemy_population"])).is_equal_approx(1.0, 0.001)
	assert_int(int(report["peak_simultaneous_enemies"])).is_equal(2)
	assert_float(float(report["first_draft_gameplay_seconds"])).is_equal_approx(1.5, 0.001)
	assert_int((report["progression_events"] as Array).size()).is_equal(1)

func test_task11_telemetry_metrics_are_deterministic_for_same_samples() -> void:
	var temp_root := OS.get_environment("TMPDIR")
	if temp_root.is_empty():
		temp_root = "/tmp"
	var first_path := temp_root.path_join("acidblood-task11-deterministic-a.json")
	var second_path := temp_root.path_join("acidblood-task11-deterministic-b.json")
	var profile: Dictionary = PlaytestProfileScript.build(&"BENCHMARK", 445)
	var first: PlaytestTelemetry = PlaytestTelemetryScript.new()
	var second: PlaytestTelemetry = PlaytestTelemetryScript.new()
	first.begin(profile, &"stage_001", first_path)
	second.begin(profile, &"stage_001", second_path)
	for sample in [[0.25, 1], [0.75, 3], [0.5, 0]]:
		first.advance_simulation(float(sample[0]), int(sample[1]))
		second.advance_simulation(float(sample[0]), int(sample[1]))
	first.finish(&"victory")
	second.finish(&"victory")
	var first_report := JSON.parse_string(FileAccess.get_file_as_string(first_path)) as Dictionary
	var second_report := JSON.parse_string(FileAccess.get_file_as_string(second_path)) as Dictionary
	for key in ["simulated_gameplay_seconds", "active_combat_seconds", "dead_air_seconds",
			"active_pressure_ratio", "average_live_enemy_population", "peak_simultaneous_enemies"]:
		assert_bool(is_equal_approx(float(first_report[key]), float(second_report[key]))).is_true()

func test_task11_telemetry_aggregates_draft_offers_and_selections() -> void:
	var temp_root := OS.get_environment("TMPDIR")
	if temp_root.is_empty():
		temp_root = "/tmp"
	var path := temp_root.path_join("acidblood-task11-draft-summary.json")
	var profile: Dictionary = PlaytestProfileScript.build(&"BENCHMARK", 446)
	var telemetry: PlaytestTelemetry = PlaytestTelemetryScript.new()
	telemetry.begin(profile, &"stage_001", path)
	telemetry.advance_simulation(1.0, 2)
	telemetry.record_event("draft_open", {
		"draft_index": 1,
		"offer_ids": ["build_cannon", "sharp_rounds", "long_barrel"],
		"offer_categories": ["NEW_TURRET", "NORMAL", "NORMAL"],
	})
	telemetry.record_event("card_chosen", {"draft_index": 1, "card_id": "build_cannon", "category": "NEW_TURRET"})
	telemetry.finish(&"victory")
	var report := JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary
	var offers := report["draft_offers"] as Array
	var selections := report["selected_drafts"] as Array
	assert_int(offers.size()).is_equal(1)
	assert_int(selections.size()).is_equal(1)
	assert_str(String((offers[0] as Dictionary)["offer_ids"][0])).is_equal("build_cannon")
	assert_str(String((selections[0] as Dictionary)["card_id"])).is_equal("build_cannon")
	var build_path := report["build_path"] as Array
	assert_int(build_path.size()).is_equal(1)
	assert_str(String((build_path[0] as Dictionary)["category"])).is_equal("NEW_TURRET")
	var offer_counts := report["category_offer_counts"] as Dictionary
	var selection_counts := report["category_selection_counts"] as Dictionary
	assert_int(int(offer_counts["NEW_TURRET"])).is_equal(1)
	assert_int(int(offer_counts["NORMAL"])).is_equal(2)
	assert_int(int(selection_counts["NEW_TURRET"])).is_equal(1)

func test_frost_turret_freezes_target() -> void:
	var boot := await _boot_battle()
	var runner: GdUnitSceneRunner = boot["runner"]
	var battle := boot["battle"] as Battle
	battle.spawn_wave_enemy(&"runner", 0.0)
	var enemy := battle.enemies.back() as Enemy
	enemy.position = Vector3(0.0, 0.0, 0.0)
	_spawn_turret(battle, &"frost", Vector3(0.0, 0.0, 0.0))
	await runner.simulate_frames(30)
	assert_object(enemy).is_valid()
	assert_bool(enemy.is_frozen).is_true()

func _card_ids(cards: Array[CardData]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card in cards:
		ids.append(card.id)
	return ids

func test_frozen_brute_shatters_on_direct_heavy_impact() -> void:
	var boot := await _boot_battle()
	var runner: GdUnitSceneRunner = boot["runner"]
	var battle := boot["battle"] as Battle
	battle.spawn_wave_enemy(&"brute", 0.0)
	var enemy := battle.enemies.back() as Enemy
	enemy.position = Vector3(0.0, 0.0, 0.0)
	enemy.apply_slow(0.5, 3.0)
	var initial_hp := enemy.hp
	battle.apply_hit(enemy, 14.5, {"heavy_impact": true})
	await runner.simulate_frames(140)
	assert_object(enemy).is_valid()
	assert_bool(enemy.is_frozen).is_false()
	assert_float(enemy.hp).is_less(initial_hp - 20.0)

func test_guardian_auto_fire_hits_brute() -> void:
	var boot := await _boot_battle()
	var runner: GdUnitSceneRunner = boot["runner"]
	var battle := boot["battle"] as Battle
	battle.spawn_wave_enemy(&"brute", 0.0)
	var enemy := battle.enemies.back() as Enemy
	enemy.position = Vector3(0.0, 0.0, 2.0)
	var hp_before := enemy.hp
	await runner.simulate_frames(60)
	assert_object(enemy).is_valid()
	assert_float(enemy.hp).is_less(hp_before)

func _boot_battle() -> Dictionary:
	var runner := scene_runner(BattleScene.resource_path)
	runner.set_time_factor(1.0)
	await runner.simulate_frames(1)
	var battle := runner.scene() as Battle
	assert_object(battle).is_valid()
	return {"runner": runner, "battle": battle}

func _spawn_turret(battle: Battle, turret_id: StringName, pos: Vector3) -> Turret:
	var turret := TurretScene.instantiate() as Turret
	var turret_root := battle.get_node("Actors/Turrets") as Node3D
	turret_root.add_child(turret)
	turret.setup(battle, Catalog.turret(turret_id))
	turret.position = pos
	return turret

func _make_test_stage() -> StageData:
	var stage := StageDataScript.new() as StageData
	stage.id = &"gdunit_pilot_stage"
	stage.display_name = "GdUnit Pilot"
	stage.index = 1
	stage.fortress_hp = 100.0
	stage.hp_scale = 1.0
	stage.speed_scale = 1.0
	var wave := WaveDataScript.new() as WaveData
	wave.groups = []
	wave.pre_wave_delay = 0.0
	wave.post_delay = 0.0
	var second_wave := WaveDataScript.new() as WaveData
	second_wave.groups = []
	second_wave.pre_wave_delay = 0.0
	second_wave.post_delay = 0.0
	stage.waves = [wave, second_wave]
	return stage
