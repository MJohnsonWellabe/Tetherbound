extends "res://tests/test_case.gd"

## BEINGS-STORMRAVEN-WINGS (F36#74): `rest_joints` in creature_pose_settle.gd
## holds named joints at their rest rotation through a hit or faint clip. No
## species row states it on main; the arm is an overlay. OFF until GPU-judged.

const SETTLE := preload("res://scripts/creatures/creature_pose_settle.gd")
const CONFIG := "res://data/config/creature_pose_settle.json"


func test_no_species_holds_joints_at_rest_by_default() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	for role: String in ["faint", "hit"]:
		var block: Dictionary = cfg.get(role, {})
		assert_false(block.has("rest_joints"), "no roster-wide %s rest_joints" % role)
		var rows: Dictionary = block.get("per_species", {})
		for id: Variant in rows:
			if rows[id] is Dictionary:
				assert_false((rows[id] as Dictionary).has("rest_joints"), "%s %s has no rest_joints row" % [role, id])


func test_hold_track_at_rest_replaces_or_blends_every_key() -> void:
	var rest := Quaternion(Vector3.UP, 0.3)
	var swung := Quaternion(Vector3.RIGHT, 0.6)
	var animation := Animation.new()
	var track := animation.add_track(Animation.TYPE_ROTATION_3D)
	animation.rotation_track_insert_key(track, 0.0, rest)
	animation.rotation_track_insert_key(track, 0.5, swung)
	animation.rotation_track_insert_key(track, 1.0, swung)
	var half := animation.duplicate(true) as Animation
	SETTLE.hold_track_at_rest(animation, track, rest, 0.0)
	for key in animation.track_get_key_count(track):
		assert_true((animation.track_get_key_value(track, key) as Quaternion).is_equal_approx(rest), "key %d is the rest rotation" % key)
	SETTLE.hold_track_at_rest(half, track, rest, 0.5)
	var mid: Quaternion = half.track_get_key_value(track, 1)
	assert_true(mid.is_equal_approx(rest.slerp(swung, 0.5)), "keep 0.5 blends half way back to the clip")
