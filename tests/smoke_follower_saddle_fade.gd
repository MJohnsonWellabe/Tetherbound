extends SceneTree

## F39#0 GPU pass, P2-109: after dismounting Aquaryn the camera sat inside the
## mount, the body dithered out as designed, and its saddle stayed opaque at
## screen centre, floating in the air. The saddle hangs off the body, not the
## model, so the follower's camera fade has to cover it too.
##
##   godot --headless --path . --script tests/smoke_follower_saddle_fade.gd
##
## A real follower body (creature.tscn + follower_creature.gd, the encounter
## director's own recipe) wears the real saddle through the riding
## controller's own attach; the camera is put inside the body, frames run, and
## every saddle surface must carry the dithered fade copy. Then the camera
## leaves and every saddle surface must be handed back.

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const FOLLOWER := preload("res://scripts/creatures/follower_creature.gd")
const RIDING := preload("res://scripts/world/riding_controller.gd")
const SPECIES_ID := "aquaryn"

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(FOLLOWER)
	world.add_child(body)
	body.call("setup", SPECIES_ID, false)
	for i in 5:
		await process_frame
	RIDING._attach_saddle(body, SPECIES_ID)
	var saddle := body.get_node_or_null(^"RideSaddle")
	if saddle == null:
		_fail("the saddle did not attach to %s" % SPECIES_ID)
		_report()
		return

	camera.global_position = body.global_position + Vector3(0.0, 1.5, 0.0)
	for i in 60:
		await process_frame
	var faded := _surfaces(saddle)
	if faded.x == 0:
		_fail("the saddle has no material surfaces to check")
	elif faded.y != faded.x:
		_fail("camera inside the mount: %d of %d saddle surfaces faded" % [faded.y, faded.x])
	else:
		print("inside: %d/%d saddle surfaces dithered" % [faded.y, faded.x])

	camera.global_position = body.global_position + Vector3(0.0, 4.0, 30.0)
	for i in 60:
		await process_frame
	var after := _surfaces(saddle)
	if after.y != 0:
		_fail("camera clear of the mount: %d saddle surfaces still dithered" % after.y)
	else:
		print("outside: saddle opaque again")
	_report()


## (surfaces, surfaces showing an object-dither fade)
func _surfaces(node: Node) -> Vector2i:
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
		counts += _surfaces(child)
	return counts


func _fail(message: String) -> void:
	_failures.append(message)
	push_error(message)


func _report() -> void:
	if _failures.is_empty():
		print("smoke_follower_saddle_fade: OK")
		quit(0)
	else:
		print("smoke_follower_saddle_fade: FAILED %d" % _failures.size())
		quit(1)
