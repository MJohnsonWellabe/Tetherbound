extends "res://tests/test_case.gd"

## REWARD-ECONOMY (prompt 58). The chapter's reward audit,
## `data/config/chapter_rewards.json`, and the invariants it declares.
##
## Every check here is one of prompt 58's own acceptance bullets turned into
## something a build can fail on. The audit table itself is design record and is
## not read by the game — what IS enforced is that the economy it describes
## still matches the economy that ships.
##
## The one that caught something real: `every_tm_is_obtainable`. Three of the
## fourteen TMs in items.json — Earthshatter, Leviathan Surge and Heavenfall,
## one apex move per type, all three with complete entries in moves.json and
## tms.json — had no acquisition path anywhere in the game. Not mispriced, not
## badly placed: unobtainable. Nothing failed, because nothing was looking.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const BAND_CONTENT := preload("res://scripts/data/band_content.gd")

## Read as TEXT, not preloaded. `playground_world.gd` extends Node3D and pulls
## in the whole world; D02 keeps this suite pure logic, and the only thing
## wanted from it is one const. Same approach tools/_probe_pacing.py takes to
## the same file's SIGIL_GATE_AT.
const WORLD_SCRIPT_PATH := "res://scripts/world/playground_world.gd"

const REWARDS_PATH := "res://data/config/chapter_rewards.json"
const ITEMS_PATH := "res://data/items/items.json"
const TRADE_PATH := "res://data/config/trade.json"
const BUILDABLES_PATH := "res://data/items/buildables.json"
const HARVEST_PATH := "res://data/config/harvest.json"
const RECIPE_PATHS := [
	"res://data/recipes/recipes.json",
	"res://data/recipes/recipes_rootstone.json",
	"res://data/recipes/recipes_ironwood.json",
]


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _audit() -> Dictionary:
	var data := _json(REWARDS_PATH)
	assert_false(data.is_empty(), "%s is missing or unparseable" % REWARDS_PATH)
	return data


func _item_ids() -> Array:
	var items: Variant = _json(ITEMS_PATH).get("items", {})
	if items is Dictionary:
		return (items as Dictionary).keys()
	var out: Array = []
	for entry: Variant in (items as Array):
		out.append(str((entry as Dictionary).get("id", "")))
	return out


## The `tm_*` keys of `playground_world.gd`'s TM_AT, by regex over the source.
func _tms_placed_in_the_world() -> Array:
	var source := FileAccess.get_file_as_string(WORLD_SCRIPT_PATH)
	assert_ne(source, "", "%s could not be read" % WORLD_SCRIPT_PATH)
	var block_start := source.find("const TM_AT")
	assert_true(block_start != -1, "%s has no `const TM_AT`" % WORLD_SCRIPT_PATH)
	var block_end := source.find("}", block_start)
	var block := source.substr(block_start, block_end - block_start)
	var found: Array = []
	var re := RegEx.create_from_string("\"(tm_[a-z_]+)\"\\s*:\\s*Vector2")
	for m: RegExMatch in re.search_all(block):
		found.append(m.get_string(1))
	assert_true(found.size() >= 2,
		"parsed %d TMs out of TM_AT; the block's shape changed and this check went blind" % found.size())
	return found


## Where a TM can come from: standing in the world, stocked by a vendor, or
## paid by a trainer. Any one of the three makes it obtainable.
func _obtainable_tms() -> Dictionary:
	var found: Dictionary = {}
	for id: String in _tms_placed_in_the_world():
		found[id] = "world pickup"
	for vendor: Variant in (_json(TRADE_PATH).get("vendors", {}) as Dictionary).values():
		for good: Variant in ((vendor as Dictionary).get("goods", {}) as Dictionary).keys():
			if str(good).begins_with("tm_"):
				found[str(good)] = "shop"
	for entry: Variant in TRAINERS.trainers():
		for item: Variant in ((entry as Dictionary).get("reward", {}) as Dictionary).get("items", []):
			var id := str((item as Dictionary).get("id", ""))
			if id.begins_with("tm_"):
				found[id] = "trainer reward"
	return found


## Prompt 58: "A found TM should feel like a meaningful team-build choice."
## A TM that cannot be found at all is not a choice, and this is the check that
## was missing when three of them shipped that way.
func test_every_tm_in_the_game_can_actually_be_obtained() -> void:
	var obtainable := _obtainable_tms()
	var tms: Array = []
	for id: Variant in _item_ids():
		if str(id).begins_with("tm_"):
			tms.append(str(id))
	assert_true(tms.size() >= 10,
		"only %d TMs were read from items.json; this check would barely test anything" % tms.size())
	for id: String in tms:
		assert_true(obtainable.has(id),
			("'%s' exists as an item but is in no shop, no trainer reward and nowhere in the world; "
			+ "a player can never get it") % id)


