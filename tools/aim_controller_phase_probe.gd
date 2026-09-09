extends SceneTree
## Isolated proof for command-associated post-process aim sampling. The fixture
## uses the production trainer, wild-creature movement/AI, SpringArm camera and
## ThrowAim callbacks. It tears down at commit, before release can spend an orb.
const OPENING := preload("res://tests/helpers/fresh_opening_segment.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")

const ACQUIRE_SECONDS := 4.0
const MOVING_EDGE_X := 1.30
const MOVING_EDGE_SPEED := 2.4


class TraceRig extends "res://scripts/player/camera_rig.gd":
	var observer: Callable

	func _process(delta: float) -> void:
		if observer.is_valid():
			observer.call("rig.process.before")
		super(delta)
		if observer.is_valid():
			observer.call("rig.process.after")

	func _physics_process(delta: float) -> void:
		if observer.is_valid():
			observer.call("rig.physics.before")
		super(delta)
		if observer.is_valid():
			observer.call("rig.physics.after")


class TracePlayer extends "res://scripts/player/player_controller.gd":
	var observer: Callable

	func _physics_process(delta: float) -> void:
		if observer.is_valid():
			observer.call("trainer.physics.before")
		super(delta)
		if observer.is_valid():
			observer.call("trainer.physics.after")


class TraceWild extends "res://scripts/creatures/wild_creature.gd":
	var observer: Callable

	func _physics_process(delta: float) -> void:
		if observer.is_valid():
			observer.call("target.physics.before")
		super(delta)
		if observer.is_valid():
			observer.call("target.physics.after")


class TraceAim extends "res://scripts/combat/throw_aim.gd":
	var observer: Callable
	var commits := 0
	var assisted := false

	func _tick_aiming(delta: float) -> void:
		if observer.is_valid():
			observer.call("throw.physics.before")
		super(delta)
		if observer.is_valid():
			observer.call("throw.physics.after")

	func _commit_launch_assist() -> void:
		super()
		commits += 1
		assisted = _committed_assist_point != Vector3.INF
		if observer.is_valid():
			observer.call("throw.commit")


class Combat extends Node:
	var aim: Node

	func throw_aim() -> Node:
		return aim

	func is_aiming() -> bool:
		return aim != null and aim.state == aim.State.AIMING


