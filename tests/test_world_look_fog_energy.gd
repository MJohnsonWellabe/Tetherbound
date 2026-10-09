extends "res://tests/test_case.gd"

## VIS audit (ralph/reports/VISUAL/AUDIT.md): the sky shader draws
## `colour * sky_energy`, so fog must be scaled by the same energy or distant
## geometry fades to a colour brighter than the sky it meets. Measured before
## the fix at Meadows 23:00: fogged ranges #6080b0 against a #263f6c sky.

const WORLD_LOOK := preload("res://scripts/world/world_look.gd")


func test_fog_is_scaled_by_a_dimmed_sky() -> void:
	var c: Color = WORLD_LOOK.fog_light_colour({"fog_colour": "#4d6a9e"}, {"energy": 0.75})
	var raw := Color("#4d6a9e")
	assert_almost_eq(c.r, raw.r * 0.75, 0.001)
	assert_almost_eq(c.g, raw.g * 0.75, 0.001)
	assert_almost_eq(c.b, raw.b * 0.75, 0.001)


func test_full_and_brighter_skies_leave_fog_unchanged() -> void:
	var raw := Color("#a6bccb")
	for energy: float in [1.0, 1.3]:
		var c: Color = WORLD_LOOK.fog_light_colour({"fog_colour": "#a6bccb"}, {"energy": energy})
		assert_almost_eq(c.b, raw.b, 0.001, "energy %.1f must not brighten fog" % energy)
	var missing: Color = WORLD_LOOK.fog_light_colour({"fog_colour": raw}, {})
	assert_almost_eq(missing.g, raw.g, 0.001, "a preset without sky energy keeps its fog; Color input accepted")


func test_every_art_preset_fog_on_screen_meets_its_rendered_horizon() -> void:
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	for name: String in (art["times"] as Dictionary).keys():
		var preset: Variant = art["times"][name]
		if not preset is Dictionary or not (preset as Dictionary).has("environment"):
			continue
		var env: Dictionary = (preset as Dictionary).get("environment", {})
		var sky: Dictionary = (preset as Dictionary).get("sky", {})
		if not env.has("fog_colour") or not sky.has("horizon_colour"):
			continue
		var fog: Color = WORLD_LOOK.fog_light_colour(env, sky)
		var horizon := Color(str(sky["horizon_colour"])) * float(sky.get("energy", 1.0))
		assert_true(fog.v <= horizon.v + 0.01,
			"%s: fog on screen (v %.3f) must not be brighter than the sky horizon (v %.3f)" % [name, fog.v, horizon.v])
