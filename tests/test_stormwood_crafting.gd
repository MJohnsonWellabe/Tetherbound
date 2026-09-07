extends "res://tests/test_case.gd"

## Production integration coverage: this goes through ItemDB and GameState's
## normal inventory transaction rather than inspecting the Stormwood JSON alone.

const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const GAME_STATE := preload("res://autoload/game_state.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")

const STORMWOOD_RECIPES := [
	"insulated_helm", "insulated_vest", "rod_mast", "voltcap_stew",
	"glowmoss_tonic", "stormglass_orb_socket", "stormglass_lining", "thunderwood_frame",
]

var db: RefCounted
var bag: RefCounted
var progression: RefCounted
var state: Node


func before_each() -> void:
	db = ITEM_DB.new()
	bag = INVENTORY.new(db)
	progression = PROGRESSION_STATE.new()
	state = GAME_STATE.new()
	state.items = db
	state.inventory = bag
	state.progression = progression


func after_each() -> void:
	if state != null:
		state.free()


func test_item_db_merges_the_eight_live_stormwood_inventory_recipes() -> void:
	for id: String in STORMWOOD_RECIPES:
		var recipe: Dictionary = db.recipe(id)
		assert_false(recipe.is_empty(), "ItemDB did not load " + id)
		assert_eq(str(recipe.get("realm_id", "")), "stormwood")
		assert_true(db.has(str((recipe.get("output", {}) as Dictionary).get("id", ""))), id + " output is not an ItemDB item")


func test_locked_stormwood_recipe_refuses_even_with_its_full_cost() -> void:
	const RECIPE := "insulated_helm"
	assert_eq(db.recipe_unlock_flag(RECIPE), "stormwood:rodline_linked")
	for requirement: Dictionary in state.recipe_cost_for(RECIPE):
		bag.add(str(requirement.id), int(requirement.n))
	assert_false(state.recipe_known(RECIPE))
	assert_false(state.can_craft(RECIPE))
	assert_false(state.craft(RECIPE))
	assert_eq(bag.count("insulated_helm"), 0)
	for requirement: Dictionary in db.recipe(RECIPE).cost:
		assert_eq(bag.count(str(requirement.id)), int(requirement.n), "locked craft spent " + str(requirement.id))


func test_unlocked_recipe_spends_every_ingredient_and_grants_exactly_one_output() -> void:
	const RECIPE := "insulated_helm"
	progression.set_flag("stormwood:rodline_linked")
	for requirement: Dictionary in state.recipe_cost_for(RECIPE):
		bag.add(str(requirement.id), int(requirement.n))
	assert_true(state.can_craft(RECIPE))
	assert_true(state.craft(RECIPE))
	assert_eq(bag.count("insulated_helm"), 1)
	for requirement: Dictionary in db.recipe(RECIPE).cost:
		assert_eq(bag.count(str(requirement.id)), 0, "crafted helm retained " + str(requirement.id))


func test_stew_and_tonic_remain_distinct_consumables() -> void:
	progression.set_flag("stormwood:chapter_started")
	for id: String in ["voltcap_stew", "glowmoss_tonic"]:
		for requirement: Dictionary in state.recipe_cost_for(id):
			bag.add(str(requirement.id), int(requirement.n))
		assert_true(state.craft(id), id + " should craft through GameState")
		assert_eq(bag.count(id), 1)
	assert_eq(db.kind("voltcap_stew"), "food")
	assert_eq(db.kind("glowmoss_tonic"), "consumable")
	assert_true(int(db.definition("voltcap_stew").get("satiety", 0)) > 0)
	assert_true(int(db.definition("glowmoss_tonic").get("heal", 0)) > 0)
	assert_false(bool(db.definition("glowmoss_tonic").get("revive", false)))
