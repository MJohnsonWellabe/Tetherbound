extends SceneTree

## G3-HARNESS-0904 / 2.9. Does the FIXED `stick_navigator.gd` actually leave
## the Pond basin from the exact coordinate GATE2-EVIDENCE-0903 recorded it
## freezing at, walking the real bearing toward the Old Bram detour -- no
## `S05-32x` workaround waypoint, no teleport?
##
##   godot --headless --path . --script tools/gate_f/probe_pond_walker_fix.gd
##
## `probe_pond_stranding.gd` already proved the WORLD is passable there (0/10
## stands wedged under a raw stick push). This probe answers the other half:
## does the WALKER, unassisted, now get out. Same scene, same coordinate, same
## bearing GATE2-EVIDENCE-0903's own S05 run recorded stalling on for 543 s
## across a 29,250-frame budget -- run here through the real
## `tests/helpers/stick_navigator.gd::walk_to()`, the same call every Gate F
## journey segment uses.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

## Where GATE2-EVIDENCE-0903's S05 run froze, to the centimetre, on three
## independent runs.
const STALL := Vector3(-328.7, -14.2, 505.3)
## The Old Bram detour -- the bearing the walker was driving at when it froze.
const DETOUR_TARGET := Vector3(195.0, 0.0, 905.0)
## The original run's own budget for this leg, so "did it get out" is judged
## on the same terms the failing run was.
const BUDGET_FRAMES := 29250
const SETTLE_FRAMES := 300

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _stick := Vector2.ZERO


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	_player = _find_player(_world)
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("PROBE FAIL: player=%s rig=%s" % [str(_player), str(_rig)])
		quit(1)
		return

	_player.global_position = STALL
	_player.velocity = Vector3.ZERO
	_rig.global_position = STALL
	for i in 90:
		await physics_frame

	print("=== fixed-walker pond exit probe ===")
	print("start (%.1f, %.1f, %.1f); target (%.1f, %.1f, %.1f); budget %d frames"
		% [STALL.x, STALL.y, STALL.z, DETOUR_TARGET.x, DETOUR_TARGET.y, DETOUR_TARGET.z, BUDGET_FRAMES])

	var nav: RefCounted = NAVIGATOR.new(self, _player, _rig,
		func(x: float, y: float) -> void: _stick = Vector2(x, y); _drive_stick())

	var t0 := Time.get_ticks_msec()
	var frame0 := Engine.get_physics_frames()
	var arrived: bool = await nav.walk_to(DETOUR_TARGET, BUDGET_FRAMES, 4.0)
	var frames_spent := Engine.get_physics_frames() - frame0
	var wall_ms := Time.get_ticks_msec() - t0
	var final_pos := _player.global_position
	var remaining := Vector2(final_pos.x - DETOUR_TARGET.x, final_pos.z - DETOUR_TARGET.z).length()

	_stick = Vector2.ZERO
	_drive_stick()

	print("arrived=%s frames_spent=%d (%.1f play-seconds) wall_ms=%d"
		% [str(arrived), frames_spent, float(frames_spent) / 60.0, wall_ms])
	print("final position (%.1f, %.1f, %.1f); %.1f m short of target"
		% [final_pos.x, final_pos.y, final_pos.z, remaining])
	print("VERDICT INPUT: %s" % ("ARRIVED -- walker leaves the basin unassisted" if arrived
		else "DID NOT ARRIVE within budget -- walker still cannot leave the basin unassisted"))
	quit(0)


func _drive_stick() -> void:
	_axis(JOY_AXIS_LEFT_X, _stick.x)
	_axis(JOY_AXIS_LEFT_Y, _stick.y)


func _axis(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = axis
	event.axis_value = clampf(value, -1.0, 1.0)
	Input.parse_input_event(event)


func _find_player(from: Node) -> CharacterBody3D:
	if from is CharacterBody3D and str(from.name) == "Player":
		return from as CharacterBody3D
	for child in from.get_children():
		var found := _find_player(child)
		if found != null:
			return found
	return null
