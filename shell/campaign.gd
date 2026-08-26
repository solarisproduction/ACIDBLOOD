extends Control
## Campaign screen: 30 data-driven stage entries with sequential unlocking,
## plus developer traversal tools (debug builds only).

@onready var grid: GridContainer = %StageGrid
@onready var back_button: Button = %BackButton
@onready var dev_box: HBoxContainer = %DevBox
@onready var auto_win_button: Button = %AutoWinButton
@onready var reset_button: Button = %ResetButton
@onready var entry_title: Label = %EntryTitle
@onready var entry_meta: Label = %EntryMeta
@onready var entry_briefing: Label = %EntryBriefing
@onready var deploy_button: Button = %DeployButton

var _selected_stage: StageData

func _ready() -> void:
	back_button.pressed.connect(func() -> void: Game.change_scene(Game.HOME_SCENE))
	deploy_button.pressed.connect(_deploy_selected_stage)
	dev_box.visible = OS.is_debug_build()
	auto_win_button.pressed.connect(_on_auto_win)
	reset_button.pressed.connect(_on_reset)
	_refresh()
	back_button.call_deferred("grab_focus")

func _refresh() -> void:
	for child in grid.get_children():
		child.queue_free()
	var stages := Catalog.stages()
	var ids := Catalog.ordered_stage_ids()
	for i in stages.size():
		var stage := stages[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(120, 90)
		btn.add_theme_font_size_override("font_size", 26)
		var unlocked := Game.progression.is_stage_unlocked(i, ids)
		if Game.progression.is_stage_completed(stage.id):
			btn.text = "%d\n*" % stage.index
		elif unlocked:
			btn.text = str(stage.index)
		else:
			btn.text = "%d\nX" % stage.index
			btn.disabled = true
		btn.tooltip_text = "Act %d • %s\n%s" % [stage.resolved_act_number(), stage.intent_label(), stage.display_name]
		if not stage.briefing.is_empty():
			btn.tooltip_text += "\n" + stage.briefing
		btn.pressed.connect(func() -> void: _select_stage(stage))
		grid.add_child(btn)
	if _selected_stage == null or not Game.progression.is_stage_unlocked(_selected_stage.index - 1, ids):
		_select_stage(stages[0] if not stages.is_empty() else null)
	else:
		_select_stage(_selected_stage)

func _select_stage(stage: StageData) -> void:
	if stage == null:
		_selected_stage = null
		entry_title.text = "NO OPERATION AVAILABLE"
		entry_meta.text = ""
		entry_briefing.text = ""
		deploy_button.disabled = true
		return
	var ids := Catalog.ordered_stage_ids()
	if not Game.progression.is_stage_unlocked(stage.index - 1, ids):
		return
	_selected_stage = stage
	entry_title.text = "%02d  %s" % [stage.index, stage.display_name]
	entry_meta.text = "ACT %d  •  %s  •  %d WAVES  •  REWARD %d SALVAGE" % [
		stage.resolved_act_number(), stage.intent_label().to_upper(), stage.waves.size(), stage.reward_cores]
	entry_briefing.text = stage.briefing if not stage.briefing.is_empty() else "Operation briefing unavailable."
	deploy_button.disabled = false
	deploy_button.call_deferred("grab_focus")

func _deploy_selected_stage() -> void:
	if _selected_stage != null:
		Game.start_stage(_selected_stage)

## Dev traversal: complete the first unlocked-but-uncompleted stage without
## playing it, applying the normal reward path.
func _on_auto_win() -> void:
	var stages := Catalog.stages()
	var ids := Catalog.ordered_stage_ids()
	for i in stages.size():
		var stage := stages[i]
		if Game.progression.is_stage_unlocked(i, ids) and not Game.progression.is_stage_completed(stage.id):
			Game.progression.apply_victory(stage.id, stage.reward_cores)
			Game.progression.save()
			break
	_refresh()

func _on_reset() -> void:
	Game.progression = Progression.new()
	Game.progression.save()
	_refresh()
