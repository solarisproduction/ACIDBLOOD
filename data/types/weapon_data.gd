class_name WeaponDefinition
extends Resource
## Shared weapon contract for every current attack source.
##
## The semantic axes are deliberately small: current gameplay only needs the
## damage family, engagement profile, attack topology and targeting policy.
## Numeric bases remain here as well so Guardian and turrets share one combat
## boundary; run modifiers still apply through their existing stat paths.

const DAMAGE_PHYSICAL := &"Physical"
const PROFILE_ROAMING := &"ROAMING"
const PROFILE_FORTRESS := &"FORTRESS"
const TOPOLOGY_DIRECT := &"Direct"
const TOPOLOGY_SPLASH := &"Splash"
const TARGET_MOST_ADVANCED := &"most_advanced"

@export var id: StringName
@export var display_name: String = ""
@export var damage_family: StringName = DAMAGE_PHYSICAL
@export var engagement_profile: StringName = PROFILE_ROAMING
@export var attack_topology: StringName = TOPOLOGY_DIRECT
@export var targeting_policy: StringName = TARGET_MOST_ADVANCED
@export var damage: float = 4.0
@export var attack_interval: float = 0.5
@export var attack_range: float = 7.0
@export var projectile_speed: float = 14.0
@export var projectile_radius: float = 0.12
@export var projectile_count: int = 1
@export var pierce: int = 0
@export var splash_radius: float = 0.0
@export var slow_factor: float = 1.0
@export var slow_duration: float = 0.0
## Current Bolt data uses lightning; future topologies must earn their own
## implementation instead of being represented as unused metadata.
@export var attack_mode: StringName = &"projectile"
## Visual-only tracers spawned across one real damage cycle.
@export var visual_tracers_per_shot: int = 1
## Degrees between projectiles when projectile_count > 1.
@export var spread_degrees: float = 8.0
@export var projectile_color: Color = Color(0.4, 0.9, 1.0)
@export var projectile_visual: StringName = &"orb"
@export var impact_visual: StringName = &"none"


func contract_valid() -> bool:
	return (
		not id.is_empty()
		and not damage_family.is_empty()
		and not engagement_profile.is_empty()
		and not attack_topology.is_empty()
		and not targeting_policy.is_empty()
	)
