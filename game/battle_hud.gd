class_name BattleHUD
extends Control
## Battle HUD + level-up draft overlay. The overlay's subtree has
## process_mode ALWAYS so card buttons work while the tree is paused.

const FAMILY_GUARDIAN := &"guardian"
const FAMILY_FORTRESS := &"fortress"
const FAMILY_BOLT := &"bolt"
const FAMILY_CANNON := &"cannon"
const FAMILY_FROST := &"frost"
const OVERLAY_DRAFT := &"draft"
const OVERLAY_PLACEMENT := &"placement"

const FAMILY_META := {
	FAMILY_GUARDIAN: {
		"label": "GUARDIAN",
		"accent": Color("a64b3c"),
		"surface": Color(0.18, 0.11, 0.10, 0.96),
	},
	FAMILY_FORTRESS: {
		"label": "BARRICADE",
		"accent": Color("b08a45"),
		"surface": Color(0.19, 0.15, 0.10, 0.96),
	},
	FAMILY_BOLT: {
		"label": "BOLT",
		"accent": Color("3d7fe3"),
		"surface": Color(0.09, 0.13, 0.21, 0.96),
	},
	FAMILY_CANNON: {
		"label": "CANNON",
		"accent": Color("c96a2b"),
		"surface": Color(0.20, 0.12, 0.08, 0.96),
	},
	FAMILY_FROST: {
		"label": "FROST",
		"accent": Color("56a7b8"),
		"surface": Color(0.08, 0.16, 0.18, 0.96),
	},
}

# Semantic category is the card's stable identity. Focus/selection is applied
# by DraftCard as an additional neutral treatment and never swaps this accent.
const SEMANTIC_META := {
	CardData.CATEGORY_NEW_TURRET: {
		"label": "NEW TURRET",
		"accent": Color("d6a84e"),
		"surface": Color(0.20, 0.16, 0.08, 0.96),
	},
	CardData.CATEGORY_NORMAL: {
		"label": "NORMAL",
		"accent": Color("82909a"),
		"surface": Color(0.13, 0.15, 0.16, 0.96),
	},
	CardData.CATEGORY_BREAKTHROUGH: {
		"label": "BREAKTHROUGH",
		"accent": Color("c65a43"),
		"surface": Color(0.20, 0.10, 0.08, 0.96),
	},
	CardData.CATEGORY_CHAIN: {
		"label": "CHAIN",
		"accent": Color("58a7a8"),
		"surface": Color(0.08, 0.16, 0.17, 0.96),
	},
	CardData.CATEGORY_COMBO: {
		"label": "COMBO",
		"accent": Color("9a69bd"),
		"surface": Color(0.15, 0.10, 0.19, 0.96),
	},
}

var battle: Battle

@onready var stage_label: Label = %StageLabel
@onready var wave_label: Label = %WaveLabel
@onready var fortress_label: Label = %FortressLabel
@onready var fortress_bar: ProgressBar = %FortressBar
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var ability_label: Label = %AbilityLabel
@onready var ability_bar: ProgressBar = %AbilityBar
@onready var ability_hint: Label = %AbilityHint
@onready var draft_title: Label = $DraftLayer/Center/Panel/Title
@onready var draft_subtitle: Label = $DraftLayer/Center/Panel/Subtitle
@onready var threat_layer: Control = %ThreatLayer
@onready var threat_label: Label = %ThreatLabel
@onready var placement_hint: Label = %PlacementHint
@onready var draft_layer: Control = %DraftLayer
@onready var draft_panel: VBoxContainer = %Panel
@onready var cards_box: GridContainer = %CardsBox

var _threat_hide_at := 0.0
var _overlay_mode: StringName = &""
var _overlay_buttons: Array[Button] = []
var _overlay_selected_index: int = -1
var _level_up_ready := false
var _pending_level_ups := 0

func setup(b: Battle) -> void:
	battle = b
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	_layout_draft_overlay()
	stage_label.text = "Act %d • %d. %s" % [b.stage.resolved_act_number(), b.stage.index, b.stage.display_name]
	wave_label.text = "Wave -/%d" % b.stage.waves.size()
	# Wave identity remains available to WaveDirector, telemetry and debug, but
	# is not part of the normal player-facing battle hierarchy.
	wave_label.visible = false
	draft_layer.visible = false
	placement_hint.visible = false
	update_fortress()
	update_xp()
	update_ability()
	threat_layer.visible = false

