class_name CardData
extends Resource
## One upgrade card. Eligibility is evaluated by core/draft.gd.

@export var id: StringName
@export var title: String = ""
@export_multiline var description: String = ""
@export var weight: float = 10.0
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
