class_name StageData
extends Resource
## One campaign stage, fully data-driven: the generic Battle scene consumes
## any StageData. Difficulty scaling multiplies enemy bases at spawn time.

@export var id: StringName
@export var display_name: String = ""
## 1-based campaign order.
@export var index: int = 1
@export var reward_cores: int = 5
@export var hp_scale: float = 1.0
@export var speed_scale: float = 1.0
@export var waves: Array[WaveData] = []
