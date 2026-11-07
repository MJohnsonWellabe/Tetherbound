extends "res://tests/test_case.gd"

## CAUSE-POSES roster-wide faint/hit settle (creature_pose_settle.gd): ships
## OFF; OFF changes nothing on a body; ON re-keys faint and hit for both an F36
## recipe rig and an own-clip rig (grounded, collapsed, planted, recoiling).
## Body cases run in a child with an initialized SceneTree, as in
## test_f36_pose_candidates.gd.

const SETTLE := preload("res://scripts/creatures/creature_pose_settle.gd")


func test_ships_off() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SETTLE.PATH))
	assert_false(bool(cfg.get("enabled", true)), "the creature_pose_settle arm (master enabled) ships OFF")
	assert_false(SETTLE.any_enabled(cfg), "no section applies while the master flag is OFF")
	var on := cfg.duplicate(true)
	on["enabled"] = true
	assert_true(SETTLE.any_enabled(on), "flipping the master flag alone arms the sections")


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


func test_enabled_scopes_union_their_species_and_master_or_none_change_nothing() -> void:
	var cfg := {"enabled": false,
		"tidewake_scope": {"enabled": true, "species": ["ripplet", "riptusk"]},
		"lanekit_mosshell_scope": {"enabled": true, "species": ["mosshell", "riptusk"]},
		"other_scope": {"enabled": false, "species": ["galecrest"]}}
	var out: Dictionary = SETTLE.scoped(cfg)
	assert_eq(out.enabled, true)
	assert_eq(out.only_species, ["ripplet", "riptusk", "mosshell"])
	cfg.tidewake_scope.enabled = false
	cfg.lanekit_mosshell_scope.enabled = false
	assert_eq(SETTLE.scoped(cfg), cfg, "no enabled scope changes nothing")
	var master := {"enabled": true, "lanekit_mosshell_scope": {"enabled": true, "species": ["mosshell"]}}
	assert_eq(SETTLE.scoped(master), master, "the roster-wide master ignores scopes")
	var shipped: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/creature_pose_settle.json"))
	# Shipped: master OFF; lanekit_mosshell_scope ON (F38#26 judged gain), tidewake_scope OFF.
	var live: Dictionary = SETTLE.scoped(shipped)
	assert_eq(live.enabled, true)
	assert_eq(live.only_species, ["mosshell"])
