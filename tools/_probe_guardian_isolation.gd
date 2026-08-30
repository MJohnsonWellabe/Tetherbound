extends SceneTree

## T3-ACTIVITIES / JUDGE-3 sec1e: the Warrens Guardian reads as "a near-black
## lump" at player distance in the den. Before touching anything, answer the
## two questions the fix depends on, in isolation:
##
##   1. Does the alpha colourway swap actually APPLY on burrowback? The swap
##      resolves texture siblings off the source material's albedo
##      `resource_path` (creature_body.gd::_texture_for), and burrowback's
##      textures are EMBEDDED in the glb -- if the path fallback misses, the
##      "heavier-stone-plates repaint" never reaches the render and the rim is
##      dressing a stock dark body.
##   2. Is burrowback actually self-lit? creature_body.gd's rim-not-albedo
##      reasoning rests on "the painted albedo is wired into the emission
##      slot" -- but this glb's embedded emissive image measures pure black,
##      so scene light may be ALL this species has, which changes which lever
##      can work in a dim den.
##
## Renders an ordinary and an alpha burrowback against a neutral mid-grey
## stage, lit and unlit, and prints the material facts either way.
##
##   xvfb-run -a -s "-screen 0 900x700x24" godot --path . \
##     --rendering-driver opengl3 --resolution 900x700 \
##     --script tools/_probe_guardian_isolation.gd -- <out_dir>

const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const BODY := preload("res://scripts/creatures/creature_body.gd")

var _world: Node3D
var _key: DirectionalLight3D
var _fill: OmniLight3D


func _init() -> void:
	_run()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir := args[0] if args.size() > 0 else "res://shots/guardian_isolation"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	_world = Node3D.new()
	root.add_child(_world)

	# Neutral stage: mid-grey backdrop and floor, no sky, flat ambient off, so
	# the only light in the frame is the light this file placed and emission.
	var env_holder := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.35, 0.35)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.5)
	env.ambient_light_energy = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env_holder.environment = env
	_world.add_child(env_holder)

	var backdrop := MeshInstance3D.new()
	var wall := PlaneMesh.new()
	wall.size = Vector2(30.0, 16.0)
	backdrop.mesh = wall
	backdrop.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	backdrop.position = Vector3(0.0, 4.0, -5.0)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.42, 0.40, 0.38)
	wall_mat.roughness = 1.0
	backdrop.material_override = wall_mat
	_world.add_child(backdrop)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30.0, 30.0)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.36, 0.33, 0.30)
	floor_mat.roughness = 1.0
	floor_mesh.material_override = floor_mat
	_world.add_child(floor_mesh)

	_key = DirectionalLight3D.new()
	_key.light_energy = 1.1
	_key.rotation_degrees = Vector3(-42.0, 30.0, 0.0)
	_world.add_child(_key)
	_fill = OmniLight3D.new()
	_fill.light_energy = 0.6
	_fill.omni_range = 14.0
	_fill.position = Vector3(-3.0, 2.5, 4.0)
	_world.add_child(_fill)

	var camera := Camera3D.new()
	camera.fov = 45.0
	_world.add_child(camera)
	camera.make_current()

	for i in 30:
		await process_frame

	var ordinary := _spawn("burrowback", false, Vector3(-2.0, 0.0, 0.0))
	var alpha := _spawn("burrowback", true, Vector3(2.0, 0.0, 0.0))
	for i in 10:
		await process_frame

	print("=== ordinary burrowback ===")
	_print_materials(ordinary.get_node(^"Model"))
	print("=== alpha (guardian-dressed) burrowback ===")
	_print_materials(alpha.get_node(^"Model"))

	camera.position = Vector3(0.0, 1.6, 7.5)
	camera.look_at(Vector3(0.0, 1.0, 0.0), Vector3.UP)
	await _shoot("%s/01-pair-lit.png" % out_dir)

	_key.visible = false
	_fill.visible = false
	env.ambient_light_energy = 0.0
	await _shoot("%s/02-pair-unlit-emission-only.png" % out_dir)

	_key.visible = true
	_fill.visible = true
	env.ambient_light_energy = 0.35
	camera.position = Vector3(2.0, 1.7, 5.2)
	camera.look_at(alpha.global_position + Vector3(0.0, 1.0, 0.0), Vector3.UP)
	await _shoot("%s/03-alpha-close.png" % out_dir)
	quit(0)


func _spawn(id: String, as_alpha: bool, at: Vector3) -> Node3D:
	var body: Node3D = CREATURE_SCENE.instantiate()
	body.set_script(BODY)
	_world.add_child(body)
	if as_alpha:
		body.set("body_scale", 1.35)
	body.call("setup", id, false)
	if as_alpha:
		body.call("set_alpha", true)
	body.global_position = at
	body.rotation.y = deg_to_rad(35.0)
	body.set_physics_process(false)
	return body


func _print_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		var mesh: Mesh = instance.mesh
		for surface in (mesh.get_surface_count() if mesh != null else 0):
			var mat := instance.get_active_material(surface) as BaseMaterial3D
			if mat == null:
				continue
			var albedo_path: String = mat.albedo_texture.resource_path if mat.albedo_texture != null else "<none>"
			var emission_path: String = mat.emission_texture.resource_path if mat.emission_texture != null else "<none>"
			print("  surface %d '%s'" % [surface, mat.resource_name])
			print("    albedo_tex=%s" % albedo_path)
			print("    emission_enabled=%s emission=%s energy=%.2f emission_tex=%s" % [
				mat.emission_enabled, mat.emission, mat.emission_energy_multiplier, emission_path])
			print("    rim_enabled=%s rim=%.2f rim_tint=%.2f" % [mat.rim_enabled, mat.rim, mat.rim_tint])
	for child in node.get_children():
		_print_materials(child)


func _shoot(path: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image != null:
		image.save_png(path)
		print("wrote %s" % path)
