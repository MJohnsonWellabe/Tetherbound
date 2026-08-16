extends SceneTree

## SE21/SE22 — measuring the river the config now authors, not eyeballing it.
##
##   godot --headless --path . --script tools/_probe_river.gd
##
## Three questions, all of which have to be answered with numbers before the
## feature can be claimed (SD16 sited the quarry floor the same way):
##   1. is the bed low enough, everywhere, for ONE water plane to sit in it?
##   2. are the walls past the player's 45-degree floor_max_angle, everywhere
##      except the authored narrows the bridge spans?
##   3. is there a saddle anywhere between the authored points — a stretch
##      the interpolation left shallow enough to walk down and back up?

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const FLOOR_MAX_ANGLE := 45.0


func _init() -> void:
	var field := HEIGHTFIELD.new()
	var config: Dictionary = HEIGHTFIELD.load_config()
	var river: Dictionary = config.get("river", {})
	var course: Array = river.get("course", [])
	var level := float(river.get("water_level", 0.0))
	print("river: %d course points, water level %.1f" % [course.size(), level])

	# Walk the whole course at 3m, not just the authored vertices.
	var line: Array[Vector2] = []
	for entry: Variant in course:
		var at: Array = (entry as Dictionary).get("at", [])
		line.append(Vector2(float(at[0]), float(at[1])))
	var samples: Array[Vector2] = []
	for i in line.size() - 1:
		var steps := maxi(1, int(line[i].distance_to(line[i + 1]) / 3.0))
		for s in steps:
			samples.append(line[i].lerp(line[i + 1], float(s) / steps))
	samples.append(line[line.size() - 1])

	var worst_bed := -INF
	var worst_bed_at := Vector2.ZERO
	var wet := 0
	var dry := 0
	for p: Vector2 in samples:
		var bed: float = field.call("height_at", p.x, p.y)
		if p.length() < 240.0 and bed > worst_bed:
			worst_bed = bed
			worst_bed_at = p
		if bed < level:
			wet += 1
		else:
			dry += 1
	print("bed: highest inside the world is %.2f at %.0f,%.0f (water level %.1f)" % [
		worst_bed, worst_bed_at.x, worst_bed_at.y, level])
	print("bed: %d of %d 3m stations are under water, %d dry" % [wet, wet + dry, dry])

	# Wall angles: the steepest slope found crossing the channel at each
	# authored point, and the depth of the cut there.
	print("\npoint            bed      rim(near/far)   drop   steepest wall")
	var shallowest := INF
	for entry: Variant in course:
		var at: Array = (entry as Dictionary).get("at", [])
		var p := Vector2(float(at[0]), float(at[1]))
		if p.length() > 245.0:
			continue
		var across := _across_at(line, p)
		var reach: float = float((entry as Dictionary).get("half_width", 9.0)) + float((entry as Dictionary).get("rim", 5.0))
		var bed: float = field.call("height_at", p.x, p.y)
		var near_rim: float = field.call("height_at", p.x - across.x * (reach + 2.0), p.y - across.y * (reach + 2.0))
		var far_rim: float = field.call("height_at", p.x + across.x * (reach + 2.0), p.y + across.y * (reach + 2.0))
		var steepest := 0.0
		for side: float in [-1.0, 1.0]:
			var step := 0.5
			var d := 0.0
			while d < reach + 3.0:
				var q0 := p + across * (side * d)
				var q1 := p + across * (side * (d + step))
				var h0: float = field.call("height_at", q0.x, q0.y)
				var h1: float = field.call("height_at", q1.x, q1.y)
				steepest = maxf(steepest, rad_to_deg(atan2(absf(h1 - h0), step)))
				d += step
		shallowest = minf(shallowest, steepest)
		print("%6.1f,%6.1f  %7.2f  %6.2f/%6.2f  %6.2f   %5.1f deg" % [
			p.x, p.y, bed, near_rim, far_rim, minf(near_rim, far_rim) - bed, steepest])
	print("shallowest wall anywhere on an authored point: %.1f deg (floor_max_angle is %.0f)" % [
		shallowest, FLOOR_MAX_ANGLE])

	# Saddles between the authored points: the same crossing profile, sampled
	# every 6m along the whole course.
	var worst_wall := INF
	var worst_at := Vector2.ZERO
	for i in range(0, samples.size(), 2):
		var p: Vector2 = samples[i]
		if p.length() > 240.0:
			continue
		var across := _across_at(line, p)
		var steepest := 0.0
		for side: float in [-1.0, 1.0]:
			var d := 0.0
			while d < 20.0:
				var h0: float = field.call("height_at", p.x + across.x * side * d, p.y + across.y * side * d)
				var h1: float = field.call("height_at", p.x + across.x * side * (d + 0.5), p.y + across.y * side * (d + 0.5))
				steepest = maxf(steepest, rad_to_deg(atan2(absf(h1 - h0), 0.5)))
				d += 0.5
		if steepest < worst_wall:
			worst_wall = steepest
			worst_at = p
	print("shallowest wall ANYWHERE along the course: %.1f deg at %.0f,%.0f" % [
		worst_wall, worst_at.x, worst_at.y])

	# SE22's abutments: the two landings the span sits on must agree.
	print("\nOld Mill Crossing:")
	for entry: Array in [["far-bank abutment", 175.2, 46.4], ["village-side abutment", 149.6, 37.8],
			["mill site", 148.8, 41.8], ["narrows centre", 162.4, 42.1]]:
		print("  %-22s ground %.2f" % [entry[0], float(field.call("height_at", float(entry[1]), float(entry[2])))])
	quit(0)


## Unit vector across the course at `p` — the direction a player would walk to
## cross the river there.
func _across_at(line: Array[Vector2], p: Vector2) -> Vector2:
	var best := INF
	var along := Vector2.RIGHT
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var ab := b - a
		var t: float = clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		var d := p.distance_to(a.lerp(b, t))
		if d < best:
			best = d
			along = ab.normalized()
	return Vector2(-along.y, along.x)
