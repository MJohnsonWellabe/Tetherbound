extends "res://tests/test_case.gd"

## UIPOSES lane: the Riptusk F36 role flag (P2-028 side-lie faint, P2-029
## prone rest) ships OFF and is well formed.

const POSES_PATH := "res://data/creatures/f36_pose_candidates.json"
const FLAG := "uiposes_riptusk_side_faint_prone_rest"


func test_riptusk_flag_is_off_and_well_formed() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POSES_PATH))
	var entry: Dictionary = data.candidate_role_flags[FLAG]
	assert_false(bool(entry.enabled), "Riptusk pose flag ships OFF")
	assert_true("rest" in entry.adds_roles)
	for id: String in ["riptusk", "water_riptusk"]:
		for role: String in ["faint", "rest"]:
			var spec: Dictionary = entry.presentations[id][role]
			var frames: Array = spec.frames
			assert_eq(float(frames[0].phase), 0.0)
			assert_eq(float(frames[-1].phase), 1.0)
			for frame: Dictionary in frames:
				assert_eq((frame.bones as Dictionary).size(), (data.species.riptusk.bones as Array).size(), "%s %s covers every bone" % [id, role])
	var last: Array = entry.presentations.riptusk.faint.frames[-1].pivot_rotation_deg
	assert_true(absf(float(last[2])) >= 70.0, "faint ends on its side")
