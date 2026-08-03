extends SceneTree

## Does the impact burst render at all?
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/diagnose_flash.gd
##
## Three attempts at making it appear in a survey frame have failed — the render
## clock, the culling bounds, and the parent node were each a plausible cause and
## none of them was it. So: a bare scene, a camera pointed at a known spot, a
## burst spawned at that spot, and a shot on each of the first few physics
## frames. Either it is there or the burst is not drawing, and that is a much
## smaller question than the one the combat survey asks.

const FLASH := preload("res://scripts/combat/impact_flash.gd")
const OUT_DIR := "res://shots/_diag"

var _camera: Camera3D = null
var _root: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	_root = Node3D.new()
	root.add_child(_root)

	# Something to see it against, so "nothing rendered at all" and "the burst
	# did not render" are distinguishable.
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	ground.mesh = plane
	var dirt := StandardMaterial3D.new()
	dirt.albedo_color = Color(0.25, 0.32, 0.18)
	ground.material_override = dirt
	_root.add_child(ground)

	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(deg_to_rad(-50.0), deg_to_rad(-40.0), 0.0)
	_root.add_child(sun)

	_camera = Camera3D.new()
	_camera.fov = 70.0
	_root.add_child(_camera)
	_camera.global_position = Vector3(0.0, 2.0, 6.0)
	_camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	_camera.make_current()

	for i in 10:
		await physics_frame
	await _shoot("flash-00-before")

	# Control: a plain opaque sphere at the same spot, added the same way. If
	# this renders and the burst does not, the fault is in the burst's material;
	# if neither renders, it is in how the node is being added.
	var control := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 0.4
	ball.height = 0.8
	control.mesh = ball
	var flat := StandardMaterial3D.new()
	flat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flat.albedo_color = Color("#ff8800")
	control.material_override = flat
	_root.add_child(control)
	control.global_position = Vector3(-1.2, 1.0, 0.0)

	var burst: Node3D = FLASH.burst(_root, Vector3(0.0, 1.0, 0.0), Color("#ffd27a"), 0.85, 0.26, 1.0)
	print("  burst is %s, inside tree: %s" % [
		"null" if burst == null else str(burst), "n/a" if burst == null else str(burst.is_inside_tree())
	])
	if burst != null:
		print("  children: %d, position %s" % [burst.get_child_count(), str(burst.global_position)])

	# Stop the clock before composing each shot.
	#
	# This is what made the burst "invisible" through four wrong diagnoses. Under
	# software rendering a single frame takes an appreciable fraction of a
	# second of REAL time, physics keeps ticking throughout, and a 0.26-second
	# effect is long dead by the time the shutter opens. Nothing was wrong with
	# the effect; the camera was just slower than the thing it was photographing.
	for shot in 4:
		for i in 3:
			await physics_frame
		paused = true
		if is_instance_valid(burst):
			for child in burst.get_children():
				var m := child as MeshInstance3D
				print("    child %s visible_in_tree=%s pos=%s surfaces=%s aabb=%s" % [
					m.name, str(m.is_visible_in_tree()), str(m.global_position),
					"n/a" if m.mesh == null else str(m.mesh.get_surface_count()),
					str(m.get_aabb())
				])
		else:
			print("    burst was already freed")
		await _shoot("flash-%02d-after" % (shot + 1))
		paused = false

	quit(0)


func _shoot(name: String) -> void:
	for i in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("  %-20s no image" % name)
		return
	image.save_png("%s/%s.png" % [OUT_DIR, name])

	# Count warm pixels the way tools/frame_stats.py does, so the number here and
	# the number the critic quotes mean the same thing.
	var warm := 0
	for y in range(0, image.get_height(), 2):
		for x in range(0, image.get_width(), 2):
			var c := image.get_pixel(x, y)
			if c.s > 0.4 and c.v > 0.6 and (c.h * 360.0) > 10.0 and (c.h * 360.0) < 70.0:
				warm += 1
	print("  %-20s warm pixels: %d" % [name, warm])
