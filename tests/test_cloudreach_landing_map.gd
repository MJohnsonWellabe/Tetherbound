extends "res://tests/test_case.gd"

## F07#0 (WORLD §11): the Three Bells reveal the three known safe landing
## points, and each aeries survey adds map knowledge. Derived map pins in
## `cloudreach_world_payoffs.gd` (`landing_map_markers`/`sync_landing_map`),
## never saved, gated on each landing's region (`map_reveal_requires`).

const PAYOFFS := preload("res://scripts/world/cloudreach_world_payoffs.gd")
const PROGRESSION := preload("res://autoload/progression_state.gd")
const MAP := preload("res://autoload/map_state.gd")

var flags: RefCounted
var data: Dictionary


func before_each() -> void:
	flags = PROGRESSION.new()
	data = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_npc_runtime.json")).get("world_payoffs", {})


func _ids(markers: Dictionary) -> Array:
	var ids := markers.keys()
	ids.sort()
	return ids


func test_every_landing_declares_its_region_gate() -> void:
	var markers: Array = data.get("survey_markers", [])
	assert_eq(markers.size(), 3, "three known safe landing points")
	for spec: Dictionary in markers:
		assert_false((spec.get("map_reveal_requires", []) as Array).is_empty(), "%s is gated so the map cannot spoil its region" % str(spec.id))


func test_nothing_is_known_before_the_bells_or_a_survey() -> void:
	for flag: String in ["fly_traversal_unlocked", "cloudreach_upper_route_unlocked", "cloudreach_upper_anchors_disabled"]:
		flags.set_flag(flag)
	assert_eq(PAYOFFS.landing_map_markers(flags, data).size(), 0)


func test_the_bells_reveal_only_the_landings_whose_region_is_open() -> void:
	flags.set_flag("side_three_bells_complete")
	assert_eq(PAYOFFS.landing_map_markers(flags, data).size(), 0, "no region open yet")
	flags.set_flag("fly_traversal_unlocked")
	assert_eq(_ids(PAYOFFS.landing_map_markers(flags, data)), ["cloudreach_landing_high_perches"])
	flags.set_flag("cloudreach_upper_route_unlocked")
	flags.set_flag("cloudreach_upper_anchors_disabled")
	assert_eq(PAYOFFS.landing_map_markers(flags, data).size(), 3, "all three known safe landings")


func test_a_survey_is_map_knowledge_even_without_the_bells() -> void:
	flags.set_flag("fly_traversal_unlocked")
	flags.set_flag("side_aerie_high_perches_surveyed")
	var markers := PAYOFFS.landing_map_markers(flags, data)
	assert_eq(_ids(markers), ["cloudreach_landing_high_perches"])
	assert_true(str(markers["cloudreach_landing_high_perches"].name).ends_with("(surveyed)"))


func test_sync_is_idempotent_and_restores_after_a_map_reload() -> void:
	var map: RefCounted = MAP.new()
	flags.set_flag("side_three_bells_complete")
	flags.set_flag("fly_traversal_unlocked")
	assert_true(PAYOFFS.sync_landing_map(map, flags, data), "first sync adds the pin")
	var revision := int(map.get("revision"))
	assert_false(PAYOFFS.sync_landing_map(map, flags, data), "a repeat sync changes nothing")
	assert_eq(int(map.get("revision")), revision)
	flags.set_flag("side_aerie_high_perches_surveyed")
	assert_true(PAYOFFS.sync_landing_map(map, flags, data), "a survey renames the pin")
	var fresh: RefCounted = MAP.new()
	assert_true(PAYOFFS.sync_landing_map(fresh, flags, data), "a reloaded map (no dynamic markers) gets the pin back")
	var dynamic_ids: Array = []
	for entry: Dictionary in fresh.call("landmarks"):
		if bool(entry.get("dynamic", false)):
			dynamic_ids.append(str(entry.id))
	assert_eq(dynamic_ids, ["cloudreach_landing_high_perches"])
