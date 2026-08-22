extends "res://tests/test_case.gd"

## OP21-21 regression: the washed-out grey weather state.
##
## world_weather.gd rolled a UNIFORM random pick across clear/cloudy/fog/rain
## every 240-480 real seconds, and three of those four presets pushed the sky
## toward near-white grey -- cloudy/fog/rain measured 2-13% HSV saturation on
## their sky/ambient/fog colours (near-neutral grey) against clear's ~68%
## whole-frame mean saturation, so on that timer the game read as "washed out
## and broken" 75% of the time. Root-caused and fixed by:
##   1. retuning cloudy/fog/rain's sky/ambient/fog colours toward a more
##      saturated blue-grey (measured via tools/frame_stats.py against
##      rendered tools/capture_weather.gd frames -- see the `_comment`
##      entries in data/config/weather.json for the before/after numbers);
##   2. weighting the weather roll toward "clear" instead of picking
##      uniformly across all four presets;
##   3. capping how many cycles in a row can land away from "clear"
##      (`max_consecutive_non_clear`).
##
## This file is the regression for all three: (1) a colour-saturation floor
## on every preset's sky/ambient/fog colours, checked directly against
## data/config/weather.json rather than a rendered frame, so a future preset
## edit that reintroduces a near-white/grey colour fails CI without needing a
## render; (2) an assertion that "clear" is weighted as the single most
## likely preset; (3) behavioural coverage of the roll + streak cap in
## world_weather.gd itself.
##
## Per D02 scope (pure logic only, no scenes/rendering): WorldWeather extends
## Node but nothing exercised here touches the scene tree -- _ready() (which
## builds the rain particle system) is never called because the node is never
## added to a SceneTree; only its data (_config/_presets/_order) and pure
## methods (_load/_pick_next/set_weather) are used, the same way
## test_day_cycle.gd exercises day_cycle.gd's pure math.

const WORLD_WEATHER := preload("res://scripts/world/world_weather.gd")
const WEATHER_JSON_PATH := "res://data/config/weather.json"

## Below this HSV saturation a colour reads as functionally neutral grey.
## The OLD cloudy/fog/rain sky and ambient colours measured 0.023-0.135
## saturation (see the retune comments in weather.json); the retuned values
## measure 0.125-0.294. This floor sits between the two, closer to the old
## broken values, so it fails a regression back toward them while leaving
## real headroom for future retuning.
const MIN_SATURATION := 0.08

## fog_density_add ceiling. The OLD "fog" preset used 0.015 -- already the
## single largest contributor to fog's washed-out read (it was the frame
## with a BRIGHTER near-ground luminance than clear, not just a greyer one).
## The retuned value is 0.007. This cap sits below the old value so a future
## edit cannot silently walk fog_density_add back up past the point that
## caused OP21-21, while leaving room to tune.
const MAX_FOG_DENSITY_ADD := 0.012

var _config: Dictionary = {}
var _presets: Dictionary = {}


func before_each() -> void:
	var file := FileAccess.open(WEATHER_JSON_PATH, FileAccess.READ)
	assert_true(file != null, "weather.json should be readable")
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "weather.json should parse as a JSON object")
	_config = parsed if parsed is Dictionary else {}
	_presets = _config.get("presets", {})


func _preset_names() -> Array[String]:
	var found: Array[String] = []
	for key: String in _presets.keys():
		if not key.begins_with("_"):
			found.append(key)
	return found


func test_weather_json_has_the_four_expected_presets() -> void:
	var names := _preset_names()
	for expected in ["clear", "cloudy", "fog", "rain"]:
		assert_true(names.has(expected), "weather.json should still define '%s'" % expected)


## The core OP21-21 regression: no preset's sky colours may be near-neutral
## grey. Checked against the data directly (no render needed) so this runs
## in the same CI pass as every other pure-logic test.
func test_every_preset_sky_colour_clears_the_saturation_floor() -> void:
	for name in _preset_names():
		var preset: Dictionary = _presets[name]
		var sky: Dictionary = preset.get("sky", {})
		for key: String in ["top_colour", "horizon_colour", "ground_horizon_colour"]:
			if not sky.has(key):
				continue
			var colour := Color(str(sky[key]))
			assert_true(colour.s >= MIN_SATURATION,
				"%s.sky.%s (%s) measures %.3f saturation, below the %.2f floor -- reads as neutral grey"
				% [name, key, sky[key], colour.s, MIN_SATURATION])


