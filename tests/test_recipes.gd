extends "res://tests/test_case.gd"

## R2.4's crafting arithmetic: what a recipe costs, whether it can be
## afforded, and what actually happens to the satchel when it is crafted.
##
## Runs against the REAL data/recipes/recipes.json, the same way
## test_inventory.gd runs against the real items.json — a recipe deleted or
## renamed in the data file fails here rather than silently doing nothing at
## the campfire.
##
## `GAME_STATE` is instantiated directly rather than through the autoload:
## `_ready()` mounts the pause menu scene and touches the live tree, neither
## of which a pure-logic test wants. `items`/`inventory` are wired by hand
## instead, which is enough — `craft()`/`can_craft()`/`recipe_cost_for()`
## only ever read those two, never `_menu` or the scene tree.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const GAME_STATE := preload("res://autoload/game_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

## OF30. The one recipe Tam the blacksmith has to teach before it can be made,
## and the flag his second conversation writes. Named here rather than typed
## into six assertions, so renaming either in the data file fails in one place.
const TAUGHT_RECIPE := "orb_basic"
const TAUGHT_FLAG := "recipe_orb_basic"

var db: RefCounted = null
var bag: RefCounted = null
var progression: RefCounted = null
var state: Node = null


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)
	# OF30: the flag store is wired by hand for the same reason `items` and
	# `inventory` are — `recipe_known()` reads it, and a bare state with no
	# store treats every gated recipe as still locked. Most cases below are
	# about the arithmetic rather than the gate, so the gate is opened here and
	# closed again by the two tests that are actually about it.
	progression = PROGRESSION_STATE.new()
	progression.set_flag(TAUGHT_FLAG)
	state = GAME_STATE.new()
	state.items = db
	state.inventory = bag
	state.progression = progression


func after_each() -> void:
	if state != null:
		state.free()


func test_the_two_base_recipes_are_defined() -> void:
	for id in ["orb_basic", "potion_small"]:
		var recipe: Dictionary = db.recipe(id)
		assert_false(recipe.is_empty(), "recipes.json is missing '%s'" % id)
		assert_true(recipe.has("cost"), "'%s' names no cost" % id)
		assert_true(recipe.has("output"), "'%s' names no output" % id)


func test_recipes_only_use_baseline_materials() -> void:
	# GAME_DESIGN.md 15 / MEADOWS_PROGRESSION_SPEC.md 10: wood, stone, fiber
	# and berries, nothing else, for the base tier.
	const ALLOWED := ["wood", "stone", "fiber", "berries"]
	for id in db.recipe_ids():
		var recipe: Dictionary = db.recipe(str(id))
		for requirement in (recipe.get("cost", []) as Array):
			var ingredient := str((requirement as Dictionary).get("id", ""))
			assert_true(ALLOWED.has(ingredient),
				"'%s' costs '%s', which is not a baseline material" % [id, ingredient])


func test_recipe_output_is_a_real_item() -> void:
	for id in db.recipe_ids():
		var output: Dictionary = db.recipe(str(id)).get("output", {})
		var output_id := str(output.get("id", ""))
		assert_true(db.has(output_id), "'%s' produces unknown item '%s'" % [id, output_id])
		assert_true(int(output.get("n", 0)) > 0, "'%s' produces zero or fewer" % id)


func test_recipe_cost_for_matches_the_data_file() -> void:
	var cost: Array = state.recipe_cost_for("orb_basic")
	assert_false(cost.is_empty(), "orb_basic should cost something")
	assert_eq(cost, db.recipe("orb_basic").get("cost", []))


func test_recipe_cost_for_unknown_recipe_is_empty() -> void:
	assert_eq(state.recipe_cost_for("not_a_real_recipe"), [])


func test_cannot_craft_with_an_empty_satchel() -> void:
	assert_false(state.can_craft("orb_basic"))
	assert_false(state.can_craft("potion_small"))


func test_can_craft_once_every_ingredient_is_in_hand() -> void:
	for requirement in state.recipe_cost_for("orb_basic"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.can_craft("orb_basic"))


func test_can_craft_is_false_short_of_even_one_ingredient() -> void:
	var cost: Array = state.recipe_cost_for("orb_basic")
	for i in cost.size():
		var requirement := cost[i] as Dictionary
		var short: int = int(requirement.get("n", 0)) - 1
		if short > 0:
			bag.add(str(requirement.get("id", "")), short)
	assert_false(state.can_craft("orb_basic"), "one ingredient short must refuse the whole craft")


func test_can_craft_refuses_an_unknown_recipe_however_rich_you_are() -> void:
	bag.add("wood", 999)
	bag.add("stone", 999)
	bag.add("fiber", 999)
	bag.add("berries", 999)
	assert_false(state.can_craft("legendary_orb"))


func test_craft_spends_the_cost_and_grants_the_output() -> void:
	for requirement in state.recipe_cost_for("potion_small"):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_eq(bag.count("potion_small"), 0)

	assert_true(state.craft("potion_small"))
	assert_eq(bag.count("potion_small"), 1)
	for requirement in db.recipe("potion_small").get("cost", []):
		var entry := requirement as Dictionary
		assert_eq(bag.count(str(entry.get("id", ""))), 0,
			"'%s' should have been fully spent" % str(entry.get("id", "")))