func show_stage_intro(stage: StageData) -> void:
	show_threat_banner(stage.banner_text(), 2.6)

func _process(_delta: float) -> void:
	update_ability()
	if threat_layer.visible and Time.get_ticks_msec() >= _threat_hide_at:
		threat_layer.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _overlay_mode == OVERLAY_PLACEMENT:
		var placement_handled := false
		if event.is_action_pressed("ui_accept"):
			battle.confirm_turret_placement()
			placement_handled = true
		elif event.is_action_pressed("ui_left"):
			battle.move_placement_selection(-1)
			placement_handled = true
		elif event.is_action_pressed("ui_right"):
			battle.move_placement_selection(1)
			placement_handled = true
		if placement_handled:
			get_viewport().set_input_as_handled()
		return
	if not draft_layer.visible:
		return
	var handled := false
	if event.is_action_pressed("ui_accept"):
		_activate_overlay_selection()
		handled = true
	elif event.is_action_pressed("ui_left"):
		_move_overlay_selection(-1)
		handled = true
	elif event.is_action_pressed("ui_right"):
		_move_overlay_selection(1)
		handled = true
	elif event.is_action_pressed("ui_up"):
		_move_overlay_selection(-1 if _overlay_mode == OVERLAY_DRAFT else -2)
		handled = true
	elif event.is_action_pressed("ui_down"):
		_move_overlay_selection(1 if _overlay_mode == OVERLAY_DRAFT else 2)
		handled = true
	if handled:
		get_viewport().set_input_as_handled()

func update_fortress() -> void:
	var rs := battle.run_state
	fortress_bar.max_value = rs.fortress_max_hp()
	fortress_bar.value = rs.fortress_hp
	fortress_bar.modulate = Color.WHITE
	fortress_label.modulate = Color.WHITE
	fortress_label.text = "Barricade %d/%d" % [ceili(rs.fortress_hp), ceili(rs.fortress_max_hp())]

func update_xp() -> void:
	var rs := battle.run_state
	level_label.text = "Lv %d" % rs.level
	if _level_up_ready:
		level_label.text += " • READY"
	xp_bar.max_value = Leveling.xp_required(rs.level)
	xp_bar.value = rs.xp
	xp_bar.modulate = Color.WHITE if not _level_up_ready else Color(0.98, 0.82, 0.36, 1.0)
	level_label.modulate = Color.WHITE if not _level_up_ready else Color(1.0, 0.90, 0.48, 1.0)

func update_wave(index: int, total: int, label: String = "") -> void:
	var suffix := label
	if suffix.is_empty():
		wave_label.text = "Wave %d/%d" % [index, total]
	else:
		wave_label.text = "Wave %d/%d • %s" % [index, total, suffix]

func update_ability() -> void:
	if battle == null or battle.guardian == null:
		return
	var remaining := battle.guardian.ability_cooldown_remaining()
	var total := battle.guardian.ability_cooldown_total()
	ability_label.text = "Pulse"
	ability_hint.text = "Space • Charging"
	ability_bar.max_value = total
	ability_bar.value = maxf(0.0, total - remaining)
	if remaining <= 0.0:
		ability_hint.text = "Space • Ready"

func set_level_up_ready(ready: bool, pending_count: int = 0) -> void:
	_level_up_ready = ready
	_pending_level_ups = pending_count
	update_xp()

func show_threat_banner(text: String, duration: float = 2.0) -> void:
	threat_label.text = text
	threat_layer.visible = true
	_threat_hide_at = Time.get_ticks_msec() + int(duration * 1000.0)

