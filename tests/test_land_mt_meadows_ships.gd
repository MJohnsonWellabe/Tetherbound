extends "res://tests/test_case.gd"

## LANE-LAND-MT Meadows ships (GPU judged, 13 Nov 2026): the dusk ridge haze
## (G-land-mt-duskridge) and the broken Burrow Warrens hillside
## (G-land-mt-brokenhill) ship ON with their verdicts recorded.

const RIDGE := "res://data/config/meadows_ridge_vl.json"
const RIDGE_SHADER := "res://shaders/meadows_ridge_far.gdshader"
const WARRENS := "res://data/config/burrow_warrens.json"
const WARRENS_SCRIPT := preload("res://scripts/world/burrow_warrens.gd")


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func test_dusk_ridge_haze_ships_on() -> void:
	var shader: Dictionary = _json(RIDGE).get("shader", {})
	assert_eq(float(shader.get("warm_haze_mix", 0.0)), 0.85, "the judged warm-haze mix ships")
	assert_eq(float(shader.get("warm_keep_scale", 1.0)), 0.6, "the judged haze thinning ships")
	assert_true(str(shader.get("_why_warm_haze", "")).contains("+0.69"), "the verdict is cited")
	var code := FileAccess.get_file_as_string(RIDGE_SHADER)
	assert_true(code.contains("uniform float warm_haze_mix = 0.0;"), "the shader keeps an off default")
	assert_true(code.contains("fog_colour.r - fog_colour.b"), "warmth is measured from the live fog")


func test_broken_hillside_ships_on() -> void:
	var cfg: Dictionary = WARRENS_SCRIPT.hill_shell_config(_json(WARRENS))
	var broken: Dictionary = cfg.get("broken", {})
	assert_true(bool(broken.get("enabled", false)), "the broken hillside ships ON")
	assert_eq(str(broken.get("scope", "")), "client_presentation", "the flag declares scope")
	assert_true(str(broken.get("_why_on", "")).contains("+1.42"), "the verdict is cited")
	assert_true(float((broken.get("relief", {}) as Dictionary).get("amp_m", 0.0)) > 0.0, "the relief is on")
	assert_true(FileAccess.get_file_as_string("res://scripts/world/burrow_warrens.gd").contains("func _hill_broken_setup("), "the broken build exists")
