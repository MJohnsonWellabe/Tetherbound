extends "res://tests/test_case.gd"

## WORLD §5.1: five dead-end pockets (coordinator ruling: a walled dead-end
## clearing of installed static walls or deadwood with an existing reward moved
## inside). Walkability uses the production heightfield's true slope against
## the player's own floor limit; the walls are the same boxes the runtime
## builds (`stormwood_pockets.gd::wall_boxes`).
const POCKETS := preload("res://scripts/world/stormwood_pockets.gd")
const FIELD := preload("res://scripts/world/stormwood_heightfield.gd")
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")
const MAX_WALK_DEG := 45.0  # scenes/player/player.tscn floor_max_angle 0.7854
const CAPSULE_RADIUS := 0.4  # scenes/player/player.tscn
const WINDOW_HALF := 30
const BAKE_DIR := "res://data/scatter/stormwood"
const WORLD_PATH := "res://data/config/stormwood_world.json"
const TERRAIN_PATH := "res://data/config/terrain_stormwood.json"
## Collider buckets for the road-reach search; every grown reach (at most
## 2.61 + 0.4 m) plus half a 2 m step stays under one cell.
const COLLIDER_CELL_M := 8.0


class FixtureWorld extends Node3D:
	var simulation_only := true
	var field := FIELD.new()

	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


## The roads a pocket hangs off: every route except the pockets' own spurs.
func _roads(world: Dictionary) -> Array:
	var out: Array = []
	for route: Dictionary in world.routes:
		if str(route.get("kind", "")) != "spur":
			out.append(route)
	return out


func _xz(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))


func _distance_to_route(at: Vector2, route: Dictionary) -> float:
	var points: Array = route.points
	var nearest := INF
	for i in range(1, points.size()):
		nearest = minf(nearest, Geometry2D.get_closest_point_to_segment(at, _xz(points[i - 1]), _xz(points[i])).distance_to(at))
	return nearest


## Every committed baked collider as [centre XZ, collision_radius x scale],
## bucketed by COLLIDER_CELL_M.
func _baked_colliders() -> Dictionary:
	var scatter := SCATTER.config()
	var layers := {}
	var drained := {}
	for file_name: String in DirAccess.get_files_at(BAKE_DIR):
		if file_name.begins_with("region_") and file_name.ends_with(".bin"):
			var file := FileAccess.open("%s/%s" % [BAKE_DIR, file_name], FileAccess.READ)
			if file != null:
				BAKE._read_region(file, layers, drained)
	var grid := {}
	for layer: String in layers:
		var spec: Dictionary = scatter.layers[layer]
		if not bool(spec.get("collides", false)):
			continue
		for entry: Dictionary in layers[layer]:
			var point: Vector3 = entry.placement.position
			_bucket(grid, Vector2(point.x, point.z), float(spec.collision_radius) * float(entry.placement.scale))
	return grid


func _bucket(grid: Dictionary, at: Vector2, reach: float) -> void:
	var cell := Vector2i(floori(at.x / COLLIDER_CELL_M), floori(at.y / COLLIDER_CELL_M))
	if not grid.has(cell):
		grid[cell] = []
	(grid[cell] as Array).append([at, reach])


## True when the player's capsule, swept from `a` to `b`, touches a collider.
func _step_blocked(grid: Dictionary, a: Vector2, b: Vector2) -> bool:
	var mid := (a + b) * 0.5
	var cell := Vector2i(floori(mid.x / COLLIDER_CELL_M), floori(mid.y / COLLIDER_CELL_M))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for row: Array in grid.get(cell + Vector2i(dx, dz), []):
				var centre: Vector2 = row[0]
				if Geometry2D.get_closest_point_to_segment(centre, a, b).distance_to(centre) < float(row[1]) + CAPSULE_RADIUS:
					return true
	return false


