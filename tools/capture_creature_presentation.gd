extends SceneTree

## CREATURE-PRESENTATION. Two frames per species, on GRASS, under the meadow's
## own light: a portrait that answers "can you find its face" and a field shot
## that answers "does it separate from the ground it stands on".
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_creature_presentation.gd -- [--out DIR] [species...]
##
## Why not `preview_creatures.gd` or `capture_roster_ordinary.gd`: both stand
## the roster on a NEUTRAL GREY card. That is the right rig for judging a
## colourway against itself and the wrong one for judging it against the world
## -- a mint-green rabbit reads perfectly well on grey and disappears on the
## meadow, which is exactly the defect that reached the owner's screen
## (`shots/band3/09-wild-cluster-on-the-road.png`). The ground here is keyed to
## the grass those frames actually measure (hue ~140, value ~0.30 lit), so a
## creature that vanishes in the game vanishes here too.
##
## The field shot is rendered at gameplay distance and is meant to be looked at
## SMALL: `tools/thumbnail_sheet.py` scales it to 30%, which is the size a wild
## creature occupies when the player decides whether to walk toward it.

const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")

## The trainer, drawn as a reference bar. Presence is a comparison, not a number.
const TRAINER_HEIGHT := 1.8

## Sampled from `shots/band3/09-wild-cluster-on-the-road.png` and divided back
## out of the sun/ambient this rig applies, so the rendered ground here lands
## on the same value and hue the shipped frames measure rather than on
## palette.json's board colour (which `palette.json::_caveat` warns is a
## concept-art value, too bright once a real light multiplies it).
const GRASS_ALBEDO := Color(0.20, 0.30, 0.16)


func _init() -> void:
	_run()


func _run() -> void:
	# preview_creatures.gd's documented quirk: creature_body.setup() gates the
	# build on is_inside_tree(), so a frame has to pass before anything exists.
	await process_frame

	var argv := OS.get_cmdline_user_args()
	var out_dir := "res://shots/creature_presentation"
	var ids: Array = []
	# `--alpha <species> <multiplier>` adds a second body of that species at the
	# size `encounter_director._make_alpha` gives it, standing beside the
	# ordinary one and the trainer bar. An alpha is supposed to read as an
	# EVENT, and the only way to know whether 1.3x does that is to look at the
	# two of them in one frame next to a person.
	var alphas: Array = []
	var i := 0
	while i < argv.size():
		if argv[i] == "--out" and i + 1 < argv.size():
			out_dir = argv[i + 1]
			i += 2
			continue
		if argv[i] == "--alpha" and i + 2 < argv.size():
			alphas.append([argv[i + 1], float(argv[i + 2])])
			i += 3
			continue
		ids.append(argv[i])
		i += 1
	if ids.is_empty():
		ids = SPECIES.table().keys()
		ids.sort()
	DirAccess.make_dir_recursive_absolute(out_dir)

	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	# Meadow daylight sky, not a studio card: a pale blue behind the subject is
	# what the player sees behind anything standing on a rise.
	e.background_color = Color(0.42, 0.60, 0.74)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.55, 0.62, 0.74)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.environment = e
	world.add_child(env)

	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(-35.0), 0.0)
	key.light_energy = 1.3
	key.light_color = Color(1.0, 0.97, 0.90)
	world.add_child(key)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(120, 120)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GRASS_ALBEDO
	mat.roughness = 1.0
	floor_mesh.material_override = mat
	world.add_child(floor_mesh)

	var camera := Camera3D.new()
	camera.fov = 40.0
	world.add_child(camera)
	camera.make_current()

	var ruler := MeshInstance3D.new()
	var bar := BoxMesh.new()
	bar.size = Vector3(0.06, TRAINER_HEIGHT, 0.06)
	ruler.mesh = bar
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.45, 0.47, 0.5)
	ruler.material_override = grey
	world.add_child(ruler)

	for id: String in ids:
		var body: Node3D = CREATURE_SCENE.instantiate()
		body.name = "Shot_%s" % id
		body.set_script(BODY)
		world.add_child(body)
		body.call("setup", id)
		body.global_position = Vector3.ZERO
		# No floor collider under this card; an unfrozen CharacterBody3D falls
		# out of shot under its own gravity (preview_creatures.gd's own note).
		body.set_physics_process(false)
		# Three-quarter TOWARD the camera, so the face is in shot. A model's
		# forward is -Z, and the camera sits at +X/+Z, so this is the yaw that
		# turns the head into the lens rather than away from it -- the first
		# pass shot the whole roster's back and could not have judged a face
		# at all.
		body.rotation.y = deg_to_rad(25.0)

		var height := 1.8
		if body.has_method("body_height"):
			height = float(body.call("body_height"))

		for _f in 30:
			await physics_frame

		# Framing scales with the body, or the 2.6m stag is cropped by the same
		# camera that leaves the 1.35m bird a speck.
		var portrait_distance := maxf(2.6, height * 1.75)
		ruler.global_position = Vector3(-height * 0.85, TRAINER_HEIGHT * 0.5, -0.5)
		camera.global_position = Vector3(
			portrait_distance * 0.36, height * 0.80, portrait_distance * 0.93)
		camera.look_at(Vector3(0.0, height * 0.60, 0.0), Vector3.UP)
		await _shoot("%s/%s_portrait.png" % [out_dir, id])

		# Gameplay distance: far enough that the creature is a shape and a
		# colour rather than a set of features, which is the read the field
		# frames failed.
		ruler.global_position = Vector3(-1.6, TRAINER_HEIGHT * 0.5, 0.0)
		camera.global_position = Vector3(2.0, 2.4, 17.0)
		camera.look_at(Vector3(0.0, height * 0.5, 0.0), Vector3.UP)
		await _shoot("%s/%s_field.png" % [out_dir, id])

		body.queue_free()
		await process_frame

	for entry: Array in alphas:
		var species: String = entry[0]
		var multiplier: float = entry[1]
		var pair: Array = []
		var offsets := [-1.6, 1.6]
		for index in 2:
			var creature: Node3D = CREATURE_SCENE.instantiate()
			creature.name = "Alpha_%s_%d" % [species, index]
			creature.set_script(BODY)
			world.add_child(creature)
			creature.call("setup", species)
			if index == 1:
				creature.call("apply_size_multiplier", multiplier)
			creature.global_position = Vector3(float(offsets[index]), 0.0, 0.0)
			creature.set_physics_process(false)
			creature.rotation.y = deg_to_rad(15.0)
			pair.append(creature)

		for _f in 30:
			await physics_frame

		var tall := 1.8
		if pair[1].has_method("body_height"):
			tall = float(pair[1].call("body_height"))
		ruler.global_position = Vector3(0.0, TRAINER_HEIGHT * 0.5, 0.0)
		camera.global_position = Vector3(1.2, tall * 0.75, maxf(6.0, tall * 3.4))
		camera.look_at(Vector3(0.0, tall * 0.45, 0.0), Vector3.UP)
		await _shoot("%s/%s_alpha_x%.2f.png" % [out_dir, species, multiplier])
		for creature: Node3D in pair:
			creature.queue_free()
		await process_frame

	quit(0)


func _shoot(path: String) -> void:
	for _f in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		push_error("no image for %s" % path)
		return
	image.save_png(path)
	print("wrote %s" % path)
