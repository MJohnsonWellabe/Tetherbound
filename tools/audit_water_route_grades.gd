extends SceneTree
## Read-only geometry audit: never lowers authored waypoints or edits config.
## Samples the actual analytic graded surface, not raw polyline rise/run.
const FIELD := preload("res://scripts/world/water_heightfield.gd")
func _init() -> void:
	var config := FIELD.load_config()
	var field := FIELD.new(config)
	var failures: Array = []
	for route: Dictionary in config.land_routes:
		var points: Array = route.polyline
		var maximum := 0.0
		for i in points.size() - 1:
			var a := Vector3(float(points[i][0]), float(points[i][1]), float(points[i][2]))
			var b := Vector3(float(points[i + 1][0]), float(points[i + 1][1]), float(points[i + 1][2]))
			var count := maxi(1, ceili(a.distance_to(b)))
			for step in count:
				var at := a.lerp(b, float(step) / float(count))
				var slope: float = field.slope_degrees_at(at.x, at.z, 0.5)
				maximum = maxf(maximum, slope)
				if slope > 35.0:
					failures.append({"route": route.id, "position": [at.x, at.z], "slope": slope})
		print("WATER GRADE %s max_slope=%.2f" % [route.id, maximum])
	print("WATER GRADE steep_samples=%d" % failures.size())
	var report := FileAccess.open("user://water-route-grade-audit.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(failures, "  "))
	quit(0)
