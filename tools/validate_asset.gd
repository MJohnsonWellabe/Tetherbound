extends SceneTree

## Judge one creature asset inside the engine the game actually ships on.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/validate_asset.gd -- terrapup
##
##   ... --script tools/validate_asset.gd -- res://assets/pals/x.glb 1.2
##
## TETHERBOUND_3D_ART_PIPELINE.md section 15 and 16: a model that looks good in
## a Blender close-up can still fail in the game, so do not judge it only in
## Blender. Section 16 names the distances that matter — exploration, combat,
## capture aim, interaction close-up — and asks whether eyes, limbs, attack
## anticipation and the species' signature feature still read at each.
##
## Blender's turntable answers "is this the creature in the drawing". This
## answers "does it survive being in the game", which is a different question
## and the one that decides whether an asset ships.
##
## WHAT THIS DELIBERATELY REUSES
##
## The creature is built by `pal_body.gd` from `species.json`, not loaded
## directly. That means these frames show the model AFTER `_fit()` has scaled
## it to the gameplay collider and AFTER `model_yaw` has turned it — which is
## how the player will see it. Loading the .glb straight would produce a
## prettier picture of an asset nobody will ever see at that size.

const SPECIES := preload("res://scripts/pals/pal_species.gd")
const BODY := preload("res://scripts/pals/pal_body.gd")

const PAL_SCENE := "res://scenes/pals/pal.tscn"
const OUT_DIR := "res://shots/validation"

## Metres of the trainer, stood beside the creature as a ruler. GAME_DESIGN's
## scale reference and every sheet's scale chart use the same figure.
const TRAINER_HEIGHT := 1.8

## The four distances section 16 asks for, in metres from the subject, with the
## camera height each is actually seen from.
##
## Taken from the real cameras rather than invented: `exploration` is the
## third-person follow distance, `combat` is where the combat camera sits during
## a fight, `capture` is where the player stands when aiming an orb, and
## `closeup` is an interaction.
const DISTANCES := [
	{"name": "exploration", "distance": 9.0, "height": 3.2},
	{"name": "combat", "distance": 6.0, "height": 2.2},
	{"name": "capture", "distance": 4.0, "height": 1.7},
	{"name": "closeup", "distance": 1.8, "height": 1.0},
]

## Two lighting conditions, because an asset can pass under studio light and
## fail under the game's. Section 15 asks for both.
const LIGHTING := ["neutral", "gameplay"]

var _species_id: String = ""
var _shots: int = 0


func _init() -> void:
	_run()


## `await`ed all the way down, deliberately.
##
## `_capture` has to yield two frames before grabbing the viewport, and an
## `await` in a callee that the caller does not await does not pause the caller
## — so the first version tore the world down before a single frame had
## rendered and reported "0 frames" cheerfully. Every function on this path
## returns a coroutine and every call site awaits it.
func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("usage: --script tools/validate_asset.gd -- <species_id>")
		quit(2)
		return

	_species_id = args[0]
	if not SPECIES.has(_species_id):
		push_error("unknown species '%s'. Known: %s" % [
			_species_id, ", ".join(SPECIES.table().keys())
		])
		quit(2)
		return

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	for lighting: String in LIGHTING:
		await _capture_set(lighting)

	print("\n%s: %d frames -> %s" % [_species_id, _shots, OUT_DIR])
	print("  Judge these, not the Blender renders. Section 16 asks: do the eyes")
	print("  read, do the limbs separate, is an attack legible before it lands,")
	print("  and is the species' signature feature visible at combat distance?")
	quit(0)


func _capture_set(lighting: String) -> void:
	var world := Node3D.new()
	root.add_child(world)
	_build_environment(world, lighting)

	var body: Node3D = await _build_creature(world)
	if body == null:
		world.queue_free()
		return

	_build_scale_bar(world, body)

	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true

	var focus: Vector3 = Vector3(0.0, float(body.call("body_height")) * 0.5, 0.0)

	for setup: Dictionary in DISTANCES:
		var distance := float(setup["distance"])
		var height := float(setup["height"])
		# look_at_from_position, not position-then-look_at: during `_init` the
		# tree has not finished coming up and `look_at` refuses to run on a node
		# it does not yet consider in-tree. This form does not care.
		camera.look_at_from_position(Vector3(0.0, height, distance), focus, Vector3.UP)
		await _capture("%s_%s_%s" % [_species_id, lighting, setup["name"]])

	world.queue_free()


