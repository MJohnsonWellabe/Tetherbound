extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#5 P2-039: pool_satin_1104 replaces the
## black pools' fixed satin sheen so they stop mirroring the pale sky. It
## ships OFF; while OFF the zones config carries no pool sheen keys.

const ZONES := preload("res://scripts/world/stormwood_ground_zones.gd")


func test_pool_satin_ships_off() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ZONES.CONFIG_PATH))
	assert_false(bool(raw.pool_satin_1104.get("enabled", true)), "ships OFF until judged")
	var zones := ZONES.config()
	assert_false(zones.has("pool_roughness"), "OFF leaves the shader's own sheen")


func test_pool_satin_values_are_duller_than_the_shipped_sheen() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ZONES.CONFIG_PATH))
	assert_true(float(raw.pool_satin_1104.pool_roughness) > 0.38, "rougher than the shipped 0.38")
	assert_true(float(raw.pool_satin_1104.pool_specular) < 0.25, "less specular than the shipped 0.25")
