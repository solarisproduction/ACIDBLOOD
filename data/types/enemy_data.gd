class_name EnemyData
extends Resource
## One enemy archetype. Behavior differences are data (speed, armor,
## stop_range, attack_interval), not per-archetype scripts.

@export var id: StringName
@export var display_name: String = ""
@export var max_hp: float = 10.0
@export var speed: float = 1.5
@export var armor: float = 0.0
@export var xp: int = 2
## Damage dealt to the fortress: per contact (kamikaze) or per attack tick.
@export var fortress_damage: float = 5.0
## 0 = kamikaze: deal fortress_damage once on contact and die.
## > 0 = stop at stop_range from the fortress line and attack repeatedly.
@export var attack_interval: float = 0.0
@export var stop_range: float = 0.0
@export var is_boss: bool = false

@export_group("Presentation")
@export_enum("Box", "Capsule", "Cylinder", "Sphere") var shape: int = 0
@export var color: Color = Color.WHITE
@export var body_scale: Vector3 = Vector3.ONE
## Optional low-poly GLB wrapper scene; when null the runtime builds a
## primitive placeholder from shape/color/body_scale. See docs/ASSET_CONTRACT.md.
@export var model_scene: PackedScene
