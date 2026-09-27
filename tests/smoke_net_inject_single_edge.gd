extends "res://tools/net/peer_runner.gd"

## Regression for the harness double press (Stormwood F11#3, #356 02:13):
## one injected tap must produce exactly one `just_pressed` edge.
##
## `_press_edge` queues a physical joypad event, which Godot flushes on the next
## PROCESS frame, and also calls `Input.action_press`. When several physics
## ticks run per process frame, a release after one physics tick landed before
## that flush, and the late physical press then made a SECOND edge -- so every
## toggle prompt flipped twice. This runs the real `_inject` with physics at
## 240 Hz and rendering capped at 30 fps (about eight ticks per process frame)
## and counts edges both where gameplay reads them.
##
##   godot --headless --path . --script tests/smoke_net_inject_single_edge.gd
##
## No network, no world: it never calls the peer runner's own `_initialize`.

const ACTION := "interact"
const TAPS := 6


class EdgeCounter extends Node:
	var action := ""
	var physics_edges := 0
	var process_edges := 0

	func _physics_process(_delta: float) -> void:
		if Input.is_action_just_pressed(action):
			physics_edges += 1

	func _process(_delta: float) -> void:
		if Input.is_action_just_pressed(action):
			process_edges += 1


func _initialize() -> void:
	Engine.physics_ticks_per_second = 240
	Engine.max_physics_steps_per_frame = 16
	Engine.max_fps = 30
	Input.use_accumulated_input = false
	_run.call_deferred()


func _run() -> void:
	var counter := EdgeCounter.new()
	counter.action = ACTION
	root.add_child(counter)
	for i in 10:
		await process_frame
	var failures: Array[String] = []
	for tap in TAPS:
		var before_physics := counter.physics_edges
		var before_process := counter.process_edges
		var result: Dictionary = await _inject(ACTION, 1)
		if not bool(result.get("ok", false)):
			failures.append("tap %d: _inject refused: %s" % [tap, str(result)])
			break
		# Let any late physical event flush before counting this tap.
		for i in 6:
			await process_frame
		var physics_delta := counter.physics_edges - before_physics
		var process_delta := counter.process_edges - before_process
		print("smoke_net_inject_single_edge: tap %d -> physics edges %d, process edges %d"
			% [tap, physics_delta, process_delta])
		if physics_delta != 1:
			failures.append("tap %d: %d physics just_pressed edges (want 1)" % [tap, physics_delta])
		if process_delta > 1:
			failures.append("tap %d: %d process just_pressed edges (want at most 1)" % [tap, process_delta])
	# Control (reported, not asserted): the pre-fix ordering -- release after one
	# physics tick with no process-frame flush -- so the log shows whether this
	# machine's frame pacing reproduces the double edge the fix removes.
	var control_extra := 0
	for tap in TAPS:
		var before := counter.physics_edges
		if not bool(_press_edge(ACTION, true).get("ok", false)):
			break
		await physics_frame
		_press_edge(ACTION, false)
		for i in 6:
			await process_frame
		control_extra += maxi(0, counter.physics_edges - before - 1)
	print("smoke_net_inject_single_edge: CONTROL pre-fix ordering produced %d extra edge(s) over %d taps%s"
		% [control_extra, TAPS, "" if control_extra > 0 else " (pacing did not reproduce the defect here)"])
	for f in failures:
		print("FAIL: " + f)
	print("smoke_net_inject_single_edge: %d taps, %d failed" % [TAPS, failures.size()])
	quit(0 if failures.is_empty() else 1)
