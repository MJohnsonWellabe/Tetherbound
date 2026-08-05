extends "res://tests/test_case.gd"

## The clock, the weather state machine, and the spawn conditions. M10.
##
## Per D02 these are pure-logic tests: which two keyframes an hour sits between,
## which phase an hour is in, how two look blocks blend, how the next weather is
## rolled, and whether a species' conditions are met. Whether the result LOOKS
## like night is `tools/preview_weather.gd` and a human's eye, and pretending a
## number could answer that is the D18 mistake.
##
## The last group is different in kind: it checks that the two config files
## agree with each other and with the roster. A weather id misspelt in one file
## and not the other produces a game that silently never rains, and there is
## nothing in a rendered frame that would tell you why.

const CYCLE := preload("res://scripts/world/sky_cycle.gd")
const LOOK := preload("res://scripts/world/world_look.gd")

const WEATHER_CONFIG := "res://data/config/weather.json"
const ART_CONFIG := "res://data/config/art.json"
const SPECIES_TABLE := "res://data/pals/species.json"


func _json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}


func _weather() -> Dictionary:
	return _json(WEATHER_CONFIG)


func _art() -> Dictionary:
	return _json(ART_CONFIG)


func _named(section: Dictionary) -> Array:
	var found: Array = []
	for key: String in section.keys():
		if not key.begins_with("_"):
			found.append(key)
	return found


# --- phases ----------------------------------------------------------------


func test_each_hour_lands_in_exactly_one_phase() -> void:
	var phases: Dictionary = _weather().get("phases", {})
	assert_true(phases.size() >= 4, "the four phases of §24's day")
	for step in 48:
		var at := float(step) * 0.5
		var hits := 0
		for name: String in phases.keys():
			if name.begins_with("_"):
				continue
			var span: Dictionary = phases[name]
			var from := float(span["from"])
			var to := float(span["to"])
			var inside := (at >= from and at < to) if from <= to else (at >= from or at < to)
			if inside:
				hits += 1
		assert_eq(hits, 1, "hour %.1f is in exactly one phase" % at)


func test_night_wraps_past_midnight() -> void:
	# The one phase that crosses midnight, and the one the nocturnal species
	# depend on. A naive `from <= hour and hour < to` makes it permanently empty.
	var phases: Dictionary = _weather().get("phases", {})
	assert_eq(CYCLE.phase_at(phases, 23.0), "night", "23:00 is night")
	assert_eq(CYCLE.phase_at(phases, 0.0), "night", "midnight is night")
	assert_eq(CYCLE.phase_at(phases, 3.5), "night", "03:30 is still night")
	assert_ne(CYCLE.phase_at(phases, 12.0), "night", "noon is not night")


func test_the_named_phases_are_the_ones_the_hours_produce() -> void:
	var phases: Dictionary = _weather().get("phases", {})
	assert_eq(CYCLE.phase_at(phases, 6.0), "dawn")
	assert_eq(CYCLE.phase_at(phases, 11.0), "day")
	assert_eq(CYCLE.phase_at(phases, 18.0), "dusk")
	# Hours outside 0..24 are the same hour, because a clock wraps.
	assert_eq(CYCLE.phase_at(phases, 35.0), CYCLE.phase_at(phases, 11.0))
	assert_eq(CYCLE.phase_at(phases, -1.0), CYCLE.phase_at(phases, 23.0))


# --- the keyframe curve ----------------------------------------------------


func test_an_hour_on_a_keyframe_is_that_keyframe_exactly() -> void:
	var hours: Array = [0.0, 6.2, 11.0, 18.0]
	var at := LOOK.bracket_hours(hours, 11.0)
	assert_eq(int(at["before"]), 2, "11:00 starts the day->golden segment")
	assert_almost_eq(float(at["t"]), 0.0, 0.0001, "and sits at its start")


func test_an_hour_between_two_keyframes_is_the_fraction_between_them() -> void:
	var hours: Array = [0.0, 6.2, 11.0, 18.0]
	var at := LOOK.bracket_hours(hours, 14.5)
	assert_eq(int(at["before"]), 2)
	assert_eq(int(at["after"]), 3)
	assert_almost_eq(float(at["t"]), 0.5, 0.0001, "14:30 is halfway from 11:00 to 18:00")


