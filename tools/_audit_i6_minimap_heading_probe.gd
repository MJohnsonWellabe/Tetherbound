extends SceneTree

## BACKLOG-I6-MINIMAP-HEADING, diagnosis only -- root-causes the mismatch
## `tests/smoke_gate_a_map_cycle.gd::_check_actual_travel_drives_minimap()`
## reports ("minimap heading 3.142 does not match resolved travel 2.096"),
## standing since `ralph/reports/handover-T5-OPENING-2026-08-30.md:314-317`
## and reconfirmed by Audit I6 (`ralph/reports/audit/I-2026-08-31.md:255-300`).
##
## Reproduces byte-identical on `origin/main` (`453107fb`): both numbers,
## every run. This probe replays the same real-pad `_hold_axis(JOY_AXIS_
## LEFT_X, 1.0, 70)` the smoke test uses, but samples `_player.global_position`,
## `minimap._movement_yaw` AND `player._deflect_left`/`_deflect_wanted`
## (player_controller.gd:327-334, the OF15 "slide around what you walk into"
## obstacle mechanic) on every physics frame, instead of only before/after.
##
## FINDING. The trainer's real path during the held 70-frame stick input is
## NOT a straight line -- it has two distinct, exact-heading segments:
##
##   phase 1: displacement (+0.083, 0.0)/frame, yaw = 1.571 (due east)
##   phase 2: displacement (0.0, -0.083)/frame, yaw = 3.142 (due south, exact PI)
##
## and `player._deflect_left` goes from 0.0 to >0.0 (OF15 deflection engaging,
## `DEFLECT_FOR = 0.3s` = 18 physics frames) at EXACTLY the physics frame the
## heading flips, and stays >0.0 for the rest of the hold -- the trainer
## collided with an obstacle near spawn partway through the hold and OF15's
## slide-around-what-you-walk-into deflection (`player_controller.gd:287-334`,
## an owner-directed real feature, not a bug) took over for the rest of the
## window, redirecting travel ~90 degrees.
##
## `minimap._movement_yaw` (`scripts/ui/minimap.gd:120-131`) is a LIVE sample:
## every `update_view()` call recomputes it fresh from only the immediately
## preceding frame's displacement, so by the time the stick is released it
## correctly holds the trainer's true, current, final heading -- 3.142, due
## south, exactly what phase 2 was doing.
##
## The smoke test's `expected` (`tests/smoke_gate_a_map_cycle.gd:95-102`) is
## instead one atan2 over the NET displacement between a position sampled
## BEFORE the hold and one sampled 78 frames later (70 held + 8 release/decel,
## AFTER the deflection). That single vector blends phase 1 and phase 2 into
## 2.096 rad -- a direction the trainer was never actually facing or moving in
## at any single instant; it is the chord of a two-segment path, not either
## segment's real heading.
##
## So the two numbers disagree because they answer different questions
## whenever the sampled window contains a heading change (which OF15 makes a
## routine occurrence near any rock/prop/village structure), not because
## `_movement_yaw`'s own frame-to-frame math is wrong. Diagnosis only -- no
## fix applied. Whether the real fix is "give the smoke test a straight,
## obstacle-free run" or "smooth/average `_movement_yaw` over a short window
## so a brief deflection doesn't visibly snap the compass" is a design call
## for the follow-up task, not decided here.
##
## Invocation:
##
##   godot --headless --path . --script tools/_audit_i6_minimap_heading_probe.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const HOLD_FRAMES := 70
const RELEASE_FRAMES := 8

var _player: CharacterBody3D = null
var _minimap: Control = null


func _init() -> void:
	_run()


func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	current_scene = world
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = world.get_node_or_null(^"Player") as CharacterBody3D
	var hud := world.get_node_or_null(^"PlaygroundHUD")
	_minimap = hud.get("_minimap") as Control if hud != null else null
	if _player == null or _minimap == null:
		print("PROBE FAIL: could not find Player/HUD minimap in the booted scene")
		quit(1)
		return

	for i in 8:
		await physics_frame
	var before: Vector3 = _player.global_position
	print("probe before=%s" % [before])

	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 1.0
	Input.parse_input_event(motion)

	var last_yaw := INF
	var last_deflecting := false
	for i in HOLD_FRAMES:
		await physics_frame
		var yaw: float = float(_minimap.get("_movement_yaw"))
		var deflect_left: float = float(_player.get("_deflect_left"))
		var deflecting := deflect_left > 0.0
		if absf(yaw - last_yaw) > 0.01 or deflecting != last_deflecting:
			print("frame=%d pos=%s movement_yaw=%.3f deflect_left=%.3f (%s)" % [
				i, _player.global_position, yaw, deflect_left,
				"OF15 DEFLECTING" if deflecting else "free travel",
			])
		last_yaw = yaw
		last_deflecting = deflecting

	var release := InputEventJoypadMotion.new()
	release.axis = JOY_AXIS_LEFT_X
	release.axis_value = 0.0
	Input.parse_input_event(release)
	for i in RELEASE_FRAMES:
		await physics_frame

	var after: Vector3 = _player.global_position
	var displacement := Vector2(after.x - before.x, after.z - before.z)
	var expected := atan2(displacement.x, displacement.y)
	var movement_yaw := float(_minimap.get("_movement_yaw"))
	print("")
	print("probe after=%s displacement=%s" % [after, displacement])
	print("probe net-displacement heading (smoke test's 'expected') = %.3f" % expected)
	print("probe minimap._movement_yaw (live, final) = %.3f" % movement_yaw)
	print("probe mismatch = %.3f rad" % absf(angle_difference(expected, movement_yaw)))
	quit(0)
