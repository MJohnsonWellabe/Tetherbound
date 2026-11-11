extends "res://tests/test_case.gd"

## P2-119: fly_traversal hang_pose (elbow bend plus hang_pose.body) ships ON
## since 11 Nov 2026 (GPU High 6.26 -> 7.14, G-newapproach-fly-grip). When on,
## the legs trail back with bent knees and the torso leans forward; an explicit
## off block poses nothing.

const TRAINER := preload("res://scripts/player/trainer_model.gd")
const FLY := preload("res://scripts/player/fly_controller.gd")


func test_hang_pose_ships_on_with_its_verdict() -> void:
	var pose: Dictionary = FLY.hang_pose()
	var body: Dictionary = pose.get("body", {})
	assert_true(bool(body.get("enabled", false)), "hang_pose.body ships ON")
	assert_true(float(pose.get("upper_lateral", 0.0)) > 1.5, "upper arms aim outward so the elbows bend")
	assert_true(float(pose.get("forearm_lateral", 1.0)) < 0.0, "forearms aim back in toward the grip")
	assert_true(str(pose.get("_why_on", "")).contains("6.26 -> 7.14"), "hang_pose records its GPU verdict")


func test_body_block_off_is_read_as_off() -> void:
	# trainer_model.gd::_apply_fly_hang gates the body rotations on this exact
	# read; an absent or false flag keeps the legs and torso at rest.
	for off: Dictionary in [{}, {"body": {}}, {"body": {"enabled": false, "hip_extension_deg": 22.0}}]:
		var body: Variant = off.get("body", {})
		assert_false(body is Dictionary and bool((body as Dictionary).get("enabled", false)), "an off or absent body block stays off")


func test_trailing_legs_and_forward_lean() -> void:
	var rows: Array = TRAINER.fly_hang_body_rotations({"hip_extension_deg": 22.0, "knee_flexion_deg": 50.0,
		"knee_offset_deg": 12.0, "torso_lean_deg": 12.0})
	var by_bone := {}
	for row: Array in rows:
		by_bone[row[0]] = row
	assert_true(float(by_bone.LeftUpLeg[1]) > 0.0 and float(by_bone.RightUpLeg[1]) > 0.0, "thighs trail back (+X on this rig)")
	assert_true(float(by_bone.LeftLeg[1]) > 0.0, "knees bend (+X)")
	assert_true(float(by_bone.RightLeg[1]) > float(by_bone.LeftLeg[1]), "one leg trails further, not a mirrored ladder hang")
	assert_true(float(by_bone.Spine[1]) < 0.0, "torso leans forward (-X)")


func test_wing_fold_ships_on_with_its_score_and_names_rig_bones() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/fly_traversal.json"))
	assert_true(bool(cfg.landing_presentation.wing_fold_enabled), "landing wing fold ships ON (VIS-MEADOWS r1b judged gain)")
	assert_true(str(cfg.landing_presentation.get("_why_wing_fold_on", "")).contains("CPU 5.99 -> 6.33"), "wing fold records its CPU score")
	var bones: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures/f36_pose_candidates.json")).species.galecrest.bones
	for row: Array in cfg.capabilities.galecrest.landing_fold_offsets:
		assert_true(str(row[0]) in bones, "fold bone %s exists on the Galecrest rig" % row[0])
