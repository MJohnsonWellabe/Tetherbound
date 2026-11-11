extends "res://tests/test_case.gd"

## camera_occlusion.gd _ignored (dialogue re-capture on main 8df122a83, seven
## identical errors): an ignore list holding a freed node raised "Left operand
## of 'is' is a previously freed instance". Validity is tested first now.

const OCCLUSION := preload("res://scripts/player/camera_occlusion.gd")


func test_freed_node_in_the_ignore_list_is_skipped() -> void:
	var owner_node := Node3D.new()
	var child := Node3D.new()
	owner_node.add_child(child)
	var other := Node3D.new()
	var freed := Node3D.new()
	var ignore: Array = [freed, owner_node]
	freed.free()
	assert_false(OCCLUSION._ignored(other, [ignore[0]]), "a freed owner ignores nothing")
	assert_true(OCCLUSION._ignored(child, ignore), "a live owner after a freed one still ignores its child")
	assert_false(OCCLUSION._ignored(other, ignore))
	other.free()
	owner_node.free()
