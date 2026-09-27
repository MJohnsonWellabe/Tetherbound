extends SceneTree

## F03 lure legibility. Can a player standing on the ordinary road SEE an
## optional activity's lure at all? The rendered lure walk
## (tests/capture_activity_lures.gd) found three lures (Old Bram, the
## Meadowhart herd, Doss's river nest) readable only after leaving the road.
## This headless probe answers the geometric half of that question for every
## road sample, not only the one route the walk happened to take:
##
##   flock <writer-lock> godot --headless --path . \
##     --script tests/probe_lure_road_visibility.gd -- [--activity=bram|herd|doss]
##     [--at=bram:195,905] [--grid=bram:cx,cz,half,step]
##
## Road graph: the same one the lure walk plans on -- every trail band, loop and
## shortcut in terrain_playground.json, densified to 8 m. Samples are road
## nodes within SAMPLE_RANGE_M (straight line) of the lure. From each sample a
## ray runs from eye height (terrain + 1.6 m) to the lure's body centre (the
## live body + 1 m; for the herd, the spawn centre and every live member).
##
## Occluders:
##   * terrain -- Terrain3D's heightmap sampled every TERRAIN_STEP_M along the
##     ray (dynamic terrain collision only exists around the camera, the
##     heightmap is the same surface everywhere);
##   * hard -- a physics ray against the world with EVERY scatter collider
##     (trees, rocks, saplings) forced resident: the probe widens
##     vegetation.gd's streaming bubble to cover the world, so the playground's
##     own re-centring keeps them resident; creatures and the lure are not
##     occluders;
##   * soft -- non-colliding scatter (bushes and other soft occluders) whose
##     footprint the ray passes through below its SOFT_TOP_M, reported as a
##     separate stricter column;
##   * canopy -- the strictest, pessimistic column: a tree, grove tree or
##     sapling counts as blocking wherever the ray passes inside its canopy disc
##     (the model's own bounding radius x scale x CANOPY_FACTOR) at any height.
##     The truth sits between `soft` and `canopy` (most canopies start above
##     eye height).
##
## `--at=` evaluates a candidate site (ground + 1 m) instead of the live body;
## `--grid=` scans a square of candidate sites and prints those that qualify
## (>= MIN_OFF_ROAD_M from every road, clear line from a road sample within
## GOOD_RANGE_M, no solid scatter within ARENA_CLEAR_M).
##
## Inert by default: a standalone SceneTree script, not a test_*.gd. Writes
## nothing.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const SETTLE_FRAMES := 240
const DENSIFY_M := 8.0
const SAMPLE_RANGE_M := 160.0
const GOOD_RANGE_M := 100.0
const WITNESS_RANGE_M := 120.0
const EYE_M := 1.6
const BODY_M := 1.0
const TERRAIN_STEP_M := 1.0
const SOFT_TOP_M := 2.0
const MIN_OFF_ROAD_M := 25.0
const ARENA_CLEAR_M := 6.0
const CANOPY_FACTOR := 0.7
const CANOPY_MODELS := ["CommonTree", "CherryBlossom", "TwistedTree", "Pine", "Birch"]

