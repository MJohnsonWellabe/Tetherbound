extends SceneTree

## PERF-ROG / OP23-01. Rank the per-frame costs of the real Meadows world at
## named sites, so "feels like ten frames per second on the ROG Ally" becomes
## a list of numbers instead of a list of guesses.
##
##   godot --headless --path . --script tools/perf_profile.gd
##   godot --headless --path . --script tools/perf_profile.gd -- --sites=village,band4
##   godot --headless --path . --script tools/perf_profile.gd -- --frames=180 --json=out.json
##
## WHAT THIS CAN AND CANNOT MEASURE, stated plainly because the whole value of
## this tool is that its numbers are not misread.
##
## No container in this project has ROG Ally hardware. Nothing here is a device
## frame rate and nothing here should ever be quoted as one. What a container
## CAN measure, and what the owner's report actually needs, is the CPU-side
## per-frame work the game asks for at a given place in the world -- because
## that work is hardware-independent in SHAPE (an O(n) sweep over 143k
## placements is an O(n) sweep on any machine) even though its absolute cost is
## not. A handheld's small cores make GDScript roughly 3-6x slower than this
## box; the RANKING between subsystems survives that scaling, which is why this
## reports a ranking and not a verdict.
##
## `--headless` is correct here and is not the documented trap. Godot's Dummy
## rendering driver means the RENDER_* monitors read zero, so this deliberately
## does not report draw calls; it reports the STRUCTURAL numbers that decide
## them (MultiMesh instance counts, batch counts, visible skinned bodies, node
## counts), which the Dummy driver reports honestly. `--mode=render` re-runs
## the same sites under `xvfb-run` + `opengl3` when the RenderingServer's own
## draw-call/primitive counters are wanted; see this file's `_render_stats()`.
## Never add `--headless` to that invocation (docs/AGENT_WORKFLOW.md).
##
## HOW COSTS ARE ATTRIBUTED. Godot's `TIME_PROCESS`/`TIME_PHYSICS_PROCESS`
## monitors are whole-frame totals: they say the frame cost 40ms, never which
## subsystem spent it. So this drives the suspects DIRECTLY -- it calls
## `vegetation.update_collision_streaming()` itself and times that one call,
## walks the wild population and times one activation sweep, and so on. Each
## number below is therefore a measured call, not a share of a total inferred
## by subtraction.

const SCENE := "res://scenes/world/meadows_playground.tscn"

## Long enough for the world's deferred build passes (village, warrens,
## stronghold, scatter) to finish. `smoke_traversal.gd` and
## `tools/_probe_ow5_walk.gd` both use 240 for the same reason.
const SETTLE_FRAMES := 240
## After a teleport, before sampling. Terrain3D rebuilds dynamic collision
## incrementally around the CAMERA on the physics tick, so a site sampled too
## soon after a jump measures that rebuild instead of the site.
##
## 300, not the 120 this started at, and the difference is not cosmetic: at 120
## the same two sites reported 45-51ms mean PHYSICS time, which reads as a
## catastrophic physics regression and is entirely the terrain still building.
## At 600 they report 3.9-4.6ms. 300 is where the reading stops moving.
## `--resettle=N` overrides it; raise it if a site's physics time looks wild.
const RESETTLE_FRAMES := 300
## Frames sampled per site once settled.
const DEFAULT_FRAMES := 120

const MB := 1024.0 * 1024.0

## Frames per sample in `--bisect`. Three samples are taken per subtree.
const SAMPLE_FRAMES := 40

## The sites, in corridor order. `at` is world x/z; the y comes from the world.
## Chosen to span what the chapter actually asks the machine for: the village
## (dense authored props + NPCs + interior shells), open Band 1 meadow (the
## scatter's own baseline), Band 2's stone-and-root belt, Band 4's ironwood
## (the densest authored band), and the stronghold approach (Team Tether's
## hero geometry, pylons and lights).
const SITES := {
	"village": Vector2(10.0, -10.0),
	"band1": Vector2(0.0, 700.0),
	"band2": Vector2(0.0, 2200.0),
	"band3": Vector2(0.0, 4000.0),
	"band4": Vector2(0.0, 6000.0),
	"stronghold": Vector2(0.0, 7500.0),
}

