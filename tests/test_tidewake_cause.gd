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
	var shipped := PROFILE.resolve(_raw())
	var stripped := _raw()
	stripped.erase("cause_tidewake")
	var expected := PROFILE.resolve(stripped)
	shipped.erase("cause_tidewake")
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
	assert_eq(on.offshore.deep_colour, "#15506c")
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
	for section: String in ["dune_grass_candidate", "stones_candidate", "lesson_clusters_candidate"]:
		assert_false(off.has(section), "%s is out of play while dunes is off" % section)
		assert_true(on.has(section), "%s comes into play with dunes" % section)
	assert_eq(float(on.dunes.flank_strength), 0.22)
	assert_eq(on.dunes.sand_colour, off.dunes.sand_colour, "sand colour is kept")
	assert_false(on.has("surfaces_candidate"), "unlisted sections stay off")


func test_parts_compose() -> void:
	var on := _with(["sea", "light", "dunes"])
	assert_true(on.has("cause_light_look"))
	assert_true(on.has("dune_grass_candidate"))
	assert_eq(float(on.surfaces.water.haze_strength), 0.6)
