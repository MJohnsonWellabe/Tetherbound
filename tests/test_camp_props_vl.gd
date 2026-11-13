extends "res://tests/test_case.gd"

## Visual lane v1/b9 (3 Nov 2026): the Blender r2 camp nest bed (F39#12) and
## workbench (F39#13) ship ON with their judged CPU scores.

const PROPS := preload("res://scripts/world/meshy_camp_props.gd")


func test_r2_nest_bed_ships_on_with_its_score() -> void:
	var nest: Dictionary = PROPS.settings().get("bed", {}).get("nest_candidate", {})
	assert_true(bool(nest.get("enabled", false)), "r2 nest bed ships ON (judged gain)")
	assert_true(str(nest.get("_why_on", "")).contains("7.02"), "nest records its mapped score")
	assert_true(str(nest.get("model", "")).ends_with("nest_bed_r2.glb"), "the judged r2 model is the one shipped")
	assert_true(ResourceLoader.exists(str(nest.get("model", ""))), "nest model is imported")


func test_r2_workbench_ships_on_with_its_score() -> void:
	var built: Dictionary = PROPS.settings().get("workbench", {}).get("vl_candidate", {})
	assert_true(bool(built.get("enabled", false)), "r2 workbench ships ON (judged gain)")
	assert_true(str(built.get("_why_on", "")).contains("6.56"), "workbench records its mapped score")
	# r2b is the judged r2 build with its hung tools turned back onto the bench
	# (tests/test_camp_workbench_model_parts.gd); the r2 file threw them off it.
	assert_true(str(built.get("model", "")).ends_with("camp_workbench_r2b.glb"), "the judged r2 build, parts fixed, is the one shipped")
	assert_true(str(built.get("_why_r2b", "")).contains("4.61 m"), "the parts fix records what it fixed")
	assert_true(ResourceLoader.exists(str(built.get("model", ""))), "workbench model is imported")


func test_apply_seats_the_judged_models() -> void:
	var bed := Node3D.new()
	var bench := Node3D.new()
	var bed_seat := PROPS.apply_bed(bed)
	var bench_seat := PROPS.apply_workbench(bench)
	assert_true(bed_seat != null and bed_seat.get_child_count() == 1, "the nest bed seats one model")
	assert_true(bench_seat != null and bench_seat.get_child_count() == 1, "the workbench seats one model")
	bed.free()
	bench.free()
