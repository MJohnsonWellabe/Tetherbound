extends "res://tests/test_case.gd"

## F42#2: the move cluster and ultimate ring sit inside the 1920×1080 canvas,
## in the lower-right corner (UX §3.2). A bare `position` write on the
## bottom-right-anchored cluster once put it off-screen at the top-left, and
## the in-fight capture showed no move slots or ultimate ring at all.
const RUNS_IN_INITIALIZED_TREE := true
const OVERLAY := preload("res://scripts/ui/combat_system_overlay.gd")


func test_move_cluster_is_on_screen_in_the_lower_right() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var canvas := Control.new()
	canvas.size = Vector2(1920, 1080)
	tree.root.add_child(canvas)
	var overlay: Control = OVERLAY.new()
	canvas.add_child(overlay)
	var moves: Control = overlay.get("_moves")
	var rect := Rect2(moves.position, moves.size)
	assert_eq(overlay.size, Vector2(1920, 1080), "overlay fills the canvas")
	assert_true(Rect2(Vector2.ZERO, overlay.size).encloses(rect), "cluster inside the canvas: %s" % str(rect))
	assert_true(rect.position.x > 960.0 and rect.position.y > 540.0, "cluster in the lower-right quadrant: %s" % str(rect))
	overlay.call("_layout_commands")
	var lane: Control = overlay.get("_command_box")
	var lane_rect := Rect2(lane.position, lane.size)
	assert_true(Rect2(Vector2.ZERO, overlay.size).encloses(lane_rect) and lane_rect.position.y > 540.0,
		"command lane on screen, bottom half: %s" % str(lane_rect))
	canvas.queue_free()
