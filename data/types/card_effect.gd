class_name CardEffect
extends Resource
## One atomic card operation. Cards compose a small vocabulary of these
## instead of having per-card scripts.
##
## ADD_STAT / MULTIPLY_STAT: stat path + value. Projectile count, pierce and
## attack behavior changes are stats too ("guardian.projectiles",
## "guardian.pierce"), which keeps the vocabulary small.
## UNLOCK_TURRET: target = turret id; builds it in the next free slot.
## APPLY_BRANCH: target = turret branch id; the branch resource contributes
## its own stat effects and is recorded in the run state.
## HEAL_FORTRESS: value = flat HP restored (clamped to max).

enum Op { ADD_STAT, MULTIPLY_STAT, UNLOCK_TURRET, HEAL_FORTRESS, APPLY_BRANCH }

@export var op: Op = Op.ADD_STAT
@export var stat: StringName
@export var value: float = 0.0
@export var target: StringName
