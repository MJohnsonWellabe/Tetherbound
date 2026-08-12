extends SceneTree

## Can you still finish the opening if you just WALK OFF THE BED?
##
##   godot --headless --path . --script tests/smoke_wake_softlock.gd
##
## **Headless, never under xvfb** — same reason as `smoke_opening.gd`.
##
## ## Why this exists as a separate test
##
## The owner reported the game was uncompletable: *"you still can't interact
## with grandpa at the beginning. so then you leave the house and never get a
## starter."* `smoke_opening.gd` was green through all of it.
##
## It was green because it is **a correct test of the intended path**. It walks
## to the bed, presses interact, and only then goes downstairs — so it can never
## be the player who skips that press. The bug lived entirely in the order of
## operations, which a test that hard-codes the right order is structurally
## blind to.
##
## The mechanism, for whoever reads this after the next one: the beat machine
## started at `wake`, and `wake` had exactly ONE exit — the bed prompt. Nothing
## forced it. `_refresh_lockout()` never gated locomotion on the beat, so the
## fade cleared and you could walk away. Do that and the beat stuck at `wake`
## forever, which left Grandpa's interactable disabled (his conversation for
## that beat is ""), which made `interactable.gd` hand back an empty offer, so
## the arbiter never even saw him. No prompt, dead button, no starter.
##
## So this test drives the ONE thing `smoke_opening` cannot: the wrong order.
## It never touches the bed prompt. It walks out of the loft and then asks
## whether the game is still winnable.
##
## ## What it asserts, and why each line is here
##
##   1. After walking clear of the bed, the beat is no longer `wake`. This is
##      the fix's actual contract.
##   2. Grandpa's prompt is ENABLED and the arbiter offers it. Asserting the
##      beat alone would pass on a fix that moved the beat but left the prompt
##      wired to something else.
##   3. Pressing interact opens his conversation. The button has to reach it.
##
## Anything that reintroduces a beat with a single skippable exit fails here.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const DIRECTOR_SCRIPT := "res://scripts/story/sequence_director.gd"

## The director waits on the house before it stages anyone; the world builds it
## at the end of its own _ready. Same budget smoke_opening uses.
const SETTLE_FRAMES := 300
const WALK_FRAMES := 1200

var _failures: Array[String] = []
var _world: Node = null
var _player: CharacterBody3D = null
var _model: Node3D = null
var _rig: Node3D = null
var _director: Node = null
var _arbiter: Node = null
var _dialogue: CanvasLayer = null


func _init() -> void:
	_run()


func _run() -> void:
	var packed: PackedScene = load(SCENE)
	if packed == null:
		_fail("could not load %s" % SCENE)
		return _finish()
	_world = packed.instantiate()
	root.add_child(_world)

	for i in SETTLE_FRAMES:
		await physics_frame

	if not _collect_nodes():
		return _finish()

	await _walk_off_the_bed_without_pressing_it()
	await _grandpa_is_reachable_anyway()
	_finish()


func _collect_nodes() -> bool:
	_player = _find_by_method(_world, "set_locomotion_enabled") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_director = _find_by_script(_world, DIRECTOR_SCRIPT)
	_arbiter = _find_by_method(_world, "prompt")
	_dialogue = _find_by_method(_world, "drain_effects") as CanvasLayer

	_model = _player.get_node_or_null(^"Model") as Node3D

	for pair in [["player", _player], ["director", _director],
			["arbiter", _arbiter], ["dialogue", _dialogue], ["model", _model]]:
		if pair[1] == null:
			_fail("no %s in the booted scene" % pair[0])
			return false
	return true


