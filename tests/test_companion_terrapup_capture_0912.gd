extends "res://tests/test_case.gd"

## Static/source contracts for the OWNER-0912 companion evidence instrument.
## Rendering remains the production command in the capture tool's header; these
## checks keep a later cleanup from quietly replacing real controller/rest paths
## with posed fixture shortcuts while leaving plausible-looking PNGs behind.

const TOOL_PATH := "res://tools/capture_companion_terrapup_0912.gd"
const OPENING_PATH := "res://data/config/opening.json"
const SPECIES_PATH := "res://data/creatures/species.json"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _source() -> String:
	return FileAccess.get_file_as_string(TOOL_PATH)


func test_capture_is_fresh_and_has_the_complete_eight_frame_plan() -> void:
	var source := _source()
	assert_true(source.contains("FRESH_OUTPUT.create_fresh"),
		"every run requires a new explicit evidence directory")
	assert_true(source.contains("manifest.json"), "the run writes a manifest")
	assert_true(source.contains("PLANNED_FRAMES.size()"),
		"completion is checked against the authored plan")
	for frame: String in [
		"01-formation-settled-day", "02-formation-settled-night",
		"03-formation-left-motion-day", "04-formation-right-motion-day",
		"05-terrapup-lay-side-day", "06-terrapup-lay-three-quarter-day",
		"07-terrapup-lay-side-night", "08-terrapup-lay-three-quarter-night",
	]:
		assert_true(source.contains(frame), "capture plan retains %s" % frame)


func test_formation_uses_production_party_director_camera_and_input() -> void:
	var source := _source()
	for seam: String in [
		"meadows_playground.tscn", "EncounterDirector", "adopt_starter",
		"_party.call(\"add\"", "CameraRig/Camera3D", "Input.action_press",
		"move_forward", "move_left", "move_right", "is_closing",
	]:
		assert_true(source.contains(seam), "formation capture retains production seam %s" % seam)
	assert_true(source.contains("station_error_xz_m"),
		"manifest measures authored-station error")
	assert_true(source.contains("camera_axis_surface_clearance_m"),
		"manifest measures companion clearance from the camera/player axis")


func test_rest_uses_party_assignment_recall_and_the_real_resting_body() -> void:
	var source := _source()
	for seam: String in [
		"Stronghold", "recovery_point", "assign_creature", "RestingCreature",
		"_director.call(\"ally_body\") == null", "current_animation",
		"surface_get_arrays", "get_bone_global_pose", "get_bind_pose",
	]:
		assert_true(source.contains(seam), "rest capture retains production seam %s" % seam)
	assert_false(source.contains(".seek("), "capture must not inject an animation pose")
	assert_false(source.contains("set(\"resting\""),
		"capture must not bypass Party/CreatureBed with a direct resting write")
	assert_false(source.contains("call(\"play_rest\")"),
		"capture lets creature_bed.gd, not the instrument, trigger play_rest")


func test_authored_formation_and_terrapup_rest_contracts_still_match_the_receipt() -> void:
	var opening := _json(OPENING_PATH)
	var follower := opening.get("follower", {}) as Dictionary
	assert_almost_eq(float(follower.get("side_offset", 0.0)), 1.8, 0.001,
		"the shipped companion station is beside the trainer")
	assert_almost_eq(float(follower.get("back_offset", 0.0)), 0.5, 0.001,
		"the shipped station is only half a step behind")
	assert_true(float(follower.get("side_offset", 0.0)) > float(follower.get("back_offset", 0.0)),
		"formation remains beside-not-behind")

	var species := _json(SPECIES_PATH).get("species", {}) as Dictionary
	var terrapup := (species.get("terrapup", {}) as Dictionary).get("placeholder", {}) as Dictionary
	assert_almost_eq(float(terrapup.get("rest_roll_deg", -999.0)), 0.0, 0.001,
		"Terrapup opts into its authored completed faint/Lay silhouette")
	assert_eq(str((terrapup.get("animations", {}) as Dictionary).get("faint", "")), "faint",
		"play_rest resolves the shipped Terrapup faint clip")
