extends "res://tests/smoke_throw_preview_occlusion.gd"
const OPENING = preload("res://tests/helpers/fresh_opening_segment.gd")
const RIG = preload("res://scripts/player/camera_rig.gd")
class CombatFixture extends Node:
	var aim: Node
	func throw_aim() -> Node: return aim
	func is_aiming() -> bool: return true
func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var player := CharacterBody3D.new()
	world.add_child(player)
	var target := TargetBody.new()
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = target.body_radius()
	shape.shape = sphere
	target.add_child(shape)
	world.add_child(target)
	target.position = Vector3(0,1,-8)
	var rig := RIG.new()
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	world.add_child(rig)
	rig.set_target(player, {"height":1.0,"distance":4.0,"pitch_start_deg":0.0,"shoulder_offset":0.0})
	var aim := AIM.new()
	world.add_child(aim)
	aim.arm(player,target,rig)
	aim.state = AIM.State.AIMING
	aim._guard = 100.0
	var combat := CombatFixture.new()
	combat.aim = aim
	world.add_child(combat)
	var opening := OPENING.new()
	opening._tree = self
	opening._rig = rig
	opening._player = player
	opening._combat = combat
	rig.set_process(false)
	rig._process(1.0)
	for frame in 6: await physics_frame
	await process_frame
	# Explicit diagnostic initial condition: a live camera follow destination
	# differs from its currently centred pose; no campaign progression proof.
	player.position.x = 3.0
	var started := Time.get_ticks_msec()
	opening._wild = target
	print("NATIVE AIM BEFORE camera=",camera.global_transform," target=",target.centre()," player=",player.global_position," report=",aim.launch_assist_diagnostics())
	var converged: bool = await opening._aim_camera_at(target)
	print("NATIVE AIM RETURN camera=",camera.global_transform," target=",target.centre()," report=",aim.launch_assist_diagnostics())
	if not OS.get_cmdline_user_args().has("--stationary-control"):
		rig._process(0.25)
	await physics_frame
	await process_frame
	var report := aim.launch_assist_diagnostics()
	print("NATIVE AIM converged=",converged," report=",report," preview=",aim.aim_report()," elapsed=",Time.get_ticks_msec()-started)
	_check(converged and (bool(report.get("eligible",false)) == OS.get_cmdline_user_args().has("--stationary-control")), "Premature success reproduced only when camera follow advances")
	opening._stop_right_stick()
	world.queue_free()
	await process_frame
	print("NATIVE AIM checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)