class PhaseOpening extends "res://tests/helpers/fresh_opening_segment.gd":
	var observer: Callable
	var requested_stick := Vector2.ZERO
	var effective_stick := Vector2.ZERO
	var command_id := 0
	var observed_command_id := 0
	var observed_requested := Vector2.ZERO
	var observed_effective := Vector2.ZERO
	var observed_turn_degrees := 0.0
	var observed_seconds := 0.0
	var command_count := 0
	var observation_count := 0
	var attribution_ok := true
	var nonzero_commands := 0
	var last_degree_error := INF

	func _aim_camera_at(target: Node3D, seconds: float = ACQUIRE_SECONDS) -> bool:
		var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
		if camera == null:
			return false
		_aim_has_history = false
		var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
		while Time.get_ticks_msec() < deadline:
			var to := (target.call("centre") as Vector3) - camera.global_position
			if to.length() < 0.01:
				return false
			var forward := -camera.global_transform.basis.z
			var wanted := to.normalized()
			var right := camera.global_transform.basis.x
			var up := camera.global_transform.basis.y
			var yaw_error := atan2(wanted.dot(right), wanted.dot(forward))
			var pitch_error := atan2(wanted.dot(up), wanted.dot(forward))
			last_degree_error = rad_to_deg(forward.angle_to(wanted))
			if observer.is_valid():
				observer.call("helper.sample")
			var centred := absf(yaw_error) < deg_to_rad(AIM_WINDOW_DEGREES) \
				and absf(pitch_error) < deg_to_rad(AIM_WINDOW_DEGREES)
			if centred and _strict_readiness_now():
				if await _released_phase_is_ready(target):
					return true
				continue

			# Keep the inherited response curve and minimum-live-stick calculation.
			# Calibration is updated only from the observation paired with this
			# command; released/stationary intervals never enter this calculation.
			var direction := Vector2(yaw_error, -pitch_error).normalized()
			var command := direction * _aim_deflection
			await _command_and_observe(target, camera, command)
		_stop_right_stick()
		return false

	func _released_phase_is_ready(target: Node3D) -> bool:
		# The production helper's existing release/process/physics sequence and no
		# additional acquisition wait or deadline reset.
		var production_ready: bool = await super._released_aim_is_ready()
		var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
		if camera == null:
			return false
		var wanted := ((target.call("centre") as Vector3) - camera.global_position).normalized()
		var forward := -camera.global_transform.basis.z
		var yaw_error := atan2(wanted.dot(camera.global_transform.basis.x), wanted.dot(forward))
		var pitch_error := atan2(wanted.dot(camera.global_transform.basis.y), wanted.dot(forward))
		last_degree_error = rad_to_deg(forward.angle_to(wanted))
		var centred := absf(yaw_error) < deg_to_rad(AIM_WINDOW_DEGREES) \
			and absf(pitch_error) < deg_to_rad(AIM_WINDOW_DEGREES)
		if observer.is_valid():
			observer.call("helper.post_settle")
		return production_ready and centred and _strict_readiness_now()

	func _strict_readiness_now() -> bool:
		if _combat == null or not bool(_combat.call("is_aiming")):
			return false
		var throw: Node = _combat.call("throw_aim")
		if throw == null:
			return false
		var current: Dictionary = throw.call("launch_assist_diagnostics")
		var preview: Dictionary = throw.call("aim_report")
		return bool(current.get("eligible", false)) and not preview.is_empty() \
			and not bool(preview.get("trajectory_blocked", true))

	func _command_and_observe(target: Node3D, camera: Camera3D, command: Vector2) -> void:
		command_id += 1
		command_count += 1
		requested_stick = command
		if command.length() > 0.0001:
			nonzero_commands += 1
		var before := -camera.global_transform.basis.z
		var started_usec := Time.get_ticks_usec()
		_send_axis(JOY_AXIS_RIGHT_X, command.x)
		_send_axis(JOY_AXIS_RIGHT_Y, command.y)
		if observer.is_valid():
			observer.call("command.requested")

		# The event was requested after the current input flush. Resume at the
		# following pre-node process signal, then observe once after camera nodes.
		await _tree.process_frame
		if observer.is_valid():
			observer.call("command.delivered")
		await _tree.create_timer(0.0, true, false).timeout

		var after := -camera.global_transform.basis.z
		effective_stick = Input.get_vector("look_left", "look_right", "look_up", "look_down")
		observed_command_id = command_id
		observed_requested = command
		observed_effective = effective_stick
		observed_turn_degrees = rad_to_deg(before.angle_to(after))
		observed_seconds = float(Time.get_ticks_usec() - started_usec) / 1000000.0
		observation_count += 1
		var same_direction := command.length() <= 0.0001 or (effective_stick.length() > 0.0001 \
			and command.normalized().dot(effective_stick.normalized()) > 0.999)
		attribution_ok = attribution_ok and observed_command_id == observation_count and same_direction
		if observer.is_valid():
			observer.call("command.observed")

		var wanted := ((target.call("centre") as Vector3) - camera.global_position).normalized()
		var remaining := rad_to_deg(after.angle_to(wanted))
		if observed_turn_degrees <= AIM_STILL_DEGREES:
			_aim_deflection = clampf(_aim_deflection * 2.0, _smallest_live_deflection(), 1.0)
		else:
			_aim_sample_turn = observed_turn_degrees
			_aim_sample_seconds = observed_seconds
			_aim_deflection = clampf(_aim_deflection * sqrt(remaining / observed_turn_degrees),
				_smallest_live_deflection(), 1.0)

	func issue_trace_command(command: Vector2) -> void:
		command_id += 1
		requested_stick = command
		_send_axis(JOY_AXIS_RIGHT_X, command.x)
		_send_axis(JOY_AXIS_RIGHT_Y, command.y)


var failures: Array[String] = []
var checks := 0
var traces: Array[Dictionary] = []
var f: Dictionary
var watching := false
var dispatch_index := -1
var commit_index := -1
var run_process_start := 0
var run_physics_start := 0


func _initialize() -> void:
	Engine.physics_ticks_per_second = 60
	Engine.max_fps = 240 if OS.get_cmdline_user_args().has("--falsification") else 60
	run_process_start = Engine.get_process_frames()
	run_physics_start = Engine.get_physics_frames()
	_run.call_deferred()