var _frames := DEFAULT_FRAMES
var _site_names: Array[String] = []
var _json_path := ""
var _label := ""
var _bisect := false
## Overrides RESETTLE_FRAMES. Terrain3D builds dynamic collision around the
## camera on the PHYSICS tick, so a site sampled too soon after a teleport
## measures that build rather than the site -- visible as a physics-time spike
## that moves when this is raised.
var _resettle := RESETTLE_FRAMES

var _world: Node = null
var _player: CharacterBody3D = null
var _rig: Node3D = null
var _camera: Node3D = null
var _vegetation: Node = null
var _director: Node = null
var _hud: Node = null

var _report: Dictionary = {}


func _init() -> void:
	_run()


func _parse_args() -> void:
	for a in OS.get_cmdline_user_args():
		var parts := a.split("=", true, 1)
		var key := parts[0].lstrip("-")
		var val := parts[1] if parts.size() > 1 else ""
		match key:
			"frames": _frames = maxi(10, int(val))
			"json": _json_path = val
			"label": _label = val
			"bisect": _bisect = val != "0"
			"resettle": _resettle = maxi(0, int(val))
			"sites":
				for s in val.split(",", false):
					var name := s.strip_edges()
					if SITES.has(name):
						_site_names.append(name)
					else:
						print("PERF WARN: unknown site '%s' ignored" % name)
	if _site_names.is_empty():
		for name: String in SITES.keys():
			_site_names.append(name)


func _run() -> void:
	_parse_args()
	print("=== PERF-ROG profile (OP23-01) ===")
	print("label=%s  sites=%s  frames/site=%d" % [
		("none" if _label == "" else _label), ", ".join(_site_names), _frames])
	print("NOTE: container hardware, not a ROG Ally. Read the RANKING, never the absolutes.")
	print("")

	var boot_start := Time.get_ticks_msec()
	_world = (load(SCENE) as PackedScene).instantiate()
	root.add_child(_world)
	for i in SETTLE_FRAMES:
		await physics_frame
	var boot_ms := Time.get_ticks_msec() - boot_start
	print("world booted and settled in %.1fs" % (boot_ms / 1000.0))

	_player = _world.get_node_or_null(^"Player") as CharacterBody3D
	_rig = _world.get_node_or_null(^"CameraRig") as Node3D
	_camera = _world.get_node_or_null(^"CameraRig/Camera3D") as Node3D
	_vegetation = _world.get_node_or_null(^"Vegetation")
	_director = _world.get_node_or_null(^"EncounterDirector")
	_hud = _world.get_node_or_null(^"PlaygroundHUD")
	if _player == null or _vegetation == null:
		print("PERF FAIL: scene is missing Player or Vegetation")
		quit(1)
		return

	_report["label"] = _label
	_report["boot_ms"] = boot_ms
	_report["world"] = _world_totals()
	_print_world_totals(_report["world"])

	var sites: Dictionary = {}
	for name: String in _site_names:
		var site := await _measure_site(name)
		sites[name] = site
		_print_site(name, site)
	_report["sites"] = sites

	_print_ranking(sites)

	if _bisect:
		await _bisect_process_cost()

	if _json_path != "":
		var f := FileAccess.open(_json_path, FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(_report, "  "))
			f.close()
			print("\nwrote %s" % _json_path)

	quit(0)


