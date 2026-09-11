extends "res://tests/test_case.gd"

const POLICY := "res://data/creatures/four_biome_colourways.json"
const TEXTURES := {
	"voltwig": "res://assets/creatures/tetherbound/voltwig/models/voltwig_extracted_base_color_vivid.png",
	"glimmermoth": "res://assets/creatures/tetherbound/glimmermoth/models/glimmermoth_extracted_base_color_vivid.png",
	"stormbrush": "res://assets/creatures/tetherbound/stormbrush/models/stormbrush_extracted_base_color_vivid.png",
	"mosshock": "res://assets/creatures/tetherbound/mosshock/models/mosshock_extracted_base_color_vivid.png",
	"staticub": "res://assets/creatures/tetherbound/staticub/models/staticub_extracted_base_color_vivid.png",
	"tanglevolt": "res://assets/creatures/tetherbound/tanglevolt/models/tanglevolt_extracted_base_color_vivid.png",
	"stormraven": "res://assets/creatures/tetherbound/stormraven/models/stormraven_extracted_base_color_vivid.png",
	"thundertunnel": "res://assets/creatures/tetherbound/thundertunnel/models/thundertunnel_extracted_base_color_vivid.png",
	"fulgocobra": "res://assets/creatures/tetherbound/fulgocobra/models/fulgocobra_extracted_base_color_vivid.png",
}


func test_policy_recovers_source_regions_without_global_hue_flattening() -> void:
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
		assert_eq(int((rule.get("finish", {}) as Dictionary).get("feature_percentile", -1)), 0)
		if id == "mosshock":
			assert_eq(vivid.size(), 3, "Mosshock alone gets an anatomical red/gold-to-moss repaint")
			assert_eq((vivid[2] as Dictionary).get("match", {}), {}, "unmatched Mosshock regions stay authored")
		else:
			assert_eq(vivid.size(), 1, "%s uses one source-preserving rule" % id)
			if vivid.size() == 1:
				assert_eq((vivid[0] as Dictionary).get("match", {}), {})
				assert_almost_eq(float((vivid[0] as Dictionary).get("sat_scale", 0.0)), 1.0)


func test_outputs_cannot_return_to_the_flat_neon_roster() -> void:
	for id: String in TEXTURES:
		var shares := _colour_shares(TEXTURES[id])
		assert_false(shares.is_empty(), "%s texture loads and decompresses" % id)
		if shares.is_empty():
			continue
		assert_between(float(shares.chartreuse), 0.0, 0.12,
			"%s cannot collapse into the former yellow-green mass" % id)
		assert_between(float(shares.cyan), 0.0, 0.18,
			"%s cannot collapse into the former cyan mass" % id)

	var mosshock := _colour_shares(TEXTURES.mosshock)
	assert_between(float(mosshock.moss), 0.34, 0.78,
		"Mosshock's dorsal growth reads moss green rather than lava red or cyan")
	var stormbrush := _colour_shares(TEXTURES.stormbrush)
	assert_between(float(stormbrush.neutral), 0.20, 0.72,
		"Stormbrush retains its dark-and-white badger coat hierarchy")
	var fulgocobra := _colour_shares(TEXTURES.fulgocobra)
	assert_between(float(fulgocobra.dark), 0.30, 0.82,
		"Fulgocobra retains charcoal scales and a cream throat")


func _colour_shares(path: String) -> Dictionary:
	var texture := load(path) as Texture2D
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		return {}
	if image.is_compressed() and image.decompress() != OK:
		return {}
	var counts := {"samples": 0, "neutral": 0, "dark": 0, "moss": 0, "chartreuse": 0, "cyan": 0}
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var colour := image.get_pixel(x, y)
			var hue := colour.h * 360.0
			counts.samples += 1
			if colour.s < 0.25:
				counts.neutral += 1
			if colour.v < 0.42:
				counts.dark += 1
			if hue >= 82.0 and hue <= 135.0 and colour.s > 0.28:
				counts.moss += 1
			if hue >= 55.0 and hue <= 85.0 and colour.s > 0.58 and colour.v > 0.45:
				counts.chartreuse += 1
			if hue >= 165.0 and hue <= 200.0 and colour.s > 0.58:
				counts.cyan += 1
	var total := maxf(float(counts.samples), 1.0)
	return {
		"neutral": float(counts.neutral) / total,
		"dark": float(counts.dark) / total,
		"moss": float(counts.moss) / total,
		"chartreuse": float(counts.chartreuse) / total,
		"cyan": float(counts.cyan) / total,
	}
