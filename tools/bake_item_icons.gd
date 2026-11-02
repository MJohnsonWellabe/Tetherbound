extends SceneTree

## P2-095: bake craft-panel item icons from installed meshes.
##
##   xvfb-run godot --path . --rendering-driver opengl3 --rendering-method gl_compatibility \
##       --script res://tools/bake_item_icons.gd [-- --only=axe,wood]
##
## Reads data/config/craft_item_icons.json. For each listed item: the entry's
## `mesh`, else the item's own world_model/held_model from items.json, framed to
## its bounds in a transparent SubViewport with a key/fill/rim light, written to
## output_dir/<id>.png. A tint replaces albedo (shape and shading kept) where
## several items share one mesh. Missing meshes are reported and skipped: the
## panel then keeps that item's existing icon.

const CONFIG := "res://data/config/craft_item_icons.json"
const ITEMS := "res://data/items/items.json"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	var items_doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(ITEMS))
	var defs: Variant = items_doc.get("items", items_doc) if items_doc is Dictionary else {}
	var only: Array[String] = []
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			for id: String in arg.trim_prefix("--only=").split(",", false):
				only.append(id)
	var size := int(cfg.get("size_px", 192))
	var out_dir := str(cfg.get("output_dir", "res://assets/ui/icons/items_rendered"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(size, size)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.76, 0.82)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = environment
	viewport.add_child(env)
	for spec: Array in [[Vector3(-40, -35, 0), 1.25, Color(1.0, 0.95, 0.86)],
			[Vector3(-15, 140, 0), 0.45, Color(0.75, 0.85, 1.0)],
			[Vector3(-10, 200, 0), 0.7, Color(0.85, 0.95, 1.0)]]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = spec[0]
		light.light_energy = spec[1]
		light.light_color = spec[2]
		viewport.add_child(light)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.current = true
	var holder := Node3D.new()
	viewport.add_child(holder)
	var made := 0
	var entries: Dictionary = cfg.get("items", {})
	for id: String in entries:
		if not only.is_empty() and id not in only:
			continue
		var entry: Dictionary = entries[id]
		var def: Dictionary = {}
		if defs is Dictionary and (defs as Dictionary).get(id) is Dictionary:
			def = defs[id]
		var mesh_path := str(entry.get("mesh", def.get("world_model", def.get("held_model", ""))))
		if mesh_path.is_empty() or not ResourceLoader.exists(mesh_path):
			print("ICON SKIP %s: no installed mesh (%s)" % [id, mesh_path])
			continue
		var model := _instance(mesh_path)
		if model == null:
			print("ICON SKIP %s: could not instance %s" % [id, mesh_path])
			continue
		for child in holder.get_children():
			child.free()
		var view: Dictionary = (cfg.get("default_view", {}) as Dictionary).duplicate()
		view.merge(entry.get("view", {}), true)
		var pivot := Node3D.new()
		holder.add_child(pivot)
		pivot.add_child(model)
		if entry.has("tint"):
			_tint(model, Color(str(entry.tint)), float(entry.get("metallic", 0.0)))
		pivot.rotation_degrees = Vector3(0.0, float(view.get("yaw_deg", 35.0)), float(view.get("roll_deg", 0.0)))
		var box := _bounds(pivot)
		if box.size.length() < 0.0001:
			print("ICON SKIP %s: empty bounds" % id)
			continue
		var centre := box.get_center()
		var radius := box.size.length() * 0.5
		var fov := float(view.get("fov_deg", 28.0))
		camera.fov = fov
		var distance := radius / tan(deg_to_rad(fov) * 0.5) / float(view.get("fill", 0.84))
		var pitch := deg_to_rad(float(view.get("pitch_deg", -22.0)))
		var dir := Vector3(0.0, -sin(pitch), cos(pitch))
		camera.near = maxf(0.001, distance - radius * 2.0)
		camera.far = distance + radius * 4.0
		camera.look_at_from_position(centre + dir * distance, centre, Vector3.UP)
		for _frame in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := _trimmed(viewport.get_texture().get_image(), float(cfg.get("trim_pad", 0.06)))
		var path := "%s/%s.png" % [out_dir, id]
		if image == null or image.is_empty() or image.save_png(ProjectSettings.globalize_path(path)) != OK:
			print("ICON FAIL %s" % id)
			continue
		made += 1
		print("ICON %s <- %s" % [id, mesh_path])
	print("ICONS BAKED %d" % made)
	quit(0)


## Crop to the drawn object (alpha bounds), square it with a small pad and
## scale back to the bake size, so a thin tool fills its slot like a round orb.
func _trimmed(image: Image, pad: float) -> Image:
	if image == null or image.is_empty():
		return image
	image.convert(Image.FORMAT_RGBA8)
	var size := image.get_width()
	var used := image.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return image
	var side := int(ceil(maxf(used.size.x, used.size.y) * (1.0 + pad * 2.0)))
	var square := Image.create(side, side, false, Image.FORMAT_RGBA8)
	square.fill(Color(0, 0, 0, 0))
	var at := Vector2i((side - used.size.x) / 2, (side - used.size.y) / 2)
	square.blit_rect(image, used, at)
	square.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return square


func _instance(path: String) -> Node3D:
	var res: Resource = load(path)
	if res is PackedScene:
		return (res as PackedScene).instantiate() as Node3D
	if res is Mesh:
		var mi := MeshInstance3D.new()
		mi.mesh = res
		return mi
	return null


func _tint(node: Node, colour: Color, metallic: float) -> void:
	if node is MeshInstance3D:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colour
		mat.roughness = 0.55
		mat.metallic = metallic
		(node as MeshInstance3D).material_override = mat
	for child in node.get_children():
		_tint(child, colour, metallic)


func _bounds(node: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi: Node in node.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var b := m.global_transform * m.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
