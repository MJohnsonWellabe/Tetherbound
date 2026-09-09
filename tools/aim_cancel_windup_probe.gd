extends "res://tools/aim_controller_phase_probe.gd"

## Synthetic native lifecycle proof. Production callbacks are never called
## manually; the observer sends only InputMap-backed physical controller events.
class WindupObserver extends Node:
	var observe: Callable
	func _physics_process(_delta: float) -> void:
		observe.call()

var cancel_enabled := false
var cancel_sent := false
var cancel_consumed := false
var sent := false
var refused := false
var observed_commit := false
var commit_frame := -1
var cancel_frame := -1
var commit_process := -1
var cancel_process := -1
var commit_stock := -1
var invalid_commit := false
var cancelled_stock := -1
var flee_edge := false
var initial_stock := 0
var shared_watch: Node

func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("windup cancellation probe watchdog")
		quit(1))
	# Artificial inventory, once before any measured case; never refilled.
	var game := root.get_node("Game")
	game.get("inventory").call("add", "orb_basic", 4)
	for spec in [
		["legacy stale commit", true, false, false, 60],
		["stale commit cancelled", true, true, false, 60],
		["eligible release", false, true, false, 60],
		["blocked dispatch", false, true, true, 60],
		["multiple physics per idle cancellation", true, true, false, 15],
	]:
		if not await _windup_case(spec[0], spec[1], spec[2], spec[3], spec[4]):
			_finish()
			return
	_finish()

func _windup_case(label: String, residual: bool, cancel: bool, blocked: bool, fps: int) -> bool:
	Engine.max_fps = fps
	await _build(false, 0.0, blocked)
	if not blocked:
		if not _require(await f.opening._aim_camera_at(f.target, ACQUIRE_SECONDS),
				label + ": existing steering acquired within unchanged budget"):
			await _teardown()
			return false
	await process_frame
	cancel_enabled = cancel
	cancel_sent = false
	cancel_consumed = false
	sent = false
	refused = false
	observed_commit = false
	invalid_commit = false
	flee_edge = false
	commit_frame = -1
	cancel_frame = -1
	commit_process = -1
	cancel_process = -1
	commit_stock = -1
	cancelled_stock = -1
	initial_stock = f.aim.stock()
	traces.clear()
	if residual:
		# Disclosed initial condition only; no pose changes after observation starts.
		f.player.global_position.x = -10.0
	shared_watch = f.opening._watch_throw_commit() if cancel else null
	var observer := WindupObserver.new()
	observer.name = "AfterThrowWindupObserver"
	observer.process_physics_priority = f.aim.process_physics_priority
	observer.observe = _observe_windup
	f.manager.add_child(observer)
	f.manager.move_child(observer, shared_watch.get_index() + 1 if cancel else f.aim.get_index() + 1)
	watching = true
	print("CANCEL_CASE ", label, " fps=", fps, " stock=", initial_stock)
	var current: Dictionary = f.aim.launch_assist_diagnostics()
	var preview: Dictionary = f.aim.aim_report()
	_sample("input.dispatch")
	if f.manager.is_aiming() and bool(current.get("eligible", false)) \
			and not preview.is_empty() and not bool(preview.get("trajectory_blocked", true)):
		sent = true
		Input.parse_input_event(f.opening._event_for(&"interact", true))
	else:
		refused = true
	var deadline := Time.get_ticks_msec() + 1200
	while Time.get_ticks_msec() < deadline:
		await create_timer(0.0, true, true).timeout
		if refused or cancel_consumed or not f.aim.last_launch().is_empty() \
				or (not cancel and observed_commit):
			break
	var ok := true
	if blocked:
		ok = _require(bool(preview.get("trajectory_blocked", false))
			and str(preview.get("trajectory_blocker", "")) == "HandArcBlocker",
			label + ": physical preview identifies blocker") and ok
		ok = _require(refused and not sent and f.aim.commits == 0
			and f.aim.stock() == initial_stock and f.aim.last_launch().is_empty(),
			label + ": no input, commit, release or spend") and ok
	elif residual:
		ok = _require(sent and observed_commit and invalid_commit and f.aim.commits == 1,
			label + ": eligible dispatch produces actual ineligible commit") and ok
		ok = _require(commit_stock == initial_stock and f.aim.last_launch().is_empty(),
			label + ": commit precedes all release/spending") and ok
		if cancel:
			ok = _require(cancel_sent and cancel_consumed and cancel_frame == commit_frame + 1,
				label + ": real cancel consumed on immediately following physics tick") and ok
			ok = _require(cancelled_stock == initial_stock and f.aim.stock() == initial_stock
				and f.aim.state == f.aim.State.IDLE and not flee_edge,
				label + ": free exit preserves stock and never asserts flee actions") and ok
			if fps == 15:
				ok = _require(commit_process == cancel_process,
					label + ": commit and cancellation occur within one idle interval") and ok
	else:
		ok = _require(sent and observed_commit and not invalid_commit and not cancel_sent,
			label + ": actual eligible commit is retained") and ok
		ok = _require(not f.aim.last_launch().is_empty() and f.aim.stock() == initial_stock - 1,
			label + ": actual production release spends exactly one orb") and ok
	print("CANCEL_RESULT ", label, " commit_physics=", commit_frame,
		" cancel_physics=", cancel_frame, " commit_process=", commit_process,
		" cancel_process=", cancel_process, " stock=", f.aim.stock(),
		" last_launch=", f.aim.last_launch())
	Input.parse_input_event(f.opening._event_for(&"menu_cancel", false))
	Input.flush_buffered_events()
	await _teardown()
	return ok

func _observe_windup() -> void:
	if not watching:
		return
	if not observed_commit and float(f.aim.get("_windup")) > 0.0:
		observed_commit = true
		commit_frame = Engine.get_physics_frames()
		commit_process = Engine.get_process_frames()
		commit_stock = f.aim.stock()
		var actual_preview: Dictionary = f.aim.aim_report()
		invalid_commit = f.aim.get("_committed_assist_point") == Vector3.INF \
			or not bool(actual_preview.get("eligible", false)) \
			or bool(actual_preview.get("trajectory_blocked", true))
		print("WINDUP_OBSERVED physics=", commit_frame, " process=", commit_process,
			" windup=", f.aim.get("_windup"), " point=", f.aim.get("_committed_assist_point"),
			" stock=", commit_stock, " report=", actual_preview)
	if is_instance_valid(shared_watch):
		cancel_sent = shared_watch.cancel_sent
	if cancel_sent:
		flee_edge = flee_edge or Input.is_action_pressed("combat_run") \
			or Input.is_action_pressed("creature_recall")
		if not cancel_consumed and shared_watch.cancelled:
			cancel_consumed = true
			cancel_frame = Engine.get_physics_frames()
			cancel_process = Engine.get_process_frames()
			cancelled_stock = f.aim.stock()
			print("CANCEL_CONSUMED physics=", cancel_frame, " just_pressed=",
				Input.is_action_just_pressed("menu_cancel"), " stock=", cancelled_stock)
