extends "res://tests/test_case.gd"

## Correctness (LANE-LAND-MT, 13 Nov): the Veilfall base mist never showed.
## CPU probes on the F39#31 views: the spray quads draw (alpha forced to 1
## paints them), and alpha = opacity * radial shows the mist, but the billow
## gate `smoothstep(0.2, 0.75, billow + radial * 0.35)` took every puff to
## nothing. The shipped spray keeps a floor share of each puff, so the noise
## breaks the mist up but can never erase it.

const SHADER_PATH := "res://shaders/water_veilfall_spray.gdshader"
const VEILFALL := "res://data/config/water_veilfall.json"


func test_spray_shader_floors_the_billow_gate() -> void:
	var code := FileAccess.get_file_as_string(SHADER_PATH)
	assert_true(code.contains("uniform float billow_floor"), "the spray shader has a billow floor")
	assert_true(code.contains("mix(billow_floor, 1.0, smoothstep(0.2, 0.75, billow + radial * 0.35))"),
		"the billow term scales the puff from the floor up instead of gating it")


func test_shipped_falls_spray_keeps_a_visible_floor() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VEILFALL))
	assert_true(parsed is Dictionary, "water_veilfall.json parses")
	var spray: Dictionary = ((parsed as Dictionary).get("falls", {}) as Dictionary).get("spray_shader", {})
	var floor_share := float(spray.get("billow_floor", 0.0))
	assert_true(floor_share >= 0.3 and floor_share <= 1.0, "the shipped mist keeps at least 30% of each puff")
	assert_eq(float(spray.get("size_scale", 1.0)), 1.0, "the correctness fix does not resize the puffs")
