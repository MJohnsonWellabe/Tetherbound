extends RefCounted

const BAKE := preload("res://scripts/world/scatter_bake.gd")
const PATH := "res://data/config/stormwood_vegetation.json"
const SOURCES: Array[String] = [PATH, "res://data/config/terrain_stormwood.json", "res://data/config/stormwood_world.json", "res://scripts/world/stormwood_heightfield.gd", "res://scripts/world/stormwood_scatter.gd"]

static func config() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(PATH)) as Dictionary

static func fingerprint() -> int:
	var mixed := 0
	for path: String in SOURCES:
		mixed = BAKE.mix_config_source(mixed,FileAccess.get_file_as_string(path),path)
	return mixed & 0x1FFFFFFFFFFFFF

static func placements(field: RefCounted, world: Dictionary) -> Dictionary:
	var cfg := config()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cfg.seed)
	var out: Dictionary = {}
	for layer: String in cfg.layers:
		out[layer] = []
	var occupied: Dictionary = {}
	# The roadside composition is deliberately asymmetric. A broadleaf stand
	# leans over one shoulder, ferns and broken timber open the opposite view.
	for route: Dictionary in world.routes:
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
				for j in 7:
					var under := at+side*rng.randf_range(6,20)*(1 if j%2 else -1)+Vector2(rng.randf_range(-8,8),rng.randf_range(-8,8))
					_add(out,cfg,field,world,rng,occupied,["storm_fern","storm_bush","storm_mushroom"][j%3],under)
	var bounds: Dictionary = world.realm.world_bounds
	var spacing := float(cfg.background_spacing_m)
	for z in range(int(bounds.min_z)+35,int(bounds.max_z)-35,int(spacing)):
		for x in range(int(bounds.min_x)+35,int(bounds.max_x)-35,int(spacing)):
			var at := Vector2(x+rng.randf_range(-24,24),z+rng.randf_range(-24,24))
			if rng.randf()<0.18:
				continue
			_add(out,cfg,field,world,rng,occupied,"storm_canopy",at)
			if rng.randf()<0.45:
				_add(out,cfg,field,world,rng,occupied,"storm_rock",at+Vector2(12,7))
	return out

static func _add(out: Dictionary,cfg: Dictionary,field: RefCounted,world: Dictionary,rng: RandomNumberGenerator,occupied: Dictionary,layer: String,at: Vector2) -> void:
	var is_tree := layer.contains("canopy") or layer=="storm_deadwood"
	var key := "%s:%d:%d"%["tree" if is_tree else layer,floori(at.x/9),floori(at.y/9)]
	if occupied.has(key):
		return
	var h := float(field.call("height_at",at.x,at.y))
	if h<0 or float(field.call("slope_degrees_at",at.x,at.y))>42:
		return
	for landmark: Dictionary in world.landmarks:
		var p: Array = landmark.position
		var radius := 36.0 if str(landmark.category) in ["camp","settlement","stronghold"] else 13.0
		if at.distance_to(Vector2(float(p[0]),float(p[2])))<radius:
			return
	if is_tree:
		for route: Dictionary in world.routes:
			var points: Array = route.points
			for i in range(1,points.size()):
				var a := Vector2(float(points[i-1][0]),float(points[i-1][1]))
				var b := Vector2(float(points[i][0]),float(points[i][1]))
				if Geometry2D.get_closest_point_to_segment(at,a,b).distance_to(at)<9:
					return
	occupied[key]=true
	var spec: Dictionary = cfg.layers[layer]
	var models: Array = spec.models
	out[layer].append({"model":models[rng.randi_range(0,models.size()-1)],"position":Vector3(at.x,h,at.y),"yaw":rng.randf_range(0,TAU),"scale":rng.randf_range(float(spec.scale_min),float(spec.scale_max))})
