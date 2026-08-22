extends SceneTree

## Sites BAND5-APPROACH's conduit run by MEASUREMENT rather than by guess, the
## same way stronghold.json's own `_comment_where` sited the chambers.
##
## Two questions only this can answer:
##   1. Does a straight line from the band mouth to the works stay on ground a
##      pylon can stand on -- `_build_pylons` drops a pylon wherever
##      `ground_height_at` returns a number, so a run over a 12m step reads as
##      a line of pylons at random heights rather than a line.
##   2. Does the conduit CABLE clear the ground between consecutive pylons?
##      `severed_spokes.gd::_conduit_span` sags `distance * 0.05` below the
##      attachment (`height * 0.66`) measured from EACH pylon's OWN base, so a
##      rise between two pylons pushes the ground up into a cable that was
##      computed from the two ends. A cable through a hillock is the kind of
##      defect that only shows in a render, and this finds it in a second.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const FROM := Vector2(-40.0, 7010.0)
const TO := Vector2(-8.0, 7505.0)
const COUNT := 13
const HEIGHT := 9.0
const ATTACH := 0.66   # severed_spokes.gd::CONDUIT_ATTACH
const SAG := 0.05      # severed_spokes.gd::CONDUIT_SAG
const SINK := 0.22     # `base_y := ground - 0.22`

func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var points: Array[Vector2] = []
	for i in COUNT:
		var t := float(i) / float(COUNT - 1)
		points.append(FROM.lerp(TO, t))

	print("=== pylon stations ===")
	var grounds: Array[float] = []
	var lowest := INF
	var highest := -INF
	for i in COUNT:
		var p: Vector2 = points[i]
		var g: float = field.height_at(p.x, p.y)
		grounds.append(g)
		lowest = minf(lowest, g)
		highest = maxf(highest, g)
		print("  %2d  (%7.1f, %7.1f)  ground %6.2f" % [i, p.x, p.y, g])
	print("  relief across the run: %.2f m (%.2f -> %.2f)" % [highest - lowest, lowest, highest])

	print("=== cable clearance between stations ===")
	var worst := INF
	var worst_at := -1
	for i in COUNT - 1:
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var ay: float = grounds[i] - SINK + HEIGHT * ATTACH
		var by: float = grounds[i + 1] - SINK + HEIGHT * ATTACH
		var span := a.distance_to(b)
		var sag := span * SAG
		var span_low := INF
		for s in range(1, 20):
			var t := float(s) / 20.0
			var here: Vector2 = a.lerp(b, t)
			var cable := lerpf(ay, by, t) - sag * 4.0 * t * (1.0 - t)
			var clear: float = cable - float(field.height_at(here.x, here.y))
			span_low = minf(span_low, clear)
		print("  %2d->%2d  span %5.1f m  sag %4.2f  min clearance %5.2f m" % [i, i + 1, span, sag, span_low])
		if span_low < worst:
			worst = span_low
			worst_at = i
	print("  WORST clearance %.2f m, on span %d->%d" % [worst, worst_at, worst_at + 1])

	print("=== separation from authored content ===")
	var fixtures := {
		"sigil_gate": Vector2(0.0, 7400.0),
		"the_waystop": Vector2(-25.0, 7460.0),
		"outer_watch_corr": Vector2(-68.0, 7140.0),
		"outer_watch_cache": Vector2(-71.0, 7144.0),
		"checkpoint_ness": Vector2(45.0, 7440.0),
		"harvest_5000": Vector2(-58.0, 7112.0),
		"works_centre": Vector2(0.0, 7560.0),
	}
	for name: String in fixtures:
		var at: Vector2 = fixtures[name]
		var best := INF
		var best_i := -1
		for i in COUNT:
			var d: float = at.distance_to(points[i])
			if d < best:
				best = d
				best_i = i
		print("  %-20s nearest pylon %2d at %6.1f m" % [name, best_i, best])
	quit(0)
