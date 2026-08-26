class_name GuardianData
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var move_speed: float = 6.0
@export var weapon: WeaponDefinition

@export_group("Presentation")
@export var color: Color = Color(0.3, 0.85, 1.0)
@export var presentation_scale: float = 1.0

@export_group("Active Ability")
@export var ability_cooldown: float = 24.0
@export var ability_lane_width: float = 1.6
@export var ability_lane_length: float = 4.2
@export var ability_stun_duration: float = 1.5
@export var ability_knockback: float = 1.2

## Optional low-poly GLB wrapper scene (see docs/ASSET_CONTRACT.md).
@export var model_scene: PackedScene
