extends "res://tests/smoke_throw_preview_occlusion.gd"
## Tiny native regression for released-look aim readiness. No Terrain3D or save.
const OPENING := preload("res://tests/helpers/fresh_opening_segment.gd")
const RIG := preload("res://scripts/player/camera_rig.gd")

class CommitAim extends "res://scripts/combat/throw_aim.gd":
	var spends := 0
	var commit_eligible := false
	var physics_refreshes := 0
	func _spend_orb() -> bool:
		spends += 1
		return true
	func _commit_launch_assist() -> void:
		super()
		commit_eligible = _committed_assist_point != Vector3.INF
	func _tick_aiming(delta: float) -> void:
		super(delta)
		physics_refreshes += 1

class LegacyOpening extends "res://tests/helpers/fresh_opening_segment.gd":
	# Exact readiness defect under test: angular convergence returned before a
	# released-look camera process and throw physics refresh.
	func _aim_camera_at(target: Node3D, _seconds: float = AIM_CONVERGE_SECONDS) -> bool:
		var camera := _rig.get_node_or_null(^"Camera3D") as Camera3D
		var wanted := ((target.call("centre") as Vector3) - camera.global_position).normalized()
		var forward := -camera.global_transform.basis.z
		if rad_to_deg(forward.angle_to(wanted)) <= AIM_WINDOW_DEGREES:
			_stop_right_stick()
			return true
		return await super._aim_camera_at(target, _seconds)

class CombatFixture extends Node:
	var aim: Node
	func throw_aim() -> Node: return aim
	func is_aiming() -> bool: return aim != null and aim.state == aim.State.AIMING
	func is_fighting() -> bool: return true

class MovingTarget extends StaticBody3D:
	var velocity := Vector3.ZERO
	func centre() -> Vector3: return global_position
	func body_radius() -> float: return 0.8
	func _process(delta: float) -> void: position += velocity * delta

func _run() -> void:
	if OS.get_cmdline_user_args().has("--legacy-readiness"):
		await _readiness_case("pre-settle camera follow (legacy baseline)", true, false, true)
		print("aim readiness legacy checks=", checks, " failures=", failures)
		quit(0 if failures.is_empty() else 1)
		return
	await _readiness_case("pre-settle camera follow", true, false)
	await _readiness_case("stationary control", false, false)
	await _readiness_case("moving target", false, true)
	await _blocked_no_spend_case()
	print("aim readiness checks=", checks, " failures=", failures)
	quit(0 if failures.is_empty() else 1)

func _fixture(moving: bool = false, legacy: bool = false) -> Dictionary:
	var world := Node3D.new()
	root.add_child(world)
	var player := CharacterBody3D.new()
	world.add_child(player)
	var target := MovingTarget.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = target.body_radius()
	shape.shape = sphere
	target.add_child(shape)
	world.add_child(target)
	target.position = Vector3(0, 1, -8)
	target.velocity = Vector3(0.35, 0, 0) if moving else Vector3.ZERO
	var rig := RIG.new()
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	world.add_child(rig)
	rig.set_target(player, {"height": 1.0, "distance": 4.0, "pitch_start_deg": 0.0,
		"shoulder_offset": 0.0})
	var aim := CommitAim.new()
	world.add_child(aim)
	aim.arm(player, target, rig)
	aim.state = aim.State.AIMING
	aim._guard = 0.0
	var combat := CombatFixture.new()
	combat.aim = aim
	world.add_child(combat)
	var opening = LegacyOpening.new() if legacy else OPENING.new()
	opening._tree = self
	opening._rig = rig
	opening._player = player
	opening._combat = combat
	opening._wild = target
	for _frame in 6: await physics_frame
	await process_frame
	return {"world": world, "player": player, "target": target, "rig": rig,
		"camera": camera, "aim": aim, "opening": opening}

func _readiness_case(label: String, unsettled_follow: bool, moving: bool,
		legacy: bool = false) -> void:
	var f := await _fixture(moving, legacy)
	if unsettled_follow:
		# The camera is centered at the old follow pose. Moving the player creates
		# the exact stale-success condition without touching the rig transform.
		f.player.position.x = 6.0
	var refreshes_before: int = f.aim.physics_refreshes
	var ready: bool = await f.opening._aim_camera_at(f.target, 4.0)
	var current: Dictionary = f.aim.launch_assist_diagnostics()
	var preview: Dictionary = f.aim.aim_report()
	_check(ready, label + ": released-look convergence succeeds")
	_check(f.aim.physics_refreshes > refreshes_before,
		label + ": readiness returns only after throw physics refresh")
	_check(bool(current.get("eligible", false)), label + ": current production verdict survives release")
	_check(not bool(preview.get("trajectory_blocked", true)), label + ": refreshed physical preview is clear")
	var before: int = f.aim.spends
	await f.opening._tap_action(&"interact")
	for _frame in 30:
		if f.aim.spends > before:
			break
		await physics_frame
	_check(f.aim.spends == before + 1, label + ": actual pad input reaches throw release")
	_check(f.aim.commit_eligible, label + ": eligibility survives through actual throw commit")
	_check(f.aim.last_launch().has("direction"), label + ": production throw records a committed launch")
	f.world.queue_free()
	await process_frame

func _blocked_no_spend_case() -> void:
	var f := await _fixture(false)
	# This thin blocker sits below the elevated camera ray but crosses the hand
	# trajectory used by the production preview.
	var blocker := StaticBody3D.new()
	blocker.name = "RegressionBlocker"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.2, 2.0, 0.08)
	collision.shape = box
	blocker.add_child(collision)
	f.world.add_child(blocker)
	blocker.position = Vector3(0, 1.0, -3.5)
	for _frame in 3: await physics_frame
	var ready: bool = await f.opening._aim_camera_at(f.target, 1.0)
	var preview: Dictionary = f.aim.aim_report()
	_check(not ready, "blocked LOS: readiness refuses through the full bounded convergence")
	_check(bool(preview.get("trajectory_blocked", false)), "blocked LOS: real preview identifies obstruction")
	_check(f.aim.spends == 0, "blocked LOS: no orb is spent")
	f.world.queue_free()
	await process_frame
