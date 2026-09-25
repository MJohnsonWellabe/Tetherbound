extends "res://tests/test_case.gd"

## The committed Stormwood forest bake keeps its trunks and rocks off every
## authored seat (trainer, NPC, harvest node, pickup), out of every landmark
## sightline and out of each pocket mouth's approach cone. Read from the
## production bake files, so a re-bake that drops a clearing fails here.
const BAKE := preload("res://scripts/world/scatter_bake.gd")
const SCATTER := preload("res://scripts/world/stormwood_scatter.gd")
const POCKETS := preload("res://scripts/world/stormwood_pockets.gd")
const BAKE_DIR := "res://data/scatter/stormwood"
## The brief's floor: no collider surface within ~3 m of a trainer or NPC and
## ~1.5 m of a pickup or harvest node. The config may only be stricter.
const FLOOR_M := {"trainer": 3.0, "npc": 3.0, "harvest": 1.5, "pickup": 1.5}
const TREE_LAYERS: Array[String] = ["storm_canopy", "storm_deadwood", "crown_canopy"]


func _placements() -> Dictionary:
	var layers := {}
	var drained := {}
	for file_name: String in DirAccess.get_files_at(BAKE_DIR):
		if file_name.begins_with("region_") and file_name.ends_with(".bin"):
			var file := FileAccess.open("%s/%s" % [BAKE_DIR, file_name], FileAccess.READ)
			if file != null:
				BAKE._read_region(file, layers, drained)
	return layers


func test_the_committed_bake_is_fresh() -> void:
	assert_true(BAKE.is_fresh("stormwood", int(SCATTER.config().seed), SCATTER.fingerprint()),
		"the committed Stormwood scatter bake matches its sources, seats included")


func test_seat_clearances_are_config_driven_and_meet_the_floor() -> void:
	var clearings: Dictionary = SCATTER.config().seat_clearings
	for kind: String in FLOOR_M:
		assert_true(float(clearings.collider_surface_m[kind]) >= float(FLOOR_M[kind]),
			"%s collider clearance %.2f m is under the %.1f m floor" % [kind, float(clearings.collider_surface_m[kind]), float(FLOOR_M[kind])])
		assert_true(float(clearings.ground_cover_m[kind]) > 0.0, "%s keeps some ground cover off its seat" % kind)
	assert_true(SCATTER.seats().size() > 400, "every trainer, NPC, harvest and pickup seat is read")


func test_no_baked_collider_or_ground_cover_crowds_an_authored_seat() -> void:
	var config := SCATTER.config()
	var clearings: Dictionary = config.seat_clearings
	var layers := _placements()
	# Colliders and ground cover bucketed on a 16 m grid; every clearance is
	# well under one cell, so a 3 x 3 lookup is exhaustive.
	var grid := {}
	for layer: String in layers:
		var spec: Dictionary = config.layers[layer]
		var collides := bool(spec.get("collides", false))
		for entry: Dictionary in layers[layer]:
			var point: Vector3 = entry.placement.position
			var at := Vector2(point.x, point.z)
			var cell := Vector2i(floori(at.x / 16.0), floori(at.y / 16.0))
			if not grid.has(cell):
				grid[cell] = []
			var reach := float(spec.collision_radius) * float(entry.placement.scale) if collides else 0.0
			(grid[cell] as Array).append([at, collides, reach, layer])
	var failures := 0
	for seat: Dictionary in SCATTER.seats():
		var at: Vector2 = seat.at
		var cell := Vector2i(floori(at.x / 16.0), floori(at.y / 16.0))
		var surface := INF
		var cover := INF
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				for row: Array in grid.get(cell + Vector2i(dx, dz), []):
					var d := at.distance_to(row[0] as Vector2)
					if bool(row[1]):
						surface = minf(surface, d - float(row[2]))
					else:
						cover = minf(cover, d)
		var need := float(clearings.collider_surface_m[seat.kind])
		if surface < need:
			failures += 1
			assert_true(false, "%s %s at (%.0f, %.0f): a baked collider surface %.2f m away (needs %.1f m)" % [
				seat.kind, seat.id, at.x, at.y, surface, need])
		var need_cover := float(clearings.ground_cover_m[seat.kind])
		if cover < need_cover:
			failures += 1
			assert_true(false, "%s %s at (%.0f, %.0f): baked ground cover %.2f m away (needs %.1f m)" % [
				seat.kind, seat.id, at.x, at.y, cover, need_cover])
	assert_eq(failures, 0, "authored seats crowded by the forest bake")


func test_no_baked_tree_stands_in_a_landmark_sightline() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_world.json"))
	var layers := _placements()
	var ids: Array[String] = []
	for sightline: Dictionary in world.landmark_sightlines:
		ids.append(str(sightline.id))
		var a := Vector2(float(sightline.from[0]), float(sightline.from[1]))
		var b := Vector2(float(sightline.to[0]), float(sightline.to[1]))
		var inside := 0
		for layer: String in TREE_LAYERS:
			for entry: Dictionary in layers.get(layer, []):
				var point: Vector3 = entry.placement.position
				var at := Vector2(point.x, point.z)
				if Geometry2D.get_closest_point_to_segment(at, a, b).distance_to(at) < float(sightline.clear_radius_m):
					inside += 1
		assert_eq(inside, 0, "%s: baked trees inside the sightline" % sightline.id)
	assert_true(ids.has("dynamo_west_to_stormheart"), "dynamo_west_approach keeps the Dynamo tower in view")


func test_each_pocket_mouth_approach_cone_is_clear() -> void:
	var cfg := POCKETS.config()
	var approach: Dictionary = cfg.approach_clear
	var config := SCATTER.config()
	var layers := _placements()
	var slope := tan(deg_to_rad(float(approach.half_angle_deg)))
	for pocket: Dictionary in cfg.pockets:
		var f := POCKETS.frame(pocket)
		var forward: Vector2 = f.forward
		var mouth: Vector2 = (f.centre as Vector2) + forward * (float(cfg.interior_half_m) + float(cfg.wall_thickness_m))
		var blockers: Array[String] = []
		for layer: String in layers:
			var tall := TREE_LAYERS.has(layer) or bool((config.layers[layer] as Dictionary).get("collides", false))
			var length := float(approach.length_m) if tall else float(approach.ground_cover_length_m)
			for entry: Dictionary in layers[layer]:
				var point: Vector3 = entry.placement.position
				var local := Vector2(point.x, point.z) - mouth
				var ahead := local.dot(forward)
				if ahead < 0.0 or ahead > length:
					continue
				if absf(local.cross(forward)) < float(approach.mouth_half_width_m) + ahead * slope:
					blockers.append("%s at %.0f m" % [layer, ahead])
		assert_true(blockers.is_empty(), "%s's approach cone holds %s" % [pocket.id, ", ".join(blockers)])
