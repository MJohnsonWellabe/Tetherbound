extends "res://tests/test_case.gd"

## F40#19 rain (LANE-MESHY): world-look weather keys for a closed storm deck
## and low height mist, and the Cloudreach rain_storm_sky arm that uses them
## (OFF until judged on the GPU).

const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const CLOUDREACH_WEATHER := preload("res://scripts/world/cloudreach_weather.gd")


func _look(weather: Dictionary) -> Node:
	var look: Node = WORLD_LOOK.new()
	look.set("_weather", weather)
	return look


func test_storm_sky_keys_close_the_cloud_deck() -> void:
	var look := _look({"sky": {"cloud_coverage": 0.86, "cloud_sharpness": 1.4}})
	var sky := {"cloud_coverage": 0.36}
	look.call("_layer_weather", {}, sky, {})
	assert_almost_eq(float(sky.cloud_coverage), 0.86, 0.0001, "storm coverage replaces the time of day's")
	assert_almost_eq(float(sky.cloud_sharpness), 1.4, 0.0001, "storm sharpness applies")
	look.free()


func test_storm_sky_keys_leave_a_cloudless_sky_alone() -> void:
	var look := _look({"sky": {"cloud_coverage": 0.86}})
	var sky := {}
	look.call("_layer_weather", {}, sky, {})
	assert_false(sky.has("cloud_coverage"), "a gradient sky stays a gradient sky")
	look.free()


func test_height_mist_keys_reach_the_environment_config() -> void:
	var look := _look({"environment": {"fog_height_m": 151.5, "fog_height_density": 0.08}})
	var env := {}
	look.call("_layer_weather", {}, {}, env)
	assert_almost_eq(float(env.weather_fog_height_m), 151.5, 0.0001)
	assert_almost_eq(float(env.weather_fog_height_density), 0.08, 0.0001)
	look.free()


func test_no_weather_mist_without_the_keys() -> void:
	var look := _look({"environment": {"fog_density_add": 0.008}})
	var env := {}
	look.call("_layer_weather", {}, {}, env)
	assert_false(env.has("weather_fog_height_density"), "rain without the mist keys adds no height fog")
	look.free()


func test_rain_storm_sky_ships_on_as_sky_only() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))
	var arm: Dictionary = cfg.weather_arms.rain_storm_sky
	assert_true(bool(arm.get("enabled", false)), "ships ON (GPU sky-only +0.44, 3/3)")
	assert_true(str(arm.get("_why_on", "")).contains("a7a8d1fb3"), "records the GPU verdict")
	var rain: Dictionary = arm.presets.rain
	assert_true(float(rain.sky.cloud_coverage) > 0.8, "the arm closes the deck")
	assert_false(rain.has("environment"), "no environment keys: the judged-losing mist does not ship")
	assert_eq(arm.get("scenes"), ["cloudreach_cliffs"], "Cloudreach only (Tidewake reuses this weather script)")
	var cloudreach: Dictionary = CLOUDREACH_WEATHER.realm_preset("rain", {"sky": {}, "environment": {}}, "cloudreach_cliffs")
	assert_almost_eq(float(cloudreach.sky.cloud_coverage), 0.86, 0.0001, "Cloudreach rain closes the deck")
	assert_false((cloudreach.environment as Dictionary).has("fog_height_density"), "no height mist in real play")
	assert_false((cloudreach.environment as Dictionary).has("fog_height_above_ground_m"), "no mist ceiling in real play")
	for scene: String in ["water_archipelago", ""]:
		var other: Dictionary = CLOUDREACH_WEATHER.realm_preset("rain", {"sky": {}, "environment": {}}, scene)
		assert_false((other.sky as Dictionary).has("cloud_coverage"), "%s rain unchanged" % (scene if scene != "" else "unscoped"))


func test_relative_mist_follows_the_ground_floor() -> void:
	var look := _look({"environment": {"fog_height_above_ground_m": 1.0, "fog_height_density": 0.08}})
	var env := {}
	look.call("_layer_weather", {}, {}, env)
	assert_almost_eq(float(env.weather_fog_height_above_ground_m), 1.0, 0.0001)
	look.set("_weather_fog_above_ground", 1.0)
	assert_true(float(look.call("_weather_fog_ceiling", 0.0)) < -1000.0, "no ground reading yet: no mist")
	look.set("_weather_fog_floor_y", 109.5)
	assert_almost_eq(float(look.call("_weather_fog_ceiling", 0.0)), 110.5, 0.0001, "1 m above the ground")
	look.set("_weather_height_fog_on", true)
	assert_true(bool(look.call("weather_fog_follows_ground")))
	look.free()


func test_absolute_mist_keeps_its_world_height() -> void:
	var look := _look({})
	assert_almost_eq(float(look.call("_weather_fog_ceiling", 42.0)), 42.0, 0.0001)
	assert_false(bool(look.call("weather_fog_follows_ground")), "no weather mist, nothing follows")
	look.free()


func test_scene_scoped_arms_skip_other_scenes() -> void:
	# Every shipped ON arm without `scenes` still applies with or without a scene id.
	var plain: Dictionary = CLOUDREACH_WEATHER.realm_preset("rain", {"sky": {}, "environment": {}})
	var tidewake: Dictionary = CLOUDREACH_WEATHER.realm_preset("rain", {"sky": {}, "environment": {}}, "water_archipelago")
	assert_eq(plain, tidewake, "unscoped arms are unchanged by the scene id")
