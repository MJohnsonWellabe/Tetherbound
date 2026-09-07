extends "res://tests/test_case.gd"
const FIELD := preload("res://scripts/world/water_heightfield.gd")

func test_island_harvest_minima_and_new_dry_approaches() -> void:
	var field := FIELD.new()
	var world := FIELD.load_config()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	var counts := {}
	var ids := {}
	var additions := 0
	for row: Dictionary in data.harvest:
		assert_false(ids.has(row.id), "Stable harvest identity must be unique")
		ids[row.id] = true
		counts[row.island_id] = int(counts.get(row.island_id, 0)) + 1
		if row.get("placement_revision", "") != "density_wave3": continue
		additions += 1
		var at := _xz(row.position)
		assert_eq(row.evidence_status, "analytic_approach_only_not_baked_or_walked")
		assert_true(field.height_at(at.x, at.y) >= 0.8, "Dry resource center: " + str(row.id))
		for offset: Vector2 in [Vector2(-1,-1), Vector2(-1,1), Vector2(1,-1), Vector2(1,1)]:
			var p := at + offset
			assert_true(field.height_at(p.x,p.y) >= 0.8 and field.slope_degrees_at(p.x,p.y) <= 35.0, "Dry gentle resource footprint")
		for other: Dictionary in data.pickups + data.harvest:
			if other.id == row.id: continue
			assert_true(at.distance_to(_xz(other.position)) >= 5.99, "Resource/pickup spacing: " + str(row.id))
		for anchor: Dictionary in world.anchors:
			assert_true(at.distance_to(_xz(anchor.safe_position)) >= 12.0, "Landing remains clear")
		var closest := INF
		for route: Dictionary in world.land_routes:
			for i in range(route.polyline.size()-1):
				closest = minf(closest, at.distance_to(Geometry2D.get_closest_point_to_segment(at, _xz(route.polyline[i]), _xz(route.polyline[i+1]))))
		assert_true(closest >= 5.99, "Resource leaves the walking route clear")
		var approach: Array = row.get("approach_polyline", [row.get("approach_from", row.position), row.position])
		for i in range(approach.size()-1):
			var a := _xz(approach[i])
			var b := _xz(approach[i+1])
			for step in range(int(ceil(a.distance_to(b)))+1):
				var p := a.move_toward(b,step)
				assert_true(field.height_at(p.x,p.y) >= 0.8 and field.slope_degrees_at(p.x,p.y) <= 35.0, "Analytic approach remains dry and within authored grade: " + str(row.id))
		if row.island_id == "tidal_cradle":
			assert_true(at.distance_to(Vector2(601,1389)) > 120.0, "Keep planned Alpha shore basin clear")
	for island: Dictionary in world.islands:
		assert_true(int(counts.get(island.id,0)) >= (14 if island.main_path else 8), "BUILD per-island harvest minimum: " + str(island.id))
		assert_eq(int(data.census.by_island[island.id].harvest), int(counts.get(island.id,0)))
	assert_eq(additions, 22)
	assert_eq(data.harvest.size(), 182)
	assert_eq(int(data.census.harvest), 182)

func _xz(at: Array) -> Vector2:
	return Vector2(at[0], at[2])
