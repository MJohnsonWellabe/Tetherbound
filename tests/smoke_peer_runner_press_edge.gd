extends SceneTree

## F11#3 regression (granted to Stormwood on #321): one tap injected by the net
## proof runner (`tools/net/press_inject.gd::tap()`, which `peer_runner.gd`'s
## `_inject` delegates to) must read as exactly ONE `just_pressed` in
## `_physics_process`, even when a slow process frame runs several physics
## ticks, as it did on the host in the F11#3 two-peer proof (the Spark socket's
## toggle flipped twice).
##
## Negative control: the runner's previous sequence (press, one physics frame,
## release, no flush wait) under the same stall must read TWO edges, or the
## stall does not reproduce the defect and the check proves nothing.
##
##   godot --headless --path . --script tests/smoke_peer_runner_press_edge.gd

const PRESS_INJECT := preload("res://tools/net/press_inject.gd")
const GATE_F_HARNESS := preload("res://tools/gate_f/operator_harness.gd")
const ACTION := "interact"
## A process frame this long runs about three 60 Hz physics ticks.
const STALL_MS := 50

var _failures: Array[String] = []


class EdgeCounter extends Node:
	var action := StringName("interact")
	var edges := 0
	var stall_ms := 0

	func _physics_process(_delta: float) -> void:
		if Input.is_action_just_pressed(action):
			edges += 1

	func _process(_delta: float) -> void:
		if stall_ms > 0:
			OS.delay_msec(stall_ms)


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 8
	var binding := Callable(GATE_F_HARNESS, "_physical_binding")
	var counter := EdgeCounter.new()
	counter.action = StringName(ACTION)
	root.add_child(counter)
	for _i in 10:
		await process_frame
	counter.stall_ms = STALL_MS
	for _i in 10:
		await process_frame

	# Negative control: the old runner sequence.
	var old_edges := await _count(counter, func() -> void:
		await physics_frame
		PRESS_INJECT.edge(binding, ACTION, true)
		await physics_frame
		PRESS_INJECT.edge(binding, ACTION, false)
		await process_frame
		await physics_frame)
	_check(old_edges == 2, "negative control: the old sequence under a %d ms stall reads 2 edges (got %d)" % [STALL_MS, old_edges])

	# The fixed tap, injected from a physics-frame resume and from an idle one
	# (`_step_press` resumes from either, depending on what it awaited last).
	for context: String in ["physics", "idle"]:
		var edges := await _count(counter, func() -> void:
			if context == "physics":
				await physics_frame
			else:
				await process_frame
			var result: Dictionary = await PRESS_INJECT.tap(self, binding, ACTION, 1)
			_check(bool(result.get("ok", false)), "%s tap injected: %s" % [context, str(result)]))
		_check(edges == 1, "a %s-context tap under a %d ms stall reads exactly 1 edge (got %d)" % [context, STALL_MS, edges])

	# Without the stall the fixed tap still reads one edge.
	counter.stall_ms = 0
	var calm := await _count(counter, func() -> void:
		await physics_frame
		await PRESS_INJECT.tap(self, binding, ACTION, 1))
	_check(calm == 1, "without a stall a tap reads exactly 1 edge (got %d)" % calm)

	for line in _failures:
		print("PRESS EDGE FAIL: ", line)
	print("PEER RUNNER PRESS EDGE %s" % ["OK" if _failures.is_empty() else "FAILED"])
	quit(0 if _failures.is_empty() else 1)


## Edges counted from just before `body` to a few frames after it.
func _count(counter: EdgeCounter, body: Callable) -> int:
	Input.action_release(StringName(ACTION))
	for _i in 4:
		await process_frame
	counter.edges = 0
	await body.call()
	for _i in 6:
		await process_frame
	return counter.edges


func _check(ok: bool, message: String) -> void:
	print("PRESS EDGE %s: %s" % ["PASS" if ok else "FAIL", message])
	if not ok:
		_failures.append(message)
