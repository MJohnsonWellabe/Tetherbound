extends SceneTree
## Driver-only centering/motion guard proof. Uses the real SpringArm rig, real
## throw physics and the opening helper's physical pad event. It stops every
## successful case immediately after commit, before release can spend an orb.
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
	var desired_speed := 0.0
	var _acceleration := 0.0
	var _impulse := Vector3.ZERO
	var _gravity := 0.0
	var _jump_speed := 0.0
	var guard_new_impulse_bound := 0.0
	var guard_environment_clear := true
	func centre() -> Vector3: return global_position
	func body_radius() -> float: return 0.8
	func combat_config() -> Dictionary: return {"lunge": guard_new_impulse_bound}
	func _physics_process(delta: float) -> void:
		if observer.is_valid(): observer.call("target.physics.before")
		velocity.x = move_toward(velocity.x, desired_speed, _acceleration * delta)
		move_and_slide()
		if observer.is_valid(): observer.call("target.physics.after")

class Combat extends Node:
	var aim: Node
	func throw_aim() -> Node: return aim
	func is_aiming() -> bool: return aim.state == aim.State.AIMING

class GuardOpening extends "res://tests/helpers/fresh_opening_segment.gd":
	var observer: Callable
	var rejected_candidates := 0
	var nonzero_steering_commands := 0
	var last_guard: Dictionary = {}

	func _aim_camera_at(target: Node3D, seconds: float = AIM_CONVERGE_SECONDS) -> bool:
		var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
		if camera == null:
			return false
		_aim_has_history = false
		var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
		while Time.get_ticks_msec() < deadline:
			var to := (target.call("centre") as Vector3) - camera.global_position
			if to.length() < 0.01:
				_stop_right_stick()
				await _tree.process_frame
				continue
			var forward := -camera.global_transform.basis.z
			var wanted := to.normalized()
			var right := camera.global_transform.basis.x
			var up := camera.global_transform.basis.y
			var yaw_error := atan2(wanted.dot(right), wanted.dot(forward))
			var pitch_error := atan2(wanted.dot(up), wanted.dot(forward))
			last_guard = _guard_snapshot(target, camera, yaw_error, pitch_error)
			if bool(last_guard.get("safe", false)):
				if await _released_guard_is_ready(target):
					return true
				rejected_candidates += 1
				_aim_has_history = false
				continue
			rejected_candidates += 1
			# A rejected eligible or one-degree candidate still drives the stick.
			# This deliberately removes the inherited `or _shot_is_eligible()` seam.
			var error_degrees := rad_to_deg(forward.angle_to(wanted))
			var deflection := _calibrated_deflection(forward, error_degrees)
			var direction := Vector2(yaw_error, pitch_error).normalized()
			var x := direction.x * deflection
			var y := -direction.y * deflection
			if absf(x) > 0.0001 or absf(y) > 0.0001:
				nonzero_steering_commands += 1
			_send_axis(JOY_AXIS_RIGHT_X, x)
			_send_axis(JOY_AXIS_RIGHT_Y, y)
			await _tree.process_frame
		_stop_right_stick()
		return false

	func _released_guard_is_ready(target: Node3D) -> bool:
		# Exactly the existing release/process/physics sequence; no added wait.
		var production_ready: bool = await super._released_aim_is_ready()
		var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
		if camera == null:
			return false
		var errors := _axis_errors(target, camera)
		last_guard = _guard_snapshot(target, camera, errors.x, errors.y)
		if observer.is_valid(): observer.call("guard.post_settle")
		return production_ready and bool(last_guard.get("safe", false))

	func _guard_snapshot(target: Node3D, camera: Camera3D,
			yaw_error: float, pitch_error: float) -> Dictionary:
		var throw: Node = _combat.call("throw_aim") if _combat != null else null
		var current: Dictionary = throw.call("launch_assist_diagnostics") if throw != null else {}
		var preview: Dictionary = throw.call("aim_report") if throw != null else {}
		var forward := -camera.global_transform.basis.z
		var camera_bound := _camera_follow_bound(forward)
		var motion := _target_motion_bound(target, forward)
		var offset := float(current.get("reticle_offset", INF))
		var radius := float(current.get("reticle_radius", -1.0))
		var total := offset + camera_bound + float(motion.get("metres", INF))
		var centred := absf(yaw_error) < deg_to_rad(AIM_WINDOW_DEGREES) \
			and absf(pitch_error) < deg_to_rad(AIM_WINDOW_DEGREES)
		var production_ready := bool(current.get("eligible", false)) \
			and not preview.is_empty() and not bool(preview.get("trajectory_blocked", false))
		return {
			"safe": centred and production_ready and bool(motion.get("certain", false)) \
				and total <= radius,
			"centred": centred,
			"production_ready": production_ready,
			"offset_now": offset,
			"radius": radius,
			"camera_bound": camera_bound,
			"target_bound": float(motion.get("metres", INF)),
			"bound_total": total,
			"motion_certain": bool(motion.get("certain", false)),
			"motion_reason": str(motion.get("reason", "")),
		}

	func _camera_follow_bound(forward: Vector3) -> float:
		if _rig == null or not _has_property(_rig, &"_target") \
				or not _has_property(_rig, &"_height") or not _has_property(_rig, &"_shoulder"):
			return INF
		var followed := _rig.get("_target") as Node3D
		if followed == null or not is_instance_valid(followed):
			return INF
		var desired := followed.global_position + Vector3.UP * float(_rig.get("_height"))
		var shoulder := float(_rig.get("_shoulder"))
		if not is_zero_approx(shoulder):
			desired += Basis(Vector3.UP, float(_rig.get("yaw"))).x * shoulder
		return _perpendicular(desired - _rig.global_position, forward).length()

	func _target_motion_bound(target: Node3D, forward: Vector3) -> Dictionary:
		if not target is CharacterBody3D:
			return {"certain": false, "metres": INF, "reason": "target is not CharacterBody3D"}
		for property: StringName in [&"_acceleration", &"_impulse", &"_gravity", &"_jump_speed"]:
			if not _has_property(target, property):
				return {"certain": false, "metres": INF, "reason": "missing " + str(property)}
		if not _environment_is_bounded(target):
			return {"certain": false, "metres": INF, "reason": "environment velocity active/unknown"}
		var hz := float(Engine.physics_ticks_per_second)
		if hz <= 0.0:
			return {"certain": false, "metres": INF, "reason": "invalid physics rate"}
		var dt := 1.0 / hz
		var body := target as CharacterBody3D
		var velocity_term := _perpendicular(body.velocity, forward).length() * dt
		# creature_body uses semi-implicit move_toward, so a full a*dt^2 is the
		# displacement allowance. Gravity is budgeted the same way for airborne state.
		var acceleration_term := (absf(float(target.get("_acceleration"))) \
			+ absf(float(target.get("_gravity")))) * dt * dt
		var current_impulse := target.get("_impulse") as Vector3
		var impulse_term := _perpendicular(current_impulse, forward).length() * dt
		var new_impulse := 0.0
		if target.has_method("combat_config"):
			new_impulse = absf(float((target.call("combat_config") as Dictionary).get("lunge", 0.0)))
		elif _has_property(target, &"guard_new_impulse_bound"):
			new_impulse = absf(float(target.get("guard_new_impulse_bound")))
		else:
			return {"certain": false, "metres": INF, "reason": "new impulse bound unavailable"}
		var jump_term := absf(float(target.get("_jump_speed"))) * dt
		return {"certain": true,
			"metres": velocity_term + acceleration_term + impulse_term + new_impulse * dt + jump_term,
			"reason": "one input-to-poll physics step"}

	func _environment_is_bounded(target: Node3D) -> bool:
		if _has_property(target, &"_environment_velocity"):
			var modifiers: Variant = target.get("_environment_velocity")
			if modifiers == null or not _has_property(modifiers, &"_entries"):
				return false
			return (modifiers.get("_entries") as Dictionary).is_empty()
		return _has_property(target, &"guard_environment_clear") \
			and bool(target.get("guard_environment_clear"))

	func _axis_errors(target: Node3D, camera: Camera3D) -> Vector2:
		var wanted := ((target.call("centre") as Vector3) - camera.global_position).normalized()
		var forward := -camera.global_transform.basis.z
		return Vector2(atan2(wanted.dot(camera.global_transform.basis.x), wanted.dot(forward)),
			atan2(wanted.dot(camera.global_transform.basis.y), wanted.dot(forward)))

	func _perpendicular(delta: Vector3, forward: Vector3) -> Vector3:
		var normal := forward.normalized()
		return delta - normal * delta.dot(normal)

	func _has_property(object: Object, property: StringName) -> bool:
		if object == null:
			return false
		for row: Dictionary in object.get_property_list():
			if StringName(row.get("name", "")) == property:
				return true
		return false

