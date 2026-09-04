extends "res://tests/test_case.gd"

## Capture evidence must recognise the tiled GrassField representation shipped
## by the game.  The parent MultiMesh is intentionally empty when cull tiles
## own the instances; treating that as a bare field invalidates every ground
## and water frame even though the rendered grass is present.

const CAPTURE_CHECK := preload("res://tools/capture_check.gd")


class FakeGrassField extends MultiMeshInstance3D:
	var _camera: Camera3D = null
	var _ring_instances: int = 0


func _field(ring_instances: int, legacy_instances: int) -> FakeGrassField:
	var field := FakeGrassField.new()
	field._ring_instances = ring_instances
	if legacy_instances > 0:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.instance_count = legacy_instances
		field.multimesh = mm
	return field


func test_tiled_grass_counts_as_live_even_when_the_parent_multimesh_is_empty() -> void:
	var field := _field(64, 0)
	assert_true(CAPTURE_CHECK._field_has_instances(field),
		"the shipped tiled field owns instances in child tiles, not its parent MultiMesh")
	field.free()


func test_the_legacy_parent_multimesh_still_counts_as_live() -> void:
	var field := _field(0, 1)
	assert_true(CAPTURE_CHECK._field_has_instances(field),
		"older capture fixtures still expose their instances on the parent MultiMesh")
	field.free()


func test_a_field_with_no_tiled_or_legacy_instances_is_rejected() -> void:
	var field := _field(0, 0)
	assert_false(CAPTURE_CHECK._field_has_instances(field),
		"a genuinely empty GrassField must not validate a bare-ground capture")
	field.free()
