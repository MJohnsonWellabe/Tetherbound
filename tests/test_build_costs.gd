extends "res://tests/test_case.gd"

## Building costs materials, and the three stations that were waiting on an
## inventory now have one.
##
## Four halves, and they fail in different ways:
##
##   1. THE PRICES. Every piece has a cost, every cost names a real item, and the
##      reference cottage adds up to a session's work. This is the test that
##      replaced `test_stations.test_no_piece_carries_a_build_cost_yet`, which
##      asserted the opposite while there was nothing to pay with.
##   2. THE SPENDING. `build_mode`'s shortfall arithmetic against a real
##      `inventory.gd`, including the case that matters most — a null purse
##      cannot afford anything, and building is never quietly free.
##   3. THE WORKBENCH. Recipes, crafting, and the free repair §19 asks for.
##   4. STORAGE, AND THE HARD RULE. A chest holds items and CANNOT hold a
##      creature, and the last four tests are what make that structural rather
##      than merely absent.
##
## Deliberately NOT here: `build_mode` driving a ghost, or `structures.place()`
## building real nodes. `run_tests.gd` works inside `SceneTree._init()`, where
## `root` is not yet in the tree and every `global_position` silently reads
## (0,0,0). `tests/smoke_build.gd` is where the node-level round trip belongs.

const BUILD := preload("res://scripts/building/build_mode.gd")
const STATION := preload("res://scripts/building/station.gd")
const INVENTORY := preload("res://scripts/items/inventory.gd")
const STACK := preload("res://scripts/items/item_stack.gd")
const DEFS := preload("res://scripts/items/item_defs.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")

const CATALOGUE := "res://data/building/pieces.json"
const RECIPES := "res://data/recipes/crafting.json"

const WORKBENCH := "workbench_timber"
const STORAGE := "storage_crate"
const BERRY_PLOT := "berry_plot"

## GAME_DESIGN.md §20's early tutorial — "Build shelter. Build bed. Build
## campfire." — as an actual shopping list: a 2x2-cell room is four floors and
## eight wall edges, one of which is the doorway.
const COTTAGE := {
	"floor_wooddark": 4,
	"wall_plaster_straight": 7,
	"wall_plaster_door_round": 1,
	"door_1_round": 1,
	"roof_roundtiles_4x4": 1,
	"bed_simple": 1,
	"campfire_stone": 1,
}

var _built: Array[Node] = []


func after_each() -> void:
	for node: Node in _built:
		if is_instance_valid(node):
			node.free()
	_built.clear()


