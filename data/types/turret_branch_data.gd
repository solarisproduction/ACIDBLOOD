class_name TurretBranchData
extends Resource
## One specialization branch for a turret family. The branch applies a bundle
## of normal CardEffects so the runtime keeps using the same modifier system.

@export var id: StringName
@export var turret_id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var excludes_branches: Array[StringName] = []
@export var effects: Array[CardEffect] = []
