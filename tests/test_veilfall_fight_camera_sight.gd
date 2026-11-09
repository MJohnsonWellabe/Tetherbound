extends "res://tests/test_case.gd"

## F39#21 camera (LANE-MESHY, 9 Nov 2026): the Heart Chamber asks the fight
## camera to keep its sight line to both fighters clear, including the
## camera-only crystal box, so the lens never stands behind the crystal.

const VEILFALL_CONFIG := "res://data/config/water_veilfall.json"


func _rules() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(VEILFALL_CONFIG))


func test_heart_chamber_turns_on_fight_camera_sight() -> void:
	var rules := _rules()
	assert_true(bool(rules.get("fight_camera_world_sight", false)), "the chamber asks for clear sight lines")
	assert_true(not str(rules.get("_why_fight_camera_world_sight", "")).is_empty(), "the flag records why")


func test_the_crystal_carries_a_camera_only_box_the_sight_rays_can_meet() -> void:
	var rules := _rules()
	var crystal: Array = rules.get("crystal_position", [])
	var covered := false
	for box: Dictionary in rules.get("camera_occluders", []):
		var at: Array = box.get("at", [])
		if at.size() == 3 and crystal.size() == 3 and absf(float(at[0]) - float(crystal[0])) < 0.5 \
				and absf(float(at[2]) - float(crystal[2])) < 0.5:
			covered = true
	assert_true(covered, "the containment crystal has a camera-only box")


func test_sight_mask_includes_the_camera_only_layer() -> void:
	var layer := int(preload("res://scripts/player/camera_rig.gd").OCCLUSION_ONLY_LAYER)
	assert_true((0xFFFFFFFF & layer) != 0, "the room sight mask meets camera-only boxes")
	assert_true((0x7FFFFFFF & layer) == 0, "the default sight mask still skips them")
