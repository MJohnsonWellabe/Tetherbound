extends "res://tests/test_case.gd"

## BEINGS-FLY-SHOULDER (F38#8): fly_traversal.json hang_pose.shoulder_grip_1113,
## OFF until GPU-judged. When on, the carrier's feet hold the trainer's
## shoulders (trainer_model.gd fly_grip_world_points) instead of the wrists.

const FLY := preload("res://scripts/player/fly_controller.gd")
const TRAINER_MODEL := preload("res://scripts/player/trainer_model.gd")


func test_flag_is_off_and_presentation_only() -> void:
	var block: Dictionary = FLY.hang_pose().get("shoulder_grip_1113", {})
	assert_false(block.is_empty(), "the block exists")
	assert_false(bool(block.get("enabled", true)), "it is OFF until GPU-judged")
	assert_eq(str(block.get("scope", "")), "client_presentation")
	assert_eq((block.get("upper", []) as Array).size(), 3, "upper arm direction is a vector")
	assert_eq((block.get("forearm", []) as Array).size(), 3, "forearm direction is a vector")


func test_shoulder_grip_reads_only_while_on() -> void:
	var model: Node = TRAINER_MODEL.new()
	var pose := FLY.hang_pose().duplicate(true)
	model.set("_fly_pose", pose)
	assert_true((model.call("shoulder_grip") as Dictionary).is_empty(), "OFF: no shoulder grip, the wrists stay the grip")
	(pose["shoulder_grip_1113"] as Dictionary)["enabled"] = true
	model.set("_fly_pose", pose)
	var on: Dictionary = model.call("shoulder_grip")
	assert_false(on.is_empty(), "ON: the shoulder grip block is read")
	assert_true(float(on.get("grip_lift_m", 0.0)) > 0.0, "the feet sit a little above the shoulder joint")
	assert_eq((model.call("fly_grip_world_points") as Array).size(), 0, "without a rig there are no grip points (callers fall back)")
	model.free()


func test_carrier_alignment_asks_the_model() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/player/fly_controller.gd")
	assert_true(source.contains("fly_grip_world_points"), "align_carrier_grip reads the model's grip points (local and remote carriers)")
