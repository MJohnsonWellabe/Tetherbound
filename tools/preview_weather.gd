extends SceneTree

## Photograph the day/night cycle and every weather state, from one fixed
## viewpoint. M10.
##
##   xvfb-run -a -s "-screen 0 1024x576x24" \
##     /opt/godot/godot --path . --rendering-driver opengl3 \
##     --resolution 1024x576 --script tools/preview_weather.gd
##
## ONE viewpoint on purpose. `tools/survey.gd` varies the camera and holds the
## hour nearly still, which is the right shape for judging composition and the
## wrong shape for judging a time-of-day system: five different framings of five
## different hours cannot tell you whether the hours differ. Here the framing is
## a constant and the sky is the variable, so any difference between two frames
## is the thing this milestone built.
##
## HONEST LIMITS, per D06 and the note at the top of tools/survey.sh:
##   * Compatibility renderer under llvmpipe, because Terrain3D segfaults under
##     lavapipe. No volumetric fog, no SSAO, no screen-space or depth reads. The
##     rain is CPU particles and depth fog for exactly that reason, so these
##     frames show what the Forward+ build will show — but nothing here can
##     prove a claim about SSAO or god rays, because neither is present.
##   * Frame times from this harness are meaningless as performance.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const WORLD_LOOK := preload("res://scripts/world/world_look.gd")
const OUT_DIR := "res://shots/weather"

## Terrain streams in over several frames and builds collision after that.
const SETTLE_FRAMES := 240
const POSE_FRAMES := 20
## Rain has a 1.1s lifetime; capturing before a full generation has fallen gives
## a frame with a thin band of drops near the top and clear air below it.
const RAIN_FILL_FRAMES := 70

## The same eye and target as `01-spawn-outward` in tools/survey.gd, so a frame
## from this tool and a frame from that one are comparable. The horizon sits a
## little lower here because the subject is the sky.
const EYE := Vector2(0.0, 0.0)
const EYE_H := 2.4
const TARGET := Vector2(150.0, 120.0)
const HORIZON := 0.30
const FOV := 70.0
const ACTOR := Vector2(9.0, 7.0)
const ACTOR_CLEARANCE := 0.4

## hour, weather, whether to fire a lightning strike into the shutter.
const SHOTS := [
	{"name": "cycle-01-0100-night", "hour": 1.0, "weather": "clear"},
	{"name": "cycle-02-0500-predawn", "hour": 5.0, "weather": "clear"},
	{"name": "cycle-03-0620-dawn", "hour": 6.2, "weather": "clear"},
	{"name": "cycle-04-1100-day", "hour": 11.0, "weather": "clear"},
	{"name": "cycle-05-1500-afternoon", "hour": 15.0, "weather": "clear"},
	{"name": "cycle-06-1800-golden", "hour": 18.0, "weather": "clear"},
	{"name": "cycle-07-2000-dusk", "hour": 20.0, "weather": "clear"},
	{"name": "cycle-08-2200-nightfall", "hour": 22.0, "weather": "clear"},
	{"name": "weather-01-day-clear", "hour": 11.0, "weather": "clear"},
	{"name": "weather-02-day-cloudy", "hour": 11.0, "weather": "cloudy"},
	{"name": "weather-03-day-rain", "hour": 11.0, "weather": "rain"},
	{"name": "weather-04-day-storm", "hour": 11.0, "weather": "storm"},
	{"name": "weather-05-day-storm-flash", "hour": 11.0, "weather": "storm", "flash": true},
	{"name": "weather-06-day-fog", "hour": 11.0, "weather": "fog"},
	{"name": "weather-07-golden-rain", "hour": 18.0, "weather": "rain"},
	{"name": "weather-08-night-storm", "hour": 0.0, "weather": "storm"},
	{"name": "weather-09-dawn-fog", "hour": 6.2, "weather": "fog"},
	{"name": "weather-10-night-clear", "hour": 1.0, "weather": "clear"},
]

