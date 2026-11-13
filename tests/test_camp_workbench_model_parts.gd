extends "res://tests/test_case.gd"

## The Blender-built camp workbench (assets/props/vl-1103/camp_workbench).
## r2 turned each joined material group about its own origin, which threw the
## hung tools, rope coil, vise and lantern up to 1.6 m off the bench (the
## floating dark squares and the stray white ring in the Tidewake camp
## frames). Every part of the model in use must lie on the bench.

const CONFIG := "res://data/config/meshy_camp_props.json"
const HERO_PROP := preload("res://scripts/world/meshy_hero_prop.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")
## Half the 2.6 m top plus the lantern post and (r3) the awning overhang.
const HALF_LENGTH_M := 1.7
const HALF_DEPTH_M := 1.35


func _model_in_use() -> String:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var bench: Dictionary = cfg.get("workbench", {})
	var built: Dictionary = bench.get("vl_candidate", {})
	return str(built.get("model", "")) if bool(built.get("enabled", false)) else str(bench.get("model", ""))


func _assert_parts_on_bench(path: String) -> void:
	var model: Node3D = HERO_PROP.load_model(path)
	assert_true(model != null, "%s loads" % path)
	if model == null:
		return
	var whole: AABB = BOUNDS.measure(model)
	assert_true(whole.size.x <= HALF_LENGTH_M * 2.0, "%s is %.2f m long: a part is off the bench" % [path, whole.size.x])
	assert_true(whole.size.z <= HALF_DEPTH_M * 2.0, "%s is %.2f m deep: a part is off the bench" % [path, whole.size.z])
	model.free()


func test_the_bench_in_use_has_every_part_on_the_bench() -> void:
	_assert_parts_on_bench(_model_in_use())


func test_the_r3_candidate_has_every_part_on_the_bench() -> void:
	_assert_parts_on_bench("res://assets/props/vl-1103/camp_workbench/camp_workbench_r3.glb")
