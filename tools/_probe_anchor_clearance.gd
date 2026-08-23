extends SceneTree

## STRONGHOLD-R2 scratch: does a scatter anchor still have room after the
## stronghold approach road landed? Prints each anchor's distance to the
## nearest road and its slope, so a nudge can be checked before a re-bake
## rather than after a test run.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const WATCH := [
	Vector2(58.0, -135.3),
	Vector2(60.5, -133.7),
	Vector2(62.0, -136.0),
	Vector2(56.0, -130.0),
]


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	for spot: Vector2 in WATCH:
		var nearest := INF
		for entry: Variant in field.call("road_bands"):
			var band: Dictionary = entry
			var line: PackedVector2Array = band["line"]
			for i in line.size() - 1:
				nearest = minf(nearest, _segment_distance(spot, line[i], line[i + 1]))
		print("(%.1f, %.1f): %.2fm from the nearest road, path_factor %.3f, slope %.1f deg" % [
			spot.x, spot.y, nearest,
			field.call("path_factor", spot.x, spot.y),
			field.call("slope_degrees_at", spot.x, spot.y, 1.0)])
	quit(0)


func _segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	if ab.length_squared() < 0.0001:
		return point.distance_to(a)
	var t := clampf((point - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return point.distance_to(a + ab * t)
