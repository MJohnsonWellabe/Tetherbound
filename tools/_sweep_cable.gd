extends SceneTree
## Round-2 cable tuning. The critic: "the cable rises from the distant pylon in
## a smooth mathematical swoop -- it reads as a bezier debug line, not a hanging
## cable; cables sag, they do not soar." Sag and ground clearance pull against
## each other, so both are swept together rather than either being guessed.
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const ATTACH := 0.66
const SAG := 0.05
const SINK := 0.22
const FROM := Vector2(-40.0, 7010.0)
const TO := Vector2(-8.0, 7505.0)

func _init() -> void:
	var f: RefCounted = HEIGHTFIELD.new()
	print("%6s %5s %7s %8s %9s %8s" % ["height", "n", "sagx", "spacing", "sag_m", "worst_m"])
	for h: float in [10.0, 11.0, 12.0]:
		for n: int in [15, 17]:
			for sx: float in [1.0, 1.6, 2.2, 2.8]:
				var pts: Array[Vector2] = []
				for i in n:
					pts.append(FROM.lerp(TO, float(i) / float(n - 1)))
				var worst := INF
				var sag_m := 0.0
				for i in n - 1:
					var ga: float = f.height_at(pts[i].x, pts[i].y)
					var gb: float = f.height_at(pts[i + 1].x, pts[i + 1].y)
					var ay := ga - SINK + h * ATTACH
					var by := gb - SINK + h * ATTACH
					var span: float = pts[i].distance_to(pts[i + 1])
					sag_m = span * SAG * sx
					for s in range(1, 24):
						var t := float(s) / 24.0
						var p: Vector2 = pts[i].lerp(pts[i + 1], t)
						var c: float = lerpf(ay, by, t) - sag_m * 4.0 * t * (1.0 - t) \
							- float(f.height_at(p.x, p.y))
						worst = minf(worst, c)
				var mark := "  <-- clears 2.2m" if worst >= 2.2 else ""
				print("%6.1f %5d %7.1f %8.1f %9.2f %8.2f%s" % [
					h, n, sx, FROM.distance_to(TO) / float(n - 1), sag_m, worst, mark])
	quit(0)
