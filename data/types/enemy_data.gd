class_name EnemyData
extends Resource
## One enemy archetype. Tactical identity and behavior differences are data
## (role, affinity, movement, speed, armor, stop_range, attack_interval), not
## per-archetype scripts.

const ROLE_FRONTLINE := &"FRONTLINE"
const ROLE_IMPACT := &"IMPACT"
const ROLE_SIEGE := &"SIEGE"
const ROLE_RANGED := &"RANGED"
const ROLE_SUPPORT := &"SUPPORT"
const ROLE_PROTECTOR := &"PROTECTOR"
const ROLE_SPAWNER := &"SPAWNER"
const ROLE_ELITE := &"ELITE"
const ROLE_BOSS := &"BOSS"
const VALID_ROLES := [
	ROLE_FRONTLINE,
	ROLE_IMPACT,
	ROLE_SIEGE,
	ROLE_RANGED,
	ROLE_SUPPORT,
	ROLE_PROTECTOR,
	ROLE_SPAWNER,
	ROLE_ELITE,
	ROLE_BOSS,
]

const MOVEMENT_DIRECT := &"DIRECT"
const MOVEMENT_WEAVE := &"WEAVE"
const VALID_MOVEMENT_PATTERNS := [MOVEMENT_DIRECT, MOVEMENT_WEAVE]

const MODIFIER_ARMORED := &"ARMORED"
const VALID_MODIFIERS := [MODIFIER_ARMORED]

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

@export_group("Tactical")
## Explicit tactical purpose. Runtime behavior remains driven by the data
## fields below; it is never inferred from the resource filename or id.
@export var role: StringName = ROLE_FRONTLINE
## Damage-family multipliers. Missing families are neutral (1.0).
@export var damage_affinity: Dictionary = {}
## Explicit modifiers whose numeric behavior remains owned by the base fields.
@export var modifiers: Array[StringName] = []
## Controlled lateral movement while an enemy advances toward its stop line.
@export var movement_pattern: StringName = MOVEMENT_DIRECT
@export var movement_amplitude: float = 0.0
@export var movement_frequency: float = 0.0

@export_group("Threat")
@export_enum("Basic", "Ranged", "Elite", "Boss") var threat_profile: int = 0

@export_group("Presentation")
@export_enum("Box", "Capsule", "Cylinder", "Sphere") var shape: int = 0
@export var color: Color = Color.WHITE
@export var body_scale: Vector3 = Vector3.ONE
## Optional low-poly GLB wrapper scene; when null the runtime builds a
## primitive placeholder from shape/color/body_scale. See docs/ASSET_CONTRACT.md.
@export var model_scene: PackedScene


func role_valid() -> bool:
	return role in VALID_ROLES


func modifiers_valid() -> bool:
	for modifier in modifiers:
		if modifier not in VALID_MODIFIERS:
			return false
	return true


func affinity_valid() -> bool:
	for family in damage_affinity:
		var multiplier: Variant = damage_affinity[family]
		if not (multiplier is float or multiplier is int) or float(multiplier) <= 0.0:
			return false
	return true


func movement_contract_valid() -> bool:
	if movement_pattern not in VALID_MOVEMENT_PATTERNS:
		return false
	if movement_pattern == MOVEMENT_WEAVE:
		return movement_amplitude > 0.0 and movement_frequency > 0.0
	return movement_amplitude >= 0.0 and movement_frequency >= 0.0


func contract_valid() -> bool:
	return role_valid() and modifiers_valid() and affinity_valid() and movement_contract_valid()


func affinity_multiplier(damage_family: StringName) -> float:
	var multiplier: Variant = damage_affinity.get(damage_family, 1.0)
	if multiplier is float or multiplier is int:
		return maxf(0.01, float(multiplier))
	return 1.0
