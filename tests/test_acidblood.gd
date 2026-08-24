@tool
extends McpTestSuite

var _checks = null

func suite_name() -> String:
	return "acidblood"

func section(title: String) -> void:
	print("[%s]" % title)

func check(name: String, cond: bool) -> void:
	assert_true(cond, name)

func _get_checks():
	if _checks == null:
		_checks = load("res://tests/acidblood_checks.gd").new()
	return _checks

func test_scripts_and_scenes_load() -> void:
	_get_checks().run_scripts_and_scenes_load(self)

func test_rng_determinism() -> void:
	_get_checks().run_rng_determinism(self)

func test_draft_determinism() -> void:
	_get_checks().run_draft_determinism(self)

func test_draft_rules() -> void:
	_get_checks().run_draft_rules(self)

func test_leveling_and_run_state() -> void:
	_get_checks().run_leveling_and_run_state(self)

func test_slot_ordering() -> void:
	_get_checks().run_slot_ordering(self)

func test_combat() -> void:
	_get_checks().run_combat(self)

func test_stat_registry() -> void:
	_get_checks().run_stat_registry(self)

func test_progression_save_load() -> void:
	_get_checks().run_progression_save_load(self)

func test_campaign_data() -> void:
	_get_checks().run_campaign_data(self)

func test_data_references() -> void:
	_get_checks().run_data_references(self)

func test_content_conventions() -> void:
	_get_checks().run_content_conventions(self)
