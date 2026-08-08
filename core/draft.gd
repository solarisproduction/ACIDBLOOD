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
	for pre in card.prerequisites:
		if int(acquired.get(pre, 0)) <= 0:
			return false
	for ex in card.excludes:
		if int(acquired.get(ex, 0)) > 0:
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
	while offer.size() < count and not pool.is_empty():
		var weights: Array[float] = []
		for card in pool:
			weights.append(card.weight)
		var idx := rng.weighted_index(weights)
		if idx < 0:
			break
		offer.append(pool[idx])
		pool.remove_at(idx)
	return offer
