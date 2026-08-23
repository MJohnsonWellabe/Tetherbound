extends SceneTree

## Capture the four Team Tether ranks side by side, for the visual critic loop
## (`NP2`). NP2-grunt-wire: grunt, officer and captain now build on the grunt
## rig (`art.json`'s `grunt` block) with `npc_ranks.gd`'s palette and badge
## laid over it; the Warden himself is still the one rank with no `base`
## override, so he renders with his own unmodified `art.json` entry, as the
## top of the rank ladder every other tone is judged against.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" \
##     godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_npc_ranks.gd

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const OUT_DIR := "res://shots/_diag"

## Left to right, lowest to highest -- the order a rank ladder should read in.
const ORDER := ["grunt", "officer", "captain", "warden"]
const SPACING := 1.7

const SETTLE_FRAMES := 20


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var world := Node3D.new()
	root.add_child(world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.10, 0.11, 0.13)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.87, 0.90)
	env.ambient_light_energy = 2.2
	env_node.environment = env
	world.add_child(env_node)

	# Flat, near-frontal key so the jacket's own tint reads without deep
	# self-shadow crushing it to near-black -- this is a palette comparison
	# render, not a mood shot.
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-25.0), deg_to_rad(-10.0), 0.0)
	key.light_energy = 1.8
	world.add_child(key)

	var fill := DirectionalLight3D.new()
	fill.rotation = Vector3(deg_to_rad(-20.0), deg_to_rad(170.0), 0.0)
	fill.light_energy = 1.0
	fill.light_color = Color(0.80, 0.85, 0.95)
	world.add_child(fill)

	var bodies: Array[Node3D] = []
	for i in ORDER.size():
		var rank: String = ORDER[i]
		var cfg: Dictionary = NPC_RANKS.config_for(rank)
		if cfg.is_empty():
			push_error("no config for rank '%s'" % rank)
			continue

		var holder := Node3D.new()
		holder.set_script(CHARACTER_MODEL)
		holder.position = Vector3((i - (ORDER.size() - 1) / 2.0) * SPACING, 0.0, 0.0)
		world.add_child(holder)
		if not bool(holder.call("build_from_config", cfg)):
			push_error("rank '%s' failed to build" % rank)
			holder.queue_free()
			continue
		if holder.has_method("play"):
			holder.call("play", "idle")
		bodies.append(holder)

	var camera := Camera3D.new()
	camera.fov = 45.0
	world.add_child(camera)
	camera.look_at_from_position(Vector3(0.0, 1.5, 5.2), Vector3(0.0, 1.1, 0.0), Vector3.UP)
	camera.make_current()

	for i in SETTLE_FRAMES:
		await process_frame
	await RenderingServer.frame_post_draw

	var image := root.get_texture().get_image()
	if image == null:
		push_error("viewport returned no image")
		quit(1)
		return

	var path := "%s/npc_ranks.png" % OUT_DIR
	var error := image.save_png(path)
	if error != OK:
		push_error("save_png failed (%d)" % error)
		quit(1)
		return

	print("  npc_ranks -> %s" % path)
	quit(0)
