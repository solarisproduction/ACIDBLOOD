class_name WaveData
extends Resource

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

@export var groups: Array[SpawnGroup] = []
## Wave pacing role. Used for boss / elite warnings and campaign previews.
@export var intent: StringName = &""
## Human-readable wave label shown in the HUD.
@export var label: String = ""
## Delay before this wave starts after the previous one clears.
@export var pre_wave_delay: float = 2.0
## Pause before the next wave starts once this one is cleared.
@export var post_delay: float = 2.0

func intent_label() -> String:
	return String(INTENT_LABELS.get(intent, String(intent).capitalize()))

func display_label() -> String:
	if not label.is_empty():
		return label
	if intent == &"":
		return ""
	return intent_label()

func banner_text() -> String:
	if not label.is_empty():
		return label
	if intent == &"boss":
		return "Boss Wave"
	if intent == &"elite":
		return "Elite Wave"
	if intent == &"":
		return "Incoming Wave"
	return "%s Wave" % intent_label()
