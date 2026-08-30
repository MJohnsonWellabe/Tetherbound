extends SceneTree

## T1-PERF (2026-08-30). The missing ROG budget input: draw calls, primitives,
## objects AND light/shadow counts, at every authored location the chapter
## actually asks the ROG Ally to render -- village, all five Meadows bands,
## and the stronghold/Meadows Hall -- at day AND night, since night adds
## lights on top of the same geometry and is the likely worst case.
##
## Extends `tools/perf_render_stats.gd`'s proven method (same RenderingServer
## monitors, same "NEVER --headless with a rendering driver" trap, same
## Terrain3D-follows-the-player mechanism) rather than replacing it --
## `stronghold_approach` here is the identical camera pose so its numbers
## are directly comparable to HALL_DESIGN_2026-08-30.md's measured baseline
## (1069 draw calls / 25.8M primitives / 1381 objects).
##
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . \
##     --rendering-driver opengl3 --resolution 1280x720 \
##     --script tools/perf_site_survey.gd -- --label=T1-PERF-baseline
##
## Optional: --sites=village_high,band4_ironwood  --times=day  --json=out.json
## (site names are the VIEWS keys below, not band ids -- "village" alone is
## silently ignored and the tool falls back to running every site, since an
## empty --sites match reads the same as "no filter given")
##
## LIGHT COUNTING METHOD, stated plainly because it is the one number this
## tool invents a method for rather than reading from an engine monitor.
## Godot's headless Performance singleton has no "active light count"
## monitor -- RENDER_TOTAL_* only counts draw calls/primitives/objects, not
## lights, and nothing in RenderingServer exposes a per-frame visible-light
## count outside the editor's own debug overlay. So this counts every
## OmniLight3D/SpotLight3D in the whole tree whose OWN authored range
## (omni_range / spot_range) reaches the sample point -- "could this light
## plausibly be shading something standing here" -- which is a real,
## reproducible number from the light's own authored data, not a frustum or
## occlusion count. It is reported as exactly that: a reachability count,
## not a GPU-verified active count. Shadow-casting is a real boolean read
## per light (`shadow_enabled`), not estimated.
##
## NEVER add `--headless` here (hangs forever per ralph/conventions.md) --
## this tool reads RENDER_* monitors, unlike `tools/perf_scatter_density.gd`,
## which is headless-safe because it reads no rendering monitor at all.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const SETTLE_FRAMES := 240
const RESETTLE_FRAMES := 180
const TIME_SETTLE_FRAMES := 20
## Half of `perf_render_stats.gd`'s 30: this tool pays RESETTLE_FRAMES twice
## per site (once per time-of-day) rather than once, so trims the cheaper
## knob to keep total runtime sane across 7 sites x 2 times. Draw
## calls/primitives at a settled camera pose do not meaningfully drift frame
## to frame (no camera motion, no LOD threshold being crossed) -- SAMPLE
## exists to average out incidental per-frame noise, not to wait out a
## transient, so halving it does not trade away validity the way cutting
## RESETTLE_FRAMES would.
const SAMPLE_FRAMES := 15

## Elevated views with distant scatter in frame, same convention as
## `perf_render_stats.gd::VIEWS` (whose four entries are reused verbatim --
## `village_high`/`band1_open`/`band4_ironwood`/`stronghold_approach` are
## copied so this tool's numbers for those four are the same measurement,
## not a second guess at it). `band2`/`band3`/`band5` are new: sited at the
## same x/z `tools/perf_profile.gd::SITES` already uses for the CPU-cost
## profile (so a lane cross-referencing the two tools is looking at the same
## points on the map), band5 at HALL_DESIGN_2026-08-30.md's own H-01 stand
## (0,7160) -- "cresting into Band 5" -- since no other authored band-5
## viewpoint exists yet. Each entry is [x, z, height above ground, yaw deg].
const VIEWS := {
	"village_high": [10.0, -10.0, 24.0, 180.0],
	"band1_open": [0.0, 700.0, 24.0, 0.0],
	"band2_stone": [0.0, 2200.0, 26.0, 0.0],
	"band3_river": [0.0, 4000.0, 26.0, 0.0],
	"band4_ironwood": [0.0, 6000.0, 28.0, 0.0],
	"band5_approach": [0.0, 7160.0, 26.0, 0.0],
	"stronghold_approach": [0.0, 7420.0, 26.0, 0.0],
}

