extends SceneTree

## GOLDEN-HOUR. The decisive test named in
## ralph/reports/finding-golden-hour-black-frame.md.
##
## The survey's `05-spawn-low-sun` renders pure black while `01-spawn-outward`
## -- same eye, same target, same actor -- renders correctly. The only stated
## difference is `"time": "golden"` against `"time": "day"`. Three hypotheses
## were already eliminated on paper (truncated run, malformed preset, panorama
## shader recompile); the remaining three cannot be told apart by reading, so
## this renders the SAME viewpoint at day/golden/night under four different
## settle regimes in one run and records what the engine actually held at the
## shutter.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/_diag_golden_hour.gd
##
## The four regimes, per time of day:
##   survey   -- byte-for-byte the survey's own timing (20 physics + 4 process).
##   immediate-- one process frame. Almost no wall-clock passes.
##   generous -- the survey's timing plus 10 more process frames.
##   frozen   -- the survey's timing with WorldLook._process() DISABLED.
##
## `frozen` is the discriminator. world_look.gd's apply_time() docstring still
## claims it is "the ONE place _elapsed_seconds is written outside _process,
## so tools/survey.gd calling this directly cannot be undone by the very next
## _process() tick" -- but that was written before OP23-05 added the continuous
## blend, which now re-derives sun/sky/environment from the LIVE hour every
## BLEND_INTERVAL seconds. Under llvmpipe a single frame costs seconds of real
## time, so a handful of settle frames is hours of in-game clock. If `frozen`
## renders and `survey` does not, the pin is being overwritten and this is a
## harness defect, not an art one.
##
## Every shot also records the state actually on the nodes at the shutter --
## hour, live preset, sun pitch/energy, exposure, ambient, colour grade -- so
## the frames do not have to be trusted on their own. See this viewpoint's
## history in world_look.gd: it has been wrong in plausible-looking ways before.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const OUT_DIR := "res://shots/golden_diag"

const SETTLE_FRAMES := 240
const FOV := 70.0

## Survey viewpoint 05-spawn-low-sun, copied exactly (which is also 01's eye,
## target and actor -- that shared framing is the whole point of the finding).
const EYE := Vector2(-9.0, -7.0)
const EYE_H := 2.2
const TARGET := Vector2(-140.0, 145.0)
const TARGET_H := 8.0
const ACTOR := Vector2(-15.0, -1.0)
const ACTOR_CLEARANCE := 0.4
## 05's horizon. 01 uses 0.28; held at 05's value so this is 05's frame.
const HORIZON := 0.34

## tools/survey.gd's own settle, reproduced.
const SURVEY_PHYSICS := 20
const SURVEY_PROCESS := 4
## What "a generous settle" means here, on top of the survey's own.
const EXTRA_PROCESS := 10

## time-of-day name, regime. Order matters: `golden` is captured both in the
## middle and dead last, because being the survey's final viewpoint is the one
## other thing that distinguishes 05 from 01.
const TRIALS := [
	{"time": "day", "regime": "survey"},
	{"time": "day", "regime": "immediate"},
	{"time": "day", "regime": "generous"},
	{"time": "day", "regime": "frozen"},
	{"time": "golden", "regime": "survey"},
	{"time": "golden", "regime": "immediate"},
	{"time": "golden", "regime": "generous"},
	{"time": "golden", "regime": "frozen"},
	{"time": "night", "regime": "survey"},
	{"time": "night", "regime": "immediate"},
	{"time": "night", "regime": "generous"},
	{"time": "night", "regime": "frozen"},
	{"time": "golden", "regime": "survey-last"},
]

var _look: Node = null
var _sun: DirectionalLight3D = null
var _env: Environment = null
var _cycle: RefCounted = null


func _init() -> void:
	_run()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	var packed: PackedScene = load(SCENE)
	if packed == null:
		push_error("could not load %s" % SCENE)
		quit(1)
		return

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

	var camera := Camera3D.new()
	camera.fov = FOV
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()

	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	else:
		print("WARN: no Terrain node with set_camera")

	_look = world.get_node_or_null(^"WorldLook")
	if _look == null:
		push_error("no WorldLook node; this test cannot say anything")
		quit(1)
		return
	_cycle = _look.get("_cycle")
	_sun = _look.get_node_or_null(_look.get("sun_path")) as DirectionalLight3D
	var holder: WorldEnvironment = \
		_look.get_node_or_null(_look.get("environment_path")) as WorldEnvironment
	if holder != null:
		_env = holder.environment

	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	# Pose once. Nothing below moves the camera or the actor, so every frame in
	# this run is the same shot with a different time of day on it.
	var eye_ground: float = field.height_at(EYE.x, EYE.y)
	var target_ground: float = field.height_at(TARGET.x, TARGET.y)
	camera.global_position = Vector3(EYE.x, eye_ground + EYE_H, EYE.y)
	camera.look_at(Vector3(TARGET.x, target_ground + TARGET_H, TARGET.y), Vector3.UP)
	camera.rotation = Vector3(_pitch_for_horizon(HORIZON), camera.rotation.y, 0.0)
	if player != null:
		player.global_position = Vector3(
			ACTOR.x, field.height_at(ACTOR.x, ACTOR.y) + ACTOR_CLEARANCE, ACTOR.y)
		var away := player.global_position - camera.global_position
		player.rotation = Vector3(0.0, atan2(away.x, away.z) + 0.35, 0.0)

	print("")
	print("GOLDEN-HOUR decisive test. Viewpoint = survey 05-spawn-low-sun.")
	print("day_length_seconds = %.1f, so one in-game hour is %.1f real seconds."
		% [float(_cycle.get("day_length_seconds")), float(_cycle.get("day_length_seconds")) / 24.0])
	print("")

	var index := 0
	for entry: Variant in TRIALS:
		var trial: Dictionary = entry
		index += 1
		await _trial(index, str(trial["time"]), str(trial["regime"]))

	print("")
	print("%d frames -> %s" % [TRIALS.size(), OUT_DIR])
	print("Software rendering (D06/D01). Frame times here are NOT performance.")
	quit(0)


