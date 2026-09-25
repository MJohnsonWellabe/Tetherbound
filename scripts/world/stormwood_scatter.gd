extends RefCounted

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const PATH := "res://data/config/stormwood_vegetation.json"
const SETTLEMENTS := "res://data/config/stormwood_settlements.json"
const POCKETS_PATH := "res://data/config/stormwood_pockets.json"
const POCKET_FRAME_PATH := "res://scripts/world/stormwood_pocket_frame.gd"
const POCKET_FRAME := preload(POCKET_FRAME_PATH)
const SOURCES: Array[String] = [PATH, SETTLEMENTS, "res://data/config/terrain_stormwood.json", "res://data/config/stormwood_world.json", "res://scripts/world/stormwood_heightfield.gd", "res://scripts/world/stormwood_scatter.gd", POCKETS_PATH, POCKET_FRAME_PATH]
## Authored seats the scatter keeps clear (vegetation.json `seat_clearings`).
## These files are NOT whole-file bake sources: only each seat's kind, id and
## XZ position enter the fingerprint (`seat_fingerprint_text`), so a dialogue,
## party or item edit leaves the bake fresh while moving, adding or removing a
## seat stales it and needs a re-bake.
const SEAT_SOURCES := {
	"trainer": ["res://data/config/stormwood_trainers.json", "trainers"],
	"npc": ["res://data/config/stormwood_npcs.json", "characters"],
	"harvest": ["res://data/config/stormwood_harvests.json", "sites"],
	"pickup": ["res://data/config/stormwood_pickups.json", "pickups"],
}
const SEAT_CELL_M := 16.0

static func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH)) as Dictionary

static func fingerprint() -> int:
	var mixed := 0
	for path: String in SOURCES:
		mixed = BAKE.mix_config_source(mixed,FileAccess.get_file_as_string(path),path)
	mixed = BAKE.mix_config_source(mixed, seat_fingerprint_text(), "stormwood_scatter:seats")
	return mixed & 0x1FFFFFFFFFFFFF

## Every authored seat as {kind, id, at: Vector2 (world XZ)}, in file order.
## Harvest sites store [x, z]; the other files store [x, y, z].
static func seats() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for kind: String in ["trainer", "npc", "harvest", "pickup"]:
		var source: Array = SEAT_SOURCES[kind]
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(str(source[0])))
		for row: Dictionary in data.get(str(source[1]), []):
			var p: Array = row.get("position", [])
			if p.size() < 2:
				continue
			var z := float(p[1]) if p.size() == 2 else float(p[2])
			out.append({"kind": kind, "id": str(row.id), "at": Vector2(float(p[0]), z)})
	return out

static func seat_fingerprint_text() -> String:
	var lines := PackedStringArray()
	for seat: Dictionary in seats():
		var at: Vector2 = seat.at
		lines.append("%s|%s|%.2f|%.2f" % [seat.kind, seat.id, at.x, at.y])
	return "\n".join(lines)

