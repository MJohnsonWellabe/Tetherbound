extends "res://tests/test_case.gd"

## P2-025: grass tufts on or through a paved masonry top are collapsed; tufts
## beside it and the flag default are untouched.

const PAVED := preload("res://scripts/world/cloudreach_paved_grass.gd")
const GROUNDING := preload("res://scripts/world/cloudreach_grounding.gd")


func test_flag_defaults_off() -> void:
	assert_false(bool(GROUNDING.read_config().get("clear_paved_grass", true)))


func test_clears_only_tufts_on_the_paved_top() -> void:
	var world := Node3D.new()
	var paving := StandardMaterial3D.new()
	var dais := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(26.0, 1.3, 20.0)
	dais.mesh = box
	dais.material_override = paving
	dais.position = Vector3(100.0, 0.65, 50.0)
	world.add_child(dais)
	var tufts := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = BoxMesh.new()
	multimesh.instance_count = 4
	var points := [Vector3(100.0, 1.3, 50.0), Vector3(110.0, 0.4, 55.0),
		Vector3(120.0, 0.0, 50.0), Vector3(100.0, 5.0, 50.0)]
	for i in points.size():
		multimesh.set_instance_transform(i, Transform3D(Basis(), points[i]))
	tufts.multimesh = multimesh
	world.add_child(tufts)
	var cleared: int = PAVED.clear(world, [paving], {})
	assert_eq(cleared, 2, "the tuft on the top and the one poking up from under it")
	assert_true(multimesh.get_instance_transform(0).basis.get_scale().is_zero_approx())
	assert_true(multimesh.get_instance_transform(1).basis.get_scale().is_zero_approx())
	assert_false(multimesh.get_instance_transform(2).basis.get_scale().is_zero_approx(), "beside the dais")
	assert_false(multimesh.get_instance_transform(3).basis.get_scale().is_zero_approx(), "far above it")
	world.free()
