extends "res://tests/test_case.gd"

const DB := preload("res://autoload/item_db.gd")
const BAG := preload("res://autoload/inventory.gd")
const STATE := preload("res://autoload/game_state.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const PATCH := preload("res://scripts/world/cloudreach_resource_patch.gd")
const GATHER := preload("res://scripts/world/harvest_logic.gd")
const VITALS := preload("res://scripts/player/player_vitals.gd")
const RESOURCES := ["windworn_heartwood", "cliffglass_ore", "gale_fiber", "skyplume", "sunleaf", "cloudberry"]

var db: RefCounted
var bag: RefCounted
var state: Node


func before_each() -> void:
	db = DB.new()
	bag = BAG.new(db)
	state = STATE.new()
	state.items = db
	state.inventory = bag
	state.progression = PROGRESSION.new()


func after_each() -> void:
	state.free()


func test_every_resource_has_inventory_identity_stack_and_saved_slots() -> void:
	for id: String in RESOURCES:
		var definition: Dictionary = db.definition(id)
		assert_false(definition.is_empty(), id)
		assert_false(definition.has("weight"))
		assert_true(ResourceLoader.exists(str(definition.get("icon", ""))))
		var cap: int = db.stack_size(id)
		assert_eq(bag.add(id, cap + 1), 0)
		assert_eq(bag.count(id), cap + 1)
		assert_eq(int(bag.stack_at(bag.find_slot(id)).get("n", 0)), cap)
	var loaded: RefCounted = BAG.new(db)
	for i in bag.slot_count():
		# The real save format's ordinary inventory slot dictionaries survive JSON.
		if not bag.is_slot_empty(i):
			loaded.set_slot(i, JSON.parse_string(JSON.stringify(bag.stack_at(i))))
	for id: String in RESOURCES:
		assert_eq(loaded.count(id), bag.count(id))
	assert_eq(loaded.used_slots(), 12)


func test_cloudreach_tools_use_equipped_working_tool_not_hidden_ownership() -> void:
	for pair: Array in [["windworn_heartwood", "axe"], ["cliffglass_ore", "pickaxe"], ["gale_fiber", "knife"]]:
		bag.add(pair[1], 1)
		assert_eq(int(GATHER.gather(pair[0], 4, bag, db, "").amount), 0)
		assert_eq(int(GATHER.gather(pair[0], 4, bag, db, pair[1]).amount), 4)
		bag.damage_tool(bag.find_slot(pair[1]), 999)
		assert_eq(int(GATHER.gather(pair[0], 4, bag, db, pair[1]).amount), 0)
	assert_eq(int(GATHER.gather("cloudberry", 4, bag, db, "").amount), 4)
	assert_eq(int(GATHER.gather("sunleaf", 3, bag, db, "").amount), 3)


func test_every_recipe_is_arrival_gated_and_crafts_the_declared_useful_result() -> void:
	var recipes: Dictionary = PATCH.load_config(DB.CLOUDREACH_RECIPES_PATH).get("recipes", {})
	assert_eq(recipes.size(), 7)
	for id: String in recipes:
		bag = BAG.new(db)
		state.inventory = bag
		state.progression.set_flag("cloudreach_chapter_started", false)
		var recipe: Dictionary = db.recipe(id)
		assert_eq(str(recipe.get("realm_id", "")), "cloudreach")
		var tool: String = str(recipe.get("reinforce", {}).get("tool", ""))
		if not tool.is_empty():
			bag.add(tool, 1)
		for cost: Dictionary in recipe.get("cost", []):
			assert_false(db.definition(str(cost.id)).is_empty())
			bag.add(str(cost.id), int(cost.n))
		assert_false(state.recipe_known(id))
		assert_false(state.craft(id), "recipes cannot leak into the Meadows")
		state.progression.set_flag("cloudreach_chapter_started")
		assert_true(state.craft(id), id)
		for cost: Dictionary in recipe.get("cost", []):
			assert_eq(bag.count(str(cost.id)), 0, "cost consumed once")
		if not tool.is_empty():
			assert_eq(bag.count(tool), 1)
			assert_eq(bag.max_durability_at(bag.find_slot(tool)), db.max_durability(tool) + 35)
		else:
			var output: Dictionary = recipe.output
			assert_false(db.definition(str(output.id)).is_empty())
			assert_eq(bag.count(str(output.id)), int(output.n))


func test_full_satchel_recipe_refuses_without_spending_ingredients() -> void:
	state.progression.set_flag("cloudreach_chapter_started")
	bag.add("cloudberry", 30)
	bag.add("sunleaf", 30)
	while not bag.is_full():
		bag.add("axe", 1)
	assert_false(state.craft("cloudreach_trail_preserve"))
	assert_eq(bag.count("cloudberry"), 30)
	assert_eq(bag.count("sunleaf"), 30)


func test_full_satchel_can_craft_when_the_last_ingredient_stacks_free_room() -> void:
	state.progression.set_flag("cloudreach_chapter_started")
	bag.add("cloudberry", 3)
	bag.add("sunleaf", 1)
	while not bag.is_full():
		bag.add("axe", 1)
	assert_true(state.craft("cloudreach_trail_preserve"))
	assert_eq(bag.count("cloudberry"), 0)
	assert_eq(bag.count("sunleaf"), 0)
	assert_eq(bag.count("cloudreach_trail_preserve"), 1)


func test_preserve_has_real_temporary_stamina_and_shared_meal_effects() -> void:
	var vitals: RefCounted = VITALS.new()
	vitals.configure_satiety(PATCH.load_config("res://data/config/vitals.json"))
	vitals.satiety = 40.0
	var food: Dictionary = db.definition("cloudreach_trail_preserve")
	vitals.eat(float(food.satiety), food.buff)
	assert_eq(vitals.satiety, 75.0)
	assert_almost_eq(vitals.stamina_regen_scale(), 1.3, 0.001)
	assert_true(float(food.creature_food.nourishment) > 0.0)
	assert_true(float(food.creature_food.happiness) > 0.0)
	vitals.tick_satiety(241.0)
	assert_eq(vitals.active_buffs.size(), 0)
	assert_true(int(db.definition("potion_large").get("heal", 0)) >= 80)


func test_gather_sources_have_persistent_day_scoped_identity_and_existing_art() -> void:
	var seen := {}
	var progression: RefCounted = PROGRESSION.new()
	var nodes: Array[Dictionary] = PATCH.gatherable_nodes()
	assert_eq(nodes.size(), 12, "two skyplume encounter sources remain deferred")
	for node: Dictionary in nodes:
		assert_ne(str(node.resource_id), "skyplume")
		var spec: Dictionary = PATCH.harvest_spec(node, 4)
		assert_true(ResourceLoader.exists(str(spec.model)))
		assert_eq(str(spec.item), str(node.resource_id))
		assert_eq(int(spec.amount), int(node.amount))
		var flag: String = PATCH.depletion_flag(node, 4)
		assert_false(seen.has(flag))
		seen[flag] = true
		progression.set_flag(flag)
	var restored: RefCounted = PROGRESSION.new()
	restored.load_data(JSON.parse_string(JSON.stringify(progression.save_data())))
	for node: Dictionary in nodes:
		assert_true(restored.has(PATCH.depletion_flag(node, 4)))
		assert_false(restored.has(PATCH.depletion_flag(node, 5)), "next world day regrows")
		assert_eq(PATCH.depletion_flag(node, 4), PATCH.depletion_flag(node.duplicate(true), 4))
