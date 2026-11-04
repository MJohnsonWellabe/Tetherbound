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
