extends "res://tests/test_case.gd"

## Regression: `cloudreach_world.gd::_ready()` merges the realm's sky profile
## into every `art.json` time preset. `art.json`'s `times` block also carries
## `_`-prefixed comment strings (N13 added `_comment_night_end_n13`), and a typed
## Dictionary loop over `.values()` threw on the string and aborted `_ready()`,
## leaving the whole Cloudreach world unbuilt while CI stayed green because no
## Cloudreach smoke runs there. These tests pin the guard against the real
## config and against a synthetic block with a comment in every position.

const WORLD := preload("res://scripts/world/cloudreach_world.gd")
const ART_PATH := "res://data/config/art.json"


func _read_art() -> Dictionary:
	var file := FileAccess.open(ART_PATH, FileAccess.READ)
	assert_true(file != null, "art.json must open")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "art.json must parse to a dictionary")
	return parsed if parsed is Dictionary else {}


func test_the_shipped_art_json_times_block_still_carries_comment_strings() -> void:
	# The condition the regression depends on. If a later cleanup removes every
	# comment key this test goes red so the synthetic test below is known to be
	# the one still guarding the loop.
	var times: Dictionary = _read_art().get("times", {})
	var strings := 0
	for key in times.keys():
		if times[key] is String:
			strings += 1
			assert_true(str(key).begins_with("_"),
				"a non-preset entry in times must be a _-prefixed comment: %s" % key)
	assert_true(strings >= 1, "art.json times currently carries at least one comment string")


func test_merging_the_real_art_json_touches_every_preset_and_no_comment() -> void:
	var times: Dictionary = (_read_art().get("times", {}) as Dictionary).duplicate(true)
	var presets := 0
	for key in times.keys():
		if times[key] is Dictionary:
			presets += 1
	var merged := WORLD.merge_sky_profile_into_times(times, {"probe": 1})
	assert_eq(merged, presets, "every dictionary preset is merged exactly once")
	for key in times.keys():
		var value: Variant = times[key]
		if value is Dictionary:
			assert_eq(int((value["sky"] as Dictionary).get("probe", 0)), 1,
				"preset %s carries the merged sky profile" % key)
		else:
			assert_true(value is String, "non-dictionary entries are left as the strings they were")


func test_a_comment_string_in_any_position_does_not_abort_the_merge() -> void:
	var times := {
		"_lead": "comment first",
		"day": {"hour": 12.0},
		"_mid": "comment in the middle",
		"night": {"hour": 0.0, "sky": {"kept": true}},
		"_tail": "comment last",
	}
	var merged := WORLD.merge_sky_profile_into_times(times, {"tint": "x"})
	assert_eq(merged, 2, "both presets merged, three comments skipped")
	assert_eq(str((times["day"]["sky"] as Dictionary).get("tint", "")), "x")
	assert_true(bool((times["night"]["sky"] as Dictionary).get("kept", false)),
		"merge is additive: an existing sky key survives")
	assert_eq(str(times["_mid"]), "comment in the middle", "comment strings are untouched")


func test_a_missing_or_non_dictionary_times_block_merges_nothing() -> void:
	assert_eq(WORLD.merge_sky_profile_into_times(null, {"a": 1}), 0)
	assert_eq(WORLD.merge_sky_profile_into_times("not a block", {"a": 1}), 0)
	assert_eq(WORLD.merge_sky_profile_into_times({}, {"a": 1}), 0)
