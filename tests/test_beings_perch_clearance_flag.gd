extends "res://tests/test_case.gd"

## BEINGS-PERCH-CLEARANCE (F40#17): cloudreach_high_perches_visual.json
## `companion_needle_clearance`, OFF until GPU-judged. The High Perches needles
## stay visual-only (no collider); when ON they declare a follower keep-clear
## radius and the Cloudreach follow validator refuses spots whose rendered
## footprint overlaps one, so the companion no longer stands inside a needle.

const CONFIG_PATH := "res://data/config/cloudreach_high_perches_visual.json"
const FOLLOWER := preload("res://scripts/creatures/follower_creature.gd")
const WORLD := preload("res://scripts/world/cloudreach_world.gd")
const DIRECTOR_PATH := "res://scripts/combat/cloudreach_encounter_director.gd"
const WORLD_PATH := "res://scripts/world/cloudreach_world.gd"


func _flag() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG_PATH))
	assert_true(parsed is Dictionary, "High Perches config parses")
	return (parsed as Dictionary).get("companion_needle_clearance", {}) if parsed is Dictionary else {}


func test_flag_is_off_and_declares_scope() -> void:
	var flag := _flag()
	assert_false(flag.is_empty(), "companion_needle_clearance exists")
	assert_false(bool(flag.get("enabled", true)), "it is OFF until GPU-judged")
	assert_true(str(flag.get("scope", "")).contains("no state"), "presentation-only scope")
	var margin := float(flag.get("margin_m", -1.0))
	assert_true(margin >= 0.0 and margin <= 1.0, "a small non-negative margin")


func test_world_uses_the_followers_group_and_meta_names() -> void:
	assert_eq(StringName(WORLD.FOLLOWER_KEEP_CLEAR_GROUP), StringName(FOLLOWER.KEEP_CLEAR_GROUP),
		"the needles join the follower's keep-clear group")
	assert_eq(StringName(WORLD.FOLLOWER_KEEP_CLEAR_RADIUS_META), StringName(FOLLOWER.KEEP_CLEAR_RADIUS_META),
		"with the follower's radius meta")
	var source := FileAccess.get_file_as_string(WORLD_PATH)
	assert_true(source.contains("needle.add_to_group(FOLLOWER_KEEP_CLEAR_GROUP)"),
		"each needle joins the group")
	assert_true(source.contains("companion_needle_clearance"), "only behind the flag")


func test_validator_refuses_spots_inside_a_zone() -> void:
	var source := FileAccess.get_file_as_string(DIRECTOR_PATH)
	assert_true(source.contains("if _in_keep_clear(spot, body, zones):"),
		"the follow and recall spot search skips keep-clear spots")
	# The rule it applies: a 2.28 m footprint (Galecrest) 3.3 m from a 4.3 m zone overlaps;
	# 7 m away it is clear; with no zones nothing is refused.
	var zones := [[Vector2.ZERO, 4.3]]
	assert_true(FOLLOWER.keep_clear_hit(zones, Vector3(3.3, 0.0, 0.0), 2.28), "inside the needle: refused")
	assert_false(FOLLOWER.keep_clear_hit(zones, Vector3(7.0, 0.0, 0.0), 2.28), "clear of it: allowed")
	assert_false(FOLLOWER.keep_clear_hit([], Vector3(3.3, 0.0, 0.0), 2.28), "no zones: unchanged")
