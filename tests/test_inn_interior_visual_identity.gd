extends "res://tests/test_case.gd"

const INTERIOR := preload("res://scripts/world/inn_interior.gd")


func test_common_room_has_timber_architectural_depth_without_blocking_the_door() -> void:
	var root := Node3D.new()
	var interior := INTERIOR.new()
	root.add_child(interior)
	interior.call("build")
	var dressing := interior.get_node_or_null(^"CommonRoomTimberDressing") as Node3D
	assert_true(dressing != null, "the inn common room is still an uninterrupted pale box")
	if dressing == null:
		root.free()
		return
	assert_true(dressing.get_node_or_null(^"WainscotWest") != null,
		"the long guest wall has no timber depth")
	assert_true(dressing.get_node_or_null(^"WainscotBar") != null,
		"the bar wall has no grounded lower course")
	assert_true(dressing.find_child("CeilingTie_*", false, false) != null,
		"the common room has no overhead timber rhythm")
	assert_true(dressing.get_node_or_null(^"DoorWainscotL") != null
		and dressing.get_node_or_null(^"DoorWainscotR") != null,
		"the two door returns are not framed independently")
	assert_true(dressing.get_node_or_null(^"DoorWainscot") == null,
		"a solid wainscot panel blocks the inn threshold")
	root.free()
