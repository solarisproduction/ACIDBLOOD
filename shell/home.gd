extends Control
## Home screen: entry point, cores display and the permanent upgrade shop.

@onready var cores_label: Label = %CoresLabel
@onready var upgrades_box: VBoxContainer = %UpgradesBox
@onready var play_button: Button = %PlayButton

func _ready() -> void:
	play_button.pressed.connect(func() -> void: Game.change_scene(Game.CAMPAIGN_SCENE))
	_refresh()

func _refresh() -> void:
	cores_label.text = "Cores: %d" % Game.progression.cores
	for child in upgrades_box.get_children():
		child.queue_free()
	for up in Catalog.perm_upgrades():
		upgrades_box.add_child(_make_upgrade_row(up))

func _make_upgrade_row(up: PermUpgradeData) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	var level := Game.progression.upgrade_level(up.id)
	label.text = "%s  %d/%d" % [up.display_name, level, up.max_level]
	label.tooltip_text = up.description
	label.add_theme_font_size_override("font_size", 24)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 22)
	if level >= up.max_level:
		btn.text = "MAX"
		btn.disabled = true
	else:
		btn.text = "Buy (%d)" % Game.progression.upgrade_cost(up)
		btn.disabled = not Game.progression.can_buy_upgrade(up)
		btn.pressed.connect(func() -> void:
			if Game.progression.buy_upgrade(up):
				Game.progression.save()
				_refresh())
	row.add_child(btn)
	return row
