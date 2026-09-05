extends SceneTree

## Cloudreach environment evidence: ten real production-scene, third-person views
## plus structural rendering counters and measured Windows frame pacing.
##
## Run with a real rendering driver, never `--headless`:
##   godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/capture_cloudreach_environment_correction.gd

const SCENE := preload("res://scenes/world/cloudreach_cliffs.tscn")
const OUT_DIR := "res://ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/shots"
const PERF_PATH := "res://ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/performance.json"
const SETTLE_FRAMES := 18
const SAMPLE_FRAMES := 24
const REPAIR_VIEWS := [
	{"name":"01-ila-clear-yard","stand":Vector2(-233,573),"target":Vector3(-211,188,555),"pitch_deg":-12.0},
	{"name":"02-lower-road-fiber","stand":Vector2(-280.4,875),"target":Vector3(-284,261,890),"pitch_deg":-12.0},
	{"name":"03-rope-approach","stand":Vector2(-540,1280),"target":Vector3(-468,338.25,1344),"pitch_deg":-6.0},
	{"name":"04-rope-far-abutment","stand":Vector2(-459,1352),"target":Vector3(-440,345,1370),"pitch_deg":-12.0},
	{"name":"05-stone-plateau-join","stand":Vector2(-230,1575),"target":Vector3(-190,393,1603),"pitch_deg":-10.0},
	{"name":"06-senn-clear-yard","stand":Vector2(-60,2220),"target":Vector3(-85,450,2220),"pitch_deg":-12.0},
	{"name":"07-voss-clear-yard","stand":Vector2(300,5100),"target":Vector3(320,1080,5116),"pitch_deg":-12.0}
]

