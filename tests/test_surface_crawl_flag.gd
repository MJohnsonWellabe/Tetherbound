extends "res://tests/test_case.gd"

## F39#5 (LANE-BELOW6, 12 Nov 2026): `surface_crawl_1112` in human_swim_visual.json
## is the last swim-pose layer and changes pose keys only while it is on.

const TRAINER_MODEL := preload("res://scripts/player/trainer_model.gd")
const CONFIG := "res://data/config/human_swim_visual.json"


func test_flag_is_declared_with_pose_keys_only() -> void:
	var cfg: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) as Dictionary).get("surface_crawl_1112", {})
	assert_false(cfg.is_empty(), "surface_crawl_1112 is declared")
	assert_eq(str(cfg.get("scope", "")), "client_presentation")
	var pose: Dictionary = cfg.get("swim_pose", {})
	for key: String in pose:
		assert_true(key in ["chest_above_surface_m", "body_pitch_deg", "head_lift_deg", "neck_lift_deg", "arm_lateral",
			"arm_depth", "forearm_depth", "arm_recover_lift", "forearm_recover_scale", "stroke_seconds", "kick_deg", "knee_deg",
			"arm_reach_scale", "forearm_minimum_reach", "forearm_lateral_scale"],
			"%s is a pose key" % key)
	assert_true(float(pose.get("arm_reach_scale", 1.0)) < 1.0, "the arms sweep beside the shoulders instead of reaching past the head")


func test_loaded_pose_follows_the_flag() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var loaded := TRAINER_MODEL.load_human_swim_visual()
	var crawl: Dictionary = raw.get("surface_crawl_1112", {})
	var wanted := float((crawl.get("swim_pose", {}) as Dictionary).get("arm_reach_scale", 1.0))
	if bool(crawl.get("enabled", false)):
		assert_eq(float(loaded.get("arm_reach_scale", 1.0)), wanted, "on: the crawl layer wins")
	else:
		assert_eq(float(loaded.get("arm_reach_scale", 1.0)), 1.0, "off: the stroke is the one that ships")
