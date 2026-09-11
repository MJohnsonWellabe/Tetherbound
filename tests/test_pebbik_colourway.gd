extends "res://tests/test_case.gd"

const POLICY := "res://data/creatures/four_biome_colourways.json"
const ORDINARY := "res://assets/creatures/tetherbound/pebbik/models/pebbik_extracted_base_color_vivid.png"


func test_policy_preserves_the_owner_board_regions() -> void:
	var file := FileAccess.open(POLICY, FileAccess.READ)
	assert_true(file != null)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary)
	if not parsed is Dictionary:
		return
	var rule: Dictionary = (parsed as Dictionary).get("species", {}).get("pebbik", {})
	var vivid: Array = rule.get("vivid_rules", [])
	assert_eq(vivid.size(), 1)
	if vivid.size() == 1:
		assert_eq((vivid[0] as Dictionary).get("match", {}), {})
		assert_almost_eq(float((vivid[0] as Dictionary).get("sat_scale", 0.0)), 1.0)
	assert_eq(int((rule.get("finish", {}) as Dictionary).get("feature_percentile", -1)), 0)
	assert_between(float((rule.get("finish", {}) as Dictionary).get("sat_ceiling", 1.0)), 0.55, 0.65)


func test_output_keeps_tan_cream_and_blue_without_neon_yellow() -> void:
	var shares := _colour_shares()
	assert_false(shares.is_empty(), "ordinary texture loads and decompresses")
	if shares.is_empty():
		return
	assert_between(float(shares.warm), 0.35, 0.55,
		"warm tan remains the broad body region")
	assert_between(float(shares.blue), 0.15, 0.30,
		"blue feather tips remain a distinct secondary region")
	assert_between(float(shares.cream), 0.04, 0.12,
		"cream face and chest remain readable")
	assert_between(float(shares.neon_yellow), 0.0, 0.005,
		"the previous neon-yellow collapse cannot return")


func _colour_shares() -> Dictionary:
	var texture := load(ORDINARY) as Texture2D
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		return {}
	if image.is_compressed() and image.decompress() != OK:
		return {}
	var counts := {"samples": 0, "warm": 0, "blue": 0, "cream": 0, "neon_yellow": 0}
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var colour := image.get_pixel(x, y)
			counts.samples += 1
			var hue := colour.h * 360.0
			if hue >= 5.0 and hue <= 45.0 and colour.s > 0.18 and colour.s < 0.7 and colour.v > 0.25:
				counts.warm += 1
			if hue >= 195.0 and hue <= 250.0 and colour.s > 0.35:
				counts.blue += 1
			if colour.s < 0.25 and colour.v > 0.55:
				counts.cream += 1
			if hue >= 45.0 and hue <= 75.0 and colour.s > 0.6 and colour.v > 0.5:
				counts.neon_yellow += 1
	var total := maxf(float(counts.samples), 1.0)
	return {
		"warm": float(counts.warm) / total,
		"blue": float(counts.blue) / total,
		"cream": float(counts.cream) / total,
		"neon_yellow": float(counts.neon_yellow) / total,
	}
