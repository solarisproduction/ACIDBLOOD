@tool
class_name AcidbloodSuiteRun
extends RefCounted

const AcidbloodChecks := preload("res://tests/acidblood_checks.gd")

class ValidationSink:
	var failures := 0
	var checks := 0

	func section(title: String) -> void:
		print("[%s]" % title)

	func check(name: String, cond: bool) -> void:
		checks += 1
		if cond:
			print("  PASS  %s" % name)
		else:
			failures += 1
			print("  FAIL  %s" % name)

func project_context() -> Dictionary:
	return {
		"game_available": _autoload_available("Game"),
		"helper_available": _autoload_available("_mcp_game_helper"),
		"game_autoload": String(ProjectSettings.get_setting("autoload/Game", "")),
		"helper_autoload": String(ProjectSettings.get_setting("autoload/_mcp_game_helper", "")),
	}

func _autoload_available(node_name: String) -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	return tree.root.get_node_or_null(node_name) != null

func run_all() -> Dictionary:
	var sink := ValidationSink.new()
	AcidbloodChecks.new().run_all(sink)
	return {
		"checks": sink.checks,
		"failures": sink.failures,
	}
