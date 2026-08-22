extends SceneTree

## The Meadows roster in its ORDINARY colourways only, for the download page.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --script tools/capture_roster_ordinary.gd
##
## `capture_shiny_pairs.gd` renders every species twice, ordinary beside shiny,
## because that frame's job is judging OF28's "a shiny is a genuinely different
## colourway, not a shade". That frame then went on the public download page,
## which put every rare colourway in the game on a page a first-time player
## reads before they have caught anything. Owner directive, 2026-08-22: **do
## not show the shinies.** So the page gets this instead, and the pair sheet
## stays what it always was -- an internal judging frame.
##
## Same species list and same flat neutral light as the pair sheet, so the two
## remain comparable; only the shiny column and the camera framing differ.

const SPECIES_IDS := [
	"paddlenewt", "burrowback", "terrapup", "ripplet", "galewisp",
	"meadowhart", "tuskroot", "mosshell", "brooktail", "galecrest",
	"duskhush", "pipwing", "reedwing", "bramblebun", "mudsnout",
	"trailpup", "veridian",
]
const CREATURE_SCENE := preload("res://scenes/creatures/creature.tscn")
const BODY := preload("res://scripts/creatures/creature_body.gd")
const OUT := "res://shots/_roster_ordinary.png"

const SPACING := 2.4
## Six across rather than the pair sheet's five, because one row is now half
## as wide and seventeen singles in three rows frames tighter than four.
const PER_ROW := 6
const ROW_DEPTH := 4.3


func _init() -> void:
	_run()


func _run() -> void:
	# preview_creatures.gd's documented quirk: setup() gates the body build on
	# is_inside_tree(), so a frame has to pass before anything is built.
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
		var creature := CREATURE_SCENE.instantiate()
		creature.set_script(BODY)
		world.add_child(creature)
		creature.set_physics_process(false)
		creature.call("setup", id, false)
		creature.set("global_position", Vector3(x, 0.0, z))
		x += SPACING

	var camera := Camera3D.new()
	var mid := (PER_ROW - 1) * SPACING * 0.5
	var mid_z := z * 0.5
	camera.position = Vector3(mid, 6.2, mid_z + 8.6)
	camera.look_at_from_position(camera.position, Vector3(mid, 0.6, mid_z))
	world.add_child(camera)
	camera.make_current()

	for i in 12:
		await process_frame

	var img := root.get_viewport().get_texture().get_image()
	img.save_png(OUT)
	print("saved %s" % OUT)
	quit(0)