func test_the_segment_that_crosses_midnight_is_the_one_that_can_be_wrong() -> void:
	var hours: Array = [0.0, 6.2, 11.0, 18.0]
	# 18:00 -> 24:00/00:00 is the wrapping segment.
	var at := LOOK.bracket_hours(hours, 21.0)
	assert_eq(int(at["before"]), 3, "21:00 is after the last keyframe of the day")
	assert_eq(int(at["after"]), 0, "and before the first of the next")
	assert_almost_eq(float(at["t"]), 0.5, 0.0001, "half way from 18:00 to midnight")
	# ...and the tail of the same segment, before the first keyframe.
	var tail := LOOK.bracket_hours([2.0, 8.0, 20.0], 1.0)
	assert_eq(int(tail["before"]), 2, "01:00 follows the 20:00 keyframe")
	assert_eq(int(tail["after"]), 0)
	assert_almost_eq(float(tail["t"]), 5.0 / 6.0, 0.0001, "five of the six hours from 20:00 to 02:00")


func test_a_single_keyframe_cannot_divide_by_zero() -> void:
	var at := LOOK.bracket_hours([9.0], 17.0)
	assert_eq(int(at["before"]), 0)
	assert_eq(int(at["after"]), 0)
	assert_almost_eq(float(at["t"]), 0.0, 0.0001)


# --- blending look blocks --------------------------------------------------


func test_numbers_lerp_and_colours_lerp_as_colours() -> void:
	var a := {"energy": 1.0, "colour": "#000000"}
	var b := {"energy": 3.0, "colour": "#ffffff"}
	var mid := LOOK.blend_blocks(a, b, 0.5)
	assert_almost_eq(float(mid["energy"]), 2.0, 0.0001)
	var half := Color(str(mid["colour"]))
	assert_between(half.r, 0.45, 0.55, "halfway between black and white")
	assert_true(str(mid["colour"]).begins_with("#"), "and still parseable as a colour")


func test_a_value_only_one_side_declares_survives() -> void:
	var mid := LOOK.blend_blocks({"only_a": 4.0}, {"only_b": 9.0}, 0.5)
	assert_almost_eq(float(mid["only_a"]), 4.0, 0.0001)
	assert_almost_eq(float(mid["only_b"]), 9.0, 0.0001)


func test_strings_take_a_side_rather_than_being_averaged() -> void:
	var a := {"panorama": "day.hdr"}
	var b := {"panorama": "night.hdr"}
	assert_eq(str(LOOK.blend_blocks(a, b, 0.2)["panorama"]), "day.hdr")
	assert_eq(str(LOOK.blend_blocks(a, b, 0.8)["panorama"]), "night.hdr")


func test_comments_are_not_values() -> void:
	var mid := LOOK.blend_blocks({"_comment": "why", "x": 0.0}, {"_comment": "also why", "x": 1.0}, 0.5)
	assert_false(mid.has("_comment"), "art.json carries its reasoning inline; it is not a look value")
	assert_almost_eq(float(mid["x"]), 0.5, 0.0001)


# --- choosing the next weather ---------------------------------------------


func test_the_weather_never_rolls_into_itself() -> void:
	var weights := {"clear": 40.0, "cloudy": 30.0, "rain": 20.0, "fog": 10.0}
	for step in 100:
		var roll := float(step) / 100.0
		assert_ne(CYCLE.choose_from(weights, "clear", roll), "clear",
			"a re-roll into the same weather looks exactly like a broken timer")


func test_a_zero_weight_state_is_never_chosen() -> void:
	var weights := {"clear": 50.0, "storm": 0.0, "fog": 50.0}
	for step in 60:
		assert_ne(CYCLE.choose_from(weights, "clear", float(step) / 60.0), "storm")


func test_the_roll_spans_the_whole_table() -> void:
	var weights := {"clear": 1.0, "cloudy": 1.0, "rain": 1.0}
	var seen := {}
	for step in 60:
		seen[CYCLE.choose_from(weights, "storm", float(step) / 60.0)] = true
	assert_eq(seen.size(), 3, "every state with weight is reachable")


