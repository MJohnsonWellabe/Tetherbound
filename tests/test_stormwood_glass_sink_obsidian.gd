extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#10 P2-070: obsidian_1104 turns the Glass
## Sink floor into large dark obsidian plates with sparse glowing seams. It
## ships OFF and leaves the config unchanged while OFF.

const SINK := preload("res://scripts/world/stormwood_glass_sink.gd")


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SINK.CONFIG_PATH))


func test_obsidian_ships_off_and_is_inert() -> void:
	var config := _config()
	assert_false(bool(config.obsidian_1104.get("enabled", true)), "ships OFF until judged")
	assert_eq(SINK.with_obsidian(config), config, "OFF leaves the config identical")


func test_obsidian_on_darkens_enlarges_and_glows_without_red() -> void:
	var config := _config()
	config.obsidian_1104["enabled"] = true
	var on := SINK.with_obsidian(config)
	assert_true(Color(str(on.glass_colour)).get_luminance() < Color(str(config.glass_colour)).get_luminance(), "darker body")
	assert_true(float(on.fracture_scale) < float(config.fracture_scale), "larger plates")
	assert_true(float(on.vein_energy) > 0.0 and float(on.vein_fraction) < 0.5, "sparse glowing veins")
	var vein := Color(str(on.vein_colour))
	assert_true(vein.b > vein.r, "stormglass glow is blue, never red")
	assert_eq(on.meshy_rim, config.meshy_rim, "dressing keys are untouched")
