extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#19 P2-043: basalt_crust_1104 turns the
## Glass Field's glossy crust plate into a low matte basalt mound. It ships
## OFF and changes nothing while OFF.

const FIELD := preload("res://scripts/world/stormwood_glass_field.gd")


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_glass_field.json"))


func test_basalt_crust_ships_off_and_is_inert() -> void:
	var field := FIELD.new()
	field.config = _config()
	assert_false(bool(field.config.basalt_crust_1104.get("enabled", true)), "ships OFF until judged")
	assert_eq(field._basalt_crust(), {}, "OFF returns no crust override")
	field.free()


func test_basalt_crust_on_is_smaller_taller_and_matte() -> void:
	var field := FIELD.new()
	field.config = _config()
	field.config.basalt_crust_1104["enabled"] = true
	var crust: Dictionary = field._basalt_crust()
	assert_true(float(crust.footprint) < float(field.config.shard_finish.crust_footprint), "a smaller footprint than the plate")
	assert_true(float(crust.roughness) >= 0.8, "matte basalt")
	var tint := Color(str(crust.colour))
	assert_false(tint.r > tint.g * 1.4 and tint.r > tint.b * 1.4, "no red or oxblood")
	field.free()


## F41#19 seam_clear_1104: ships OFF; ON drops the fissure ribbons, clears the
## whole scar of grass and narrows the shipped glass crust.
## F41#19 seam_clear_1104 r2: ships ON (qj_seam2 4.77 -> 5.59); keeps every
## fissure (the glass-field identity needs them) but darkens it, clears the
## whole scar of grass and narrows the shipped glass crust.
func test_seam_clear_ships_on_and_darkens_fissures() -> void:
	var field := FIELD.new()
	field.config = _config()
	assert_true(bool(field.config.seam_clear_1104.get("enabled", false)), "ships ON (judged 5.59)")
	assert_true(str(field.config.seam_clear_1104.get("_why_on", "")).contains("5.59"), "_why_on cites the judged score")
	field.config.seam_clear_1104["enabled"] = false
	assert_eq(field._seam_clear(), {}, "OFF returns no override")
	field.config.seam_clear_1104["enabled"] = true
	var seam: Dictionary = field._seam_clear()
	assert_false(seam.has("hide_fissures"), "the fissures are never dropped")
	assert_true(Color(str(seam.fissure_colour)).get_luminance() < 0.2, "fissures read as dark cracks")
	assert_true(float(seam.grass_clear_fraction) > 0.82, "grass cleared wider than shipped")
	assert_true(float(seam.crust_footprint) < float(field.config.shard_finish.crust_footprint), "a narrower crust")
	field.free()
