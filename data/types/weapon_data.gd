class_name WeaponData
extends Resource
## Guardian weapon configuration. All values are bases; run modifiers apply
## on top via stat paths ("guardian.damage", "guardian.attack_interval", ...).

@export var id: StringName
@export var damage: float = 4.0
@export var attack_interval: float = 0.5
@export var attack_range: float = 7.0
@export var projectile_speed: float = 14.0
@export var projectile_count: int = 1
@export var pierce: int = 0
## Degrees between projectiles when projectile_count > 1.
@export var spread_degrees: float = 8.0
@export var projectile_color: Color = Color(0.4, 0.9, 1.0)
