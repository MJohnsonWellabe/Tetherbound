extends "res://tests/test_case.gd"

## camera_rig.gd's pass-through sync (Aquaryn basin, F39#0 GPU pass) reads a
## scene group every physics tick. Unit tests tick rigs that were never added
## to a tree, where get_tree() is null: the sync must skip cleanly instead of
## raising a script error on every step.

const RIG := preload("res://scripts/player/camera_rig.gd")


class ErrorCatcher extends Logger:
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		errors.append("%s:%d %s %s %s" % [file, line, function, code, rationale])


func test_ticking_a_rig_outside_the_tree_raises_no_error() -> void:
	var rig := SpringArm3D.new()
	rig.set_script(RIG)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	rig.notification(Node.NOTIFICATION_READY)
	var player := Node3D.new()
	rig.set_target(player)
	var catcher := ErrorCatcher.new()
	OS.add_logger(catcher)
	for i in 5:
		rig._physics_process(1.0 / 60.0)
	OS.remove_logger(catcher)
	assert_false(rig.is_inside_tree(), "the fixture must be outside the tree to test this")
	assert_eq(catcher.errors.size(), 0, "ticking an out-of-tree rig raised: %s" % [catcher.errors])
	rig.free()
	player.free()