func _require(value: bool, label: String) -> bool:
	checks += 1
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures.append(label)
	return value


func _sample(stage: String) -> void:
	if not watching or f.is_empty():
		return
	var camera: Camera3D = f.camera
	var opening: PhaseOpening = f.opening
	var row := {
		"stage": stage,
		"physics": Engine.get_physics_frames(),
		"process": Engine.get_process_frames(),
		"eye": camera.global_position,
		"pivot": f.rig.global_position,
		"forward": -camera.global_basis.z,
		"target": f.target.centre(),
		"trainer": f.player.global_position,
		"requested": opening.requested_stick,
		"effective": Input.get_vector("look_left", "look_right", "look_up", "look_down"),
		"command_id": opening.command_id,
		"observed_command_id": opening.observed_command_id,
		"observed_requested": opening.observed_requested,
		"observed_effective": opening.observed_effective,
		"observed_turn": opening.observed_turn_degrees,
		"degree_error": opening.last_degree_error,
		"current": f.aim.launch_assist_diagnostics(),
		"preview": f.aim.aim_report(),
		"pressed": Input.is_action_pressed("interact"),
		"just_pressed": Input.is_action_just_pressed("interact"),
	}
	traces.append(row)
	if stage == "input.dispatch":
		dispatch_index = traces.size() - 1
	elif stage == "throw.commit":
		commit_index = traces.size() - 1
	if stage in ["legacy.helper.sample", "legacy.rig.after", "command.observed",
			"helper.post_settle", "input.dispatch", "input.parsed", "throw.commit"]:
		print("PHASE ", row)


func _build(adversarial_order: bool, initial_target_x: float = 0.0,
		blocked: bool = false) -> void:
	var world := Node3D.new()
	world.name = "AimControllerPhaseWorld"
	root.add_child(world)

	var floor := StaticBody3D.new()
	floor.name = "Floor"
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size = Vector3(24.0, 0.2, 24.0)
	floor_shape.shape = floor_box
	floor.add_child(floor_shape)
	floor.position.y = -0.1
	world.add_child(floor)

	# Ordinary solo order: CameraRig, Player, CombatManager/ThrowAim, then wild.
	# The adversarial control deliberately retains target-before-throw order.
	var rig := TraceRig.new()
	rig.name = "CameraRig"
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	world.add_child(rig)

	var player := TracePlayer.new()
	player.name = "Player"
	player.camera_rig_path = NodePath("../CameraRig")
	var player_collision := CollisionShape3D.new()
	player_collision.name = "Collision"
	var player_capsule := CapsuleShape3D.new()
	player_capsule.radius = 0.4
	player_capsule.height = 1.8
	player_collision.shape = player_capsule
	player_collision.position.y = 0.9
	player.add_child(player_collision)
	world.add_child(player)

	var target := TraceWild.new()
	target.name = "PhaseWild"
	var target_collision := CollisionShape3D.new()
	target_collision.name = "Collision"
	target.add_child(target_collision)
	var model := Node3D.new()
	model.name = "Model"
	target.add_child(model)
	var body := MeshInstance3D.new()
	body.name = "Body"
	target.add_child(body)
	var head := MeshInstance3D.new()
	head.name = "Head"
	target.add_child(head)
	target.position = Vector3(initial_target_x, 0.0, -8.0)
	target.populate("bramblebun", player)

	var manager := Combat.new()
	manager.name = "CombatManager"
	var aim := TraceAim.new()
	aim.name = "ThrowAim"
	manager.aim = aim
	manager.add_child(aim)

	if adversarial_order:
		world.add_child(target)
		world.add_child(manager)
	else:
		world.add_child(manager)
		world.add_child(target)

	if blocked:
		var blocker := StaticBody3D.new()
		blocker.name = "HandArcBlocker"
		var blocker_collision := CollisionShape3D.new()
		var blocker_box := BoxShape3D.new()
		blocker_box.size = Vector3(0.5, 3.0, 0.2)
		blocker_collision.shape = blocker_box
		blocker.add_child(blocker_collision)
		blocker.position = Vector3(0.0, 1.5, -3.0)
		world.add_child(blocker)

	rig.set_target(player, CATCH.config().get("aim", {}))
	aim.arm(player, target, rig)
	aim.state = aim.State.AIMING
	aim._guard = 0.0
	target.set_engaged(true, player)
	target.set_catch_aim_active(true)

	var opening := PhaseOpening.new()
	opening._tree = self
	opening._rig = rig
	opening._player = player
	opening._combat = manager
	opening._wild = target
	f = {"world": world, "player": player, "target": target, "rig": rig,
		"camera": camera, "manager": manager, "aim": aim, "opening": opening}
	rig.observer = _sample
	player.observer = _sample
	target.observer = _sample
	aim.observer = _sample
	opening.observer = _sample

	for _frame in 6:
		await physics_frame
	for _frame in 6:
		await process_frame


