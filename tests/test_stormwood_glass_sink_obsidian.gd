extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#10 P2-070: obsidian_1104 turns the Glass
## Sink floor into large dark obsidian plates with sparse glowing seams. It
## ships ON since VIS-STORMWOOD j4 and leaves the config unchanged while OFF.

const SINK := preload("res://scripts/world/stormwood_glass_sink.gd")


func _config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SINK.CONFIG_PATH))


## VIS-STORMWOOD j4: judged gain (F41#10 4.03 -> 5.07), ships ON.
func test_obsidian_ships_on_and_is_inert_when_off() -> void:
	var config := _config()
	assert_true(bool(config.obsidian_1104.get("enabled", false)), "ships ON (judged gain)")
	assert_true(str(config.obsidian_1104.get("_why_on", "")).contains("5.07"), "records its mapped score")
	config.obsidian_1104["enabled"] = false
	assert_eq(SINK.with_obsidian(config), config, "OFF leaves the config identical")


func test_obsidian_on_darkens_enlarges_and_glows_without_red() -> void:
	var config := _config()
	config.obsidian_1104["enabled"] = true
	config.obsidian_1104.r3["enabled"] = false
	var on := SINK.with_obsidian(config)
	assert_true(Color(str(on.glass_colour)).get_luminance() < Color(str(config.glass_colour)).get_luminance(), "darker body")
	assert_true(float(on.fracture_scale) < float(config.fracture_scale), "larger plates")
	assert_true(float(on.vein_energy) > 0.0 and float(on.vein_fraction) < 0.5, "sparse glowing veins")
	var vein := Color(str(on.vein_colour))
	assert_true(vein.b > vein.r, "stormglass glow is blue, never red")
	assert_eq(on.meshy_rim, config.meshy_rim, "dressing keys are untouched")


## r2 (OFF until judged): sparser, fainter veins over larger plates.
func test_obsidian_r2_ships_off_and_thins_the_veins_when_on() -> void:
	var config := _config()
	assert_false(bool(config.obsidian_1104.r2.get("enabled", true)), "r2 ships OFF")
	config.obsidian_1104.r3["enabled"] = false
	var r1 := SINK.with_obsidian(config)
	config.obsidian_1104.r2["enabled"] = true
	var r2 := SINK.with_obsidian(config)
	assert_true(float(r2.vein_fraction) < float(r1.vein_fraction), "fewer glowing seams")
	assert_true(float(r2.vein_energy) < float(r1.vein_energy), "fainter glow")
	assert_true(float(r2.fracture_scale) < float(r1.fracture_scale), "larger plates")
	assert_false(r2.has("r2"), "the switch block does not leak into material keys")


## r3 (qj_obs3, judged gain): no glowing veins and no visible seams.
func test_obsidian_r3_ships_on_and_removes_the_grid() -> void:
	var config := _config()
	assert_true(bool(config.obsidian_1104.r3.get("enabled", false)), "r3 ships ON (judged gain)")
	assert_true(str(config.obsidian_1104.r3.get("_why_on", "")).contains("4.38"), "records its mapped score")
	var r3 := SINK.with_obsidian(config)
	assert_almost_eq(float(r3.vein_energy), 0.0, 0.0001, "no glowing veins")
	assert_almost_eq(float(r3.seam_width), 0.0, 0.0001, "no seam lines")
	assert_false(r3.has("r3"), "the switch block does not leak into material keys")