## Breadth-first walk on a 2 m grid from 2 m outside `pocket`'s mouth. A step
## is legal when its ground is walkable (true slope <= 45 deg), it stays out
## of every pocket wall grown by the capsule, and the capsule's sweep touches
## no collider in `colliders`. Returns the route id reached (within the road
## corridor of a non-spur route) or "".
func _mouth_reaches_road(field: RefCounted, pocket: Dictionary, cfg: Dictionary, walls: Array[Dictionary],
		colliders: Dictionary, roads: Array, half_width: float) -> String:
	var f := POCKETS.frame(pocket)
	var start: Vector2 = POCKETS.FRAME.mouth(pocket, cfg) + (f.forward as Vector2) * 2.0
	var seen := {Vector2i.ZERO: true}
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	var head := 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		var at := start + Vector2(c) * 2.0
		for route: Dictionary in roads:
			if _distance_to_route(at, route) <= half_width:
				return str(route.id)
		if absi(c.x) > 220 or absi(c.y) > 220:
			continue
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if seen.has(n):
				continue
			seen[n] = true
			var q := start + Vector2(n) * 2.0
			if field.slope_degrees_at(q.x, q.y) > MAX_WALK_DEG or _in_wall(walls, cfg, q) or _step_blocked(colliders, at, q):
				continue
			queue.append(n)
	return ""


func _pickup(id: String) -> Dictionary:
	for row: Dictionary in _json("res://data/config/stormwood_pickups.json").pickups:
		if str(row.id) == id:
			return row
	return {}


## Inside a wall box grown by the player's capsule radius.
func _in_wall(walls: Array[Dictionary], cfg: Dictionary, at: Vector2) -> bool:
	for wall: Dictionary in walls:
		var local: Vector2 = at - (wall.centre as Vector2)
		var along: Vector2 = wall.along
		if absf(local.dot(along)) <= float(wall.length) * 0.5 + CAPSULE_RADIUS \
				and absf(local.dot(Vector2(along.y, -along.x))) <= float(cfg.wall_thickness_m) * 0.5 + CAPSULE_RADIUS:
			return true
	return false


## Breadth-first walk on a 1 m grid from the pocket centre; true when it
## reaches the edge of a 60 m window around the pocket.
func _escapes(field: RefCounted, pocket: Dictionary, cfg: Dictionary, walls: Array[Dictionary]) -> bool:
	var centre := Vector2(float(pocket.at[0]), float(pocket.at[1]))
	var seen := {Vector2i.ZERO: true}
	var queue: Array[Vector2i] = [Vector2i.ZERO]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_back()
		if absi(c.x) >= WINDOW_HALF or absi(c.y) >= WINDOW_HALF:
			return true
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if seen.has(n):
				continue
			seen[n] = true
			var at := centre + Vector2(n)
			if field.slope_degrees_at(at.x, at.y) > MAX_WALK_DEG or _in_wall(walls, cfg, at):
				continue
			queue.append(n)
	return false


func test_five_pockets_one_per_walkable_region_each_holding_a_moved_reward() -> void:
	var cfg := POCKETS.config()
	var world := _json("res://data/config/stormwood_world.json")
	assert_eq(cfg.pockets.size(), 5, "WORLD §5.1 asks for five dead-end pockets")
	var regions := {}
	for pocket: Dictionary in cfg.pockets:
		regions[str(pocket.region_id)] = true
		var reward := _pickup(str(pocket.reward_pickup_id))
		assert_false(reward.is_empty(), "%s holds an existing pickup" % pocket.id)
		if reward.is_empty():
			continue
		assert_eq(str(reward.region_id), str(pocket.region_id), "%s's reward stays in its region" % pocket.id)
		assert_eq(str(reward.placement), "optional_reward_pocket", "%s holds an optional reward, not a story item" % pocket.id)
		assert_eq(str(reward.get("pocket_id", "")), str(pocket.id))
		var at := Vector2(float(reward.position[0]), float(reward.position[2]))
		assert_true(POCKETS.contains(pocket, cfg, at), "%s's reward lies inside its walls" % pocket.id)
		for region: Dictionary in world.regions:
			if str(region.id) == str(pocket.region_id):
				var bounds: Dictionary = region.bounds
				assert_true(at.y >= float(bounds.min_z) and at.y < float(bounds.max_z), "%s sits in its region" % pocket.id)
				var gated := str(region.get("access", {}).get("requires_unlock", ""))
				assert_eq(str(reward.get("requires_unlock", "")), gated, "%s keeps its region's gate" % pocket.id)
	assert_eq(regions.keys().size(), 5, "one pocket in each walkable region (the Crown is arch-only)")
	assert_false(regions.has("hollow_crown"))


