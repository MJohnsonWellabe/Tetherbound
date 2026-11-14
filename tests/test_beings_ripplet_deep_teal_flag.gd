extends "res://tests/test_case.gd"

## BEINGS-RIPPLET-DEEP (F39#19): creature_coat_flags.json
## `beings_ripplet_deep_teal`, OFF until GPU-judged. Ripplet's own teal fur goes
## a deeper sea-teal with sharper grain; the cream and glow marks are kept.

const FLAGS_PATH := "res://data/config/creature_coat_flags.json"
const FLAG := "beings_ripplet_deep_teal"
const KEY := "res://assets/creatures/tetherbound/ripplet/candidate_owner1101/models/creature_ripplet_owner1101_Image_0.jpg"


func _entry() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_coat_flags.json parses")
	return ((parsed as Dictionary).get("flags", {}) as Dictionary).get(FLAG, {})


func test_flag_is_off_scoped_and_keys_ripplet_only() -> void:
	var entry := _entry()
	assert_false(entry.is_empty(), "%s exists" % FLAG)
	assert_false(bool(entry.get("enabled", true)), "%s is OFF until GPU-judged" % FLAG)
	assert_true(str(entry.get("scope", "")).contains("no state"), "presentation-only scope")
	var coats: Dictionary = entry.get("coats", {})
	assert_eq(coats.keys(), [KEY], "Ripplet's live albedo only")
	var coat: Dictionary = coats[KEY]
	assert_true(ResourceLoader.exists(str(coat.get("albedo", ""))), "the deep-teal albedo is imported")
	assert_true(float(coat.get("roughness", 0.0)) >= 0.9, "matte")
	assert_true(float(coat.get("specular", 1.0)) <= 0.25, "low specular")


func test_the_coat_is_darker_and_keeps_its_hue() -> void:
	var coat: Dictionary = (_entry().get("coats", {}) as Dictionary).get(KEY, {})
	var stats := func(path: String) -> Vector2:
		var image := (load(path) as Texture2D).get_image()
		if image.is_compressed():
			image.decompress()
		var value := 0.0
		var teal := 0
		var count := 0
		for y in range(0, image.get_height(), 16):
			for x in range(0, image.get_width(), 16):
				var c := image.get_pixel(x, y)
				value += c.v
				count += 1
				if c.s > 0.18 and c.h * 360.0 > 160.0 and c.h * 360.0 < 205.0:
					teal += 1
		return Vector2(value / float(count), float(teal) / float(count))
	var before: Vector2 = stats.call(KEY)
	var after: Vector2 = stats.call(str(coat.get("albedo", "")))
	assert_true(after.x < before.x - 0.03, "the coat is darker (%.3f -> %.3f)" % [before.x, after.x])
	assert_true(absf(after.y - before.y) < 0.08, "the teal share is kept (%.2f -> %.2f)" % [before.y, after.y])
