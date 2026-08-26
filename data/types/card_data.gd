class_name CardData
extends Resource
## One upgrade card. Eligibility is evaluated by core/draft.gd.

const CATEGORY_NEW_TURRET := &"NEW_TURRET"
const CATEGORY_NORMAL := &"NORMAL"
const CATEGORY_BREAKTHROUGH := &"BREAKTHROUGH"
const CATEGORY_CHAIN := &"CHAIN"
const CATEGORY_COMBO := &"COMBO"
const VALID_CATEGORIES := [
	CATEGORY_NEW_TURRET,
	CATEGORY_NORMAL,
	CATEGORY_BREAKTHROUGH,
	CATEGORY_CHAIN,
	CATEGORY_COMBO,
]

@export var id: StringName
@export var title: String = ""
@export_multiline var description: String = ""
@export var weight: float = 10.0
@export var category: StringName = &"NORMAL"
## Build tags used for draft weighting and future synergy checks.
@export var tags: Array[StringName] = []
## Maximum times this card can be acquired in one run.
@export var max_stacks: int = 1
## Card ids that must be acquired before this card can appear.
@export var prerequisites: Array[StringName] = []
## Card ids that make this card ineligible once acquired (branching choices).
@export var excludes: Array[StringName] = []
## Permanent unlock flag required for this card to enter the run pool
## (empty = always available).
@export var requires_unlock: StringName
@export var effects: Array[CardEffect] = []

func category_valid() -> bool:
	return category in VALID_CATEGORIES

func category_contract_valid() -> bool:
	if not category_valid():
		return false
	match category:
		CATEGORY_NEW_TURRET:
			return _has_operation(CardEffect.Op.UNLOCK_TURRET)
		CATEGORY_BREAKTHROUGH:
			return _has_operation(CardEffect.Op.APPLY_BRANCH)
		CATEGORY_CHAIN:
			return not prerequisites.is_empty()
		CATEGORY_COMBO:
			return prerequisites.size() >= 2
		_:
			return true

func _has_operation(operation: CardEffect.Op) -> bool:
	for effect in effects:
		if effect.op == operation:
			return true
	return false
