extends "res://tests/test_case.gd"

## State routing and visual ownership only. These checks cannot certify skin
## deformation, stroke quality or waterline readability; those need rendering.
const MODEL := preload("res://scripts/player/trainer_model.gd")
const SWIM := preload("res://scripts/player/swim_state.gd")

class LocalSwim:
	extends Node
	var state := SWIM.new()
	func snapshot() -> Dictionary:
		return state.snapshot()

class RemoteBody:
	extends CharacterBody3D
	var aquatic := SWIM.new()
	func animation_state() -> String:
		return "jump"


func _local() -> CharacterBody3D:
	var player := CharacterBody3D.new()
	var swim := LocalSwim.new()
	swim.name = "SwimController"
	player.add_child(swim)
	swim.state.enter_water(false, 1.25)
	return player


func _model(player: CharacterBody3D, enabled: bool = true) -> Node3D:
	var model := Node3D.new()
	model.set_script(MODEL)
	player.add_child(model)
	assert_true(bool(model.call("build", "trainer")))
	model.set("_player", player)
	var config := MODEL.load_human_swim_visual()
	config.pose_enabled = enabled
	model.set("_human_swim_visual", config)
	return model


func test_disabled_pose_leaves_art_bones_and_animation_untouched() -> void:
	# F39 P2-071: shipped on; the disabled path below stays pinned.
	assert_true(bool(MODEL.load_human_swim_visual().get("pose_enabled", false)))
	var player := _local()
	var model := _model(player, false)
	var art: Transform3D = model.call("art_transform")
	var rig: Skeleton3D = model.call("skeleton")
	var hips := rig.find_bone("Hips")
	var pose := rig.get_bone_pose(hips)
	var animator: AnimationPlayer = model.call("animation_player")
	var active := animator.active
	assert_false(bool(model.call("_update_human_swim_visual", 0.1)))
	assert_true(art.is_equal_approx(model.call("art_transform")))
	assert_true(pose.is_equal_approx(rig.get_bone_pose(hips)))
	assert_eq(animator.active, active)
	player.free()


func test_local_and_remote_use_existing_aquatic_snapshot() -> void:
	var local := _local()
	var remote := RemoteBody.new()
	remote.aquatic.enter_water(false, 1.25)
	assert_eq(MODEL.human_swim_snapshot(local), MODEL.human_swim_snapshot(remote))
	var local_model := _model(local)
	var remote_model := _model(remote)
	assert_true(bool(local_model.call("_update_human_swim_visual", 0.25)))
	assert_true(bool(remote_model.call("_update_human_swim_visual", 0.25)))
	assert_true((local_model.call("art_transform") as Transform3D).is_equal_approx(
		remote_model.call("art_transform")))
	var local_rig: Skeleton3D = local_model.call("skeleton")
	var remote_rig: Skeleton3D = remote_model.call("skeleton")
	for index in local_rig.get_bone_count():
		assert_true(local_rig.get_bone_pose(index).is_equal_approx(remote_rig.get_bone_pose(index)))
	local.free()
	remote.free()


func test_paused_human_freezes_stroke_and_does_not_write_simulation() -> void:
	var player := _local()
	player.velocity = Vector3(2, 0, 1)
	var model := _model(player)
	var swim := player.get_node("SwimController")
	assert_true(bool(model.call("_update_human_swim_visual", 0.2)))
	swim.state.pause_for_combat()
	var packet: Dictionary = swim.snapshot()
	var transform_before := player.transform
	var velocity_before := player.velocity
	var phase: float = model.get("_human_swim_phase")
	var rig: Skeleton3D = model.call("skeleton")
	var arm := rig.find_bone("LeftArm")
	var arm_pose := rig.get_bone_pose(arm)
	assert_true(bool(model.call("_update_human_swim_visual", 1.0)))
	assert_almost_eq(float(model.get("_human_swim_phase")), phase)
	assert_true(arm_pose.is_equal_approx(rig.get_bone_pose(arm)))
	assert_eq(swim.snapshot(), packet)
	assert_true(player.transform.is_equal_approx(transform_before))
	assert_eq(player.velocity, velocity_before)
	player.free()


func test_leaving_water_restores_exact_art_and_bone_pose_and_resumes_animation() -> void:
	var player := _local()
	var model := _model(player)
	var before: Transform3D = model.call("art_transform")
	var rig: Skeleton3D = model.call("skeleton")
	var poses: Array[Transform3D] = []
	for index in rig.get_bone_count():
		poses.append(rig.get_bone_pose(index))
	var animator: AnimationPlayer = model.call("animation_player")
	var active := animator.active
	assert_true(bool(model.call("_update_human_swim_visual", 0.2)))
	assert_false(animator.active)
	assert_false(before.is_equal_approx(model.call("art_transform")))
	player.get_node("SwimController").state.leave_water()
	assert_false(bool(model.call("_update_human_swim_visual", 0.2)))
	assert_true(before.is_equal_approx(model.call("art_transform")))
	for index in rig.get_bone_count():
		assert_true(poses[index].is_equal_approx(rig.get_bone_pose(index)))
	assert_eq(animator.active, active)
	assert_eq(str(model.get("_current")), "")
	player.free()


