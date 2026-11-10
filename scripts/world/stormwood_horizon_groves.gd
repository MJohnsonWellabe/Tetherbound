extends RefCounted

## Stormwood swing part 2 (`groves_1110` in stormwood_destination_dressing.json,
## OFF until judged). GPU judges at the open Stormwood stands (F41#4, #5, #12,
## #17) name a flat horizon: fogged far terrain and a painted sky treeline read
## as one pale slab behind a thin row of trees. This plants real tree
## silhouettes in clumped, layered bands 150-450 m out from each listed stand, so the
## horizon steps back through near grove, far grove and the sky treeline.
##
## Presentation only. The trees are the scatter's own finished render meshes
## (`vegetation.gd registered_mesh()`: same retint, fades and LODs), drawn as
## MultiMeshes with no collider, no harvest and no durable state, on drawing
## shells only. Placement is deterministic per seed, so every client agrees.
## Bands skip any point near a route (route_half_width + route_margin_m), an
## authored seat, any landmark, or ground below the band's floor (the crater
## and the Glass Sink), so no road, stand or fight space gains a tree.

const CONFIG := "res://data/config/stormwood_destination_dressing.json"
const WORLD := "res://data/config/stormwood_world.json"
const TERRAIN := "res://data/config/terrain_stormwood.json"
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")


static func config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONFIG))
	return (parsed as Dictionary).get("groves_1110", {}) if parsed is Dictionary else {}


## Every grove placement as {model, at: Vector2, scale, yaw}. Pure: the world
## supplies height and nothing here touches the scene, so tests can call it.
static func placements(cfg: Dictionary, height_at: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORLD))
	var half := float((JSON.parse_string(FileAccess.get_file_as_string(TERRAIN)) as Dictionary).route_half_width)
	var road_clear := half + float(cfg.get("route_margin_m", 14.0))
	var roads: Array[PackedVector2Array] = []
	for route: Dictionary in world.routes:
		var line := PackedVector2Array()
		for raw: Array in route.points:
			line.append(Vector2(float(raw[0]), float(raw[1])))
		roads.append(line)
	var keep_out: Array[Vector2] = []
	for landmark: Dictionary in world.get("landmarks", []):
		keep_out.append(Vector2(float(landmark.position[0]), float(landmark.position[2])))
	var seats: Array[Vector2] = []
	for seat: Dictionary in SCATTER.seats():
		seats.append(seat.at)
	var landmark_clear := float(cfg.get("landmark_margin_m", 70.0))
	var seat_clear := float(cfg.get("seat_margin_m", 12.0))
	var rng := RandomNumberGenerator.new()
	for grove: Dictionary in cfg.get("groves", []):
		var centre := Vector2(float(grove.centre[0]), float(grove.centre[1]))
		var floor_y := float(grove.get("min_ground_y", -INF))
		for band: Dictionary in grove.get("bands", []):
			var r_in := float(band.radius_m[0])
			var r_out := float(band.radius_m[1])
			var step := float(band.spacing_m)
			var n := int(ceil(r_out / step))
			var models: Array = band.models
			for gz in range(-n, n + 1):
				for gx in range(-n, n + 1):
					rng.seed = hash("%s:%s:%d:%d:%d" % [str(grove.id), str(band.id), int(cfg.get("seed", 1110)), gx, gz])
					var at := centre + Vector2(gx, gz) * step + Vector2(rng.randf_range(-0.4, 0.4), rng.randf_range(-0.4, 0.4)) * step
					var d := at.distance_to(centre)
					if d < r_in or d > r_out or rng.randf() < float(band.get("skip", 0.2)):
						continue
					# Groves, not a wall: a low-frequency mask keeps clumps and
					# opens gaps through which the next band and the sky
					# treeline show.
					var clump: Dictionary = band.get("cluster", {})
					if not clump.is_empty() and _clump(at / float(clump.scale_m), int(cfg.get("seed", 1110))) < float(clump.threshold):
						continue
					if _near_any_line(at, roads, road_clear) or _near_any(at, keep_out, landmark_clear) or _near_any(at, seats, seat_clear):
						continue
					var y := float(height_at.call(at.x, at.y))
					if is_nan(y) or y < floor_y:
						continue
					var scale_range: Array = band.scale
					out.append({
						"model": str(models[rng.randi() % models.size()]),
						"at": at, "y": y,
						"scale": rng.randf_range(float(scale_range[0]), float(scale_range[1])),
						"yaw": rng.randf() * TAU,
						"height_offset": float(band.get("height_offset", 0.0)),
					})
	return out