## T1-LIGHT (landed on `main` the same day this tool was written) added the
## Burrow Warrens den's first REAL shadow-casting light
## (`data/config/burrow_warrens.json` guardian key light, `"shadow": true`) --
## exactly the new cost the coordinator flagged as untested by this tool's
## exterior-only VIEWS above. An interior chamber cannot use the
## ground-height + fixed-pitch convention VIEWS relies on (Terrain3D's
## heightfield is the HILL the cave is buried under, not the cave floor), so
## this is a second, small set of views with a pre-resolved eye/look-at pair
## instead of an x/z + ground offset. Coordinates read once via
## `tools/_probe_warrens_markers.gd` (`BurrowWarrens.marker("den")`/
## `marker("guardian")`) rather than hand-derived from the site's yaw/offset
## math, which is exactly the kind of arithmetic this repo's own
## `stronghold.gd` review already warns is easy to get backwards. Re-run that
## probe and update the two Vector3 literals below if the Warrens are ever
## re-sited.
const ABSOLUTE_VIEWS := {
	"warrens_den": {
		"eye": Vector3(-385.28, 4.1484 + 1.7, 2638.28 - 3.0),
		"look_at": Vector3(-385.99, 4.1484 + 1.4, 2643.23),
	},
}

## Times of day to sample. "day" is the design baseline everything else is
## measured against; "night" is named in the T1-PERF brief as the likely
## worst case because it ADDS lights (braziers, window glow, occupation
## conduit) on top of the same day geometry rather than removing anything.
const TIMES: Array[String] = ["day", "night"]

var _label := ""
var _site_names: Array[String] = []
var _times: Array[String] = []
var _json_path := ""


func _init() -> void:
	_run()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--label="):
			_label = a.substr("--label=".length())
		elif a.begins_with("--sites="):
			for s in a.substr("--sites=".length()).split(",", false):
				var name := s.strip_edges()
				if VIEWS.has(name):
					_site_names.append(name)
				else:
					print("PERF WARN: unknown site '%s' ignored" % name)
		elif a.begins_with("--times="):
			_times.clear()
			for t in a.substr("--times=".length()).split(",", false):
				_times.append(t.strip_edges())
		elif a.begins_with("--json="):
			_json_path = a.substr("--json=".length())
	if _site_names.is_empty():
		for name: String in VIEWS.keys():
			_site_names.append(name)
	if _times.is_empty():
		for t: String in TIMES:
			_times.append(t)