func _trial(index: int, time_name: String, regime: String) -> void:
	# Always start from a live clock again, so a previous `frozen` trial cannot
	# quietly make the next one look better than the survey's real conditions.
	_look.set_process(true)

	var started := Time.get_ticks_msec()
	_look.call("apply_time", time_name)
	var pinned_hour := _hour()
	if regime == "frozen":
		# The pin, held. Nothing else in the trial differs from `survey`.
		_look.set_process(false)

	if regime == "immediate":
		await process_frame
	else:
		for i in SURVEY_PHYSICS:
			await physics_frame
		for i in SURVEY_PROCESS:
			await process_frame
		if regime == "generous":
			for i in EXTRA_PROCESS:
				await process_frame
	await RenderingServer.frame_post_draw

	var waited := float(Time.get_ticks_msec() - started) / 1000.0
	var image := root.get_texture().get_image()
	if image == null:
		print("FAIL %s/%s: viewport returned no image" % [time_name, regime])
		return

	var name := "%02d-%s-%s" % [index, time_name, regime]
	var path := "%s/%s.png" % [OUT_DIR, name]
	var error := image.save_png(path)
	if error != OK:
		print("FAIL %s: save_png failed (%d)" % [name, error])
		return

	var flat := _flatness(image)
	var verdict := "BLACK/FLAT" if flat < 0.01 else "rendered"
	print("%-26s spread %.4f  %s" % [name, flat, verdict])
	print("    pinned hour %.2f -> hour at shutter %.2f   (%.1fs of wall clock)"
		% [pinned_hour, _hour(), waited])
	print("    WorldLook.time_of_day()=%s   live preset=%s   %s"
		% [str(_look.call("time_of_day")), _preset_now(), _interp_now()])
	print("    %s" % _sun_state())
	print("    %s" % _env_state())


func _hour() -> float:
	if _cycle == null:
		return -1.0
	return float(_cycle.call("hour_at", float(_look.get("_elapsed_seconds"))))


func _preset_now() -> String:
	if _cycle == null:
		return "?"
	return str(_cycle.call("preset_at", _hour()))


func _interp_now() -> String:
	if _cycle == null:
		return ""
	var i: Dictionary = _cycle.call("interpolate_at", _hour())
	return "blend %s->%s t=%.3f" % [str(i.get("from")), str(i.get("to")), float(i.get("t"))]


func _sun_state() -> String:
	if _sun == null:
		return "sun: NOT FOUND"
	return "sun: pitch %.1fdeg yaw %.1fdeg energy %.3f colour %s shadow_opacity %.2f" % [
		rad_to_deg(_sun.rotation.x), rad_to_deg(_sun.rotation.y),
		_sun.light_energy, _sun.light_color.to_html(false), _sun.shadow_opacity]


func _env_state() -> String:
	if _env == null:
		return "env: NOT FOUND"
	var grade := "off"
	if _env.adjustment_enabled:
		grade = "bright %.2f contrast %.2f sat %.2f" % [
			_env.adjustment_brightness, _env.adjustment_contrast, _env.adjustment_saturation]
	var sky_kind := "none"
	if _env.sky != null:
		sky_kind = _env.sky.sky_material.get_class() if _env.sky.sky_material != null else "null"
	return "env: exposure %.3f white %.2f ambient %.3f (%s, sky_contrib %.2f) grade[%s] sky[%s] fog %.5f %s" % [
		_env.tonemap_exposure, _env.tonemap_white, _env.ambient_light_energy,
		_env.ambient_light_color.to_html(false), _env.ambient_light_sky_contribution,
		grade, sky_kind, _env.fog_density, _env.fog_light_color.to_html(false)]


func _pitch_for_horizon(fraction: float) -> float:
	var half := tan(deg_to_rad(FOV) * 0.5)
	return -atan((0.5 - clampf(fraction, 0.05, 0.95)) * 2.0 * half)


## tools/survey.gd's own measure, copied so the number here and the number the
## survey's critic failed on are the same number.
func _flatness(image: Image) -> float:
	var width := image.get_width()
	var height := image.get_height()
	var step := maxi(1, width / 64)
	var lowest := Vector3(INF, INF, INF)
	var highest := Vector3(-INF, -INF, -INF)
	for y in range(0, height, step):
		for x in range(0, width, step):
			var c := image.get_pixel(x, y)
			lowest = Vector3(minf(lowest.x, c.r), minf(lowest.y, c.g), minf(lowest.z, c.b))
			highest = Vector3(maxf(highest.x, c.r), maxf(highest.y, c.g), maxf(highest.z, c.b))
	return (highest - lowest).length()
