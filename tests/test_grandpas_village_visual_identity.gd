extends "res://tests/test_case.gd"

const HARVEST_PATH := "res://data/config/bands/band1_lower_meadows/harvest.json"
const PRESENTATION_PATH := "res://scripts/world/village_well_presentation.gd"
const VILLAGE_PATH := "res://scripts/world/village.gd"
const GRANDPA_HOUSE_PATH := "res://scripts/world/grandpa_house.gd"
const CAPTURE_PATH := "res://tools/capture_grandpas_village_identity.gd"
const VILLAGE_BERRY_ORDERS := [10, 11, 1031, 1032, 1033, 1036]


func _source(path: String) -> String:
	return FileAccess.get_file_as_string(path)


func _harvest_nodes() -> Array:
	var parsed: Variant = JSON.parse_string(_source(HARVEST_PATH))
	assert_true(parsed is Dictionary, "band-one harvest config parses")
	return (parsed as Dictionary).get("nodes", []) if parsed is Dictionary else []


func _node(order: int) -> Dictionary:
	for raw: Variant in _harvest_nodes():
		if raw is Dictionary and int((raw as Dictionary).get("order", -1)) == order:
			return raw as Dictionary
	return {}


func test_village_berries_keep_content_without_creature_sized_silhouettes() -> void:
	for order: int in VILLAGE_BERRY_ORDERS:
		var berry := _node(order)
		assert_false(berry.is_empty(), "village berry %d remains authored" % order)
		assert_eq(str(berry.get("item", "")), "berries", "order %d remains a berry" % order)
		assert_eq(int(berry.get("amount", 0)), 3, "order %d keeps its yield" % order)
		assert_eq(str(berry.get("model", "")),
			"res://assets/environment/stylized_nature/Bush_Common_Flowers.gltf",
			"order %d keeps the installed berry model" % order)
		assert_between(float(berry.get("model_scale", 0.0)), 0.42, 0.56,
			"order %d stays a readable bush below creature-sized scale" % order)


func test_square_axis_deadwood_keeps_yield_without_blocking_the_well() -> void:
	var deadwood := _node(3)
	assert_false(deadwood.is_empty(), "the demonstrated square-axis deadwood remains authored")
	assert_eq(str(deadwood.get("item", "")), "wood", "the node remains opening wood")
	assert_eq(int(deadwood.get("amount", 0)), 4, "the opening wood yield is preserved")
	assert_eq(deadwood.get("at", []), [-8.0, 8.0], "the interactable position does not move")
	assert_between(float(deadwood.get("model_scale", 0.0)), 0.10, 0.13,
		"the existing visual-scale seam removes the black foreground obstruction")


func test_well_light_is_installed_bounded_and_visual_only() -> void:
	assert_true(ResourceLoader.exists("res://assets/props/quaternius_fantasy/Lantern_Wall.gltf"),
		"the well uses the installed village prop family")
	var script := load(PRESENTATION_PATH) as GDScript
	assert_true(script != null, "the well presentation parses")
	if script == null:
		return
	var presentation := script.new() as Node3D
	presentation.call("build")
	var stats := presentation.call("stats") as Dictionary
	assert_eq(int(stats.get("curb_stone_count", 0)), 12,
		"the village has one low well curb, not crossed shrine-scale platforms")
	assert_eq(int(stats.get("lantern_count", 0)), 2,
		"both existing well posts carry a readable practical fixture")
	assert_eq(int(stats.get("light_count", 0)), 3,
		"one well pool and two practical path pools carry the civic night layer")
	assert_true(float(stats.get("light_range_m", 99.0)) <= 9.0,
		"the warm pool remains local to the square")
	assert_eq(int(stats.get("path_light_count", 0)), 2,
		"the well approach is framed without a repeated lamp avenue")
	assert_eq(str(stats.get("sign_text", "")), "GRANDPA'S VILLAGE",
		"the civic structure carries the location name rather than relying on the inn")
	var source := _source(PRESENTATION_PATH)
	for forbidden: String in ["StaticBody3D.new()", "CollisionShape3D.new()", "Area3D.new()"]:
		assert_false(source.contains(forbidden), "well presentation remains visual-only")
	presentation.free()
	var prefabs := JSON.parse_string(_source("res://data/config/building_prefabs.json")) as Dictionary
	var well := ((prefabs.get("prefabs", {}) as Dictionary).get("well", {}) as Dictionary)
	for raw: Variant in well.get("modules", []):
		assert_ne(str((raw as Dictionary).get("module", "")), "Stairs_Exterior_Platform",
			"the four overlapping shrine-scale stair bodies must not return")


func test_production_village_mounts_the_well_presentation() -> void:
	assert_true(load(VILLAGE_PATH) is Script, "the production village script parses")
	var source := _source(VILLAGE_PATH)
	assert_true(source.contains("VILLAGE_WELL_PRESENTATION"),
		"production village preloads the civic well layer")
	assert_true(source.contains('prefab_name == "well"'),
		"the civic layer is attached only to the existing authored well")
	assert_true(source.contains("identity.call(\"build\")"),
		"the production placement invokes the visual layer")
	var house_source := _source(GRANDPA_HOUSE_PATH)
	assert_true(house_source.contains("GRANDPA'S HOME") \
		and house_source.contains("GrandpasHomeMarker"),
		"Grandpa's actual opening house has an unmistakable exterior focal cue")


func test_capture_harness_has_square_and_street_views_at_both_times() -> void:
	assert_true(load(CAPTURE_PATH) is Script, "the dedicated capture harness parses")
	var source := _source(CAPTURE_PATH)
	assert_true(source.contains('"01-civic-square-southeast"') and source.contains('"02-well-path-south"') \
		and source.contains('"03-grandpas-home-square"'),
		"R3 evidence covers both civic axes and Grandpa's actual home")
	assert_false(source.contains('Vector2(-9.0, -18.0)'),
		"the accepted inn no longer monopolizes the R2 proof composition")
	assert_true(source.contains('GRANDPAS-VILLAGE-R3'), "R3 evidence writes to a fresh directory")
	assert_true(source.contains('for time_name: String in ["day", "night"]'),
		"each composition is captured at authored day and night")
	assert_true(source.contains('look.call("apply_time", time_name)'),
		"the requested production clock is actually applied")
	assert_true(source.contains('^"Water/SubmersionOverlay"'),
		"independent water tint cannot contaminate the village evidence")
