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

var db: RefCounted = null
var bag: RefCounted = null
var state: Node = null


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)
	state = GAME_STATE.new()
	state.items = db
	state.inventory = bag


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
