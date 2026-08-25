class_name SpawnGroup
extends Resource
## `count` enemies of one archetype, spawned `interval` seconds apart,
## starting `start_delay` seconds after the wave begins.

@export var enemy_id: StringName
@export var count: int = 1
@export var interval: float = 1.0
@export var start_delay: float = 0.0
## Optional authored lateral pressure. Random keeps the original distribution.
@export_enum("Random", "Left", "Center", "Right") var lane: String = "random"
