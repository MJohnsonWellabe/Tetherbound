extends "res://tools/aim_controller_phase_probe.gd"

## Isolated input-order experiment; no campaign or production edits. Reuses the
## retained native camera/player/wild/ThrowAim fixture, not its steering loop.
## Initial follow residual is a synthetic condition, set before observation.

class DispatchGate extends Node:
	var dispatch: Callable
	func _physics_process(_delta: float) -> void:
		set_physics_process(false)
		dispatch.call()

var _sent := false
var _refused := false
var _drain_at_dispatch := false

func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("same-physics dispatch probe watchdog")
		quit(1))
	if not await _dispatch_case("legacy pre-process residual", false, true, false):
		_finish()
		return
	if not await _dispatch_case("same-physics residual", true, true, false):
		_finish()
		return
	if not await _dispatch_case("same-physics stationary", true, false, false):
		_finish()
		return
	await _dispatch_case("same-physics blocked", true, false, true)
	_finish()

func _dispatch_case(label: String, same_physics: bool, residual: bool, blocked: bool) -> bool:
	await _build(false, 0.0, blocked)
	if not blocked:
		var acquired: bool = await f.opening._aim_camera_at(f.target, ACQUIRE_SECONDS)
		if not _require(acquired, label + ": existing native steering acquired the fixture"):
			await _teardown()
			return false
	await process_frame
	_sent = false
	_refused = false
	_drain_at_dispatch = same_physics
	traces.clear()
	dispatch_index = -1
	commit_index = -1
	if residual:
		f.player.global_position.x = -10.0
	watching = true
	print("SAME_PHYSICS CASE ", label)
	if same_physics:
		var gate := DispatchGate.new()
		gate.name = "InputPhaseObservation"
		gate.process_physics_priority = f.aim.process_physics_priority
		gate.dispatch = _try_dispatch
		f.manager.add_child(gate)
		f.manager.move_child(gate, f.aim.get_index())
	else:
		_try_dispatch()
	for _frame in 8:
		await create_timer(0.0, true, true).timeout
		if f.aim.commits > 0 or _refused:
			break
	var ok := true
	if not same_physics:
		ok = _require(_sent and f.aim.commits == 1 and not f.aim.assisted,
			label + ": retained native follow changes eligible dispatch to ineligible commit")
	elif blocked:
		ok = _require(_refused and not _sent and f.aim.commits == 0,
			label + ": blocked physical preview dispatches no pad event")
	elif _sent:
		ok = _require(f.aim.commits == 1 and f.aim.assisted,
			label + ": current eligibility survives the actual parsed pad commit")
		if commit_index > dispatch_index and dispatch_index >= 0:
			var intervening := []
			for index in range(dispatch_index + 1, commit_index):
				if traces[index].stage in ["rig.process.after", "target.physics.after", "trainer.physics.after"]:
					intervening.append(traces[index].stage)
			ok = _require(intervening.is_empty(), label + ": no pose callback between verdict and commit") and ok
		else:
			ok = _require(false, label + ": dispatch and commit ordering recorded") and ok
	else:
		ok = _require(residual and _refused and f.aim.commits == 0,
			label + ": changed current verdict refuses before dispatch")
	print("SAME_PHYSICS RESULT ", label, " sent=", _sent, " refused=", _refused,
		" commits=", f.aim.commits, " assisted=", f.aim.assisted)
	await _teardown()
	return ok

func _try_dispatch() -> void:
	var current: Dictionary = f.aim.launch_assist_diagnostics()
	var preview: Dictionary = f.aim.aim_report()
	_sample("input.dispatch")
	if not f.manager.is_aiming() or not bool(current.get("eligible", false)) \
			or preview.is_empty() or bool(preview.get("trajectory_blocked", true)):
		_refused = true
		return
	_sent = true
	Input.parse_input_event(f.opening._event_for(&"interact", true))
	if _drain_at_dispatch:
		# parse_input_event buffers the physical event. Drain the ordinary Input
		# queue in this callback so ThrowAim sees it before another pose update.
		Input.flush_buffered_events()
	_sample("input.parsed")
