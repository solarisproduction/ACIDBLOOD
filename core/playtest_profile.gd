class_name PlaytestProfile
extends RefCounted
## Explicit, non-persistent initialization profiles for development runs.

const FRESH := &"FRESH"
const BENCHMARK := &"BENCHMARK"
const FRESH_VERSION := "fresh-v1"
const BENCHMARK_VERSION := "benchmark-v1"
const DEFAULT_FRESH_SEED := 11001
const DEFAULT_BENCHMARK_SEED := 22001

static func build(profile_id: StringName, seed_value: int = 0) -> Dictionary:
	var normalized := String(profile_id).to_upper()
	var is_benchmark := normalized == String(BENCHMARK)
	var profile := BENCHMARK if is_benchmark else FRESH
	var seed := seed_value
	if seed == 0:
		seed = DEFAULT_BENCHMARK_SEED if is_benchmark else DEFAULT_FRESH_SEED
	return {
		"profile": profile,
		"profile_version": BENCHMARK_VERSION if is_benchmark else FRESH_VERSION,
		"seed": seed,
		"initial_stage": 1,
		"initial_state": _initial_state(is_benchmark),
	}

static func progression_for(profile: Dictionary) -> Progression:
	var progression := Progression.new()
	var initial_state: Dictionary = profile.get("initial_state", {})
	progression.cores = int(initial_state.get("cores", 0))
	for stage_id in initial_state.get("completed_stages", []):
		progression.completed_stages.append(String(stage_id))
	var upgrade_levels: Dictionary = initial_state.get("upgrade_levels", {})
	for upgrade_id in upgrade_levels:
		progression.upgrade_levels[String(upgrade_id)] = int(upgrade_levels[upgrade_id])
	progression.save_path = _discard_path(profile)
	return progression

static func _initial_state(is_benchmark: bool) -> Dictionary:
	if not is_benchmark:
		return {"cores": 0, "completed_stages": [], "upgrade_levels": {}, "owned_cards": [], "unlock_flags": []}
	return {
		"cores": 17,
		"completed_stages": ["stage_001", "stage_002"],
		"upgrade_levels": {"guardian_core": 2, "frost_protocol": 1},
		"owned_cards": [],
		"unlock_flags": ["frost_turret"],
	}

static func _discard_path(profile: Dictionary) -> String:
	var temp_root := OS.get_environment("TMPDIR")
	if temp_root.is_empty():
		temp_root = "/tmp"
	return temp_root.path_join("acidblood-playtest-%s.json" % String(profile.get("profile", "UNKNOWN")).to_lower())