## The whole point: leave the bed the way a player who missed the prompt would.
func _walk_off_the_bed_without_pressing_it() -> void:
	var beat := str(_director.call("beat"))
	if beat != "wake":
		# Not a failure of the fix — but if the scene no longer starts in wake,
		# this test is measuring nothing and should be rewritten, not trusted.
		_fail("expected to start in the 'wake' beat, got '%s'; this test is now vacuous" % beat)
		return

	# OF8: this walk never touches BedPrompt, so it is the one path that can
	# only reach "standing" through trainer_model.gd's own auto-clear on
	# movement, never through sequence_director's explicit call on the
	# prompt. If that self-clear regressed, this is the only test that would
	# notice — smoke_opening's own get-up check always goes through the
	# prompt.
	if not bool(_model.call("is_lying")):
		_fail("expected the trainer lying down at the start of 'wake'; nothing here would be testing the walk-away exit")
		return

	var start := _player.global_position
	# Diagonally into the room rather than a single axis: OF8 puts the
	# trainer's feet at the FOOT of the bed to lie down correctly
	# (grandpa_house.gd places NightStand at that same end, "at its foot",
	# on purpose) and the bed itself sits under the loft's west eave, so a
	# straight walk on any single axis from there clips either the
	# nightstand or the low roof slope within a couple of metres — measured
	# directly: +X moved 2.8m before stopping, +Z 1.9m, -Z 2.7m, none past
	# this test's own 3.5m floor. +X-Z (measured 5.0m clear) is the one that
	# does not. The contract this test cares about (leaving the bed at all
	# ends the beat, not that one route does) does not depend on which clear
	# direction is picked, only that it is one that actually leaves.
	var away := start + Vector3(6.0, 0.0, -6.0)
	await _walk_toward_point(away, WALK_FRAMES)

	var moved := _player.global_position.distance_to(start)
	if moved < 3.5:
		_fail("only moved %.1fm off the bed; the walk did not leave the loft, so nothing was tested" % moved)
		return

	if bool(_model.call("is_lying")):
		_fail("walked %.1fm off the bed without pressing it and the trainer is still posed lying down" % moved)
		return

	beat = str(_director.call("beat"))
	if beat == "wake":
		_fail("SOFT-LOCK: walked %.1fm from the bed without pressing it and the beat is STILL 'wake'. "
			% moved + "Grandpa stays disabled from here and the opening cannot be completed.")
		return
	print("walked %.1fm off the bed without pressing it; beat advanced to '%s'" % [moved, beat])


## The beat moving is necessary but not sufficient — the button has to work.
func _grandpa_is_reachable_anyway() -> void:
	if not _failures.is_empty():
		return

	var grandpa := _world.get_parent().get_node_or_null(^"Grandpa") as Node3D
	if grandpa == null:
		grandpa = _find_named(_world.get_parent(), "Grandpa")
	if grandpa == null:
		_fail("no Grandpa in the scene to walk to")
		return

	await _walk_toward_point(grandpa.global_position, WALK_FRAMES)

	var offered := str(_arbiter.call("prompt"))
	if offered.is_empty():
		_fail("stood next to Grandpa and the arbiter offers NO prompt — "
			+ "his interactable is still disabled, which is the soft-lock's real symptom")
		return
	print("Grandpa offers: '%s'" % offered)

	await _press("interact")
	for i in 30:
		await physics_frame
	if not bool(_dialogue.call("is_open")):
		_fail("pressed interact on Grandpa's prompt ('%s') and no conversation opened" % offered)
		return
	print("interact opened Grandpa's conversation — the opening is completable")


## --- helpers, deliberately the same shape as smoke_opening's ----------------

func _walk_toward_point(point: Vector3, frames: int) -> void:
	for i in frames:
		var to := point - _player.global_position
		to.y = 0.0
		if to.length() <= 1.6:
			break
		if _rig != null:
			_rig.set("yaw", atan2(-to.x, -to.z))
		_send("move_forward", true)
		await physics_frame
	_send("move_forward", false)
	for i in 10:
		await physics_frame


func _press(action: String) -> void:
	_send(action, true)
	await physics_frame
	await physics_frame
	_send(action, false)
	await physics_frame


## Both channels, per HANDOFF §10: polled state AND a parsed event, because UI
## and gameplay read the input in different ways.
func _send(action: String, pressed: bool) -> void:
	if pressed:
		Input.action_press(action)
	else:
		Input.action_release(action)
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _find_by_script(node: Node, path: String) -> Node:
	var script: Script = node.get_script()
	if script != null and script.resource_path == path:
		return node
	for child in node.get_children():
		var found := _find_by_script(child, path)
		if found != null:
			return found
	return null


func _find_by_method(node: Node, method: String) -> Node:
	if node.has_method(method):
		return node
	for child in node.get_children():
		var found := _find_by_method(child, method)
		if found != null:
			return found
	return null


func _find_named(node: Node, wanted: String) -> Node3D:
	if node.name == wanted and node is Node3D:
		return node as Node3D
	for child in node.get_children():
		var found := _find_named(child, wanted)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	print("")
	if _failures.is_empty():
		print("wake soft-lock: OK — walked off the bed, Grandpa still works.")
		quit(0)
		return
	for line in _failures:
		print("FAIL: %s" % line)
	quit(1)
