extends SceneTree

## Offline authoring pass: lower excessive route grades without raising either
## shoreline endpoint. The resulting JSON is reviewable; bake separately.
const FIELD := preload("res://scripts/world/water_heightfield.gd")

func _init() -> void:
	var config := FIELD.load_config()
	config.terrain.trail_grading = {
		"enabled": true, "grid_pitch_m": 32.0, "flat_half_width_m": 3.0,
		"feather_m": 15.0, "preserve_shore_band_m": 22.0, "shore_blend_m": 10.0,
		"maximum_centerline_grade_deg": 20.0,
		"_comment": "Starting 6m walk surface, 15m graded shoulders, spatial 32m lookup. Preserve outer 22m coast and all safe shore anchors; blend inland over 10m. Grade targets require baked real-body walks."
	}
	var rise_per_m := tan(deg_to_rad(20.0))
	for route: Dictionary in config.land_routes:
		var points: Array = route.polyline
		if str(route.id) == "veilfall_exploration_spine" and not bool(route.get("hike_ends_at_gate", false)):
			# The hike goes around the mountain to the falls; the original planning
			# polyline crossed itself and descended straight through its own climb.
			points = [points[0], points[3], points[1], points[2]]
			route.polyline = points
			route.hike_ends_at_gate = true
		if not bool(route.get("radial_landing_approaches", false)):
			var island: Dictionary = {}
			for row: Dictionary in config.islands:
				if str(row.id) == str(route.island_id):
					island = row
			var centre := Vector2(float(island.center_xz_m[0]), float(island.center_xz_m[1]))
			for index in [points.size() - 1, 0]:
				var endpoint: Array = points[index]
				var offset := Vector2(float(endpoint[0]), float(endpoint[2])) - centre
				if offset.length() < float(island.shore_radius_m) - 24.0:
					continue
				var inland := centre + offset.normalized() * (float(island.shore_radius_m) - 38.0)
				var added := [inland.x, 6.0, inland.y]
				points.insert(1 if index == 0 else index, added)
			route.radial_landing_approaches = true
		for _pass in points.size() * 2:
			for i in range(1, points.size() - 1):
				for j in [i - 1, i + 1]:
					var distance := Vector2(float(points[i][0]) - float(points[j][0]), float(points[i][2]) - float(points[j][2])).length()
					points[i][1] = snappedf(minf(float(points[i][1]), float(points[j][1]) + distance * rise_per_m), 0.001)
		route.grading_status = "analytic_trail_modifier_authored_bake_and_walk_required"
	var file := FileAccess.open(FIELD.CONFIG_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(config, "  ") + "\n")
	file.close()
	var field := FIELD.new(config)
	var failures: Array = []
	for route: Dictionary in config.land_routes:
		var points: Array = route.polyline
		var maximum := 0.0
		for i in points.size() - 1:
			var a := Vector3(float(points[i][0]), float(points[i][1]), float(points[i][2]))
			var b := Vector3(float(points[i + 1][0]), float(points[i + 1][1]), float(points[i + 1][2]))
			for step in maxi(1, ceili(a.distance_to(b))):
				var at := a.lerp(b, float(step) / float(maxi(1, ceili(a.distance_to(b)))))
				var slope: float = field.slope_degrees_at(at.x, at.z, 0.5)
				maximum = maxf(maximum, slope)
				if slope > 35.0:
					failures.append({"route": route.id, "position": [at.x, at.z], "slope": slope})
		print("WATER GRADE %s max_slope=%.2f" % [route.id, maximum])
	print("WATER GRADE steep_samples=%d" % failures.size())
	var report := FileAccess.open("user://water-route-grade-audit.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(failures, "  "))
	quit(0)