var _world: Node3D
var _terrain_data: Object
var _vegetation: Node
var _space: PhysicsDirectSpaceState3D
var _roads: Array = []  # Array of PackedVector2Array polylines
var _nodes := PackedVector2Array()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var only := ""
	var ats: Array = []
	var grids: Array = []
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--activity="):
			only = a.trim_prefix("--activity=")
		elif a.begins_with("--at="):
			ats.append(a.trim_prefix("--at="))
		elif a.begins_with("--grid="):
			grids.append(a.trim_prefix("--grid="))
	_load_roads()
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for i in SETTLE_FRAMES:
		await physics_frame
	var terrain := _world.get_node_or_null(^"Terrain3D")
	if terrain == null:
		for n in _world.find_children("*", "Terrain3D", true, false):
			terrain = n
			break
	_terrain_data = terrain.get("data") if terrain != null else null
	_vegetation = _world.get_node_or_null(^"Vegetation")
	if _terrain_data == null or _vegetation == null:
		print("[lure-sight] FAIL no terrain data or vegetation")
		quit(1)
		return
	# Every scatter collider resident, and kept so by the playground's own
	# twice-a-second re-centring (it reads this same radius).
	_vegetation.set("COLLISION_STREAM_RADIUS", 100000.0)
	_vegetation.call("force_collision_resident", "")
	for i in 10:
		await physics_frame
	print("[lure-sight] scatter colliders resident: %d of %d" % [
		int(_vegetation.call("collision_resident_count")), int(_vegetation.call("collidable_count"))])
	_space = _world.get_world_3d().direct_space_state

	_collect_canopies()
	for id: String in ["bram", "herd", "doss"]:
		if only != "" and only != id:
			continue
		var targets := _live_targets(id)
		if targets.is_empty():
			print("[lure-sight] %s FAIL lure not present" % id)
			continue
		_report("%s (live, %d targets)" % [id, targets.size()], targets, targets[0] as Vector3)
	for spec: String in ats:
		var parts := spec.split(":")
		var xz := parts[1].split(",")
		var p := _ground(float(xz[0]), float(xz[1]))
		_report("%s at %s" % [parts[0], parts[1]], [p], p)
	_canopies.clear()  # the grid scan uses the hard/soft columns only
	for spec: String in grids:
		_scan(spec)
	quit(0)


func _live_targets(id: String) -> Array:
	var out: Array = []
	match id:
		"bram":
			var trainers := _world.get_node_or_null(^"Trainers")
			var body := trainers.call("body_for", "old_champion_bram") as Node3D if trainers != null else null
			if body != null:
				out.append(body.global_position + Vector3(0, BODY_M, 0))
		"doss":
			var doss := _world.get_node_or_null(^"RiverNestClear/Doss") as Node3D
			if doss != null:
				out.append(doss.global_position + Vector3(0, BODY_M, 0))
		"herd":
			var spawns: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
				"res://data/config/bands/band1_lower_meadows/spawns.json"))
			for raw: Variant in spawns.get("spawns", []):
				if int((raw as Dictionary).get("order", -1)) == 1005:
					var c: Array = raw["centre"]
					out.append(_ground(float(c[0]), float(c[2])))
			var director := _world.get_node_or_null(^"EncounterDirector")
			if director != null:
				for candidate: Variant in director.get("_wild_creatures"):
					var b := candidate as Node3D
					if b != null and is_instance_valid(b) and str(b.name).begins_with("Wild_meadowhart_1005_"):
						out.append(b.global_position + Vector3(0, BODY_M, 0))
	return out


func _ground(x: float, z: float) -> Vector3:
	return Vector3(x, float(_terrain_data.call("get_height", Vector3(x, 0, z))) + BODY_M, z)


## One lure (or candidate): every road sample in range, how many see it.
func _report(label: String, targets: Array, anchor: Vector3) -> Dictionary:
	var r := _evaluate(targets, anchor, SAMPLE_RANGE_M)
	print("[lure-sight] %s pos=(%.1f,%.1f) road_offset_m=%.1f samples=%d clear_hard=%d clear_soft=%d clear_canopy=%d nearest_canopy_clear_m=%s nearest_clear_m=%s farthest_clear_m=%s clear_within_%d=%s clear_within_%d=%s arena_scatter=%s" % [
		label, anchor.x, anchor.z, r.road_offset, r.samples, r.clear_hard, r.clear_soft,
		r.clear_canopy, str(r.nearest_canopy),
		str(r.nearest), str(r.farthest), int(WITNESS_RANGE_M), str(r.within_witness),
		int(GOOD_RANGE_M), str(r.within_good),
		str(bool(_vegetation.call("has_solid_scatter_near", anchor, ARENA_CLEAR_M)))])
	if not r.best.is_empty():
		print("[lure-sight]   nearest clear road sample at %s (%.1f m)" % [str(r.best), float(r.nearest)])
	return r


