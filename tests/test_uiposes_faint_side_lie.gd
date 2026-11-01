extends "res://tests/test_case.gd"

## UIPOSES lane: side-lie faint presentation (P2-015/P2-028) and the Riptusk
## F36 role flag (P2-028/P2-029). Both ship OFF.

const SIDE_LIE := preload("res://scripts/creatures/faint_side_lie.gd")
const POSES_PATH := "res://data/creatures/f36_pose_candidates.json"
const FLAG := "uiposes_riptusk_side_faint_prone_rest"


func test_side_lie_ships_off() -> void:
	assert_false(bool(SIDE_LIE.config().get("enabled", true)), "creature_faint_presentation defaults OFF")
	assert_true(SIDE_LIE.recipe("terrapup").is_empty(), "no recipe while the flag is off")


func test_recipe_only_for_listed_species_when_on() -> void:
	var cfg := {"enabled": true, "species": {"terrapup": {"roll_deg": -80.0}}}
	assert_false(SIDE_LIE.recipe("terrapup", cfg).is_empty())
	assert_true(SIDE_LIE.recipe("galecrest", cfg).is_empty())


func test_rolled_transform_lies_on_side_and_stays_grounded() -> void:
	var before := Transform3D(Basis.IDENTITY, Vector3(0.0, 0.1, 0.0))
	var row := {"roll_deg": 80.0, "sink_m": 0.06, "recentre_scale": 0.5}
	var rolled := SIDE_LIE.rolled_transform(before, row, 1.6, 0.5)
	var up := rolled.basis * Vector3.UP
	assert_true(up.y < 0.25, "body up-axis is near horizontal (lying on its side)")
	assert_true(rolled.origin.y > before.origin.y, "the roll's own dip is lifted, never sunk below the ground")
	var mirrored := SIDE_LIE.rolled_transform(before, {"roll_deg": -80.0, "sink_m": 0.06, "recentre_scale": 0.5}, 1.6, 0.5)
	assert_true(absf(mirrored.origin.y - rolled.origin.y) < 0.0001, "lift is the same whichever way it falls")


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
