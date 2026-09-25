extends RefCounted

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const PATH := "res://data/config/stormwood_vegetation.json"
const SETTLEMENTS := "res://data/config/stormwood_settlements.json"
const SOURCES: Array[String] = [PATH, SETTLEMENTS, "res://data/config/terrain_stormwood.json", "res://data/config/stormwood_world.json", "res://scripts/world/stormwood_heightfield.gd", "res://scripts/world/stormwood_scatter.gd"]

static func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH)) as Dictionary

static func fingerprint() -> int:
	var mixed := 0
	for path: String in SOURCES:
		mixed = BAKE.mix_config_source(mixed,FileAccess.get_file_as_string(path),path)
	return mixed & 0x1FFFFFFFFFFFFF

static func placements(field: RefCounted, world: Dictionary) -> Dictionary:
	var cfg := config()
	var settlements: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SETTLEMENTS))
	cfg["structure_footprints"] = settlements.get("structures", [])
	cfg["route_half_width"] = float((JSON.parse_string(FileAccess.get_file_as_string("res://data/config/terrain_stormwood.json")) as Dictionary).route_half_width)
	var rng := RandomNumberGenerator.new()
	var out: Dictionary = {}
	for layer: String in cfg.layers:
		out[layer] = []
	var occupied: Dictionary = {}
	# The roadside composition is deliberately asymmetric. A broadleaf stand
	# leans over one shoulder, ferns and broken timber open the opposite view.
	for route: Dictionary in world.routes:
		# Each road and each background cell draws from its own seed, so an
		# authored road edit re-rolls only the planting along that road rather
		# than every tree in the forest.
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