## And the other direction: a TM placed in the world or sold in a shop that has
## no teach data is a pickup that does nothing when used.
func test_every_obtainable_tm_can_be_taught_to_something() -> void:
	var tms: Dictionary = _json("res://data/moves/tms.json").get("tms", {})
	var moves: Dictionary = _json("res://data/moves/moves.json").get("moves", {})
	assert_false(tms.is_empty(), "tms.json read empty; this check would pass vacuously")
	for id: String in _obtainable_tms().keys():
		assert_true(tms.has(id),
			"'%s' can be obtained but has no entry in tms.json; using it would teach nothing" % id)
		var move := str((tms.get(id, {}) as Dictionary).get("move_id", ""))
		assert_true(moves.has(move),
			"'%s' teaches move '%s', which is not in moves.json" % [id, move])
		var types: Array = (tms.get(id, {}) as Dictionary).get("compatible_types", []) as Array
		assert_false(types.is_empty(),
			"'%s' is compatible with no type at all; no creature could ever learn it" % id)


## Prompt 58: "Every introduced material must have understandable current uses."
## The failure this guards is a material the world yields that nothing consumes
## — the "that is another collectible" outcome its definition-of-done rejects.
func test_no_material_the_world_yields_is_an_orphan() -> void:
	var harvest: Dictionary = BAND_CONTENT.load_config(HARVEST_PATH, "nodes")
	var yielded: Dictionary = {}
	for node: Variant in (harvest.get("nodes", []) as Array):
		yielded[str((node as Dictionary).get("item", ""))] = true
	assert_true(yielded.size() >= 4,
		"only %d harvestable materials found; this check would barely test anything" % yielded.size())

	var consumed: Dictionary = {}
	for path: String in RECIPE_PATHS:
		for recipe: Variant in (_json(path).get("recipes", {}) as Dictionary).values():
			for cost: Variant in ((recipe as Dictionary).get("cost", []) as Array):
				consumed[str((cost as Dictionary).get("id", ""))] = "recipe input"
	var buildables := FileAccess.get_file_as_string(BUILDABLES_PATH)
	var trade := FileAccess.get_file_as_string(TRADE_PATH)

	for material: String in yielded.keys():
		var quoted := "\"%s\"" % material
		assert_true(consumed.has(material) or buildables.contains(quoted) or trade.contains(quoted),
			("the world yields '%s' and nothing consumes it — no recipe, no build cost, no shop. "
			+ "That is a collectible, which is what prompt 58's definition of done rejects") % material)


## Prompt 58: "money has useful sinks" and "the player should periodically want
## coins." Both fail the same way — income the shop cannot absorb — so this
## checks that what the chapter pays out can actually buy the thing worth
## saving for.
func test_coin_income_can_buy_the_things_worth_saving_for() -> void:
	var audit := _audit()
	var want := int((audit.get("invariants", {}) as Dictionary).get(
		"coin_income_covers_at_least_n_expensive_tms", 2))

	var income := int((_json(TRADE_PATH).get("starting_coins", 0)))
	for entry: Variant in TRAINERS.trainers():
		var reward: Dictionary = (entry as Dictionary).get("reward", {})
		income += int(reward.get("coins", 0))
		for item: Variant in (reward.get("items", []) as Array):
			if str((item as Dictionary).get("id", "")) == "coin":
				income += int((item as Dictionary).get("count", 0))

	var prices: Array[int] = []
	for vendor: Variant in (_json(TRADE_PATH).get("vendors", {}) as Dictionary).values():
		var goods: Dictionary = (vendor as Dictionary).get("goods", {})
		for good: String in goods.keys():
			if good.begins_with("tm_"):
				prices.append(int((goods[good] as Dictionary).get("buy", 0)))
	assert_true(prices.size() >= want,
		"only %d TMs are for sale; the coin sink this checks does not exist" % prices.size())
	prices.sort()
	prices.reverse()
	var dearest := 0
	for i in mini(want, prices.size()):
		dearest += prices[i]
	assert_true(income >= dearest,
		("the chapter pays out %d coins and its %d dearest TMs cost %d together; "
		+ "money has no reachable sink") % [income, want, dearest])


## The audit is design record, but a row naming an item that does not exist is a
## record of something that never shipped.
func test_every_item_the_audit_names_is_real() -> void:
	var known := _item_ids()
	assert_false(known.is_empty(), "items.json read empty; this check would pass vacuously")
	var rows: Array = _audit().get("activities", []) as Array
	assert_true(rows.size() >= 15,
		"the reward audit has only %d rows; it does not cover the chapter" % rows.size())
	for row: Variant in rows:
		for key: String in ((row as Dictionary).get("reward", {}) as Dictionary).keys():
			if key in ["coins", "xp_bonus", "tm", "spends", "rootstone", "heartstone"]:
				continue
			assert_true(known.has(key),
				"the reward audit's '%s' row pays '%s', which is not an item"
					% [str((row as Dictionary).get("activity", "")), key])
