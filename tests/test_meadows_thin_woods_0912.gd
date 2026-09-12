extends "res://tests/test_case.gd"

const RULES := preload("res://scripts/world/scatter_rules.gd")
const B2_PATH := "res://data/config/bands/band2_stone_and_root/vegetation.json"
const B3_PATH := "res://data/config/bands/band3_the_river_lock/vegetation.json"


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "%s parses" % path)
	return parsed as Dictionary if parsed is Dictionary else {}


func _clearing(path: String, id: String) -> Dictionary:
	for raw: Variant in (_json(path).get("clearings", []) as Array):
		if raw is Dictionary and str((raw as Dictionary).get("id", "")) == id:
			return raw as Dictionary
	return {}


func _solid_layer() -> Dictionary:
	return {
		"max_slope_deg": 90.0,
		"min_slope_deg": -1.0,
		"min_height": -1000.0,
		"max_height": 1000.0,
		"clear_radius": 0.0,
		"cleared_by_clearings": true,
	}


func test_only_the_two_owner_named_zones_opt_into_partial_clearings() -> void:
	var found: Array[String] = []
	for path: String in [B2_PATH, B3_PATH]:
		for raw: Variant in (_json(path).get("clearings", []) as Array):
			var clearing := raw as Dictionary
			if clearing.has("retain_fraction"):
				found.append(str(clearing.get("id", "")))
	found.sort()
	assert_eq(found, ["stonewater_walkable_thin_wood", "warrens_walkable_thin_wood"],
		"only the two bounded owner-named landscapes use partial clearing")
	for spec: Array in [
		[B2_PATH, "warrens_walkable_thin_wood", 0.32],
		[B3_PATH, "stonewater_walkable_thin_wood", 0.35],
	]:
		var clearing := _clearing(str(spec[0]), str(spec[1]))
		assert_false(clearing.is_empty(), "%s is authored" % str(spec[1]))
		assert_almost_eq(float(clearing.get("retain_fraction", 0.0)), float(spec[2]), 0.001)


func test_partial_clearings_keep_some_blocking_scatter_but_remove_most() -> void:
	var layer := _solid_layer()
	for spec: Array in [
		[Vector2(-315.0, 2550.0), 62.0],
		[Vector2(-120.0, 3420.0), 70.0],
	]:
		var centre := spec[0] as Vector2
		var radius := float(spec[1])
		var kept := 0
		var sampled := 0
		for x_step in range(-16, 17):
			for z_step in range(-16, 17):
				var spot := centre + Vector2(float(x_step) * 2.5, float(z_step) * 2.5)
				if spot.distance_to(centre) >= radius * 0.92:
					continue
				# Exclude the Warrens' nested hard r30 mouth clearing from this
				# density measurement; its complete opening is intentional.
				if centre.x < -300.0 and spot.distance_to(Vector2(-357.0, 2610.0)) < 30.0:
					continue
				sampled += 1
				kept += 1 if RULES.allowed(layer, 0.0, 0.0, 9999.0, spot) else 0
		var fraction := float(kept) / float(sampled)
		assert_true(kept > 0, "thin woods retain real trunks/rocks")
		assert_between(fraction, 0.12, 0.50,
			"thin woods should retain roughly one third of blocking scatter")


func test_existing_clearings_still_default_to_fully_open() -> void:
	var layer := _solid_layer()
	assert_false(RULES.allowed(layer, 0.0, 0.0, 9999.0, Vector2(400.0, 1800.0)),
		"an existing clearing with no retain_fraction remains completely open")
	assert_true(RULES.allowed(layer, 0.0, 0.0, 9999.0, Vector2(1000.0, 1000.0)),
		"ground outside all clearings is unaffected")