func _run() -> void:
	if not await _legacy_phase_prerequisite():
		await _finish()
		return
	if not await _case("production stationary", false, false, 0.0, false, 0.0):
		await _finish()
		return
	if not await _case("production moving edge", false, true, MOVING_EDGE_X, false,
			MOVING_EDGE_SPEED):
		await _finish()
		return
	if not await _case("production nonzero follow residual", false, true, 0.0, true, 0.0):
		await _finish()
		return
	if not await _blocked_case():
		await _finish()
		return
	if not await _case("adversarial moving edge target-before-throw", true, true,
			MOVING_EDGE_X, false, MOVING_EDGE_SPEED):
		await _finish()
		return
	if not await _case("adversarial follow target-before-throw", true, true, 0.0, true, 0.0):
		await _finish()
		return

	var process_count := Engine.get_process_frames() - run_process_start
	var physics_count := Engine.get_physics_frames() - run_physics_start
	print("CALLBACK_TOTAL process=", process_count, " physics=", physics_count,
		" requested_ratio=", "4:1" if OS.get_cmdline_user_args().has("--falsification") else "1:1")
	if OS.get_cmdline_user_args().has("--falsification"):
		_require(process_count > physics_count * 2,
			"different-ratio falsification observes more than two idle callbacks per physics callback")
	else:
		_require(process_count > 0 and physics_count > 0,
			"60 Hz proof records native process and physics callback counts")
	await _finish()


func _legacy_phase_prerequisite() -> bool:
	await _build(false)
	watching = true
	traces.clear()
	var opening: PhaseOpening = f.opening
	opening._stop_right_stick()
	await process_frame
	await create_timer(0.0, true, false).timeout

	var delivered := Vector2(0.35, 0.0)
	opening.issue_trace_command(delivered)
	await process_frame
	var before: Vector3 = -f.camera.global_basis.z
	var effective_before := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	var newly_requested := Vector2(0.75, 0.0)
	opening.issue_trace_command(newly_requested)
	_sample("legacy.helper.sample")
	await create_timer(0.0, true, false).timeout
	var after: Vector3 = -f.camera.global_basis.z
	_sample("legacy.rig.after")
	var turn := rad_to_deg(before.angle_to(after))
	var ok := true
	ok = _require(effective_before.length() > 0.0
		and effective_before.normalized().dot(delivered.normalized()) > 0.999,
		"phase prerequisite: camera frame receives the preceding delivered command") and ok
	ok = _require(newly_requested.distance_to(effective_before) > 0.1,
		"phase prerequisite: helper's newly requested command differs from effective stick") and ok
	ok = _require(turn > 0.02,
		"phase prerequisite: post-camera turn occurs after the mismatched helper sample") and ok
	opening._stop_right_stick()
	watching = false
	f.world.queue_free()
	await process_frame
	return ok


