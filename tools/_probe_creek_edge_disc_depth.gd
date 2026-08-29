extends SceneTree
## T1-CAST (§15 continuation). Follow-up to
## tools/_probe_creek_edge_scatter_depth.gd's finding: the T1-CREATURE centre
## fix only checked the CENTRE point's depth, but encounter_director.gd's own
## scatter draw (`distance = radius * sqrt(rng.randf())`) is a uniform-AREA
## sample over the disc -- which, because a disc's area grows with radius,
## puts MOST of its probability mass near the OUTER edge, not the centre.
## Fixing only the centre point therefore verifies the least-sampled part of
## the disc. This script grid-samples the WHOLE disc (not just the seeded
## individuals) to find the worst-case depth at the cluster's current radius,
## then searches for the largest radius that keeps the worst point on the
## disc clearing the water by a real margin -- the fix that actually bounds
## what any future reroll of `count` could ever place.
##
##   godot --headless --path . --script tools/_probe_creek_edge_disc_depth.gd

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const SPAWNS_PATH := "res://data/config/bands/band1_lower_meadows/spawns.json"
const WATER_PATH := "res://data/config/terrain_playground.json"

const BODY_HEIGHT := {
	"paddlenewt": 1.15,
	"mosshell": 1.40,
	"brooktail": 1.05,
}

## Fraction of body that must stay above the surface for a point to count as
## "clears" -- 0.5 (half the body visible) rather than literal zero, matching
## the standard T1-CREATURE's own report used ("most of the body clears it").
const CLEAR_MARGIN := 0.5

const TARGET_ORDERS := [6, 7, 8]


func _init() -> void:
	var spawns_file := FileAccess.open(SPAWNS_PATH, FileAccess.READ)
	var spawns_data: Dictionary = JSON.parse_string(spawns_file.get_as_text())
	var water_file := FileAccess.open(WATER_PATH, FileAccess.READ)
	var water_data: Dictionary = JSON.parse_string(water_file.get_as_text())
	var water_level: float = float((water_data.get("water", {}) as Dictionary).get("level", -17.0))
	var field := HEIGHTFIELD.new(HEIGHTFIELD.load_config())

	for spawn: Dictionary in spawns_data.get("spawns", []):
		var order: int = int(spawn.get("order", -1))
		if not TARGET_ORDERS.has(order):
			continue
		var species: String = spawn.get("species", "")
		var body_h: float = BODY_HEIGHT.get(species, 1.0)
		var centre_arr: Array = spawn.get("centre", [])
		var centre := Vector2(centre_arr[0], centre_arr[2])
		var radius: float = float(spawn.get("radius", 0.0))

		print("\n%s (order %d), centre (%.2f,%.2f), authored radius %.1f, body %.2f" % [
			species, order, centre.x, centre.y, radius, body_h])

		# Worst point at the AUTHORED radius (fine ring+radial grid, not just
		# the two/one seeded individuals -- this is "what could ANY reroll of
		# count place here", not "what did this exact seed place").
		var worst_depth := -INF
		var worst_spot := Vector2.ZERO
		var r := 0.5
		while r <= radius + 0.01:
			var steps: int = max(8, int(r * 3.0))
			for i in steps:
				var ang: float = TAU * float(i) / float(steps)
				var spot: Vector2 = centre + Vector2(sin(ang), cos(ang)) * r
				var h: float = field.height_at(spot.x, spot.y)
				var depth: float = water_level - h
				if depth > worst_depth:
					worst_depth = depth
					worst_spot = spot
			r += 0.5
		var worst_frac: float = clampf(1.0 - worst_depth / body_h, 0.0, 1.0) if worst_depth > 0.0 else 1.0
		print("  worst point on the FULL disc: (%.1f,%.1f), depth %.2f -> %.0f%% of body above water" % [
			worst_spot.x, worst_spot.y, worst_depth, worst_frac * 100.0])

		# Per-RING (not cumulative) worst depth, so a manual pick of radius
		# can see exactly where the drop-off actually starts, rather than
		# only the single first radius the cumulative pass below fails at.
		print("  ring profile (worst single-ring depth, not cumulative):")
		var ring_r := 0.5
		while ring_r <= radius + 0.01:
			var steps: int = max(8, int(ring_r * 3.0))
			var ring_worst := -INF
			for i in steps:
				var ang: float = TAU * float(i) / float(steps)
				var spot: Vector2 = centre + Vector2(sin(ang), cos(ang)) * ring_r
				var h: float = field.height_at(spot.x, spot.y)
				var depth: float = water_level - h
				ring_worst = maxf(ring_worst, depth)
			var ring_frac: float = clampf(1.0 - ring_worst / body_h, 0.0, 1.0) if ring_worst > 0.0 else 1.0
			print("    r=%.1f: worst depth %.2f -> %.0f%% clear" % [ring_r, ring_worst, ring_frac * 100.0])
			ring_r += 0.5

		# Search for the largest radius (0.5m steps) whose own worst-case
		# point still clears by CLEAR_MARGIN.
		var safe_radius := 0.0
		var test_r := 0.5
		while test_r <= radius + 0.01:
			var steps: int = max(8, int(test_r * 3.0))
			var ok := true
			for i in steps:
				var ang: float = TAU * float(i) / float(steps)
				var spot: Vector2 = centre + Vector2(sin(ang), cos(ang)) * test_r
				var h: float = field.height_at(spot.x, spot.y)
				var depth: float = water_level - h
				var frac: float = clampf(1.0 - depth / body_h, 0.0, 1.0) if depth > 0.0 else 1.0
				if frac < CLEAR_MARGIN:
					ok = false
					break
			if not ok:
				break
			safe_radius = test_r
			test_r += 0.5
		print("  largest radius keeping the WHOLE disc >= %.0f%% clear: %.1fm (was %.1fm)" % [
			CLEAR_MARGIN * 100.0, safe_radius, radius])
	quit(0)
