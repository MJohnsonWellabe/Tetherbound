extends SceneTree

## F39#0 GPU pass, Aquaryn basin: the camera arm stopped on Aquaryn's flank
## and the lens sat inside the trainer's hair. Out of a fight the arm now
## sweeps through Aquaryn (`camera_rig.gd::PASS_THROUGH_GROUP`) and the body
## fades while the lens is inside it (`creature_body.gd` camera fade).
##
##   godot --headless --path . --script tests/smoke_camera_pass_through.gd
##
## 1. A solid body on the arm's centre line shortens the arm (the control, so
##    case 2 is not vacuous), and the same body in the group does not.
## 2. Aquaryn's world body joins the group and opts into the fade out of a
##    fight, and leaves both while this peer fights (any phase, catching and
##    resolving included, host or guest) or is in any other local fight.
## 3. A body that opts in dithers every model surface with the camera inside
##    it, and hands them back when the camera leaves.

const RIG_SCRIPT := "res://scripts/player/camera_rig.gd"
const RIG := preload("res://scripts/player/camera_rig.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const CREATURE_BODY := preload("res://scripts/creatures/creature_body.gd")
const ALPHA_BODY := preload("res://scripts/creatures/water_alpha_body.gd")
const WATER_ALPHA := preload("res://scripts/combat/water_alpha.gd")
const ARM_LENGTH := 6.0
const SETTLE_FRAMES := 8

var _failures: Array[String] = []
var _world: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	_world = Node3D.new()
	root.add_child(_world)
	await physics_frame
	await _the_arm_passes_through_a_grouped_body()
	await _aquaryn_passes_only_out_of_a_fight()
	await _an_opted_in_body_fades_with_the_lens_inside()
	_report()


func _the_arm_passes_through_a_grouped_body() -> void:
	var blocker := _spawn_blocker()
	var arm := _spawn_arm()
	for i in SETTLE_FRAMES:
		await physics_frame
	if arm.get_hit_length() >= ARM_LENGTH - 0.01:
		_fail("control: an ungrouped body on the centre line did not shorten the arm (%.2fm)" % arm.get_hit_length())
	else:
		print("control: arm stops at %.2fm on an ungrouped body" % arm.get_hit_length())
	blocker.add_to_group(RIG.PASS_THROUGH_GROUP)
	for i in SETTLE_FRAMES:
		await physics_frame
	if arm.get_hit_length() < ARM_LENGTH - 0.01:
		_fail("a pass-through body still shortened the arm to %.2fm of %.2fm" % [arm.get_hit_length(), ARM_LENGTH])
	else:
		print("pass-through: arm keeps its full %.2fm" % arm.get_hit_length())
	blocker.remove_from_group(RIG.PASS_THROUGH_GROUP)
	for i in SETTLE_FRAMES:
		await physics_frame
	if arm.get_hit_length() >= ARM_LENGTH - 0.01:
		_fail("leaving the group did not restore the arm's collision with the body")
	arm.queue_free()
	blocker.queue_free()
	await physics_frame


func _aquaryn_passes_only_out_of_a_fight() -> void:
	# The real predicate, on local state only (review of 5b1179976: a guest
	# never holds the authority record, and catching/resolving still count).
	var alpha: Node = WATER_ALPHA.new()
	if not bool(alpha.call("camera_passes_through")):
		_fail("no local fight: the arm should pass through Aquaryn")
	alpha.set("_local_fight", true)
	alpha.set("_encounter", {"phase": "catching"})
	if bool(alpha.call("camera_passes_through")):
		_fail("this peer's fight in its catching phase still lets the arm through")
	alpha.set("_encounter", {"phase": "resolving"})
	if bool(alpha.call("camera_passes_through")):
		_fail("this peer's fight in its resolving phase still lets the arm through")
	alpha.set("_local_fight", false)
	var manager := Node.new()
	manager.set_script(_fake("var fighting := true\nfunc is_fighting() -> bool:\n\treturn fighting\n"))
	alpha.set("_manager", manager)
	if bool(alpha.call("camera_passes_through")):
		_fail("another local fight still lets the arm through Aquaryn")
	manager.set("fighting", false)
	if not bool(alpha.call("camera_passes_through")):
		_fail("the arm stays blocked after the local fight ended")
	manager.free()
	alpha.free()

	# A GUEST's body, through its real physics tick: the guest branch returns
	# before any authority work, and must still follow its own fight state.
	var authority := Node.new()
	authority.set_script(_fake("var passes := true\nfunc camera_passes_through() -> bool:\n\treturn passes\n"
		+ "func is_alpha_authority() -> bool:\n\treturn false\n"))
	_world.add_child(authority)
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(ALPHA_BODY)
	body.set("authority_node", authority)
	_world.add_child(body)
	for i in 3:
		await physics_frame
	if not body.is_in_group(RIG.PASS_THROUGH_GROUP) or not bool(body.get("fades_when_camera_inside")):
		_fail("guest, no local fight: Aquaryn's body is not in the pass-through group with its fade on")
	authority.set("passes", false)
	for i in 3:
		await physics_frame
	if body.is_in_group(RIG.PASS_THROUGH_GROUP) or bool(body.get("fades_when_camera_inside")):
		_fail("guest in its own Aquaryn fight: the body still passes the camera arm or fades")
	else:
		print("aquaryn: passes and fades out of a fight only (host predicate and guest tick)")
	body.queue_free()
	authority.queue_free()
	await physics_frame


func _fake(source: String) -> GDScript:
	var script := GDScript.new()
	script.source_code = "extends Node\n" + source
	script.reload()
	return script


func _an_opted_in_body_fades_with_the_lens_inside() -> void:
	var camera := Camera3D.new()
	_world.add_child(camera)
	camera.current = true
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(CREATURE_BODY)
	_world.add_child(body)
	body.call("setup", "aquaryn", false)
	body.set("fades_when_camera_inside", true)
	for i in 5:
		await process_frame
	var model: Node3D = body.call("model_pivot")
	if model == null:
		_fail("aquaryn has no model to fade")
		return
	camera.global_position = body.global_position + Vector3(0.0, 1.5, 0.0)
	for i in 60:
		await process_frame
	var inside := _dithered(model)
	if inside.x == 0 or inside.y != inside.x:
		_fail("lens inside the body: %d of %d model surfaces dithered" % [inside.y, inside.x])
	else:
		print("inside: %d/%d model surfaces dithered" % [inside.y, inside.x])
	camera.global_position = body.global_position + Vector3(0.0, 4.0, 30.0)
	for i in 60:
		await process_frame
	if _dithered(model).y != 0:
		_fail("lens outside the body: surfaces still dithered")
	body.queue_free()
	camera.queue_free()


func _dithered(node: Node) -> Vector2i:
	var counts := Vector2i.ZERO
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var mesh := node as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface)
			if not (material is BaseMaterial3D):
				continue
			counts.x += 1
			if (material as BaseMaterial3D).distance_fade_mode == BaseMaterial3D.DISTANCE_FADE_OBJECT_DITHER:
				counts.y += 1
	for child in node.get_children():
		counts += _dithered(child)
	return counts


func _spawn_arm() -> SpringArm3D:
	var arm := SpringArm3D.new()
	arm.set_script(load(RIG_SCRIPT))
	_world.add_child(arm)
	arm.spring_length = ARM_LENGTH
	arm.global_position = Vector3.ZERO
	arm.global_rotation = Vector3.ZERO
	return arm


## A creature-sized solid straddling the arm's centre line (+Z) at 3 m.
func _spawn_blocker() -> CharacterBody3D:
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 3.0, 2.0)
	var shape := CollisionShape3D.new()
	shape.shape = box
	var body := CharacterBody3D.new()
	body.add_child(shape)
	_world.add_child(body)
	body.global_position = Vector3(0.0, 0.0, 3.0)
	return body


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report() -> void:
	if _failures.is_empty():
		print("smoke_camera_pass_through: OK")
		quit(0)
	else:
		for line in _failures:
			print("smoke_camera_pass_through FAIL: %s" % line)
		quit(1)
