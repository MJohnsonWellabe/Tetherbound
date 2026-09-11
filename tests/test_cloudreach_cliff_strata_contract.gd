extends "res://tests/test_case.gd"

const SHADER_PATH := "res://shaders/cloudreach_cliff.gdshader"


func test_cloudreach_strata_are_warped_and_spatially_intermittent() -> void:
	var source := FileAccess.get_file_as_string(SHADER_PATH)
	assert_true(source.contains("strata_phase_warp"))
	assert_true(source.contains("strata_presence"))
	assert_true(source.contains("ochre_patch"))
	assert_true(source.contains("world_position.x * 0.006"))
	assert_true(source.contains("world_position.z * 0.006"))
	assert_false(source.contains("mod(strata_band, 2.0)"),
		"cliffs must not alternate one exact realm-wide stripe cadence")
	assert_false(source.contains("mod(strata_band, 3.0)"),
		"ochre must form irregular outcrops instead of every third world band")


func test_cloudreach_strata_preserve_ledge_and_crevice_material_roles() -> void:
	var source := FileAccess.get_file_as_string(SHADER_PATH)
	assert_true(source.contains("ledge_normal_threshold"))
	assert_true(source.contains("ledge_moss_strength"))
	assert_true(source.contains("crevice_strength"))
	assert_true(source.contains("rock_normal"))
	assert_true(source.contains("NORMAL=normalize"))
