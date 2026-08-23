extends SceneTree

## Quick look at Meshy camp-set candidates/results, a lighter substitute for
## the full Blender turntable pipeline: one lit render per model from a fixed
## 3/4 angle. Entries prefixed `__tracked__` load from the committed
## assets/props/generated_camp/ tree; anything else is read from
## assets_raw/<species>/<candidate>/model.glb, which needs its own fetch
## first (tools/art_pipeline/meshy.py). Used during BAND1-D1's owner-directed
## camp-set generation to pick winners and re-check the wired-in result;
## re-run and edit CANDIDATES below for the next asset that needs the same
## quick look.
##
##   xvfb-run -a -s "-screen 0 900x700x24" godot --path . \
##     --rendering-driver opengl3 --resolution 900x700 \
##     --script tools/_capture_camp_candidates.gd

const OUT_DIR := "res://shots/camp_candidates"
const CANDIDATES := [
	"__tracked__camp_tent", "__tracked__camp_bed", "__tracked__campfire_stone_ring",
]


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var world := Node3D.new()
	root.add_child(world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.11, 0.12, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.9
	env_node.environment = env
	world.add_child(env_node)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45.0, -35.0, 0.0)
	key.light_energy = 1.3
	world.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20.0, 145.0, 0.0)
	fill.light_energy = 0.5
	fill.light_color = Color(0.75, 0.8, 1.0)
	world.add_child(fill)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(6.0, 6.0)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.2, 0.22, 0.19)
	ground.mesh = plane
	ground.material_override = gmat
	world.add_child(ground)

	var camera := Camera3D.new()
	camera.fov = 45.0
	world.add_child(camera)
	camera.make_current()

	# Warm-up: the FIRST candidate in every run of this script rendered as a
	# flat dark wedge with nothing in frame, every time, regardless of which
	# model was actually first -- a camera/viewport race on the very first
	# frames after camera.make_current(), not a per-model problem. A few
	# settle frames before the loop starts, once, fixes it for all candidates
	# rather than needing extra frames inside the loop on every iteration.
	for i in 30:
		await process_frame

	for rel in CANDIDATES:
		var abs_path: String
		if rel.begins_with("__tracked__"):
			abs_path = ProjectSettings.globalize_path("res://assets/props/generated_camp/%s.glb" % rel.replace("__tracked__", ""))
		else:
			abs_path = ProjectSettings.globalize_path("res://assets_raw/%s/model.glb" % rel)
		if not FileAccess.file_exists(abs_path):
			push_warning("missing: %s" % abs_path)
			continue
		# assets_raw/ carries a deliberate .gdignore (tools/art_pipeline/
		# README.md: the Blender half of this pipeline reads raw GLBs
		# directly and Godot import is never meant to see them until a
		# winner is chosen and copied under assets/). So this loads the file
		# at RUNTIME with GLTFDocument instead of `load()`, which needs an
		# editor import pass that will never happen for this directory.
		var gltf := GLTFDocument.new()
		var state := GLTFState.new()
		var err := gltf.append_from_file(abs_path, state)
		if err != OK:
			push_warning("gltf load failed (%d): %s" % [err, abs_path])
			continue
		var node: Node3D = gltf.generate_scene(state)
		if node == null:
			push_warning("gltf generated no scene: %s" % abs_path)
			continue
		world.add_child(node)

		var aabb := _combined_aabb(node)
		var centre: Vector3 = aabb.position + aabb.size * 0.5
		var radius: float = aabb.size.length() * 0.5
		var eye := centre + Vector3(1.0, 0.65, 1.0).normalized() * (radius * 2.6 + 0.5)
		camera.global_position = eye
		camera.look_at(centre, Vector3.UP)

		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		var out_name: String = rel.replace("/", "-")
		var out_path := "%s/%s.png" % [OUT_DIR, out_name]
		image.save_png(out_path)
		print("wrote %s  (aabb size=%.2f,%.2f,%.2f)" % [out_path, aabb.size.x, aabb.size.y, aabb.size.z])

		world.remove_child(node)
		node.queue_free()

	quit(0)


func _combined_aabb(node: Node3D) -> AABB:
	var meshes: Array = []
	_collect(node, meshes)
	if meshes.is_empty():
		return AABB()
	var aabb: AABB = (meshes[0] as MeshInstance3D).global_transform * (meshes[0] as MeshInstance3D).get_aabb()
	for i in range(1, meshes.size()):
		var mi := meshes[i] as MeshInstance3D
		aabb = aabb.merge(mi.global_transform * mi.get_aabb())
	return aabb


func _collect(node: Node, into: Array) -> void:
	if node is MeshInstance3D:
		into.append(node)
	for c in node.get_children():
		_collect(c, into)