func _case(label: String, adversarial_order: bool, moving: bool,
		initial_target_x: float, follow: bool, initial_speed: float) -> bool:
	await _build(adversarial_order, initial_target_x)
	traces.clear()
	dispatch_index = -1
	commit_index = -1
	watching = true
	print("CASE ", label)
	if follow:
		# Fixture initial condition only, before the measured acquisition interval.
		f.player.position.x = -4.0
	if moving:
		f.target.velocity = Vector3(initial_speed, 0.0, 0.0)
	var began_ms := Time.get_ticks_msec()
	var ready: bool = await f.opening._aim_camera_at(f.target, ACQUIRE_SECONDS)
	var elapsed_ms := Time.get_ticks_msec() - began_ms
	_sample("input.dispatch")
	var current: Dictionary = f.aim.launch_assist_diagnostics()
	var preview: Dictionary = f.aim.aim_report()
	var ok := true
	ok = _require(ready and elapsed_ms <= int(ACQUIRE_SECONDS * 1000.0) + 50,
		label + ": one-degree acquisition is live inside the unchanged four-second deadline") and ok
	ok = _require(f.opening.nonzero_commands > 0 and f.opening.command_count == f.opening.observation_count
		and f.opening.attribution_ok,
		label + ": every steering command has one matching post-process observation") and ok
	ok = _require(bool(current.get("eligible", false)) and not preview.is_empty()
		and not bool(preview.get("trajectory_blocked", true)),
		label + ": unchanged strict current/preview/trajectory gates hold at dispatch") and ok
	if not ok:
		await _teardown()
		return false

	Input.parse_input_event(f.opening._event_for(&"interact", true))
	_sample("input.parsed")
	for _frame in 8:
		await create_timer(0.0, true, true).timeout
		if f.aim.commits > 0:
			break
	ok = _require(f.aim.commits == 1 and f.aim.assisted,
		label + ": ready buffered press retains strict assisted production commit") and ok
	ok = _check_commit_interval(label, 1 if adversarial_order else 0) and ok
	await _teardown()
	return ok


func _blocked_case() -> bool:
	await _build(false, 0.0, true)
	traces.clear()
	watching = true
	print("CASE production blocked hand trajectory")
	var ready: bool = await f.opening._aim_camera_at(f.target, ACQUIRE_SECONDS)
	var preview: Dictionary = f.aim.aim_report()
	var ok := true
	ok = _require(not ready, "blocked hand trajectory: unchanged deadline expires without readiness") and ok
	ok = _require(bool(preview.get("trajectory_blocked", false))
		and str(preview.get("trajectory_blocker", "")) == "HandArcBlocker",
		"blocked hand trajectory: real preview names the physical blocker") and ok
	ok = _require(f.aim.commits == 0 and is_zero_approx(float(f.aim.get("_windup")))
		and not Input.is_action_pressed("interact"),
		"blocked hand trajectory: no press, commit, windup or spend path") and ok
	await _teardown()
	return ok


func _check_commit_interval(label: String, expected_target_steps: int) -> bool:
	var ok := _require(dispatch_index >= 0 and commit_index > dispatch_index,
		label + ": dispatch and native production commit receipts exist")
	if not ok:
		return false
	var target_steps := 0
	var trainer_steps := 0
	var process_steps := 0
	for index in range(dispatch_index + 1, commit_index + 1):
		if traces[index].stage == "target.physics.after":
			target_steps += 1
		elif traces[index].stage == "trainer.physics.after":
			trainer_steps += 1
		elif traces[index].stage == "rig.process.after":
			process_steps += 1
	var at_dispatch: Dictionary = traces[dispatch_index]
	var at_commit: Dictionary = traces[commit_index]
	ok = _require(target_steps == expected_target_steps,
		label + ": target movement callback count matches tree order") and ok
	ok = _require(bool(at_dispatch.current.get("eligible", false))
		and bool(at_dispatch.preview.get("eligible", false))
		and not bool(at_dispatch.preview.get("trajectory_blocked", true))
		and bool(at_commit.current.get("eligible", false))
		and bool(at_commit.current.get("line_of_sight", false)),
		label + ": dispatch predicts the strict commit body and LOS verdict") and ok
	print("INTERVAL ", label, " target_steps=", target_steps,
		" trainer_steps=", trainer_steps, " process_steps=", process_steps,
		" dispatch_offset=", at_dispatch.current.get("reticle_offset", INF),
		" commit_offset=", at_commit.current.get("reticle_offset", INF))
	return ok


func _teardown() -> void:
	Input.parse_input_event(f.opening._event_for(&"interact", false))
	f.opening._stop_right_stick()
	watching = false
	# Queue immediately after the commit callback/timer; release windup never runs.
	f.world.queue_free()
	await process_frame
	f = {}


func _finish() -> void:
	print("PHASE_PROOF checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)
