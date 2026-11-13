extends "res://tests/test_case.gd"

## BEINGS-STATICUB-COOL: creature_coat_flags.json `beings_staticub_cool_veins`,
## OFF until GPU-judged. Staticub's shipped storm coat moves toward Stormursa's
## purple-brown (more blue, less red, never red) and the r10 vein glow map lights.
## The flag sits after below6_staticub_storm_fur so its albedo wins when ON.

const FLAGS_PATH := "res://data/config/creature_coat_flags.json"
const FLAG := "beings_staticub_cool_veins"
const BASE := "res://assets/creatures/tetherbound/staticub/candidate_r10/models/creature_staticub_r10_"
const KEY := BASE + "Image_0.jpg"
const STORM := BASE + "Image_0_storm.png"


func _flags() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_coat_flags.json parses")
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


func test_flag_is_off_scoped_and_keys_staticub_only() -> void:
	var flags := _flags()
	var entry: Dictionary = flags.get(FLAG, {})
	assert_false(entry.is_empty(), "%s exists" % FLAG)
	assert_false(bool(entry.get("enabled", true)), "%s is OFF until GPU-judged" % FLAG)
	assert_true(str(entry.get("scope", "")).contains("no state"), "presentation-only scope")
	var coats: Dictionary = entry.get("coats", {})
	assert_eq(coats.keys(), [KEY], "Staticub's r10 albedo only")
	var coat: Dictionary = coats[KEY]
	assert_true(ResourceLoader.exists(str(coat.get("albedo", ""))), "the cool albedo is imported")
	assert_eq(str(coat.get("emission", "")), BASE + "glow_read.png", "the model's own vein glow map")
	assert_true(float(coat.get("emission_energy", 0.0)) > 0.0, "the veins emit")
	var keys := flags.keys()
	assert_true(keys.find(FLAG) > keys.find("below6_staticub_storm_fur"), "it overrides the storm coat when ON")


func test_the_coat_is_cooler_than_the_storm_coat_and_never_red() -> void:
	var coat: Dictionary = (_flags().get(FLAG, {}).get("coats", {}) as Dictionary).get(KEY, {})
	var mean := func(path: String) -> Color:
		var image := (load(path) as Texture2D).get_image()
		if image.is_compressed():
			image.decompress()
		var sum := Color(0, 0, 0)
		var count := 0
		for y in range(0, image.get_height(), 16):
			for x in range(0, image.get_width(), 16):
				var c := image.get_pixel(x, y)
				sum.r += c.r
				sum.g += c.g
				sum.b += c.b
				count += 1
		return Color(sum.r / count, sum.g / count, sum.b / count)
	var before: Color = mean.call(STORM)
	var after: Color = mean.call(str(coat.get("albedo", "")))
	assert_true(after.b > before.b + 0.03, "more blue (%.3f -> %.3f)" % [before.b, after.b])
	assert_true(after.r < before.r, "less red (%.3f -> %.3f)" % [before.r, after.r])
	assert_true(after.r - after.g < before.r - before.g, "the coat moves away from red, not toward it")
