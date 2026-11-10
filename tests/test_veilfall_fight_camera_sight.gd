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


## F39#21 Nerissa win (10 Nov): release snaps a long fight arm in at once in
## rooms that ask for camera sight, and never lengthens a short arm.
func test_release_snap_pulls_a_long_arm_in_and_never_out() -> void:
	var rig: SpringArm3D = preload("res://scripts/player/camera_rig.gd").new()
	rig.set("_distance", 5.2)
	rig.spring_length = 20.0
	rig.call("snap_arm_in")
	assert_true(absf(rig.spring_length - 5.2) < 0.001, "a long fight arm snaps to the exploration length")
	rig.spring_length = 3.0
	rig.call("snap_arm_in")
	assert_true(absf(rig.spring_length - 3.0) < 0.001, "a collapsed arm is never lengthened")
	rig.free()


func test_release_snap_is_scoped_to_rooms_that_ask_for_sight() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/combat/combat_manager.gd")
	var at := source.find("func _release_camera(")
	var body := source.substr(at, source.find("\nfunc ", at + 10) - at)
	assert_true(body.contains("_room_asks_camera_sight_at(") and body.contains("snap_arm_in"),
		"release snaps only through the room's ask")
	assert_true(source.contains("release_camera_snap_at"), "the room's ask is release_camera_snap_at")
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VEILFALL_CONFIG))
	assert_true(rules.has("release_camera_snap_1110"), "the release snap is a declared room rule")


func test_release_snap_ships_on_with_judged_gain_recorded() -> void:
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(VEILFALL_CONFIG))
	assert_true(bool(rules.get("release_camera_snap_1110", false)), "the release snap ships ON after the GPU judge")
	assert_true(str(rules.get("_why_on_release_camera_snap_1110", "")).contains("+1.31"), "the judged gain is recorded")
