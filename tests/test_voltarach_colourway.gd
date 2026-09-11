extends "res://tests/test_case.gd"

const POLICY := "res://data/creatures/four_biome_colourways.json"
const ORDINARY := "res://assets/creatures/tetherbound/voltarach/models/voltarach_extracted_base_color_vivid.png"
const ALPHA := "res://assets/creatures/tetherbound/voltarach/models/voltarach_extracted_base_color_alpha.png"


func test_ordinary_policy_preserves_source_regions_while_alpha_stays_authored() -> void:
	var file := FileAccess.open(POLICY, FileAccess.READ)
	assert_true(file != null)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary)
	if not parsed is Dictionary:
		return
	var rule: Dictionary = (parsed as Dictionary).get("species", {}).get("voltarach", {})
	var vivid: Array = rule.get("vivid_rules", [])
	assert_eq(vivid.size(), 1, "ordinary Voltarach has one identity repaint rule")
	if vivid.size() == 1:
		assert_eq((vivid[0] as Dictionary).get("match", {}), {})
		assert_almost_eq(float((vivid[0] as Dictionary).get("sat_scale", 0.0)), 1.0)
	assert_eq(int((rule.get("finish", {}) as Dictionary).get("feature_percentile", -1)), 0)
	assert_between(float((rule.get("finish", {}) as Dictionary).get("sat_ceiling", 1.0)), 0.5, 0.6)
	assert_eq((rule.get("alpha_rules", []) as Array).size(), 3,
		"the retained indigo alpha remains separately authored")


func test_outputs_are_board_palette_not_magenta_duplicates() -> void:
	var ordinary := _colour_shares(ORDINARY)
	var alpha := _colour_shares(ALPHA)
	assert_false(ordinary.is_empty(), "ordinary texture loads")
	assert_false(alpha.is_empty(), "alpha texture loads")
	if ordinary.is_empty() or alpha.is_empty():
		return
	assert_between(float(ordinary.magenta), 0.0, 0.005,
		"ordinary no longer collapses into the rejected hot-magenta mass")
	assert_between(float(ordinary.warm), 0.40, 0.70,
		"ordinary retains broad amber/gold shell planes")
	assert_between(float(ordinary.dark), 0.45, 0.75,
		"ordinary retains the board's charcoal mass")
	assert_between(float(alpha.violet), 0.80, 0.99,
		"alpha retains its storm-indigo presentation")
	assert_between(float(alpha.warm), 0.0, 0.005,
		"ordinary and alpha do not collapse to the same palette")


func _colour_shares(path: String) -> Dictionary:
	var texture := load(path) as Texture2D
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		return {}
	if image.is_compressed() and image.decompress() != OK:
		return {}
	var counts := {"samples": 0, "magenta": 0, "warm": 0, "violet": 0, "dark": 0}
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var colour := image.get_pixel(x, y)
			counts.samples += 1
			var hue := colour.h * 360.0
			if hue >= 300.0 and hue <= 345.0 and colour.s > 0.45:
				counts.magenta += 1
			if hue >= 20.0 and hue <= 55.0 and colour.s > 0.2 and colour.v > 0.2:
				counts.warm += 1
			if hue >= 235.0 and hue <= 270.0 and colour.s > 0.35:
				counts.violet += 1
			if colour.v < 0.30:
				counts.dark += 1
	var total := maxf(float(counts.samples), 1.0)
	return {
		"magenta": float(counts.magenta) / total,
		"warm": float(counts.warm) / total,
		"violet": float(counts.violet) / total,
		"dark": float(counts.dark) / total,
	}
