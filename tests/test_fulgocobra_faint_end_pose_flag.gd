extends "res://tests/test_case.gd"

## F36#46 candidate: Fulgocobra-only settle scope with stated end pitches for
## the neck. OFF until a GPU verdict; no other species carries an end pose.

const CONFIG := "res://data/config/creature_pose_settle.json"


func test_scope_is_off_and_fulgocobra_only() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var scope: Dictionary = cfg.get("below6_fulgocobra_scope", {})
	assert_false(bool(scope.get("enabled", true)))
	assert_eq(scope.get("species", []), ["fulgocobra"])


func test_only_fulgocobra_states_an_end_pose() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var faint: Dictionary = cfg.get("faint", {})
	assert_false(faint.has("end_pose"), "no roster-wide end pose")
	var rows: Dictionary = faint.get("per_species", {})
	for id: Variant in rows:
		if rows[id] is Dictionary and (rows[id] as Dictionary).has("end_pose"):
			assert_eq(str(id), "fulgocobra")
	var pose: Dictionary = (rows.get("fulgocobra", {}) as Dictionary).get("end_pose", {})
	assert_true(bool(pose.get("enabled", false)))
	var joints: Dictionary = pose.get("joints", {})
	assert_eq(joints.size(), 4)
	for joint: Variant in joints:
		assert_true(str(joint).begins_with("spine_"))
		assert_true(float(joints[joint]) < 0.0, "every neck joint is lowered")
