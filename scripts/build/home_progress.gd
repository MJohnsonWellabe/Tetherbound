extends RefCounted

## GATEB-FLAGS (68-CHAPTER/17-RG18). "What counts as a home" for the two
## CONTRACT flags data/progression/objectives.json left for the building
## lane to decide -- `home_built` and `home_materials_gathered`.
##
## Deliberately NOT a spatial validation framework. No adjacency, no
## enclosure geometry, no walking the scene tree for gaps in a wall run --
## that is a whole new system for a single HUD line, and CLAUDE.md/spec 19
## already ban a giant quest/validation engine. The rule instead is a small,
## tunable COUNT of already-placed catalogue pieces, read the exact way
## `build_placer.gd::_neighbour_positions` already reads `GameState.
## placed_buildings` -- so a save/load or an out-of-order build (structure
## first, camp second, whichever) answers the question the same way live
## placement does.
##
## The rule: a home is the tutorial camp -- fire + bedroll, already the
## literal sleep spot (`camp.gd::_on_rest`) the very next objective asks the
## player to use -- enclosed by the smallest room a player would naturally
## build around it: one floor tile, one wall, a roof, and a usable door.
## That is more than a campfire alone (which is why `home_built` is not just
## "has a camp"), short of a fully sealed four-wall box (which would need
## the adjacency framework this file exists to avoid), and it is exactly
## the piece set `buildables.json`'s own `structures` tab already offers.
##
## `data/config/progression.json`'s `home.required_pieces` is the ONE place
## that count lives. `materials_threshold()` below sums those same pieces'
## own `buildables.json` costs rather than typing a second number by hand,
## so "gather enough for a home" and "build a home" can never drift apart --
## move a buildable's cost and both beats move with it for free.

const CONFIG_PATH := "res://data/config/progression.json"

static var _config: Dictionary = {}


static func _load_config() -> Dictionary:
	if not _config.is_empty():
		return _config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("progression.json missing at %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_config = parsed
	return _config


## id -> how many of that placed catalogue piece a home needs. TUNABLE --
## `data/config/progression.json`'s `home.required_pieces`. `cfg` lets a test
## pin a small dict without touching the shipped file, the same seam
## `progression.gd::config()`'s callers use.
static func required_pieces(cfg: Dictionary = {}) -> Dictionary:
	var config: Dictionary = cfg if not cfg.is_empty() else _load_config()
	var home: Dictionary = config.get("home", {})
	return home.get("required_pieces", {})


## How many of each catalogue id already stand in the world, counted from
## `GameState.placed_buildings` (the save-format registry every placed piece
## is entered into, not the live scene tree) so this answers identically
## right after a fresh placement and right after a load.
static func pieces_built(placed_buildings: Array) -> Dictionary:
	var counts := {}
	for entry: Variant in placed_buildings:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var id := str((entry as Dictionary).get("id", ""))
		if id.is_empty():
			continue
		counts[id] = int(counts.get(id, 0)) + 1
	return counts


## True once every `required_pieces()` entry is met or exceeded. Empty
## config (a broken/missing file) fails closed rather than reading as an
## instantly-satisfied home.
static func home_built(placed_buildings: Array, cfg: Dictionary = {}) -> bool:
	var required := required_pieces(cfg)
	if required.is_empty():
		return false
	var counts := pieces_built(placed_buildings)
	for id: String in required.keys():
		if int(counts.get(id, 0)) < int(required[id]):
			return false
	return true


## The raw material cost of one full `required_pieces()` set, read straight
## from `buildables.json` through `items` (ItemDB) -- never a hand-typed
## number. {item_id: n, ...}.
static func materials_threshold(items: RefCounted, cfg: Dictionary = {}) -> Dictionary:
	var required := required_pieces(cfg)
	var totals := {}
	for id: String in required.keys():
		var copies := int(required[id])
		var entry: Dictionary = items.call("buildable", id)
		for requirement: Variant in (entry.get("cost", []) as Array):
			var need := requirement as Dictionary
			var item_id := str(need.get("id", ""))
			if item_id.is_empty():
				continue
			totals[item_id] = int(totals.get(item_id, 0)) + int(need.get("n", 0)) * copies
	return totals


## True once `inventory` holds at least `materials_threshold()` of
## everything. Reads the CATALOGUE cost always, ignoring the free-build
## toggle on purpose: free build only waives what PLACING a piece spends
## (`GameState.build_cost_for`), never what gathering hands the player, so
## this stays a real, always-reachable threshold whether or not building
## itself happens to be free right now -- the same ladder a free-build
## tester still climbs, they just never have to spend what they gathered.
static func materials_gathered(inventory: RefCounted, items: RefCounted, cfg: Dictionary = {}) -> bool:
	var threshold := materials_threshold(items, cfg)
	if threshold.is_empty():
		return false
	for item_id: String in threshold.keys():
		if int(inventory.call("count", item_id)) < int(threshold[item_id]):
			return false
	return true


## One-line call site for a build-placement path: sets `home_built` the
## instant it becomes true and never again (idempotent no-op after that,
## same as every other progression flag). Safe to call on every placement
## and on save restore alike.
static func maybe_set_home_built(game: Node) -> void:
	if game == null:
		return
	var progression: RefCounted = game.get("progression")
	if progression == null or bool(progression.call("has", "home_built")):
		return
	var buildings: Array = game.get("placed_buildings") as Array
	if home_built(buildings):
		progression.call("set_flag", "home_built")


## One-line call site for a gathering-completion path.
static func maybe_set_materials_gathered(game: Node) -> void:
	if game == null:
		return
	var progression: RefCounted = game.get("progression")
	if progression == null or bool(progression.call("has", "home_materials_gathered")):
		return
	var inventory: RefCounted = game.get("inventory")
	var items: RefCounted = game.get("items")
	if inventory == null or items == null:
		return
	if materials_gathered(inventory, items):
		progression.call("set_flag", "home_materials_gathered")
