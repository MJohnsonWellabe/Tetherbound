extends SceneTree

## F01 walks: what solid body stands ON a road? The walk stalled twice against
## baked Rock_Medium_1 scatter whose origin sat just outside path_factor's
## 1.8m origin exclusion while its collider covered the centreline. This scans
## every village road polyline (paths.routes, paths.approaches) and the Lower
## Meadows spine (trail.bands band1_lower_meadows) every STEP_M: a player-sized
## capsule lifted STEP_CLEAR_M off the terrain on the centreline, tested against
## every static collider with every scatter collider forced resident. Prints one
## line per distinct blocker (node path, first/last road sample it blocks).
##
##   flock <writer-lock> godot --headless --path . --script tests/probe_road_blockers.gd
##
## Inert: a standalone SceneTree script, not a test_*.gd. Writes nothing.

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const SETTLE_FRAMES := 240
const STEP_M := 1.0
const BODY_RADIUS := 0.4
const BODY_HEIGHT := 1.8
const STEP_CLEAR_M := 0.35
const SPINE_ID := "band1_lower_meadows"

var _world: Node3D
var _terrain_data: Object


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_world = (load(SCENE) as PackedScene).instantiate() as Node3D
	root.add_child(_world)
	current_scene = _world
	for _i in SETTLE_FRAMES:
		await physics_frame
	for n in _world.find_children("*", "Terrain3D", true, false):
		_terrain_data = n.get("data")
		break
	var veg := _world.get_node_or_null(^"Vegetation")
	if veg != null:
		veg.set("COLLISION_STREAM_RADIUS", 100000.0)
		veg.call("force_collision_resident", "")
	for _i in 30:
		await physics_frame
	var space := _world.get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	var player := _world.get_node_or_null(^"Player") as CollisionObject3D
	if player != null:
		exclude.append(player.get_rid())
	var shape := CapsuleShape3D.new()
	shape.radius = BODY_RADIUS
	shape.height = BODY_HEIGHT
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = shape
	q.exclude = exclude
	q.collide_with_areas = false

	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN_PATH))
	var paths: Dictionary = cfg.get("paths", {})
	var roads := {}
	for raw: Variant in (paths.get("routes", []) as Array) + (paths.get("approaches", []) as Array):
		var entry := raw as Dictionary
		roads[str(entry.get("id", entry.get("label", "")))] = entry.get("points", [])
	for raw: Variant in ((cfg.get("trail", {}) as Dictionary).get("bands", []) as Array):
		if str((raw as Dictionary).get("id", "")) == SPINE_ID:
			roads[SPINE_ID] = (raw as Dictionary).get("points", [])

	var found := {}  # collider path -> {road, first, last, count}
	var samples := 0
	for road: String in roads:
		var pts: Array = roads[road]
		var arc := 0.0
		for i in pts.size() - 1:
			var a := Vector2(float(pts[i][0]), float(pts[i][1]))
			var b := Vector2(float(pts[i + 1][0]), float(pts[i + 1][1]))
			var n := maxi(1, int(ceil(a.distance_to(b) / STEP_M)))
			for k in n:
				var p := a.lerp(b, float(k) / float(n))
				samples += 1
				var g := _ground(p.x, p.y)
				q.transform = Transform3D(Basis(), Vector3(p.x, g + STEP_CLEAR_M + BODY_HEIGHT * 0.5, p.y))
				for hit: Dictionary in space.intersect_shape(q, 4):
					var c := hit.get("collider") as Node
					if c == null or c is CharacterBody3D:
						continue
					# Scatter shares one body per model, so key those by a 4m cell:
					# each distinct rock or tree gets its own line.
					var key := "%s|%s" % [road, str(c.get_path())]
					if str(c.get_path()).contains("/Vegetation/"):
						key += "|%d,%d" % [floori(p.x / 4.0), floori(p.y / 4.0)]
					if not found.has(key):
						found[key] = {"road": road, "node": str(c.get_path()), "first": p, "last": p,
							"arc": arc + a.distance_to(p), "count": 0}
					found[key].last = p
					found[key].count += 1
			arc += a.distance_to(b)
	print("[road-blockers] %d road samples on %d roads; %d blockers" % [samples, roads.size(), found.size()])
	for key: String in found:
		var f: Dictionary = found[key]
		print("[road-blockers] road=%s arc=%.0f first=(%.1f,%.1f) last=(%.1f,%.1f) samples=%d node=%s" % [
			f.road, f.arc, f.first.x, f.first.y, f.last.x, f.last.y, f.count, f.node])
	quit(0)


func _ground(x: float, z: float) -> float:
	if _terrain_data == null:
		return 0.0
	var g := float(_terrain_data.call("get_height", Vector3(x, 0.0, z)))
	return 0.0 if is_nan(g) else g
