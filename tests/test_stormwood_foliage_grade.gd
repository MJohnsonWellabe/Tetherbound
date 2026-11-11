extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026): foliage_grade_1104 recolours the Stormwood
## canopy layers through the variant_retint overlay. It ships OFF (no overlay),
## and ON it covers every model of each graded layer without touching the
## scatter bake input.

const VEGETATION := preload("res://scripts/world/vegetation.gd")


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_foliage_grade_ships_off_and_adds_no_overlay() -> void:
	var look := _json(VEGETATION.STORMWOOD_LOOK_PATH)
	assert_false(bool(look.foliage_grade_1104.get("enabled", true)), "ships OFF until judged")
	# bark_grey_1110 ships ON since 10 Nov and merges after this grade; switch it off
	# so this checks only that foliage_grade_1104 OFF adds nothing.
	if look.has("bark_grey_1110"):
		look.bark_grey_1110["enabled"] = false
	if look.has("bark_detail_1110"):
		look.bark_detail_1110["enabled"] = false
	var vegetation := _json("res://data/config/stormwood_vegetation.json")
	assert_eq(VEGETATION.stormwood_foliage_grade(vegetation, look), {}, "OFF adds no overlay")


func test_foliage_grade_on_covers_each_layer_model_with_cool_tints() -> void:
	var look := _json(VEGETATION.STORMWOOD_LOOK_PATH)
	look.foliage_grade_1104["enabled"] = true
	# Isolate this grade: bark_grey_1110 (ON since 10 Nov) merges after it and
	# retints the same bark materials.
	if look.has("bark_grey_1110"):
		look.bark_grey_1110["enabled"] = false
	if look.has("bark_detail_1110"):
		look.bark_detail_1110["enabled"] = false
	var vegetation := _json("res://data/config/stormwood_vegetation.json")
	var overlay := VEGETATION.stormwood_foliage_grade(vegetation, look)
	var variants: Dictionary = overlay.variant_retint
	for layer_name: String in look.foliage_grade_1104.layers:
		for model: String in vegetation.layers[layer_name].models:
			assert_true(variants.has(model), "%s model %s graded" % [layer_name, model])
			var policy := VEGETATION.retint_policy(model, vegetation.layers[layer_name], overlay)
			for material: String in look.foliage_grade_1104.layers[layer_name]:
				var tint := Color(str(policy.tints[material]))
				assert_eq(tint.to_html(false), Color(str(look.foliage_grade_1104.layers[layer_name][material])).to_html(false), "%s %s tint applied" % [layer_name, material])
				assert_false(tint.r > tint.g * 1.3 and tint.r > tint.b * 1.3, "no red or oxblood: %s" % material)


## The grade's texture adjusts reach retint_policy for each graded model.
func test_foliage_grade_on_adds_texture_adjusts() -> void:
	var look := _json(VEGETATION.STORMWOOD_LOOK_PATH)
	look.foliage_grade_1104["enabled"] = true
	var vegetation := _json("res://data/config/stormwood_vegetation.json")
	var overlay := VEGETATION.stormwood_foliage_grade(vegetation, look)
	for layer_name: String in look.foliage_grade_1104.adjust:
		for model: String in vegetation.layers[layer_name].models:
			var policy := VEGETATION.retint_policy(model, vegetation.layers[layer_name], overlay)
			for material: String in look.foliage_grade_1104.adjust[layer_name]:
				assert_true(float(policy.adjusts[material].saturation) < 1.0, "%s %s desaturated" % [layer_name, material])
