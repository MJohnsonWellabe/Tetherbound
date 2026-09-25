extends "res://tests/test_case.gd"

const MANAGER := preload("res://scripts/combat/combat_manager.gd")

class Rig extends Node3D:
	var _target: Node3D
	var _distance := 6.0
	var _shoulder := 1.0
	var _tracking_manual_left := 0.0
	var yaw := 0.0
	var pitch := -0.4

class ManagerFixture extends "res://scripts/combat/combat_manager.gd":
	var room := -1.0
	var wanted_shoulder := 2.0
	func _room_clearance() -> float: return room
	func _combat_camera_framing_target(_framing: Dictionary) -> float: return 0.0
	func _combat_shoulder_offset(_distance: float, _pitch: float) -> float: return wanted_shoulder


func test_visible_width_changes_required_shoulder_without_raising_safety_cap() -> void:
	var small := MANAGER.shoulder_for_extents(5.0, 10.0, 0.1, 0.1)
	var wide := MANAGER.shoulder_for_extents(5.0, 10.0, 0.7, 0.2)
	assert_true(wide > small, "live width must influence clearance")
	assert_almost_eq(MANAGER.shoulder_for_extents(5.0, 1.0, 2.0, 1.0), MANAGER.SHOULDER_MAX_M,
		0.0001, "impossible close overlap must not move an uncollided pivot past its safety cap")


func test_uncapped_parallax_clears_both_projected_edges() -> void:
	var setback := 5.0
	var gap := 10.0
	var shoulder := MANAGER.shoulder_for_extents(setback, gap, 0.7, 0.2)
	var parallax_at_ally := shoulder * gap / (setback + gap)
	var visible_edges := 0.7 + 0.2 * setback / (setback + gap)
	assert_almost_eq(parallax_at_ally - visible_edges, MANAGER.SHOULDER_CLEARANCE_FLOOR_M)


func test_live_update_preserves_manual_look_throw_target_and_room_constraint() -> void:
	var manager := ManagerFixture.new()
	var rig := Rig.new()
	var ally := Node3D.new()
	var other_target := Node3D.new()
	rig._target = ally
	manager.set("_camera_rig", rig)
	manager.set("_ally_body", ally)
	manager.call("_update_combat_camera_framing", 1.0)
	assert_true(rig._shoulder > 1.0, "ordinary combat refreshes stale shoulder")
	rig._shoulder = 1.0
	rig._tracking_manual_left = 0.3
	manager.call("_update_combat_camera_framing", 1.0)
	assert_almost_eq(rig._shoulder, 1.0, 0.0001, "manual look grace owns its framing")
	rig._tracking_manual_left = 0.0
	rig._target = other_target
	manager.call("_update_combat_camera_framing", 1.0)
	assert_almost_eq(rig._shoulder, 1.0, 0.0001, "throw/catch target is untouched")
	rig._target = ally
	manager.room = 2.0
	manager.call("_update_combat_camera_framing", 1.0)
	# F04: a nearby wall is not a camera-distance ceiling or a shoulder reset.
	# SpringArm3D and the rig's swept pivot handle real geometry; the request
	# keeps the full framing distance and the solved shoulder.
	var base := float((load("res://scripts/combat/combat_math.gd").config().get("camera", {}) as Dictionary).get("distance", 6.0))
	assert_almost_eq(rig._distance, base, 0.0001, "the nearest wall no longer truncates the distance request")
	assert_true(rig._shoulder > 1.0, "the nearest wall no longer zeroes the shoulder")
	manager.free()
	rig.free()
	ally.free()
	other_target.free()


func test_the_room_distance_cap_is_one_shipped_config_value_and_it_is_off() -> void:
	# F04: the cap moved in and out across batches. It is now a single config
	# value; flipping it needs a new in-engine capture (combat.json `_why`).
	var framing: Dictionary = ((load("res://scripts/combat/combat_math.gd").config()
		.get("camera", {}) as Dictionary).get("framing", {}) as Dictionary)
	assert_true(framing.has("room_distance_cap"), "the room cap is declared in config")
	assert_false(bool(framing.get("room_distance_cap", true)), "the shipped room cap is off")
