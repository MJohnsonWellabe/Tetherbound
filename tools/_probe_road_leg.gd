extends SceneTree

## STRONGHOLD-R2 scratch: worst slope and height profile along one authored
## leg, for checking a hand-set final approach the Dijkstra never proposed.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const LEG := [
	Vector2(74.0, -41.0),
	Vector2(61.0, -60.0),
	Vector2(55.0, -79.8),
	Vector2(57.0, -104.5),
	Vector2(60.8, -116.5),
	Vector2(73.5, -137.5),
	Vector2(92.2, -154.8),
	Vector2(126.0, -175.0),
	Vector2(154.5, -183.2),
	Vector2(189.0, -186.5),
	Vector2(204.0, -196.0),
	Vector2(216.0, -205.0),
	Vector2(226.0, -210.5),
	Vector2(232.0, -211.0),
	Vector2(235.5, -206.0),
	Vector2(236.0, -197.0),
	Vector2(235.0, -186.0),
	Vector2(233.0, -176.0),
	Vector2(231.8, -165.4),
]


func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var worst := 0.0
	var worst_at := Vector2.ZERO
	for i in LEG.size() - 1:
		var a: Vector2 = LEG[i]
		var b: Vector2 = LEG[i + 1]
		var steps := maxi(2, int(a.distance_to(b)))
		for s in steps + 1:
			var p := a.lerp(b, float(s) / float(steps))
			var deg: float = field.slope_degrees_at(p.x, p.y, 1.0)
			if deg > worst:
				worst = deg
				worst_at = p
			if s % 5 == 0:
				print("  (%.1f, %.1f) h %.2f slope %.1f" % [
					p.x, p.y, field.height_at(p.x, p.y), deg])
	print("worst %.1f deg at (%.1f, %.1f)" % [worst, worst_at.x, worst_at.y])
	quit(0)
