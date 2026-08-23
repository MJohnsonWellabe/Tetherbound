extends SceneTree

## Answers the question `playground_world.gd`'s own SIGIL_GATE comment deferred
## to this lane in writing: "this yaw needs fresh tuning against the real
## approach ONCE IT IS BUILT -- flagged rather than guessed at. Ground truth at
## (0,7400) was NOT re-probed by this pass."
##
## The approach is built now, and this lane's driven run
## (`tools/_probe_band5_approach.gd`) measured something the yaw note did not
## anticipate: the gate at (0,7400) is 55.9m from the nearest point of the
## authored spine. A gate standing 56m off the road in open meadow is not a
## gate. So this probes BOTH questions together -- where the road actually
## crosses z=7400, whether that ground can carry a gate, and what yaw puts the
## leaf across the road rather than across a bearing that stopped existing when
## OW5D moved everything.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

func _init() -> void:
	var field: RefCounted = HEIGHTFIELD.new()
	var spine: Array[Vector2] = [
		Vector2(0.0, 7000.0), Vector2(-80.0, 7120.0), Vector2(-20.0, 7250.0),
		Vector2(80.0, 7370.0), Vector2(20.0, 7480.0), Vector2(0.0, 7560.0)]

	print("=== how far is the gate at (0,7400) from the road? ===")
	var gate := Vector2(0.0, 7400.0)
	var best := INF
	var best_point := Vector2.ZERO
	var best_seg := -1
	for i in spine.size() - 1:
		var a: Vector2 = spine[i]
		var b: Vector2 = spine[i + 1]
		var ab: Vector2 = b - a
		var t: float = clampf((gate - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var p: Vector2 = a + ab * t
		var d: float = gate.distance_to(p)
		if d < best:
			best = d
			best_point = p
			best_seg = i
	print("  nearest point on the spine: (%.1f, %.1f) on segment %d -- %.1f m away" % [
		best_point.x, best_point.y, best_seg, best])

	print("=== candidate: put the gate where the road crosses z=7400 ===")
	var a2: Vector2 = spine[3]
	var b2: Vector2 = spine[4]
	var t2 := (7400.0 - a2.y) / (b2.y - a2.y)
	var on_road: Vector2 = a2.lerp(b2, t2)
	var bearing: Vector2 = (b2 - a2).normalized()
	print("  road crosses z=7400 at (%.1f, %.1f)" % [on_road.x, on_road.y])
	print("  the road's own bearing there: (%.3f, %.3f)" % [bearing.x, bearing.y])

	# `road_gate.gd::build(world, at, yaw_deg)` yaws the leaf about +Y. A leaf
	# whose span runs across the road is the one that stops anybody on it.
	var yaw := rad_to_deg(atan2(bearing.x, bearing.y))
	print("  yaw putting the leaf ACROSS the road: %.1f deg (current constant: -17.6)" % yaw)

	print("=== is that ground fit to carry a gate? ===")
	for name: String in ["candidate", "current"]:
		var at: Vector2 = on_road if name == "candidate" else gate
		var lo := INF
		var hi := -INF
		var steps := 0
		for i in 9:
			for j in 9:
				var x := at.x - 8.0 + float(i) * 2.0
				var z := at.y - 8.0 + float(j) * 2.0
				var g: float = field.height_at(x, z)
				if is_nan(g):
					continue
				lo = minf(lo, g)
				hi = maxf(hi, g)
				steps += 1
		print("  %-10s at (%7.1f, %7.1f): %d samples over a 16m pad, relief %.2f m" % [
			name, at.x, at.y, steps, hi - lo])

	print("=== separation from what already stands there ===")
	var fixtures := {
		"checkpoint Ness": Vector2(45.0, 7440.0),
		"the_waystop": Vector2(-25.0, 7460.0),
		"nearest approach pylon": Vector2(-14.86, 7398.9),
		"duskhush cluster 5002": Vector2(85.0, 7375.0),
		"trailpup cluster 5003": Vector2(20.0, 7485.0),
	}
	for name: String in fixtures:
		print("  %-24s %6.1f m from the candidate, %6.1f m from the current site" % [
			name, on_road.distance_to(fixtures[name]), gate.distance_to(fixtures[name])])
	quit(0)
