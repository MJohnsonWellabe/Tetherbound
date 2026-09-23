extends "res://tests/test_case.gd"

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const GLOW := preload("res://scripts/combat/telegraph_glow.gd")
const CAMERA := preload("res://scripts/player/camera_rig.gd")

class CameraSpy extends Node:
	var nudges := 0
	func nudge_combat_impact(_config: Dictionary) -> void:
		nudges += 1

class Beat extends Node3D:
	var active := true
	func is_active() -> bool:
		return active


func test_only_charged_landing_requests_camera_nudge() -> void:
	var manager := MANAGER.new()
	var camera := CameraSpy.new()
	manager.set("_camera_rig", camera)
	manager.call("_nudge_camera_on_landing", false)
	assert_eq(camera.nudges, 0, "quick landing must leave camera alone")
	manager.call("_nudge_camera_on_landing", true)
	assert_eq(camera.nudges, 1)
	manager.free()
	camera.free()


func test_nudge_returns_to_neutral_without_changing_aim() -> void:
	var camera := CAMERA.new()
	camera.rotation = Vector3(0.2, 0.7, 0.0)
	camera.nudge_combat_impact({"seconds": 0.16, "degrees": 0.65})
	camera.call("_tick_impact_nudge", 0.04)
	assert_true(camera.rotation.z > 0.0, "charged impact produces a brief visible roll")
	assert_almost_eq(camera.rotation.x, 0.2)
	assert_almost_eq(camera.rotation.y, 0.7)
	camera.call("_tick_impact_nudge", 0.2)
	assert_almost_eq(camera.rotation.z, 0.0)
	camera.nudge_combat_impact({"enabled": false})
	camera.call("_tick_impact_nudge", 0.04)
	assert_almost_eq(camera.rotation.z, 0.0)
	camera.free()


func test_reduced_motion_removes_the_impact_roll_only() -> void:
	# UX §8: reduced motion lowers camera impulse. The roll is pure impulse,
	# so it goes; the same nudge with the setting off still rolls.
	var motion := preload("res://scripts/ui/motion_prefs.gd")
	var camera := CAMERA.new()
	motion.set_reduced_motion(true)
	camera.nudge_combat_impact({"seconds": 0.16, "degrees": 0.65})
	camera.call("_tick_impact_nudge", 0.04)
	# With reduced motion on, a charged impact must not roll the camera.
	assert_almost_eq(camera.rotation.z, 0.0)
	motion.set_reduced_motion(false)
	camera.nudge_combat_impact({"seconds": 0.16, "degrees": 0.65})
	camera.call("_tick_impact_nudge", 0.04)
	assert_true(camera.rotation.z > 0.0, "with it off, the roll is back")
	camera.free()


func test_state_glow_survives_hitstop_and_ends_on_interruption() -> void:
	var parent := Node3D.new()
	var beat := Beat.new()
	parent.add_child(beat)
	var glow := GLOW.begin(parent, Vector3.ZERO, Color.CYAN, 1.1, 0.1)
	glow.call("_ready")
	glow.call("follow_state", beat, beat.is_active)
	glow.call("_physics_process", 0.3)
	assert_false(glow.is_queued_for_deletion(), "state duration outranks wall-clock lifetime")
	beat.active = false
	glow.call("_physics_process", 0.01)
	assert_true(glow.is_queued_for_deletion(), "interrupted warning must not outlive its wind-up")
	parent.free()


func test_player_stagger_uses_distinct_glow_and_reuses_duplicate_record() -> void:
	var manager := MANAGER.new()
	var arena := Node3D.new()
	var body := Node3D.new()
	arena.add_child(body)
	manager.set("_arena", arena)
	manager.set("_ally_body", body)
	manager.set("_action", MANAGER.Action.STAGGER)
	manager.call("_announce_stagger", false)
	manager.call("_announce_stagger", false)
	assert_eq(arena.get_child_count(), 2, "one body, one stagger ring despite duplicate notification")
	var ring := arena.get_child(1)
	assert_ne(ring.get("_colour"), Color("#ff40e6"), "stagger must differ from warning")
	ring.call("_ready")
	ring.call("_physics_process", 0.8)
	assert_false(ring.is_queued_for_deletion(), "stagger ring follows the rooted state")
	manager.set("_action", MANAGER.Action.READY)
	ring.call("_physics_process", 0.01)
	assert_true(ring.is_queued_for_deletion())
	manager.free()
	arena.free()
