extends "res://tests/test_case.gd"

## BEINGS-TRAILPUP-AMBER (F36#83): creature_coat_flags.json
## `beings_trailpup_amber`, OFF until GPU-judged. Amber paws and irises on the
## live Trailpup coat (owner pick, 1 Nov 2026). Stormtrail wears its own
## texture and is not keyed.

const FLAGS_PATH := "res://data/config/creature_coat_flags.json"
const FLAG := "beings_trailpup_amber"
const LIVE := "res://assets/creatures/tetherbound/trailpup/candidate_nat1024/models/creature_trailpup_nat1024_Image_0.jpg"


func _entry() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FLAGS_PATH))
	assert_true(parsed is Dictionary, "creature_coat_flags.json parses")
	return ((parsed as Dictionary).get("flags", {}) as Dictionary).get(FLAG, {})


func test_flag_is_off_and_declares_scope() -> void:
	var entry := _entry()
	assert_false(entry.is_empty(), "%s exists" % FLAG)
	assert_false(bool(entry.get("enabled", true)), "%s is OFF until GPU-judged" % FLAG)
	assert_true(str(entry.get("scope", "")).contains("no state"), "presentation-only scope")


func test_it_keys_only_the_live_trailpup_albedo() -> void:
	var coats: Dictionary = _entry().get("coats", {})
	assert_eq(coats.keys(), [LIVE], "one coat, keyed on the live Trailpup albedo (not Stormtrail's)")
	var coat: Dictionary = coats.get(LIVE, {})
	for part: String in ["albedo", "emission"]:
		assert_true(ResourceLoader.exists(str(coat.get(part, ""))), "%s texture is imported" % part)
	var energy := float(coat.get("emission_energy", 0.0))
	assert_true(energy > 0.0 and energy <= 2.0, "glow energy stays modest (%.2f)" % energy)


func test_glow_is_amber_and_small() -> void:
	var coat: Dictionary = (_entry().get("coats", {}) as Dictionary).get(LIVE, {})
	var image := (load(str(coat.get("emission", ""))) as Texture2D).get_image()
	if image.is_compressed():
		image.decompress()
	var lit := 0
	var red_leak := 0
	var step := 4
	var total := 0
	for y in range(0, image.get_height(), step):
		for x in range(0, image.get_width(), step):
			total += 1
			var c := image.get_pixel(x, y)
			if c.r < 0.25:
				continue
			lit += 1
			# Amber, never the reserved red: green stays well above a third of red.
			if c.g < c.r * 0.33:
				red_leak += 1
	assert_true(lit > 0, "the map glows somewhere")
	assert_true(float(lit) / float(total) < 0.12, "glow covers a small part of the texture (%d of %d samples)" % [lit, total])
	assert_eq(red_leak, 0, "no red or oxblood texel in the glow")