## --- world-wide structural totals, measured once ----------------------------
##
## These are what a frame's rendering and physics load is BUILT from, and they
## are what a density change moves. They do not vary by site, so they are taken
## once and reported at the top: a site's own numbers are then read against
## them ("of 223k placements, 1,400 have a live collider here").
func _world_totals() -> Dictionary:
	var stats: Dictionary = _vegetation.call("stats")
	var out := {
		"scatter_instances": int(stats.get("instances", 0)),
		"scatter_batches": int(stats.get("batches", 0)),
		"scatter_solid": int(stats.get("solid", 0)),
		"scatter_layers": stats.get("layers", {}),
		"harvest_points": int(stats.get("harvest_points", 0)),
		"node_count": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"object_count": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"static_mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / MB,
	}
	# Every skinned body in the world, whether or not it is ticking. A
	# deactivated wild still owns a Skeleton3D and an AnimationPlayer, and
	# those cost per-frame CPU that `set_physics_process(false)` does not
	# touch -- which is exactly the kind of cost this profile exists to name.
	var skeletons: Array[Node] = _world.find_children("*", "Skeleton3D", true, false)
	var players: Array[Node] = _world.find_children("*", "AnimationPlayer", true, false)
	var playing := 0
	var bones := 0
	for p: Node in players:
		if (p as AnimationPlayer).is_playing():
			playing += 1
	for s: Node in skeletons:
		bones += (s as Skeleton3D).get_bone_count()
	out["skeletons"] = skeletons.size()
	out["skeleton_bones"] = bones
	out["animation_players"] = players.size()
	out["animation_players_playing"] = playing
	out["multimesh_instances"] = _world.find_children("*", "MultiMeshInstance3D", true, false).size()
	out["mesh_instances"] = _world.find_children("*", "MeshInstance3D", true, false).size()
	out["static_bodies"] = _world.find_children("*", "StaticBody3D", true, false).size()
	out["character_bodies"] = _world.find_children("*", "CharacterBody3D", true, false).size()
	out["areas"] = _world.find_children("*", "Area3D", true, false).size()
	out["lights"] = _world.find_children("*", "OmniLight3D", true, false).size() \
		+ _world.find_children("*", "SpotLight3D", true, false).size()
	out["particles"] = _world.find_children("*", "GPUParticles3D", true, false).size() \
		+ _world.find_children("*", "CPUParticles3D", true, false).size()
	var wilds := _wilds()
	out["wild_total"] = wilds.size()
	out["wild_ticking"] = _wild_ticking(wilds)
	return out


## The director keeps its population in `_wild_creatures` and its distance
## activation in `_clusters`; neither has a public accessor and this tool has
## no business adding one to gameplay code just to read it. `Object.get()`
## reads a script member directly, which is what a profiler wants: the real
## array, not a copy of it made for the profiler's benefit.
func _wilds() -> Array:
	if _director == null:
		return []
	var raw: Variant = _director.get("_wild_creatures")
	return raw if raw is Array else []


func _wild_ticking(wilds: Array) -> int:
	var n := 0
	for w: Variant in wilds:
		if w is Node and is_instance_valid(w) and (w as Node).is_physics_processing():
			n += 1
	return n


## --- one site ---------------------------------------------------------------


func _measure_site(name: String) -> Dictionary:
	var at: Vector2 = SITES[name]
	var ground := 0.0
	if _world.has_method("ground_height_at"):
		ground = float(_world.call("ground_height_at", at.x, at.y))
	if is_nan(ground):
		ground = 0.0
	var spot := Vector3(at.x, ground + 1.5, at.y)
	_player.global_position = spot
	_player.velocity = Vector3.ZERO
	if _rig != null:
		_rig.global_position = spot
	for i in _resettle:
		await physics_frame

	var out: Dictionary = {"at": [at.x, at.y], "ground_y": ground}

	# --- whole-frame totals, sampled over a real run of frames ---------------
	#
	# Sampled rather than read once: `TIME_PROCESS` is the last frame's value
	# and a single read lands wherever the throttled sweeps happen to be. The
	# max matters more than the mean here -- a 40ms spike twice a second is
	# what a player feels as "ten fps", and a mean hides it completely.
	var proc: Array[float] = []
	var phys: Array[float] = []
	for i in _frames:
		await process_frame
		proc.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		phys.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
	out["process_ms"] = _spread(proc)
	out["physics_ms"] = _spread(phys)

	out["physics_active_objects"] = int(Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS))
	out["physics_collision_pairs"] = int(Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS))
	out["physics_island_count"] = int(Performance.get_monitor(Performance.PHYSICS_3D_ISLAND_COUNT))
	out["node_count"] = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))

	# --- the suspects, each timed by calling it directly ---------------------
	out["costs"] = await _subsystem_costs()
	return out


