extends "res://tests/test_case.gd"
const VISIT := preload("res://tools/earned_saves/master_visit.gd")

class ChestPrompt extends Node3D:
	signal activated

func test_chest_geometry_is_not_an_interaction_prompt() -> void:
	var site := Node3D.new()
	var chest := Node3D.new()
	chest.name = "RecipeChest"
	site.add_child(chest)
	chest.add_child(Node3D.new())
	assert_eq(VISIT.chest_prompt(site), null)
	var prompt := ChestPrompt.new()
	chest.add_child(prompt)
	assert_eq(VISIT.chest_prompt(site), prompt)
	site.free()
	assert_eq(VISIT.chest_prompt(null), null)

func test_rebuilt_site_supplies_new_prompt() -> void:
	var site := Node3D.new()
	var chest := Node3D.new()
	chest.name = "RecipeChest"
	site.add_child(chest)
	var old_prompt := ChestPrompt.new()
	chest.add_child(old_prompt)
	assert_eq(VISIT.chest_prompt(site), old_prompt)
	old_prompt.free()
	var new_prompt := ChestPrompt.new()
	chest.add_child(new_prompt)
	assert_eq(VISIT.chest_prompt(site), new_prompt)
	site.free()