func flash_fortress_hit(amount: float, max_hp: float) -> void:
	if fortress_bar == null or fortress_label == null:
		return
	var ratio := clampf(amount / maxf(1.0, max_hp), 0.0, 0.35)
	var flash_color := Color(1.0, 0.88, 0.52, 1.0)
	if ratio >= 0.12:
		flash_color = Color(1.0, 0.58, 0.32, 1.0)
	if ratio >= 0.22:
		flash_color = Color(1.0, 0.35, 0.24, 1.0)
	var flash_scale := 1.0 + ratio * 0.18
	var tween := create_tween()
	fortress_label.modulate = flash_color
	fortress_bar.modulate = flash_color
	tween.tween_property(fortress_label, "scale", Vector2.ONE * flash_scale, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(fortress_bar, "scale", Vector2.ONE * flash_scale, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(fortress_label, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(fortress_bar, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(fortress_label, "modulate", Color.WHITE, 0.14)
	tween.parallel().tween_property(fortress_bar, "modulate", Color.WHITE, 0.14)

func show_draft(offer: Array[CardData]) -> void:
	_overlay_mode = OVERLAY_DRAFT
	placement_hint.visible = false
	var draft_index := battle.run_state.draft_count
	var draft_total := battle.run_state.max_draft_choices
	draft_title.text = "LEVEL UP %d/%d — CHOOSE ONE" % [draft_index, draft_total]
	var emergency_available := false
	for card in offer:
		for eff in card.effects:
			if eff.op == CardEffect.Op.HEAL_FORTRESS:
				emergency_available = true
				break
		if emergency_available:
			break
	draft_subtitle.text = "Emergency response available • Arrows move • Space confirms" if emergency_available else "Three choices • Arrows move • Space confirms"
	_overlay_buttons.clear()
	_overlay_selected_index = -1
	var sorted_offer := offer.duplicate()
	sorted_offer.sort_custom(_sort_offer_cards)
	for child in cards_box.get_children():
		child.queue_free()
	cards_box.columns = mini(3, maxi(1, sorted_offer.size()))
	var card_width := _draft_card_width(cards_box.columns)
	for card in sorted_offer:
		var semantic := Draft.semantic_category(card)
		var semantic_meta: Dictionary = SEMANTIC_META.get(semantic, SEMANTIC_META[CardData.CATEGORY_NORMAL])
		var family := Draft.weapon_family(card)
		var family_meta: Dictionary = FAMILY_META.get(family, FAMILY_META[FAMILY_GUARDIAN])
		var btn := DraftCard.new()
		var role_text := "%s • %s" % [str(family_meta["label"]), _card_role_label(card)]
		btn.setup(card, str(semantic_meta["label"]), role_text, semantic_meta["accent"], semantic_meta["surface"], card_width)
		btn.pressed.connect(_on_card_pressed.bind(card))
		cards_box.add_child(btn)
		_overlay_buttons.append(btn)
	draft_layer.visible = true
	update_xp()
	call_deferred("_focus_overlay_selection")
	if Game.autoplay:
		get_tree().create_timer(0.05).timeout.connect(func() -> void:
			if draft_layer.visible and not sorted_offer.is_empty():
				_on_card_pressed(sorted_offer[0]))

func show_placement(turret: TurretData, slot_index: int) -> void:
	_overlay_mode = OVERLAY_PLACEMENT
	draft_layer.visible = false
	placement_hint.text = "CHOOSE SLOT: %s\n← / → MOVE • SPACE CONFIRM" % ArenaLayout.slot_display_name(slot_index).to_upper()
	placement_hint.visible = true
	if Game.autoplay:
		get_tree().create_timer(0.05).timeout.connect(func() -> void:
			if _overlay_mode == OVERLAY_PLACEMENT:
				battle.confirm_turret_placement())

func update_placement(slot_index: int) -> void:
	if _overlay_mode != OVERLAY_PLACEMENT:
		return
	placement_hint.text = "CHOOSE SLOT: %s\n← / → MOVE • SPACE CONFIRM" % ArenaLayout.slot_display_name(slot_index).to_upper()

func hide_draft() -> void:
	draft_layer.visible = false
	_overlay_mode = &""
	_overlay_buttons.clear()
	_overlay_selected_index = -1
	for child in cards_box.get_children():
		child.queue_free()

func hide_overlay() -> void:
	hide_draft()
	hide_placement()

func hide_placement() -> void:
	if _overlay_mode == OVERLAY_PLACEMENT:
		_overlay_mode = &""
	placement_hint.visible = false

func _on_card_pressed(card: CardData) -> void:
	if not draft_layer.visible:
		return
	draft_layer.visible = false
	battle.on_card_chosen(card)

func _draft_card_width(columns: int) -> float:
	var viewport_width := get_viewport_rect().size.x
	var panel_width := clampf(viewport_width - 40.0, 480.0, 680.0)
	var gaps := float(maxi(0, columns - 1) * 18)
	return maxf(150.0, floor((panel_width - gaps) / float(maxi(1, columns))))

func _layout_draft_overlay() -> void:
	var viewport_width := get_viewport_rect().size.x
	var panel_width := clampf(viewport_width - 40.0, 480.0, 680.0)
	draft_panel.custom_minimum_size = Vector2(panel_width, 0)

func _card_role_label(card: CardData) -> String:
	match Draft.card_role(card):
		&"build":
			return "BUILD"
		&"emergency":
			return "EMERGENCY"
		&"choice":
			return "CHOICE"
		&"upgrade":
			return "UPGRADE"
		_:
			return "PASSIVE"

func _sort_offer_cards(a: CardData, b: CardData) -> bool:
	var a_role := _role_priority(a)
	var b_role := _role_priority(b)
	if a_role != b_role:
		return a_role < b_role
	var a_cat := _category_priority(Draft.semantic_category(a))
	var b_cat := _category_priority(Draft.semantic_category(b))
	if a_cat != b_cat:
		return a_cat < b_cat
	return a.title.naturalnocasecmp_to(b.title) < 0

func _role_priority(card: CardData) -> int:
	match _card_role_label(card):
		"EMERGENCY":
			return 0
		"BUILD":
			return 1
		"UPGRADE":
			return 2
		"CHOICE":
			return 3
		_:
			return 4

func _category_priority(category: StringName) -> int:
	match category:
		CardData.CATEGORY_NEW_TURRET:
			return 0
		CardData.CATEGORY_BREAKTHROUGH:
			return 1
		CardData.CATEGORY_CHAIN:
			return 2
		CardData.CATEGORY_COMBO:
			return 3
		CardData.CATEGORY_NORMAL:
			return 4
		_:
			return 5

func _focus_overlay_selection() -> void:
	if _overlay_buttons.is_empty():
		return
	if _overlay_selected_index < 0 or _overlay_selected_index >= _overlay_buttons.size():
		_overlay_selected_index = _first_enabled_overlay_index()
	_sync_overlay_focus()

func _first_enabled_overlay_index() -> int:
	for i in range(_overlay_buttons.size()):
		var button := _overlay_buttons[i]
		if is_instance_valid(button) and not button.disabled:
			return i
	return -1

func _sync_overlay_focus() -> void:
	if _overlay_selected_index < 0 or _overlay_selected_index >= _overlay_buttons.size():
		return
	var button := _overlay_buttons[_overlay_selected_index]
	if is_instance_valid(button) and not button.disabled:
		button.grab_focus()

func _move_overlay_selection(step: int) -> void:
	if _overlay_buttons.is_empty() or step == 0:
		return
	if _overlay_selected_index < 0 or _overlay_selected_index >= _overlay_buttons.size():
		_overlay_selected_index = _first_enabled_overlay_index()
		if _overlay_selected_index < 0:
			return
	var next := _overlay_selected_index
	next = (_overlay_selected_index + step + _overlay_buttons.size()) % _overlay_buttons.size()
	if next < 0 or next >= _overlay_buttons.size():
		return
	if _overlay_buttons[next].disabled:
		var search := next
		var attempts := 0
		while attempts < _overlay_buttons.size():
			search = (search + (1 if step >= 0 else -1) + _overlay_buttons.size()) % _overlay_buttons.size()
			if not _overlay_buttons[search].disabled:
				next = search
				break
			attempts += 1
		if attempts >= _overlay_buttons.size():
			return
	_overlay_selected_index = next
	_sync_overlay_focus()

func _activate_overlay_selection() -> void:
	if _overlay_selected_index < 0 or _overlay_selected_index >= _overlay_buttons.size():
		return
	var button := _overlay_buttons[_overlay_selected_index]
	if not is_instance_valid(button) or button.disabled:
		return
	button.emit_signal("pressed")
