extends SceneTree

## Render every species side by side against a neutral card, at a known scale.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/preview_creatures.gd
##
## A creature in a survey frame is thirty pixels of it, half behind another
## creature, under whatever the sun is doing. That is the right way to judge
## whether it READS in the game and a useless way to find out what colour it
## actually is — an orange fox and a white rabbit came back as two identical
## white blobs, and the reason turned out to be neither the fox nor the rabbit.
##
## So: each species alone, lit flatly, at the size its collider claims, with a
## 1.8m trainer-height bar beside it for scale. This is the ruler the visual
## rubric was missing (`docs/reviews/MA-03`, the calibration miss).

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const BODY := preload("res://scripts/pals/pal_body.gd")
const PAL_SCENE := preload("res://scenes/pals/pal.tscn")
const OUT := "res://shots/_creatures.png"

## Metres of the trainer, drawn as a reference bar beside every creature.
const TRAINER_HEIGHT := 1.8


func _init() -> void:
	_run()


func _run() -> void:
	# Godot's --script SceneTree entry runs _init() before the tree itself has
	# started iterating: nodes added here get _ready() called (their $Path
	# children resolve fine) but is_inside_tree() stays false until the first
	# yield back to the engine. pal_body.gd's setup() gates _build_placeholder()
	# on is_inside_tree(), so building creatures before this await silently
	# built nothing — the actual cause behind the reverted attempt this task's
	# backlog entry mentions. One frame here is enough; render_bounds.gd's own
	# header names the same quirk for global_transform specifically.
	await process_frame

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

	var ids: Array = SPECIES.table().keys()
	ids.sort()

	# Spread along X so one camera sees them all, and stand a grey bar of the
	# trainer's height behind each so relative scale is readable rather than
	# asserted.
	var spacing := 2.2
	var x := -spacing * (ids.size() - 1) * 0.5
	for id: String in ids:
		# pal.tscn is deliberately scriptless (its $Collision/$Model/$Body/$Head
		# children are what pal_body.gd's @onready vars resolve against); BODY.new()
		# alone produces a bare CharacterBody3D with none of them, so every
		# @onready lookup failed and no creature was ever built. Instantiate the
		# scene and attach the script, the same order encounter_director.gd uses
		# for wild and ally pals: script attached before add_child, setup() called
		# after — setup() is what actually builds the placeholder/model, since
		# species_id is still empty when _ready() runs.
		var body: Node3D = PAL_SCENE.instantiate()
		body.name = "Preview_%s" % id
		body.set_script(BODY)
		world.add_child(body)
		body.call("setup", id)
		body.global_position = Vector3(x, 0.0, 0.0)
		# This card has no floor collider, only the decorative plane below — a
		# CharacterBody3D with nothing to stand on falls under its own gravity
		# every physics frame. 120 frames of that (the wait below) drops it
		# metres out of the shot with no error to say why the render came back
		# empty. Nothing here needs to move; freeze it where it was placed.
		body.set_physics_process(false)

		var ruler := MeshInstance3D.new()
		var bar := BoxMesh.new()
		bar.size = Vector3(0.06, TRAINER_HEIGHT, 0.06)
		ruler.mesh = bar
		var grey := StandardMaterial3D.new()
		grey.albedo_color = Color(0.45, 0.47, 0.5)
		ruler.material_override = grey
		world.add_child(ruler)
		ruler.global_position = Vector3(x - 0.75, TRAINER_HEIGHT * 0.5, -0.4)
		x += spacing

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.33, 0.30)
	floor_mesh.material_override = mat
	world.add_child(floor_mesh)

	var camera := Camera3D.new()
	camera.fov = 42.0
	world.add_child(camera)
	camera.make_current()

	for i in 120:
		await physics_frame
	# Framed after the bodies exist, so it fits whatever the roster grew to.
	camera.global_position = Vector3(0.0, 1.3, spacing * ids.size() * 0.95 + 2.0)
	camera.look_at(Vector3(0.0, 0.85, 0.0), Vector3.UP)

	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		print("no image")
		quit(1)
		return
	image.save_png(OUT)
	print("wrote %s for %d species: %s" % [OUT, ids.size(), ", ".join(ids)])
	print("the grey bar beside each is %.1fm — the trainer's height." % TRAINER_HEIGHT)
	quit(0)
