class_name WaveDirector
extends Node

enum State { IDLE, DELAY, SPAWNING, CLEARING, DONE }

const INITIAL_DELAY := 1.5

var battle: Battle
var stage: StageData
var wave_index := 0          # 1-based, wave currently running (or last run)
var _state := State.IDLE
var _timer := 0.0
var _groups: Array[Dictionary] = []  # {group: SpawnGroup, spawned: int, t: float}

func configure(b: Battle, s: StageData) -> void:
	battle = b
	stage = s
	_state = State.DELAY
	_timer = INITIAL_DELAY
	if stage != null and not stage.waves.is_empty():
		var first_wave := stage.waves[0] as WaveData
		_timer = maxf(_timer, first_wave.pre_wave_delay)

func _physics_process(delta: float) -> void:
	match _state:
		State.DELAY:
			_timer -= delta
			if _timer <= 0.0:
				_start_next_wave()
		State.SPAWNING:
			_tick_spawns(delta)
		State.CLEARING:
			if battle.enemies.is_empty():
				if wave_index >= stage.waves.size():
					_state = State.DONE
					battle.on_stage_cleared()
				else:
					var next_wave := stage.waves[wave_index] as WaveData
					battle.preview_wave(wave_index + 1, stage.waves.size(), next_wave)
					_state = State.DELAY
					var current_wave := stage.waves[wave_index - 1] as WaveData
					_timer = maxf(current_wave.post_delay, next_wave.pre_wave_delay)
		_:
			pass

func _start_next_wave() -> void:
	wave_index += 1
	var wave := stage.waves[wave_index - 1] as WaveData
	battle.on_wave_started(wave_index, stage.waves.size(), wave)
	_groups.clear()
	for g in wave.groups:
		_groups.append({"group": g, "spawned": 0, "t": g.start_delay})
	_state = State.SPAWNING

func _tick_spawns(delta: float) -> void:
	var all_done := true
	for gs in _groups:
		var g: SpawnGroup = gs.group
		if gs.spawned >= g.count:
			continue
		all_done = false
		gs.t -= delta
		while gs.t <= 0.0 and gs.spawned < g.count:
			battle.spawn_wave_enemy(g.enemy_id, battle.roll_spawn_x())
			gs.spawned += 1
			gs.t += maxf(g.interval, 0.0)
			if g.interval <= 0.0:
				gs.t = 0.0 if gs.spawned < g.count else 1.0
	if all_done:
		_state = State.CLEARING
