class_name StageData
extends Resource
## One campaign stage, fully data-driven: the generic Battle scene consumes
## any StageData. Difficulty scaling multiplies enemy bases at spawn time.

const INTENT_LABELS := {
	&"": "Standard",
	&"introduce": "Introduce",
	&"reinforce": "Reinforce",
	&"pressure": "Pressure",
	&"test": "Test",
	&"recover": "Recover",
	&"elite": "Elite",
	&"preboss": "Preboss",
	&"boss": "Boss",
}

@export var id: StringName
@export var display_name: String = ""
## 1-based campaign order.
@export var index: int = 1
## Campaign act. 0 = derive from stage index, otherwise author explicitly.
@export var act_number: int = 0
## Stage pacing role used by the campaign shell and battle intro banner.
@export var intent: StringName = &""
@export_multiline var briefing: String = ""
@export var reward_cores: int = 5
## Base fortress HP for this stage. Only permanent upgrades/cards may raise
## it during a run; stage scaling does not modify fortress HP automatically.
@export var fortress_hp: float = 100.0
@export var hp_scale: float = 1.0
@export var speed_scale: float = 1.0
@export var waves: Array[WaveData] = []

func resolved_act_number() -> int:
	if act_number > 0:
		return act_number
	return clampi(int(ceil(float(index) / 10.0)), 1, 3)

func intent_label() -> String:
	return String(INTENT_LABELS.get(intent, String(intent).capitalize()))

func banner_text() -> String:
	var head := "Act %d • %d. %s" % [resolved_act_number(), index, display_name]
	if briefing.is_empty():
		return head
	return "%s\n%s" % [head, briefing]
