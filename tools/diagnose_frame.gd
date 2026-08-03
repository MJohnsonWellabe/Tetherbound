extends SceneTree

## Render one viewpoint several times, changing exactly one thing each time.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/diagnose_frame.gd
##
## For when a frame is wrong and reasoning about why has already been wrong
## once. The near-field ground measured luminance 0.068 against 0.27-0.60 across
## the references, and two confident explanations — grass shadows, then macro
## variation — both turned out not to be it. A render with one variable moved is
## worth more than a third guess.
##
## Writes shots/_diag/<name>.png. Nothing here is part of the survey; delete the
## output when the question is answered.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/_diag"
const SETTLE_FRAMES := 240

## Same as survey.gd's 01-spawn-outward.
const EYE := Vector2(0.0, 0.0)
const EYE_H := 2.2
const TARGET := Vector2(150.0, 120.0)
const HORIZON := 0.28
const FOV := 70.0

var _world: Node = null
var _camera: Camera3D = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = _world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = _world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false

	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.far = 2000.0
	_world.add_child(_camera)
	_camera.make_current()
	_pose()

	var sun: DirectionalLight3D = _world.get_node_or_null(^"Sun") as DirectionalLight3D
	var env: Environment = (_world.get_node_or_null(^"WorldEnvironment") as WorldEnvironment).environment
	var terrain: Node3D = _world.get_node_or_null(^"Terrain") as Node3D
	var material: Object = null if terrain == null else terrain.get("material")

	await _shoot("00-baseline")

	sun.shadow_enabled = false
	await _shoot("01-no-shadows")
	sun.shadow_enabled = true

	var was_energy := env.ambient_light_energy
	env.ambient_light_energy = 4.0
	await _shoot("02-ambient-4x")
	env.ambient_light_energy = was_energy

	if material != null:
		material.call("set_shader_param", "enable_macro_variation", false)
		await _shoot("03-no-macro-variation")
		material.call("set_shader_param", "enable_macro_variation", true)

		material.set("dual_scale_texture", -1)
		await _shoot("04-no-dual-scale")
		material.set("dual_scale_texture", 0)

	var veg: Node = _world.get_node_or_null(^"Vegetation")
	if veg != null:
		veg.visible = false
		await _shoot("05-no-vegetation")
		veg.visible = true

	var was_fog := env.fog_enabled
	env.fog_enabled = false
	await _shoot("06-no-fog")
	env.fog_enabled = was_fog

	# Sky ambient may simply not reach the terrain under this renderer. If a flat
	# colour ambient lifts the darks and a 4x sky ambient did not, then the
	# survey is showing a lighting model the shipping build does not use, and the
	# right response is to distrust the frames rather than to crush the config.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.70, 0.80)
	env.ambient_light_energy = 1.6
	await _shoot("07-colour-ambient")
	env.ambient_light_energy = was_energy
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY

	if material != null:
		# Did normal_depth reach the shader at all? The config asked for 0.3 and
		# the frame did not move by a thousandth, which is either "not the cause"
		# or "never applied", and those need separating.
		var assets: Object = terrain.get("assets")
		if assets != null and assets.has_method("get_texture"):
			var grass: Object = assets.call("get_texture", 0)
			if grass != null:
				print("  grass normal_depth reads back as %s" % str(grass.get("normal_depth")))
				grass.set("normal_depth", 0.0)
				await _shoot("08-no-normal-map")

	for pitch in [-70.0, -35.0]:
		sun.rotation = Vector3(deg_to_rad(pitch), sun.rotation.y, 0.0)
		await _shoot("09-sun-pitch-%d" % int(pitch))
	sun.rotation = Vector3(deg_to_rad(-52.0), sun.rotation.y, 0.0)

	# Shadow acne is the remaining candidate for the near-field mottle: it is
	# high-frequency, it is dark, and it only appears where shadow texels are
	# densest, which is exactly the near split.
	for bias: Array in [[0.02, 0.2], [0.03, 0.6], [0.08, 2.5]]:
		sun.shadow_bias = bias[0]
		sun.shadow_normal_bias = bias[1]
		await _shoot("10-bias-%.2f-%.1f" % [bias[0], bias[1]])
	sun.shadow_bias = 0.06
	sun.shadow_normal_bias = 1.4

	for distance in [80.0, 500.0]:
		sun.directional_shadow_max_distance = distance
		await _shoot("11-shadow-distance-%d" % int(distance))
	sun.directional_shadow_max_distance = 220.0

	# Sun HEADING, which is the one thing never questioned. The camera looks
	# north-east across the playground and the sun has sat at yaw -40 since the
	# first art pass, which puts it beyond the far hills — so the whole near
	# slope is backlit and every frame has a dark foreground. Landscape
	# photography puts the sun behind the viewer's shoulder for exactly this
	# reason.
	for yaw in [-140.0, -100.0, -70.0, -40.0, 0.0, 40.0]:
		sun.rotation = Vector3(deg_to_rad(-52.0), deg_to_rad(yaw), 0.0)
		await _shoot("12-sun-yaw-%d" % int(yaw))

	print("")
	print("near-field luminance is the bottom 15%% of each frame; compare 00 with the rest.")
	quit(0)


func _pose() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var eye := Vector3(EYE.x, field.height_at(EYE.x, EYE.y) + EYE_H, EYE.y)
	_camera.global_position = eye
	_camera.look_at(Vector3(TARGET.x, field.height_at(TARGET.x, TARGET.y) + 6.0, TARGET.y), Vector3.UP)
	var half := tan(deg_to_rad(FOV) * 0.5)
	_camera.rotation = Vector3(-atan((0.5 - HORIZON) * 2.0 * half), _camera.rotation.y, 0.0)


func _shoot(name: String) -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	if image == null:
		print("  %-24s no image" % name)
		return
	image.save_png("%s/%s.png" % [OUT_DIR, name])

	var height := image.get_height()
	var total := 0.0
	var count := 0
	for y in range(int(height * 0.85), height, 2):
		for x in range(0, image.get_width(), 4):
			var c := image.get_pixel(x, y)
			total += c.r * 0.2126 + c.g * 0.7152 + c.b * 0.0722
			count += 1
	print("  %-24s near-field luminance %.3f" % [name, total / maxf(1.0, float(count))])
