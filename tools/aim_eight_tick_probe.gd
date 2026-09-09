extends "res://tools/aim_controller_phase_probe.gd"

## Synthetic opening wrapper only; real manager still needs world proof.
class OpeningCombat extends "res://tools/aim_controller_phase_probe.gd".Combat:
	var target: Node
	var opens := 0
	func is_fighting() -> bool:
		return true
	func enemy() -> RefCounted:
		return target.get("instance")
	func _physics_process(_delta: float) -> void:
		if not is_aiming() and Input.is_action_just_pressed("interact"):
			if aim.call("try_begin_aim", true, ""):
				opens += 1

class EventReceipt extends Node:
	var presses := 0
	var releases := 0
	func _input(event: InputEvent) -> void:
		if event is InputEventJoypadButton:
			if event.pressed:
				presses += 1
			else:
				releases += 1
			print("NATIVE_INPUT physics=", Engine.get_physics_frames(), " process=",
				Engine.get_process_frames(), " button=", event.button_index, " pressed=", event.pressed)

var stage_name := ""

func _run() -> void:
	create_timer(20.0, true, false, true).timeout.connect(func() -> void:
		push_error("eight tick probe watchdog")
		quit(1))
	root.get_node("Game").get("inventory").call("add", "orb_basic", 4)
	await _build(false)
	var events := EventReceipt.new()
	f.world.add_child(events)
	stage_name = "already_aiming"
	watching = true
	var stock: int = f.aim.stock()
	var before := Engine.get_physics_frames()
	var opened: bool = await f.opening._open_throw_aim()
	var immediate := Engine.get_physics_frames() == before
	for _i in 10:
		await physics_frame
	if not _require(opened and immediate and events.presses == 0 and events.releases == 0
			and f.aim.commits == 0 and f.aim.stock() == stock,
			"already AIMING open returns immediately with no physical input, commit or spend"):
		await _teardown()
		_finish()
		return
	watching = false
	await _teardown()
	await _build(false)
	# Independent closed-case setup. Guard is not assigned after setup.
	f.manager.set_script(OpeningCombat)
	f.manager.aim = f.aim
	f.manager.target = f.target
	f.manager.set_physics_process(true)
	f.aim.state = f.aim.State.IDLE
	events = EventReceipt.new()
	f.world.add_child(events)
	stage_name = "closed_aim"
	watching = true
	before = Engine.get_physics_frames()
	opened = await f.opening._open_throw_aim()
	if not _require(opened and Engine.get_physics_frames() - before == 8
			and events.presses == 1 and events.releases == 1 and f.manager.opens == 1
			and f.aim.commits == 0 and f.aim.stock() == stock,
			"closed aim delegates to inherited eight-tick physical open and native try_begin_aim"):
		await _teardown()
		_finish()
		return
	watching = false
	await _teardown()
	await _build(false)
	if not _require(await f.opening._aim_camera_at(f.target, ACQUIRE_SECONDS),
			"zero-guard exact-tap case acquires with existing steering"):
		await _teardown()
		_finish()
		return
	events = EventReceipt.new()
	f.world.add_child(events)
	var helper: Node = f.opening._watch_throw_commit()
	stage_name = "zero_guard_eight_tick"
	watching = true
	_sample("exact_tap.dispatch")
	before = Engine.get_physics_frames()
	await f.opening._tap_action(&"interact")
	_sample("exact_tap.return")
	if not _require(Engine.get_physics_frames() - before == 8 and events.presses >= 1
			and f.aim.commits == 1 and helper.observed,
			"exact eight-tick tap reaches one native commit observed by shared helper"):
		helper.stop()
		await _teardown()
		_finish()
		return
	var deadline := Time.get_ticks_msec() + 1200
	while Time.get_ticks_msec() < deadline and f.aim.last_launch().is_empty() and not helper.cancelled:
		await physics_frame
	var ok: bool = (helper.cancelled and f.aim.stock() == stock and f.aim.last_launch().is_empty()) \
		or (not helper.invalid and not f.aim.last_launch().is_empty() and f.aim.stock() == stock - 1)
	_require(ok, "observed native commit either safely cancels or validly releases exactly one orb")
	helper.stop()
	await _teardown()
	_finish()

func _sample(stage: String) -> void:
	super(stage)
	if not watching or f.is_empty():
		return
	if stage in ["throw.physics.before", "throw.physics.after", "throw.commit",
			"exact_tap.dispatch", "exact_tap.return"]:
		print("EIGHT_TICK ", {"case": stage_name, "stage": stage,
			"physics": Engine.get_physics_frames(), "process": Engine.get_process_frames(),
			"guard": f.aim.get("_guard"), "windup": f.aim.get("_windup"),
			"guard_positive": float(f.aim.get("_guard")) > 0.0,
			"guard_precise": "%.20f" % float(f.aim.get("_guard")),
			"state": f.aim.state, "committed": str(f.aim.get("_committed_assist_point")),
			"pressed": Input.is_action_pressed("interact"),
			"just_pressed": Input.is_action_just_pressed("interact")})
