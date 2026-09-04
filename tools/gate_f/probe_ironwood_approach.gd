extends SceneTree

## G3-HARNESS-0904. S08's run this session stalled walking from the Old Mill
## Crossing landing toward the Ironwood Grove -- 747.6 m short of (-345, 5060)
## after 45,000 walking frames (750 play-seconds), wedged near (-164, -9, 4335),
## very close to the crossing itself. Confirmed DETERMINISTIC (identical
## freeze coordinate on two independent full S08 runs) and NOT reproduced by
## this isolated stick_navigator.gd-only walk over the same start/target
## bearing, which arrives cleanly -- see G3-HARNESS-0904's report for the
## full writeup and what was and was not ruled out (CarveFailsafe volumes:
## ruled out via probe_carve_failsafe_at.gd; the isolated walk here: succeeds,
## which is why 2.9's fix is not implicated). Root cause still open.
##
## BUDGET_FRAMES is 12000, not S08-22's real 45000: this is a fast go/no-go
## check (arrives well inside 12000 when it arrives at all), not a full
## reproduction of the segment's own budget.
##
##   godot --headless --path . --script tools/gate_f/probe_ironwood_approach.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

## build_s08_entry_synthetic.gd's own settle point (far_point(35.0) past the crossing).
const START := Vector3(-152.0, -2.15, 4238.0)
const TARGET := Vector3(-345.0, 0.0, 5060.0)
const BUDGET_FRAMES := 12000
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

	_player.global_position = START
	_player.velocity = Vector3.ZERO
	_rig.global_position = START
	for i in 90:
		await physics_frame

	print("=== ironwood approach probe ===")
	print("start (%.1f, %.1f, %.1f); target (%.1f, %.1f, %.1f); budget %d frames"
		% [START.x, START.y, START.z, TARGET.x, TARGET.y, TARGET.z, BUDGET_FRAMES])

	var nav: RefCounted = NAVIGATOR.new(self, _player, _rig,
		func(x: float, y: float) -> void: _stick = Vector2(x, y); _drive_stick())

	var t0 := Time.get_ticks_msec()
	var frame0 := Engine.get_physics_frames()
	var arrived: bool = await nav.walk_to(TARGET, BUDGET_FRAMES, 4.0)
	var frames_spent := Engine.get_physics_frames() - frame0
	var wall_ms := Time.get_ticks_msec() - t0
	var final_pos := _player.global_position
	var remaining := Vector2(final_pos.x - TARGET.x, final_pos.z - TARGET.z).length()

	_stick = Vector2.ZERO
	_drive_stick()

	print("arrived=%s frames_spent=%d (%.1f play-seconds) wall_ms=%d"
		% [str(arrived), frames_spent, float(frames_spent) / 60.0, wall_ms])
	print("final position (%.1f, %.1f, %.1f); %.1f m short of target"
		% [final_pos.x, final_pos.y, final_pos.z, remaining])
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
