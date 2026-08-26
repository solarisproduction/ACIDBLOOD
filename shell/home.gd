extends Control
## Home screen: entry point, cores display and the permanent upgrade shop.

@onready var cores_label: Label = %CoresLabel
@onready var upgrades_box: VBoxContainer = %UpgradesBox
@onready var play_button: Button = %PlayButton

const TRACK_ORDER: Array[StringName] = [
	PermUpgradeData.TRACK_FORTRESS,
	PermUpgradeData.TRACK_COMMAND,
	PermUpgradeData.TRACK_ENGINEERING,
	PermUpgradeData.TRACK_GENERAL,
]

const TRACK_TITLES := {
	PermUpgradeData.TRACK_FORTRESS: "Barricade",
	PermUpgradeData.TRACK_COMMAND: "Guardian",
	PermUpgradeData.TRACK_ENGINEERING: "Turrets",
	PermUpgradeData.TRACK_GENERAL: "General",
}

func _ready() -> void:
	play_button.pressed.connect(func() -> void: Game.change_scene(Game.CAMPAIGN_SCENE))
	_refresh()
	# The automated playtest leaves Home immediately; guard the deferred focus
	# against the scene transition before calling Control.grab_focus().
	call_deferred("_focus_play_button")

func _focus_play_button() -> void:
	if is_inside_tree() and is_instance_valid(play_button) and play_button.is_inside_tree():
		play_button.grab_focus()

func _refresh() -> void:
	cores_label.text = "Salvage: %d" % Game.progression.cores
	for child in upgrades_box.get_children():
		child.queue_free()
	var grouped := _group_upgrades_by_track(Catalog.perm_upgrades())
	for track in TRACK_ORDER:
		var ups: Array = grouped.get(track, [])
		if ups.is_empty():
			continue
		upgrades_box.add_child(_make_track_section(track, ups))

func _group_upgrades_by_track(upgrades: Array[PermUpgradeData]) -> Dictionary:
	var grouped := {}
	for track in TRACK_ORDER:
		grouped[track] = []
	for up in upgrades:
		if not grouped.has(up.track):
			grouped[up.track] = []
		(grouped[up.track] as Array).append(up)
	return grouped

func _make_track_section(track: StringName, upgrades: Array) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	var title := Label.new()
	title.text = String(TRACK_TITLES.get(track, String(track).capitalize()))
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)

	for up in upgrades:
		box.add_child(_make_upgrade_row(up))
	return box

func _make_upgrade_row(up: PermUpgradeData) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	var level := Game.progression.upgrade_level(up.id)
	label.text = "%s  %d/%d\n%s" % [up.display_name, level, up.max_level, up.description]
	label.tooltip_text = _upgrade_tooltip(up)
	label.add_theme_font_size_override("font_size", 22)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(label)
	var btn := Button.new()
	btn.add_theme_font_size_override("font_size", 22)
	if level >= up.max_level:
		btn.text = "MAX"
		btn.disabled = true
	elif not Game.progression.meets_requirements(up):
		btn.text = _requirements_text(up)
		btn.disabled = true
	else:
		btn.text = _upgrade_button_text(up, level)
		btn.disabled = not Game.progression.can_buy_upgrade(up)
		btn.pressed.connect(func() -> void:
			if Game.progression.buy_upgrade(up):
				Game.progression.save()
				_refresh())
	row.add_child(btn)
	return row

func _requirements_text(up: PermUpgradeData) -> String:
	if up.requires_nodes.is_empty():
		return "Locked"
	var names: Array[String] = []
	for req in up.requires_nodes:
		var req_up := _find_upgrade(req)
		names.append(req_up.display_name if req_up != null else String(req))
	return "Needs %s" % ", ".join(names)

func _upgrade_tooltip(up: PermUpgradeData) -> String:
	var text := up.description
	if not up.requires_nodes.is_empty():
		text += "\nRequires: %s" % ", ".join(_required_upgrade_names(up))
	return text

func _upgrade_button_text(up: PermUpgradeData, level: int) -> String:
	var cost := Game.progression.upgrade_cost(up)
	if up.max_level == 1 and level == 0:
		return "Unlock (%d)" % cost
	return "Upgrade (%d)" % cost

func _required_upgrade_names(up: PermUpgradeData) -> Array[String]:
	var names: Array[String] = []
	for req in up.requires_nodes:
		var req_up := _find_upgrade(req)
		names.append(req_up.display_name if req_up != null else String(req))
	return names

func _find_upgrade(id: StringName) -> PermUpgradeData:
	for up in Catalog.perm_upgrades():
		if up.id == id:
			return up
	return null