func _pieces() -> Dictionary:
	var file := FileAccess.open(CATALOGUE, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var out: Dictionary = {}
	if parsed is Dictionary:
		for id: String in (parsed as Dictionary).get("pieces", {}).keys():
			if not id.begins_with("_"):
				out[id] = (parsed as Dictionary)["pieces"][id]
	return out


func _cost(piece_id: String) -> Dictionary:
	var entry: Variant = (_pieces().get(piece_id, {}) as Dictionary).get("cost", {})
	return entry if entry is Dictionary else {}


func _station(piece_id: String) -> Node:
	var piece: Dictionary = _pieces().get(piece_id, {})
	var station: Node = STATION.create(piece)
	if station != null:
		station.call("setup", piece_id, STATION.config_of(piece), Vector3.ZERO)
		_built.append(station)
	return station


func _bag(contents: Dictionary = {}) -> RefCounted:
	var bag: RefCounted = INVENTORY.new()
	for item: String in contents.keys():
		bag.add(item, int(contents[item]))
	return bag


# --- the prices -------------------------------------------------------------

func test_every_piece_costs_something() -> void:
	# The replacement for the old "no piece carries a cost" guard, and it is the
	# stronger statement: a piece with no price is one the player can spam, and a
	# free wall next to a priced one reads as a bug rather than as a bargain.
	var priced := 0
	for id: String in _pieces().keys():
		var cost := _cost(id)
		assert_false(cost.is_empty(), "build piece '%s' is free" % id)
		priced += 1
	assert_eq(priced, _pieces().size())


func test_every_cost_names_a_real_item_in_a_real_amount() -> void:
	# A typo in a cost is a piece nobody can ever build, and it would look exactly
	# like a balance problem from inside the game.
	for id: String in _pieces().keys():
		for item: String in _cost(id).keys():
			assert_true(DEFS.has(item), "piece '%s' costs '%s', which is not an item" % [id, item])
			assert_true(int(_cost(id)[item]) > 0,
				"piece '%s' costs %s of '%s'" % [id, _cost(id)[item], item])


func test_nothing_is_built_out_of_a_creature() -> void:
	# CLAUDE.md: "No hunting/butchering." GAME_DESIGN.md §19: "Do not create a
	# meat/leather economy." A build cost is the sneakiest place that could
	# arrive, because a roof asking for hide reads as flavour.
	var forbidden := ["meat", "hide", "leather", "bone", "pelt", "fur", "sinew", "egg"]
	for id: String in _pieces().keys():
		for item: String in _cost(id).keys():
			for word: String in forbidden:
				assert_false(item.contains(word),
					"piece '%s' costs '%s'; there is no hunting economy" % [id, item])
			assert_false(SPECIES.has(item),
				"piece '%s' costs '%s', which is a creature" % [id, item])


func test_a_starter_cottage_is_a_session_of_gathering() -> void:
	# The number the owner will actually feel, pinned so a rebalance has to face
	# it. Against data/config/gathering.json: a tree is 12 wood, a boulder 8
	# stone, a bush 6 fiber with a knife.
	var total: Dictionary = {}
	for id: String in COTTAGE.keys():
		for item: String in _cost(id).keys():
			total[item] = int(total.get(item, 0)) + int(_cost(id)[item]) * int(COTTAGE[id])

	assert_eq(int(total.get("wood", 0)), 72, "the cottage's wood bill has moved")
	assert_eq(int(total.get("stone", 0)), 28, "the cottage's stone bill has moved")
	assert_eq(int(total.get("fiber", 0)), 32, "the cottage's fiber bill has moved")

	# Six trees, four boulders and six bushes. The band is what is actually being
	# asserted: under about four trees the cottage is free and building never
	# becomes a reason to explore; over about a dozen it is a chore, which is the
	# word CLAUDE.md uses for the thing to avoid.
	var trees := float(total["wood"]) / 12.0
	var boulders := float(total["stone"]) / 8.0
	var bushes := float(total["fiber"]) / 6.0
	assert_between(trees, 4.0, 12.0, "a cottage should be a few trees")
	assert_between(boulders, 2.0, 8.0, "a cottage should be a few boulders")
	assert_between(bushes, 3.0, 12.0, "a cottage should be a few bushes")


func test_a_stone_wall_and_a_timber_floor_are_priced_in_different_things() -> void:
	# The reason there are three materials rather than one. If everything cost
	# wood, gathering stone would be busywork.
	assert_true(int(_cost("wall_unevenbrick_straight").get("stone", 0)) > 0,
		"a brick wall should want stone")
	assert_true(int(_cost("floor_wooddark").get("wood", 0)) > 0, "a wooden floor should want wood")
	assert_eq(int(_cost("floor_wooddark").get("stone", 0)), 0,
		"a plain wooden floor should not want stone")
	assert_true(int(_cost("roof_roundtiles_4x4").get("fiber", 0)) > 0,
		"a roof should want fiber; nothing else does enough to make fiber worth gathering")


func test_a_bigger_roof_costs_more_than_a_smaller_one() -> void:
	# Sanity on the ladder. A 3x4 roof covering three times the floor of a 2x2 for
	# the same price is the sort of thing nobody notices until a player builds
	# nothing but the big one.
	var small := int(_cost("roof_roundtiles_4x4").get("wood", 0))
	var large := int(_cost("roof_roundtiles_6x8").get("wood", 0))
	assert_true(large > small, "the 3x4 roof (%d wood) must cost more than the 2x2 (%d)" % [large, small])


# --- spending ---------------------------------------------------------------

func test_a_full_purse_is_short_of_nothing() -> void:
	var bag := _bag({"wood": 10, "stone": 10, "fiber": 10})
	assert_eq(BUILD.shortfall(bag, {"wood": 4}), {})
	assert_eq(BUILD.shortfall(bag, {"wood": 4, "stone": 2, "fiber": 2}), {})


func test_a_short_purse_says_what_is_missing_and_by_how_much() -> void:
	# Not "no". A refusal that does not name the material sends the player out to
	# gather the wrong thing.
	var bag := _bag({"wood": 2})
	assert_eq(BUILD.shortfall(bag, {"wood": 4, "stone": 6}), {"wood": 2, "stone": 6})
	assert_true(BUILD.describe_shortfall({"wood": 2}).contains("2 more Wood"))
	assert_true(BUILD.describe_cost({"wood": 4, "stone": 2}).contains("4 Wood"))


func test_no_inventory_cannot_afford_anything() -> void:
	# The single most important line in this file. The brief for the trainer's
	# inventory says: if it is absent at runtime, refuse the action and say why —
	# never silently succeed. A null purse that returned "affordable" would make
	# building free for anyone whose inventory had not finished loading.
	assert_eq(BUILD.shortfall(null, {"wood": 4}), {"wood": 4})
	assert_false(BUILD.shortfall(null, {"wood": 4}).is_empty(),
		"a missing inventory must not make building free")
	# A free piece is still free, which is the only thing a null purse can allow.
	assert_eq(BUILD.shortfall(null, {}), {})


func test_an_object_that_is_not_an_inventory_cannot_afford_anything() -> void:
	# Duck typing's failure mode: something is wired to the wrong node and every
	# call quietly does nothing. `has_method` is what catches it.
	assert_eq(BUILD.shortfall(RefCounted.new(), {"stone": 3}), {"stone": 3})


func test_spending_a_cost_takes_exactly_it() -> void:
	var bag := _bag({"wood": 10, "stone": 10})
	for item: String in {"wood": 4, "stone": 2}.keys():
		bag.remove(item, int({"wood": 4, "stone": 2}[item]))
	assert_eq(bag.count_of("wood"), 6)
	assert_eq(bag.count_of("stone"), 8)


func test_a_refund_puts_a_wall_back_in_the_bag() -> void:
	# Removal refunds in full — a tunable, and the reasoning is in
	# data/config/building.json. This asserts the arithmetic is a round trip: a
	# wall put up and taken down leaves the trainer exactly where they started.
	var cost := _cost("wall_plaster_straight")
	var bag := _bag({"wood": 20, "stone": 20, "fiber": 20})
	var before := {
		"wood": bag.count_of("wood"), "stone": bag.count_of("stone"), "fiber": bag.count_of("fiber")
	}
	for item: String in cost.keys():
		bag.remove(item, int(cost[item]))
	assert_true(bag.count_of("wood") < int(before["wood"]), "building must cost something")
	for item: String in cost.keys():
		bag.add(item, int(cost[item]))
	for item: String in before.keys():
		assert_eq(bag.count_of(item), int(before[item]), "the refund did not balance for %s" % item)


# --- the workbench ----------------------------------------------------------

func test_the_workbench_is_not_an_empty_station() -> void:
	# The rule this milestone was warned about by name: "Do not ship a workbench
	# that places and does nothing." It has recipes and it has a repair, and if
	# either ever goes away this fails.
	var bench := _station(WORKBENCH)
	assert_ne(bench, null, "the workbench must attach a station")
	assert_true((bench.call("recipes") as Dictionary).size() >= 3,
		"a bench with nothing to craft is a decoration with extra steps")
	assert_true(bench.has_method("repair"), "§19: tools repair for free at a station")


func test_every_recipe_makes_a_real_item_from_real_materials() -> void:
	var file := FileAccess.open(RECIPES, FileAccess.READ)
	assert_ne(file, null, "the recipe file must exist")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	var recipes: Dictionary = (parsed as Dictionary).get("recipes", {})
	var checked := 0
	for id: String in recipes.keys():
		if id.begins_with("_"):
			continue
		var recipe: Dictionary = recipes[id]
		assert_true(DEFS.has(str(recipe.get("makes", ""))),
			"recipe '%s' makes '%s', which is not an item" % [id, recipe.get("makes", "")])
		for item: String in (recipe.get("costs", {}) as Dictionary).keys():
			assert_true(DEFS.has(item), "recipe '%s' costs '%s', which is not an item" % [id, item])
			assert_false(SPECIES.has(item), "recipe '%s' costs a creature" % id)
		checked += 1
	assert_eq(checked, 5, "M8 asks for five tools")


func test_the_five_tools_are_all_craftable() -> void:
	# §19 lists Axe, Pickaxe, Knife, Hammer, Fishing Rod. A tool with no recipe is
	# a tool the player can only ever have been given.
	var makes: Array[String] = []
	for id: String in (_station(WORKBENCH).call("recipes") as Dictionary).keys():
		makes.append(str(((_station(WORKBENCH).call("recipes") as Dictionary)[id] as Dictionary).get("makes", "")))
	for tool_id: String in ["axe", "pickaxe", "knife", "hammer", "fishing_rod"]:
		assert_true(makes.has(tool_id), "'%s' has no recipe" % tool_id)


func test_crafting_spends_the_materials_and_hands_over_the_tool() -> void:
	var bench := _station(WORKBENCH)
	var bag := _bag({"wood": 10, "fiber": 10})
	assert_true(bool(bench.call("can_craft", bag, "axe")))
	assert_true(bool(bench.call("craft", bag, "axe")))
	assert_eq(bag.count_of("axe"), 1, "the bench must hand over the axe")
	assert_eq(bag.count_of("wood"), 7, "an axe costs 3 wood")
	assert_eq(bag.count_of("fiber"), 8, "an axe costs 2 fiber")


func test_crafting_without_the_materials_is_refused_and_costs_nothing() -> void:
	var bench := _station(WORKBENCH)
	var bag := _bag({"wood": 1})
	assert_false(bool(bench.call("craft", bag, "axe")))
	assert_eq(str(bench.call("last_refusal")), "not_enough")
	assert_eq(bag.count_of("wood"), 1, "a refused craft must not have taken the wood")
	assert_eq(bag.count_of("axe"), 0)


func test_a_recipe_nobody_wrote_is_refused_rather_than_made() -> void:
	var bench := _station(WORKBENCH)
	assert_false(bool(bench.call("craft", _bag({"wood": 99}), "sword")))
	assert_eq(str(bench.call("last_refusal")), "no_such_recipe")


func test_the_bench_mends_a_worn_tool_for_free() -> void:
	# §19: "repair for free at appropriate station". Free means FREE — no
	# materials, no partial restore, and the station is a place rather than a
	# price.
	var bench := _station(WORKBENCH)
	var bag := _bag({"axe": 1})
	var axe: RefCounted = bag.at(0)
	axe.use(40)
	assert_true(int(axe.durability) < axe.max_durability())
	assert_true(bool(bench.call("repair", bag, 0)))
	assert_eq(int(axe.durability), axe.max_durability(), "repair must be whole")


func test_the_bench_mends_a_broken_tool_rather_than_replacing_it() -> void:
	# A tool at zero durability is BROKEN, NOT DESTROYED — item_stack.gd's
	# reasoning — and free repair is what makes that a mercy rather than a
	# permanent dead slot.
	var bench := _station(WORKBENCH)
	var bag := _bag({"knife": 1})
	var knife: RefCounted = bag.at(0)
	knife.use(knife.max_durability())
	assert_true(bool(knife.is_broken()))
	assert_eq(int(bench.call("repair_all", bag)), 1)
	assert_false(bool(knife.is_broken()), "a broken tool must come back from the bench")


func test_mending_a_bag_with_nothing_worn_says_so() -> void:
	var bench := _station(WORKBENCH)
	assert_eq(int(bench.call("repair_all", _bag({"axe": 1}))), 0)
	assert_eq(str(bench.call("last_refusal")), "nothing_to_mend")


# --- storage, and the hard rule ---------------------------------------------

func test_a_chest_holds_items() -> void:
	var chest := _station(STORAGE)
	assert_ne(chest, null, "the storage crate must attach a station")
	assert_true(bool(chest.call("is_empty")))
	assert_true(bool(chest.call("put", "wood", 30)))
	assert_eq(int(chest.call("count_of", "wood")), 30)
	assert_true(bool(chest.call("take", "wood", 10)))
	assert_eq(int(chest.call("count_of", "wood")), 20)


func test_a_chest_is_a_view_onto_the_same_inventory_everything_else_uses() -> void:
	# A chest is a VIEW onto an inventory, never a second kind of container. If it
	# ever grows its own storage code, the rules that make an inventory safe —
	# including "it cannot hold a pal" — stop applying to it.
	var chest := _station(STORAGE)
	var held: RefCounted = chest.call("contents")
	assert_ne(held, null)
	assert_true(held.has_method("add") and held.has_method("to_records") and held.has_method("count_of"),
		"a chest must be made of scripts/items/inventory.gd")
	assert_eq(int(chest.call("slot_count")), 12, "the crate's capacity comes from pieces.json")


func test_a_chest_survives_a_reload_with_its_contents() -> void:
	var chest := _station(STORAGE)
	chest.call("put", "stone", 15)
	chest.call("put", "berries", 4)
	var record := STATION.write_record({"piece": STORAGE}, chest)
	assert_true(record.has(STATION.KEY), "a chest with something in it must save it")

	var after := _station(STORAGE)
	assert_true(bool(after.call("is_empty")), "a fresh chest is empty")
	after.call("load_state", STATION.read_record(record))
	assert_eq(int(after.call("count_of", "stone")), 15)
	assert_eq(int(after.call("count_of", "berries")), 4)


func test_a_worn_axe_stowed_in_a_chest_comes_back_worn() -> void:
	# The reason `stow()` takes a stack rather than an item id: `add()` builds a
	# fresh one from the definition, and a 40%-worn axe put in a chest must not
	# come out brand new.
	var chest := _station(STORAGE)
	var axe: RefCounted = STACK.create("axe", 1)
	axe.use(48)
	assert_true(bool(chest.call("stow", axe)))
	var record := STATION.write_record({"piece": STORAGE}, chest)
	var after := _station(STORAGE)
	after.call("load_state", STATION.read_record(record))
	var back: RefCounted = (after.call("contents") as RefCounted).at(0)
	assert_ne(back, null)
	assert_eq(int(back.durability), 120 - 48, "the chest polished the axe")


func test_a_chest_cannot_be_given_a_creature() -> void:
	# CLAUDE.md: "Player can own only five pals total. Never implement pal storage
	# beyond five." A chest is the single most obvious place that rule dies.
	#
	# The only way into a chest is an item id, checked against items.json. Every
	# species id in the game is offered here and every one must be refused — not
	# by a special case that names pals, but because a species is not an item.
	var chest := _station(STORAGE)
	var offered := 0
	for species_id: String in SPECIES.table().keys():
		if species_id.begins_with("_"):
			continue
		assert_false(bool(chest.call("put", species_id, 1)),
			"a chest accepted '%s', which is a creature" % species_id)
		assert_eq(str(chest.call("last_refusal")), "unknown_item")
		offered += 1
	assert_true(offered >= 2, "there should be species to offer")
	assert_true(bool(chest.call("is_empty")), "nothing may have got in")


func test_no_item_in_the_game_is_a_creature() -> void:
	# The other half of the same guard, from the data side. The day somebody adds
	# a `pal_bruno` item to items.json to "make pals storable", a chest would
	# accept it and the hard rule would be gone with no code change at all. This
	# is where that stops.
	for item_id: String in DEFS.ids():
		assert_false(SPECIES.has(item_id),
			"'%s' is both an item and a creature; that is half a pal box" % item_id)


func test_a_chest_has_no_verb_that_takes_a_creature() -> void:
	# Structural, not merely absent. Getting a pal into a chest would take a NEW
	# METHOD, and this is the list of names anyone would reach for first.
	var chest := _station(STORAGE)
	for verb: String in [
		"store_pal", "deposit_pal", "put_pal", "add_pal", "keep", "box",
		"stash_creature", "store_creature", "pals", "party",
	]:
		assert_false(chest.has_method(verb),
			"storage has a '%s' method; there is no pal storage beyond the five" % verb)


func test_a_chest_refuses_anything_that_is_not_in_the_item_table() -> void:
	var chest := _station(STORAGE)
	assert_false(bool(chest.call("put", "moonstone", 1)))
	assert_eq(str(chest.call("last_refusal")), "unknown_item")
	assert_false(bool(chest.call("put", "", 1)))


# --- the berry plot ---------------------------------------------------------

func test_a_new_plot_is_empty_and_says_so() -> void:
	var plot := _station(BERRY_PLOT)
	assert_ne(plot, null, "the berry plot must attach a station")
	assert_eq(str(plot.call("state")), "empty")
	assert_false(bool(plot.call("is_planted")))
	assert_almost_eq(float(plot.call("growth")), 0.0)


func test_planting_costs_a_berry() -> void:
	# §21: plant, wait, harvest. The seed is a berry the player found, which is
	# what connects farming to foraging rather than making it a separate economy.
	var plot := _station(BERRY_PLOT)
	var bag := _bag({"berries": 3})
	assert_true(bool(plot.call("plant", bag)))
	assert_eq(bag.count_of("berries"), 2, "planting must cost a seed")
	assert_eq(str(plot.call("state")), "growing")


func test_planting_with_no_seed_is_refused() -> void:
	var plot := _station(BERRY_PLOT)
	assert_false(bool(plot.call("plant", _bag({}))))
	assert_eq(str(plot.call("last_refusal")), "no_seed")
	assert_false(bool(plot.call("is_planted")), "a refused planting must leave bare soil")


func test_a_plot_ripens_after_its_own_time_and_not_before() -> void:
	var plot := _station(BERRY_PLOT)
	plot.call("plant", _bag({"berries": 1}))
	plot.call("tick", 100.0)
	assert_false(bool(plot.call("is_ripe")), "100s of a 240s crop is not ripe")
	assert_between(float(plot.call("growth")), 0.3, 0.5, "and should read as about 40% grown")
	plot.call("tick", 200.0)
	assert_true(bool(plot.call("is_ripe")))
	assert_almost_eq(float(plot.call("growth")), 1.0)


func test_picking_an_unripe_plot_is_refused() -> void:
	var plot := _station(BERRY_PLOT)
	var bag := _bag({"berries": 1})
	plot.call("plant", bag)
	assert_false(bool(plot.call("pick", bag)))
	assert_eq(str(plot.call("last_refusal")), "not_ripe")


func test_picking_a_ripe_plot_pays_more_than_it_cost_and_replants_itself() -> void:
	# No watering chores (§21), so harvesting returns the plot to GROWING rather
	# than to bare soil. And a plot must yield more than the seed, or it is a
	# machine for turning berries into berries.
	var plot := _station(BERRY_PLOT)
	var bag := _bag({"berries": 1})
	plot.call("plant", bag)
	plot.call("tick", 500.0)
	assert_true(bool(plot.call("pick", bag)))
	assert_eq(bag.count_of("berries"), 6, "a crop should be worth the wait")
	assert_eq(str(plot.call("state")), "growing", "a picked plot keeps growing")
	assert_almost_eq(float(plot.call("growth")), 0.0)


func test_picking_into_a_full_bag_does_not_lose_the_crop() -> void:
	var plot := _station(BERRY_PLOT)
	plot.call("plant", _bag({"berries": 1}))
	plot.call("tick", 500.0)
	# A one-slot inventory with a berry stack already at its limit.
	var tiny: RefCounted = INVENTORY.new(1)
	tiny.add("berries", DEFS.stack_limit("berries"))
	assert_false(bool(plot.call("pick", tiny)))
	assert_eq(str(plot.call("last_refusal")), "no_room")
	assert_true(bool(plot.call("is_ripe")), "the crop must still be on the plant")


func test_a_half_grown_plot_comes_back_half_grown() -> void:
	# The requirement in one test: "A half-grown berry plot must come back
	# half-grown."
	var before := _station(BERRY_PLOT)
	before.call("plant", _bag({"berries": 1}))
	before.call("tick", 120.0)
	var half := float(before.call("growth"))
	assert_between(half, 0.4, 0.6, "120s of a 240s crop is half grown")

	var record := STATION.write_record({"piece": BERRY_PLOT}, before)
	var after := _station(BERRY_PLOT)
	assert_false(bool(after.call("is_planted")), "a fresh plot is bare")
	after.call("load_state", STATION.read_record(record))
	assert_eq(str(after.call("state")), "growing")
	assert_almost_eq(float(after.call("growth")), half, 0.01,
		"a reloaded plot must come back exactly as grown as it was")


func test_a_ripe_plot_comes_back_ripe_and_a_bare_one_saves_nothing() -> void:
	var ripe := _station(BERRY_PLOT)
	ripe.call("plant", _bag({"berries": 1}))
	ripe.call("tick", 500.0)
	var after := _station(BERRY_PLOT)
	after.call("load_state", STATION.read_record(STATION.write_record({}, ripe)))
	assert_true(bool(after.call("is_ripe")))

	# A plot nobody planted has nothing to say, so its record must stay the shape
	# a bare piece's record has always been.
	assert_false(STATION.write_record({"piece": BERRY_PLOT}, _station(BERRY_PLOT)).has(STATION.KEY))


func test_a_plot_needs_no_water_and_no_tending() -> void:
	# §21 says so in as many words: "No watering chores." Every one of these is a
	# chore looking for a system to live in, and a berry plot is exactly the kind
	# of thing that grows them.
	var plot := _station(BERRY_PLOT)
	for verb: String in ["water", "fertilise", "fertilize", "weed", "till", "hydrate", "soil"]:
		assert_false(plot.has_method(verb), "a berry plot has a '%s' chore" % verb)