func test_craft_fails_all_or_nothing_when_short() -> void:
	# One wood short of orb_basic's cost. A craft that ate the fiber anyway and
	# then refused would be a satchel silently losing materials for nothing.
	var cost: Array = state.recipe_cost_for("orb_basic")
	for requirement in cost:
		var entry := requirement as Dictionary
		var id := str(entry.get("id", ""))
		var need := int(entry.get("n", 0))
		bag.add(id, need - 1 if id == str((cost[0] as Dictionary).get("id", "")) else need)

	var before := {}
	for requirement in cost:
		var id: String = str((requirement as Dictionary).get("id", ""))
		before[id] = bag.count(id)

	assert_false(state.craft("orb_basic"))
	for requirement in cost:
		var id: String = str((requirement as Dictionary).get("id", ""))
		assert_eq(bag.count(id), int(before[id]), "'%s' must be untouched by a failed craft" % id)


func test_craft_never_touches_free_build() -> void:
	# docs/decisions/D16 scopes free_build to BUILDING costs. Crafting has its
	# own materials loop and must not become a second, undocumented cheat.
	state.free_build = true
	assert_false(state.can_craft("orb_basic"), "free_build must not waive crafting costs")


## --- OF30: what Tam has to teach you before you can make it ------------------

## Owner-reported: "Then he'll give you the recipe for basic orbs." The gate is
## a plain progression flag named by the recipe itself (recipes.json's
## `unlocked_by`); see docs/decisions/D43.
func test_the_orb_recipe_names_the_flag_that_unlocks_it() -> void:
	assert_eq(db.recipe_unlock_flag(TAUGHT_RECIPE), TAUGHT_FLAG,
		"recipes.json's '%s' should wait on '%s'" % [TAUGHT_RECIPE, TAUGHT_FLAG])


func test_a_recipe_with_no_unlock_flag_is_known_from_the_first_minute() -> void:
	assert_eq(db.recipe_unlock_flag("potion_small"), "",
		"potion_small is nobody's to hand over and must not be gated")
	progression.set_flag(TAUGHT_FLAG, false)
	assert_true(state.recipe_known("potion_small"))


func test_the_orb_recipe_is_unknown_until_the_flag_is_set() -> void:
	progression.set_flag(TAUGHT_FLAG, false)
	assert_false(state.recipe_known(TAUGHT_RECIPE))
	progression.set_flag(TAUGHT_FLAG)
	assert_true(state.recipe_known(TAUGHT_RECIPE))


## The gate is a real refusal, not just a hidden row. A full satchel and an
## untaught recipe still make nothing.
func test_an_untaught_recipe_refuses_however_full_the_satchel_is() -> void:
	progression.set_flag(TAUGHT_FLAG, false)
	for requirement in db.recipe(TAUGHT_RECIPE).get("cost", []):
		bag.add(str((requirement as Dictionary).get("id", "")), 99)
	assert_false(state.can_craft(TAUGHT_RECIPE), "an untaught recipe must refuse")
	assert_false(state.craft(TAUGHT_RECIPE), "an untaught recipe must craft nothing")
	assert_eq(bag.count("orb_basic"), 0)


## And once taught, it crafts — the other half of OF30's "the orb recipe
## unlocks and crafts" done-when.
func test_once_taught_the_orb_recipe_crafts() -> void:
	for requirement in state.recipe_cost_for(TAUGHT_RECIPE):
		bag.add(str(requirement.get("id", "")), int(requirement.get("n", 0)))
	assert_true(state.can_craft(TAUGHT_RECIPE))
	assert_true(state.craft(TAUGHT_RECIPE))
	assert_eq(bag.count("orb_basic"), 1)


func test_the_known_list_grows_by_exactly_the_taught_recipe() -> void:
	progression.set_flag(TAUGHT_FLAG, false)
	var locked: Array = state.known_recipe_ids()
	assert_false(locked.has(TAUGHT_RECIPE), "the orb recipe should not be listed before it is taught")
	assert_true(locked.has("potion_small"), "the craft screen must never be empty")

	progression.set_flag(TAUGHT_FLAG)
	var unlocked: Array = state.known_recipe_ids()
	assert_true(unlocked.has(TAUGHT_RECIPE))
	assert_eq(unlocked.size(), locked.size() + 1, "one flag should unlock exactly one recipe")


## A state with no flag store at all cannot answer "have you been taught this",
## and must not guess yes -- see recipe_known()'s own comment.
func test_a_state_with_no_flag_store_treats_a_gated_recipe_as_locked() -> void:
	state.progression = null
	assert_false(state.recipe_known(TAUGHT_RECIPE))
	assert_true(state.recipe_known("potion_small"), "an ungated recipe needs no store to be known")


func test_every_unlock_flag_named_by_a_recipe_is_actually_written_by_something() -> void:
	# A recipe gated behind a flag nothing ever sets is a recipe that is
	# unreachable forever, and it fails silently: the craft screen simply never
	# grows the row. Checked against the dialogue table, which is where every
	# `flag:` effect in the game lives today.
	const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
	var written: Array[String] = []
	for id: String in RUNNER.table():
		var conversation: Dictionary = RUNNER.table()[id]
		for raw: Variant in conversation.get("lines", []) as Array:
			if not raw is Dictionary:
				continue
			var line: Dictionary = raw
			var effects: Array = (line.get("effects", []) as Array).duplicate()
			if str(line.get("effect", "")) != "":
				effects.append(str(line["effect"]))
			for effect: Variant in effects:
				var parts: Array = RUNNER.parse_effect(str(effect))
				if str(parts[0]) == "flag":
					written.append(str(parts[1]))

	for id in db.recipe_ids():
		var flag: String = str(db.recipe_unlock_flag(str(id)))
		if flag == "":
			continue
		assert_true(written.has(flag),
			"recipe '%s' waits on flag '%s', which no conversation ever sets" % [id, flag])
