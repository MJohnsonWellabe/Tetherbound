extends "res://tests/test_case.gd"

## F10#2 C3 (V-SW-3/5/7, Tidewake's matching finding): the fight camera keeps
## the piloted ally out of the combat HUD's left column and keeps the lens out
## of a large foe's render mesh. Pure-geometry tests of the two solvers; the
## live wiring is exercised by the named-fight captures.

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const RIG := preload("res://scripts/player/camera_rig.gd")
const VIEW := Vector2(1280, 720)


func _rect(left: float, top: float, right: float, bottom: float) -> Array[Vector2]:
	return [Vector2(left, top), Vector2(right, top), Vector2(left, bottom), Vector2(right, bottom)]


func test_an_ally_under_the_left_column_lowers_the_shoulder_by_its_overlap() -> void:
	# Ally spans x 150..400 px, low in the frame: 83 px left of the column's
	# right edge (0.26 + 0.02 of 1280 = 358.4 px ... left 150 -> overlap 208.4).
	var cap := MANAGER.hud_safe_shoulder_cap(2.2, _rect(150, 330, 400, 470), VIEW, 100.0, 0.26, 0.42, 0.02, -1.5)
	assert_almost_eq(cap, 2.2 - (358.4 - 150.0) / 100.0, 0.001, "shoulder drops by the overlap in metres")
	assert_true(cap < 2.2, "an ally under the HUD always lowers the shoulder")


func test_an_ally_clear_of_the_column_keeps_its_shoulder() -> void:
	var clear := MANAGER.hud_safe_shoulder_cap(2.2, _rect(420, 330, 600, 470), VIEW, 100.0, 0.26, 0.42, 0.02, -1.5)
	assert_true(clear >= 2.2, "an ally already right of the column is not pushed in (cap %.2f)" % clear)
	var high := MANAGER.hud_safe_shoulder_cap(2.2, _rect(100, 50, 300, 250), VIEW, 100.0, 0.26, 0.42, 0.02, -1.5)
	assert_eq(high, INF, "an ally above the column's top has no HUD constraint")


func test_the_cap_never_goes_below_its_floor() -> void:
	var cap := MANAGER.hud_safe_shoulder_cap(0.0, _rect(0, 400, 50, 700), VIEW, 20.0, 0.26, 0.42, 0.02, -1.5)
	assert_almost_eq(cap, -1.5, 0.001, "a huge overlap is bounded by min_shoulder")
	assert_eq(MANAGER.hud_safe_shoulder_cap(1.0, [], VIEW, 100.0, 0.26, 0.42, 0.02, -1.5), INF)


func test_the_arm_stops_short_of_a_foe_render_box_in_its_way() -> void:
	# Pivot at origin, arm 9.5 m toward +Z; a foe's render box spans z 5..8.
	var foe := AABB(Vector3(-1.5, -1, 5), Vector3(3, 3, 3))
	var limit := MANAGER.body_limit_along_arm(Vector3.ZERO, Vector3(0, 0, 9.5), foe, 0.35, 2.0)
	assert_almost_eq(limit, 5.0 - 0.35 - 0.35, 0.001, "stops margin short of the grown box")
	assert_eq(MANAGER.body_limit_along_arm(Vector3.ZERO, Vector3(0, 0, 9.5),
		AABB(Vector3(4, -1, 5), Vector3(2, 2, 2)), 0.35, 2.0), INF, "a box beside the arm sets no limit")
	assert_almost_eq(MANAGER.body_limit_along_arm(Vector3.ZERO, Vector3(0, 0, 9.5),
		AABB(Vector3(-1, -1, 0.8), Vector3(2, 2, 2)), 0.35, 2.0), 2.0, 0.001, "never shorter than min_length")
	assert_eq(MANAGER.body_limit_along_arm(Vector3.ZERO, Vector3(0, 0, 9.5),
		AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2)), 0.35, 2.0), INF, "a pivot inside the box (clinch) is left to the ally guards")


func test_the_rig_applies_and_clears_the_body_limit() -> void:
	var rig: Node3D = RIG.new()
	rig.set("_distance", 9.5)
	rig.set_body_limit(4.0)
	assert_almost_eq(rig.body_limit(), 4.0, 0.001)
	# `_follow` needs a live target in the tree (not available to unit tests):
	# pin that it clamps the eased length to the limit on every frame.
	var source := FileAccess.get_file_as_string("res://scripts/player/camera_rig.gd")
	var follow := source.substr(source.find("func _follow("), 3000)
	assert_true(follow.contains("spring_length = minf(spring_length, _body_limit)"),
		"_follow clamps the arm to the limit after easing it out")
	var set_target := source.substr(source.find("func set_target("), 1500)
	assert_true(set_target.contains("_body_limit = INF"), "a new target clears the limit")
	rig.set_body_limit(INF)
	assert_eq(rig.body_limit(), INF, "INF clears it")
	rig.set_body_limit(-1.0)
	assert_eq(rig.body_limit(), INF, "a non-positive limit clears it")
	rig.free()


func test_the_config_declares_both_fixes() -> void:
	var camera: Dictionary = preload("res://scripts/combat/combat_math.gd").config().get("camera", {})
	assert_true(bool(camera.get("hud_safe", {}).get("enabled", false)))
	assert_true(bool(camera.get("body_clear", {}).get("enabled", false)))
