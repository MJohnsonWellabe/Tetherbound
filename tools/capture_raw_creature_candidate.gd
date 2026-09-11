extends SceneTree

## Renders a raw, unimported Meshy GLB from four fixed angles so creature
## candidates can be accepted or rejected before refinement or installation.
##
## Usage:
##   godot --path . --rendering-method gl_compatibility --resolution 900x700 \
##     --script tools/capture_raw_creature_candidate.gd -- skyrill/preview_a

const OUT_ROOT := "res://shots/raw_creature_candidates"
const VIEW_DIRECTIONS := {
	"front_three_quarter": Vector3(1.0, 0.45, 1.0),
	"side": Vector3(1.0, 0.30, 0.0),
	"rear_three_quarter": Vector3(1.0, 0.45, -1.0),
	"front": Vector3(0.0, 0.30, 1.0),
}


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or ".." in args[0]:
		push_error("expected one safe candidate path, e.g. skyrill/preview_a")
		quit(2)
		return

	var candidate: String = args[0]
	var model_path := ProjectSettings.globalize_path("res://assets_raw/%s/model.glb" % candidate)
	if not FileAccess.file_exists(model_path):
		push_error("candidate model is missing: %s" % model_path)
		quit(3)
		return

	var gltf := GLTFDocument.new()
	var state := GLTFState.new()
	var err := gltf.append_from_file(model_path, state)
	if err != OK:
		push_error("candidate GLB failed to load (%d): %s" % [err, model_path])
		quit(4)
		return
	var creature: Node3D = gltf.generate_scene(state)
	if creature == null:
		push_error("candidate GLB generated no scene: %s" % model_path)
		quit(5)
		return

	var world := Node3D.new()
	root.add_child(world)
	world.add_child(creature)

	var initial_aabb := _combined_aabb(creature)
	creature.position = Vector3(
		-(initial_aabb.position.x + initial_aabb.size.x * 0.5),
		-initial_aabb.position.y,
		-(initial_aabb.position.z + initial_aabb.size.z * 0.5)
	)
	var aabb := _combined_aabb(creature)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.075, 0.09, 0.12)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.68, 0.72, 0.82)
	env.ambient_light_energy = 1.0
	env_node.environment = env
	world.add_child(env_node)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	key.light_energy = 1.45
	key.shadow_enabled = true
	world.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, 145.0, 0.0)
	fill.light_energy = 0.55
	fill.light_color = Color(0.68, 0.79, 1.0)
	world.add_child(fill)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	var ground_extent: float = maxf(6.0, maxf(aabb.size.x, aabb.size.z) * 2.2)
	plane.size = Vector2(ground_extent, ground_extent)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.18, 0.21, 0.20)
	ground_mat.roughness = 0.92
	plane.material = ground_mat
	ground.mesh = plane
	world.add_child(ground)

	var camera := Camera3D.new()
	camera.fov = 38.0
	world.add_child(camera)
	camera.make_current()

	var out_dir := "%s/%s" % [OUT_ROOT, candidate.replace("/", "-")]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var centre := aabb.position + aabb.size * 0.5
	var radius: float = maxf(aabb.size.length() * 0.5, 0.5)

	for i in 30:
		await process_frame

	for view_name: String in VIEW_DIRECTIONS:
		var direction: Vector3 = VIEW_DIRECTIONS[view_name].normalized()
		camera.global_position = centre + direction * (radius * 2.7 + 0.5)
		camera.look_at(centre, Vector3.UP)
		for i in 8:
			await process_frame
		await RenderingServer.frame_post_draw
		var out_path := "%s/%s.png" % [out_dir, view_name]
		root.get_texture().get_image().save_png(out_path)
		print("wrote %s" % out_path)

	print("candidate=%s aabb_position=(%.3f,%.3f,%.3f) aabb_size=(%.3f,%.3f,%.3f)" % [
		candidate,
		aabb.position.x, aabb.position.y, aabb.position.z,
		aabb.size.x, aabb.size.y, aabb.size.z,
	])
	quit(0)


func _combined_aabb(node: Node3D) -> AABB:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes(node, meshes)
	if meshes.is_empty():
		return AABB(Vector3.ZERO, Vector3.ONE)
	var first := meshes[0]
	var combined := first.global_transform * first.get_aabb()
	for i in range(1, meshes.size()):
		var mesh_instance := meshes[i]
		combined = combined.merge(mesh_instance.global_transform * mesh_instance.get_aabb())
	return combined


func _collect_meshes(node: Node, into: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		into.append(node as MeshInstance3D)
	for child in node.get_children():
		_collect_meshes(child, into)