func test_a_table_with_nothing_else_in_it_holds() -> void:
	assert_eq(CYCLE.choose_from({"clear": 10.0}, "clear", 0.5), "clear",
		"nothing else is available, so it stays rather than returning an empty id")


# --- spawn conditions ------------------------------------------------------


func test_a_species_with_no_conditions_is_always_present() -> void:
	assert_almost_eq(CYCLE.weight_for({}, "night", "storm"), 1.0, 0.0001)


func test_a_nocturnal_species_is_rarer_by_day_rather_than_deleted() -> void:
	var pup := {"phases": ["dusk", "night"], "elsewhere": 0.35}
	assert_almost_eq(CYCLE.weight_for(pup, "night", "clear"), 1.0, 0.0001)
	assert_almost_eq(CYCLE.weight_for(pup, "day", "clear"), 0.35, 0.0001)
	assert_true(CYCLE.weight_for(pup, "day", "clear") > 0.0,
		"a player who only ever plays at noon should still be able to meet one")


func test_the_rare_one_is_gated_on_time_AND_weather_and_is_absent_otherwise() -> void:
	# §24: "rare pals can depend on habitat, time and weather". Habitat is the
	# distance band in spawns.json; these are the other two, and the AND between
	# them is the part a table-driven check gets wrong.
	var wolf := {"phases": ["night"], "weather": ["clear", "fog"], "elsewhere": 0.0}
	assert_almost_eq(CYCLE.weight_for(wolf, "night", "clear"), 1.0, 0.0001)
	assert_almost_eq(CYCLE.weight_for(wolf, "night", "fog"), 1.0, 0.0001)
	assert_almost_eq(CYCLE.weight_for(wolf, "night", "rain"), 0.0, 0.0001,
		"right hour, wrong weather")
	assert_almost_eq(CYCLE.weight_for(wolf, "day", "clear"), 0.0, 0.0001,
		"right weather, wrong hour")


func test_a_weather_gated_species_ignores_the_hour() -> void:
	var frog := {"weather": ["rain", "storm", "fog"], "elsewhere": 0.3}
	assert_almost_eq(CYCLE.weight_for(frog, "day", "rain"), 1.0, 0.0001)
	assert_almost_eq(CYCLE.weight_for(frog, "night", "rain"), 1.0, 0.0001)
	assert_almost_eq(CYCLE.weight_for(frog, "day", "clear"), 0.3, 0.0001)


func test_a_missing_elsewhere_means_absent() -> void:
	assert_almost_eq(CYCLE.weight_for({"phases": ["night"]}, "day", "clear"), 0.0, 0.0001)


# --- the milestone's own bullets -------------------------------------------


func test_the_roster_has_a_nocturnal_species() -> void:
	# M10 asks for "at least one nocturnal pal" in as many words.
	var conditions: Dictionary = _weather().get("spawn_conditions", {})
	var nocturnal: Array = []
	for id: String in conditions.keys():
		if id.begins_with("_"):
			continue
		var phases: Array = (conditions[id] as Dictionary).get("phases", [])
		if phases.has("night") and not phases.has("day"):
			nocturnal.append(id)
	assert_true(nocturnal.size() >= 1, "at least one species is out at night and not by day")


func test_the_roster_has_a_weather_conditioned_species() -> void:
	# M10 asks for "at least one weather-conditioned spawn".
	var conditions: Dictionary = _weather().get("spawn_conditions", {})
	var gated: Array = []
	for id: String in conditions.keys():
		if id.begins_with("_"):
			continue
		if (conditions[id] as Dictionary).has("weather"):
			gated.append(id)
	assert_true(gated.size() >= 1, "at least one species depends on the weather")


func test_every_weather_of_section_24_exists() -> void:
	# clear, cloudy, rain, thunderstorms, fog.
	var states: Array = _named(_weather().get("states", {}))
	for required in ["clear", "cloudy", "rain", "storm", "fog"]:
		assert_true(states.has(required), "§24 names %s" % required)


# --- the two config files have to agree ------------------------------------


func test_every_weather_state_has_a_look_and_every_look_has_a_state() -> void:
	var behaviour: Array = _named(_weather().get("states", {}))
	var looks: Array = _named(_art().get("weather", {}))
	for id: String in behaviour:
		assert_true(looks.has(id), "weather.json's '%s' has no look in art.json" % id)
	for id: String in looks:
		assert_true(behaviour.has(id), "art.json's '%s' look has no state in weather.json" % id)


