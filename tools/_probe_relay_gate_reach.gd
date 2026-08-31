extends SceneTree

## Scratch probe (not committed to the segment suite): can a player standing
## where GATE-F-LEG-S07's move_to walk got stuck (approaching the Tether Relay
## compound from the picket road) actually reach the gate and Officer Dell
## using the same wall-following navigator the Gate F harness itself uses?
## Settles whether the S07 move_to FAILs are a real world/geometry defect or
## a harness-navigator limitation before touching any game file.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const NAVIGATOR := preload("res://tests/helpers/stick_navigator.gd")

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _stick_left := Vector2.ZERO


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in 300:
		await process_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	if _player == null or _rig == null:
		print("no player/rig")
		quit(1)
		return

	# Start exactly where the S07 harness got stuck walking toward Officer Dell.
	_player.global_position = Vector3(333.0, 8.0, 3755.0)
	_player.velocity = Vector3.ZERO
	for i in 30:
		await physics_frame

	var nav: RefCounted = NAVIGATOR.new(self, _player, _rig,
		func(x: float, y: float) -> void: _stick_left = Vector2(x, y); _drive())

	print("=== leg 1: stuck point -> the gate world coord (342.1, 3771.6) ===")
	var gate_y := float(_world.call("ground_height_at", 342.1, 3771.6)) if _world.has_method("ground_height_at") else _player.global_position.y
	var ok1: bool = await nav.call("walk_to", Vector3(342.1, gate_y, 3771.6), 3000, 3.0)
	print("gate reach: %s, ended at %s" % [ok1, _player.global_position])

	print("=== leg 2: (from wherever leg 1 ended) -> Officer Dell (347.5, 3763.5) ===")
	var dell_y := float(_world.call("ground_height_at", 347.5, 3763.5)) if _world.has_method("ground_height_at") else _player.global_position.y
	var ok2: bool = await nav.call("walk_to", Vector3(347.5, dell_y, 3763.5), 3000, 3.0)
	print("dell reach: %s, ended at %s" % [ok2, _player.global_position])

	quit(0)


func _drive() -> void:
	_press_axis(&"move_right", clampf(_stick_left.x, 0.0, 1.0))
	_press_axis(&"move_left", clampf(-_stick_left.x, 0.0, 1.0))
	_press_axis(&"move_back", clampf(_stick_left.y, 0.0, 1.0))
	_press_axis(&"move_forward", clampf(-_stick_left.y, 0.0, 1.0))


func _press_axis(action: StringName, strength: float) -> void:
	if not InputMap.has_action(action):
		return
	if strength <= 0.001:
		Input.action_release(action)
	else:
		Input.action_press(action, strength)
	for binding in InputMap.action_get_events(action):
		var motion := binding as InputEventJoypadMotion
		if motion == null:
			continue
		var m := InputEventJoypadMotion.new()
		m.axis = motion.axis
		m.axis_value = signf(motion.axis_value) * strength
		Input.parse_input_event(m)