func test_each_pocket_is_a_walkable_dead_end_opening_only_at_its_mouth() -> void:
	var field := FIELD.new()
	var cfg := POCKETS.config()
	for pocket: Dictionary in cfg.pockets:
		var f := POCKETS.frame(pocket)
		var half := float(cfg.interior_half_m)
		var worst := 0.0
		for dx in range(-int(half), int(half) + 1):
			for dz in range(-int(half), int(half) + 1):
				var q: Vector2 = (f.centre as Vector2) + (f.right as Vector2) * dx + (f.forward as Vector2) * dz
				worst = maxf(worst, field.slope_degrees_at(q.x, q.y))
		assert_true(worst <= 30.0, "%s's interior is comfortable ground (%.1f deg)" % [pocket.id, worst])
		var walls := POCKETS.wall_boxes(pocket, cfg)
		assert_true(_escapes(field, pocket, cfg, walls), "%s opens through its mouth" % pocket.id)
		var sealed := walls.duplicate()
		sealed.append({"centre": (f.centre as Vector2) + (f.forward as Vector2) * (half + float(cfg.wall_thickness_m) * 0.5),
			"along": f.right, "length": float(cfg.mouth_width_m) + 1.0})
		assert_false(_escapes(field, pocket, cfg, sealed),
			"%s is closed everywhere except its mouth: a dead end" % pocket.id)


func test_pockets_sit_off_the_roads_with_their_mouths_toward_one() -> void:
	var cfg := POCKETS.config()
	var world := _json("res://data/config/stormwood_world.json")
	for pocket: Dictionary in cfg.pockets:
		var f := POCKETS.frame(pocket)
		var centre: Vector2 = f.centre
		var nearest := INF
		var toward := Vector2.ZERO
		for route: Dictionary in _roads(world):
			var points: Array = route.points
			for i in range(1, points.size()):
				var q := Geometry2D.get_closest_point_to_segment(centre,
					Vector2(float(points[i - 1][0]), float(points[i - 1][1])), Vector2(float(points[i][0]), float(points[i][1])))
				if q.distance_to(centre) < nearest:
					nearest = q.distance_to(centre)
					toward = (q - centre).normalized()
		assert_true(nearest >= 40.0, "%s is off the road, not a roadside stop (%.0f m)" % [pocket.id, nearest])
		assert_true((f.forward as Vector2).dot(toward) > 0.9, "%s's mouth faces its nearest road" % pocket.id)