var _failures: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	await _prove_the_shader_samples_what_the_built_in_material_samples()

	var packed: PackedScene = load(SCENE)
	var world: Node = packed.instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var hud: CanvasLayer = world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	if hud != null:
		hud.visible = false
	var minimap: CanvasLayer = world.get_node_or_null(^"Minimap") as CanvasLayer
	if minimap != null:
		minimap.visible = false

	var look: Node = world.get_node_or_null(^"WorldLook")
	var cycle: Node = world.get_node_or_null(^"SkyCycle")
	if look == null or cycle == null:
		_failures.append("the scene has no WorldLook/SkyCycle pair; nothing to preview")
		_report([])
		return

	# THE D18 CHECK, in the scene rather than in a probe: the cross-fading sky
	# has a fallback that snaps instead of fading, and the fallback looks almost
	# right in a still. A whole preview run judged on the fallback would be four
	# rounds of tuning a path the game does not take.
	if not bool(look.call("blending_sky")):
		_failures.append(
			"the sky is on the FALLBACK path, not the cross-fading shader — a panorama "
			+ "named in art.json did not load, and none of these frames show the real sky")

	var field: RefCounted = HEIGHTFIELD.new()
	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	_pose(camera, field)
	_place_actor(world.get_node_or_null(^"Player") as Node3D, field, camera)

	cycle.call("set_paused", true)

	# `-- night` renders only the shots whose name contains "night". A full set is
	# eighteen software-rendered frames of a 74,000-prop meadow, and tuning one
	# hour by re-rendering the other seventeen is most of an hour per round.
	var only := ""
	for argument in OS.get_cmdline_user_args():
		only = str(argument)
	if only != "":
		print("  filtering to shots matching '%s'" % only)

	var written: Array[String] = []
	for entry: Variant in SHOTS:
		var shot: Dictionary = entry
		var name := str(shot["name"])
		if only != "" and not name.contains(only):
			continue
		if not bool(cycle.call("force_weather", str(shot["weather"]))):
			_failures.append("%s: no weather state called '%s'" % [name, shot["weather"]])
			continue
		cycle.call("set_hour", float(shot["hour"]))

		var wet: bool = str(shot["weather"]) in ["rain", "storm"]
		for i in (RAIN_FILL_FRAMES if wet else POSE_FRAMES):
			await process_frame
		if bool(shot.get("flash", false)):
			cycle.call("strike_lightning")
			# Two frames in: the rise is 0.04s, so the peak lands almost at once
			# and waiting longer photographs the decay instead of the strike.
			await process_frame
			await process_frame
		else:
			# A storm rolls its own strikes, and one landing a few frames before
			# the shutter would brighten a frame that is supposed to show the
			# storm's ordinary light. Wait it out rather than explaining it away.
			var guard := 0
			while float(cycle.call("flash")) > 0.005 and guard < 240:
				guard += 1
				await process_frame
		await RenderingServer.frame_post_draw

		var image := root.get_texture().get_image()
		if image == null:
			_failures.append("%s: viewport returned no image" % name)
			continue
		var path := "%s/%s.png" % [OUT_DIR, name]
		if image.save_png(path) != OK:
			_failures.append("%s: save_png failed" % name)
			continue
		written.append(path)
		print("  %-30s %s   %s" % [name, cycle.call("describe"), _stats(image)])

	_report(written)


## The equivalence proof, before anything is tuned on top of it.
##
## D18: four art rounds went into a texture that was not on screen because
## nobody checked which of two shader inputs was being sampled. This milestone
## replaced Godot's `PanoramaSkyMaterial` with a hand-written sky shader, so the
## identical mistake is one uv convention away — a flipped sign puts the sun on
## the wrong side of the world and every "the shadows do not match the sky"
## finding after that would be chasing the wrong thing.
##
## So: render one sky through the built-in material and the same sky through the
## shader at blend 0, and compare the pixels. Anything but a near-exact match is
## a failure, printed first, before any frame is looked at.
func _prove_the_shader_samples_what_the_built_in_material_samples() -> void:
	const PANORAMA := "res://assets/environment/sky/day.hdr"
	if not ResourceLoader.exists(PANORAMA):
		_failures.append("day.hdr is missing; the sky equivalence check cannot run")
		return

	var stage := Node3D.new()
	root.add_child(stage)
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	var holder := WorldEnvironment.new()
	holder.environment = env
	stage.add_child(holder)
	var camera := Camera3D.new()
	camera.fov = FOV
	stage.add_child(camera)
	camera.make_current()
	# Aimed a little off-axis and above the horizon, so the frame contains the
	# horizon band, some cloud and some clear zenith rather than one flat patch.
	camera.rotation = Vector3(deg_to_rad(6.0), deg_to_rad(50.0), 0.0)

	var built_in := PanoramaSkyMaterial.new()
	built_in.panorama = load(PANORAMA)
	built_in.filter = true
	env.sky.sky_material = built_in
	var reference := await _shoot(camera)

	var shader := Shader.new()
	shader.code = WORLD_LOOK.SKY_SHADER
	var mine := ShaderMaterial.new()
	mine.shader = shader
	mine.set_shader_parameter("sky_a", load(PANORAMA))
	mine.set_shader_parameter("sky_b", load(PANORAMA))
	mine.set_shader_parameter("sky_overcast", load(PANORAMA))
	mine.set_shader_parameter("energy_a", 1.0)
	mine.set_shader_parameter("energy_b", 1.0)
	mine.set_shader_parameter("blend", 0.0)
	mine.set_shader_parameter("overcast_blend", 0.0)
	mine.set_shader_parameter("overcast_energy", 1.0)
	mine.set_shader_parameter("overcast_tint", Vector3.ONE)
	mine.set_shader_parameter("flash", 0.0)
	env.sky.sky_material = mine
	var ours := await _shoot(camera)

	stage.queue_free()
	await process_frame

	if reference == null or ours == null:
		_failures.append("the sky equivalence check could not capture a frame")
		return

	var worst := 0.0
	var total := 0.0
	var samples := 0
	for y in range(0, reference.get_height(), 4):
		for x in range(0, reference.get_width(), 4):
			var a := reference.get_pixel(x, y)
			var b := ours.get_pixel(x, y)
			var away: float = maxf(maxf(absf(a.r - b.r), absf(a.g - b.g)), absf(a.b - b.b))
			worst = maxf(worst, away)
			total += away
			samples += 1
	var mean := total / maxf(1.0, float(samples))
	print("  sky shader vs PanoramaSkyMaterial: mean %.5f  worst %.5f" % [mean, worst])
	# WHAT THE NUMBERS ACTUALLY WERE, so the threshold is not a guess.
	#
	# Wrong sign on the azimuth — the sky mirrored, clouds in the wrong half of
	# the world — measured mean 0.118. Correct, it measures mean 0.015, and an
	# amplified difference image shows that residual is a thin outline around
	# every cloud edge and nothing anywhere else: a sub-texel resampling
	# difference between the two shaders, not a difference in what is sampled.
	# Rotating the panorama by a hundredth of a turn — about 3.6 degrees, far
	# less than anyone would notice — takes it to 0.030.
	#
	# So 0.04 sits above the noise and below every wrong answer tested. `worst`
	# is printed and not asserted: one pixel on a hard cloud edge legitimately
	# differs by a lot, and a threshold on it would only ever measure contrast.
	if mean > 0.04:
		_failures.append(
			("the sky shader does NOT sample the panorama the way PanoramaSkyMaterial does "
			+ "(mean %.5f, worst %.5f). Every hour in art.json was authored against the "
			+ "built-in mapping; fix the uv before tuning anything.") % [mean, worst])


