extends SceneTree
## OWNER-0901-INTERACT-RELIABILITY. Companion to probe_interact_flake.gd,
## which found 0% misses for a STATIONARY press. This tests the one condition
## that leaves untested: pressing `interact` while still WALKING into range,
## at every possible timing relative to the exact physics tick the offer
## becomes available -- the scenario a real player is actually in most of the
## time, since nobody stops dead before tapping the button.
##
##   godot --headless --path . --script tools/probe_interact_approach.gd
##
## Each trial starts well outside Wilhelm's radius, walks straight at him with
## real movement input, and fires a single `interact` tap at a DIFFERENT frame
## offset from the start of the walk (offsets sweep across the frame the
## player actually crosses into range, both before and after). A trial is a
## MISS only if the tap landed on or after the frame the offer genuinely
## became available (radius + line-of-sight both satisfied, independently
## recomputed here from ground truth each physics tick) and the dialogue
## still failed to open within a generous grace window.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const START_DISTANCE := 6.0
const TRIALS := 50
const MAX_WALK_FRAMES := 240
const GRACE_FRAMES := 20

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _panel: Node = null
var _wilhelm: Node3D = null

var _attempts := 0
var _misses := 0
var _skipped := 0
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

	for trial in TRIALS:
		# Sweep the press offset across a window that straddles when the
		# player will cross into range -- roughly frames 40-100 of the walk
		# for a 6m approach at the player's walk speed, padded generously
		# either side.
		var press_at_frame: int = 10 + trial * 4
		await _one_trial(trial, press_at_frame)

	print("")
	print("approach-press trials: %d, misses: %d (%.1f%%), skipped (press before/no crossing): %d" % [
		_attempts, _misses, 100.0 * float(_misses) / float(maxi(1, _attempts)), _skipped])
	for line in _miss_log:
		print("  miss: %s" % line)
	quit(0 if _misses == 0 else 1)


func _reset_player_far() -> void:
	if bool(_panel.call("is_open")):
		_panel.call("close")
		for i in 5:
			await physics_frame
	var facing := _wilhelm.rotation.y
	var spot := _wilhelm.global_position + Vector3(sin(facing), 0.0, cos(facing)) * START_DISTANCE
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var to := _wilhelm.global_position - _player.global_position
	to.y = 0.0
	_rig.set("yaw", atan2(-to.x, -to.z))
	for i in 5:
		await physics_frame


## Ground truth: is Wilhelm's `Interactable` genuinely willing to offer right
## now, independent of the arbiter's own (possibly stale) cached winner?
func _offer_available() -> bool:
	var interactable: Node = _wilhelm.call("prompt_node")
	if interactable == null:
		return false
	var offer: Variant = interactable.call("interaction_offer", _player.global_position)
	return offer is Dictionary and not (offer as Dictionary).is_empty()


func _one_trial(trial: int, press_at_frame: int) -> void:
	await _reset_player_far()
	Input.action_press(&"move_forward")

	var pressed_interact := false
	var crossed_at := -1
	var press_landed_available := false

	for f in MAX_WALK_FRAMES:
		if not pressed_interact and f >= press_at_frame:
			pressed_interact = true
			press_landed_available = _offer_available()
			Input.action_press(&"interact")
			await physics_frame
			Input.action_release(&"interact")
		else:
			await physics_frame
		if crossed_at < 0 and _offer_available():
			crossed_at = f
		if bool(_panel.call("is_open")):
			break

	Input.action_release(&"move_forward")

	if not pressed_interact:
		_skipped += 1
		return
	if crossed_at < 0:
		# Never came into range/LOS at all within the walk window -- nothing
		# to test this trial, not a press failure.
		_skipped += 1
		return

	_attempts += 1
	var opened := false
	for i in GRACE_FRAMES:
		if bool(_panel.call("is_open")):
			opened = true
			break
		await physics_frame

	if not opened and press_landed_available:
		_misses += 1
		_miss_log.append(
			"trial %d: pressed at walk-frame %d (offer already available then; crossed at %d), never opened" % [
				trial, press_at_frame, crossed_at])
	elif not opened:
		# Pressed before the offer was truly available -- expected to do
		# nothing; not counted as a miss, but logged for visibility.
		print("  (expected no-op) trial %d: pressed at %d, offer became available at %d, no open" % [
			trial, press_at_frame, crossed_at])
