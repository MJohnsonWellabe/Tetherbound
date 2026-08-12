extends SceneTree

## Muybridge strip of the trainer's walk and sprint, at REAL game speed.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" ~/.cache/tetherbound-art/godot \
##     --path . --rendering-driver opengl3 --resolution 960x540 \
##     --script tools/capture_player_gait.gd
##
## OF5: the owner says running and walking look unnatural. A single frame of a
## gait cannot show why — gait defects live in the relationship between frames
## (feet vs ground, cadence vs travel). So this renders a sequence: the body
## translates along X at the speed movement.json actually drives it, over a
## half-metre-striped ground, while the clip advances deterministically via
## AnimationPlayer.advance(). A planted foot that changes stripe between two
## adjacent frames is foot-skate, measurable in the image, no opinion needed.
##
## Writes shots/gait/<clip>-NN.png plus a 3/4 view per clip; compose with
## tools/sheet.py for the blind pass.

const CHARACTER_MODEL := preload("res://scripts/characters/character_model.gd")
const OUT_DIR := "res://shots/gait"

## Frames captured per clip, spread over exactly one animation cycle.
const STEPS := 8

## (clip, metres per second the controller drives during it). Speeds must match
## data/config/movement.json's locomotion block — read at runtime below so a
## retune shows up here without editing this file.
var _gaits: Array = []


func _init() -> void:
	_run()


func _run() -> void:
	await process_frame

	var move := _movement_config()
	var loco: Dictionary = move.get("locomotion", {})
	_gaits = [
		["walk", float(loco.get("walk_speed", 5.0))],
		["sprint", float(loco.get("sprint_speed", 8.6))],
	]

	var world := Node3D.new()
	root.add_child(world)
	_light(world)
	_striped_ground(world)

	var model := Node3D.new()
	model.set_script(CHARACTER_MODEL)
	world.add_child(model)
	if not bool(model.call("build", "trainer")):
		printerr("trainer failed to build")
		quit(1)
		return
	# The clip translates nothing (animation is in place); face travel (+X).
	model.rotation.y = deg_to_rad(90.0)

	var camera := Camera3D.new()
	camera.fov = 40.0
	world.add_child(camera)
	camera.make_current()

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var anim: AnimationPlayer = model.call("animation_player")
	for gait: Array in _gaits:
		var clip: String = gait[0]
		var speed: float = gait[1]
		var cycle: float = anim.get_animation(clip).length
		model.call("play", clip)
		# play() cross-fades 0.18s, and under speed_scale = 0 that fade never
		# finishes — the second clip captured would render as a frozen blend
		# still dominated by the first one (measured: the sprint strip came
		# out as walk poses). Re-play unblended; loop mode is already set.
		anim.play(clip)
		# Deterministic stepping: seek to a known phase per frame, so a frame
		# is a known point of the cycle regardless of how slow the software
		# renderer runs. NOT advance() under speed_scale = 0 — measured on
		# 4.7, that combination advances nothing and renders frame 0 forever.
		anim.speed_scale = 0.0

		var x := -4.0
		model.position.x = x
		# Side view, tracking the body so the stripes scroll past the feet.
		for i in STEPS:
			var t := cycle * i / STEPS
			anim.seek(t, true)
			x = -4.0 + speed * t
			model.position.x = x
			camera.position = Vector3(x, 1.1, 4.6)
			camera.look_at(Vector3(x, 0.9, 0.0), Vector3.UP)
			await _settle()
			_save("%s-%02d" % [clip, i])

		# One 3/4 view mid-cycle for torso/arm read; the side strip cannot show
		# arm crossing or lateral balance.
		anim.seek(cycle * 0.25, true)
		camera.position = Vector3(x + 2.6, 1.5, 3.4)
		camera.look_at(Vector3(x, 0.95, 0.0), Vector3.UP)
		await _settle()
		_save("%s-quarter" % clip)
		anim.speed_scale = 1.0

	print("wrote %d frames per gait to %s" % [STEPS + 1, OUT_DIR])
	print("stripes are 0.5m; %s" % str(_gaits))
	quit(0)


func _settle() -> void:
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw


func _save(name: String) -> void:
	var image := root.get_texture().get_image()
	if image == null:
		printerr("no image for %s" % name)
		return
	image.save_png("%s/%s.png" % [OUT_DIR, name])


func _movement_config() -> Dictionary:
	var file := FileAccess.open("res://data/config/movement.json", FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}


func _light(world: Node3D) -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.55, 0.62, 0.68)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.78, 0.82)
	e.ambient_light_energy = 1.4
	env.environment = e
	world.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation = Vector3(deg_to_rad(-42.0), deg_to_rad(-30.0), 0.0)
	key.light_energy = 1.5
	key.shadow_enabled = true
	world.add_child(key)


## Half-metre stripes along the travel axis. The ruler foot-skate is measured
## against: a planted foot must stay on its stripe from frame to frame.
func _striped_ground(world: Node3D) -> void:
	var a := StandardMaterial3D.new()
	a.albedo_color = Color(0.42, 0.45, 0.42)
	var b := StandardMaterial3D.new()
	b.albedo_color = Color(0.72, 0.74, 0.70)
	for i in 120:
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.5, 0.05, 8.0)
		strip.mesh = box
		strip.material_override = a if i % 2 == 0 else b
		strip.position = Vector3(-10.0 + 0.5 * i + 0.25, -0.025, 0.0)
		world.add_child(strip)
