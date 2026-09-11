extends "res://tests/test_case.gd"

const POLICY := "res://data/creatures/four_biome_colourways.json"
const TEXTURES := {
	"cannonback": "res://assets/creatures/tetherbound/cannonback/models/cannonback_extracted_base_color_vivid.png",
	"aquaryn": "res://assets/creatures/tetherbound/aquaryn/models/aquaryn_extracted_base_color_vivid.png",
	"tidecoil": "res://assets/creatures/tetherbound/tidecoil/models/tidecoil_extracted_base_color_vivid.png",
	"riverdrake": "res://assets/creatures/tetherbound/riverdrake/models/riverdrake_extracted_base_color_vivid.png",
	"abyssal_guardian": "res://assets/creatures/tetherbound/abyssal_guardian/models/abyssal_guardian_extracted_base_color_vivid.png",
}


func test_policy_preserves_the_water_board_regions() -> void:
	var file := FileAccess.open(POLICY, FileAccess.READ)
	assert_true(file != null)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary)
	if not parsed is Dictionary:
		return
	var species: Dictionary = (parsed as Dictionary).get("species", {})
	for id: String in TEXTURES:
		var rule: Dictionary = species.get(id, {})
		var vivid: Array = rule.get("vivid_rules", [])
		assert_eq(vivid.size(), 1, "%s uses one source-preserving rule" % id)
		if vivid.size() == 1:
			assert_eq((vivid[0] as Dictionary).get("match", {}), {})
			assert_almost_eq(float((vivid[0] as Dictionary).get("sat_scale", 0.0)), 1.0)
		assert_eq(int((rule.get("finish", {}) as Dictionary).get("feature_percentile", -1)), 0)


func test_outputs_keep_blue_cream_and_coral_without_purple_collapse() -> void:
	for id: String in TEXTURES:
		var shares := _colour_shares(TEXTURES[id])
		assert_false(shares.is_empty(), "%s texture loads and decompresses" % id)
		if shares.is_empty():
			continue
		assert_between(float(shares.blue), 0.12, 0.92,
			"%s retains authored blue material regions" % id)
		assert_between(float(shares.neutral), 0.06, 0.72,
			"%s retains cream/white anatomical regions" % id)
		assert_between(float(shares.violet), 0.0, 0.08,
			"%s cannot return to the former fluorescent purple treatment" % id)

	for id: String in ["aquaryn", "tidecoil", "riverdrake"]:
		var shares := _colour_shares(TEXTURES[id])
		assert_between(float(shares.coral), 0.01, 0.28,
			"%s retains coral fin accents from the owner board" % id)


func _colour_shares(path: String) -> Dictionary:
	var texture := load(path) as Texture2D
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		return {}
	if image.is_compressed() and image.decompress() != OK:
		return {}
	var counts := {"samples": 0, "neutral": 0, "blue": 0, "coral": 0, "violet": 0}
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var colour := image.get_pixel(x, y)
			var hue := colour.h * 360.0
			counts.samples += 1
			if colour.s < 0.24 and colour.v > 0.28:
				counts.neutral += 1
			if hue >= 175.0 and hue <= 245.0 and colour.s > 0.24:
				counts.blue += 1
			if (hue <= 25.0 or hue >= 340.0) and colour.s > 0.24:
				counts.coral += 1
			if hue >= 265.0 and hue <= 325.0 and colour.s > 0.58:
				counts.violet += 1
	var total := maxf(float(counts.samples), 1.0)
	return {
		"neutral": float(counts.neutral) / total,
		"blue": float(counts.blue) / total,
		"coral": float(counts.coral) / total,
		"violet": float(counts.violet) / total,
	}
