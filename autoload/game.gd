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
## When true the battle auto-picks the first draft card (smoke tests).
var autoplay := false

var _smoke := false
var _smoke_start_ms := 0

func _ready() -> void:
	progression = Progression.load_or_new()
	var args := OS.get_cmdline_user_args()
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

func _process(_delta: float) -> void:
	if _smoke and Time.get_ticks_msec() - _smoke_start_ms > 120_000:
		print("SMOKE_TIMEOUT")
		get_tree().quit(3)

func _start_smoke(stage_index: int) -> void:
	var stage := Catalog.stage_by_index(stage_index)
	if stage == null:
		print("SMOKE_ERROR missing stage %d" % stage_index)
		get_tree().quit(2)
		return
	start_stage(stage, 1337)

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
	if victory:
		awarded = progression.apply_victory(current_stage.id, current_stage.reward_cores)
		progression.save()
	last_result = {
		"victory": victory,
		"stage_name": current_stage.display_name,
		"stage_index": current_stage.index,
		"awarded_cores": awarded,
		"stats": stats,
	}
	if _smoke:
		print("SMOKE_RESULT victory=%s stage=%d kills=%d wave=%d level=%d fortress_hp=%.1f cards=%d" % [
			victory, current_stage.index, stats.get("kills", 0), stats.get("wave", 0),
			stats.get("level", 0), stats.get("fortress_hp", 0.0), stats.get("cards", 0)])
		get_tree().quit(0)
		return
	change_scene(RESULT_SCENE)

func change_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
