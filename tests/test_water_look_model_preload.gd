extends "res://tests/test_case.gd"

## Tidewake look models load on the loader threads, not inside one build frame:
## ~19 Meshy GLBs loaded back to back froze a co-op host past its 15 s
## heartbeat (smoke_net_water_alpha on #713).

const WATER_WORLD := preload("res://scripts/world/water_world.gd")


func test_model_paths_are_collected_once_and_missing_files_skipped() -> void:
	var barrel := "res://assets/props/quaternius_fantasy/Barrel.gltf"
	var look := {"a": {"model": barrel}, "b": [{"model": barrel},
		{"model": "res://assets/props/does_not_exist/nothing.glb"}]}
	assert_eq(WATER_WORLD.look_model_paths(look), [barrel] as Array[String])


func test_the_build_awaits_the_models_before_the_dock_builders() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/world/water_world.gd")
	var request := source.find("var look_models := _request_look_models()")
	var wait := source.find("await _await_look_models(look_models)")
	assert_true(request >= 0 and wait > request, "requested at the start, awaited later")
	assert_true(wait < source.find("var docks := DOCKS.new()"), "awaited before the dock builders")
	assert_true(wait < source.find("water_landmark_models.gd\").new()"), "awaited before the landmark models")
