extends SceneTree
## OWNER-0901-INTERACT-RELIABILITY. A white-box, deterministic test of the
## specific race the owner-playtest notification's own hypothesis list led
## with: interaction_arbiter.gd recomputes its winner/offer once per
## `_process()` (idle/render frame) but reads the button once per
## `_physics_process()` (fixed 60Hz) tick -- so `activate()` can run against a
## winner that is up to one render-frame stale relative to the exact physics
## tick the press landed on.
##
## The full-world probes (probe_interact_flake/approach/lag.gd) hunted for
## this under realistic and lag-simulated play and found nothing -- but they
## depend on WHEN in real (simulated) time a provider's offer happens to
## flip relative to WHEN a press happens to land, which is luck-of-the-draw
## even across hundreds of trials. This probe removes the luck: it uses a
## fake provider under direct control, and sweeps a press across every
## possible tick offset relative to the exact tick the offer flips from
## unavailable to available, deterministically covering the one relative
## timing that would expose a one-frame-stale read if this code has one.
##
##   godot --headless --path . --script tools/probe_arbiter_race.gd

const ARBITER_SCRIPT := preload("res://scripts/world/interaction_arbiter.gd")

class FakeProvider extends RefCounted:
	var available_from_tick: int = -1
	var current_tick: int = 0
	var activations: int = 0

	func interaction_offer(_from: Vector3) -> Dictionary:
		if available_from_tick < 0 or current_tick < available_from_tick:
			return {}
		return {"label": "Test", "distance": 1.0, "priority": 0, "actionable": true}

	func interaction_activate() -> void:
		activations += 1


var _root_node: Node = null
var _player: Node3D = null
var _arbiter: Node = null
var _provider: FakeProvider = null
var _misses := 0
var _attempts := 0
var _miss_log: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	_root_node = Node.new()
	root.add_child(_root_node)

	_player = Node3D.new()
	_root_node.add_child(_player)

	# Sweep the press across ticks -6..+6 relative to the exact tick the
	# fake offer flips available. 0 = press lands the SAME physics tick the
	# offer first becomes available; negative = press lands before; positive
	# = after.
	for offset in range(-6, 7):
		await _one_trial(offset)

	print("")
	print("arbiter race-window trials: %d, misses: %d (%.1f%%)" % [
		_attempts, _misses, 100.0 * float(_misses) / float(maxi(1, _attempts))])
	for line in _miss_log:
		print("  miss: %s" % line)
	quit(0 if _misses == 0 else 1)


func _fresh_arbiter() -> void:
	if _arbiter != null and is_instance_valid(_arbiter):
		_arbiter.queue_free()
	_arbiter = ARBITER_SCRIPT.new()
	_root_node.add_child(_arbiter)
	_arbiter.call("set_player", _player)
	_provider = FakeProvider.new()
	_arbiter.call("register", _provider)
	for i in 5:
		await physics_frame


func _one_trial(offset: int) -> void:
	await _fresh_arbiter()

	# Choose an availability tick comfortably past this fresh boot's settle,
	# then land the press `offset` ticks from it.
	var flip_tick := 20
	_provider.available_from_tick = flip_tick
	var press_tick: int = flip_tick + offset

	var pressed := false
	var tick := 0
	for i in 40:
		_provider.current_tick = tick
		if tick == press_tick:
			pressed = true
			Input.action_press(&"interact")
			await physics_frame
			Input.action_release(&"interact")
		else:
			await physics_frame
		tick += 1

	if not pressed:
		_miss_log.append("offset %d: press tick %d never reached in the trial window" % [offset, press_tick])
		return

	_attempts += 1
	var expected_can_activate: bool = press_tick >= flip_tick
	var did_activate: bool = _provider.activations > 0
	if expected_can_activate and not did_activate:
		_misses += 1
		_miss_log.append(
			"offset %+d: pressed at tick %d (offer available from tick %d onward) but activate() never fired" % [
				offset, press_tick, flip_tick])
	elif not expected_can_activate and did_activate:
		# Not a "miss" in the owner's sense (nothing was silently swallowed),
		# but worth flagging: a press that landed BEFORE the offer existed
		# still fired activate() -- a phantom accept rather than a phantom
		# refusal. Logged, not counted as a miss.
		print("  (unexpected accept) offset %+d: pressed at tick %d before offer existed (tick %d), but it fired" % [
			offset, press_tick, flip_tick])