var failures: Array[String] = []
var checks := 0
var traces: Array[Dictionary] = []
var f: Dictionary
var watching := false
var parsed_index := -1
var commit_index := -1

func _initialize() -> void:
	var physics_fps := 60
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--physics-fps="):
			physics_fps = int(arg.get_slice("=", 1))
	Engine.physics_ticks_per_second = physics_fps
	Engine.max_fps = 240 if OS.get_cmdline_user_args().has("--falsification") else 60
	_run.call_deferred()

func _check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
	print("PASS: " if value else "FAIL: ", label)

func _sample(stage: String) -> void:
	if not watching: return
	var row := {"stage": stage, "physics": Engine.get_physics_frames(),
		"process": Engine.get_process_frames(), "eye": f.camera.global_position,
		"pivot": f.rig.global_position, "forward": -f.camera.global_basis.z,
		"target": f.target.centre(), "current": f.aim.launch_assist_diagnostics(),
		"preview": f.aim.aim_report(), "guard": f.opening.last_guard.duplicate(true),
		"pressed": Input.is_action_pressed("interact"),
		"just_pressed": Input.is_action_just_pressed("interact")}
	traces.append(row)
	if stage == "input.parsed": parsed_index = traces.size() - 1
	if stage == "throw.commit": commit_index = traces.size() - 1
	if stage in ["guard.post_settle", "helper.return", "input.parsed", "throw.commit"]:
		print("PHASE ", row)

