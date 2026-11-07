extends "res://tests/test_case.gd"

## VIS-STORMWOOD (4 Nov 2026), F41#1: root_floor_1104 turns the green terrain
## inside the Stormheart hollow into dark root loam. It ships OFF until judged;
## the shader patch is additive and applies once.

const FLOOR := preload("res://scripts/world/stormheart_root_floor.gd")


func test_root_floor_ships_off() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FLOOR.CONFIG_PATH))
	assert_false(bool(raw.root_floor_1104.get("enabled", true)), "ships OFF until judged")
	assert_eq(FLOOR.config(), {}, "OFF returns no config")


func test_root_floor_patch_is_additive_and_idempotent() -> void:
	var code := "uniform float a;\nvoid fragment() {\n  SPECULAR = 1. - mat.normal_rough.a;\n}\n"
	var once := FLOOR.patched_code(code)
	assert_true(once.contains(FLOOR.MARKER), "patch applied")
	assert_true(once.contains("SPECULAR = 1. - mat.normal_rough.a;"), "anchor kept")
	assert_eq(FLOOR.patched_code(once), once, "applies once")
	assert_eq(FLOOR.patched_code("void vertex() {}"), "void vertex() {}", "no anchors: unchanged")


func test_root_floor_colours_are_dark_and_not_red() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FLOOR.CONFIG_PATH))
	for key: String in ["loam_colour", "root_colour"]:
		var c := Color(str(raw.root_floor_1104[key]))
		assert_true(c.get_luminance() < 0.3, "%s reads as dark loam" % key)
		assert_false(c.r > c.g * 1.4 and c.r > c.b * 1.4, "%s is no red or oxblood" % key)
