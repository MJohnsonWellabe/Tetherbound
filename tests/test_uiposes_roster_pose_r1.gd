extends "res://tests/test_case.gd"

## Roster-wide F36 candidate (UIPOSES): ships OFF; faint ends side-lying with
## no pitch; hit recoils early and returns; remake-owned species are skipped.

const R1 := preload("res://scripts/creatures/roster_pose_r1.gd")
const POSES := "res://data/creatures/f36_pose_candidates.json"


func _data() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(POSES))


func test_ships_off() -> void:
	assert_false(R1.enabled(_data()), "roster_pose_r1 defaults OFF")


func test_faint_ends_side_lying_without_pitch_for_every_profile() -> void:
	var data := _data()
	var cfg := R1.settings(data)
	var checked := 0
	for name: String in data.profiles:
		var profile: Dictionary = data.profiles[name]
		if not profile.has("faint"):
			continue
		var faint := R1.faint_side_lie(profile.faint, cfg)
		var first: Array = faint.frames[0].pivot_rotation_deg
		var last: Array = faint.frames[-1].pivot_rotation_deg
		assert_eq(float(last[0]), 0.0, "%s faint has no nose-down pitch" % name)
		assert_true(absf(float(last[2])) >= 70.0, "%s faint ends on its side" % name)
		assert_true(absf(float(first[2])) < 1.0, "%s faint starts standing" % name)
		assert_eq((faint.frames as Array).size(), (profile.faint.frames as Array).size(), "%s keeps its authored frames" % name)
		checked += 1
	assert_true(checked > 40, "covers the roster's profiles (%d)" % checked)


func test_hit_recoils_and_returns() -> void:
	var spec := {"duration_s": 0.3, "loop": false, "frames": [
		{"phase": 0.0, "bones": {}, "pivot_roll_deg": 0, "pivot_rotation_deg": [0.0, 0.0, 0.0]},
		{"phase": 0.3, "bones": {}, "pivot_roll_deg": 0, "pivot_rotation_deg": [0.0, 0.0, 0.0]},
		{"phase": 1.0, "bones": {}, "pivot_roll_deg": 0, "pivot_rotation_deg": [0.0, 0.0, 0.0]}]}
	var hit := R1.hit_recoil(spec, {"hit_pitch_deg": -11.0, "hit_lean_deg": 5.0, "recoil_peak": 0.3})
	assert_true(absf(float(hit.frames[0].pivot_rotation_deg[0])) < 0.01, "starts at rest")
	assert_true(float(hit.frames[1].pivot_rotation_deg[0]) <= -10.9, "peaks with a visible recoil")
	assert_true(absf(float(hit.frames[2].pivot_rotation_deg[0])) < 0.01, "returns to rest")


func test_remake_owned_species_are_skipped() -> void:
	var flags := {"flags": {"remake_owner1101_voltwig": true, "remake_owner1101_pebbik": {"enabled": false}}}
	assert_true(R1.remake_owned("voltwig", flags))
	assert_true(R1.remake_owned("water_voltwig", flags))
	assert_false(R1.remake_owned("pebbik", flags))
	assert_false(R1.remake_owned("craghorn", flags))
