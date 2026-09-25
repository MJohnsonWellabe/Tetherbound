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
	var authored := {"night": {"sky": {"energy": 0.75}}, "day": {}}
	WORLD.merge_sky_profile_into_times(authored, {"energy": 1.3, "cloud_coverage": 0.4})
	assert_almost_eq(float(authored["night"]["sky"]["energy"]), 0.75, 0.0001,
		"a preset's own sky energy is not lifted to the realm's daytime value")
	assert_almost_eq(float(authored["night"]["sky"]["cloud_coverage"]), 0.4, 0.0001,
		"profile keys the preset does not author still arrive")
	assert_almost_eq(float(authored["day"]["sky"]["energy"]), 1.3, 0.0001)
	assert_eq(str(times["_mid"]), "comment in the middle", "comment strings are untouched")


func test_a_missing_or_non_dictionary_times_block_merges_nothing() -> void:
	assert_eq(WORLD.merge_sky_profile_into_times(null, {"a": 1}), 0)
	assert_eq(WORLD.merge_sky_profile_into_times("not a block", {"a": 1}), 0)
	assert_eq(WORLD.merge_sky_profile_into_times({}, {"a": 1}), 0)


func test_atmosphere_colours_become_the_base_and_only_the_fog_delta_stays_weather() -> void:
	var look := {"sky": {"horizon_colour": "#a6bccb", "top_colour": "#3b6f93"},
		"environment": {"fog_colour": "#ffffff"},
		"times": {"night": {"sky": {"horizon_colour": "#4d6a9e"}}}}
	var delta := WORLD.fold_atmosphere_into_base(look, {
		"environment": {"fog_density_add": -0.00015, "fog_colour": "#a2bdc8"},
		"sky": {"horizon_colour": "#a2bdc8", "ground_horizon_colour": "#a2bdc8"}})
	assert_eq(str(look["sky"]["horizon_colour"]), "#a2bdc8", "the day inherits the realm haze")
	assert_eq(str(look["sky"]["top_colour"]), "#3b6f93", "other base sky keys are kept")
	assert_eq(str(look["environment"]["fog_colour"]), "#a2bdc8")
	assert_eq(str(look["times"]["night"]["sky"]["horizon_colour"]), "#4d6a9e",
		"night keeps its own horizon; the haze no longer stands behind the night sky")
	assert_false((delta.get("sky", {}) as Dictionary).has("horizon_colour"),
		"no colour rides the weather delta any more")
	assert_almost_eq(float((delta["environment"] as Dictionary)["fog_density_add"]), -0.00015, 0.0000001)
	assert_false((delta["environment"] as Dictionary).has("fog_colour"))


func test_the_shipped_cloudreach_night_is_darker_than_its_day() -> void:
	var art := _read_art()
	var visual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var look: Dictionary = art.duplicate(true)
	(look["sky"] as Dictionary).merge(visual.get("sky_profile", {}), true)
	WORLD.merge_sky_profile_into_times(look["times"], visual.get("sky_profile", {}))
	WORLD.fold_atmosphere_into_base(look, visual.get("atmosphere", {}))
	var night: Dictionary = look["times"]["night"]["sky"]
	assert_true(float(night.get("energy", 1.0)) < float(look["sky"].get("energy", 1.0)),
		"night sky energy stays below the realm's daytime sky")
	assert_true(Color(str(night["horizon_colour"])).get_luminance()
		< Color(str(look["sky"]["horizon_colour"])).get_luminance(),
		"night horizon is darker than the day haze")


## Frame-matrix M4. The realm's night override lifts the moon-shadow fill but
## leaves the preset a night: the budget is world_look.gd's own light_budget
## arithmetic (Compatibility ambient share, weighted by colour luma).
func _budget(env: Dictionary, sun: Dictionary) -> Dictionary:
	var exposure := float(env.get("exposure", 1.0))
	var direct := float(sun.get("energy", 1.25)) * exposure \
		* Color(str(sun.get("colour", "#ffffff"))).get_luminance()
	var ambient := float(env.get("ambient_energy", 1.0)) \
		* (1.0 - float(env.get("ambient_sky_contribution", 0.55))) * exposure \
		* Color(str(env.get("ambient_colour", "#9fb4c6"))).get_luminance()
	return {"direct": direct, "ambient": ambient, "total": direct + ambient}


func _night_budget(times: Dictionary, base: Dictionary) -> Dictionary:
	var env: Dictionary = (base.get("environment", {}) as Dictionary).duplicate()
	env.merge(times["night"]["environment"], true)
	var sun: Dictionary = (base.get("sun", {}) as Dictionary).duplicate()
	sun.merge(times["night"]["sun"], true)
	return _budget(env, sun)


func test_the_cloudreach_night_override_lifts_shadow_fill_but_stays_night() -> void:
	var art := _read_art()
	var visual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var shared_times: Dictionary = (art["times"] as Dictionary).duplicate(true)
	var realm_times: Dictionary = (art["times"] as Dictionary).duplicate(true)
	assert_eq(WORLD.apply_time_overrides(realm_times, visual.get("time_overrides", {})), 1)
	var shared := _night_budget(shared_times, art)
	var realm := _night_budget(realm_times, art)
	var day := _budget(art["environment"], art["sun"])
	assert_true(float(realm.ambient) >= float(shared.ambient) * 1.8,
		"moon-shadow fill at least 1.8x the shared night (%.3f vs %.3f)" % [realm.ambient, shared.ambient])
	assert_almost_eq(float(realm.direct), float(shared.direct), 0.0001,
		"the moon itself is the shared night's")
	assert_true(float(realm.ambient) <= float(day.ambient) * 1.6,
		"the fill stays in the range of the daytime fill, not a flood")
	var realm_env: Dictionary = realm_times["night"]["environment"]
	var shared_env: Dictionary = shared_times["night"]["environment"]
	assert_almost_eq(float(realm_env.exposure), float(shared_env.exposure), 0.0001,
		"exposure stays the shared night's, so the sky stays dark")
	assert_true(Color(str(realm_env.ambient_colour)).b > Color(str(realm_env.ambient_colour)).r * 1.8,
		"the fill stays a night blue")
	assert_true(float(realm_env.creature_emission_floor) < float(shared_env.creature_emission_floor),
		"creatures lean on the night light rather than a fixed self-glow")
	assert_eq(shared_times["night"]["environment"]["ambient_energy"],
		art["times"]["night"]["environment"]["ambient_energy"], "the shared preset is untouched")


func test_time_overrides_win_skip_comments_and_ignore_unknown_presets() -> void:
	var times := {"_c": "comment", "night": {"sun": {"energy": 0.5}, "environment": {"a": 1, "b": 2}}}
	var touched := WORLD.apply_time_overrides(times, {
		"_comment": "skip",
		"night": {"_why": "skip", "environment": {"a": 9, "_note": "skip"}},
		"missing": {"environment": {"a": 3}},
	})
	assert_eq(touched, 1)
	assert_eq(times["night"]["environment"]["a"], 9)
	assert_eq(times["night"]["environment"]["b"], 2)
	assert_false((times["night"]["environment"] as Dictionary).has("_note"))
	assert_false((times["night"] as Dictionary).has("_why"))
	assert_false(times.has("missing"))
	assert_eq(WORLD.apply_time_overrides(null, {}), 0)
	assert_eq(WORLD.apply_time_overrides(times, "nope"), 0)
