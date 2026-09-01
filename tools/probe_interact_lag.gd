extends SceneTree
## OWNER-0901-INTERACT-RELIABILITY. Same approach-and-tap methodology as
## probe_interact_approach.gd (0% misses at native headless speed), but with
## an artificial per-frame stall inserted to simulate the low framerate the
## OWNER-0901-PERFORMANCE-LAG report describes on the ROG Ally.
##
## Why this matters specifically for `interact`: interaction_arbiter.gd
## recomputes its winner/offer ONCE per rendered frame (`_process`, see
## `_recompute()`) but reads the button ONCE PER PHYSICS TICK (`_physics_process`,
## fixed at 60Hz regardless of render rate). At 60fps those are ~1:1 and the
## cached winner is at most one 1/60s tick stale when a press is read. Under
## real lag, MANY physics ticks land inside a single slow rendered frame
## (Godot's fixed-timestep catch-up, capped by
## `physics/common/max_physics_steps_per_frame`, default 8) while the cached
## winner is only refreshed once for that whole batch -- so the window in
## which "I just walked into range and tapped immediately" reads a stale
## winner grows in direct proportion to how bad the frame hitch is. This
## probe manufactures that condition with `OS.delay_msec()` between physics
## ticks (which stalls the whole process, forcing Godot's own catch-up logic
## to run several physics ticks before the next `_process`) and reruns the
## exact walk-and-tap sweep, at every offset, to see whether a miss appears
## that the unlagged probe never produced.
##
##   godot --headless --path . --script tools/probe_interact_lag.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 300
const START_DISTANCE := 6.0
const TRIALS := 40
const MAX_WALK_TICKS := 480
const GRACE_TICKS := 40
## Stalls the main thread this long before letting the engine advance, once
## every few physics ticks -- enough to push several ticks into a catch-up
## batch under Godot's default 8-step cap without the whole probe taking
## geological time to run.
const STALL_MSEC := 70
const STALL_EVERY_N_TICKS := 3

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _panel: Node = null
var _wilhelm: Node3D = null
var _tick_count := 0

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
		await _tick()

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
		var press_at_tick: int = 10 + trial * 6
		await _one_trial(trial, press_at_tick)

	print("")
	print("LAGGED approach-press trials: %d, misses: %d (%.1f%%), skipped: %d" % [
		_attempts, _misses, 100.0 * float(_misses) / float(maxi(1, _attempts)), _skipped])
	for line in _miss_log:
		print("  miss: %s" % line)
	quit(0 if _misses == 0 else 1)


## One "tick" of the probe's own clock -- a physics_frame, but with an
## occasional artificial stall first to manufacture a slow/lagged frame.
func _tick() -> void:
	_tick_count += 1
	if _tick_count % STALL_EVERY_N_TICKS == 0:
		OS.delay_msec(STALL_MSEC)
	await physics_frame


func _reset_player_far() -> void:
	if bool(_panel.call("is_open")):
		_panel.call("close")
		for i in 5:
			await _tick()
	var facing := _wilhelm.rotation.y
	var spot := _wilhelm.global_position + Vector3(sin(facing), 0.0, cos(facing)) * START_DISTANCE
	spot.y = float(_world.call("ground_height_at", spot.x, spot.z)) + 1.0
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	var to := _wilhelm.global_position - _player.global_position
	to.y = 0.0
	_rig.set("yaw", atan2(-to.x, -to.z))
	for i in 5:
		await _tick()


func _offer_available() -> bool:
	var interactable: Node = _wilhelm.call("prompt_node")
	if interactable == null:
		return false
	var offer: Variant = interactable.call("interaction_offer", _player.global_position)
	return offer is Dictionary and not (offer as Dictionary).is_empty()


func _one_trial(trial: int, press_at_tick: int) -> void:
	await _reset_player_far()
	Input.action_press(&"move_forward")

	var pressed_interact := false
	var crossed_at := -1
	var press_landed_available := false

	for f in MAX_WALK_TICKS:
		if not pressed_interact and f >= press_at_tick:
			pressed_interact = true
			press_landed_available = _offer_available()
			Input.action_press(&"interact")
			await _tick()
			Input.action_release(&"interact")
		else:
			await _tick()
		if crossed_at < 0 and _offer_available():
			crossed_at = f
		if bool(_panel.call("is_open")):
			break

	Input.action_release(&"move_forward")

	if not pressed_interact or crossed_at < 0:
		_skipped += 1
		return

	_attempts += 1
	var opened := false
	for i in GRACE_TICKS:
		if bool(_panel.call("is_open")):
			opened = true
			break
		await _tick()

	if not opened and press_landed_available:
		_misses += 1
		_miss_log.append(
			"trial %d: pressed at tick %d (offer already available then; crossed at %d), never opened" % [
				trial, press_at_tick, crossed_at])
	elif not opened:
		print("  (expected no-op) trial %d: pressed at %d, offer available at %d, no open" % [
			trial, press_at_tick, crossed_at])
