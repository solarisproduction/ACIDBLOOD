class_name Draft
extends RefCounted
## Deterministic card draft generation.
## Same catalog + same context + same RNG seed => same offer.

## Returns true if the card may appear in a draft for this context.
## ctx keys:
##   acquired: Dictionary card id -> count (run acquisitions)
##   unlocks: Dictionary flag StringName -> bool (permanent unlocks)
##   blocked: Array[StringName] card ids the runtime forbids right now
##            (e.g. build cards when all tower slots are full)
##   fortress_hp / fortress_max_hp: optional runtime health context used to
##            suppress pure-heal cards when they have no value
##   draft_index: optional 1-based draft number in this run, used for light
##            early-run guardrails
static func is_eligible(card: CardData, ctx: Dictionary) -> bool:
	var acquired: Dictionary = ctx.get("acquired", {})
	var unlocks: Dictionary = ctx.get("unlocks", {})
	var blocked: Array = ctx.get("blocked", [])
	if card.id in blocked:
		return false
	if int(acquired.get(card.id, 0)) >= card.max_stacks:
		return false
	if card.requires_unlock != &"" and not bool(unlocks.get(card.requires_unlock, false)):
		return false
	if _is_pure_fortress_heal(card):
		var fortress_hp := float(ctx.get("fortress_hp", -1.0))
		var fortress_max_hp := float(ctx.get("fortress_max_hp", -1.0))
		if fortress_hp >= 0.0 and fortress_max_hp >= 0.0 and fortress_hp >= fortress_max_hp:
			return false
	for pre in card.prerequisites:
		if int(acquired.get(pre, 0)) <= 0:
			return false
	for ex in card.excludes:
		if int(acquired.get(ex, 0)) > 0:
			return false
	return true

static func _is_pure_fortress_heal(card: CardData) -> bool:
	if card.effects.is_empty():
		return false
	for eff in card.effects:
		if eff.op != CardEffect.Op.HEAL_FORTRESS:
			return false
	return true

## Weighted sample without replacement; never returns duplicate ids.
## Returns up to `count` cards (fewer if the eligible pool is smaller).
static func generate_offer(catalog: Array[CardData], ctx: Dictionary, rng: DetRNG, count: int = 3) -> Array[CardData]:
	var pool: Array[CardData] = []
	for card in catalog:
		if is_eligible(card, ctx):
			pool.append(card)
	var offer: Array[CardData] = []
	var draft_index := int(ctx.get("draft_index", 0))
	if draft_index > 0 and draft_index <= 2 and count > 0:
		var build_pool := _cards_with_role(pool, &"build")
		var guaranteed_build := _draw_weighted(build_pool, rng)
		if guaranteed_build != null:
			offer.append(guaranteed_build)
			pool.erase(guaranteed_build)
	while offer.size() < count and not pool.is_empty():
		var candidate_pool := _pool_with_category_guard(pool, offer)
		var picked := _draw_weighted(candidate_pool, rng)
		if picked == null:
			break
		offer.append(picked)
		pool.erase(picked)
	return offer

## Runtime-only blocking rules that depend on battle state rather than card
## ownership or permanent progression. Keep these here so offer-quality rules
## stay centralized in the draft system instead of leaking into Battle.
static func runtime_blocked_cards(catalog: Array[CardData], slots_available: int) -> Array[StringName]:
	var blocked: Array[StringName] = []
	if slots_available > 0:
		return blocked
	for card in catalog:
		if card_role(card) == &"build":
			blocked.append(card.id)
	return blocked

static func card_role(card: CardData) -> StringName:
	for eff in card.effects:
		if eff.op == CardEffect.Op.UNLOCK_TURRET:
			return &"build"
		if eff.op == CardEffect.Op.APPLY_BRANCH:
			return &"choice"
	if not card.prerequisites.is_empty():
		return &"upgrade"
	if _is_pure_fortress_heal(card):
		return &"recovery"
	return &"passive"

static func card_category(card: CardData) -> StringName:
	if _has_card_marker(card, &"bolt"):
		return &"bolt"
	if _has_card_marker(card, &"cannon"):
		return &"cannon"
	if _has_card_marker(card, &"frost"):
		return &"frost"
	for eff in card.effects:
		if eff.stat == &"fortress.max_hp" or eff.op == CardEffect.Op.HEAL_FORTRESS:
			return &"fortress"
	return &"guardian"

static func _cards_with_role(cards: Array[CardData], role: StringName) -> Array[CardData]:
	var out: Array[CardData] = []
	for card in cards:
		if card_role(card) == role:
			out.append(card)
	return out

static func _draw_weighted(cards: Array[CardData], rng: DetRNG) -> CardData:
	if cards.is_empty():
		return null
	var weights: Array[float] = []
	for card in cards:
		weights.append(card.weight)
	var idx := rng.weighted_index(weights)
	if idx < 0:
		return null
	return cards[idx]

static func _pool_with_category_guard(pool: Array[CardData], offer: Array[CardData]) -> Array[CardData]:
	if offer.size() < 2:
		return pool
	var category_counts := {}
	for card in offer:
		var category := card_category(card)
		category_counts[category] = int(category_counts.get(category, 0)) + 1
	var restricted: Array[CardData] = []
	for card in pool:
		if int(category_counts.get(card_category(card), 0)) >= 2:
			continue
		restricted.append(card)
	return restricted if not restricted.is_empty() else pool

static func _has_card_marker(card: CardData, marker: StringName) -> bool:
	if marker in card.tags:
		return true
	if String(card.id).contains(String(marker)):
		return true
	if String(card.requires_unlock).contains(String(marker)):
		return true
	for pre in card.prerequisites:
		if String(pre).contains(String(marker)):
			return true
	for eff in card.effects:
		if String(eff.target).contains(String(marker)) or String(eff.stat).contains(".%s." % String(marker)):
			return true
	return false
