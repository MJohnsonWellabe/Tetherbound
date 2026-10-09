extends "res://tests/test_case.gd"

## VIS audit (ralph/reports/VISUAL/AUDIT.md): the sky shader draws
## `colour * sky_energy`, so fog must be scaled by the same energy or distant
## geometry fades to a colour brighter than the sky it meets. Measured before
## the fix at Meadows 23:00: fogged ranges #6080b0 against a #263f6c sky.

const WORLD_LOOK := preload("res://scripts/world/world_look.gd")


func test_cloudreach_rain_retains_night_colours_and_its_weather_energy_and_density() -> void:
	var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
	var overlay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_look.json"))
	var weather: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/weather.json"))
	var look: Node = WORLD_LOOK.new()
	look.set("_config", WORLD_LOOK.merged_look(art, overlay))
	look.set("_weather", weather.presets.rain)
	var sun: Dictionary = art.times.night.sun.duplicate(true)
	var sky: Dictionary = art.times.night.sky.duplicate(true)
	var env: Dictionary = art.times.night.environment.duplicate(true)
	look.call("_layer_weather", sun, sky, env, 1.0)
	assert_eq(sky.top_colour, Color(str(art.times.night.sky.top_colour)))
	assert_eq(sky.horizon_colour, Color(str(art.times.night.sky.horizon_colour)))
	assert_eq(env.ambient_colour, Color(str(art.times.night.environment.ambient_colour)))
	assert_almost_eq(float(sun.energy), float(art.times.night.sun.energy) * float(weather.presets.rain.sun.energy_mult))
	assert_almost_eq(float(env.ambient_energy), float(art.times.night.environment.ambient_energy) * float(weather.presets.rain.environment.ambient_energy_mult))
	assert_almost_eq(float(env.fog_density), float(art.times.night.environment.fog_density) + float(weather.presets.rain.environment.fog_density_add))
	assert_eq(sun.shadow_opacity, weather.presets.rain.sun.shadow_opacity)
	assert_eq(env.fog_colour, art.times.night.environment.fog_colour)
	look.free()


func test_weather_palette_is_realm_scoped_and_continuous_at_dawn_and_dusk() -> void:
	var weather: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/weather.json"))
	var look: Node = WORLD_LOOK.new()
	look.set("_weather", weather.presets.rain)
	var sky := {"top_colour": "#1b2d5c"}
	look.call("_layer_weather", {}, sky, {}, 1.0)
	assert_eq(sky.top_colour, weather.presets.rain.sky.top_colour, "other realms retain their original overrides")
	look.set("_config", {"weather_palette": {"preserve_night_colour": true}})
	for weight: float in [0.0, 0.001, 0.5, 0.999, 1.0]:
		sky = {"top_colour": "#1b2d5c"}
		look.call("_layer_weather", {}, sky, {}, weight)
		var observed: Color = sky.top_colour if sky.top_colour is Color else Color(str(sky.top_colour))
		var expected := Color(str(weather.presets.rain.sky.top_colour)).lerp(Color("#1b2d5c"), weight)
		assert_almost_eq(observed.r, expected.r)
		assert_almost_eq(observed.g, expected.g)
		assert_almost_eq(observed.b, expected.b)
	look.free()


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
