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
