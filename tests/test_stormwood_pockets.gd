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


class FixtureWorld extends Node3D:
	var simulation_only := true
	var field := FIELD.new()

	func ground_height_at(x: float, z: float) -> float:
		return field.height_at(x, z)


func _json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path)) as Dictionary


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
		for route: Dictionary in world.routes:
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
		assert_eq(body.get_child_count(), walls.size(), "%s: one collider per wall segment (no models headless)" % pocket.id)
		for child: Node in body.get_children():
			var shape := (child as CollisionShape3D).shape as BoxShape3D
			var top := (child as CollisionShape3D).position.y + shape.size.y * 0.5
			var at := Vector2((child as CollisionShape3D).position.x, (child as CollisionShape3D).position.z)
			assert_true(top >= world.ground_height_at(at.x, at.y) + float(cfg.wall_height_m) - 0.01,
				"%s wall stands %.1f m above its ground" % [pocket.id, float(cfg.wall_height_m)])
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
