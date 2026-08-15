extends SceneTree

## Real build-piece thumbnails, replacing the letter-chip placeholders in
## assets/ui/icons/buildables/. NO meadows world -- every buildable in
## data/items/buildables.json is either a plain glTF module (`mesh`) or one of
## the two hand-authored visuals (`camp`, `storage`), whose scripts
## (scripts/build/camp.gd, scripts/build/storage_container.gd) are read here
## for the exact same mesh paths rather than re-guessing them.
##
##   xvfb-run -a -s "-screen 0 512x512x24" \
##     ~/godot-bin/godot --rendering-driver opengl3 --path . \
##     --script tools/render_build_thumbnails.gd
##
## Then refresh imports so the new PNGs actually reload in-editor/at runtime:
##   ~/godot-bin/godot --headless --import

const BUILDABLES_JSON := "res://data/items/buildables.json"
const OUT_DIR := "res://assets/ui/icons/buildables"

# scripts/build/camp.gd -- BONFIRE constant, task brief says "for camp use the
# Bonfire mesh" (not the bedroll too; one representative piece per icon).
const CAMP_MESH := "res://assets/props/quaternius_survival/Bonfire_Fire.obj"
# scripts/build/storage_container.gd -- MESH_PATH constant.
const STORAGE_MESH := "res://assets/props/quaternius_fantasy/Crate_Wooden.gltf"

const RENDER_SIZE := 256
const OUTPUT_SIZE := 128
const SETTLE_FRAMES := 3

var _viewport: SubViewport = null
var _camera: Camera3D = null
var _model_root: Node3D = null


func _init() -> void:
	_run()


func _run() -> void:
	var written := 0
	var failed: Array[String] = []

	var buildables := _load_buildables()
	if buildables.is_empty():
		push_error("no buildables parsed from %s" % BUILDABLES_JSON)
		quit(1)
		return

	_build_rig()
	await process_frame

	for entry in buildables:
		var id: String = str(entry.get("id", ""))
		var mesh_path := _mesh_path_for(entry)
		if mesh_path.is_empty():
			failed.append("%s: no mesh path resolvable" % id)
			continue
		if not ResourceLoader.exists(mesh_path):
			failed.append("%s: mesh missing on disk (%s)" % [id, mesh_path])
			continue

		var aabb: Variant = _spawn_model(mesh_path)
		if aabb == null:
			failed.append("%s: could not build a mesh instance from %s" % [id, mesh_path])
			continue

		_frame_camera(aabb as AABB)
		for i in SETTLE_FRAMES:
			await process_frame
		await RenderingServer.frame_post_draw

		var image := _viewport.get_texture().get_image()
		_clear_model()
		if image == null:
			failed.append("%s: viewport returned no image" % id)
			continue

		image.resize(OUTPUT_SIZE, OUTPUT_SIZE, Image.INTERPOLATE_LANCZOS)
		var out_path := "%s/%s.png" % [OUT_DIR, id]
		var error := image.save_png(out_path)
		if error != OK:
			failed.append("%s: save_png failed (%d)" % [id, error])
			continue
		written += 1
		print("  %-12s -> %s  (from %s)" % [id, out_path, mesh_path])

	print("")
	print("%d/%d thumbnails written -> %s" % [written, buildables.size(), OUT_DIR])
	if not failed.is_empty():
		print("")
		for line in failed:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)


# --- rig ---------------------------------------------------------------------


func _build_rig() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(RENDER_SIZE, RENDER_SIZE)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Own World3D so this never depends on (or pollutes) anything the main
	# scene tree might otherwise add.
	_viewport.world_3d = World3D.new()
	root.add_child(_viewport)

	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.30, 0.28, 0.26)
	env.ambient_light_energy = 1.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	_viewport.add_child(world_env)

	# Key light, warm and angled -- the same 3/4-lit-from-above read every
	# other icon set in this project's HUD uses.
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	key.light_energy = 1.15
	key.light_color = Color(1.0, 0.96, 0.88)
	_viewport.add_child(key)

	# Cool fill from the opposite side so the shadowed half of the piece
	# still reads instead of going flat black.
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25.0, 145.0, 0.0)
	fill.light_energy = 0.35
	fill.light_color = Color(0.75, 0.82, 1.0)
	_viewport.add_child(fill)

	_camera = Camera3D.new()
	_camera.fov = 35.0
	_viewport.add_child(_camera)

	_model_root = Node3D.new()
	_viewport.add_child(_model_root)


func _clear_model() -> void:
	for child in _model_root.get_children():
		child.queue_free()


## Spawns `mesh_path` under `_model_root` and returns its combined world AABB,
## or null if the resource produced no mesh instances at all.
func _spawn_model(mesh_path: String) -> Variant:
	for child in _model_root.get_children():
		_model_root.remove_child(child)
		child.queue_free()

	var node: Node3D = null
	# OF24: `.tscn` joins `.gltf`/`.glb` here -- the torch's own `mesh` entry
	# is a hand-authored scene (assets/props/built/torch_prop.tscn) wrapping a
	# script-built prop (scripts/world/torch_prop.gd), not a vendored file,
	# but it is still a `PackedScene` that has to be instantiated the same way.
	if mesh_path.ends_with(".gltf") or mesh_path.ends_with(".glb") or mesh_path.ends_with(".tscn"):
		var scene: PackedScene = load(mesh_path)
		if scene == null:
			return null
		node = scene.instantiate() as Node3D
	else:
		# .obj (and any other bare-mesh resource) loads directly as a Mesh,
		# the same way scripts/build/camp.gd's `_mesh()` helper uses it.
		var mesh: Mesh = load(mesh_path)
		if mesh == null:
			return null
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		node = mesh_instance
	if node == null:
		return null
	_model_root.add_child(node)

	var combined := AABB()
	var first := true
	for mesh_instance in _mesh_instances(node):
		var local_aabb: AABB = mesh_instance.mesh.get_aabb()
		var world_aabb: AABB = mesh_instance.global_transform * local_aabb
		combined = world_aabb if first else combined.merge(world_aabb)
		first = false
	if first:
		return null
	return combined


func _mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		found.append(node as MeshInstance3D)
	for child in node.get_children():
		found.append_array(_mesh_instances(child))
	return found


## 3/4 view, slight down angle, framed to the piece's own AABB so a fence
## rail and a floor panel both fill the frame instead of one swimming in
## empty space.
func _frame_camera(aabb: AABB) -> void:
	var center := aabb.get_center()
	var radius := maxf(aabb.size.length() * 0.5, 0.05)
	var direction := Vector3(1.0, 0.62, 1.0).normalized()
	# fov=35 -> distance so the bounding sphere fills most of the frame with
	# a little margin.
	var distance := radius / sin(deg_to_rad(_camera.fov) * 0.5) * 1.25
	_camera.global_position = center + direction * distance
	_camera.look_at(center, Vector3.UP)


# --- data ----------------------------------------------------------------


func _load_buildables() -> Array:
	var text := FileAccess.get_file_as_string(BUILDABLES_JSON)
	if text.is_empty():
		return []
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return []
	var list: Variant = (parsed as Dictionary).get("buildables", [])
	if typeof(list) != TYPE_ARRAY:
		return []
	return list as Array


func _mesh_path_for(entry: Dictionary) -> String:
	var id := str(entry.get("id", ""))
	if id == "camp":
		return CAMP_MESH
	if id == "storage":
		return STORAGE_MESH
	return str(entry.get("mesh", ""))
