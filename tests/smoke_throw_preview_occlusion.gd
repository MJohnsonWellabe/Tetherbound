extends SceneTree
## Tiny real-physics preview/orb/HUD regression. No campaign world or save.
const AIM := preload("res://scripts/combat/throw_aim.gd")
const ORB := preload("res://scenes/combat/orb.tscn")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const PREVIEW := preload("res://scripts/combat/throw_preview.gd")
var checks := 0
var failures: Array[String] = []

class TargetBody extends StaticBody3D:
	func centre() -> Vector3: return global_position
	func body_radius() -> float: return 0.8

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)
	print("PASS: " if value else "FAIL: ", message)

func _run() -> void:
	await _case("neighbor blocks hand arc",true,false)
	await _case("clear hand arc",false,false)
	await _case("own ally is excluded",true,true)
	await _segment_order(false)
	await _segment_order(true)
	print("preview occlusion checks=",checks," failures=",failures)
	quit(0 if failures.is_empty() else 1)

func _case(label: String, obstructed: bool, excluded_ally: bool) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var player := StaticBody3D.new()
	player.name = "Thrower"
	world.add_child(player)
	var target := TargetBody.new()
	target.name = "IntendedTarget"
	var sphere := SphereShape3D.new()
	sphere.radius = target.body_radius()
	var target_shape := CollisionShape3D.new()
	target_shape.shape = sphere
	target.add_child(target_shape)
	world.add_child(target)
	target.position = Vector3(0,1,8)
	var blocker: StaticBody3D
	if obstructed:
		blocker = StaticBody3D.new()
		blocker.name = "OwnAlly" if excluded_ally else "NeighborCreature"
		var box := BoxShape3D.new()
		box.size = Vector3(1.2,2,1.2)
		var collision := CollisionShape3D.new()
		collision.shape = box
		blocker.add_child(collision)
		world.add_child(blocker)
		blocker.position = Vector3(0,1,3)
	var rig := Node3D.new()
	world.add_child(rig)
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	rig.add_child(camera)
	camera.position = Vector3(0,4,-1)
	camera.look_at(target.global_position)
	var aim := AIM.new()
	world.add_child(aim)
	aim.arm(player,target,rig)
	aim.set_physics_process(false)
	if excluded_ally: aim.set_pass_through([blocker])
	aim.state = AIM.State.AIMING
	aim._guard = 1.0
	aim._committed_assist_point = target.centre()
	for frame in 3: await physics_frame
	aim._tick_aiming(0.0)
	var report: Dictionary = aim.aim_report()
	var expected_blocked := obstructed and not excluded_ally
	_check(bool(report.eligible),label+": elevated camera eligibility remains true")
	_check(bool(report.trajectory_blocked)==expected_blocked,label+": physical blocker verdict")
	_check(bool(report.trajectory_hits_target)==not expected_blocked,label+": preview agrees with clearance")
	if expected_blocked:
		_check(str(report.trajectory_blocker)=="NeighborCreature",label+": exact blocker identified")
	var manager := MANAGER.new()
	manager.set("_throw",aim)
	_check(manager.catch_aim_is_locked()==not expected_blocked,label+": actual manager HUD verdict")
	manager.free()
	var origin: Vector3 = player.global_position+Vector3.UP*float(aim._spawn_height)
	var direction: Vector3 = aim._launch_direction(camera,origin)
	origin += direction*float(aim._spawn_forward)
	var orb := ORB.instantiate()
	world.add_child(orb)
	var receipt := {"hit":false,"miss":false}
	orb.struck.connect(func(_target: Node3D,_offset: float) -> void: receipt.hit=true)
	orb.missed.connect(func(_reason: String,_closest: float,_needed: float) -> void: receipt.miss=true)
	var pass_through: Array = [player]
	if excluded_ally: pass_through.append(blocker)
	orb.launch(origin,direction,float(aim._speed),target,pass_through)
	for frame in 360:
		if receipt.hit or receipt.miss: break
		await physics_frame
	_check(bool(receipt.miss)==expected_blocked and bool(receipt.hit)==not expected_blocked,
		label+": actual flying orb matches preview")
	if expected_blocked:
		_check(str(orb._ground_collider)=="NeighborCreature",label+": orb physically struck same neighbor")
	aim._hide_preview()
	_check(not bool(aim._preview.trajectory_blocked),label+": hidden preview clears stale blockage")
	world.queue_free()
	await process_frame

func _segment_order(blocker_before: bool) -> void:
	var world := Node3D.new()
	root.add_child(world)
	var target := TargetBody.new()
	world.add_child(target)
	target.position = Vector3(0,1,1.5)
	var blocker := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1,2,0.02)
	collision.shape = box
	blocker.add_child(collision)
	world.add_child(blocker)
	blocker.position = Vector3(0,1,0.5 if blocker_before else 0.9)
	var preview := PREVIEW.new()
	world.add_child(preview)
	# One-metre samples put target entry (0.7m) and both blocker controls
	# inside the SAME segment. The first physical event must win.
	preview._gravity = 0.0
	preview._max_flight = 32.0
	preview._orb_radius = 0.0
	for frame in 3: await physics_frame
	preview.update_arc(Vector3(0,1,0),Vector3.BACK,1.0,target)
	_check(preview.trajectory_blocked == blocker_before,"same segment: blocker before target=%s" % blocker_before)
	_check(preview.trajectory_hits_target != blocker_before,"same segment: target wins only before blocker=%s" % blocker_before)
	world.queue_free()
	await process_frame
