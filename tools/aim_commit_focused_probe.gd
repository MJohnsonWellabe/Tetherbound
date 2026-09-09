extends SceneTree
## Phase-boundary diagnosis only. Real SpringArm3D, throw callbacks and pad input;
## no campaign, save, inventory, HP, manual production ticks or rendered world.
const OPENING := preload("res://tests/helpers/fresh_opening_segment.gd")

class TraceRig extends "res://scripts/player/camera_rig.gd":
	var observer: Callable
	func _process(delta: float) -> void:
		if observer.is_valid(): observer.call("rig.process.before")
		super(delta)
		if observer.is_valid(): observer.call("rig.process.after")
	func _physics_process(delta: float) -> void:
		if observer.is_valid(): observer.call("rig.physics")
		super(delta)

class TraceAim extends "res://scripts/combat/throw_aim.gd":
	var observer: Callable
	var commits := 0
	var assisted := false
	func _tick_aiming(delta: float) -> void:
		if observer.is_valid(): observer.call("throw.physics.before")
		super(delta)
		if observer.is_valid(): observer.call("throw.physics.after")
	func _commit_launch_assist() -> void:
		super()
		commits += 1
		assisted = _committed_assist_point != Vector3.INF
		if observer.is_valid(): observer.call("throw.commit")

class Target extends CharacterBody3D:
	var observer: Callable
	func centre() -> Vector3: return global_position
	func body_radius() -> float: return 0.8
	func _physics_process(_delta: float) -> void:
		move_and_slide()
		if observer.is_valid(): observer.call("target.physics.after")

class Combat extends Node:
	var aim: Node
	func throw_aim() -> Node: return aim
	func is_aiming() -> bool: return aim.state == aim.State.AIMING

var failures: Array[String] = []
var checks := 0
var traces: Array[Dictionary] = []
var f: Dictionary
var watching := false

func _initialize() -> void:
	Engine.max_fps = 60
	_run.call_deferred()

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
	print("PASS: " if value else "FAIL: ", label)

func _sample(stage: String) -> void:
	if not watching: return
	var camera: Camera3D = f.camera
	var rig: TraceRig = f.rig
	var aim: TraceAim = f.aim
	var report := aim.launch_assist_diagnostics()
	var preview := aim.aim_report()
	var receipt := {"stage": stage, "physics": Engine.get_physics_frames(),
		"process": Engine.get_process_frames(), "eye": camera.global_position,
		"pivot": rig.global_position, "local_camera": camera.position,
		"forward": -camera.global_basis.z, "target": f.target.centre(),
		"player": f.player.global_position, "spring": rig.spring_length,
		"spring_hit": rig.get_hit_length(), "current": report, "preview": preview,
		"pressed": Input.is_action_pressed("interact"),
		"just_pressed": Input.is_action_just_pressed("interact")}
	traces.append(receipt)
	print("PHASE ", receipt)

func _build(initial_target_x: float = 0.0) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var player := CharacterBody3D.new()
	world.add_child(player)
	var target := Target.new()
	target.name = "FocusedTarget"
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = target.body_radius()
	collision.shape = sphere
	target.add_child(collision)
	world.add_child(target)
	target.position = Vector3(initial_target_x, 1, -8)
	var rig := TraceRig.new()
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	world.add_child(rig)
	rig.set_target(player, {"height": 1.0, "distance": 4.0,
		"pitch_start_deg": 0.0, "shoulder_offset": 0.0})
	var aim := TraceAim.new()
	world.add_child(aim)
	aim.arm(player, target, rig)
	aim.state = aim.State.AIMING
	aim._guard = 0.0
	var combat := Combat.new()
	combat.aim = aim
	world.add_child(combat)
	var opening := OPENING.new()
	opening._tree = self
	opening._rig = rig
	opening._player = player
	opening._combat = combat
	opening._wild = target
	f = {"world": world, "player": player, "target": target,
		"rig": rig, "camera": camera, "aim": aim, "opening": opening}
	rig.observer = _sample
	aim.observer = _sample
	target.observer = _sample
	for _frame in 6: await physics_frame
	# Boot can consume several physics ticks before the first idle tick; exclude
	# that startup delta from this one-frame follow fixture.
	for _frame in 6: await process_frame