## Every ranked cost, in one dictionary: `{label: {ms, per_second, note}}`.
##
## `ms` is the measured cost of ONE call. `per_second` is that cost multiplied
## by how often the game actually makes the call, which is the number that
## decides whether it matters -- a 30ms sweep twice a second and a 0.2ms
## routine every frame are 60 and 12 ms/s respectively, and reading only the
## per-call column gets that ordering backwards.
func _subsystem_costs() -> Dictionary:
	var costs: Dictionary = {}

	# 1. Collision streaming. `playground_world.gd::_process` calls this every
	#    COLLISION_STREAM_INTERVAL seconds; `_stream_batch` walks EVERY
	#    placement in EVERY collision batch, world-wide, on every call.
	var t0 := Time.get_ticks_usec()
	_vegetation.call("update_collision_streaming", _player.global_position)
	var streaming_ms := (Time.get_ticks_usec() - t0) / 1000.0
	# A second call with the bubble unchanged: the steady-state cost, with no
	# shape construction or freeing in it. The first call after a teleport
	# builds a bubble's worth of colliders and is the worst case; standing
	# still is the common case, and both are worth having.
	t0 = Time.get_ticks_usec()
	_vegetation.call("update_collision_streaming", _player.global_position)
	var streaming_steady_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var interval := 0.5
	var pw: Variant = _world.get("COLLISION_STREAM_INTERVAL")
	if pw is float:
		interval = pw
	costs["collision_streaming"] = {
		"ms": streaming_steady_ms,
		"worst_ms": streaming_ms,
		"per_second": streaming_steady_ms / interval,
		"note": "vegetation.update_collision_streaming(), %.1f Hz, over %d solid placements world-wide" % [
			1.0 / interval, int((_report["world"] as Dictionary).get("scatter_solid", 0))],
	}
	costs["collision_resident"] = {
		"count": int(_vegetation.call("collision_resident_count")),
		"note": "live CollisionShape3D nodes in the streaming bubble at this site",
	}

	# 2. Wild activation sweep. The director walks its clusters every frame.
	var wilds := _wilds()
	t0 = Time.get_ticks_usec()
	if _director != null and _director.has_method("_tick_streaming"):
		_director.call("_tick_streaming")
	var wild_stream_ms := (Time.get_ticks_usec() - t0) / 1000.0
	costs["wild_cluster_sweep"] = {
		"ms": wild_stream_ms,
		"per_second": wild_stream_ms * 60.0,
		"note": "encounter_director._tick_streaming(), every frame, over %d clusters" % _cluster_count(),
	}
	var ticking := _wild_ticking(wilds)
	costs["wild_ticking"] = {
		"count": ticking,
		"of": wilds.size(),
		"note": "wild bodies running _physics_process at this site",
	}
	# Skinned bodies are the cost `set_physics_process(false)` does NOT stop:
	# an AnimationPlayer keeps advancing and a Skeleton3D keeps rebuilding its
	# pose whether or not the creature's own script ticks, and whether or not
	# it is on screen.
	costs["animating_bodies"] = {
		"count": _playing_animation_players(),
		"of": int((_report["world"] as Dictionary).get("animation_players", 0)),
		"note": "AnimationPlayers advancing this frame, world-wide",
	}

	# 3. HUD. One real `_process` call, timed. The HUD runs ~14 update passes
	#    per frame (playground_hud.gd::_process) plus a minimap redraw whenever
	#    the player has moved, which during play is every frame.
	if _hud != null and _hud.has_method("_process"):
		# Warm once so the first-call allocation is not what gets reported.
		_hud.call("_process", 1.0 / 60.0)
		t0 = Time.get_ticks_usec()
		for i in 10:
			_hud.call("_process", 1.0 / 60.0)
		var hud_ms := (Time.get_ticks_usec() - t0) / 10000.0
		costs["hud_process"] = {
			"ms": hud_ms,
			"per_second": hud_ms * 60.0,
			"note": "playground_hud._process(), every frame",
		}

	# 4. Interaction arbiter. Polls candidate interactables around the player.
	var arbiter := _world.get_node_or_null(^"InteractionArbiter")
	if arbiter != null and arbiter.has_method("_process"):
		arbiter.call("_process", 1.0 / 60.0)
		t0 = Time.get_ticks_usec()
		for i in 10:
			arbiter.call("_process", 1.0 / 60.0)
		var arb_ms := (Time.get_ticks_usec() - t0) / 10000.0
		costs["interaction_arbiter"] = {
			"ms": arb_ms,
			"per_second": arb_ms * 60.0,
			"note": "interaction_arbiter._process(), every frame",
		}

	return costs


