extends "res://tests/test_case.gd"

const POLICY := "res://data/creatures/four_biome_colourways.json"
const TEXTURES := {
	"craghorn": "res://assets/creatures/tetherbound/craghorn/models/craghorn_extracted_base_color_vivid.png",
	"stormcapra": "res://assets/creatures/tetherbound/stormcapra/models/stormcapra_extracted_base_color_vivid.png",
	"aeriex": "res://assets/creatures/tetherbound/aeriex/models/aeriex_extracted_base_color_vivid.png",
	"ribbonray": "res://assets/creatures/tetherbound/ribbonray/models/ribbonray_extracted_base_color_vivid.png",
	"breezetail": "res://assets/creatures/tetherbound/breezetail/models/breezetail_extracted_base_color_vivid.png",
	"cloudfang": "res://assets/creatures/tetherbound/cloudfang/models/cloudfang_extracted_base_color_vivid.png",
	"cliffspike": "res://assets/creatures/tetherbound/cliffspike/models/cliffspike_extracted_base_color_vivid.png",
	"tempestwing": "res://assets/creatures/tetherbound/tempestwing/models/tempestwing_extracted_base_color_vivid.png",
	"solmane": "res://assets/creatures/tetherbound/solmane/models/solmane_extracted_base_color_vivid.png",
}


func test_policy_preserves_authored_anatomical_regions() -> void:
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
			assert_eq((vivid[0] as Dictionary).get("match", {}), {}, "%s does not flatten selected hues" % id)
			assert_almost_eq(float((vivid[0] as Dictionary).get("sat_scale", 0.0)), 1.0)
		assert_eq(int((rule.get("finish", {}) as Dictionary).get("feature_percentile", -1)), 0,
			"%s does not restamp atlas noise as facial features" % id)


func test_outputs_reject_the_previous_neon_collapses() -> void:
	for id: String in TEXTURES:
		var shares := _colour_shares(TEXTURES[id])
		assert_false(shares.is_empty(), "%s ordinary texture loads and decompresses" % id)
		if shares.is_empty():
			continue
		if id != "ribbonray":
			assert_between(float(shares.magenta), 0.0, 0.035,
				"%s cannot return to the flat magenta/violet treatment" % id)
		assert_between(float(shares.neon_yellow), 0.0, 0.02,
			"%s cannot return to the flat neon-yellow treatment" % id)

	var stormcapra := _colour_shares(TEXTURES.stormcapra)
	assert_between(float(stormcapra.neutral), 0.40, 0.72,
		"Stormcapra retains its white and charcoal armour mass")
	assert_between(float(stormcapra.blue), 0.005, 0.16,
		"Stormcapra keeps blue as a sparse crystal accent")

	var craghorn := _colour_shares(TEXTURES.craghorn)
	assert_between(float(craghorn.neutral), 0.58, 0.96,
		"Craghorn retains its white, grey and dark-horn material hierarchy")

	var aeriex := _colour_shares(TEXTURES.aeriex)
	assert_between(float(aeriex.blue), 0.28, 0.72,
		"Aeriex retains its teal flight surfaces")
	assert_between(float(aeriex.coral), 0.04, 0.30,
		"Aeriex retains its coral feather tips")

	var ribbonray := _colour_shares(TEXTURES.ribbonray)
	assert_between(float(ribbonray.blue), 0.08, 0.48,
		"Ribbonray retains blue planes inside the purple ribbon silhouette")
	assert_between(float(ribbonray.magenta), 0.28, 0.82,
		"Ribbonray remains intentionally purple without becoming one flat pink hue")

	var cloudfang := _colour_shares(TEXTURES.cloudfang)
	assert_between(float(cloudfang.neutral), 0.62, 0.98,
		"Cloudfang retains a white mass with pale-blue accents")

	var cliffspike := _colour_shares(TEXTURES.cliffspike)
	assert_between(float(cliffspike.warm), 0.20, 0.72,
		"Cliffspike retains natural tan fur rather than a saturated gold body")
	assert_between(float(cliffspike.blue), 0.025, 0.34,
		"Cliffspike retains cool quill-shadow regions")

	var tempestwing := _colour_shares(TEXTURES.tempestwing)
	assert_between(float(tempestwing.blue), 0.18, 0.68,
		"Tempestwing retains its authored blue body and wing markings")

	var solmane := _colour_shares(TEXTURES.solmane)
	assert_between(float(solmane.warm), 0.40, 0.99,
		"Solmane retains varied cream-gold structure instead of becoming a single yellow mass")


func _colour_shares(path: String) -> Dictionary:
	var texture := load(path) as Texture2D
	var image := texture.get_image() if texture != null else null
	if image == null or image.is_empty():
		return {}
	if image.is_compressed() and image.decompress() != OK:
		return {}
	var counts := {
		"samples": 0, "neutral": 0, "warm": 0, "blue": 0, "coral": 0,
		"magenta": 0, "neon_yellow": 0,
	}
	for y in range(0, image.get_height(), 4):
		for x in range(0, image.get_width(), 4):
			var colour := image.get_pixel(x, y)
			var hue := colour.h * 360.0
			counts.samples += 1
			if colour.s < 0.24:
				counts.neutral += 1
			if hue >= 15.0 and hue <= 50.0 and colour.s >= 0.12 and colour.s <= 0.65 and colour.v > 0.3:
				counts.warm += 1
			if hue >= 175.0 and hue <= 245.0 and colour.s > 0.24:
				counts.blue += 1
			if (hue <= 35.0 or hue >= 345.0) and colour.s > 0.25:
				counts.coral += 1
			if hue >= 275.0 and hue <= 335.0 and colour.s > 0.55:
				counts.magenta += 1
			if hue >= 45.0 and hue <= 75.0 and colour.s > 0.65 and colour.v > 0.65:
				counts.neon_yellow += 1
	var total := maxf(float(counts.samples), 1.0)
	return {
		"neutral": float(counts.neutral) / total,
		"warm": float(counts.warm) / total,
		"blue": float(counts.blue) / total,
		"coral": float(counts.coral) / total,
		"magenta": float(counts.magenta) / total,
		"neon_yellow": float(counts.neon_yellow) / total,
	}
