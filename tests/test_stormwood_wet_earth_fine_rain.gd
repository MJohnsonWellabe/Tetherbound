extends "res://tests/test_case.gd"

## Stormwood big swing (LANE-MESHY): `wet_earth_1110` (ground finish) and
## `fine_rain_1110` (surge presentation). Both ship ON with the groves (GPU 10 Nov).

const ZONES := preload("res://scripts/world/stormwood_ground_zones.gd")
const RULES := preload("res://scripts/world/stormwood_surge_rules.gd")


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_both_arms_ship_on_and_are_wired() -> void:
	var finish := _json("res://data/config/stormwood_ground_finish.json")
	var surge := _json("res://data/config/stormwood_surge.json")
	assert_true(bool(finish.wet_earth_1110.get("enabled", false)), "wet_earth_1110 ships ON")
	assert_true(bool(surge.presentation.fine_rain_1110.get("enabled", false)), "fine_rain_1110 ships ON")
	assert_true("wet_earth_1110" in ZONES.FINISH_CANDIDATES, "wet earth merges last in the finish")
	assert_true("fine_rain_1110" in RULES.PRESENTATION_CANDIDATES, "fine rain merges after soft_rain_1101")
	assert_true(RULES.PRESENTATION_CANDIDATES.find("fine_rain_1110") > RULES.PRESENTATION_CANDIDATES.find("soft_rain_1101"))


func test_wet_earth_values_lift_the_black_planes() -> void:
	var arm: Dictionary = _json("res://data/config/stormwood_ground_finish.json").wet_earth_1110
	var path := Color(str(arm.terrain_materials.textures.path.tint))
	assert_true(path.get_luminance() > Color("#6e6a5e").get_luminance(), "path lighter than path_loam_1104")
	assert_true(path.g >= path.r, "path tint leans olive against the warm wet_earth texture")
	assert_true(Color(str(arm.ground_zones.pool_colour)).get_luminance() > Color("#07090b").get_luminance() * 3.0, "pools no longer near-black")
	for key2: String in ["pool_colour", "soil_colour"]:
		var c2 := Color(str(arm.ground_zones[key2]))
		assert_true(c2.g >= c2.r, "%s leans olive, not salmon (green >= red)" % key2)
	assert_true(float(arm.ground_zones.pool[1]) - float(arm.ground_zones.pool[0]) > 0.1, "feathered pool edges")
	assert_true(float(arm.ground_zones.pool_roughness) > 0.38, "satin, not gloss")
	for key: String in ["pool_colour", "soil_colour"]:
		var c := Color(str(arm.ground_zones[key]))
		assert_false(c.r > c.g + 0.15 and c.r > c.b + 0.15, "%s is not red/oxblood" % key)


func test_fine_rain_overlay_thins_the_near_streaks_when_on() -> void:
	var surge := _json("res://data/config/stormwood_surge.json")
	surge.presentation.fine_rain_1110.enabled = true
	var rain: Dictionary = RULES.with_presentation_candidates(surge).presentation.rain
	assert_almost_eq(float(rain.streak_width_m), 0.03, 0.0001, "thinner than soft_rain_1101's 0.07")
	assert_almost_eq(float(rain.scale_max), 1.0, 0.0001)
	assert_eq(rain.near_fade_m, [4.0, 8.0])
	assert_true(rain.has("far_layer"), "far layer left in place")