func _cluster_count() -> int:
	if _director == null:
		return 0
	var raw: Variant = _director.get("_clusters")
	return (raw as Array).size() if raw is Array else 0


func _playing_animation_players() -> int:
	var n := 0
	for p: Node in _world.find_children("*", "AnimationPlayer", true, false):
		if (p as AnimationPlayer).is_playing():
			n += 1
	return n


func _spread(samples: Array[float]) -> Dictionary:
	if samples.is_empty():
		return {"mean": 0.0, "min": 0.0, "max": 0.0, "p95": 0.0}
	var sorted := samples.duplicate()
	sorted.sort()
	var total := 0.0
	for v: float in samples:
		total += v
	return {
		"mean": total / float(samples.size()),
		"min": sorted[0],
		"max": sorted[sorted.size() - 1],
		"p95": sorted[mini(sorted.size() - 1, int(float(sorted.size()) * 0.95))],
	}


## --- reporting --------------------------------------------------------------


func _print_world_totals(w: Dictionary) -> void:
	print("--- world totals (built once, same at every site) ---")
	print("scatter        %d placements in %d batches, %d solid, %d harvest points" % [
		w.get("scatter_instances", 0), w.get("scatter_batches", 0),
		w.get("scatter_solid", 0), w.get("harvest_points", 0)])
	print("nodes          %d nodes, %d objects, %.0f MB static" % [
		w.get("node_count", 0), w.get("object_count", 0), w.get("static_mem_mb", 0.0)])
	print("render bodies  %d MultiMeshInstance3D, %d MeshInstance3D, %d StaticBody3D, %d Area3D" % [
		w.get("multimesh_instances", 0), w.get("mesh_instances", 0),
		w.get("static_bodies", 0), w.get("areas", 0)])
	print("skinned        %d Skeleton3D (%d bones total), %d AnimationPlayer (%d playing)" % [
		w.get("skeletons", 0), w.get("skeleton_bones", 0),
		w.get("animation_players", 0), w.get("animation_players_playing", 0)])
	print("wild           %d creatures, %d ticking here" % [
		w.get("wild_total", 0), w.get("wild_ticking", 0)])
	print("lights/fx      %d point lights, %d particle systems" % [
		w.get("lights", 0), w.get("particles", 0)])
	var layers: Dictionary = w.get("scatter_layers", {})
	if not layers.is_empty():
		var names := layers.keys()
		names.sort_custom(func(a, b): return int(layers[a]) > int(layers[b]))
		var parts: Array[String] = []
		for n: Variant in names:
			parts.append("%s=%d" % [n, int(layers[n])])
		print("scatter layers %s" % ", ".join(parts))
	print("")


func _print_site(name: String, site: Dictionary) -> void:
	var p: Dictionary = site["process_ms"]
	var q: Dictionary = site["physics_ms"]
	print("--- %s  (%.0f, %.0f) ---" % [name, (site["at"] as Array)[0], (site["at"] as Array)[1]])
	print("frame cpu      process mean %.2f ms  p95 %.2f  max %.2f  |  physics mean %.2f  max %.2f" % [
		p["mean"], p["p95"], p["max"], q["mean"], q["max"]])
	print("physics             %d active bodies, %d collision pairs, %d islands" % [
		site.get("physics_active_objects", 0), site.get("physics_collision_pairs", 0),
		site.get("physics_island_count", 0)])
	var costs: Dictionary = site["costs"]
	for label: String in costs.keys():
		var c: Dictionary = costs[label]
		if c.has("ms"):
			print("  %-22s %8.3f ms/call   %8.2f ms/s   %s" % [
				label, c["ms"], c.get("per_second", 0.0), c.get("note", "")])
		else:
			print("  %-22s %8d       %s" % [label, c.get("count", 0), c.get("note", "")])
	print("")


