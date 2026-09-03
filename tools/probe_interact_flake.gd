extends SceneTree
## OWNER-0901-INTERACT-RELIABILITY. Measures how often a SINGLE `interact`
## press actually registers, without the forgiving retry loop
## `tests/smoke_relay.gd::_greet()` uses (which presses up to 40 times and
## only fails if every one of them misses — it hides a per-press flake rate
## instead of measuring it).
##
##   godot --headless --path . --script tools/probe_interact_flake.gd
##
## Stands the player in front of Wilhelm (an always-present, ungated two-line
## villager — data/config/village_npcs.json — so nothing here consumes a
## one-time flag/effect and every trial starts from the same state) and runs
## many independent open/advance/close cycles, each driven by exactly ONE
## `interact` tap per expected transition. Each tap is checked against the
## EXACT state it should produce, not merely "did something happen."

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const TRIALS := 60
## Frames between a press and checking its effect. Generous enough for a
## human-imperceptible response (0.2s at 60Hz) without masking a real miss
## the way smoke_relay's 10-frame-times-40-attempt loop does.
const CHECK_FRAMES := 15

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _panel: Node = null
var _wilhelm: Node3D = null

var _attempts := 0
var _misses := 0
var _miss_log: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_panel = _world.get_node_or_null(^"DialoguePanel")
	var village := _world.get_node_or_null(^"VillageNPCs")
	_wilhelm = village.get_node_or_null(^"Wilhelm") as Node3D if village != null else null

	if _player == null or _rig == null or _panel == null or _wilhelm == null:
		print("probe FAIL: missing player/rig/panel/Wilhelm in the built world")
		quit(1)
		return

	_stand_in_front(_wilhelm)
	for i in 60:
		await physics_frame

	for trial in TRIALS:
		await _one_cycle(trial)

	print("")
	print("interact single-press trials: %d, misses: %d (%.1f%%)" % [
		_attempts, _misses, 100.0 * float(_misses) / float(maxi(1, _attempts))])
	for line in _miss_log:
		print("  miss: %s" % line)
	quit(0 if _misses == 0 else 1)


func _stand_in_front(who: Node3D) -> void:
	var facing := who.rotation.y
	var spot := who.global_position + Vector3(sin(facing), 0.0, cos(facing)) * 2.4
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var to := who.global_position - _player.global_position
	to.y = 0.0
	_rig.set("yaw", atan2(-to.x, -to.z))


## Open (line 0) -> advance (line 1, is_last) -> close. Three single presses,
## each checked against exactly the transition it should cause.
func _one_cycle(trial: int) -> void:
	if bool(_panel.call("is_open")):
		_miss_log.append("trial %d: panel already open before the cycle started" % trial)
	await _expect_press("trial %d open" % trial, func() -> bool:
		return bool(_panel.call("is_open")) and int(_panel.get("_runner").call("line").get("index", -1)) == 0)
	await _expect_press("trial %d advance" % trial, func() -> bool:
		return bool(_panel.call("is_open")) and int(_panel.get("_runner").call("line").get("index", -1)) == 1)
	await _expect_press("trial %d close" % trial, func() -> bool:
		return not bool(_panel.call("is_open")))


## REAL InputEventJoypadButton through Input.parse_input_event(), not
## Input.action_press() -- OW4/UI-PAD1 (archive/ralph/DONE.md) both found real
## controller behaviour Input.action_press() cannot reproduce because it
## never travels the InputMap the way an actual pad event does. Interleaved
## with a continuous low-level right-stick "look" motion stream on every
## physics tick, mimicking a player who is still nudging the camera while
## they tap the button -- the one realistic condition the earlier all-clean
## trials (stationary, no other input) did not cover.
func _real_press(button_index: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button_index
	e.pressed = true
	return e


func _real_release(button_index: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button_index
	e.pressed = false
	return e


func _look_jitter() -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = 2  # right stick X, matches look_left/look_right in project.godot
	e.axis_value = 0.35 + randf() * 0.1
	Input.parse_input_event(e)


func _expect_press(label: String, ok: Callable) -> void:
	_attempts += 1
	Input.parse_input_event(_real_press(2))
	_look_jitter()
	await physics_frame
	_look_jitter()
	await physics_frame
	Input.parse_input_event(_real_release(2))
	_look_jitter()
	for i in CHECK_FRAMES:
		_look_jitter()
		await physics_frame
	if not ok.call():
		_misses += 1
		_miss_log.append(label)
	# Settle before the next tap regardless, so a miss does not cascade into
	# the following expectation via leftover input state.
	var stop := InputEventJoypadMotion.new()
	stop.axis = 2
	stop.axis_value = 0.0
	Input.parse_input_event(stop)
	for i in 10:
		await physics_frame
