class_name Catalog
extends RefCounted
## Lazy-loading registry over the data directories. All content lookup goes
## through here so the rest of the game never hardcodes resource paths.
## NOTE: DirAccess listing of res:// works in editor/headless runs; exported
## builds would need a manifest.

static var _enemies: Dictionary = {}
static var _turrets: Dictionary = {}
static var _cards: Array[CardData] = []
static var _stages: Array[StageData] = []
static var _upgrades: Array[PermUpgradeData] = []
static var _branches: Dictionary = {}
static var _guardian: GuardianData = null

static func _list_resources(dir_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("Catalog: cannot open %s" % dir_path)
		return out
	for file in dir.get_files():
		if file.ends_with(".tres") or file.ends_with(".res"):
			out.append(dir_path.path_join(file))
	out.sort()
	return out

static func enemies() -> Dictionary:
	if _enemies.is_empty():
		for path in _list_resources("res://data/enemies"):
			var e: EnemyData = load(path)
			_enemies[e.id] = e
	return _enemies

static func enemy(id: StringName) -> EnemyData:
	return enemies().get(id)

static func turrets() -> Dictionary:
	if _turrets.is_empty():
		for path in _list_resources("res://data/turrets"):
			var t: TurretData = load(path)
			_turrets[t.id] = t
	return _turrets

static func turret(id: StringName) -> TurretData:
	return turrets().get(id)

static func cards() -> Array[CardData]:
	if _cards.is_empty():
		for path in _list_resources("res://data/cards"):
			_cards.append(load(path) as CardData)
	return _cards

static func card(id: StringName) -> CardData:
	for c in cards():
		if c.id == id:
			return c
	return null

static func stages() -> Array[StageData]:
	if _stages.is_empty():
		for path in _list_resources("res://data/stages"):
			_stages.append(load(path) as StageData)
		_stages.sort_custom(func(a: StageData, b: StageData) -> bool: return a.index < b.index)
	return _stages

static func stage_by_index(index: int) -> StageData:
	for s in stages():
		if s.index == index:
			return s
	return null

static func ordered_stage_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for s in stages():
		ids.append(s.id)
	return ids

static func perm_upgrades() -> Array[PermUpgradeData]:
	if _upgrades.is_empty():
		for path in _list_resources("res://data/progression"):
			_upgrades.append(load(path) as PermUpgradeData)
	return _upgrades

static func turret_branches() -> Dictionary:
	if _branches.is_empty():
		for path in _list_resources("res://data/turret_branches"):
			var branch = load(path)
			_branches[branch.id] = branch
	return _branches

static func turret_branch(id: StringName):
	return turret_branches().get(id)

static func guardian() -> GuardianData:
	if _guardian == null:
		_guardian = load("res://data/guardian.tres")
	return _guardian

static func enemy_names() -> Array[String]:
	var names: Array[String] = []
	for e in enemies().values():
		names.append(e.name)
	return names
