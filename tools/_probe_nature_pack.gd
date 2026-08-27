extends SceneTree

## The `environment/nature` retest `ralph/BLOCKED.md` has been waiting for.
##
##   xvfb-run -a -s "-screen 0 1600x400x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1600x400 \
##     --script tools/_probe_nature_pack.gd
##
## `BLOCKED.md`'s BAND1-D1 entry writes the whole pack off: *"Each one carries
## materials with no albedo texture and a flat placeholder colour… The pack is
## authored against a palette atlas the glTF import does not apply."* Several
## `data/config/bands/*/props.json` entries route around it with `stylized_nature`
## replacements, citing *"renders with an untextured near-white placeholder
## material"*.
##
## `GF-B-010` turned up a DIFFERENT defect in the same pack — every one of its 27
## models also omits `metallicFactor`, so Godot imports each surface as a
## fully-rough metal and draws it black — and `imported_materials.gd` now
## corrects that on the `props.gd` path. The question this tool answers is
## whether that correction hands the pack back.
##
## Rendered through the REAL path: `props.gd`'s own load-and-instantiate,
## including its `make_dielectric()` call, under the environment `world_look.gd`
## builds from `art.json`'s `day` block. Nothing about the light or the material
## is typed here, so the answer is about the game rather than about a probe.
##
## A `stylized_nature` model stands at the end of the row as the control: that
## pack is what the bands were migrated TO, and it ships real textures.

const PROPS := preload("res://scripts/world/props.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const OUT := "res://shots/nature_pack"

## One model per distinct material in the pack, so every placeholder colour in
## it appears exactly once: `grass` (17 of the 27 models), `leafsGreen` (5),
## `woodBark` (9), `dirt` (5), `woodInner` (4), `_defaultMat` (3), and the three
## `color*` materials. Plus the control.
const ROW := [
	["res://assets/environment/nature/plant_bush.glb", "grass"],
	["res://assets/environment/nature/tree_oak.glb", "leafsGreen"],
	["res://assets/environment/nature/log_large.glb", "woodBark"],
	["res://assets/environment/nature/rock_largeA.glb", "dirt"],
	["res://assets/environment/nature/stump_round.glb", "woodInner"],
	["res://assets/environment/nature/mushroom_red.glb", "_defaultMat"],
	["res://assets/environment/nature/flower_redA.glb", "colorRed"],
	["res://assets/environment/stylized_nature/Bush_Common.gltf", "CONTROL"],
]

const SPACING := 2.6


func _init() -> void:
	_run()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		print("headless has no renderer; this tool only makes sense under xvfb-run")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))

	var world := Node3D.new()
	root.add_child(world)
	_build_environment(world)

	var x := -(ROW.size() - 1) * 0.5 * SPACING
	for entry: Array in ROW:
		var path := str(entry[0])
		if not ResourceLoader.exists(path):
			print("MISSING %s" % path)
			x += SPACING
			continue
		var packed: PackedScene = load(path) as PackedScene
		var node: Node3D = packed.instantiate() as Node3D
		# The one line `props.gd::place()` applies to every prop it loads.
		var fixed := PROPS.IMPORTED_MATERIALS.make_dielectric(node)
		node.position = Vector3(x, 0.0, 0.0)
		world.add_child(node)
		_report(path, str(entry[1]), node, fixed)
		x += SPACING

	var cam := Camera3D.new()
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 2.2, 12.0), Vector3(0.0, 0.8, 0.0), Vector3.UP)
	cam.current = true
	for i in 40:
		await process_frame
	get_root().get_texture().get_image().save_png("%s/row.png" % OUT)
	print("\nwrote %s/row.png" % OUT)
	quit(0)


## The colour each material actually draws with, after the metallic correction.
## `albedo_texture == null` is the claim `BLOCKED.md` makes about this pack, and
## it is the one that decides whether the pack is usable: a flat factor can be
## retinted by name, a wrong texture cannot.
func _report(path: String, material_name: String, node: Node, fixed: int) -> void:
	var found := false
	for surface: Array in _surfaces(node, []):
		var m: Variant = surface[1]
		if not m is BaseMaterial3D:
			continue
		found = true
		var base := m as BaseMaterial3D
		print("%-46s %-12s albedo=%s texture=%s metallic=%.2f (corrected %d)" % [
			path.get_file(), material_name, base.albedo_color,
			("none" if base.albedo_texture == null else base.albedo_texture.resource_path.get_file()),
			base.metallic, fixed])
	if not found:
		print("%-46s %-12s NO BaseMaterial3D" % [path.get_file(), material_name])


func _surfaces(node: Node, out: Array) -> Array:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		if instance.mesh != null:
			for surface in instance.mesh.get_surface_count():
				out.append([instance.name, instance.get_active_material(surface)])
	for child in node.get_children():
		_surfaces(child, out)
	return out


func _build_environment(world: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.shadow_enabled = true
	world.add_child(sun)
	var env_node := WorldEnvironment.new()
	env_node.name = "WorldEnvironment"
	env_node.environment = Environment.new()
	world.add_child(env_node)
	var look := Node.new()
	look.set_script(WORLD_LOOK)
	world.add_child(look)
	look.set("sun_path", look.get_path_to(sun))
	look.set("environment_path", look.get_path_to(env_node))
	look.call("_ready")
	look.call("apply_time", "day")
