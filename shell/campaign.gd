extends Control
## Campaign screen: 30 data-driven stage entries with sequential unlocking,
## plus developer traversal tools (debug builds only).

@onready var grid: GridContainer = %StageGrid
@onready var back_button: Button = %BackButton
@onready var dev_box: HBoxContainer = %DevBox
@onready var auto_win_button: Button = %AutoWinButton
@onready var reset_button: Button = %ResetButton

func _ready() -> void:
	back_button.pressed.connect(func() -> void: Game.change_scene(Game.HOME_SCENE))
	dev_box.visible = OS.is_debug_build()
	auto_win_button.pressed.connect(_on_auto_win)
	reset_button.pressed.connect(_on_reset)
	_refresh()

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
		btn.tooltip_text = stage.display_name
		btn.pressed.connect(func() -> void: Game.start_stage(stage))
		grid.add_child(btn)

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