func _evaluate(targets: Array, anchor: Vector3, range_m: float) -> Dictionary:
	var a2 := Vector2(anchor.x, anchor.z)
	var r := {"samples": 0, "clear_hard": 0, "clear_soft": 0, "clear_canopy": 0, "nearest_canopy": -1.0, "nearest": -1.0, "farthest": -1.0,
		"within_witness": false, "within_good": false, "best": [], "road_offset": _road_offset(a2)}
	for n: Vector2 in _nodes:
		var d := n.distance_to(a2)
		if d > range_m:
			continue
		r.samples += 1
		var eye := Vector3(n.x, float(_terrain_data.call("get_height", Vector3(n.x, 0, n.y))) + EYE_M, n.y)
		var hard := false
		var soft := false
		var canopy := false
		for t: Vector3 in targets:
			if _clear_terrain(eye, t) and _clear_physics(eye, t):
				hard = true
				if _clear_soft(eye, t):
					soft = true
					if _canopies.is_empty() or _clear_canopy(eye, t):
						canopy = true
						break
		if hard:
			r.clear_hard += 1
			if d > float(r.farthest):
				r.farthest = snappedf(d, 0.1)
			if float(r.nearest) < 0.0 or d < float(r.nearest):
				r.nearest = snappedf(d, 0.1)
				r.best = [snappedf(n.x, 0.1), snappedf(n.y, 0.1)]
			if d <= WITNESS_RANGE_M:
				r.within_witness = true
			if d <= GOOD_RANGE_M:
				r.within_good = true
		if soft:
			r.clear_soft += 1
		if canopy:
			r.clear_canopy += 1
			if float(r.nearest_canopy) < 0.0 or d < float(r.nearest_canopy):
				r.nearest_canopy = snappedf(d, 0.1)
	return r


func _clear_terrain(from: Vector3, to: Vector3) -> bool:
	var length := from.distance_to(to)
	var steps := int(length / TERRAIN_STEP_M)
	for i in range(1, steps):
		var p := from.lerp(to, float(i) / float(steps))
		if p.y < float(_terrain_data.call("get_height", Vector3(p.x, 0, p.z))):
			return false
	return true


func _clear_physics(from: Vector3, to: Vector3) -> bool:
	var exclude: Array[RID] = []
	for attempt in 12:
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.exclude = exclude
		var hit := _space.intersect_ray(q)
		if hit.is_empty():
			return true
		var c: Object = hit.get("collider")
		# Moving bodies (creatures, the lure's own body, the player) are not
		# scenery; everything static (scatter, buildings, props, terrain) is.
		if c is CharacterBody3D or c is RigidBody3D or (hit.position as Vector3).distance_to(to) < 0.8:
			exclude.append(hit.get("rid"))
			continue
		return false
	return false


func _clear_soft(from: Vector3, to: Vector3) -> bool:
	var pos: PackedVector3Array = _vegetation.get("_soft_occluder_positions")
	var radii: PackedFloat32Array = _vegetation.get("_soft_occluder_radii")
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	for i in pos.size():
		var s := Vector2(pos[i].x, pos[i].z)
		if absf(s.x - (a.x + b.x) * 0.5) > absf(a.x - b.x) * 0.5 + radii[i] \
				or absf(s.y - (a.y + b.y) * 0.5) > absf(a.y - b.y) * 0.5 + radii[i]:
			continue
		var c := Geometry2D.get_closest_point_to_segment(s, a, b)
		if c.distance_to(s) > radii[i] * 0.7 or c.distance_to(b) < radii[i]:
			continue
		var t := a.distance_to(c) / maxf(a.distance_to(b), 0.001)
		var y := lerpf(from.y, to.y, t)
		if y < pos[i].y + SOFT_TOP_M:
			return false
	return true


## [xz, radius] for every tree-like collidable placement.
var _canopies: Array = []


