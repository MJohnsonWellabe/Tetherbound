extends "res://tests/test_case.gd"

## P2-025: grass tufts on or through a paved masonry top are collapsed; tufts
## beside it and the flag default are untouched.

const PAVED := preload("res://scripts/world/cloudreach_paved_grass.gd")
const GROUNDING := preload("res://scripts/world/cloudreach_grounding.gd")


func test_flag_ships_on() -> void:
	assert_true(bool(GROUNDING.read_config().get("clear_paved_grass", false)),
		"clear_paved_grass ships ON: cloud yardstick 1 Nov batch-3, P2-025 5.75 -> 6.22")


func test_paved_top_covers_only_tufts_on_or_through_it() -> void:
	var world := Node3D.new()
	var paving := StandardMaterial3D.new()
	var dais := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(26.0, 1.3, 20.0)
	dais.mesh = box
	dais.material_override = paving
	dais.position = Vector3(100.0, 0.65, 50.0)
	world.add_child(dais)
	# The headless runner's dummy renderer does not store MultiMesh instance
	# transforms, so the per-tuft test is checked directly on the box set.
	var boxes: Array[Dictionary] = PAVED.paved_boxes(world, [paving], 2.0)
	assert_eq(boxes.size(), 1, "the dais is one paved top")
	var top: Dictionary = boxes[0]
	assert_true(PAVED.covers(top, Vector3(100.0, 1.3, 50.0), 1.6, 0.6), "tuft on the paved top")
	assert_true(PAVED.covers(top, Vector3(110.0, 0.4, 55.0), 1.6, 0.6), "tuft poking up through it")
	assert_false(PAVED.covers(top, Vector3(120.0, 0.0, 50.0), 1.6, 0.6), "tuft beside the dais")
	assert_false(PAVED.covers(top, Vector3(100.0, 5.0, 50.0), 1.6, 0.6), "far above it")
	var other := StandardMaterial3D.new()
	assert_eq(PAVED.paved_boxes(world, [other], 2.0).size(), 0, "only paving materials count")
	world.free()
