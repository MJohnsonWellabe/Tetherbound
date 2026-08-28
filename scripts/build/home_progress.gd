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
## The rule: a home is the tutorial campsite -- the existing `camp` gives the
## player a physical fire and bedroll, and the workbench turns nearby gathering
## into more orbs and useful preparation. Floors, walls, roofs and doors stay
## available for players who enjoy building, but are never an opening gate.
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


## --- OP23-04 / owner directive 2026-08-23: a bed per entrant --------------

## The buildable id a Creature Bed is registered under
## (`data/items/buildables.json`). One place, because two functions below
## count it.
const CREATURE_BED_ID := "creature_bed"

## The ladder's three bed flags, in the order they fill. The FIRST is
## `creature_bed_built`, which predates this and is what
## `creature_bed.gd::CREATURE_BED_FLAG`, every existing save and
## `tests/smoke_gateb_flags.gd` already name -- it keeps its meaning exactly
## ("a bed the player built is standing") and simply became the first of three
## rather than the only one.
##
## `data/progression/objectives.json` counts these to render "Build a Creature
## Bed for each of your entrants. 1/3", and `tests/test_quest_log.gd` pins the
## LENGTH of that list against `data/config/tournament.json`'s `min_party_size`
## -- the number of creatures actually entered -- so the count is authored once
## and a change to the entry size fails a test instead of shipping a chain that
## asks for the wrong number of beds.
const CREATURE_BED_FLAGS: Array[String] = [
	"creature_bed_built", "creature_bed_built_2", "creature_bed_built_3",
]


## How many player-built Creature Beds are standing, counted from the same
## `GameState.placed_buildings` registry `pieces_built()` reads -- so this
## answers identically right after a placement and right after a load, and a
## bed that belongs to the world rather than to the player (the stronghold's
## authored recovery point, `creature_bed.gd::AUTHORED_STRONGHOLD_REST`) is
## never counted, because it is in no build store to be counted from.
static func creature_beds_built(placed_buildings: Array) -> int:
	return int(pieces_built(placed_buildings).get(CREATURE_BED_ID, 0))


## Set as many of `CREATURE_BED_FLAGS` as there are beds standing, and no more.
##
## Monotonic like every other progression flag: dismantling a bed does not
## un-set one. That is deliberate rather than lazy -- the objective records
## that the player LEARNED to build a bed each, and a chain that reopened a
## finished rung because a bed was moved would be a chain that can go
## backwards. The tournament's rested gate is what actually cares whether a
## creature has somewhere to sleep TONIGHT, it is per-occupant, and it reads
## the beds themselves rather than these flags.
static func maybe_set_creature_beds(game: Node) -> void:
	if game == null:
		return
	var progression: RefCounted = game.get("progression")
	if progression == null:
		return
	var standing := creature_beds_built(game.get("placed_buildings") as Array)
	for i in mini(standing, CREATURE_BED_FLAGS.size()):
		progression.call("set_flag", CREATURE_BED_FLAGS[i])


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
