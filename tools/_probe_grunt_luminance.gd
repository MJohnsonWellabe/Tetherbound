extends SceneTree

## T1-LIGHT. Fast iteration rig for the black-NPC closure -- same pattern as
## `_probe_npc_metallic_ab.gd` (real `world_look.gd` day/night environment, no
## playground boot), so a palette/emission-floor tuning loop costs seconds per
## render instead of the ~5-10 minutes a scoped `_capture_ground_and_sky.gd`
## band pass needs. Renders grunt, officer, captain and a wooden-crate control,
## one subject per frame, at both `day` and `night`, against a flat magenta
## background. Measure with `tools/_sample_npc_luma.py shots/_diag/*.png` --
## world_look.gd's own adjustment_saturation/brightness/contrast pass runs on
## the whole framebuffer including this background, shifting its rendered
## colour differently per time-of-day preset, so the luma maths lives in
## Python where the background can be sampled per-image instead of assumed.
##
##   xvfb-run -a -s "-screen 0 1280x480x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x480 \
##     --script tools/_probe_grunt_luminance.gd
##   python3 tools/_sample_npc_luma.py shots/_diag/grunt_luminance_*.png

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const NPC_RANKS := preload("res://scripts/characters/npc_ranks.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")

const RANKS := ["grunt", "officer", "captain"]
const OUT := "res://shots/_diag"

## Saturated magenta -- never a body/crate/uniform colour at any time of day.
const BG_COLOR := Color(1.0, 0.0, 1.0)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for time_name in ["day", "night"]:
		for rank in RANKS:
			await _shoot(time_name, rank, false)
		await _shoot(time_name, "crate", true)
	quit(0)


func _shoot(time_name: String, subject: String, is_crate: bool) -> void:
	var world := Node3D.new()
	root.add_child(world)
	_build_environment(world, time_name)

	if is_crate:
		var crate: PackedScene = load("res://assets/props/quaternius_fantasy/Crate_Wooden.gltf")
		if crate != null:
			var c: Node3D = crate.instantiate()
			c.position = Vector3.ZERO
			world.add_child(c)
	else:
		var holder := Node3D.new()
		holder.set_script(CHARACTER_MODEL)
		world.add_child(holder)
		var cfg: Dictionary = NPC_RANKS.config_for(subject)
		if not bool(holder.call("build_from_config", cfg)):
			push_error("rank '%s' failed to build" % subject)

	var cam := Camera3D.new()
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.1, 2.4), Vector3(0.0, 1.0, 0.0), Vector3.UP)
	cam.current = true

	for f in 40:
		await process_frame
	var img: Image = get_root().get_texture().get_image()
	var path := "%s/grunt_luminance_%s_%s.png" % [OUT, time_name, subject]
	img.save_png(path)
	print("  %-5s %-8s -> %s" % [time_name, subject, path])

	world.queue_free()
	await process_frame


func _build_environment(world: Node3D, time_name: String) -> void:
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
	look.call("apply_time", time_name)

	# Swap the background AFTER world_look builds real day/night lighting --
	# ambient reads from the sky's own colour/energy (AMBIENT_SOURCE_SKY,
	# world_look.gd:507), which is independent of `background_mode`, so this
	# only replaces what is visually painted behind the character with a flat
	# colour, without touching the light the body is actually lit by.
	var env: Environment = env_node.environment
	env.background_mode = Environment.BG_COLOR
	env.background_color = BG_COLOR