func _collect_canopies() -> void:
	for batch: Dictionary in (_vegetation.get("_collision_batches") as Array):
		var model := str(batch.get("model", ""))
		var tree := false
		for m: String in CANOPY_MODELS:
			tree = tree or model.get_file().begins_with(m)
		if not tree:
			continue
		var base := float(_vegetation.call("_model_footprint_radius", model))
		for placement: Dictionary in (batch["placements"] as Array):
			var p: Vector3 = placement["position"]
			_canopies.append([Vector2(p.x, p.z), base * float(placement.get("scale", 1.0)) * CANOPY_FACTOR])
	print("[lure-sight] canopy discs: %d" % _canopies.size())


func _clear_canopy(from: Vector3, to: Vector3) -> bool:
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y))
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y))
	for c: Array in _canopies:
		var s: Vector2 = c[0]
		var rad: float = c[1]
		if s.x < lo.x - rad or s.x > hi.x + rad or s.y < lo.y - rad or s.y > hi.y + rad:
			continue
		var q := Geometry2D.get_closest_point_to_segment(s, a, b)
		if q.distance_to(s) < rad and q.distance_to(b) > 1.0:
			return false
	return true


func _scan(spec: String) -> void:
	var parts := spec.split(":")
	var v := parts[1].split(",")
	var cx := float(v[0])
	var cz := float(v[1])
	var half := float(v[2])
	var step := float(v[3])
	var hits := 0
	var x := cx - half
	while x <= cx + half:
		var z := cz - half
		while z <= cz + half:
			var c := Vector2(x, z)
			var off := _road_offset(c)
			if off >= MIN_OFF_ROAD_M:
				var p := _ground(x, z)
				if not bool(_vegetation.call("has_solid_scatter_near", p, ARENA_CLEAR_M)):
					var r := _evaluate([p], p, GOOD_RANGE_M)
					if int(r.clear_hard) > 0:
						hits += 1
						print("[lure-sight] grid %s ok (%.0f,%.0f) road_offset=%.1f slope=%.1f clear_hard=%d clear_soft=%d nearest=%.1f from %s moved=%.1f" % [
							parts[0], x, z, off, _slope(x, z), r.clear_hard, r.clear_soft,
							float(r.nearest), str(r.best), c.distance_to(Vector2(cx, cz))])
			z += step
		x += step
	print("[lure-sight] grid %s: %d qualifying sites" % [parts[0], hits])


## Worst terrain drop over a 5 m pad, in degrees.
func _slope(x: float, z: float) -> float:
	var h0 := float(_terrain_data.call("get_height", Vector3(x, 0, z)))
	var worst := 0.0
	for k in 8:
		var ang := TAU * float(k) / 8.0
		var h := float(_terrain_data.call("get_height", Vector3(x + 2.5 * cos(ang), 0, z + 2.5 * sin(ang))))
		worst = maxf(worst, rad_to_deg(atan(absf(h - h0) / 2.5)))
	return snappedf(worst, 0.1)


func _road_offset(p: Vector2) -> float:
	var best := INF
	for line: PackedVector2Array in _roads:
		for i in range(1, line.size()):
			best = minf(best, Geometry2D.get_closest_point_to_segment(p, line[i - 1], line[i]).distance_to(p))
	return snappedf(best, 0.1)


func _load_roads() -> void:
	var terrain: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN_PATH))
	var trail := terrain.get("trail", {}) as Dictionary
	for key: String in ["bands", "loops", "shortcuts"]:
		for entry: Variant in (trail.get(key, []) as Array):
			var pts: Array = (entry as Dictionary).get("points", [])
			if pts.size() < 2:
				continue
			var line := PackedVector2Array()
			for p: Variant in pts:
				line.append(Vector2(float(p[0]), float(p[1])))
			_roads.append(line)
			for j in range(1, line.size()):
				var steps := maxi(1, int(ceil(line[j - 1].distance_to(line[j]) / DENSIFY_M)))
				for s in range(0 if j == 1 else 1, steps + 1):
					_nodes.append(line[j - 1].lerp(line[j], float(s) / float(steps)))
