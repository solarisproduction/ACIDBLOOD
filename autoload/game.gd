extends Node
## App-flow singleton (autoload "Game"): owns permanent progression, hands the
## selected stage + seed to the Battle scene, and routes end-of-run results.
## Also hosts the headless smoke-test automation (--smoke user arg).

const HOME_SCENE := "res://shell/home.tscn"
const CAMPAIGN_SCENE := "res://shell/campaign.tscn"
const BATTLE_SCENE := "res://game/battle.tscn"
const RESULT_SCENE := "res://shell/result.tscn"

var progression: Progression
var current_stage: StageData = null
var pending_seed: int = 0
var last_result: Dictionary = {}
var playtest_active := false
var playtest_profile: Dictionary = {}
var playtest_telemetry: PlaytestTelemetry
## When true the battle auto-picks the first draft card (smoke tests).
var autoplay := false

var _smoke := false
var _smoke_start_ms := 0
var _screenshot_path := ""
var _screenshot_delay := 6.0

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var has_playtest := false
	for argument in args:
		if argument.begins_with("--playtest="):
			has_playtest = true
			break
	progression = Progression.new() if has_playtest else Progression.load_or_new()
	if args.has("--smoke"):
		_smoke = true
		autoplay = true
		Engine.time_scale = 8.0
		# Never touch the real player save from automated runs.
		progression = Progression.new()
		progression.save_path = "user://smoke_save.json"
		var stage_index := 1
		for a in args:
			if a.begins_with("--smoke-stage="):
				stage_index = int(a.get_slice("=", 1))
		_smoke_start_ms = Time.get_ticks_msec()
		call_deferred("_start_smoke", stage_index)
	for argument in args:
		if argument == "--playtest-autoplay":
			autoplay = true
		elif argument.begins_with("--playtest-time-scale="):
			Engine.time_scale = maxf(0.1, float(argument.get_slice("=", 1)))
	for a in args:
		if a.begins_with("--screenshot="):
			_screenshot_path = a.get_slice("=", 1)
		elif a.begins_with("--screenshot-delay="):
			_screenshot_delay = float(a.get_slice("=", 1))
	if _screenshot_path != "":
		progression = Progression.new()
		progression.save_path = "user://smoke_save.json"
		call_deferred("_start_screenshot")
	for argument in args:
		if argument.begins_with("--playtest="):
			var profile_id := StringName(argument.get_slice("=", 1))
			var seed_value := _argument_int(args, "--playtest-seed=", 0)
			var report_path := _argument_string(args, "--playtest-report=", "")
			call_deferred("_start_playtest", profile_id, seed_value, report_path)

func _process(_delta: float) -> void:
	if _smoke and Time.get_ticks_msec() - _smoke_start_ms > 120_000:
		var current := get_tree().current_scene
		if current != null and current.has_method("debug_snapshot"):
			print("SMOKE_DEBUG %s" % JSON.stringify(current.debug_snapshot()))
		print("SMOKE_TIMEOUT")
		get_tree().quit(3)

func _scratch_save_path(filename: String) -> String:
	var temp_root := OS.get_environment("TMPDIR")
	if temp_root.is_empty():
		temp_root = "/tmp"
	return temp_root.path_join(filename)

## Dev tool: launches stage 1 and saves a viewport capture after the delay,
## for visual verification without manual play. Ignores pause (draft overlay
## stays open without autoplay, so late captures show the card UI).
func _start_screenshot() -> void:
	if not OS.get_cmdline_user_args().has("--screenshot-stay"):
		start_stage(Catalog.stage_by_index(1), 1337)
	await get_tree().create_timer(_screenshot_delay, true, false, true).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_screenshot_path)
	print("SCREENSHOT_SAVED %s" % _screenshot_path)
	get_tree().quit(0)

func _start_smoke(stage_index: int) -> void:
	var stage := Catalog.stage_by_index(stage_index)
	if stage == null:
		print("SMOKE_ERROR missing stage %d" % stage_index)
		get_tree().quit(2)
		return
	progression.save_path = _scratch_save_path("acidblood-smoke-save.json")
	start_stage(stage, 1337)

func _start_playtest(profile_id: StringName, seed_value: int, report_path: String) -> void:
	playtest_active = true
	playtest_profile = PlaytestProfile.build(profile_id, seed_value)
	progression = PlaytestProfile.progression_for(playtest_profile)
	var stage := Catalog.stage_by_index(int(playtest_profile.get("initial_stage", 1)))
	if stage == null:
		push_error("Playtest: missing initial stage")
		get_tree().quit(2)
		return
	var resolved_seed := int(playtest_profile.get("seed", 0))
	playtest_telemetry = PlaytestTelemetry.new()
	playtest_telemetry.begin(playtest_profile, stage.id, report_path)
	start_stage(stage, resolved_seed)

func _argument_int(args: PackedStringArray, prefix: String, fallback: int) -> int:
	for argument in args:
		if argument.begins_with(prefix):
			return int(argument.get_slice("=", 1))
	return fallback

func _argument_string(args: PackedStringArray, prefix: String, fallback: String) -> String:
	for argument in args:
		if argument.begins_with(prefix):
			return argument.get_slice("=", 1)
	return fallback

func start_stage(stage: StageData, seed_override: int = 0) -> void:
	current_stage = stage
	if seed_override != 0:
		pending_seed = seed_override
	else:
		pending_seed = int(Time.get_ticks_usec()) ^ (randi() << 8)
		if pending_seed == 0:
			pending_seed = 1
	change_scene(BATTLE_SCENE)

func end_run(victory: bool, stats: Dictionary) -> void:
	var awarded := 0
	if victory and not playtest_active:
		awarded = progression.apply_victory(current_stage.id, current_stage.reward_cores)
		progression.save()
	last_result = {
		"victory": victory,
		"stage_name": current_stage.display_name,
		"stage_index": current_stage.index,
		"awarded_cores": awarded,
		"stats": stats,
	}
	if playtest_active:
		call_deferred("_quit_playtest")
		return
	if _smoke:
		print("SMOKE_RESULT victory=%s stage=%d kills=%d wave=%d level=%d fortress_hp=%.1f cards=%d" % [
			victory, current_stage.index, stats.get("kills", 0), stats.get("wave", 0),
			stats.get("level", 0), stats.get("fortress_hp", 0.0), stats.get("cards", 0)])
		# Still traverse the result screen so the full shell loop is exercised.
		change_scene(RESULT_SCENE)
		for i in 5:
			await get_tree().process_frame
		get_tree().quit(0)
		return
	change_scene(RESULT_SCENE)

func change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)

func record_playtest_event(event_name: String, payload: Dictionary = {}) -> void:
	if playtest_active and playtest_telemetry != null:
		playtest_telemetry.record_event(event_name, payload)

func record_playtest_simulation(delta: float, live_population: int) -> void:
	if playtest_active and playtest_telemetry != null:
		playtest_telemetry.advance_simulation(delta, live_population)

func finish_playtest(outcome: StringName, payload: Dictionary = {}) -> void:
	if not playtest_active or playtest_telemetry == null:
		return
	playtest_telemetry.finish(outcome, payload)

func _quit_playtest() -> void:
	await get_tree().process_frame
	get_tree().quit(0)