## The ranking is the point of the tool. Costs are summed across sites into a
## worst-site column, because a subsystem that is free in the village and
## ruinous in Band 4 is a Band 4 problem, and averaging the two would hide it.
func _print_ranking(sites: Dictionary) -> void:
	var worst: Dictionary = {}
	for site_name: String in sites.keys():
		var costs: Dictionary = (sites[site_name] as Dictionary)["costs"]
		for label: String in costs.keys():
			var c: Dictionary = costs[label]
			if not c.has("per_second"):
				continue
			var per_s: float = c["per_second"]
			if not worst.has(label) or per_s > float((worst[label] as Dictionary)["per_second"]):
				worst[label] = {"per_second": per_s, "ms": c["ms"], "site": site_name}
	var labels := worst.keys()
	labels.sort_custom(func(a, b):
		return float((worst[a] as Dictionary)["per_second"]) > float((worst[b] as Dictionary)["per_second"]))
	print("=== RANKED per-frame cost, worst site (container CPU, not device) ===")
	var budget := 1000.0 / 60.0
	for label: Variant in labels:
		var c: Dictionary = worst[label]
		print("  %-22s %8.2f ms/s  (%.3f ms/call, worst at %s) = %.1f%% of a 60fps CPU second" % [
			label, c["per_second"], c["ms"], c["site"], c["per_second"] / 10.0])
	print("")
	print("A 60fps second has %.1f ms of frame budget per frame and 1000 ms in total." % budget)
	print("Percentages above are of that whole second, on THIS box. A handheld's")
	print("small cores run GDScript roughly 3-6x slower; multiply before judging.")
	_report["ranking"] = worst


## --- attribution by subtraction ---------------------------------------------
##
## The ranked costs above are measured by calling the suspect directly, which
## only works for a suspect somebody already suspects. This finds the rest:
## it switches off one subtree's idle processing at a time and measures what
## the frame stops costing. What is left over after every child has been tried
## is the engine's own per-frame work (servers, transform propagation, the
## scene tree walk), which no amount of GDScript tuning reaches.
##
## Run at the player's spawn, which is where a fresh boot puts them and where
## the opening plays out.
func _bisect_process_cost() -> void:
	print("=== PROCESS-TIME ATTRIBUTION (by subtree, paired A/B/A) ===")
	print("Each subtree is measured against a baseline taken immediately before AND")
	print("after switching it off, and the two baselines are averaged. A first")
	print("attempt used one baseline taken at the start and reported 22ms for every")
	print("subtree including ones with a single idle node -- the world's own frame")
	print("cost drifts as terrain and streaming settle, and an unpaired difference")
	print("measures that drift rather than the subtree.")
	var rows: Array = []
	for child: Node in _world.get_children():
		var before := await _sample_process_ms(SAMPLE_FRAMES)
		var touched: Array[Node] = []
		_suspend(child, touched)
		if touched.is_empty():
			continue
		var without := await _sample_process_ms(SAMPLE_FRAMES)
		for n: Node in touched:
			n.set_process(true)
		var after := await _sample_process_ms(SAMPLE_FRAMES)
		var baseline := (before + after) * 0.5
		rows.append({
			"name": String(child.name),
			"cost": baseline - without,
			"nodes": touched.size(),
			"drift": absf(after - before),
		})
	rows.sort_custom(func(a, b): return float(a["cost"]) > float(b["cost"]))
	var named := 0.0
	var total := await _sample_process_ms(SAMPLE_FRAMES)
	for r: Dictionary in rows:
		named += float(r["cost"])
		if absf(float(r["cost"])) < 0.05:
			continue
		print("  %-28s %7.3f ms/frame  (%d idle nodes, baseline drift %.2f ms)" % [
			r["name"], r["cost"], r["nodes"], r["drift"]])
	print("  %-28s %7.3f ms/frame  (engine, servers, tree walk -- not GDScript)" % [
		"<unattributed>", total - named])
	print("  %-28s %7.3f ms/frame" % ["TOTAL process", total])
	_report["attribution"] = rows


## Switch off `_process` on a subtree, remembering only the nodes that were
## actually processing so restoring cannot switch something ON that was off.
func _suspend(node: Node, touched: Array[Node]) -> void:
	if node.is_processing():
		node.set_process(false)
		touched.append(node)
	for child: Node in node.get_children():
		_suspend(child, touched)


func _sample_process_ms(frames: int) -> float:
	# Discard the first few: the monitor reports the PREVIOUS frame, so the
	# first samples after a change still describe the old configuration.
	for i in 5:
		await process_frame
	var total := 0.0
	for i in frames:
		await process_frame
		total += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	return total / float(frames)
