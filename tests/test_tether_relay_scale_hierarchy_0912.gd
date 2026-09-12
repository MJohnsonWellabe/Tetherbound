extends "res://tests/test_case.gd"

const CONFIG_PATH := "res://data/config/tether_relay.json"
const SOURCE_PATH := "res://scripts/world/tether_relay.gd"
const HERO_PATH := "res://assets/environment/team_tether/relay_apparatus.glb"
const HALL_DIR := "res://assets/environment/team_tether/hall"
const PROP_DIR := "res://assets/props/quaternius_fantasy"


func _config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	assert_true(parsed is Dictionary, "relay redesign config remains valid JSON")
	return parsed as Dictionary if parsed is Dictionary else {}


func _asset_path(spec: Dictionary) -> String:
	var dir := str(spec.get("dir", PROP_DIR))
	var model := str(spec.get("model", ""))
	var glb := "%s/%s.glb" % [dir, model]
	return glb if ResourceLoader.exists(glb) else "%s/%s.gltf" % [dir, model]


func test_hero_is_primary_mass_without_stealing_console_clearance() -> void:
	var config := _config()
	var apparatus := config.get("apparatus", {}) as Dictionary
	assert_eq(str(apparatus.get("model", "")), HERO_PATH)
	assert_true(ResourceLoader.exists(HERO_PATH), "the approved board-14 hero remains installed")
	var height := float(apparatus.get("height", 0.0))
	assert_between(height, 5.6, 6.0,
		"relay hero must dominate an operator without overtaking the entrance hierarchy")

	var collision: Array = apparatus.get("collision_size", [])
	assert_eq(collision.size(), 3, "enlarged hero needs an explicit collision envelope")
	if collision.size() < 3:
		return
	assert_between(float(collision[0]), 5.2, 5.8)
	assert_almost_eq(float(collision[1]), height, 0.001)
	assert_between(float(collision[2]), 4.8, 5.5)
	var hero_at: Array = apparatus.get("at", [])
	var console := apparatus.get("console", {}) as Dictionary
	var console_at: Array = console.get("at", [])
	var console_size: Array = console.get("size", [])
	assert_eq(hero_at.size(), 2)
	assert_eq(console_at.size(), 2)
	assert_eq(console_size.size(), 3)
	if hero_at.size() == 2 and console_at.size() == 2 and console_size.size() == 3:
		# Apparatus yaw maps BoxShape local Z onto the site's S/gantry axis.
		var clear_s := absf(float(hero_at[0]) - float(console_at[0])) \
			- float(collision[2]) * 0.5 - float(console_size[2]) * 0.5
		assert_true(clear_s >= 1.0,
			"hero scale-up must leave a real gap to the unchanged console cabinet")

	var finish := apparatus.get("finish", {}) as Dictionary
	var tint := Color(str(finish.get("albedo_tint", "#000000")))
	assert_between(tint.get_luminance(), 0.55, 0.85,
		"finish should enrich the baked texture without crushing or bleaching it")
	assert_between(float(finish.get("roughness", 0.0)), 0.68, 0.78,
		"field machinery should remain matte, not read as a glossy collectible")
	assert_almost_eq(float(finish.get("metallic", -1.0)), 0.0, 0.001,
		"one baked material cannot plausibly metalize stone, cloth and glass together")
	var source := FileAccess.get_file_as_string(SOURCE_PATH)
	assert_true(source.contains("_apply_apparatus_finish(instance"),
		"configured finish is not applied to the installed hero")
	assert_true(source.contains("source.albedo_color * tint"),
		"finish must preserve the imported albedo texture through multiplication")
	assert_true(source.contains("apparatus.get(\"collision_size\""),
		"explicit clearance envelope is not consumed by the production builder")


func test_pad_supports_the_hero_with_an_industrial_scale_ladder() -> void:
	var config := _config()
	var props: Array = (config.get("deck_props", {}) as Dictionary).get("list", [])
	assert_eq(props.size(), 6,
		"pad service cluster includes the compact four-object service set plus its installed feed pipe and valve")
	var models: Dictionary = {}
	for raw: Variant in props:
		var spec := raw as Dictionary
		var model := str(spec.get("model", ""))
		models[model] = true
		assert_true(ResourceLoader.exists(_asset_path(spec)),
			"relay service composition names a missing installed asset: %s" % model)
	for expected: String in ["team_tether_boiler_chimney", "Crate_Metal", "Chain_Coil", "Bucket_Metal"]:
		assert_true(models.has(expected), "relay service hierarchy is missing %s" % expected)
	for rejected: String in ["Crate_Wooden", "Barrel", "Whetstone", "Axe_Bronze"]:
		assert_false(models.has(rejected), "generic village-scale pile returned to the hero pad")
	var boiler := props[0] as Dictionary
	assert_eq(str(boiler.get("dir", "")), HALL_DIR,
		"pressure vessel must reuse the installed Team Tether industrial family")
	assert_between(float(boiler.get("scale", 0.0)), 0.5, 0.65,
		"boiler is a subordinate roughly two-metre service module, not another oversized focal object")

	var lights: Dictionary = {}
	for raw: Variant in config.get("scene_lights", []):
		var light := raw as Dictionary
		lights[str(light.get("id", ""))] = light
	assert_true(lights.has("apparatus_key_teal"), "taller hero has no bounded night material read")
	assert_true(lights.has("boiler_service_warm"), "supporting pressure bank has no seating light")
	if lights.has("apparatus_key_teal"):
		var core := lights["apparatus_key_teal"] as Dictionary
		assert_true(bool(core.get("live_only", false)), "hero core must die with the relay")
		assert_between(float(core.get("range", 0.0)), 5.5, 7.0)
		assert_between(float(core.get("energy", 0.0)), 1.4, 2.1)
	if lights.has("boiler_service_warm"):
		var boiler_light := lights["boiler_service_warm"] as Dictionary
		assert_false(bool(boiler_light.get("live_only", true)),
			"physical boiler work light should survive the relay shutdown")
		assert_between(float(boiler_light.get("range", 0.0)), 4.0, 6.0)
		assert_between(float(boiler_light.get("energy", 0.0)), 1.2, 1.8)