static func placements(field: RefCounted, world: Dictionary) -> Dictionary:
	var cfg := config()
	var settlements: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SETTLEMENTS))
	cfg["structure_footprints"] = settlements.get("structures", [])
	# Dead-end pockets (stormwood_pockets.gd) keep every collider off their
	# palisade and interior: the walled square's corner radius plus the
	# largest baked collider reach.
	var pockets: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(POCKETS_PATH))
	cfg["pocket_clearings"] = pockets.pockets
	cfg["pocket_clear_radius_m"] = (float(pockets.interior_half_m) + float(pockets.wall_thickness_m)) * sqrt(2.0) + max_collider_reach(cfg)
	cfg["route_half_width"] = float((JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_stormwood.json")) as Dictionary).route_half_width)
	# Each pocket's mouth reads from its road: no tree or colliding rock in a
	# widening cone out of the mouth, and no ground cover near it.
	var frames: Array[Dictionary] = []
	for pocket: Dictionary in pockets.pockets:
		frames.append({"mouth": POCKET_FRAME.mouth(pocket, pockets), "forward": POCKET_FRAME.frame(pocket).forward})
	cfg["pocket_mouths"] = frames
	cfg["pocket_approach"] = pockets.get("approach_clear", {})
	cfg["seat_grid"] = _seat_grid(cfg.get("seat_clearings", {}))
	var rng := RandomNumberGenerator.new()
	var out: Dictionary = {}
	for layer: String in cfg.layers:
		out[layer] = []
	var occupied: Dictionary = {}
	# The roadside composition is deliberately asymmetric. A broadleaf stand
	# leans over one shoulder, ferns and broken timber open the opposite view.
	for route: Dictionary in world.routes:
		# A pocket's spur is its lane, not a road: the corridor check below
		# clears it, but it gets no roadside stand. Planting one would line
		# a 100-340 m dead-end lane like a through road and claim tree cells
		# the background forest now fills, re-planting far more than the lane.
		if str(route.get("kind", "")) == "spur":
			continue
		# Each road and each background cell draws from its own seed, so an
		# edit to one road never changes another road's or cell's random
		# draws. It can still change their planting: `occupied` is shared, so
		# a tree the edited road now places (or no longer places) claims (or
		# frees) a 9 m tree cell or 1.5 m ground cell that a road later in
		# `world.routes`, or a background cell, would have used. A candidate
		# rejected there skips its model/yaw/scale draws, which shifts every
		# later placement in that road's own stream (a background cell's
		# stream ends with the cell). Every road's corridor setback also
		# rejects candidates along its new line. Expect the edited road's
		# planting to change, plus knock-on changes wherever it meets later
		# planting: not a forest-wide reshuffle, but not strictly local.
		rng.seed = _seed_for(int(cfg.seed), "route:" + str(route.id))
		var points: Array = route.points
		for i in range(1,points.size()):
			var a := Vector2(float(points[i-1][0]),float(points[i-1][1]))
			var b := Vector2(float(points[i][0]),float(points[i][1]))
			var side := (b-a).normalized().orthogonal()
			var steps := maxi(1,ceili(a.distance_to(b)/float(cfg.road_sample_m)))
			for n in steps:
				var at := a.lerp(b,float(n)/steps)
				var tree := at + side*rng.randf_range(16,31)*(1 if n%3 else -1)
				var layer := "crown_canopy" if str(route.kind)=="island" else ("storm_deadwood" if tree.y<1000 and rng.randf()<0.55 else "storm_canopy")
				_add(out,cfg,field,world,rng,occupied,layer,tree)
				for patch in 3:
					var centre := at+side*rng.randf_range(9,25)*(1 if patch%2 else -1)
					for j in 4:
						var under := centre+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(1,6)
						_add(out,cfg,field,world,rng,occupied,["storm_fern","storm_bush","storm_mushroom"][j%3],under)
	var bounds: Dictionary = world.realm.world_bounds
	var spacing := float(cfg.background_spacing_m)
	for z in range(int(bounds.min_z)+35,int(bounds.max_z)-35,int(spacing)):
		for x in range(int(bounds.min_x)+35,int(bounds.max_x)-35,int(spacing)):
			rng.seed = _seed_for(int(cfg.seed), "cell:%d:%d" % [x, z])
			var at := Vector2(x+rng.randf_range(-24,24),z+rng.randf_range(-24,24))
			if rng.randf()<0.18:
				continue
			_add(out,cfg,field,world,rng,occupied,"storm_canopy",at)
			if rng.randf()<0.35:
				for j in 3:
					var under := at+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(4,12)
					_add(out,cfg,field,world,rng,occupied,["storm_fern","storm_mushroom","storm_bush"][j%3],under)
			if rng.randf()<0.45:
				_add(out,cfg,field,world,rng,occupied,"storm_rock",at+Vector2(12,7))
	return out

## The largest collider surface any baked layer can reach from its centre:
## collision_radius x scale_max over the colliding layers.
static func max_collider_reach(cfg: Dictionary) -> float:
	var reach := 0.0
	for layer: String in cfg.layers:
		var spec: Dictionary = cfg.layers[layer]
		if bool(spec.get("collides", false)):
			reach = maxf(reach, float(spec.get("collision_radius", 0.0)) * float(spec.scale_max))
	return reach

## Seats bucketed by SEAT_CELL_M for the per-candidate check: each entry is
## [at, collider_surface_m, ground_cover_m]. Every clearance plus the largest
## collider reach stays under one cell, so a 3 x 3 lookup is exhaustive.
static func _seat_grid(clearings: Dictionary) -> Dictionary:
	var grid := {}
	if clearings.is_empty():
		return grid
	var collider: Dictionary = clearings.collider_surface_m
	var ground: Dictionary = clearings.ground_cover_m
	for seat: Dictionary in seats():
		var at: Vector2 = seat.at
		var cell := Vector2i(floori(at.x / SEAT_CELL_M), floori(at.y / SEAT_CELL_M))
		if not grid.has(cell):
			grid[cell] = []
		(grid[cell] as Array).append([at, float(collider[seat.kind]), float(ground[seat.kind])])
	return grid

## FNV-1a over the key, mixed with the authored seed: stable across engine
## versions and platforms, unlike Variant hashing.
static func _seed_for(base: int, key: String) -> int:
	var h := -3750763034362895579 ^ base  # FNV-1a 64-bit offset basis 0xcbf29ce484222325 as a signed int
	for byte in key.to_utf8_buffer():
		h = (h ^ byte) * 0x100000001b3
	return h & 0x7FFFFFFFFFFFFFFF

static func _add(out: Dictionary,cfg: Dictionary,field: RefCounted,world: Dictionary,rng: RandomNumberGenerator,occupied: Dictionary,layer: String,at: Vector2) -> void:
	var is_tree := layer.contains("canopy") or layer=="storm_deadwood"
	var collides := bool((cfg.layers[layer] as Dictionary).get("collides", false))
	var cell := 9.0 if is_tree else 1.5
	var key := "%s:%d:%d"%["tree" if is_tree else layer,floori(at.x/cell),floori(at.y/cell)]
	if occupied.has(key):
		return
	var h := float(field.call("height_at",at.x,at.y))
	if h<0 or float(field.call("slope_degrees_at",at.x,at.y))>42:
		return
	# Baked plants must respect actual authored buildings, including outlying
	# shelters beyond a landmark's clearing. Runtime grass suppression alone
	# cannot remove a baked tree or its harvest collider from a doorway.
	for structure: Dictionary in cfg.get("structure_footprints", []):
		var centre := Vector2(float(structure.at[0]), float(structure.at[1]))
		var radius := float(structure.get("tree_clear_radius_m", 18.0) if is_tree else structure.get("ground_clear_radius_m", 10.0))
		if at.distance_to(centre) < radius:
			return
	if is_tree:
		for sightline: Dictionary in world.get("landmark_sightlines", []):
			var a := Vector2(float(sightline.from[0]), float(sightline.from[1]))
			var b := Vector2(float(sightline.to[0]), float(sightline.to[1]))
			if Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) < float(sightline.clear_radius_m):
				return
	for landmark: Dictionary in world.landmarks:
		var p: Array = landmark.position
		var radius := 36.0 if str(landmark.category) in ["camp","settlement","stronghold"] else 13.0
		if at.distance_to(Vector2(float(p[0]),float(p[2])))<radius:
			return
	# Named fights keep trunk and rock colliders out of their arena.
	var clearings: Dictionary = cfg.get("encounter_clearings", {})
	if collides:
		for site: Dictionary in clearings.get("sites", []):
			if at.distance_to(Vector2(float(site.at[0]), float(site.at[1]))) < float(clearings.collider_clear_radius_m):
				return
	# Authored seats (trainers, NPCs, harvest nodes, pickups): no collider
	# surface within the kind's `collider_surface_m` at the layer's largest
	# scale, and no ground cover centred within `ground_cover_m`.
	var spec_seat: Dictionary = cfg.layers[layer]
	var seat_reach := float(spec_seat.get("collision_radius", 0.0)) * float(spec_seat.scale_max) if collides else 0.0
	var seat_cell := Vector2i(floori(at.x / SEAT_CELL_M), floori(at.y / SEAT_CELL_M))
	var seat_grid: Dictionary = cfg.get("seat_grid", {})
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for seat: Array in seat_grid.get(seat_cell + Vector2i(dx, dz), []):
				var clear := float(seat[1]) + seat_reach if collides else float(seat[2])
				if at.distance_to(seat[0] as Vector2) < clear:
					return
	var approach: Dictionary = cfg.get("pocket_approach", {})
	if not approach.is_empty():
		var slope := tan(deg_to_rad(float(approach.half_angle_deg)))
		var length := float(approach.length_m) if (is_tree or collides) else float(approach.ground_cover_length_m)
		for mouth: Dictionary in cfg.get("pocket_mouths", []):
			var local: Vector2 = at - (mouth.mouth as Vector2)
			var ahead := local.dot(mouth.forward as Vector2)
			if ahead < -1.0 or ahead > length:
				continue
			var lateral := absf(local.cross(mouth.forward as Vector2))
			if lateral < float(approach.mouth_half_width_m) + maxf(ahead, 0.0) * slope:
				return
	if collides:
		for pocket: Dictionary in cfg.get("pocket_clearings", []):
			if at.distance_to(Vector2(float(pocket.at[0]), float(pocket.at[1]))) < float(cfg.pocket_clear_radius_m):
				return
	# Roads stay open: no trunk or colliding rock reaches into the terrain
	# contract's road corridor (route_half_width), and trees keep their 9 m
	# roadside setback.
	if collides:
		var spec_reach: Dictionary = cfg.layers[layer]
		var setback := maxf(9.0 if is_tree else 0.0, float(cfg.route_half_width) + float(spec_reach.collision_radius) * float(spec_reach.scale_max))
		for route: Dictionary in world.routes:
			var points: Array = route.points
			for i in range(1,points.size()):
				var a := Vector2(float(points[i-1][0]),float(points[i-1][1]))
				var b := Vector2(float(points[i][0]),float(points[i][1]))
				if Geometry2D.get_closest_point_to_segment(at,a,b).distance_to(at)<setback:
					return
	occupied[key]=true
	var spec: Dictionary = cfg.layers[layer]
	var models: Array = spec.models
	out[layer].append({"model":models[rng.randi_range(0,models.size()-1)],"position":Vector3(at.x,h,at.y),"yaw":rng.randf_range(0,TAU),"scale":rng.randf_range(float(spec.scale_min),float(spec.scale_max))})
