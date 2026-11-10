extends "res://tests/test_case.gd"

## F41#17 bark_grey_1110 (LANE-MESHY): ships ON (GPU, 10 Nov); it keeps Stormwood
## trunks out of the red family (rendered albedo red <= green).

const VEG := preload("res://scripts/world/vegetation.gd")


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_ships_on_and_off_changes_nothing() -> void:
	var look := _json(VEG.STORMWOOD_LOOK_PATH)
	assert_true(bool(look.bark_grey_1110.get("enabled", false)), "bark_grey_1110 ships ON after its judged gain")
	assert_true(str(look.bark_grey_1110.get("_why_on", "")).contains("G-bark-grey-1110"), "the judged gain is recorded")
	look.bark_grey_1110.enabled = false
	var veg := _json("res://data/config/stormwood_vegetation.json")
	var off := VEG.stormwood_foliage_grade(veg, look)
	if not bool(look.foliage_grade_1104.get("enabled", false)):
		assert_true(off.is_empty(), "with both grades OFF nothing changes")


func test_on_bark_albedo_keeps_red_at_or_below_green() -> void:
	var look := _json(VEG.STORMWOOD_LOOK_PATH)
	look.bark_grey_1110.enabled = true
	var veg := _json("res://data/config/stormwood_vegetation.json")
	var on := VEG.stormwood_foliage_grade(veg, look)
	var means := {"Bark_TwistedTree": Color8(84, 76, 72), "Bark_NormalTree": Color8(140, 88, 67)}
	var checked := 0
	for model: String in on.variant_retint:
		var tints: Dictionary = on.variant_retint[model]
		for material: String in means:
			if not tints.has(material):
				continue
			var tex: Color = means[material]
			var sat := float(((on.retexture_adjust.get(model, {}) as Dictionary).get(material, {}) as Dictionary).get("saturation", 1.0))
			var lum := tex.get_luminance()
			tex = Color(lerpf(lum, tex.r, sat), lerpf(lum, tex.g, sat), lerpf(lum, tex.b, sat))
			var albedo := tex * Color(str(tints[material]))
			assert_true(albedo.r <= albedo.g + 0.005, "%s %s albedo red <= green (%s)" % [model.get_file(), material, albedo])
			checked += 1
	assert_true(checked >= 3, "both barks on every canopy model checked (%d)" % checked)