func test_runtime_builds_every_wall_as_static_collision() -> void:
	var world := FixtureWorld.new()
	var cfg := POCKETS.config()
	var pockets := POCKETS.new()
	world.add_child(pockets)
	pockets.build(world)
	assert_eq(pockets.get_child_count(), 5)
	for pocket: Dictionary in cfg.pockets:
		var body := pockets.get_node_or_null("Pocket_%s" % str(pocket.id)) as StaticBody3D
		assert_true(body != null, "%s is a static body" % pocket.id)
		if body == null:
			continue
		var walls := POCKETS.wall_boxes(pocket, cfg)
		var posts := POCKETS.lure_posts(pocket, cfg)
		assert_eq(posts.size(), 2, "%s: a lure post either side of the mouth" % pocket.id)
		var junction_posts := POCKETS.spur_posts(pocket, cfg)
		assert_eq(junction_posts.size(), 2, "%s: a pair of lamps frames its spur's road junction" % pocket.id)
		assert_eq(body.get_child_count(), walls.size() + posts.size() + junction_posts.size(),
			"%s: one collider per wall segment, the two lure posts and the two junction posts (no models headless)" % pocket.id)
		for index in posts.size():
			assert_true(body.get_node_or_null("LurePost%d" % index) is CollisionShape3D, "%s: lure post %d collides" % [pocket.id, index])
		for index in junction_posts.size():
			var post_name := "SpurPost" + ("" if index == 0 else str(index + 1))
			var junction := body.get_node_or_null(post_name) as CollisionShape3D
			assert_true(junction != null, "%s: junction post %s collides" % [pocket.id, post_name])
			if junction != null:
				var marker: Vector2 = junction_posts[index].at
				assert_true(Vector2(junction.position.x, junction.position.z).is_equal_approx(marker), "%s: %s stands at its marker" % [pocket.id, post_name])
		for child: Node in body.get_children():
			if not str(child.name).begins_with("Wall"):
				continue
			var shape := (child as CollisionShape3D).shape as BoxShape3D
			var top := (child as CollisionShape3D).position.y + shape.size.y * 0.5
			var at := Vector2((child as CollisionShape3D).position.x, (child as CollisionShape3D).position.z)
			assert_true(top >= world.ground_height_at(at.x, at.y) + float(cfg.wall_height_m) - 0.01,
				"%s wall stands %.1f m above its ground" % [pocket.id, float(cfg.wall_height_m)])
	world.free()


func test_palisade_and_lamps_have_a_config_draw_distance() -> void:
	var world := FixtureWorld.new()
	world.simulation_only = false
	var cfg := POCKETS.config()
	var draw: Dictionary = cfg.draw_distance
	var pockets := POCKETS.new()
	world.add_child(pockets)
	pockets.build(world)
	var meshes := 0
	var unbounded := 0
	for node: Node in pockets.find_children("*", "GeometryInstance3D", true, false):
		meshes += 1
		var geometry := node as GeometryInstance3D
		if not is_equal_approx(geometry.visibility_range_end, float(draw.models_m)) \
				or geometry.visibility_range_fade_mode != GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF:
			unbounded += 1
	assert_true(meshes > 190, "the palisade trunks and lamp art are built (%d meshes)" % meshes)
	assert_eq(unbounded, 0, "every palisade and lamp mesh stops drawing at %.0f m" % float(draw.models_m))
	var lights := pockets.find_children("*", "OmniLight3D", true, false)
	assert_eq(lights.size(), cfg.pockets.size() * 4, "two mouth lamps and the two junction lamps per pocket")
	for node: Node in lights:
		var light := node as OmniLight3D
		var where := "%s/%s" % [light.get_parent().get_parent().name, light.get_parent().name]
		assert_true(light.distance_fade_enabled, "%s fades out with distance" % where)
		assert_true(is_equal_approx(light.distance_fade_begin + light.distance_fade_length, float(draw.lights_m)),
			"%s is gone by %.0f m" % [where, float(draw.lights_m)])
	world.free()


func test_the_forest_bake_keeps_colliders_out_of_every_pocket() -> void:
	assert_true(BAKE.is_fresh("stormwood", int(SCATTER.config().seed), SCATTER.fingerprint()),
		"the committed Stormwood scatter bake matches its sources")
	var cfg := POCKETS.config()
	var scatter := SCATTER.config()
	var radius := (float(cfg.interior_half_m) + float(cfg.wall_thickness_m)) * sqrt(2.0)
	for pocket: Dictionary in cfg.pockets:
		var at := Vector2(float(pocket.at[0]), float(pocket.at[1]))
		var layers := {}
		var drained := {}
		var region := BAKE.region_of(at, 512.0)
		var file := FileAccess.open("res://data/scatter/stormwood/region_%d_%d.bin" % [region.x, region.y], FileAccess.READ)
		if file != null:
			BAKE._read_region(file, layers, drained)
		for layer: String in layers:
			if not bool((scatter.layers[layer] as Dictionary).get("collides", false)):
				continue
			for entry: Dictionary in layers[layer]:
				var point: Vector3 = entry.placement.position
				var reach := float(scatter.layers[layer].collision_radius) * float(entry.placement.scale)
				assert_true(at.distance_to(Vector2(point.x, point.z)) - reach > radius,
					"%s: a baked %s stands inside the pocket" % [pocket.id, layer])