func _run() -> void:
	_parse_args()

	var world: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(world)
	for i in SETTLE_FRAMES:
		await physics_frame

	var rig: Node3D = world.get_node_or_null(^"CameraRig") as Node3D
	var camera: Camera3D = world.get_node_or_null(^"CameraRig/Camera3D") as Camera3D
	var player: Node3D = world.get_node_or_null(^"Player") as Node3D
	var look: Node = world.get_node_or_null(^"WorldLook")
	var weather: Node = world.get_node_or_null(^"WorldWeather")
	if rig == null or camera == null:
		print("PERF-SITE-SURVEY FAIL: no CameraRig/Camera3D")
		quit(1)
		return
	rig.set_process(false)
	rig.set_physics_process(false)
	if weather != null:
		weather.set_process(false)
		weather.set_physics_process(false)
	if look != null:
		look.set_process(false)
		look.set_physics_process(false)
		if look.has_method("set_weather"):
			look.call("set_weather", {})

	print("=== T1-PERF site survey (%s) ===" % ("unlabelled" if _label == "" else _label))
	print("driver=%s  adapter=%s" % [DisplayServer.get_name(), RenderingServer.get_video_adapter_name()])
	print("sites=%s  times=%s" % [", ".join(_site_names), ", ".join(_times)])
	print("light-reachability method: OmniLight3D/SpotLight3D whose own omni_range/")
	print("spot_range covers the sample point -- a real reachability count, not a")
	print("frustum/occlusion-verified 'active this frame' count (see file header).")
	print("")
	print("%-22s %-6s %10s %14s %10s %8s %8s" % [
		"view", "time", "draw calls", "primitives", "objects", "lights", "shadowed"])

	var report: Dictionary = {}
	for name: String in _site_names:
		var spec: Array = VIEWS[name]
		var ground := 0.0
		if world.has_method("ground_height_at"):
			ground = float(world.call("ground_height_at", float(spec[0]), float(spec[1])))
		if is_nan(ground):
			ground = 0.0
		var spot := Vector3(float(spec[0]), ground + float(spec[2]), float(spec[1]))
		if player != null:
			player.global_position = Vector3(spot.x, ground + 1.5, spot.z)
		camera.global_position = spot
		camera.global_rotation = Vector3(deg_to_rad(-8.0), deg_to_rad(float(spec[3])), 0.0)
		report[name] = await _measure_and_print(world, look, name, spot)

	for name: String in ABSOLUTE_VIEWS.keys():
		var av: Dictionary = ABSOLUTE_VIEWS[name]
		var eye: Vector3 = av["eye"]
		var look_at: Vector3 = av["look_at"]
		if player != null:
			player.global_position = eye
		camera.global_position = eye
		camera.look_at(look_at, Vector3.UP)
		report[name] = await _measure_and_print(world, look, name, eye)

	if _json_path != "":
		var f := FileAccess.open(_json_path, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(report, "  "))
			f.close()
			print("\nwrote %s" % _json_path)

	quit(0)


## Shared by the VIEWS loop (ground-relative, fixed pitch/yaw, already posed
## by the caller) and the ABSOLUTE_VIEWS loop (pre-resolved eye/look-at,
## already posed by the caller) -- both just need "sit here RESETTLE_FRAMES,
## then sample draw calls/primitives/objects/lights at each time of day".
func _measure_and_print(world: Node, look: Node, name: String, spot: Vector3) -> Dictionary:
	for i in RESETTLE_FRAMES:
		await physics_frame

	var site_report: Dictionary = {}
	for time_name: String in _times:
		if look != null:
			look.call("apply_time", time_name)
		for i in TIME_SETTLE_FRAMES:
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

		var light_counts := _lights_reaching(world, spot)
		print("%-22s %-6s %10.0f %14.0f %10.0f %8d %8d" % [
			name, time_name, draws / n, prims / n, objs / n,
			light_counts["total"], light_counts["shadowed"]])

		site_report[time_name] = {
			"draw_calls": draws / n,
			"primitives": prims / n,
			"objects": objs / n,
			"lights_reaching": light_counts["total"],
			"lights_shadowed": light_counts["shadowed"],
		}
	return site_report


## Every OmniLight3D/SpotLight3D in the tree whose own authored range covers
## `spot` -- see the file header for why this is a reachability count, not a
## GPU-verified active-light count. `visible` lights only: a light some
## builder switched off (e.g. `torch.visible = interior` in the judge capture
## tools) correctly does not count.
func _lights_reaching(world: Node, spot: Vector3) -> Dictionary:
	var total := 0
	var shadowed := 0
	var omnis: Array[Node] = world.find_children("*", "OmniLight3D", true, false)
	for n: Node in omnis:
		var l := n as OmniLight3D
		if not l.is_visible_in_tree():
			continue
		if l.global_position.distance_to(spot) <= l.omni_range:
			total += 1
			if l.shadow_enabled:
				shadowed += 1
	var spots: Array[Node] = world.find_children("*", "SpotLight3D", true, false)
	for n: Node in spots:
		var l := n as SpotLight3D
		if not l.is_visible_in_tree():
			continue
		if l.global_position.distance_to(spot) <= l.spot_range:
			total += 1
			if l.shadow_enabled:
				shadowed += 1
	return {"total": total, "shadowed": shadowed}
