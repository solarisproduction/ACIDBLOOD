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
##   under_pressure / critical_pressure: optional live threat context used to
##            weight emergency responses without replacing build choices
##   draft_index: optional 1-based draft number in this run, used for light
##            early-run guardrails
static func is_eligible(card: CardData, ctx: Dictionary) -> bool:
	if card == null or not card.category_contract_valid():
		return false
	var acquired: Dictionary = ctx.get("acquired", {})
	var unlocks: Dictionary = ctx.get("unlocks", {})
	var blocked: Array = ctx.get("blocked", [])
	var allowed_card_ids: Array = ctx.get("allowed_card_ids", [])
	var active_turrets: Array = ctx.get("active_turrets", [])
	var chosen_branches: Dictionary = ctx.get("chosen_branches", {})
	var chosen_branch_cards: Array = ctx.get("chosen_branch_cards", [])
	if not allowed_card_ids.is_empty() and card.id not in allowed_card_ids:
		return false
	if card_role(card) == &"build" and _build_target(card) in active_turrets:
		return false
	var branch_id := _branch_id(card)
	if branch_id != &"" and branch_id in chosen_branches.values():
		return false
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
	if not card.path_prerequisites.is_empty() and not _has_acquired_path(card.path_prerequisites, acquired, chosen_branch_cards):
		return false
	for ex in card.excludes:
		if int(acquired.get(ex, 0)) > 0 or ex in chosen_branch_cards:
			return false
	return true

static func _has_fortress_recovery(card: CardData) -> bool:
	for eff in card.effects:
		if eff.op == CardEffect.Op.HEAL_FORTRESS:
			return true
	return false

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
	var acquired_tags := _acquired_tag_counts(catalog, ctx.get("acquired", {}))
	var offer: Array[CardData] = []
	var draft_index := int(ctx.get("draft_index", 0))
	var critical_pressure := bool(ctx.get("critical_pressure", false))
	if critical_pressure and count > 0:
		var emergency_pool := _cards_with_role(pool, &"emergency")
		var emergency_card := _draw_weighted(emergency_pool, rng, ctx, acquired_tags, draft_index)
		if emergency_card != null:
			offer.append(emergency_card)
			pool.erase(emergency_card)
	if draft_index > 0 and draft_index <= 2 and count > offer.size():
		var build_pool := _cards_with_role(pool, &"build")
		var guaranteed_build := _draw_weighted(build_pool, rng, ctx, acquired_tags, draft_index)
		if guaranteed_build != null:
			offer.append(guaranteed_build)
			pool.erase(guaranteed_build)
	while offer.size() < count and not pool.is_empty():
		var candidate_pool := _pool_with_family_guard(pool, offer)
		var picked := _draw_weighted(candidate_pool, rng, ctx, acquired_tags, draft_index)
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
	if _has_fortress_recovery(card):
		return &"emergency"
	for eff in card.effects:
		if eff.op == CardEffect.Op.APPLY_BRANCH:
			return &"choice"
	if not card.prerequisites.is_empty():
		return &"upgrade"
	return &"passive"

static func semantic_category(card: CardData) -> StringName:
	return card.category

## Weapon/family identity is separate from the draft semantic category. It is
## used only for current family weighting and secondary UI labeling.
static func weapon_family(card: CardData) -> StringName:
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

static func _draw_weighted(cards: Array[CardData], rng: DetRNG, ctx: Dictionary, acquired_tags: Dictionary = {}, draft_index: int = 0) -> CardData:
	if cards.is_empty():
		return null
	var weights: Array[float] = []
	for card in cards:
		weights.append(_effective_weight(card, ctx, acquired_tags, draft_index))
	var idx := rng.weighted_index(weights)
	if idx < 0:
		return null
	return cards[idx]

