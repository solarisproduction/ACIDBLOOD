class_name TurretData
extends Resource
## One turret archetype. splash_radius > 0 makes hits splash; slow_factor < 1
## applies a slow status on hit. Stat paths: "turret.<id>.<stat>".

@export var id: StringName
@export var display_name: String = ""
@export var damage: float = 3.0
@export var attack_interval: float = 0.5
@export var attack_range: float = 6.5
@export var projectile_speed: float = 12.0
## 0 = single target.
@export var splash_radius: float = 0.0
## Speed multiplier applied as a status on hit; 1.0 = no slow.
@export var slow_factor: float = 1.0
@export var slow_duration: float = 0.0

@export_group("Presentation")
@export var color: Color = Color.WHITE
## Optional low-poly GLB wrapper scene (see docs/ASSET_CONTRACT.md).
@export var model_scene: PackedScene
