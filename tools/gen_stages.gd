extends SceneTree
## Data pipeline: generates the 30 campaign StageData resources into
## res://data/stages/. Stages 1-2 are hand-authored definitions; stages 3-30
## are produced from rotating wave patterns plus difficulty scaling values.
## Run: godot --headless --path . --script res://tools/gen_stages.gd
## The committed .tres files are the runtime data; rerun after editing this.

const STAGE_DIR := "res://data/stages"

func _initialize() -> void:
	var defs := _stage_definitions()
	var only_stage := _only_stage()
	var count := 0
	for d in defs:
		if only_stage > 0 and int(d.index) != only_stage:
			continue
		var stage := _build_stage(d)
		var path := "%s/stage_%03d.tres" % [STAGE_DIR, stage.index]
		var err := ResourceSaver.save(stage, path)
		if err != OK:
			push_error("gen_stages: failed to save %s (%s)" % [path, err])
			quit(1)
			return
		count += 1
	print("gen_stages: wrote %d stages" % count)
	quit(0)

func _only_stage() -> int:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--only-stage="):
			return int(argument.get_slice("=", 1))
	return 0

func _build_stage(d: Dictionary) -> StageData:
	var stage := StageData.new()
	stage.id = StringName("stage_%03d" % int(d.index))
	stage.index = int(d.index)
	stage.display_name = String(d.name)
	stage.act_number = int(d.get("act_number", 0))
	stage.intent = StringName(d.get("intent", ""))
	stage.briefing = String(d.get("briefing", ""))
	stage.reward_cores = int(d.reward)
	stage.hp_scale = float(d.get("hp_scale", 1.0))
	stage.speed_scale = float(d.get("speed_scale", 1.0))
	for wave_def in d.waves:
		var wave := WaveData.new()
		wave.pre_wave_delay = float(wave_def.get("pre_wave_delay", 2.0))
		wave.post_delay = float(wave_def.get("post_delay", 2.0))
		wave.intent = StringName(wave_def.get("intent", ""))
		wave.label = String(wave_def.get("label", ""))
		for g in wave_def.groups:
			var group := SpawnGroup.new()
			group.enemy_id = StringName(g[0])
			group.count = int(g[1])
			group.interval = float(g[2])
			group.start_delay = float(g[3]) if g.size() > 3 else 0.0
			group.lane = StringName(g[4]) if g.size() > 4 else &"random"
			wave.groups.append(group)
		stage.waves.append(wave)
	return stage

func _stage_definitions() -> Array[Dictionary]:
	var defs: Array[Dictionary] = []
	# --- Stage 1: hand-authored pressure calibration (grunt / runner / spitter).
	defs.append({
		"index": 1, "name": "Processing Yard", "reward": 6, "intent": "introduce",
		"waves": [
			{"pre_wave_delay": 2.0, "post_delay": 2.0, "intent": "introduce", "label": "Opening",
				"groups": [["grunt", 10, 0.85, 0.0, "center"]]},
			{"pre_wave_delay": 2.0, "post_delay": 2.0, "intent": "reinforce", "label": "Reinforcement",
				"groups": [["grunt", 6, 0.75, 0.0, "left"], ["runner", 3, 0.8, 3.0, "right"]]},
			{"pre_wave_delay": 2.0, "post_delay": 1.0, "intent": "test", "label": "First Test",
				"groups": [["grunt", 8, 0.9, 0.0, "center"], ["runner", 4, 0.7, 4.0, "left"], ["spitter", 2, 3.0, 2.0, "center"]]},
			{"pre_wave_delay": 0.0, "post_delay": 0.7, "intent": "pressure", "label": "Directional Pressure",
				"groups": [["grunt", 36, 0.45, 0.0, "right"], ["runner", 24, 0.40, 1.0, "left"], ["spitter", 8, 1.5, 1.5, "center"]]},
			{"pre_wave_delay": 0.0, "post_delay": 0.8, "intent": "pressure", "label": "Population Surge",
				"groups": [["grunt", 48, 0.38, 0.0, "left"], ["grunt", 32, 0.38, 1.2, "right"], ["runner", 24, 0.35, 0.8, "center"]]},
			{"pre_wave_delay": 0.0, "post_delay": 0.8, "intent": "test", "label": "Yard Climax",
				"groups": [["grunt", 60, 0.34, 0.0, "right"], ["runner", 40, 0.30, 0.8, "left"], ["spitter", 15, 1.1, 1.2, "center"]]},
		],
	})
	# --- Stage 2: hand-authored; introduces the brute and the boss.
	defs.append({
		"index": 2, "name": "Service Gate", "reward": 8, "hp_scale": 1.1,
		"waves": [
			{"groups": [["grunt", 8, 0.9], ["runner", 3, 0.8, 4.0]]},
			{"groups": [["brute", 2, 4.0], ["grunt", 6, 1.0, 2.0]]},
			{"groups": [["spitter", 3, 2.5], ["runner", 6, 0.7, 3.0], ["grunt", 6, 1.0, 1.0]]},
			{"groups": [["boss_tyrant", 1, 1.0], ["grunt", 4, 2.0, 3.0]]},
		],
	})
	# --- Stages 3-30: rotating wave patterns + difficulty scaling.
	var names := ["Drain Channel", "Pump Station", "Control Annex", "Runoff Line",
		"Reservoir Access", "Loading Yard", "Pressure Deck", "Lab Intake",
		"Transit Spine", "Cooling Duct", "Service Crossing", "Flooded Block",
		"Containment Core"]
	for n in range(3, 31):
		var hp_scale := 1.0 + 0.12 * (n - 2)
		var speed_scale := minf(1.0 + 0.02 * (n - 2), 1.5)
		var waves: Array = []
		var wave_count := 3 + (n % 3)
		for w in range(wave_count):
			var pattern := (n + w) % 3
			var size_boost := int(n / 6.0)
			match pattern:
				0:
					waves.append({"groups": [
						["grunt", 7 + size_boost, 1.0],
						["runner", 3 + size_boost, 0.8, 3.0]]})
				1:
					waves.append({"groups": [
						["grunt", 5 + size_boost, 1.1],
						["spitter", 2 + int(size_boost / 2.0), 2.6, 2.0],
						["runner", 4, 0.7, 5.0]]})
				2:
					waves.append({"groups": [
						["brute", 1 + int(size_boost / 2.0), 3.5],
						["grunt", 6 + size_boost, 1.0, 1.5]]})
		if n % 10 == 0:
			waves.append({"groups": [["boss_tyrant", 1, 1.0], ["runner", 6, 1.2, 4.0]]})
		defs.append({
			"index": n,
			"name": "%s %d" % [names[(n - 3) % names.size()], n],
			"reward": 6 + n,
			"hp_scale": hp_scale,
			"speed_scale": speed_scale,
			"waves": waves,
		})
	return defs
