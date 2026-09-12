extends "res://tests/test_case.gd"

const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const QUEST_LOG := preload("res://scripts/world/quest_log.gd")
const OBJECTIVE_BEACON := preload("res://scripts/world/objective_beacon.gd")
const OBJECTIVES_PATH := "res://data/progression/objectives.json"

var progression: RefCounted = null
var log_reader: RefCounted = null
var objectives: Dictionary = {}


func before_each() -> void:
	progression = PROGRESSION_STATE.new()
	log_reader = QUEST_LOG.new()
	objectives = JSON.parse_string(FileAccess.get_file_as_string(OBJECTIVES_PATH)) as Dictionary


func _main() -> Array:
	return objectives.get("main", []) as Array


func _complete_before(id: String) -> void:
	for raw: Variant in _main():
		var entry := raw as Dictionary
		if str(entry.get("id", "")) == id:
			return
		progression.set_flag(str(entry.get("flag_id", "")))
	assert_true(false, "objective '%s' is not authored" % id)


func _entry(id: String) -> Dictionary:
	for raw: Variant in _main():
		var entry := raw as Dictionary
		if str(entry.get("id", "")) == id:
			return entry
	return {}


func test_every_meadows_main_objective_has_one_valid_concrete_beacon_destination() -> void:
	assert_eq(_main().size(), 28, "the main objective chain changed; revisit beacon coverage deliberately")
	for raw: Variant in _main():
		var entry := raw as Dictionary
		var beacon: Variant = entry.get("beacon", null)
		assert_true(beacon is Dictionary, "%s has no beacon destination" % str(entry.get("id", "")))
		if not beacon is Dictionary:
			continue
		var position: Variant = (beacon as Dictionary).get("position", null)
		assert_true(position is Array and (position as Array).size() == 2,
			"%s beacon must be one Meadows [x,z] pair" % str(entry.get("id", "")))
		assert_false(str((beacon as Dictionary).get("display_name", "")).strip_edges().is_empty(),
			"%s beacon has no player-facing destination name" % str(entry.get("id", "")))


func test_the_beacon_selects_the_exact_same_first_undone_row_as_the_hud() -> void:
	for expected_id: String in ["opening_hear_grandpa", "open_road_gate", "head_to_south_bridge",
			"clear_the_burrow_warrens", "defeat_the_relay_captain", "restore_the_mill_crossing"]:
		progression = PROGRESSION_STATE.new()
		_complete_before(expected_id)
		var beacon: Dictionary = log_reader.tracked_beacon(progression)
		assert_eq(str(beacon.get("id", "")), expected_id)
		assert_eq(log_reader.tracked_id(progression), expected_id,
			"world beacon and HUD selected different objective rows")
		assert_true(beacon.get("position") is Vector2)


func test_a_counted_objective_moves_to_each_remaining_captain_then_the_gate() -> void:
	_complete_before("defeat_the_captains")
	var target: Dictionary = log_reader.tracked_beacon(progression)
	assert_eq(target.position, Vector2(-100.0, 4350.0))
	assert_eq(target.display_name, "Captain Riverwatch")

	progression.set_flag("defeated_captain_riverwatch")
	target = log_reader.tracked_beacon(progression)
	assert_eq(target.position, Vector2(170.0, 5590.0))
	assert_eq(target.display_name, "Field Captain")

	progression.set_flag("defeated_captain_field")
	target = log_reader.tracked_beacon(progression)
	assert_eq(target.position, Vector2(-280.0, 6460.0))
	assert_eq(target.display_name, "Ridge Captain")

	progression.set_flag("defeated_captain_ridge")
	target = log_reader.tracked_beacon(progression)
	assert_eq(target.position, Vector2(63.6, 7400.0))
	assert_eq(target.display_name, "Meadows Hall gate")


func test_counted_beacon_steps_only_use_the_objectives_existing_count_flags() -> void:
	for raw: Variant in _main():
		var entry := raw as Dictionary
		var beacon := entry.get("beacon", {}) as Dictionary
		var steps := beacon.get("steps", []) as Array
		if steps.is_empty():
			continue
		var count_flags := entry.get("count_flags", []) as Array
		for step_raw: Variant in steps:
			var step := step_raw as Dictionary
			assert_true(count_flags.has(str(step.get("until_flag", ""))),
				"%s beacon invented a branch flag outside its existing count" % str(entry.get("id", "")))


func test_completed_chapter_has_no_world_or_map_beacon() -> void:
	for raw: Variant in _main():
		progression.set_flag(str((raw as Dictionary).get("flag_id", "")))
	assert_true(log_reader.tracked_beacon(progression).is_empty())


func test_beacon_lands_just_above_the_authored_ground_without_changing_xz() -> void:
	var placed := OBJECTIVE_BEACON.world_position(Vector2(-357.0, 2610.0), 4.5)
	assert_eq(placed, Vector3(-357.0, 4.58, 2610.0))


func test_wayfinding_visual_is_tunable_and_stays_lightweight() -> void:
	var config := JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/objective_beacon.json")) as Dictionary
	assert_between(float(config.get("beam_height_m", 0.0)), 60.0, 120.0,
		"beam must clear the canopy without becoming a skyline wall")
	assert_between(float(config.get("beam_radius_m", 0.0)), 0.3, 1.2)
	assert_between(float(config.get("beam_opacity", 0.0)), 0.20, 0.32,
		"the 500m beam needs daylight contrast without becoming an opaque wall")
	assert_between(float(config.get("visible_range_m", 0.0)), 1500.0, 4000.0)
	var source := FileAccess.get_file_as_string("res://scripts/world/objective_beacon.gd")
	assert_true(source.contains("material.no_depth_test = depth_independent"),
		"the narrow world beam can disappear completely behind an ordinary route tree")
	assert_true(source.contains("_material(float(_config.get(\"beam_opacity\", 0.26)), true)"),
		"only the vertical beam should opt into canopy-proof depth; the grounded pieces must not")
	assert_false(source.contains("Light3D"), "objective beacon must not add a world-light budget")
	assert_false(source.contains("Particles"), "objective beacon must remain a few cheap meshes")


func test_real_meadows_world_mounts_one_beacon_and_shells_do_not() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/playground_world.gd")
	assert_true(source.contains("const OBJECTIVE_BEACON := preload"))
	assert_true(source.contains("objective_beacon.name = \"ObjectiveBeacon\""))
	assert_true(source.contains("if not simulation_only:\n\t\tvar objective_beacon := OBJECTIVE_BEACON.new()"),
		"simulation shells must not draw or mutate a local player's beacon")
