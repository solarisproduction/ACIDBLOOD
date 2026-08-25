@tool
class_name AcidbloodBehavioralSuite
extends GdUnitTestSuite

const BattleScene := preload("res://game/battle.tscn")
const TurretScene := preload("res://game/turret.tscn")
const StageDataScript := preload("res://data/types/stage_data.gd")
const WaveDataScript := preload("res://data/types/wave_data.gd")

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

func test_phase1_new_turret_capacity_and_duplicate_occupancy() -> void:
	var run := RunState.new()
	assert_bool(run.install_turret(&"cannon", 0)).is_true()
	assert_bool(run.install_turret(&"cannon", 0)).is_false()
	assert_bool(run.install_turret(&"cannon", 1)).is_false()
	for slot_index in range(1, 4):
		assert_bool(run.install_turret(StringName("turret_%d" % slot_index), slot_index)).is_true()
	assert_int(run.available_slot_count()).is_equal(0)
	assert_bool(run.install_turret(&"cannon", 0)).is_false()

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