func _shoot(camera: Camera3D) -> Image:
	camera.make_current()
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


func _pose(camera: Camera3D, field: RefCounted) -> void:
	var ground: float = field.height_at(EYE.x, EYE.y)
	camera.global_position = Vector3(EYE.x, ground + EYE_H, EYE.y)
	camera.look_at(Vector3(TARGET.x, ground + 6.0, TARGET.y), Vector3.UP)
	var half := tan(deg_to_rad(FOV) * 0.5)
	camera.rotation = Vector3(
		-atan((0.5 - HORIZON) * 2.0 * half), camera.rotation.y, 0.0)


func _place_actor(player: Node3D, field: RefCounted, camera: Camera3D) -> void:
	if player == null:
		return
	player.global_position = Vector3(
		ACTOR.x, field.height_at(ACTOR.x, ACTOR.y) + ACTOR_CLEARANCE, ACTOR.y)
	var away := player.global_position - camera.global_position
	player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)


## Numbers beside every frame, for the one comparison MA-05 made and this
## milestone is answering: it measured the ground half's value variation at
## 0.082–0.113 against ~0.20 in the references, and said the single best frame
## was the golden-hour one. `low` is the 5th percentile — MA-05 measured 0.47 on
## `03-rise-overlook` and called it "literally no dark tone in the image".
##
## These are a cross-check on what is looked at, never a substitute for it. D18:
## a measurement that moves exactly as predicted while the picture does not
## improve is evidence that the measurement is not of the picture.
func _stats(image: Image) -> String:
	var values: Array[float] = []
	var ground: Array[float] = []
	var width := image.get_width()
	var height := image.get_height()
	for y in range(0, height, 3):
		for x in range(0, width, 3):
			var c := image.get_pixel(x, y)
			var v := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			values.append(v)
			if y > height / 2:
				ground.append(v)
	values.sort()
	var mean := 0.0
	for v in values:
		mean += v
	mean /= maxf(1.0, float(values.size()))
	var ground_mean := 0.0
	for v in ground:
		ground_mean += v
	ground_mean /= maxf(1.0, float(ground.size()))
	var spread := 0.0
	for v in ground:
		spread += (v - ground_mean) * (v - ground_mean)
	spread = sqrt(spread / maxf(1.0, float(ground.size())))
	var low: float = values[int(float(values.size()) * 0.05)]
	return "mean %.3f  p5 %.3f  ground sd %.3f" % [mean, low, spread]


func _report(written: Array[String]) -> void:
	print("")
	print("%d frames -> %s" % [written.size(), OUT_DIR])
	print("Software rendering. Frame times from this harness are NOT a performance measurement.")
	if not _failures.is_empty():
		print("")
		for line in _failures:
			print("FAIL: %s" % line)
		quit(1)
		return
	quit(0)
