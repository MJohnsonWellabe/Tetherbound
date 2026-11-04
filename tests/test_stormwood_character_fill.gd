extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#8/#18: stormwood_character_rim.fill_1104
## adds a soft front fill through the shared overlay's fill_energy. It ships
## OFF until judged; OFF keeps the rim-only overlay (fill 0).

const RIM := preload("res://scripts/world/stormwood_character_rim.gd")


func test_fill_ships_off_and_rim_only() -> void:
	var cfg := RIM.settings()
	assert_false(bool(cfg.fill_1104.get("enabled", true)), "ships OFF until judged")
	var material := RIM.overlay(cfg)
	assert_eq(float(material.get_shader_parameter("fill_energy")), 0.0, "OFF: rim only")


func test_fill_on_sets_a_soft_front_fill() -> void:
	var cfg := RIM.settings()
	cfg.fill_1104["enabled"] = true
	var fill := float(cfg.fill_1104.fill_energy)
	assert_true(fill > 0.0 and fill < 0.4, "a soft fill, not a wash")
	cfg["fill_energy"] = fill
	assert_almost_eq(float(RIM.overlay(cfg).get_shader_parameter("fill_energy")), fill, 0.0001, "the overlay carries the fill")
