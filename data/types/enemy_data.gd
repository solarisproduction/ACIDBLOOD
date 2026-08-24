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
## Damage dealt to the barricade per attack tick once the enemy is in attack
## state.
@export var fortress_damage: float = 5.0
## > 0 = stop at stop_range from the barricade line and attack repeatedly
## from range. 0 = contact attacker: reach the barricade line, stay there, and
## attack it at the runtime default contact cadence.
@export var attack_interval: float = 0.0
@export var stop_range: float = 0.0
@export var fortress_projectile_radius: float = 0.16
@export var is_boss: bool = false

@export_group("Threat")
@export_enum("Basic", "Ranged", "Elite", "Boss") var threat_profile: int = 0

@export_group("Presentation")
@export_enum("Box", "Capsule", "Cylinder", "Sphere") var shape: int = 0
@export var color: Color = Color.WHITE
@export var body_scale: Vector3 = Vector3.ONE
## Optional low-poly GLB wrapper scene; when null the runtime builds a
## primitive placeholder from shape/color/body_scale. See docs/ASSET_CONTRACT.md.
@export var model_scene: PackedScene