func _build(initial_target_x: float, target_speed: float, acceleration: float) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var player := CharacterBody3D.new()
	world.add_child(player)
	var target := Target.new()
	target.name = "GuardTarget"
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = target.body_radius()
	collision.shape = sphere
	target.add_child(collision)
	world.add_child(target)
	target.position = Vector3(initial_target_x, 1, -8)
	# Motion begins at the case boundary after physics-space warmup, matching the
	# focused diagnosis' moving initial condition exactly.
	target.velocity = Vector3.ZERO
	target.desired_speed = 0.0
	target._acceleration = 0.0
	var rig := TraceRig.new()
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	world.add_child(rig)
	# Keep the focused diagnosis' exact real-rig initial geometry so its two
	# sufficient causes remain comparable rather than being tuned away.
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
	var opening := GuardOpening.new()
	opening._tree = self
	opening._rig = rig
	opening._player = player
	opening._combat = combat
	opening._wild = target
	f = {"world": world, "player": player, "target": target, "rig": rig,
		"camera": camera, "aim": aim, "opening": opening}
	rig.observer = _sample
	aim.observer = _sample
	target.observer = _sample
	opening.observer = _sample
	for _frame in 6: await physics_frame
	for _frame in 6: await process_frame

func _run() -> void:
	if OS.get_cmdline_user_args().has("--falsification"):
		await _case("4:1 accelerating follow+motion falsification", true, 1.30, 2.4, 34.0)
		_check_process_ratio()
	else:
		await _case("legacy unsettled follow", true, 0.0, 0.0, 0.0, true)
		await _case("moving edge", false, 1.30, 2.4, 0.0, true)
		await _case("stationary", false, 0.0, 0.0, 0.0)
		await _case("safe follow", true, 0.0, 0.0, 0.0, false, -2.0)
		await _case("moving centered", false, 0.0, 0.35, 0.0)
		await _blocked_no_spend_case()
	print("GUARD checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)

func _case(label: String, follow: bool, initial_x: float, speed: float, acceleration: float,
		require_correction: bool = false, follow_x: float = -4.0) -> void:
	await _build(initial_x, speed, acceleration)
	traces.clear()
	parsed_index = -1
	commit_index = -1
	watching = true
	print("CASE ", label)
	if follow: f.player.position.x = follow_x
	f.target.velocity = Vector3(speed, 0, 0)
	f.target.desired_speed = speed
	f.target._acceleration = acceleration
	var initial: Dictionary = f.aim.launch_assist_diagnostics()
	var ready: bool = await f.opening._aim_camera_at(f.target, 4.0)
	_sample("helper.return")
	var current: Dictionary = f.aim.launch_assist_diagnostics()
	var preview: Dictionary = f.aim.aim_report()
	_check(ready, label + ": guarded steering reports ready")
	_check(bool(current.get("eligible", false)) and not preview.is_empty()
		and not bool(preview.get("trajectory_blocked", true)),
		label + ": strict current and physical-preview gates hold at dispatch")
	_check(bool(f.opening.last_guard.get("safe", false)),
		label + ": metre bound and one-degree centering hold at dispatch")
	if require_correction:
		_check(bool(initial.get("eligible", false)), label + ": preserves initially eligible edge prerequisite")
		_check(f.opening.nonzero_steering_commands > 0,
			label + ": rejected eligible candidate actually steers")
	if ready:
		Input.parse_input_event(f.opening._event_for(&"interact", true))
		_sample("input.parsed")
		for _frame in 8:
			await create_timer(0.0, true, true).timeout
			if f.aim.commits > 0: break
	_check(f.aim.commits == 1 and f.aim.assisted,
		label + ": ordinary buffered pad input retains production assist")
	_check_commit_interval(label)
	Input.parse_input_event(f.opening._event_for(&"interact", false))
	watching = false
	f.world.queue_free()
	await process_frame

func _blocked_no_spend_case() -> void:
	await _build(0.0, 0.0, 0.0)
	var blocker := StaticBody3D.new()
	blocker.name = "GuardBlocker"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 2.0, 0.08)
	collision.shape = box
	blocker.add_child(collision)
	f.world.add_child(blocker)
	blocker.position = Vector3(0, 1.0, -3.5)
	for _frame in 3: await physics_frame
	watching = true
	var ready: bool = await f.opening._aim_camera_at(f.target, 1.0)
	var preview: Dictionary = f.aim.aim_report()
	_check(not ready, "blocked trajectory: one unchanged deadline expires without readiness")
	_check(bool(preview.get("trajectory_blocked", false)),
		"blocked trajectory: real production preview names the obstruction")
	_check(f.aim.commits == 0 and is_zero_approx(float(f.aim.get("_windup")))
		and not Input.is_action_pressed("interact"),
		"blocked trajectory: no pad dispatch, commit, windup or spend path")
	_check(f.opening.rejected_candidates > 0,
		"blocked trajectory: refusal remains inside the single active deadline")
	watching = false
	f.world.queue_free()
	await process_frame