## Build the creature exactly the way the game does: the real scene, the real
## script, the real species table.
##
## The first version hand-built the child nodes instead, and got a capsule. It
## added them AFTER putting the body in the tree, so `pal_body.gd`'s `@onready`
## references to $Body and $Model had already resolved to null and
## `_build_placeholder()` quietly declined to run. Instancing `pal.tscn` cannot
## drift from the game like that, and cannot go stale when the scene changes.
func _build_creature(world: Node3D) -> Node3D:
	var scene: PackedScene = load(PAL_SCENE) as PackedScene
	if scene == null:
		push_error("could not load %s" % PAL_SCENE)
		return null

	var body: Node3D = scene.instantiate() as Node3D
	body.set_script(BODY)

	# Species set BEFORE the node enters the tree, not by calling setup() after.
	#
	# This script runs from `_init()`, which is before the SceneTree has come up,
	# so `_ready()` on anything added here fires later than it looks like it
	# does. `setup()` called immediately after `add_child` therefore ran while
	# `pal_body`'s @onready `$Body` was still null, took its `_body != null`
	# guard, and did nothing — leaving a creature that reported no model and
	# rendered as a capsule. Setting the field first means `_ready()` builds the
	# model whenever it does fire, which is the pattern
	# `tools/preview_creatures.gd` already uses for the same reason.
	body.set("species_id", _species_id)
	world.add_child(body)

	# Let _ready() happen before touching anything it also touches.
	await process_frame

	# Freeze it, and freeze it AFTER that await.
	#
	# `pal_body` is a CharacterBody3D and applies gravity every physics frame.
	# The ground here is a MeshInstance3D with no collider — it exists to be
	# looked at, not stood on — so an unfrozen creature falls, and by the third
	# capture it is metres below the camera. The first run of this tool produced
	# four photographs of an empty meadow with a scale post in it.
	#
	# Freezing before the await is not enough, and the failure is asymmetric in a
	# way that makes it look like something else. `pal_body._ready()` calls
	# `_on_visibility_changed()`, which sets physics processing back on from
	# `visible`. On the FIRST lighting pass the tree is still coming up, so
	# `_ready()` runs after this function's body and undoes the freeze; on the
	# second pass it runs inside `add_child` and the freeze sticks. So the
	# neutral row came back empty while the gameplay row was perfect, which
	# reads as a lighting bug and is not one.
	body.set_physics_process(false)
	body.position = Vector3.ZERO

	if not bool(body.call("has_model")):
		push_warning(("'%s' fell back to the capsule. Either species.json names no " +
			"model, or the one it names failed to load — either way there is " +
			"nothing here to validate.") % _species_id)
	return body


func _build_scale_bar(world: Node3D, body: Node3D) -> void:
	## A trainer-height post beside the creature.
	##
	## Not decoration. Every reference sheet carries a scale chart against a
	## 1.75m human for a reason, and the single most common way a creature asset
	## fails in this project is by being the wrong size — which is invisible in
	## an isolated render and obvious next to a ruler.
	var post := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.06, TRAINER_HEIGHT, 0.06)
	post.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.85, 0.2, 0.2)
	material.roughness = 0.9
	post.material_override = material

	var offset: float = float(body.call("body_radius")) + 0.55
	post.position = Vector3(offset, TRAINER_HEIGHT * 0.5, 0.0)
	world.add_child(post)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40.0, 40.0)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.30, 0.36, 0.22)
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	world.add_child(ground)


func _build_environment(world: Node3D, lighting: String) -> void:
	var holder := WorldEnvironment.new()
	var env := Environment.new()
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR

	var key := DirectionalLight3D.new()
	if lighting == "neutral":
		# Studio: even, shadowless, for reading form and colour.
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.22, 0.24, 0.26)
		env.ambient_light_color = Color(0.78, 0.80, 0.84)
		env.ambient_light_energy = 1.5
		key.light_energy = 1.4
		key.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(-35.0), 0.0)
	else:
		# Gameplay: the meadow's own sky and sun angle, with shadows, because a
		# creature is seen under this and not under a studio rig.
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.55, 0.70, 0.88)
		env.ambient_light_color = Color(0.52, 0.60, 0.70)
		env.ambient_light_energy = 0.9
		key.light_energy = 1.9
		key.light_color = Color(1.0, 0.96, 0.88)
		key.rotation = Vector3(deg_to_rad(-52.0), deg_to_rad(30.0), 0.0)
		key.shadow_enabled = true

	holder.environment = env
	world.add_child(holder)
	world.add_child(key)


func _capture(name: String) -> void:
	# Two frames before grabbing: the first submits the scene, the second is the
	# one with everything actually resolved. Grabbing on frame one produces a
	# black image, which has cost this project a debugging session before
	# (docs/decisions/D06).
	for _i in 2:
		await process_frame

	var image: Image = root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT_DIR, name]
	if image.save_png(ProjectSettings.globalize_path(path)) != OK:
		push_error("could not write %s" % path)
		return
	_shots += 1
	print("  %s" % path)
