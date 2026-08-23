extends SceneTree

## GATE-D. Is the trainer really a black cut-out, or is the capture lying?
##
## D4's blind critic reported the trainer rendering as "a solid black cut-out"
## in two of its frames "with correctly lit wooden props a metre away in the
## same frame", and called the game's cast "a black speck". If that is real it
## is a chapter-wide character-material defect, not a Band 4 one. If it is the
## software renderer, it is a capture-tool problem and two other false alarms
## on this run already went that way (a bushes layer that looked crimson because
## a probe skipped the retexture pipeline; a campfire whose flame and glow did
## not survive headless).
##
## So: build a character through the same path the world uses, stand a lit
## wooden prop beside it as the critic's own control, and light both the same.
## If the prop reads and the character does not, the character material is the
## problem. If both read, the defect lives in the survey's staging.

const CHARACTER_MODEL: GDScript = preload("res://scripts/characters/character_model.gd")

func _init() -> void:
	var world := Node3D.new()
	root.add_child(world)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.45, 0.5, 0.42)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.66, 0.74, 0.80)
	e.ambient_light_energy = 0.9
	env.environment = e
	world.add_child(env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45.0, -30.0, 0.0)
	sun.light_energy = 1.15
	world.add_child(sun)

	# The character, built the way trainer_npc.gd builds one.
	var art: Variant = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/config/art.json"))
	var cfg: Dictionary = (art as Dictionary).get("trainer", {})
	var holder := Node3D.new()
	holder.set_script(CHARACTER_MODEL)
	world.add_child(holder)
	if not bool(holder.call("build_from_config", cfg)):
		print("FAILED to build the trainer from art.json")
		quit(1)
		return
	holder.position = Vector3(-0.75, 0.0, 0.0)

	# The control: a wooden prop, the same thing the critic saw lit correctly.
	var crate: PackedScene = load("res://assets/props/quaternius_fantasy/Crate_Wooden.gltf")
	if crate != null:
		var c: Node3D = crate.instantiate()
		c.position = Vector3(0.95, 0.0, 0.0)
		world.add_child(c)

	var cam := Camera3D.new()
	world.add_child(cam)
	cam.look_at_from_position(Vector3(0.0, 1.15, 3.4), Vector3(0.0, 0.95, 0.0), Vector3.UP)
	cam.current = true

	for i in 10:
		await process_frame
	get_root().get_texture().get_image().save_png("res://shots/charcheck/trainer_vs_crate.png")
	print("wrote shots/charcheck/trainer_vs_crate.png")
	quit(0)
