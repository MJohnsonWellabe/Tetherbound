extends "res://tests/test_case.gd"

## BEINGS-STORMRAVEN-ARCS (F41#13, F36#74): creature_coat_flags.json
## `beings_stormraven_arcs`, OFF until GPU-judged. Branching white-violet
## bolts along the folded wings replace the speckle glow on the shipped night
## coat; finish values match the night coat.

const FLAGS_PATH := "res://data/config/creature_coat_flags.json"
const FLAG := "beings_stormraven_arcs"
const NIGHT := "below6_stormraven_night"
const KEY := "res://assets/creatures/tetherbound/stormraven/candidate_owner1101/models/creature_stormraven_owner1101_Image_0.jpg"


func _flags() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_coat_flags.json parses")
	return (parsed as Dictionary).get("flags", {}) if parsed is Dictionary else {}


func test_flag_is_off_scoped_and_after_the_night_coat() -> void:
	var flags := _flags()
	var entry: Dictionary = flags.get(FLAG, {})
	assert_false(entry.is_empty(), "%s exists" % FLAG)
	assert_false(bool(entry.get("enabled", true)), "%s is OFF until GPU-judged" % FLAG)
	assert_true(str(entry.get("scope", "")).contains("no state"), "presentation-only scope")
	assert_true(flags.keys().find(FLAG) > flags.keys().find(NIGHT), "file order: it overrides the night coat when on")
	assert_eq((entry.get("coats", {}) as Dictionary).keys(), [KEY], "Stormraven's albedo only")


func test_finish_matches_the_shipped_night_coat() -> void:
	var flags := _flags()
	var arcs: Dictionary = ((flags.get(FLAG, {}) as Dictionary).get("coats", {}) as Dictionary).get(KEY, {})
	var night: Dictionary = ((flags.get(NIGHT, {}) as Dictionary).get("coats", {}) as Dictionary).get(KEY, {})
	for key: String in ["emission_energy", "rim", "rim_tint", "roughness", "specular"]:
		assert_eq(float(arcs.get(key, -1.0)), float(night.get(key, -2.0)), "%s matches the night coat" % key)
	for key: String in ["albedo", "emission"]:
		assert_true(ResourceLoader.exists(str(arcs.get(key, ""))), "%s texture is imported" % key)


func test_the_glow_is_white_violet_never_red() -> void:
	var arcs: Dictionary = ((_flags().get(FLAG, {}) as Dictionary).get("coats", {}) as Dictionary).get(KEY, {})
	var image := (load(str(arcs.get("emission", ""))) as Texture2D).get_image()
	if image.is_compressed():
		image.decompress()
	var lit := 0
	var red := 0
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var c := image.get_pixel(x, y)
			if c.v < 0.3:
				continue
			lit += 1
			if c.r > c.b + 0.05:
				red += 1
	assert_true(lit > 0, "the bolts glow")
	assert_eq(red, 0, "every lit texel is blue to white-violet (blue at least red)")