static func _effective_weight(card: CardData, ctx: Dictionary, acquired_tags: Dictionary, draft_index: int) -> float:
	var weight := maxf(0.01, card.weight)
	var overlap := 0
	for tag in card.tags:
		overlap += int(acquired_tags.get(tag, 0))
	if overlap > 0:
		weight *= 1.0 + minf(0.85, float(overlap) * 0.18)
	var preferred_families: Array = ctx.get("preferred_families", [])
	if not preferred_families.is_empty():
		var family := weapon_family(card)
		if family in preferred_families:
			weight *= 1.14
	var role := card_role(card)
	if role == &"build":
		weight *= _build_context_multiplier(ctx, draft_index)
	elif role == &"emergency":
		weight *= _recovery_context_multiplier(ctx)
	elif role == &"choice":
		weight *= 1.05
	return weight

static func _build_context_multiplier(ctx: Dictionary, draft_index: int) -> float:
	var multiplier := 1.0
	if draft_index <= 4:
		multiplier *= 1.18
	var slots_available := int(ctx.get("slots_available", 0))
	var active_turrets_value: Variant = ctx.get("active_turrets", 0)
	var active_turrets: int = int(active_turrets_value.size()) if active_turrets_value is Array else int(active_turrets_value)
	if slots_available > 0:
		var structural_need := 1.0
		if active_turrets <= 0:
			structural_need = 1.0
		elif active_turrets == 1:
			structural_need = 0.72
		elif active_turrets == 2:
			structural_need = 0.45
		else:
			structural_need = 0.25
		multiplier *= 1.0 + minf(0.5, structural_need * 0.35 + float(slots_available) * 0.06)
	else:
		multiplier *= 0.7
	return multiplier

static func _recovery_context_multiplier(ctx: Dictionary) -> float:
	var hp := float(ctx.get("fortress_hp", -1.0))
	var max_hp := float(ctx.get("fortress_max_hp", -1.0))
	if hp < 0.0 or max_hp <= 0.0:
		return 1.0
	var missing := clampf(1.0 - (hp / max_hp), 0.0, 1.0)
	if missing <= 0.0:
		return 0.8
	var multiplier := 1.0 + minf(0.75, missing * 1.35)
	if bool(ctx.get("critical_pressure", false)):
		multiplier *= 1.25
	return multiplier

static func _acquired_tag_counts(catalog: Array[CardData], acquired: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for card_id in acquired.keys():
		var card := _find_card(catalog, card_id)
		if card == null:
			continue
		var copies := int(acquired.get(card_id, 0))
		for tag in card.tags:
			counts[tag] = int(counts.get(tag, 0)) + copies
	return counts

static func _find_card(catalog: Array[CardData], id: StringName) -> CardData:
	for card in catalog:
		if card.id == id:
			return card
	return null

static func _pool_with_family_guard(pool: Array[CardData], offer: Array[CardData]) -> Array[CardData]:
	if offer.size() < 2:
		return pool
	var family_counts := {}
	for card in offer:
		var family := weapon_family(card)
		family_counts[family] = int(family_counts.get(family, 0)) + 1
	var restricted: Array[CardData] = []
	for card in pool:
		if int(family_counts.get(weapon_family(card), 0)) >= 2:
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
	for path_pre in card.path_prerequisites:
		if String(path_pre).contains(String(marker)):
			return true
	for eff in card.effects:
		if String(eff.target).contains(String(marker)) or String(eff.stat).contains(".%s." % String(marker)):
			return true
	return false

static func _has_acquired_path(path_prerequisites: Array[StringName], acquired: Dictionary, chosen_branch_cards: Array) -> bool:
	for path_pre in path_prerequisites:
		if int(acquired.get(path_pre, 0)) > 0 and path_pre in chosen_branch_cards:
			return true
	return false

static func _build_target(card: CardData) -> StringName:
	for eff in card.effects:
		if eff.op == CardEffect.Op.UNLOCK_TURRET:
			return eff.target
	return &""

static func _branch_id(card: CardData) -> StringName:
	for eff in card.effects:
		if eff.op == CardEffect.Op.APPLY_BRANCH:
			return eff.target
	return &""