## Same regression for the environment layer: ambient_colour and fog_colour
## are the other two places OP21-21 found near-white values (fog's ambient
## was left at default, but its fog_colour was the single greyest value in
## the whole file before the retune).
func test_every_preset_environment_colour_clears_the_saturation_floor() -> void:
	for name in _preset_names():
		var preset: Dictionary = _presets[name]
		var env: Dictionary = preset.get("environment", {})
		for key: String in ["ambient_colour", "fog_colour"]:
			if not env.has(key):
				continue
			var colour := Color(str(env[key]))
			assert_true(colour.s >= MIN_SATURATION,
				"%s.environment.%s (%s) measures %.3f saturation, below the %.2f floor -- reads as neutral grey"
				% [name, key, env[key], colour.s, MIN_SATURATION])


func test_fog_density_add_stays_below_the_whiteout_ceiling() -> void:
	for name in _preset_names():
		var env: Dictionary = _presets[name].get("environment", {})
		if not env.has("fog_density_add"):
			continue
		var value: float = float(env["fog_density_add"])
		assert_true(value <= MAX_FOG_DENSITY_ADD,
			"%s.environment.fog_density_add is %.4f, above the %.4f ceiling that caused OP21-21's fog to read as a brighter, greyer void than clear weather"
			% [name, value, MAX_FOG_DENSITY_ADD])


## "clear" must be the single most likely roll, not tied or beaten by any one
## overcast preset -- the fix for the 75%-of-the-time washed-out complaint was
## weighting toward clear, and a future edit that quietly re-levels the
## weights back toward uniform (or tips the balance to some other preset)
## should fail here rather than being rediscovered by an owner playtest.
func test_clear_is_weighted_as_the_single_most_likely_preset() -> void:
	var clear_weight: float = float(_presets.get("clear", {}).get("weight", 1.0))
	for name in _preset_names():
		if name == "clear":
			continue
		var weight: float = float(_presets[name].get("weight", 1.0))
		assert_true(clear_weight > weight,
			"clear's roll weight (%.2f) should exceed %s's (%.2f) -- clear must stay the plurality weather state"
			% [clear_weight, name, weight])


## Behavioural coverage of world_weather.gd's own _pick_next(), using a small
## synthetic config (not the real weather.json) so this is a deterministic
## test of the ALGORITHM rather than a statistical test of the shipped
## weights. Node is never added to a SceneTree, so _ready()/_process() never
## run -- only the pure methods under test do.
func _make_weather(weights: Dictionary, cap: int) -> Node:
	var weather: Node = WORLD_WEATHER.new()
	var presets := {}
	for key: String in weights.keys():
		presets[key] = {"weight": weights[key]}
	weather.set("_config", {"max_consecutive_non_clear": cap})
	weather.set("_presets", presets)
	var order: Array = []
	for key: String in weights.keys():
		order.append(key)
	weather.set("_order", order)
	return weather


func test_pick_next_never_exceeds_max_consecutive_non_clear() -> void:
	var cap := 2
	var weather := _make_weather({"clear": 1.0, "cloudy": 1.0, "fog": 1.0, "rain": 1.0}, cap)
	var streak := 0
	var worst := 0
	for i in 500:
		var picked: String = weather.call("_pick_next")
		weather.call("set_weather", picked)
		if picked == "clear":
			streak = 0
		else:
			streak += 1
			worst = maxi(worst, streak)
	weather.free()
	assert_true(worst <= cap,
		"longest observed run of consecutive non-clear presets was %d, should never exceed max_consecutive_non_clear=%d"
		% [worst, cap])


func test_pick_next_forces_clear_once_the_cap_is_reached() -> void:
	# Weighted 0 toward clear so the roll itself would never naturally choose
	# it -- isolates the cap's forcing behaviour from the weighting.
	var weather := _make_weather({"clear": 0.0001, "fog": 1.0}, 2)
	weather.set("_consecutive_non_clear", 2)
	var picked: String = weather.call("_pick_next")
	weather.free()
	assert_eq(picked, "clear",
		"once max_consecutive_non_clear cycles have passed without clear, the next pick must be forced to clear regardless of weight")


func test_pick_next_favours_the_higher_weighted_preset_over_many_rolls() -> void:
	# No cap (0 disables it) so this isolates the weighting behaviour.
	var weather := _make_weather({"clear": 9.0, "fog": 1.0}, 0)
	var clear_count := 0
	var total := 2000
	for i in total:
		var picked: String = weather.call("_pick_next")
		weather.call("set_weather", picked)
		if picked == "clear":
			clear_count += 1
	weather.free()
	var share := float(clear_count) / float(total)
	# Expected share is 0.9; a wide tolerance keeps this from being a flaky
	# RNG-seed test while still catching a badly broken weighting function
	# (e.g. one that silently reverts to a uniform pick, which would land
	# near 0.5).
	assert_true(share > 0.75,
		"clear was picked %.1f%% of %d rolls at a 9:1 weight ratio, expected well above 75%%"
		% [share * 100.0, total])
