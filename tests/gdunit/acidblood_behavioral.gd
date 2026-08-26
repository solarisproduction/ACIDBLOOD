@tool
class_name AcidbloodBehavioralSuite
extends GdUnitTestSuite

const BattleScene := preload("res://game/battle.tscn")
const TurretScene := preload("res://game/turret.tscn")
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
