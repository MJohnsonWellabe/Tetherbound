extends "res://tests/test_case.gd"

## MEADOWS-VISUAL-PASS round 5: a realm's own look is deep-merged over the
## shared art.json presets (world_look.gd::merged_look), so a Meadows-only
## value never leaks into another chapter's sky.

const WORLD_LOOK := preload("res://scripts/world/world_look.gd")


func test_the_overlay_merges_key_by_key_and_leaves_both_inputs_alone() -> void:
	var base := {"environment": {"fog_colour": "#a6bccb", "exposure": 0.6}, "times": {"day": {"hour": 8.0}}}
	var overlay := {"environment": {"fog_colour": "#98b2cb"}, "horizon_mountains": {"strength": 1.0}}
	var merged: Dictionary = WORLD_LOOK.merged_look(base, overlay)
	assert_eq(str((merged["environment"] as Dictionary)["fog_colour"]), "#98b2cb")
	assert_almost_eq(float((merged["environment"] as Dictionary)["exposure"]), 0.6, 0.0001,
		"a key the overlay does not name keeps the shared value")
	assert_true(merged.has("horizon_mountains"))
	assert_eq(str((base["environment"] as Dictionary)["fog_colour"]), "#a6bccb", "base untouched")


func test_only_the_meadows_scene_carries_the_meadows_look() -> void:
	var meadows := FileAccess.get_file_as_string("res://scenes/world/meadows_playground.tscn")
	assert_true(meadows.contains('realm_look_path = "res://data/config/meadows_look.json"'))
	for other: String in ["res://scenes/world/cloudreach_cliffs.tscn", "res://scenes/world/stormwood.tscn",
			"res://scenes/world/water_archipelago.tscn"]:
		assert_false(FileAccess.get_file_as_string(other).contains("meadows_look.json"),
			"%s must keep its own horizon" % other)


func test_the_meadows_haze_lives_in_the_meadows_overlay() -> void:
	var meadows: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/meadows_look.json"))
	var env: Dictionary = (meadows as Dictionary).get("environment", {})
	assert_true(env.has("fog_colour"), "the Meadows distance haze is the overlay's to set")
	var art: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	assert_ne(str(((art as Dictionary).get("environment", {}) as Dictionary).get("fog_colour", "")),
		str(env.get("fog_colour", "")), "art.json keeps the shared haze for the other realms")
