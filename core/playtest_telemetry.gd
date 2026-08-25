class_name PlaytestTelemetry
extends RefCounted
## Small structured recorder for isolated development playtest runs.

var report_path := ""
var _report: Dictionary = {}
var _events: Array[Dictionary] = []
var _started_msec := 0
var _finished := false

func begin(profile: Dictionary, stage_id: StringName, output_path: String = "") -> void:
	_finished = false
	_events.clear()
	_started_msec = Time.get_ticks_msec()
	report_path = output_path if not output_path.is_empty() else default_report_path(profile)
	_report = {
		"timestamp_unix": Time.get_unix_time_from_system(),
		"profile": profile.get("profile", "UNKNOWN"),
		"profile_version": profile.get("profile_version", "unknown"),
		"seed": int(profile.get("seed", 0)),
		"stage_id": String(stage_id),
		"initial_state": profile.get("initial_state", {}),
	}

func record_event(event_name: String, payload: Dictionary = {}) -> void:
	if _finished:
		return
	var event := payload.duplicate(true)
	event["event"] = event_name
	event["elapsed_seconds"] = float(Time.get_ticks_msec() - _started_msec) / 1000.0
	_events.append(event)

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
	_report["guardian_movement_events"] = int(payload.get("guardian_movement_events", 0))
	_report["pulse_uses"] = int(payload.get("pulse_uses", 0))
	_report["progression_events"] = _events.duplicate(true)
	_report["xp_gained"] = _events.filter(func(event: Dictionary) -> bool: return event.get("event") == "xp_gain")
	_report["level_ups"] = _events.filter(func(event: Dictionary) -> bool: return event.get("event") == "level_up")
	_report["draft_offers"] = payload.get("draft_offers", [])
	_report["selected_drafts"] = payload.get("selected_drafts", [])
	_write_report()

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