func test_no_wild_spawn_disc_reaches_into_a_pocket() -> void:
	# Spawn picking avoids baked scatter but not pocket walls, so a cluster's
	# whole spawn disc plus its wander must stay clear of every enclosure.
	var cfg := POCKETS.config()
	var wander := float(_json("res://data/config/combat.json").wild.wander_radius)
	var enclosure := (float(cfg.interior_half_m) + float(cfg.wall_thickness_m)) * sqrt(2.0)
	for row: Dictionary in _json("res://data/config/stormwood_encounters.json").wild_clusters:
		var at := Vector2(float(row.position[0]), float(row.position[2]))
		for pocket: Dictionary in cfg.pockets:
			var gap := at.distance_to(Vector2(float(pocket.at[0]), float(pocket.at[1]))) - float(row.radius) - wander
			assert_true(gap > enclosure, "%s's spawn disc reaches into %s" % [row.id, pocket.id])


## Every pocket's mouth connects to a road over ground the player can walk
## (true slope <= 45 deg), around every pocket wall, lamp post and committed
## baked tree or rock collider, each grown by the player's 0.4 m capsule: a
## 2 m grid search from just outside the mouth. Spurs are not targets; their
## cleared corridor is what the search is expected to use.
func test_each_pocket_mouth_is_walkable_from_a_road_around_every_collider() -> void:
	var field := FIELD.new()
	var cfg := POCKETS.config()
	var world := _json(WORLD_PATH)
	var roads := _roads(world)
	var half_width := float(_json(TERRAIN_PATH).route_half_width)
	var walls: Array[Dictionary] = []
	var colliders := _baked_colliders()
	var lamp_reach := float(cfg.mouth_lure.post_width_m) * sqrt(2.0) * 0.5
	for pocket: Dictionary in cfg.pockets:
		walls.append_array(POCKETS.wall_boxes(pocket, cfg))
		for post: Vector2 in POCKETS.lure_posts(pocket, cfg):
			_bucket(colliders, post, lamp_reach)
		var junction := POCKETS.spur_post(pocket, cfg)
		if not junction.is_empty():
			_bucket(colliders, junction.at, float(POCKETS.spur_lamp_style(cfg).post_width_m) * sqrt(2.0) * 0.5)
	assert_true(colliders.size() > 100, "the committed bake's colliders are loaded")
	for pocket: Dictionary in cfg.pockets:
		var reached := _mouth_reaches_road(field, pocket, cfg, walls, colliders, roads, half_width)
		assert_false(reached.is_empty(), "%s's mouth reaches a road on walkable, unobstructed ground" % pocket.id)
		# Built-in negative control: a ring of trunks around the mouth, closed
		# against the wall's outer face, must make the same search fail.
		var plugged := colliders.duplicate(true)
		var mouth: Vector2 = POCKETS.FRAME.mouth(pocket, cfg)
		for step in 72:
			_bucket(plugged, mouth + Vector2.from_angle(TAU * step / 72.0) * 12.0, 1.0)
		assert_eq(_mouth_reaches_road(field, pocket, cfg, walls, plugged, roads, half_width), "",
			"%s: a closed ring of trunk colliders outside the mouth blocks the search (control)" % pocket.id)


