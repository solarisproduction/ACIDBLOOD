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
## Optional behavior override. Empty inherits the turret's base attack mode.
@export var attack_mode: StringName = &""
## Used by lightning-style branches; zero keeps a direct attack.
@export var chain_count: int = 0
@export var chain_range: float = 1.8
@export var chain_damage_factor: float = 0.55
## Used by persistent lightning-zone branches; zero duration disables the field.
@export var field_radius: float = 0.0
@export var field_duration: float = 0.0
@export var field_tick_interval: float = 0.0
@export var field_damage_factor: float = 0.0
## Used by impact branches; applied to the direct target only.
@export var force_heavy_impact: bool = false
@export var impact_stun_duration: float = 0.0
@export var impact_armor_break: float = 0.0
@export var impact_armor_break_duration: float = 0.0
@export var impact_knockback: float = 0.0
## Used by expose-style branches; multiplier 1.0 disables the debuff.
@export var expose_damage_multiplier: float = 1.0
@export var expose_duration: float = 0.0
## Optional projectile visual override for branch readability.
@export var projectile_visual: StringName = &""
