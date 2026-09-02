extends Node3D

## M0 hardware probe.
##
## This scene exists to answer four questions before any game code is written,
## because each of them is cheaper to find out now than at export time:
##
##   1. Does the project open and run from a clean checkout?
##   2. Is a controller detected, and which one?
##   3. Do the input map actions actually resolve to physical inputs?
##   4. Does the exported Windows build behave the same as the editor?
##
## It is deliberately not a movement prototype. Movement feel is M1 and has its
## own acceptance gate (docs/specs/MEADOWS_VERTICAL_SLICE.md). The capsule moves only
## enough to prove the sticks are wired to the right axes.

## Metres per second. Placeholder for the probe only. The real value is TUNABLE
## and belongs in a movement config in M1, not here.
const PROBE_SPEED := 6.0
const PROBE_GRAVITY := 22.0

@onready var _player: CharacterBody3D = $Player
@onready var _camera: Camera3D = $Camera3D
@onready var _readout: Label = $UI/Readout


func _ready() -> void:
	# Godot only reports pads it has seen connect. Log at boot so a pad that
	# fails to enumerate is visible in the console, not just absent on screen.
	for device_id in Input.get_connected_joypads():
		print("[boot] joypad %d: %s" % [device_id, Input.get_joy_name(device_id)])
	if Input.get_connected_joypads().is_empty():
		print("[boot] no joypad detected at startup")

	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	var state := "connected" if connected else "disconnected"
	print("[boot] joypad %d %s: %s" % [device_id, state, Input.get_joy_name(device_id)])


func _physics_process(delta: float) -> void:
	# Read through the input map, never through raw device polling. Every
	# gameplay system in this project reads intent this way; see
	# docs/TECHNICAL_ARCHITECTURE.md, section Input.
	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	_player.velocity.x = move.x * PROBE_SPEED
	_player.velocity.z = move.y * PROBE_SPEED
	if not _player.is_on_floor():
		_player.velocity.y -= PROBE_GRAVITY * delta
	else:
		_player.velocity.y = 0.0
	_player.move_and_slide()

	_camera.look_at(_player.global_position + Vector3.UP, Vector3.UP)
	_readout.text = _build_readout(move)


func _build_readout(move: Vector2) -> String:
	var lines: Array[String] = []
	lines.append("TETHERBOUND — M0 boot probe")
	lines.append("Godot %s" % Engine.get_version_info().string)
	lines.append("")

	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		lines.append("controller: NONE DETECTED")
	else:
		for device_id in pads:
			lines.append("controller %d: %s" % [device_id, Input.get_joy_name(device_id)])
			lines.append("  known to SDL: %s" % ("yes" if Input.is_joy_known(device_id) else "NO — mapping may be wrong"))

	lines.append("")
	lines.append("move   x %+.2f   y %+.2f" % [move.x, move.y])
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	lines.append("look   x %+.2f   y %+.2f" % [look.x, look.y])
	lines.append("")
	lines.append("jump %s   sprint %s   interact %s" % [
		_held("jump"), _held("sprint"), _held("interact")
	])
	lines.append("")
	lines.append("Left stick moves the capsule. Nothing else is wired yet.")
	return "\n".join(lines)


func _held(action: String) -> String:
	return "[X]" if Input.is_action_pressed(action) else "[ ]"
