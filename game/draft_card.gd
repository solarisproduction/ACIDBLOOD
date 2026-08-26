class_name DraftCard
extends Button
## Reusable current-card presentation. It renders CardData but never owns
## eligibility, draft state, or card effects; BattleHUD remains the owner of
## selection and paused input.

func setup(card: CardData, category_label: String, role_label: String, accent: Color, surface: Color, width: float) -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	text = ""
	clip_contents = true
	custom_minimum_size = Vector2(width, 500.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_theme_stylebox_override("normal", _card_style(surface, accent, 1.0, 2))
	add_theme_stylebox_override("hover", _card_style(surface.lightened(0.08), accent.lightened(0.12), 1.0, 3))
	add_theme_stylebox_override("pressed", _card_style(surface.darkened(0.08), accent, 1.0, 3))
	add_theme_stylebox_override("focus", _card_style(surface.lightened(0.05), accent.lightened(0.18), 1.0, 4))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var root := VBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 9)
	margin.add_child(root)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 5)
	root.add_child(top_row)
	top_row.add_child(_make_badge(category_label, accent, Color(1, 1, 1, 0.95)))
	top_row.add_child(_make_badge(role_label, Color(1, 1, 1, 0.08), Color(0.94, 0.92, 0.88, 1.0)))
	if not card.excludes.is_empty():
		top_row.add_child(_make_badge("CHOOSE 1", Color(0.84, 0.82, 0.77, 0.16), Color(0.95, 0.92, 0.86, 1.0), true))

	var title := Label.new()
	title.text = card.title
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.97, 0.97, 0.95, 1))
	root.add_child(title)

	var body := Label.new()
	body.text = card.description
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.88, 0.86, 0.82, 1))
	root.add_child(body)

	var footer := FlowContainer.new()
	footer.alignment = FlowContainer.ALIGNMENT_BEGIN
	footer.add_theme_constant_override("h_separation", 5)
	footer.add_theme_constant_override("v_separation", 5)
	root.add_child(footer)
	for hint in _card_hints(card):
		footer.add_child(_make_hint_row(hint, accent))

func _card_style(bg: Color, border: Color, shadow_alpha: float, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(16)
	style.shadow_color = Color(0, 0, 0, 0.24 * shadow_alpha)
	style.shadow_size = 10
	return style

func _make_badge(text_value: String, bg: Color, fg: Color, outlined: bool = false) -> Control:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", fg)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = bg
	badge_style.set_corner_radius_all(999)
	badge_style.content_margin_left = 7
	badge_style.content_margin_top = 3
	badge_style.content_margin_right = 7
	badge_style.content_margin_bottom = 3
	if outlined:
		badge_style.border_color = Color(0.95, 0.92, 0.86, 0.75)
		badge_style.set_border_width_all(1)
	var container := PanelContainer.new()
	container.add_theme_stylebox_override("panel", badge_style)
	container.add_child(label)
	return container

func _make_hint_row(text_value: String, accent: Color) -> Control:
	var container := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, 0.14)
	style.border_color = Color(accent.r, accent.g, accent.b, 0.45)
	style.set_border_width_all(1)
	style.set_corner_radius_all(999)
	style.content_margin_left = 7
	style.content_margin_top = 3
	style.content_margin_right = 7
	style.content_margin_bottom = 3
	container.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.90, 0.89, 0.86, 1))
	container.add_child(label)
	return container

func _card_hints(card: CardData) -> Array[String]:
	var hints: Array[String] = []
	if not card.prerequisites.is_empty():
		hints.append("Needs base card")
	if not card.excludes.is_empty():
		hints.append("Exclusive")
	if card.requires_unlock != &"":
		hints.append("Permanent unlock")
	if card.max_stacks > 1:
		hints.append("%dx max" % card.max_stacks)
	return hints
