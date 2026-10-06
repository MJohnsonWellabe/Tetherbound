extends "res://tests/test_case.gd"
const WATER := preload("res://tests/helpers/water_earned_swimmer_segment.gd")
const MEADOWS := preload("res://tests/helpers/earned_roster_replacement_segment.gd")

func test_realm_override_keeps_meadows_default_and_real_swimmer_catalogue() -> void:
	assert_eq(MEADOWS.new()._replacement_realm(), "meadows")
	assert_eq(WATER.new()._replacement_realm(), "water")
	assert_false(WATER.compatible_swimmer("brooktail"))
	for id in ["water_aquaryn", "water_mosshell", "water_sirenseal", "water_riverdrake", "water_cannonback"]:
		assert_true(WATER.compatible_swimmer(id), id)
	assert_false(WATER.compatible_swimmer("water_cragclaw"))

func test_current_saddle_recipe_preserves_paid_cost_and_personal_gates() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_crafting.json"))
	var recipe: Dictionary = data.recipes[WATER.SADDLE_RECIPE]
	assert_eq(recipe.cost, [{"id":"reed_fiber", "n":8.0}, {"id":"driftwood", "n":6.0}, {"id":"reef_stone", "n":4.0}])
	assert_eq(recipe.output, {"id":"swim_saddle", "n":1.0})
	assert_true(recipe.requires_personal_flags.has("water_swim_stone_earned"))
	assert_true(recipe.requires_personal_flags.has("water_swim_saddle_recipe_learned"))
	assert_eq(data.item_registration_proposals.reef_stone.gathered_with, "pickaxe")

func test_swim_saddle_camp_panel_preserves_unlock_cost_and_workbench_route() -> void:
	# Actual production catalogue and camp craft callback, without a world or
	# native input fixture. The unchanged Alpha smoke owns the earned chain.
	var game := preload("res://autoload/game_state.gd").new()
	game.items = preload("res://autoload/item_db.gd").new()
	var panel := preload("res://scripts/ui/craft_panel.gd").new()
	panel.game = game
	panel._status = Label.new()
	panel.add_child(panel._status)
	var recipe_id: String = WATER.SADDLE_RECIPE
	var recipe: Dictionary = game.items.recipe(recipe_id)
	for cost: Dictionary in recipe.cost:
		game.inventory.add(str(cost.id), int(cost.n))
	assert_false(panel._known_ids().has(recipe_id), "personal reward and lesson are required")
	panel._craft(recipe_id)
	assert_eq(game.inventory.count("swim_saddle"), 0)
	game.local.flags.set_flag("water_swim_saddle_recipe_learned", true)
	assert_false(panel._known_ids().has(recipe_id), "lesson alone cannot bypass the Swim Stone")
	panel._craft(recipe_id)
	for cost: Dictionary in recipe.cost:
		assert_eq(game.inventory.count(str(cost.id)), int(cost.n), "refused craft spends nothing")
	game.local.flags.set_flag("water_swim_stone_earned", true)
	assert_true(panel._known_ids().has(recipe_id), "earned travel saddle appears at campfire")
	for home_only: String in ["saddle", "saddle_frame"]:
		assert_false(panel._known_ids().has(home_only), "other saddles remain homestead-only")
	var workbench := Node3D.new()
	workbench.set_meta("building_id", "workbench")
	panel._station = workbench
	assert_true(panel._known_ids().has(recipe_id), "same saddle appears at actual Workbench route")
	workbench.set_meta("building_id", "kitchen")
	assert_false(panel._known_ids().has(recipe_id), "Kitchen is not a saddle station")
	panel._station = null
	var camp_rules := preload("res://scripts/build/forward_camp_rules.gd")
	assert_true(camp_rules.recipe(recipe_id, recipe, "workbench").get("ok") == true)
	assert_false(camp_rules.recipe(recipe_id, recipe, "cookpot").get("ok") == true)
	panel._craft(recipe_id)
	assert_eq(game.inventory.count("swim_saddle"), 1, "production callback grants one paid saddle")
	for cost: Dictionary in recipe.cost:
		assert_eq(game.inventory.count(str(cost.id)), 0, "production callback spends authored cost")
	panel._craft(recipe_id)
	assert_eq(game.inventory.count("swim_saddle"), 1, "missing ingredients cannot grant another saddle")
	workbench.free()
	panel.free()
	game.free()
