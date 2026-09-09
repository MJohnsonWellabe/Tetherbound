extends "res://tools/aim_eight_tick_probe.gd"

var guarded_edge := -1.0
var fresh_edge := -1.0

func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("natural guard probe watchdog")
		quit(1))
	root.get_node("Game").get("inventory").call("add", "orb_basic", 4)
	await _build(false)
	# Disclosed closed-case setup; no state or guard assignment thereafter.
	f.manager.set_script(OpeningCombat)
	f.manager.aim = f.aim
	f.manager.target = f.target
	f.manager.set_physics_process(true)
	f.aim.state = f.aim.State.IDLE
	var events := EventReceipt.new()
	f.world.add_child(events)
	stage_name = "natural_open"
	watching = true
	if not _require(await f.opening._open_throw_aim(), "physical opening reaches native aim"):
		await _teardown()
		_finish()
		return
	var guard: float = f.aim.get("_guard")
	if not _require(guard > 0.0, "opening returns during naturally positive native guard"):
		await _teardown()
		_finish()
		return
	if OS.get_cmdline_user_args().has("--verify-readiness"):
		if not _require(not f.opening._aim_readiness_ready(),
				"earned convergence rejects naturally guarded opening"):
			await _teardown()
			_finish()
			return
	stage_name = "guarded_throw"
	_sample("exact_tap.dispatch")
	await f.opening._tap_action(&"interact")
	_sample("exact_tap.return")
	if not _require(guarded_edge > 0.0 and f.aim.commits == 0 and f.aim.stock() == 4
			and f.aim.last_launch().is_empty() and f.manager.is_aiming(),
			"real just-pressed edge under positive native guard is ignored without commit or spend"):
		await _teardown()
		_finish()
		return
	if not _require(float(f.aim.get("_guard")) <= 0.0,
			"native guard expires during existing eight-tick tap without extra sleep"):
		await _teardown()
		_finish()
		return
	if not _require(await f.opening._aim_camera_at(f.target, ACQUIRE_SECONDS)
			and f.opening._final_throw_verdict_ready(),
			"ordinary bounded steering and final verdict accept expired guard"):
		await _teardown()
		_finish()
		return
	var helper: Node = f.opening._watch_throw_commit()
	stage_name = "fresh_unguarded_throw"
	_sample("exact_tap.dispatch")
	await f.opening._tap_action(&"interact")
	_sample("exact_tap.return")
	var ok: bool = _require(fresh_edge == 0.0 and f.aim.commits == 1 and helper.observed,
		"fresh physical edge after natural guard expiry reaches one native commit")
	if ok:
		var deadline := Time.get_ticks_msec() + 1200
		while Time.get_ticks_msec() < deadline and f.aim.last_launch().is_empty() and not helper.cancelled:
			await physics_frame
		_require((helper.cancelled and f.aim.stock() == 4 and f.aim.last_launch().is_empty())
			or (not helper.invalid and not f.aim.last_launch().is_empty() and f.aim.stock() == 3),
			"fresh edge lifecycle retains helper safety and native inventory accounting")
	helper.stop()
	await _teardown()
	_finish()

func _sample(stage: String) -> void:
	super(stage)
	if watching and stage == "throw.physics.before" and Input.is_action_just_pressed("interact"):
		if stage_name == "guarded_throw":
			guarded_edge = float(f.aim.get("_guard"))
		elif stage_name == "fresh_unguarded_throw":
			fresh_edge = float(f.aim.get("_guard"))
