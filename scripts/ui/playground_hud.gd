extends CanvasLayer

## M1 debug HUD: health, stamina, and the numbers needed to tune movement.
##
## Not the real HUD. GAME_DESIGN.md's interface work comes much later; this
## exists so the owner can answer "sprint too slow" with a number rather than a
## feeling, and so a stamina meter that never moves is visible immediately.
##
## Sized for the Ally: the project authors at 1920x1080 and stretches
## canvas_items, so text set here is at real handheld pixel density.

const READOUT_INTERVAL := 0.1

@export var player_path: NodePath

var _player: CharacterBody3D = null
var _since_readout := 0.0
var _peak_fall := 0.0
var _last_damage := 0.0

@onready var _health_bar: ProgressBar = $Root/Bars/Health
@onready var _stamina_bar: ProgressBar = $Root/Bars/Stamina
@onready var _readout: Label = $Root/Readout


func _ready() -> void:
	_player = get_node_or_null(player_path) as CharacterBody3D
	if _player == null:
		push_warning("HUD has no player; readout will stay empty")
		return
	if _player.has_signal("landed"):
		_player.connect("landed", _on_landed)


func _on_landed(impact_speed: float, damage: float) -> void:
	_peak_fall = maxf(_peak_fall, impact_speed)
	_last_damage = damage


func _process(delta: float) -> void:
	if _player == null:
		return
	var vitals: RefCounted = _player.get("vitals")
	if vitals == null:
		return

	_health_bar.value = vitals.health_fraction() * 100.0
	_stamina_bar.value = vitals.stamina_fraction() * 100.0

	# Throttled: rebuilding this string every frame is wasted work and makes the
	# numbers flicker too fast to read while tuning.
	_since_readout += delta
	if _since_readout < READOUT_INTERVAL:
		return
	_since_readout = 0.0

	var speed: float = _player.call("ground_speed")
	var sprinting: bool = _player.call("is_sprinting")
	var pos: Vector3 = _player.global_position

	var lines: Array[String] = [
		"M1 movement playground",
		"",
		"speed      %.2f m/s%s" % [speed, "   SPRINT" if sprinting else ""],
		"vertical   %+.2f m/s" % _player.velocity.y,
		"grounded   %s" % ("yes" if _player.is_on_floor() else "NO"),
		"position   %.0f, %.0f, %.0f" % [pos.x, pos.y, pos.z],
		"",
		"stamina    %.0f / %.0f" % [vitals.stamina, vitals.max_stamina],
		"health     %.0f / %.0f" % [vitals.health, vitals.max_health],
		"worst landing  %.1f m/s  (%.0f damage)" % [_peak_fall, _last_damage],
	]
	lines.append_array(_input_diagnostics())
	_readout.text = "\n".join(lines)


## Live input diagnostics.
##
## On screen rather than in a log, because "the controller does nothing" is
## otherwise indistinguishable from four different causes: the handheld sitting
## in desktop/mouse mode so the sticks emit no joypad events at all, the pad
## enumerating without an SDL mapping, a wrong axis or button in the input map,
## or the window simply not having focus. Each of those looks identical from the
## outside and each shows up differently here.
##
## Keyboard values are shown alongside the pad on purpose: if WASD moves the
## capsule and the sticks do not, the game is fine and the problem is upstream
## of Godot.
func _input_diagnostics() -> Array[String]:
	var lines: Array[String] = ["", "--- input ---"]

	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		lines.append("controller  NONE DETECTED BY GODOT")
		lines.append("  the handheld is probably in desktop/mouse mode,")
		lines.append("  or the window does not have focus")
	else:
		for device_id in pads:
			lines.append("controller  %d: %s" % [device_id, Input.get_joy_name(device_id)])
			if not Input.is_joy_known(device_id):
				lines.append("  NOT a standard mapping: buttons/axes may be wrong")

	var move := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var look := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	lines.append("move  %+.2f %+.2f     look  %+.2f %+.2f" % [move.x, move.y, look.x, look.y])

	# Raw axes, bypassing the input map. If these move while `move` above stays
	# zero, the pad is fine and the input map bindings are wrong.
	if not pads.is_empty():
		var device: int = pads[0]
		lines.append("raw axes  L %+.2f %+.2f   R %+.2f %+.2f" % [
			Input.get_joy_axis(device, JOY_AXIS_LEFT_X),
			Input.get_joy_axis(device, JOY_AXIS_LEFT_Y),
			Input.get_joy_axis(device, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y),
		])

	lines.append("jump %s  sprint %s  interact %s" % [
		_held("jump"), _held("sprint"), _held("interact")
	])
	lines.append("")
	lines.append("pad: left stick move, right stick look, A jump, L3 sprint")
	lines.append("keyboard: WASD move, mouse look, Space jump, Shift sprint")
	return lines


func _held(action: String) -> String:
	return "[X]" if Input.is_action_pressed(action) else "[ ]"
