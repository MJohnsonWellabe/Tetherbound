extends "res://tests/test_case.gd"

## BEINGS-MONITOR-VALUE (F36#50, F36#92): creature_coat_flags.json
## `beings_monitor_value_lift`, OFF until GPU-judged. Value-lifted copies of
## the albedos both Mangrove Monitor forms show today; hue kept.

const BODY := preload("res://scripts/creatures/creature_body.gd")
const FLAGS_PATH := "res://data/config/creature_coat_flags.json"
const FLAG := "beings_monitor_value_lift"
const ROOT := "res://assets/creatures/tetherbound/mangrove_monitor/"
const LAND_KEY := ROOT + "candidate_r9/models/creature_mangrove_monitor_r9_Image_0.jpg"
const LAND_LIVE := ROOT + "candidate_r9/models/creature_mangrove_monitor_r9_Image_0_olive.jpg"
const WATER_KEY := ROOT + "models/mangrove_monitor_extracted_base_color_vivid.png"


func _flags() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_coat_flags.json parses")
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


func test_flag_is_off_and_keys_both_forms() -> void:
	var entry: Dictionary = _flags().get(FLAG, {})
	assert_false(entry.is_empty(), "%s exists" % FLAG)
	assert_false(bool(entry.get("enabled", true)), "%s is OFF until GPU-judged" % FLAG)
	assert_true(str(entry.get("scope", "")).contains("no state"), "presentation-only scope")
	var coats: Dictionary = entry.get("coats", {})
	assert_eq(coats.size(), 2, "one coat per form")
	for key: String in [LAND_KEY, WATER_KEY]:
		var coat: Dictionary = coats.get(key, {})
		assert_true(ResourceLoader.exists(str(coat.get("albedo", ""))), "%s has an imported lift" % key.get_file())
		assert_eq(coat.keys(), ["albedo"], "only the albedo changes; finish values are inherited")


func test_the_land_lift_sits_after_the_shipped_olive_coat() -> void:
	var names := _flags().keys()
	assert_true(names.find(FLAG) > names.find("creatures_ralph_mangrove_monitor_r9_olive"),
		"file order: the lift overrides the olive albedo it was graded from")


func _mean_value_and_hue(path: String) -> Vector2:
	var image := (load(path) as Texture2D).get_image()
	if image.is_compressed():
		image.decompress()
	var value := 0.0
	var hue_x := 0.0
	var hue_y := 0.0
	var count := 0
	for y in range(0, image.get_height(), 16):
		for x in range(0, image.get_width(), 16):
			var c := image.get_pixel(x, y)
			value += c.v
			if c.s > 0.15 and c.v > 0.1:
				hue_x += cos(c.h * TAU)
				hue_y += sin(c.h * TAU)
			count += 1
	return Vector2(value / float(count), fposmod(atan2(hue_y, hue_x) / TAU, 1.0))


func test_each_lift_is_lighter_and_keeps_its_hue() -> void:
	var coats: Dictionary = (_flags().get(FLAG, {}) as Dictionary).get("coats", {})
	for pair: Array in [[LAND_LIVE, LAND_KEY], [WATER_KEY, WATER_KEY]]:
		var before := _mean_value_and_hue(pair[0])
		var after := _mean_value_and_hue(str((coats.get(pair[1], {}) as Dictionary).get("albedo", "")))
		assert_true(after.x > before.x + 0.03, "%s is lighter (%.3f -> %.3f)" % [str(pair[0]).get_file(), before.x, after.x])
		var drift := absf(after.y - before.y)
		assert_true(minf(drift, 1.0 - drift) < 0.03, "mean hue is kept (%.3f -> %.3f)" % [before.y, after.y])
		# Green and olive, never the reserved red: mean hue stays between yellow and cyan.
		assert_true(after.y > 0.10 and after.y < 0.55, "mean hue %.3f is in the green band" % after.y)
