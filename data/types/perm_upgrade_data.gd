class_name PermUpgradeData
extends Resource
## One permanent (meta-progression) upgrade node bought with cores.

const TRACK_GENERAL := &"general"
const TRACK_FORTRESS := &"fortress"
const TRACK_COMMAND := &"command"
const TRACK_ENGINEERING := &"engineering"

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
## High-level tree track used by the shell UI.
@export var track: StringName = TRACK_GENERAL
@export var max_level: int = 5
@export var base_cost: int = 4
## Cost increase per level already owned.
@export var cost_step: int = 2
## Upgrade ids that must already be owned before this node can be bought.
@export var requires_nodes: Array[StringName] = []
## Stat path receiving a flat bonus per level (empty for pure unlocks).
@export var stat: StringName
@export var value_per_level: float = 0.0
## Permanent unlock flag this upgrade grants at level >= 1 (e.g. gates a card).
@export var unlock_flag: StringName
