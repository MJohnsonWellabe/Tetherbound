extends "res://tests/test_case.gd"

## tb/cause-tidewake: the sea, light and dunes parts ship OFF; OFF changes
## nothing, and each part ON applies exactly its intended keys.
const PROFILE := preload("res://scripts/world/tidewake_look_profile.gd")


func _raw() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PROFILE.CONFIG))


func _with(parts: Array) -> Dictionary:
	var raw := _raw()
	for part: String in parts:
		raw.cause_tidewake[part].enabled = true
	return PROFILE.resolve(raw)


func test_every_part_ships_off_and_off_changes_nothing() -> void:
	var raw := _raw()
	for part: String in ["sea", "light", "dunes"]:
		assert_false(bool(raw.cause_tidewake[part].enabled), "%s ships off" % part)
	# currents ships ON (tb/vis-tidewake-1104 r1: F39#17 CPU 5.54 -> 6.09); the
	# remaining parts are compared with currents, night and stars on in both profiles.
	assert_true(bool(raw.cause_tidewake.currents.enabled), "currents ships on")
	assert_true(str(raw.cause_tidewake.currents.get("_why_on", "")).contains("6.09"))
	# stars ships ON (look r6: F39#30b CPU 4.77 -> 4.89).
	assert_true(bool(raw.cause_tidewake.stars.enabled), "stars ships on")
	assert_true(str(raw.cause_tidewake.stars.get("_why_on", "")).contains("4.89"))
	# night ships ON (look r8: F39#30b CPU 5.67 -> 6.25).
	assert_true(bool(raw.cause_tidewake.night.enabled), "night ships on")
	assert_true(str(raw.cause_tidewake.night.get("_why_on", "")).contains("6.25"))
	var shipped := PROFILE.resolve(_raw())
	var stripped := _raw()
	var currents: Dictionary = stripped.cause_tidewake.currents
	var stars: Dictionary = stripped.cause_tidewake.stars
	var night: Dictionary = stripped.cause_tidewake.night
	stripped.cause_tidewake = {"currents": currents, "night": night, "stars": stars}
	var expected := PROFILE.resolve(stripped)
	shipped.erase("cause_tidewake")
	expected.erase("cause_tidewake")
	assert_eq(shipped, expected, "off parts leave the in-play profile unchanged")
	assert_false(shipped.has("cause_light_look"))


func test_sea_part_applies_its_water_and_offshore_keys() -> void:
	var on := _with(["sea"])
	var water: Dictionary = on.surfaces.water
	var wanted: Dictionary = _raw().cause_tidewake.sea.merge.surfaces.water
	for key: String in wanted:
		assert_eq(water[key], wanted[key], "sea sets surfaces.water.%s" % key)
	# The shipping surface keys the part does not name survive.
	assert_eq(water.roughness, _raw().surfaces.water.roughness)
	assert_eq(on.offshore.deep_colour, "#0f3f5a")
	assert_eq(on.offshore.specular, _raw().offshore.specular)
	assert_false(on.has("cause_light_look"), "sea does not touch light")


func test_light_part_fills_only_the_day_grade() -> void:
	var on := _with(["light"])
	var look: Dictionary = on.cause_light_look
	assert_eq(look.times.keys(), ["day"], "dawn, golden and night keep their grades")
	assert_eq(on.lighting, PROFILE.resolve(_raw()).lighting, "the shipping lighting section is untouched")


func test_dunes_part_restores_dressing_and_sets_dune_form() -> void:
	var off := PROFILE.resolve(_raw())
	var on := _with(["dunes"])
	# look r13 ships the shore dressing ON, so it is in play with or without dunes.
	for section: String in ["lesson_clusters_candidate", "dune_grass_candidate", "stones_candidate"]:
		assert_true(off.has(section), "%s ships on (look r13)" % section)
		assert_true(on.has(section), "%s stays in play with dunes" % section)
	assert_eq(float(on.dunes.flank_strength), 0.28)
	assert_eq(on.dunes.sand_colour, off.dunes.sand_colour, "sand colour is kept")
	assert_false(on.has("surfaces_candidate"), "unlisted sections stay off")


func test_parts_compose() -> void:
	var on := _with(["sea", "light", "dunes"])
	assert_true(on.has("cause_light_look"))
	assert_true(on.has("lesson_clusters_candidate"))
	assert_eq(float(on.surfaces.water.haze_strength), 0.3)


func test_currents_part_strips_restored_paint() -> void:
	var raw_off := _raw()
	raw_off.cause_tidewake.currents.enabled = false
	var off := PROFILE.resolve(raw_off)
	var on := _with(["currents"])
	assert_true(on.has("current_flow"), "currents brings current_flow into play")
	var restored: Dictionary = on.current_flow.state_shader.restored
	for key: String in ["dash_fill", "streak_density", "comet_opacity", "chevron_opacity", "channel_edge_opacity", "lane_opacity"]:
		assert_eq(float(restored[key]), 0.0, "restored %s is off" % key)
	# The live look is current_flow's own, unchanged.
	assert_eq(on.current_flow.state_shader.live, _raw().current_flow.state_shader.live)
	if not off.has("current_flow"):
		assert_false(_with(["sea"]).has("current_flow"), "only currents restores current_flow")


func test_horizon_part_adds_props_only_when_on() -> void:
	assert_false(PROFILE.resolve(_raw()).has("cause_horizon_props"))
	var props: Array = _with(["horizon"]).cause_horizon_props
	assert_true(props.size() >= 10)
	for spec: Dictionary in props:
		assert_true(spec.has("float_y_m"), "%s sits on the sea, not the seabed" % spec.id)
		assert_false(spec.has("collider_fraction"), "%s has no collider" % spec.id)
