extends "res://tests/test_case.gd"

## P2-119 UIPOSES candidate: fly_traversal hang_pose.body ships OFF; when on,
## the legs trail back with bent knees and the torso leans forward.

const TRAINER := preload("res://scripts/player/trainer_model.gd")
const FLY := preload("res://scripts/player/fly_controller.gd")


func test_hang_body_ships_off() -> void:
	var body: Dictionary = FLY.hang_pose().get("body", {})
	assert_false(body.is_empty(), "hang_pose.body is authored")
	assert_false(bool(body.get("enabled", true)), "hang_pose.body defaults OFF")


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


func test_wing_fold_ships_off_and_names_rig_bones() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/fly_traversal.json"))
	assert_false(bool(cfg.landing_presentation.wing_fold_enabled), "landing wing fold defaults OFF")
	var bones: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/creatures/f36_pose_candidates.json")).species.galecrest.bones
	for row: Array in cfg.capabilities.galecrest.landing_fold_offsets:
		assert_true(str(row[0]) in bones, "fold bone %s exists on the Galecrest rig" % row[0])
