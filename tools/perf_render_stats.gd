extends SceneTree

## PERF-ROG / OP23-01, the render half. What the RenderingServer is actually
## asked to draw at each site.
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/perf_render_stats.gd -- --label=lod-on
##
## NEVER add `--headless`. Two separate reasons, and both matter here:
## `--headless` hangs forever in combination with a real rendering driver
## (ralph/conventions.md, the single most expensive trap in this repo), and
## even if it did not, Godot's Dummy driver reports zero for every RENDER_*
## monitor -- which is exactly the number this tool exists to read.
##
## The counters are structural, not device-specific: draw calls and primitives
## submitted per frame are the same numbers a ROG Ally's GPU would be handed.
## llvmpipe's own frame TIME on this box is meaningless and is not reported.
##
## Toggle `scatter_lod_ranges` in data/config/performance.json between runs to
## get the two states this branch compares.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const RESETTLE_FRAMES := 180
const SAMPLE_FRAMES := 30

## Elevated views chosen to have DISTANT scatter in frame -- the pond and
## open-field views `capture_lod_before_after.gd` renders are the visual
## contract and are close-in by design, so neither can show what a distance
## cutoff does. Each entry is [x, z, height above ground, yaw degrees].
const VIEWS := {
	"village_high": [10.0, -10.0, 24.0, 180.0],
	"band1_open": [0.0, 700.0, 24.0, 0.0],
	"band4_ironwood": [0.0, 6000.0, 28.0, 0.0],
	"stronghold_approach": [0.0, 7420.0, 26.0, 0.0],
}

var _label := ""
## T1-HALL-REBUILD (2026-08-30). `--views=a,b` restricts the run to a subset.
## The four views cost 240 settle + 180 resettle each + 30 sample frames, and
## on llvmpipe that is the difference between a run that finishes in a session
## and one a lane kills at 40 minutes with nothing printed (which is exactly
## what happened to the first Hall build pass, leaving the design's own
## draw-call budget unverified). A single-view run measures the one counter the
## Hall's budget is written against in a fraction of the time; the default is
## still all four, so nothing that already calls this tool changes.
var _views: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--label="):
			_label = a.substr("--label=".length())
		elif a.begins_with("--views="):
			for v in a.substr("--views=".length()).split(",", false):
				_views.append(v.strip_edges())

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	var camera: Camera3D = world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	if rig == null or camera == null:
		print("PERF-RENDER FAIL: no CameraRig/Camera3D")
		quit(1)
		return
	rig.set_process(false)
	rig.set_physics_process(false)

	print("=== PERF-ROG render stats (%s) ===" % ("unlabelled" if _label == "" else _label))
	print("driver=%s  adapter=%s" % [DisplayServer.get_name(), RenderingServer.get_video_adapter_name()])
	print("scatter_lod_ranges=%s" % str(_lod_setting()))
	print("")
	print("%-22s %12s %14s %12s" % ["view", "draw calls", "primitives", "objects"])

	for name: String in VIEWS.keys():
		if not _views.is_empty() and not _views.has(name):
			continue
		var spec: Array = VIEWS[name]
		var ground := 0.0
		if world.has_method("ground_height_at"):
			ground = float(world.call("ground_height_at", float(spec[0]), float(spec[1])))
		if is_nan(ground):
			ground = 0.0
		var spot := Vector3(float(spec[0]), ground + float(spec[2]), float(spec[1]))
		# The player carries Terrain3D's collision/streaming bubble with it, so
		# it goes where the camera goes or the camera looks at unbuilt ground.
		if player != null:
			player.global_position = Vector3(spot.x, ground + 1.5, spot.z)
		camera.global_position = spot
		camera.global_rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(float(spec[3])), 0.0)
		for i in RESETTLE_FRAMES:
			await physics_frame

		var draws := 0.0
		var prims := 0.0
		var objs := 0.0
		for i in SAMPLE_FRAMES:
			await RenderingServer.frame_post_draw
			draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			prims += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			objs += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		var n := float(SAMPLE_FRAMES)
		print("%-22s %12.0f %14.0f %12.0f" % [name, draws / n, prims / n, objs / n])

	quit(0)


func _lod_setting() -> Variant:
	var f := FileAccess.open("res://data/config/performance.json", FileAccess.READ)
	if f == null:
		return "(no config)"
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return (parsed as Dictionary).get("scatter_lod_ranges", "(unset)") if parsed is Dictionary else "(bad config)"
