extends SceneTree
## Data pipeline: generates the 30 campaign StageData resources into
## res://data/stages/. Stages 1-2 are hand-authored definitions; stages 3-30
## are produced from rotating wave patterns plus difficulty scaling values.
## Run: godot --headless --path . --script res://tools/gen_stages.gd
## The committed .tres files are the runtime data; rerun after editing this.

const STAGE_DIR := "res://data/stages"

func _initialize() -> void:
	var defs := _stage_definitions()
	var count := 0
	for d in defs:
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

func _build_stage(d: Dictionary) -> StageData:
	var stage := StageData.new()
	stage.id = StringName("stage_%03d" % int(d.index))
	stage.index = int(d.index)
	stage.display_name = String(d.name)
	stage.reward_cores = int(d.reward)
	stage.hp_scale = float(d.get("hp_scale", 1.0))
	stage.speed_scale = float(d.get("speed_scale", 1.0))
	for wave_def in d.waves:
		var wave := WaveData.new()
		wave.post_delay = float(wave_def.get("post_delay", 2.0))
		for g in wave_def.groups:
			var group := SpawnGroup.new()
			group.enemy_id = StringName(g[0])
			group.count = int(g[1])
			group.interval = float(g[2])
			group.start_delay = float(g[3]) if g.size() > 3 else 0.0
			wave.groups.append(group)
		stage.waves.append(wave)
	return stage

func _stage_definitions() -> Array[Dictionary]:
	var defs: Array[Dictionary] = []
	# --- Stage 1: hand-authored tutorial pacing (grunt / runner / spitter).
	defs.append({
		"index": 1, "name": "Outer Fields", "reward": 6,
		"waves": [
			{"groups": [["grunt", 6, 1.2]]},
			{"groups": [["grunt", 6, 1.0], ["runner", 3, 0.8, 3.0]]},
			{"groups": [["grunt", 8, 0.9], ["runner", 4, 0.7, 4.0], ["spitter", 2, 3.0, 2.0]]},
		],
	})
	# --- Stage 2: hand-authored; introduces the brute and the boss.
	defs.append({
		"index": 2, "name": "Broken Gate", "reward": 8, "hp_scale": 1.1,
		"waves": [
			{"groups": [["grunt", 8, 0.9], ["runner", 3, 0.8, 4.0]]},
			{"groups": [["brute", 2, 4.0], ["grunt", 6, 1.0, 2.0]]},
			{"groups": [["spitter", 3, 2.5], ["runner", 6, 0.7, 3.0], ["grunt", 6, 1.0, 1.0]]},
			{"groups": [["boss_tyrant", 1, 1.0], ["grunt", 4, 2.0, 3.0]]},
		],
	})
	# --- Stages 3-30: rotating wave patterns + difficulty scaling.
	var names := ["Ash Road", "Mire", "Watchpost", "Deep Vale", "Ridge", "Hollow",
		"Ramparts", "Old Keep", "Frontier", "Wastes", "Crossing", "Bluffs", "Sanctum"]
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
