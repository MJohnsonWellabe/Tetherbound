extends "res://tests/test_case.gd"

## F40#9 authored NPC posts (GPU High 5.32 -> 6.48, G-newapproach-post-setting):
## cobble-capped warmer discs, a structure behind each of Tavi, Sora and Maela,
## a stronger shadow-casting key light, and Sora moved clear of the wall. The
## post-focus camera is not part of this landing.

const VERDICT := "5.32 -> 6.48"


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _scenes(rows: Array) -> Array[String]:
	var names: Array[String] = []
	for row: Dictionary in rows:
		names.append(str(row.scene).get_file().get_basename())
	return names


func test_post_dais_ships_the_judged_cap_and_stone() -> void:
	var dais: Dictionary = _json("res://data/config/cloudreach_npc_runtime.json").post_dais
	assert_true(dais.get("enabled") == true, "post_dais stays ON")
	assert_eq(str(dais.colour), "#8d8877", "the judged warmer stone")
	assert_eq(str(dais.cap_scene), "res://assets/environment/stylized_nature/RockPath_Round_Wide.gltf", "the judged paving cap")
	assert_true(ResourceLoader.exists(str(dais.cap_scene)), "the cap is an installed piece")
	assert_true(is_equal_approx(float(dais.cap_overhang), 1.15), "the judged cap overhang")
	assert_eq(str(dais.cap_tint), "#8f8a7a", "the judged cap tint")
	assert_true(str(dais.get("_why_on_setting", "")).contains(VERDICT), "post_dais records the GPU verdict")


func test_each_post_has_its_judged_structure() -> void:
	var props: Dictionary = _json("res://data/config/cloudreach_npc_runtime.json").post_role_props
	assert_true(props.get("enabled") == true, "post_role_props stays ON")
	assert_true(str(props.get("_why_on_setting", "")).contains(VERDICT), "post_role_props records the GPU verdict")
	var expected := {
		"young_trainer_tavi": ["Workbench", "Peg_Rack", "Dummy", "WeaponStand", "Shield_Wooden"],
		"naturalist_sora": ["Bookcase_2", "Table_Large", "BookGroup_Medium_1", "BookStand", "Bag", "Crate_Wooden"],
		"keeper_maela": ["Table_Large", "Cage_Small", "Shelf_Simple", "Barrel", "Cage_Small", "Rope_2", "Torch_Metal"],
	}
	for post: String in expected:
		var rows: Array = props.posts.get(post, [])
		var want: Array[String] = []
		want.assign(expected[post])
		assert_eq(_scenes(rows), want, "%s stands in front of its judged props" % post)
		for row: Dictionary in rows:
			assert_true(ResourceLoader.exists(str(row.scene)), "%s is installed" % str(row.scene))
			# The set's stall and cart have dark red canopies (Team Tether's colour).
			assert_false(str(row.scene).contains("Stall"), "no red-canopied stall at %s" % post)


func test_post_key_light_ships_the_judged_values() -> void:
	var light: Dictionary = _json("res://data/config/cloudreach_npc_runtime.json").post_readability.fill_light
	assert_true(light.get("enabled") == true, "the post light stays ON")
	assert_true(is_equal_approx(float(light.energy), 1.3), "the judged energy")
	assert_true(is_equal_approx(float(light.range_m), 6.0), "the judged range")
	assert_eq(light.offset, [0.9, 2.3, 1.5], "the judged raised, side offset")
	assert_true(light.get("shadow") == true, "the key light casts the grounding shadow")
	assert_true(str(light.get("_why_on_setting", "")).contains(VERDICT), "the light records the GPU verdict")


func test_sora_stands_clear_of_the_wall() -> void:
	var physical: Dictionary = _json("res://data/config/cloudreach_physical_runtime.json")
	assert_eq(physical.npc_position_overrides.get("naturalist_sora"), [1100.0, 1050.0, 2953.5], "Sora's judged position")
	assert_true(str(physical.get("_why_on_npc_position_override_naturalist_sora", "")).contains(VERDICT),
		"Sora's move records the GPU verdict")
	for key: String in physical.npc_position_overrides:
		assert_false(key.begins_with("_"), "the override map holds only NPC ids")


func test_post_focus_camera_is_not_part_of_this_landing() -> void:
	var camera: Dictionary = _json("res://data/config/camera.json")
	assert_false((camera.get("post_focus", {}) as Dictionary).get("enabled") == true,
		"the post-focus camera stays off until the owner decides")
