class_name PlaytestTelemetry
extends RefCounted
## Small structured recorder for isolated development playtest runs.

var report_path := ""
var _report: Dictionary = {}
var _events: Array[Dictionary] = []
var _started_msec := 0
var _finished := false
var _simulated_gameplay_seconds := 0.0
var _active_combat_seconds := 0.0
var _dead_air_seconds := 0.0
var _population_time_integral := 0.0
var _peak_live_population := 0
var _draft_gameplay_times: Array[float] = []

func begin(profile: Dictionary, stage_id: StringName, output_path: String = "") -> void:
	_finished = false
	_events.clear()
	_started_msec = Time.get_ticks_msec()
	_simulated_gameplay_seconds = 0.0
	_active_combat_seconds = 0.0
	_dead_air_seconds = 0.0
	_population_time_integral = 0.0
	_peak_live_population = 0
	_draft_gameplay_times.clear()
	report_path = output_path if not output_path.is_empty() else default_report_path(profile)
	_report = {
		"timestamp_unix": Time.get_unix_time_from_system(),
		"profile": profile.get("profile", "UNKNOWN"),
		"profile_version": profile.get("profile_version", "unknown"),
		"seed": int(profile.get("seed", 0)),
		"stage_id": String(stage_id),
		"initial_state": profile.get("initial_state", {}),
	}

func advance_simulation(delta: float, live_population: int) -> void:
	if _finished:
		return
	var sample_seconds := maxf(0.0, delta)
	var population := maxi(0, live_population)
	_simulated_gameplay_seconds += sample_seconds
	_population_time_integral += float(population) * sample_seconds
	_peak_live_population = maxi(_peak_live_population, population)
	if population > 0:
		_active_combat_seconds += sample_seconds
	else:
		_dead_air_seconds += sample_seconds

func record_event(event_name: String, payload: Dictionary = {}) -> void:
	if _finished:
		return
	var event := payload.duplicate(true)
	event["event"] = event_name
	event["elapsed_seconds"] = float(Time.get_ticks_msec() - _started_msec) / 1000.0
	event["gameplay_seconds"] = _simulated_gameplay_seconds
	_events.append(event)
	if event_name == "draft_open":
		_draft_gameplay_times.append(_simulated_gameplay_seconds)

func finish(outcome: StringName, payload: Dictionary = {}) -> void:
	if _finished:
		return
	_finished = true
	var elapsed := float(Time.get_ticks_msec() - _started_msec) / 1000.0
	_report["outcome"] = String(outcome)
	_report["elapsed_seconds"] = float(payload.get("elapsed_seconds", elapsed))
	_report["kills"] = int(payload.get("kills", 0))
	_report["total_xp"] = int(payload.get("total_xp", 0))
	_report["final_level"] = int(payload.get("final_level", 1))
	_report["pending_level_ups"] = int(payload.get("pending_level_ups", 0))
	_report["barricade_final_hp"] = float(payload.get("barricade_final_hp", payload.get("fortress_hp", 0.0)))
	_report["barricade_damage_taken"] = float(payload.get("barricade_damage_taken", 0.0))
	_report["peak_simultaneous_enemies"] = int(payload.get("peak_simultaneous_enemies", 0))
	_report["simulated_gameplay_seconds"] = _simulated_gameplay_seconds
	_report["active_combat_seconds"] = _active_combat_seconds
	_report["dead_air_seconds"] = _dead_air_seconds
	_report["active_pressure_ratio"] = _active_combat_seconds / maxf(0.001, _simulated_gameplay_seconds)
	_report["average_live_enemy_population"] = _population_time_integral / maxf(0.001, _simulated_gameplay_seconds)
	_report["peak_simultaneous_enemies"] = maxi(int(_report["peak_simultaneous_enemies"]), _peak_live_population)
	_report["draft_count"] = _draft_gameplay_times.size()
	_report["draft_gameplay_seconds"] = _draft_gameplay_times.duplicate()
	_report["first_draft_gameplay_seconds"] = _draft_gameplay_times[0] if not _draft_gameplay_times.is_empty() else -1.0
	_report["draft_intervals"] = _draft_intervals()
	_report["guardian_movement_events"] = int(payload.get("guardian_movement_events", 0))
	_report["pulse_uses"] = int(payload.get("pulse_uses", 0))
	_report["progression_events"] = _events.duplicate(true)
	_report["xp_gained"] = _events.filter(func(event: Dictionary) -> bool: return event.get("event") == "xp_gain")
	_report["level_ups"] = _events.filter(func(event: Dictionary) -> bool: return event.get("event") == "level_up")
	_report["draft_offers"] = _draft_offer_summaries()
	var selected_drafts := _draft_selection_summaries()
	_report["selected_drafts"] = selected_drafts
	_report["build_path"] = selected_drafts.duplicate(true)
	_report["category_offer_counts"] = _category_offer_counts()
	_report["category_selection_counts"] = _category_selection_counts()
	_write_report()

func _draft_offer_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for event in _events:
		if event.get("event") != "draft_open":
			continue
		summaries.append({
			"draft_index": int(event.get("draft_index", 0)),
			"gameplay_seconds": float(event.get("gameplay_seconds", 0.0)),
			"offer_ids": (event.get("offer_ids", []) as Array).duplicate(),
			"categories": (event.get("offer_categories", []) as Array).duplicate(),
		})
	return summaries

func _draft_selection_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for event in _events:
		if event.get("event") != "card_chosen":
			continue
		summaries.append({
			"draft_index": int(event.get("draft_index", 0)),
			"gameplay_seconds": float(event.get("gameplay_seconds", 0.0)),
			"card_id": String(event.get("card_id", "")),
			"category": String(event.get("category", "")),
			"weapon_family": String(event.get("weapon_family", "")),
		})
	return summaries

func _category_offer_counts() -> Dictionary:
	var counts := {}
	for event in _events:
		if event.get("event") != "draft_open":
			continue
		for category in event.get("offer_categories", []):
			var key := String(category)
			counts[key] = int(counts.get(key, 0)) + 1
	return counts

func _category_selection_counts() -> Dictionary:
	var counts := {}
	for event in _events:
		if event.get("event") != "card_chosen":
			continue
		var category := String(event.get("category", ""))
		if category.is_empty():
			continue
		counts[category] = int(counts.get(category, 0)) + 1
	return counts

func _draft_intervals() -> Array[float]:
	var intervals: Array[float] = []
	for index in range(1, _draft_gameplay_times.size()):
		intervals.append(_draft_gameplay_times[index] - _draft_gameplay_times[index - 1])
	return intervals

func _write_report() -> void:
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	if file == null:
		push_error("PlaytestTelemetry: cannot write %s" % report_path)
		return
	file.store_string(JSON.stringify(_report, "\t"))
	file.close()

static func default_report_path(profile: Dictionary) -> String:
	var temp_root := OS.get_environment("TMPDIR")
	if temp_root.is_empty():
		temp_root = "/tmp"
	var stamp := Time.get_unix_time_from_system()
	return temp_root.path_join("acidblood-playtest-%s-%d.json" % [String(profile.get("profile", "unknown")).to_lower(), stamp])