static func install(world: Node3D, vegetation: Node) -> int:
	var cfg := config()
	if not bool(cfg.get("enabled", false)) or bool(world.get("simulation_only")) or vegetation == null:
		return 0
	var placed := placements(cfg, Callable(world, "ground_height_at"))
	var root := Node3D.new()
	root.name = "HorizonGroves1110"
	world.add_child(root)
	# One MultiMesh per model and sector, so mesh LODs and culling work per
	# patch rather than across a ring several hundred metres wide.
	var sector_m := float(cfg.get("sector_m", 160.0))
	var buckets: Dictionary = {}
	for p: Dictionary in placed:
		var at: Vector2 = p.at
		var key := "%s|%d|%d" % [p.model, floori(at.x / sector_m), floori(at.y / sector_m)]
		if not buckets.has(key):
			buckets[key] = []
		(buckets[key] as Array).append(p)
	var meshes: Dictionary = {}
	var drawn := 0
	for key: String in buckets.keys():
		var model := key.get_slice("|", 0)
		if not meshes.has(model):
			meshes[model] = vegetation.call("registered_mesh", model) if vegetation.has_method("registered_mesh") else null
		var mesh: Mesh = meshes[model]
		if mesh == null:
			continue
		var rows: Array = buckets[key]
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Grove_%s_%d" % [model.get_file().get_basename(), drawn]
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(cfg.get("casts_shadow", false)) \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.visibility_range_end = float(cfg.get("visibility_range_end_m", 1100.0))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = rows.size()
		for i in rows.size():
			var p: Dictionary = rows[i]
			var basis := Basis(Vector3.UP, float(p.yaw)).scaled(Vector3.ONE * float(p.scale))
			var origin := Vector3((p.at as Vector2).x, float(p.y), (p.at as Vector2).y)
			mm.set_instance_transform(i, Transform3D(basis, origin + basis.y * float(p.height_offset)))
		mmi.multimesh = mm
		root.add_child(mmi)
		drawn += rows.size()
	root.set_meta("placed", drawn)
	return drawn


## Smooth value noise in [0, 1] on a unit grid (bilinear over hashed corners).
static func _clump(p: Vector2, seed: int) -> float:
	var i := Vector2i(floori(p.x), floori(p.y))
	var f := p - Vector2(i)
	f = f * f * (Vector2(3, 3) - 2.0 * f)
	var a := _corner(i, seed)
	var b := _corner(i + Vector2i(1, 0), seed)
	var c := _corner(i + Vector2i(0, 1), seed)
	var e := _corner(i + Vector2i(1, 1), seed)
	return lerpf(lerpf(a, b, f.x), lerpf(c, e, f.x), f.y)


static func _corner(i: Vector2i, seed: int) -> float:
	return float(hash("%d:%d:%d" % [seed, i.x, i.y]) & 0xFFFF) / 65535.0


static func _near_any(at: Vector2, points: Array[Vector2], radius: float) -> bool:
	for p: Vector2 in points:
		if at.distance_to(p) < radius:
			return true
	return false


static func _near_any_line(at: Vector2, lines: Array[PackedVector2Array], radius: float) -> bool:
	for line: PackedVector2Array in lines:
		for i in range(1, line.size()):
			if at.distance_to(Geometry2D.get_closest_point_to_segment(at, line[i - 1], line[i])) < radius:
				return true
	return false