func _run() -> void:
	await _case("legacy", true, false)
	await _case("stationary", false, false)
	await _case("post-process candidate", true, true)
	await _case("post-process safe follow", true, true, false, -2.0)
	await _case("post-process target motion", false, true, true)
	print("FOCUSED checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)

func _case(label: String, follow: bool, post_process: bool,
		moving: bool = false, follow_x: float = -4.0) -> void:
	await _build(1.30 if moving else 0.0)
	traces.clear()
	watching = true
	print("CASE ", label)
	# One explicit fixture initial condition: a follow destination not yet reached.
	# No transform is written after this, and the target remains stationary.
	if follow: f.player.position.x = follow_x
	if moving:
		f.target.velocity = Vector3(2.4, 0, 0)
	var ready: bool = await f.opening._released_aim_is_ready()
	_sample("helper.return")
	_check(ready, label + ": existing released-look helper reports ready")
	if post_process:
		await create_timer(0.0, true, false).timeout
	_sample("input.boundary")
	var current: Dictionary = f.aim.launch_assist_diagnostics()
	var preview: Dictionary = f.aim.aim_report()
	var dispatch := bool(current.get("eligible", false)) and not preview.is_empty() \
		and not bool(preview.get("trajectory_blocked", false))
	if dispatch:
		Input.parse_input_event(f.opening._event_for(&"interact", true))
		_sample("input.parsed")
		for _frame in 4:
			await create_timer(0.0, true, true).timeout
			if f.aim.commits > 0: break
	else:
		print("REFUSED at physical input boundary")
	if label == "legacy":
		_check(dispatch, "legacy: current eligible and physics preview clear at pad dispatch")
		_check(f.aim.commits == 1, "legacy: ordinary pad input reaches native throw commit")
		_check(f.aim.commits == 1 and not f.aim.assisted,
			"legacy: camera follow invalidates assist before native commit")
		_check_interval(label, false)
	elif label == "stationary":
		_check(dispatch and f.aim.commits == 1 and f.aim.assisted,
			"stationary: same native input ordering preserves assist")
	elif label == "post-process safe follow":
		_check(dispatch and f.aim.commits == 1 and f.aim.assisted,
			"post-process safe follow: ready press reaches assisted native commit")
	elif moving:
		_check(dispatch and f.aim.commits == 1 and not f.aim.assisted,
			"post-process target motion: timing-only candidate still permits off-body commit")
		_check_interval(label, true)
	else:
		_check(not dispatch and f.aim.commits == 0,
			"post-process candidate: observes actual invalidation before any press")
	if dispatch and OS.get_cmdline_user_args().has("--require-assisted-commit"):
		_check(f.aim.commits == 1 and f.aim.assisted,
			label + ": ready physical press MUST retain actual production assist")
	Input.parse_input_event(f.opening._event_for(&"interact", false))
	watching = false
	# Stop before release/windup: no stock override, grant or inventory write.
	f.world.queue_free()
	await process_frame

func _check_interval(label: String, target_moves: bool) -> void:
	var at_input: Dictionary = {}
	var at_commit: Dictionary = {}
	var follow_callbacks := 0
	for row in traces:
		if row.stage == "input.parsed": at_input = row
		if not at_input.is_empty() and row.stage == "rig.process.after":
			follow_callbacks += 1
		if row.stage == "throw.commit":
			at_commit = row
			break
	_check(not at_input.is_empty() and not at_commit.is_empty(), label + ": both phase receipts exist")
	if at_input.is_empty() or at_commit.is_empty(): return
	_check(at_input.forward.is_equal_approx(at_commit.forward)
		and at_input.local_camera.is_equal_approx(at_commit.local_camera)
		and is_equal_approx(at_input.spring_hit, at_commit.spring_hit),
		label + ": heading and spring-arm extension are unchanged")
	_check(bool(at_input.current.eligible) and bool(at_input.preview.eligible)
		and not bool(at_input.preview.trajectory_blocked)
		and at_commit.current.reason == "reticle_outside_body"
		and bool(at_commit.current.line_of_sight),
		label + ": exact current+preview-ready to off-body/clear-LOS verdict class")
	if target_moves:
		_check(follow_callbacks == 0 and at_input.eye.is_equal_approx(at_commit.eye)
			and at_input.target.distance_to(at_commit.target) > 0.039,
			label + ": target physics alone crosses the body boundary")
	else:
		_check(follow_callbacks == 1 and at_input.target.is_equal_approx(at_commit.target)
			and not at_input.eye.is_equal_approx(at_commit.eye),
			label + ": one native camera follow alone crosses the body boundary")
