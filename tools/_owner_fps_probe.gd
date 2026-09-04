extends SceneTree
## KICKOFF (docs/acceptance/KICKOFF_RUN.md). A real frame-rate number from a
## real GPU: stand at named sites in the shipped world with the shipped
## config and count frames for a fixed number of seconds of wall clock.
##
##   godot --path . --rendering-driver opengl3 --resolution 1280x800 \
##     --script tools/_owner_fps_probe.gd -- --seconds=20 --out=fps.json
##
## NEVER with `--headless` and a real rendering driver. NEVER under
## `--write-movie`: movie mode renders every frame regardless of speed and the
## number this reports would then be the encoder, not the game.
##
## tools/perf_render_stats.gd reports draw calls and primitives, which are the
## same on every machine; it deliberately reports no frame time because the
## containers it runs in rasterise in software. This is the other half, and it
## is only meaningful on hardware. On the ROG Ally it is the number every
## "~10 FPS with grass on" report has been waiting for.
##
## Sites are eye-level standing spots along the route, one per band plus the
## village, and the same elevated views perf_render_stats.gd uses so the two
## tools can be lined up. `--sites=a,b` restricts the run.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const SETTLE_AFTER_MOVE := 90

## [x, z, eye height above ground, yaw degrees]. Yaw 0 faces -Z (north, back
## toward the village); 180 faces +Z (south, the way the chapter goes).
const SITES := {
	"village_square_eye": [10.0, -10.0, 1.7, 180.0],
	"band1_open_eye": [0.0, 700.0, 1.7, 180.0],
	"pond_pocket_eye": [-387.0, 442.0, 1.7, 180.0],
	"band2_quarry_eye": [403.0, 1794.0, 1.7, 180.0],
	"band4_ironwood_eye": [0.0, 6000.0, 1.7, 180.0],
	"hall_approach_eye": [0.0, 7420.0, 1.7, 180.0],
	"village_high": [10.0, -10.0, 24.0, 180.0],
	"band1_open": [0.0, 700.0, 24.0, 0.0],
	"hall_approach": [0.0, 7420.0, 26.0, 180.0],
}

var _seconds := 20.0
var _out := ""
var _sites: Array[String] = []


func _init() -> void:
	_run()


func _run() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--seconds="):
			_seconds = maxf(3.0, float(a.substr("--seconds=".length())))
		elif a.begins_with("--out="):
			_out = a.substr("--out=".length())
		elif a.begins_with("--sites="):
			for s in a.substr("--sites=".length()).split(",", false):
				_sites.append(s.strip_edges())

	if OS.has_feature("movie"):
		print("FPS-PROBE FAIL: running under --write-movie; frame times would measure the encoder")
		quit(2)
		return

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node = world.get_node_or_null(^"CameraRig")
	if rig != null:
		rig.set_process(false)
		rig.set_physics_process(false)
	var camera := Camera3D.new()
	camera.fov = 70.0
	camera.far = 2000.0
	world.add_child(camera)
	camera.make_current()
	var terrain: Node = world.get_node_or_null(^"Terrain")
	if terrain != null and terrain.has_method("set_camera"):
		terrain.call("set_camera", camera)
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var field: RefCounted = HEIGHTFIELD.new()

	var grass_enabled := "unknown"
	var gf := FileAccess.open("res://data/config/grass_field.json", FileAccess.READ)
	if gf != null:
		var parsed: Variant = JSON.parse_string(gf.get_as_text())
		if parsed is Dictionary:
			grass_enabled = str((parsed as Dictionary).get("enabled", "unset"))

	var report := {
		"adapter": RenderingServer.get_video_adapter_name(),
		"driver": DisplayServer.get_name(),
		"resolution": [root.get_visible_rect().size.x, root.get_visible_rect().size.y],
		"grass_field_enabled": grass_enabled,
		"seconds_per_site": _seconds,
		"sites": {},
	}
	print("=== FPS probe: %s via %s, grass_field enabled=%s ===" % [report["adapter"], report["driver"], grass_enabled])
	print("%-22s %8s %8s %8s %8s" % ["site", "fps_avg", "ms_p95", "ms_max", "fps_1%low"])

	for name: String in SITES.keys():
		if not _sites.is_empty() and not _sites.has(name):
			continue
		var spec: Array = SITES[name]
		var x := float(spec[0])
		var z := float(spec[1])
		var ground: float = field.height_at(x, z)
		camera.global_position = Vector3(x, ground + float(spec[2]), z)
		camera.rotation = Vector3(deg_to_rad(-6.0), deg_to_rad(float(spec[3])), 0.0)
		if player != null:
			player.global_position = Vector3(x, ground + 0.4, z + 2.0)
		for i in SETTLE_AFTER_MOVE:
			await physics_frame

		var samples: Array[float] = []
		var started := Time.get_ticks_msec()
		var last := started
		while Time.get_ticks_msec() - started < int(_seconds * 1000.0):
			await process_frame
			var now := Time.get_ticks_msec()
			samples.append(float(now - last))
			last = now
		samples.sort()
		var sum := 0.0
		for v in samples:
			sum += v
		var avg_ms := sum / maxf(1.0, float(samples.size()))
		var p95 := samples[clampi(int(float(samples.size()) * 0.95), 0, samples.size() - 1)]
		var worst_start := clampi(int(float(samples.size()) * 0.99), 0, samples.size() - 1)
		var worst_sum := 0.0
		for i in range(worst_start, samples.size()):
			worst_sum += samples[i]
		var low1 := 1000.0 / maxf(0.001, worst_sum / float(samples.size() - worst_start))
		var site := {
			"fps_avg": snappedf(1000.0 / maxf(0.001, avg_ms), 0.1),
			"frame_ms_avg": snappedf(avg_ms, 0.01),
			"frame_ms_p95": snappedf(p95, 0.01),
			"frame_ms_max": snappedf(samples[samples.size() - 1], 0.01),
			"fps_1pct_low": snappedf(low1, 0.1),
			"frames": samples.size(),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		}
		var sites: Dictionary = report["sites"]
		sites[name] = site
		print("%-22s %8.1f %8.2f %8.2f %8.1f" % [name, site["fps_avg"], site["frame_ms_p95"], site["frame_ms_max"], site["fps_1pct_low"]])

	if _out != "":
		var f := FileAccess.open(_out, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(report, "  "))
			f.close()
			print("-> %s" % _out)
	quit(0)
