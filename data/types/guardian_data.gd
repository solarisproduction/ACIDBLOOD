class_name GuardianData
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var move_speed: float = 6.0
@export var weapon: WeaponData

@export_group("Presentation")
@export var color: Color = Color(0.3, 0.85, 1.0)
## Optional low-poly GLB wrapper scene (see docs/ASSET_CONTRACT.md).
@export var model_scene: PackedScene
