class_name TurretData
extends Resource
## One turret archetype. Combat ownership lives in its WeaponDefinition;
## presentation and optional model identity stay on the turret resource.

@export var id: StringName
@export var display_name: String = ""
@export var weapon: WeaponDefinition

@export_group("Presentation")
@export var color: Color = Color.WHITE
@export var presentation_scale: float = 1.0
## Optional low-poly GLB wrapper scene (see docs/ASSET_CONTRACT.md).
@export var model_scene: PackedScene