func _check_commit_interval(label: String) -> void:
	_check(parsed_index >= 0 and commit_index > parsed_index, label + ": native parse and commit receipts exist")
	if parsed_index < 0 or commit_index <= parsed_index: return
	var target_steps := 0
	var process_steps := 0
	for index in range(parsed_index + 1, commit_index + 1):
		if traces[index].stage == "target.physics.after": target_steps += 1
		if traces[index].stage == "rig.process.after": process_steps += 1
	var at_input: Dictionary = traces[parsed_index]
	var at_commit: Dictionary = traces[commit_index]
	var bound := float(at_input.guard.get("bound_total", INF))
	var committed_offset := float(at_commit.current.get("reticle_offset", INF))
	_check(target_steps == 1, label + ": input reaches commit after exactly one target physics step")
	_check(committed_offset <= bound + 0.001,
		label + ": actual commit offset stays under dispatched geometric bound")
	_check(bool(at_commit.current.get("eligible", false)) and bool(at_commit.current.get("line_of_sight", false)),
		label + ": commit-time production verdict remains eligible and clear")
	print("INTERVAL ", label, " target_steps=", target_steps,
		" process_steps=", process_steps, " bound=", bound, " actual=", committed_offset)

func _check_process_ratio() -> void:
	if parsed_index < 0 or commit_index <= parsed_index: return
	var process_steps := 0
	for index in range(parsed_index + 1, commit_index + 1):
		if traces[index].stage == "rig.process.after": process_steps += 1
	_check(process_steps >= 2,
		"4:1 falsification: multiple camera idle callbacks occur before the next physics commit")
