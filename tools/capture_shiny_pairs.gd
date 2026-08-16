extends SceneTree

## OF28: render each colourway-authored species twice — ordinary and shiny —
## side by side, same flat light as tools/preview_creatures.gd. The judge for
## "a shiny is a genuinely different colourway, not a shade" (the owner's own
## words, ralph/BACKLOG.md OF28) is this frame, never a material unit test.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" ~/godot-bin/godot --path . \
##     --rendering-driver opengl3 --script tools/capture_shiny_pairs.gd

const SPECIES_IDS := [
	"paddlenewt", "burrowback", "terrapup", "ripplet", "galewisp",
	"meadowhart", "tuskroot", "mosshell", "brooktail", "galecrest",
	"duskhush", "pipwing", "reedwing", "bramblebun", "mudsnout",
	"trailpup", "veridian",
]
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const OUT := "res://shots/_shiny_pairs.png"

const SPACING := 2.6
## Pairs per row, and how far back each next row sits -- 17 species in one
## line runs far past any sane camera frustum (the first capture framed four).
const PER_ROW := 5
const ROW_DEPTH := 4.0


func _init() -> void:
	_run()


func _run() -> void:
	# Same first-frame quirk preview_creatures.gd documents: setup() gates the
	# build on is_inside_tree(), so wait a frame before building bodies.
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

	var x := 0.0
	var z := 0.0
	var placed := 0
	for id in SPECIES_IDS:
		if placed > 0 and placed % PER_ROW == 0:
			x = 0.0
			z -= ROW_DEPTH
		placed += 1
		for is_shiny in [false, true]:
			var creature := CREATURE_SCENE.instantiate()
			# The packed scene is a bare CharacterBody3D; the body script is
			# attached at spawn time by whoever builds it (see smoke_art.gd,
			# which does exactly this before calling setup()).
			creature.set_script(BODY)
			world.add_child(creature)
			creature.set_physics_process(false)
			creature.call("setup", id, is_shiny)
			creature.set("global_position", Vector3(x, 0.0, z))
			x += SPACING

	var camera := Camera3D.new()
	var mid := (PER_ROW * 2 - 1) * SPACING * 0.5
	var mid_z := z * 0.5
	camera.position = Vector3(mid, 13.0, mid_z + 15.0)
	camera.look_at_from_position(camera.position, Vector3(mid, 0.6, mid_z))
	world.add_child(camera)
	camera.make_current()

	for i in 12:
		await process_frame

	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT)
	print("saved %s" % OUT)
	quit(0)