## Each pocket has one spur: it leaves the road it `joins` (that road is the
## pocket's nearest), ends at the mouth, keeps its road's unlock, and its
## junction lamp stands on the spur, clear of every road corridor.
func test_each_pocket_has_one_spur_from_its_road_to_its_mouth() -> void:
	var cfg := POCKETS.config()
	var world := _json(WORLD_PATH)
	var half_width := float(_json(TERRAIN_PATH).route_half_width)
	var roads := {}
	for route: Dictionary in _roads(world):
		roads[str(route.id)] = route
	var spurs := 0
	for route: Dictionary in world.routes:
		if str(route.get("kind", "")) == "spur":
			spurs += 1
	assert_eq(spurs, cfg.pockets.size(), "one spur per pocket, no stray spurs")
	var width := float(cfg.mouth_lure.post_width_m)
	for pocket: Dictionary in cfg.pockets:
		var spur := POCKETS.spur(pocket)
		assert_false(spur.is_empty(), "%s has a spur" % pocket.id)
		if spur.is_empty():
			continue
		var points: Array = spur.points
		var road: Dictionary = roads.get(str(spur.get("joins", "")), {})
		assert_false(road.is_empty(), "%s's spur joins an authored road" % pocket.id)
		if road.is_empty():
			continue
		var junction := _xz(points[0])
		assert_true(_distance_to_route(junction, road) <= 0.5, "%s's spur starts on %s" % [pocket.id, road.id])
		assert_true(_xz(points[points.size() - 1]).distance_to(POCKETS.FRAME.mouth(pocket, cfg)) <= 0.5,
			"%s's spur ends at its mouth" % pocket.id)
		var centre := Vector2(float(pocket.at[0]), float(pocket.at[1]))
		for other: Dictionary in roads.values():
			assert_true(_distance_to_route(centre, road) <= _distance_to_route(centre, other) + 0.01,
				"%s's spur joins its nearest road (%s is nearer than %s)" % [pocket.id, other.id, road.id])
		assert_eq(str(spur.get("requires_unlock", "")), str(road.get("requires_unlock", "")),
			"%s's spur keeps its road's unlock" % pocket.id)
		var pair := POCKETS.spur_posts(pocket, cfg)
		assert_eq(pair.size(), 2, "%s: two junction lamps" % pocket.id)
		var up := (_xz(points[1]) - junction).normalized()
		var sides: Array[float] = []
		for marker: Dictionary in pair:
			var at: Vector2 = marker.at
			for other: Dictionary in roads.values():
				assert_true(_distance_to_route(at, other) > half_width + width,
					"%s's junction lamp stands clear of %s's corridor" % [pocket.id, other.id])
			assert_true(_distance_to_route(at, spur) < half_width - width, "%s's junction lamp stands on its spur" % pocket.id)
			assert_true(at.distance_to(junction) < 15.0, "%s's junction lamp stands at the junction" % pocket.id)
			var toward_road := (junction - at).normalized()
			assert_true((marker.facing as Vector2).dot(toward_road) > 0.6, "%s's junction lantern faces the road" % pocket.id)
			sides.append((at - junction).cross(up))
		if sides.size() == 2:
			assert_true(sides[0] * sides[1] < 0.0, "%s's junction lamps stand either side of the spur (a gateway)" % pocket.id)


## The spur corridors are the cleared lanes: no committed baked trunk or rock
## surface inside the terrain contract's road half-width of any spur.
func test_the_forest_bake_keeps_every_spur_lane_clear() -> void:
	var world := _json(WORLD_PATH)
	var half_width := float(_json(TERRAIN_PATH).route_half_width)
	var colliders := _baked_colliders()
	for route: Dictionary in world.routes:
		if str(route.get("kind", "")) != "spur":
			continue
		var worst := INF
		for cell: Vector2i in colliders:
			for row: Array in colliders[cell]:
				worst = minf(worst, _distance_to_route(row[0] as Vector2, route) - float(row[1]))
		assert_true(worst >= half_width, "%s: a baked collider surface %.2f m from the lane's centre line (needs %.1f m)" % [
			route.id, worst, half_width])