func test_every_spawn_condition_names_a_phase_and_a_weather_that_exist() -> void:
	var phases: Array = _named(_weather().get("phases", {}))
	var states: Array = _named(_weather().get("states", {}))
	var conditions: Dictionary = _weather().get("spawn_conditions", {})
	for id: String in conditions.keys():
		if id.begins_with("_"):
			continue
		var block: Dictionary = conditions[id]
		for phase: String in block.get("phases", []):
			assert_true(phases.has(phase), "'%s' waits for a phase called '%s'" % [id, phase])
		for state: String in block.get("weather", []):
			assert_true(states.has(state), "'%s' waits for a weather called '%s'" % [id, state])


func test_every_spawn_condition_names_a_real_species() -> void:
	# A typo here is a condition that never fires, on a creature that then
	# spawns at every hour — which looks exactly like the feature not existing.
	var roster: Dictionary = _json(SPECIES_TABLE).get("species", {})
	for id: String in (_weather().get("spawn_conditions", {}) as Dictionary).keys():
		if id.begins_with("_"):
			continue
		assert_true(roster.has(id), "spawn_conditions names '%s', which is not in species.json" % id)


func test_every_phase_has_a_weight_table() -> void:
	var phases: Array = _named(_weather().get("phases", {}))
	var weights: Dictionary = _weather().get("schedule", {}).get("weights", {})
	for phase: String in phases:
		assert_true(weights.has(phase), "no weather weights for '%s'" % phase)
		var table: Dictionary = weights[phase]
		var total := 0.0
		for key: String in table.keys():
			if not key.begins_with("_"):
				total += float(table[key])
		assert_true(total > 0.0, "'%s' can never choose any weather" % phase)


func test_every_named_hour_states_where_it_sits_on_the_clock() -> void:
	var times: Dictionary = _art().get("times", {})
	var hours: Array = []
	for name: String in times.keys():
		if name.begins_with("_"):
			continue
		var block: Dictionary = times[name]
		assert_true(block.has("at_hour"), "'%s' has no at_hour, so the cycle cannot place it" % name)
		var at := float(block.get("at_hour", -1.0))
		assert_between(at, 0.0, 24.0, "'%s' sits on the clock" % name)
		assert_false(hours.has(at), "two named hours both claim %.2f" % at)
		hours.append(at)
	assert_true(hours.size() >= 4, "a cycle needs a night, a dawn, a day and a dusk")


func test_every_sky_panorama_named_anywhere_exists() -> void:
	# The cross-fading sky shader needs all three of its textures. When one is
	# missing world_look falls back to a snapping single-texture sky, which
	# looks nearly right in a still and cannot fade at all — the exact class of
	# defect D18 is about, so it is checked rather than trusted.
	var art := _art()
	var paths: Array = []
	var base: Dictionary = art.get("sky", {})
	paths.append(str(base.get("panorama", "")))
	paths.append(str(base.get("overcast_panorama", "")))
	for name: String in (art.get("times", {}) as Dictionary).keys():
		if name.begins_with("_"):
			continue
		var sky: Dictionary = (art["times"][name] as Dictionary).get("sky", {})
		if sky.has("panorama"):
			paths.append(str(sky["panorama"]))
	for path: String in paths:
		assert_true(path != "", "a sky entry names no panorama at all")
		assert_true(ResourceLoader.exists(path), "sky panorama is missing: %s" % path)


func test_the_day_starts_in_the_light_MA_05_asked_for() -> void:
	# MA-05's recommendation was to ship golden hour as the default look. With a
	# cycle that is a scheduling decision, and this is where it is made: the
	# clock starts in the late afternoon so a session OPENS in that light.
	var clock: Dictionary = _weather().get("clock", {})
	var start := float(clock.get("start_hour", -1.0))
	var phases: Dictionary = _weather().get("phases", {})
	assert_eq(CYCLE.phase_at(phases, start), "dusk",
		"the game opens at %.1f, which should be the golden end of the day" % start)
	assert_true(float(clock.get("minutes_per_day", 0.0)) > 0.0, "a day has to take some time")
