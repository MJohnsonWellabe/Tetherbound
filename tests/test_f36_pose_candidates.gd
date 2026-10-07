extends "res://tests/test_case.gd"

## Queue with ROOT. These test candidate wiring/restoration, not visual PASS.
const BODY := preload("res://scripts/creatures/creature_body.gd")
const SCENE := preload("res://scenes/creatures/creature.tscn")
const POSES := preload("res://scripts/creatures/creature_pose_candidates.gd")


func test_candidate_library_and_ordinary_body_on_initialized_scene_tree() -> void:
	# The unit runner executes in SceneTree._init, before the engine exposes
	# its main loop. These real animation nodes need an initialized tree.
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), PackedStringArray([
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/helpers/f36_pose_native.gd",
	]), output, true)
	var log_text := "\n".join(output)
	var result: Dictionary = {}
	for line: String in log_text.split("\n"):
		if line.begins_with("F36_POSE_RESULT="):
			var parsed: Variant = JSON.parse_string(line.trim_prefix("F36_POSE_RESULT="))
			if parsed is Dictionary: result = parsed
	assert_eq(code, 0, log_text)
	assert_eq(result.get("assertions"), 43.0, log_text)
	assert_eq(result.get("failures"), [], log_text)
	for marker: String in ["SCRIPT ERROR", "ERROR:", "Parse Error", "resources still in use", "instances were leaked"]:
		assert_false(log_text.contains(marker), log_text)


func _case_preview_library_preserves_installed_clips_and_revive_pivot() -> void:
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
	var skeleton := pivot.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	skeleton.force_update_all_bone_transforms()
	assert_almost_eq(POSES._posed_lowest_y(pivot, skeleton, pivot.basis) + pivot.position.y,
		0.0, 0.015, "collapsed posed skin reaches ground without scaling the installed body")
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
	# Original whole-skin floor check remains. An appendage touching the floor
	# is insufficient: test the authored starters' anatomical flank as well.
	for species: String in ["terrapup", "ripplet", "galewisp"]:
		var tucked := SCENE.instantiate() as Node3D
		tucked.set_script(BODY)
		tucked.set_meta("f36_pose_preview", true)
		loop.root.add_child(tucked)
		tucked.call("setup", species, false)
		tucked.set_physics_process(false)
		var tucked_player := tucked.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var tucked_pivot: Node3D = tucked.call("model_pivot")
		var tucked_skeleton := tucked_pivot.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		tucked.call("play_faint")
		for phase: float in [0.75, 0.875, 1.0]:
			tucked_player.seek(1.2 * phase, true)
			tucked_skeleton.force_update_all_bone_transforms()
			var contact: Dictionary = POSES._posed_floor_contact(tucked_pivot, tucked_skeleton, tucked_pivot.basis)
			var floor_y := float(contact.all_min_y) + tucked_pivot.position.y
			var torso_y := float(contact.torso_min_y) + tucked_pivot.position.y
			print("F36_TUCK_CONTACT=" + JSON.stringify({"species": species, "phase": phase,
				"all_min_y_m": floor_y, "torso_min_y_m": torso_y, "torso_vertices": contact.torso_vertices}))
			assert_almost_eq(floor_y, 0.0, 0.015, species + " complete geometry touches floor without clipping")
			assert_true(int(contact.torso_vertices) > 0 and is_finite(torso_y), species + " anatomical torso samples exist")
			assert_true(torso_y >= -0.015 and torso_y <= 0.04, species + " torso/flank contacts floor, not only a projecting appendage")
		tucked.free()


func _case_ordinary_body_keeps_candidates_off() -> void:
	var body := SCENE.instantiate() as Node3D
	body.set_script(BODY)
	var loop := Engine.get_main_loop() as SceneTree
	loop.root.add_child(body)
	body.call("setup", "terrapup", false)
	body.set_physics_process(false)
	assert_false(bool(body.get_meta("f36_pose_candidate_installed", false)), "ordinary body stays on installed art")
	body.free()
