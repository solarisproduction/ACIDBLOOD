extends Node

const AcidbloodSuiteRun := preload("res://tests/run_tests.gd")

func _ready() -> void:
	call_deferred("_run_suite")

func _run_suite() -> void:
	var runner := AcidbloodSuiteRun.new()
	var ctx := await _wait_for_project_context(3.0)
	print(
		"BOOT_CONTEXT game_available=%s helper_available=%s game_autoload=%s helper_autoload=%s"
		% [
			_bool_text(bool(ctx["game_available"])),
			_bool_text(bool(ctx["helper_available"])),
			ctx["game_autoload"],
			ctx["helper_autoload"],
		]
	)
	if not bool(ctx["game_available"]):
		print("BOOT_FAILURE missing required Game autoload")
		get_tree().quit(1)
		return
	if not bool(ctx["helper_available"]):
		print("BOOT_INFO _mcp_game_helper unavailable (non-fatal)")

	var result := runner.run_all()
	print("")
	if int(result["failures"]) > 0:
		print("TESTS FAILED: %d of %d checks failed" % [result["failures"], result["checks"]])
		get_tree().quit(1)
	else:
		print("ALL TESTS PASSED (%d checks)" % result["checks"])
		get_tree().quit(0)

func _bool_text(value: bool) -> String:
	return "true" if value else "false"

func _wait_for_project_context(timeout_sec: float) -> Dictionary:
	var runner := AcidbloodSuiteRun.new()
	var ctx := runner.project_context()
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while not ctx.game_available and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		ctx = runner.project_context()
	return ctx