func test_swimming_keeps_non_swim_bones_at_their_pre_swim_pose() -> void:
	# F39 P2-071 round 1: cloth/accessory bones snapped to the installed rest
	# pose and stood up out of the swimmer. Only the stroke bones may move.
	var player := _local()
	var model := _model(player)
	var rig: Skeleton3D = model.call("skeleton")
	var swim_bones: Array = MODEL.HUMAN_SWIM_BONES
	var poses: Array[Transform3D] = []
	for index in rig.get_bone_count():
		poses.append(rig.get_bone_pose(index))
	assert_true(bool(model.call("_update_human_swim_visual", 0.2)))
	assert_true(bool(model.call("_update_human_swim_visual", 0.2)))
	var kept := 0
	var moved := 0
	for index in rig.get_bone_count():
		if rig.get_bone_name(index) in swim_bones:
			if not poses[index].is_equal_approx(rig.get_bone_pose(index)):
				moved += 1
		else:
			assert_true(poses[index].is_equal_approx(rig.get_bone_pose(index)),
				rig.get_bone_name(index) + " keeps its pre-swim pose")
			kept += 1
	assert_true(kept > 0, "some non-swim bones exist")
	assert_true(moved > 0, "the stroke bones move")
	player.free()


func test_swimming_neutralises_entry_tilt_and_restores_it_without_rewinding_facing() -> void:
	var player := _local()
	player.transform = Transform3D(Basis(Vector3.UP, 0.4), Vector3(3.0, 1.0, 5.0))
	var player_before := player.transform
	var model := _model(player)
	model.rotation = Vector3(0.12, 0.7, -0.09)
	var before := model.rotation
	assert_true(bool(model.call("_update_human_swim_visual", 0.2)))
	assert_almost_eq(model.rotation.x, 0.0)
	assert_almost_eq(model.rotation.z, 0.0)
	assert_almost_eq(model.rotation.y, before.y)
	assert_true(player.transform.is_equal_approx(player_before))
	model.rotation.y = 1.3
	assert_true(bool(model.call("_update_human_swim_visual", 0.2)))
	assert_almost_eq(model.rotation.x, 0.0)
	assert_almost_eq(model.rotation.z, 0.0)
	assert_almost_eq(model.rotation.y, 1.3)
	player.get_node("SwimController").state.leave_water()
	assert_false(bool(model.call("_update_human_swim_visual", 0.2)))
	assert_almost_eq(model.rotation.x, before.x)
	assert_almost_eq(model.rotation.z, before.z)
	assert_almost_eq(model.rotation.y, 1.3)
	assert_true(player.transform.is_equal_approx(player_before))
	player.free()


func test_mounted_and_paused_mount_are_excluded_and_other_poses_take_precedence() -> void:
	for mode in [SWIM.Mode.MOUNTED, SWIM.Mode.LAND]:
		assert_false(MODEL.human_swim_pose_requested({"mode": mode}, true, false, false, false))
	assert_false(MODEL.human_swim_pose_requested(
		{"mode": SWIM.Mode.COMBAT_PAUSED, "resume_mode": SWIM.Mode.MOUNTED}, true, false, false, false))
	for priority in ["riding", "flying", "lying"]:
		var player := _local()
		var model := _model(player)
		assert_true(bool(model.call("_update_human_swim_visual", 0.1)))
		match priority:
			"riding": model.call("set_riding", true)
			"flying": model.call("set_fly_hang", true)
			"lying": model.call("set_lying", true)
		assert_false(bool(model.get("_human_swim_active")), priority)
		var priority_art: Transform3D = model.call("art_transform")
		assert_false(bool(model.call("_update_human_swim_visual", 0.1)))
		assert_true(priority_art.is_equal_approx(model.call("art_transform")), priority)
		player.free()


func test_disabling_candidate_while_swimming_restores_visuals_immediately() -> void:
	var player := _local()
	var model := _model(player)
	var before: Transform3D = model.call("art_transform")
	assert_true(bool(model.call("_update_human_swim_visual", 0.2)))
	model.set("_human_swim_visual", {"pose_enabled": false})
	assert_false(bool(model.call("_update_human_swim_visual", 0.2)))
	assert_true(before.is_equal_approx(model.call("art_transform")))
	assert_false(bool(model.get("_human_swim_active")))
	assert_eq(int(player.get_node("SwimController").snapshot().mode), SWIM.Mode.HUMAN)
	player.free()
