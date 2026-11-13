extends "res://tests/test_case.gd"

## turf_detail_1113 (LANE-LAND-CS): OFF until judged. On, the Cloudreach turf
## shader adds the grass texture's fine detail back.

const MATERIALS := preload("res://scripts/world/cloudreach_environment_materials.gd")


func _visual() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/cloudreach_visual.json"))


func test_ships_off_and_off_sets_nothing() -> void:
	var visual := _visual()
	assert_false(bool(visual.surface.turf_detail_1113.get("enabled", true)), "turf_detail_1113 ships OFF until judged")
	assert_true(MATERIALS.turf_detail_from(visual).is_empty(), "OFF passes no detail")
	assert_true(MATERIALS.turf_detail_from(null).is_empty(), "a missing config passes no detail")


func test_on_passes_the_three_values() -> void:
	var visual := _visual()
	visual.surface.turf_detail_1113.enabled = true
	var detail := MATERIALS.turf_detail_from(visual)
	assert_true(float(detail.strength) > 0.0, "strength is positive")
	assert_true(float(detail.fine_scale) > 1.0, "the fine octave is finer than the base")
	assert_true(float(detail.fine_strength) >= 0.0, "fine strength is set")


func test_shader_default_is_the_shipped_turf() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/cloudreach_turf.gdshaderinc")
	assert_true(code.contains("uniform vec3 turf_detail_1113 = vec3(0.0,"), "the uniform defaults to strength 0")
	assert_true(code.contains("if (turf_detail_1113.x > 0.0)"), "the detail is gated on its strength")
