extends SceneTree
## B14: band2 (Stone & Root) walks INTO the Old Quarry -- its authored vertex
## (400,1800) is the quarry floor, where `quarry_haul_road` starts -- and back
## out toward (330,1950). Players stuck there: a quarry_station bag and rock,
## the larger foundation slab and the pit's east wall all had colliders on the
## centreline, and the picket Dorn's body stood on the road at (315,1668).
##
## This sweeps a player-sized capsule, lifted a step off the terrain, every
## STEP_M along the band's own polyline from the leg's first point through
## the vertex and out, on the centreline and LANE_M either side, against every
## static collider with scatter forced resident. Anything it touches within
## CHECK_RADIUS_M of the vertex, or any trainer body on the whole leg, fails.
## Band points come from terrain_playground.json, so a re-authored road is
## what gets checked.
##
##   godot --headless --path . --script tests/smoke_quarry_leg_walkable.gd

const SCENE := "res://scenes/world/meadows_playground.tscn"
const TERRAIN_PATH := "res://data/config/terrain_playground.json"
const BAND_ID := "band2_stone_and_root"
const VERTEX := Vector2(400.0, 1800.0)
const LEG_FROM := Vector2(310.0, 1660.0)
const LEG_TO := Vector2(330.0, 1950.0)
const CHECK_RADIUS_M := 25.0
const LANE_M := 0.5
const SETTLE_FRAMES := 240
const STEP_M := 1.0
const BODY_RADIUS := 0.4
const BODY_HEIGHT := 1.8
const STEP_CLEAR_M := 0.35

var _world: Node3D
var _terrain_data: Object


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var leg := _band_leg()
	if leg.size() < 3:
		print("FAIL: %s has no %s -> %s -> %s leg in %s" % [BAND_ID, LEG_FROM, VERTEX, LEG_TO, TERRAIN_PATH])
		quit(1)
		return
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

	var blockers := {}
	var samples := 0
	for i in leg.size() - 1:
		var a: Vector2 = leg[i]
		var b: Vector2 = leg[i + 1]
		var side := (b - a).normalized().orthogonal()
		var n := maxi(1, int(ceil(a.distance_to(b) / STEP_M)))
		for k in n + 1:
			var centre := a.lerp(b, float(k) / float(n))
			for lane: float in [-LANE_M, 0.0, LANE_M]:
				var p := centre + side * lane
				samples += 1
				q.transform = Transform3D(Basis(), Vector3(p.x, _ground(p) + STEP_CLEAR_M + BODY_HEIGHT * 0.5, p.y))
				for hit: Dictionary in space.intersect_shape(q, 8):
					var c := hit.get("collider") as Node
					if c == null or c is CharacterBody3D and c.name == "Player":
						continue
					var path := str(c.get_path())
					var near_vertex := p.distance_to(VERTEX) <= CHECK_RADIUS_M
					if near_vertex or path.contains("/Trainers/"):
						if not blockers.has(path):
							blockers[path] = p
	print("quarry leg: %d capsule samples on %s" % [samples, str(leg)])
	if blockers.is_empty():
		print("PASS: band2's quarry leg is walkable -- no collider on the centreline or %.1fm either side within %.0fm of %s, and no trainer body on the leg" % [LANE_M, CHECK_RADIUS_M, VERTEX])
		quit(0)
		return
	for path: String in blockers:
		print("FAIL: %s blocks band2's quarry leg at %s" % [path.get_slice("MeadowsPlayground/", 1), str(blockers[path])])
	quit(1)


## The band's own points from LEG_FROM through VERTEX to LEG_TO.
func _band_leg() -> Array[Vector2]:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN_PATH))
	var out: Array[Vector2] = []
	for raw: Variant in ((cfg.get("trail", {}) as Dictionary).get("bands", []) as Array):
		if str((raw as Dictionary).get("id", "")) != BAND_ID:
			continue
		var on := false
		for pt: Variant in ((raw as Dictionary).get("points", []) as Array):
			var v := Vector2(float(pt[0]), float(pt[1]))
			if v.is_equal_approx(LEG_FROM):
				on = true
			if on:
				out.append(v)
			if on and v.is_equal_approx(LEG_TO):
				break
	return out


func _ground(p: Vector2) -> float:
	if _terrain_data == null:
		return 0.0
	var g := float(_terrain_data.call("get_height", Vector3(p.x, 0.0, p.y)))
	return 0.0 if is_nan(g) else g
