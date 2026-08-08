class_name BattleHUD
extends Control
## Battle HUD + level-up draft overlay. The overlay's subtree has
## process_mode ALWAYS so card buttons work while the tree is paused.

var battle: Battle

@onready var stage_label: Label = %StageLabel
@onready var wave_label: Label = %WaveLabel
@onready var fortress_label: Label = %FortressLabel
@onready var fortress_bar: ProgressBar = %FortressBar
@onready var level_label: Label = %LevelLabel
@onready var xp_bar: ProgressBar = %XPBar
@onready var draft_layer: Control = %DraftLayer
@onready var cards_box: VBoxContainer = %CardsBox

func setup(b: Battle) -> void:
	battle = b
	stage_label.text = "%d. %s" % [b.stage.index, b.stage.display_name]
	wave_label.text = "Wave -/%d" % b.stage.waves.size()
	draft_layer.visible = false
	update_fortress()
	update_xp()

func update_fortress() -> void:
	var rs := battle.run_state
	fortress_bar.max_value = rs.fortress_max_hp()
	fortress_bar.value = rs.fortress_hp
	fortress_label.text = "Fortress %d/%d" % [ceili(rs.fortress_hp), ceili(rs.fortress_max_hp())]

func update_xp() -> void:
	var rs := battle.run_state
	level_label.text = "Lv %d" % rs.level
	xp_bar.max_value = Leveling.xp_required(rs.level)
	xp_bar.value = rs.xp

func update_wave(index: int, total: int) -> void:
	wave_label.text = "Wave %d/%d" % [index, total]

func show_draft(offer: Array[CardData]) -> void:
	for child in cards_box.get_children():
		child.queue_free()
	for card in offer:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(480, 110)
		btn.text = "%s\n%s" % [card.title, card.description]
		btn.add_theme_font_size_override("font_size", 26)
		btn.pressed.connect(_on_card_pressed.bind(card))
		cards_box.add_child(btn)
	draft_layer.visible = true
	update_xp()
	if Game.autoplay:
		get_tree().create_timer(0.05).timeout.connect(func() -> void:
			if draft_layer.visible and not offer.is_empty():
				_on_card_pressed(offer[0]))

func hide_draft() -> void:
	draft_layer.visible = false

func _on_card_pressed(card: CardData) -> void:
	if not draft_layer.visible:
		return
	draft_layer.visible = false
	battle.on_card_chosen(card)
