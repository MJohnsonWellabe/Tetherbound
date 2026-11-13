extends "res://tests/test_case.gd"

## F39#19 / F39#7 (LANE-LAND-MT, GPU judged 13 Nov, G-land-mt-cragcut): the
## Venn fight's black overhead wedge was the inner side of the Veilfall crag
## shells. Back faces nearer than back_face_cut_m are discarded, so the camera
## sees the real terrain behind; far views (front faces) are unchanged.

const SHADER_PATH := "res://shaders/water_veilfall_crag.gdshader"
const KITBASH := "res://data/config/water_veilfall_crag_kitbash.json"


func test_crag_shader_discards_near_back_faces() -> void:
	var code := FileAccess.get_file_as_string(SHADER_PATH)
	assert_true(code.contains("uniform float back_face_cut_m = 0.0;"), "the cut defaults off in the shader")
	assert_true(code.contains("if (!FRONT_FACING && back_face_cut_m > 0.0 && length(VERTEX) < back_face_cut_m)"),
		"only back faces closer than the cut distance are discarded")


func test_cut_ships_on_with_its_verdict() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(KITBASH))
	assert_true(parsed is Dictionary, "the kitbash config parses")
	var crag: Dictionary = (parsed as Dictionary).get("crag_shader", {})
	assert_eq(float(crag.get("back_face_cut_m", 0.0)), 150.0, "the judged cut distance ships")
	assert_true(str(crag.get("_why_back_face_cut_m", "")).contains("+0.07"), "the verdict is cited")
	assert_eq(float(crag.get("back_face_lit", 1.0)), 0.0, "the level CRAGBACK lighting stays off")
