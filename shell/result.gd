extends Control
## Post-battle result + reward step. Reads Game.last_result.

@onready var title_label: Label = %TitleLabel
@onready var detail_label: Label = %DetailLabel
@onready var reward_label: Label = %RewardLabel
@onready var continue_button: Button = %ContinueButton
@onready var retry_button: Button = %RetryButton

func _ready() -> void:
	var r := Game.last_result
	var victory: bool = r.get("victory", false)
	title_label.text = "VICTORY" if victory else "DEFEAT"
	var stats: Dictionary = r.get("stats", {})
	detail_label.text = "%s\nKills: %d   Wave: %d   Level: %d" % [
		r.get("stage_name", "?"), stats.get("kills", 0),
		stats.get("wave", 0), stats.get("level", 0)]
	if victory:
		reward_label.text = "+%d cores (total %d)" % [r.get("awarded_cores", 0), Game.progression.cores]
	else:
		reward_label.text = "No reward"
	continue_button.pressed.connect(func() -> void: Game.change_scene(Game.CAMPAIGN_SCENE))
	retry_button.pressed.connect(func() -> void:
		var stage := Catalog.stage_by_index(int(r.get("stage_index", 1)))
		if stage != null:
			Game.start_stage(stage))
