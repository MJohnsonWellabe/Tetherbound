extends "res://tests/test_case.gd"

## F40#8 Three Bells bridge view (GPU High 5.29 -> 6.77, G-newapproach-bridge-view):
## the landing tree in front of the bridge is not placed, and locked Storm
## Anchors show the darker stone waymark instead of the cyan column.


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_bridge_landing_tree_is_cleared_with_its_verdict() -> void:
	var spec: Dictionary = _json("res://data/config/cloudreach_visual.json").get("landing_tree_clear", {})
	assert_true(spec.get("enabled") == true, "landing_tree_clear stays ON")
	var names: Array = spec.get("names", [])
	assert_true(names.has("LandingTree926"), "the tree in front of the Three Bells bridge is cleared")
	assert_true(names.has("LandingTree171"), "the road-side canopy tree stays cleared")
	assert_eq(names.size(), 2, "no other landing tree is cleared")
	assert_true(str(spec.get("_why_on_LandingTree926", "")).contains("5.29 -> 6.77"), "the bridge tree records its GPU verdict")


func test_anchor_waymark_ships_on_in_the_judged_stone() -> void:
	var mark: Dictionary = _json("res://data/config/cloudreach_npc_runtime.json").world_payoffs.anchor_waymark
	assert_true(mark.get("enabled") == true, "anchor_waymark ships ON")
	assert_true(str(mark.get("_why_on", "")).contains("5.29 -> 6.77"), "anchor_waymark records its GPU verdict")
	assert_eq(str(mark.stone_colour), "#8c8676", "the judged darker stone")
	assert_eq(str(mark.cap_colour), "#a8873f", "the judged duller cap")
	assert_true(is_equal_approx(float(mark.height_m), 2.1), "the judged shorter height")