## The stand is always on the authored route network. The target is a real
## landmark or region silhouette the player is meant to read from that point.
const VIEWS := [
	{"name": "08-upper-cliffhold-east-arrival", "stand": Vector2(-309.2, 3991.2), "target": Vector3(-340.0, 835.0, 3970.0), "pitch_deg": -5.0},
	{"name": "02-lower-cliffs-galefoot", "stand": Vector2(-280.0, 496.0), "target": Vector3(-280.0, 182.0, 520.0), "pitch_deg": -8.0},
	{"name": "07-fly-only-destination", "stand": Vector2(1110.0, 2927.0), "target": Vector3(1110.0, 1060.0, 2943.0), "pitch_deg": 5.0},
	{"name": "09-final-arena-space", "stand": Vector2(100.0, 5427.0), "target": Vector3(100.0, 1162.0, 5450.0), "pitch_deg": -10.0},
	{
		"name": "01-arrival-first-reveal",
		"stand": Vector2(0.0, -260.0),
		"target": Vector3(0.0, 150.0, -130.0),
		"pitch_deg": 3.0,
	},
	{
		"name": "02-broken-causeways",
		# Seven metres onto the tested continuous bridge approach: the landing
		# tree behind the former pivot occluded half the production camera frame.
		"stand": Vector2(-534.0, 1285.3333),
		"target": Vector3(-450.0, 342.0, 1360.0),
		"pitch_deg": 2.0,
	},
	{
		"name": "03-windscar-ravine",
		"stand": Vector2(-520.0, 2720.0),
		"target": Vector3(-300.0, 460.0, 3100.0),
		"pitch_deg": 3.0,
	},
	{
		"name": "04-high-roost-before-fly",
		"stand": Vector2(330.0, 3282.5),
		"target": Vector3(1110.0, 1060.0, 2940.0),
		"pitch_deg": 24.0,
	},
	{
		"name": "05-upper-cloudreach-cliffhold",
		"stand": Vector2(-400.0, 3890.0),
		"target": Vector3(-340.0, 830.0, 3970.0),
		"pitch_deg": 23.0,
	},
	{
		"name": "06-summit-final-approach",
		"stand": Vector2(100.0, 5290.0),
		"target": Vector3(100.0, 1215.0, 5350.0),
		"pitch_deg": 18.0,
	},
]


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var repair:="--route-repair" in OS.get_cmdline_user_args()
	var output_dir:="res://ralph/reports/CLOUDREACH-PRODUCTION-INTEGRATION-0905/route-repair" if repair else OUT_DIR
	var performance_path:=output_dir+"/performance.json" if repair else PERF_PATH
	if "--round3" in OS.get_cmdline_user_args():
		output_dir="res://ralph/reports/CLOUDREACH-ENV-CORRECTION-0904/round3/"+("repair" if repair else "shots")
		performance_path=output_dir+"/performance.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var game := root.get_node_or_null(^"Game")
	if game != null and game.has_method("reset_for_new_game"):
		game.call("reset_for_new_game")
		game.set("current_realm", "cloudreach")

	var world := SCENE.instantiate()
	root.add_child(world)
	current_scene = world
	for _frame in SETTLE_FRAMES:
		await process_frame
	var runtime:=world.get_node_or_null("CloudreachRuntime")
	if runtime==null or not bool(runtime.get("_mounted")) or world.get_node_or_null("ProceduralGroundCover")==null:
		push_error("Production assembly did not finish; refuse partial-scene visual evidence")
		quit(1)
		return

	var player := world.get_node_or_null(^"Player") as CharacterBody3D
	var rig := world.get_node_or_null(^"CameraRig") as SpringArm3D
	var camera := world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	var hud := world.get_node_or_null(^"PlaygroundHUD") as CanvasLayer
	var look := world.get_node_or_null(^"WorldLook")
	if player == null or rig == null or camera == null:
		push_error("Cloudreach capture: production player/camera shell is missing")
		quit(1)
		return
	player.set_physics_process(false)
	player.velocity = Vector3.ZERO
	# Environment evidence hides HUD only; runtime, terrain and camera are production.
	if hud != null:
		hud.visible = false
	if look != null:
		look.call("set_clock_frozen", true)
		look.call("apply_time", "day")
	rig.set_process(false)
	rig.set_physics_process(false)
	rig.spring_length = 5.8
	camera.fov = 70.0
	camera.make_current()
	root.size = Vector2i(1280, 800)
	root.content_scale_size=Vector2i(1920,1200)

	var rows: Array[Dictionary] = []
	var failures: Array[String] = []
	for raw_view: Variant in (REPAIR_VIEWS if repair else VIEWS):
		var view := raw_view as Dictionary
		var stand: Vector2 = view["stand"]
		var ground := float(world.call("ground_height_at", stand.x, stand.y))
		if is_nan(ground):
			failures.append("%s: authored stand has no ground" % str(view["name"]))
			continue
		var player_at := Vector3(stand.x, ground + 0.2, stand.y)
		var target: Vector3 = view["target"]
		player.global_position = player_at
		player.velocity = Vector3.ZERO
		var model := player.get_node_or_null(^"Model") as Node3D
		if model != null:
			var flat := target - player_at
			flat.y = 0.0
			if flat.length_squared() > 0.01:
				model.global_rotation.y = atan2(flat.x, flat.z)

		# Pose the production SpringArm exactly as ordinary exploration does:
		# horizontal yaw toward the landmark and the configured resting downward
		# pitch. A direct 3D `look_at()` aims upward at Cloudreach's high targets,
		# which also rotates the behind-camera end of a spring arm downward into
		# the route deck; that is a capture artefact, not a playable camera pose.
		rig.global_position = player_at + Vector3.UP * 1.55
		var sightline := target - player_at
		var yaw := atan2(-sightline.x, -sightline.z)
		rig.rotation = Vector3(deg_to_rad(float(view.get("pitch_deg", -10.0))), yaw, 0.0)
		rig.reset_physics_interpolation()
		player.reset_physics_interpolation()
		for _frame in SETTLE_FRAMES:
			await process_frame

		var draws := 0.0
		var primitives := 0.0
		var objects := 0.0
		var fps := 0.0
		var started := Time.get_ticks_usec()
		for _frame in SAMPLE_FRAMES:
			await RenderingServer.frame_post_draw
			draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			primitives += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			objects += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
			fps += Performance.get_monitor(Performance.TIME_FPS)
		var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
		var image := root.get_texture().get_image()
		var path := "%s/%s.png" % [output_dir, str(view["name"])]
		if image == null or image.save_png(path) != OK:
			failures.append("%s: viewport capture failed" % str(view["name"]))
			continue
		var n := float(SAMPLE_FRAMES)
		rows.append({
			"view": str(view["name"]),
			"stand": [player_at.x, player_at.y, player_at.z],
			"target": [target.x, target.y, target.z],
			"draw_calls": roundi(draws / n),
			"primitives": roundi(primitives / n),
			"objects": roundi(objects / n),
			"reported_fps": snappedf(fps / n, 0.1),
			"measured_frame_ms": snappedf(elapsed_ms / n, 0.01),
		})
		if "--sustained" in OS.get_cmdline_user_args() and str(view.name) in ["01-arrival-first-reveal","02-lower-cliffs-galefoot","09-final-arena-space"]:
			rows[-1]["sustained_static_view_10_seconds"]=await _sustained_sample()
		print("CLOUDREACH CAPTURE %s -> %s" % [str(view["name"]), path])

	var perf_file := FileAccess.open(performance_path, FileAccess.WRITE)
	if perf_file == null:
		failures.append("could not write %s" % performance_path)
	else:
		perf_file.store_string(JSON.stringify({
			"captured_at_utc": Time.get_datetime_string_from_system(true),
			"engine": Engine.get_version_info().get("string", "unknown"),
			"display_server": DisplayServer.get_name(),
			"video_adapter": RenderingServer.get_video_adapter_name(),
			"resolution": [root.size.x, root.size.y],
			"sample_frames_per_view": SAMPLE_FRAMES,
			"views": rows,
		}, "  "))
		perf_file.close()

	if not failures.is_empty():
		for failure in failures:
			push_error("Cloudreach capture: %s" % failure)
		quit(1)
		return
	print("CLOUDREACH CAPTURE OK %d frames; performance -> %s" % [rows.size(), performance_path])
	quit(0)


func _sustained_sample() -> Dictionary:
	var frame_times: Array[float]=[]
	var start:=Time.get_ticks_usec()
	var previous:=start
	var maximum_draws:=0
	var maximum_primitives:=0
	while Time.get_ticks_usec()-start<10000000:
		await RenderingServer.frame_post_draw
		var now:=Time.get_ticks_usec()
		frame_times.append(float(now-previous)/1000.0)
		previous=now
		maximum_draws=maxi(maximum_draws,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		maximum_primitives=maxi(maximum_primitives,int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	frame_times.sort()
	var count:=frame_times.size()
	return {"seconds":float(previous-start)/1000000.0,"frames":count,"mean_ms":float(previous-start)/1000.0/count,
		"p50_ms":frame_times[int(count*0.50)],"p95_ms":frame_times[int(count*0.95)],"p99_ms":frame_times[int(count*0.99)],
		"maximum_ms":frame_times[-1],"maximum_draw_calls":maximum_draws,"maximum_primitives":maximum_primitives,
		"context":"Real Windows GTX1060 Compatibility static production view; not Ally acceptance or continuous-play frame pacing."}
