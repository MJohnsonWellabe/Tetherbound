extends "res://tests/test_case.gd"

## CAUSE-POSES roster-wide faint/hit settle (creature_pose_settle.gd): ships
## OFF; OFF changes nothing on a body; ON re-keys faint and hit for both an F36
## recipe rig and an own-clip rig (grounded, collapsed, planted, recoiling).
## Body cases run in a child with an initialized SceneTree, as in
## test_f36_pose_candidates.gd.

const SETTLE := preload("res://scripts/creatures/creature_pose_settle.gd")


func test_ships_off() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SETTLE.PATH))
	assert_false(SETTLE.any_enabled(cfg), "every creature_pose_settle section defaults OFF")
	for role: String in ["faint", "hit"]:
		for part: String in (cfg[role] as Dictionary):
			assert_false(bool(cfg[role][part].enabled), "%s.%s is OFF" % [role, part])


func test_off_and_on_bodies_on_initialized_scene_tree() -> void:
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), PackedStringArray([
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/helpers/cause_poses_settle_native.gd",
	]), output, true)
	var log_text := "\n".join(output)
	var result: Dictionary = {}
	for line: String in log_text.split("\n"):
		if line.begins_with("CAUSE_POSES_RESULT="):
			var parsed: Variant = JSON.parse_string(line.trim_prefix("CAUSE_POSES_RESULT="))
			if parsed is Dictionary:
				result = parsed
	assert_eq(code, 0, log_text)
	assert_true(float(result.get("assertions", 0)) >= 20.0, log_text)
	assert_eq(result.get("failures"), [], log_text)
	for marker: String in ["SCRIPT ERROR", "Parse Error", "resources still in use", "instances were leaked"]:
		assert_false(log_text.contains(marker), log_text)
