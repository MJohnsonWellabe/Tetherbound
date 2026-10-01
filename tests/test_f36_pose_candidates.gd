extends "res://tests/test_case.gd"

## Queue with ROOT. These test candidate wiring/restoration, not visual PASS.
const BODY := preload("res://scripts/creatures/creature_body.gd")
const SCENE := preload("res://scenes/creatures/creature.tscn")


func test_preview_library_preserves_installed_clips_and_revive_pivot() -> void:
	var body := SCENE.instantiate() as Node3D
	body.set_script(BODY)
	body.set_meta("f36_pose_preview", true)
	var stage := Node3D.new()
	var loop := Engine.get_main_loop() as SceneTree
	loop.root.add_child(stage)
	stage.add_child(body)
	body.call("setup", "terrapup", false)
	body.set_physics_process(false)
	assert_true(bool(body.get_meta("f36_pose_candidate_installed", false)), "explicit preview installs on the measured rig")
	var players := body.find_children("*", "AnimationPlayer", true, false)
	assert_eq(players.size(), 1)
	if players.size() != 1:
		stage.free()
		return
	var player := players[0] as AnimationPlayer
	assert_true(player.has_animation("idle"), "installed idle retained")
	assert_true(player.has_animation("attack"), "installed attack retained")
	for role: String in ["hit", "faint", "swim", "fly_grip", "ride"]:
		assert_true(player.has_animation("f36_candidate/%s" % role), role + " candidate exists")
	var pivot: Node3D = body.call("model_pivot")
	var before := pivot.transform
	body.call("play_faint")
	player.seek(1.2, true)
	assert_true(not pivot.transform.is_equal_approx(before), "collapse changes only visual pivot")
	body.call("revive_animation")
	assert_true(pivot.transform.is_equal_approx(before), "revive restores the pre-collapse pivot")
	body.call("set_traversal_pose", "swim")
	body.call("set_traversal_pose", "swim")
	var animator: RefCounted = body.get("_animator")
	animator.call("tick", .1, 2.0, 4.0)
	assert_eq(str(player.current_animation), "f36_candidate/swim", "repeated state application selects one loop")
	body.call("set_traversal_pose", "")
	animator.call("tick", .1, 0.0, 4.0)
	assert_eq(str(player.current_animation), "idle", "dismount/state clear returns to installed idle")
	assert_true(pivot.transform.is_equal_approx(before), "ordinary idle clears candidate pivot deformation")
	stage.free()


func test_ordinary_body_keeps_candidates_off() -> void:
	var body := SCENE.instantiate() as Node3D
	body.set_script(BODY)
	var loop := Engine.get_main_loop() as SceneTree
	loop.root.add_child(body)
	body.call("setup", "terrapup", false)
	body.set_physics_process(false)
	assert_false(bool(body.get_meta("f36_pose_candidate_installed", false)), "ordinary body stays on installed art")
	body.free()
