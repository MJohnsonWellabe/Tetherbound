extends SceneTree

## Render two named species side by side, close and large, for a blind
## silhouette/palette comparison. `preview_creatures.gd` puts all seventeen
## species in one 1280px row -- about fifty pixels each, too small to judge
## colour or tell two similar creatures apart (SA6's own note). This is the
## same rig at a tighter frame for exactly two.
##
##   xvfb-run -a -s "-screen 0 1600x900x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1600x900 \
##     --script tools/capture_species_closeup.gd -- burrowback terrapup
##
## Species ids come from argv after `--`; defaults to burrowback/terrapup
## (SA5's own pair) if none are given. Writes both a colour turntable-style
## pair and a black silhouette pair, since SA5's done-when asks the critic to
## judge the pair "side by side, told nothing" -- silhouette rules out shape
## alone answering the question for palette work.

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const BODY := preload("res://scripts/pals/pal_body.gd")
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")

const TRAINER_HEIGHT := 1.8


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame

	var ids := _species_from_argv()

	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.20, 0.22, 0.24)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.82)
	e.ambient_light_energy = 1.5
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-35.0), deg_to_rad(-35.0), 0.0)
	key.light_energy = 1.6
	world.add_child(key)

	var spacing := 2.6
	var x := -spacing * (ids.size() - 1) * 0.5
	var bodies: Array = []
	for id: String in ids:
		var body: Node3D = PAL_SCENE.instantiate()
		body.name = "Closeup_%s" % id
		body.set_script(BODY)
		world.add_child(body)
		body.call("setup", id)
		body.global_position = Vector3(x, 0.0, 0.0)
		body.set_physics_process(false)
		bodies.append(body)

		var ruler := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(0.05, TRAINER_HEIGHT, 0.05)
		ruler.mesh = bar
		var grey := StandardMaterial3D.new()
		grey.albedo_color = Color(0.45, 0.47, 0.5)
		ruler.material_override = grey
		world.add_child(ruler)
		ruler.global_position = Vector3(x - 0.9, TRAINER_HEIGHT * 0.5, -0.5)
		x += spacing

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.33, 0.30)
	floor_mesh.material_override = mat
	world.add_child(floor_mesh)

	var camera := Camera3D.new()
	camera.fov = 32.0
	world.add_child(camera)
	camera.make_current()

	for i in 120:
		await physics_frame
	# 0.72 (SA5's original two-species framing) crops the outer creatures once
	# more than two stand in the row -- the row's width grows with ids.size()
	# but that multiplier didn't. 1.65 keeps the full row in frame up to five.
	camera.global_position = Vector3(0.0, 1.1, spacing * ids.size() * 1.65 + 1.4)
	camera.look_at(Vector3(0.0, 0.75, 0.0), Vector3.UP)

	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw

	var colour_image := root.get_texture().get_image()
	if colour_image == null:
		print("no image")
		quit(1)
		return
	var out_name := "_".join(ids)
	var colour_path := "res://shots/closeup_%s.png" % out_name
	colour_image.save_png(colour_path)
	print("wrote %s" % colour_path)

	# Silhouette pass: same rig, everything unshaded black against a pale
	# card, so shape alone can be judged with palette taken out of the
	# picture entirely.
	for id_index in bodies.size():
		_blacken(bodies[id_index])
	env.environment.background_color = Color(0.85, 0.86, 0.87)
	env.environment.ambient_light_energy = 0.0
	key.light_energy = 0.0
	floor_mesh.material_override.albedo_color = Color(0.85, 0.86, 0.87)

	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw

	var silhouette_image := root.get_texture().get_image()
	var silhouette_path := "res://shots/closeup_%s_silhouette.png" % out_name
	silhouette_image.save_png(silhouette_path)
	print("wrote %s" % silhouette_path)

	quit(0)


func _species_from_argv() -> Array:
	var argv := OS.get_cmdline_user_args()
	if argv.is_empty():
		return ["burrowback", "terrapup"]
	return argv


func _blacken(node: Node) -> void:
	if node is MeshInstance3D:
		var black := StandardMaterial3D.new()
		black.albedo_color = Color(0.02, 0.02, 0.02)
		black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		node.material_override = black
	for child in node.get_children():
		_blacken(child)
