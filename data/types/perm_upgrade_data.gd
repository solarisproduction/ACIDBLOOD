class_name PermUpgradeData
extends Resource
## One permanent (meta-progression) upgrade node bought with cores.

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var max_level: int = 5
@export var base_cost: int = 4
## Cost increase per level already owned.
@export var cost_step: int = 2
## Stat path receiving a flat bonus per level (empty for pure unlocks).
@export var stat: StringName
@export var value_per_level: float = 0.0
## Permanent unlock flag this upgrade grants at level >= 1 (e.g. gates a card).
@export var unlock_flag: StringName
