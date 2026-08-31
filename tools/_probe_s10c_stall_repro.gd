extends SceneTree

## GATE-F-LEG-S10CDE. Reproduce the S10c walk-back stall directly: boot the
## world, teleport the player to just before the stall point, drive the SAME
## stick_navigator.gd toward the same target the failed move_to used, and log
## per-frame physics state (position, velocity, on_floor) to see what actually
## happens to the body, rather than inferring from route.csv's 0.5 Hz trace.

const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const START := Vector3(13.47, 20.0, 7416.99)
const TARGET := Vector3(-8.0, 0.0, 7100.0)

var _stick := Vector2.ZERO

func _init() -> void:
	_run()

func _run() -> void:
	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in 90:
		await physics_frame

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	if player == null:
		for child in world.get_children():
			print("child: ", child.name, " ", child.get_class())
		print("no Player node found by that name")
		quit(1)
		return
	if rig == null:
		print("no CameraRig node found by that name")
		quit(1)
		return

	player.global_position = START
	if player is CharacterBody3D:
		(player as CharacterBody3D).velocity = Vector3.ZERO
	for i in 200:
		await physics_frame
		if i % 10 == 0 and player is CharacterBody3D:
			print("settle f=%3d pos=%s on_floor=%s" % [i, player.global_position, (player as CharacterBody3D).is_on_floor()])

	print("start: %s locomotion_enabled=%s" % [player.global_position,
		player.call("locomotion_enabled") if player.has_method("locomotion_enabled") else "n/a"])

	var nav: RefCounted = NAVIGATOR.new(self, player, rig,
		func(x: float, y: float) -> void: _stick = Vector2(x, y); _drive(player))

	nav.call("reset")
	var last := player.global_position
	for i in 400:
		await nav.call("step", TARGET)
		if i % 5 == 0:
			var vel := Vector3.ZERO
			var on_floor := false
			if player is CharacterBody3D:
				vel = (player as CharacterBody3D).velocity
				on_floor = (player as CharacterBody3D).is_on_floor()
			var moved := player.global_position.distance_to(last)
			last = player.global_position
			print("f=%3d pos=%s stick=%s vel=%s on_floor=%s moved=%.4f can_walk=%s" % [
				i, player.global_position, _stick, vel, on_floor, moved,
				nav.call("can_walk")])
	quit(0)


func _drive(player: Node3D) -> void:
	# Mirror operator_harness.gd's _drive_sticks/_press_axis exactly: both the
	# action strength AND the parsed physical joypad motion event.
	_press_axis(&"move_right", clampf(_stick.x, 0.0, 1.0))
	_press_axis(&"move_left", clampf(-_stick.x, 0.0, 1.0))
	_press_axis(&"move_back", clampf(_stick.y, 0.0, 1.0))
	_press_axis(&"move_forward", clampf(-_stick.y, 0.0, 1.0))


func _press_axis(action: StringName, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength <= 0.001:
		Input.action_release(action)
	else:
		Input.action_press(action, strength)
	for event: InputEvent in InputMap.action_get_events(action):
		var motion := event as InputEventJoypadMotion
		if motion == null:
			continue
		var m := InputEventJoypadMotion.new()
		m.axis = motion.axis
		m.axis_value = signf(motion.axis_value) * strength
		Input.parse_input_event(m)
		break
