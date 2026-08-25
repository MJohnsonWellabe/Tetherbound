extends SceneTree
## Grid-search a GATE_KEY_AT site clear of everything solid near the village
## road gate, on the correct side of its seal. Written for the SIGIL-SEAL
## fallout (2026-08-25): the old (24,-10) key sat 6.8m along the gate's own
## fence line, inside `_build_wings()`'s new `seal_half_width` 12.0m reach, so
## the wing panel it now builds there blocked every approach to the key's own
## prompt radius. Kept for the next time a gate or a fence near here moves.
##
## THE SIDE CONVENTION, worth recording because it cost two wrong runs to pin
## down: `smoke_opening.gd`'s crossing check projects onto `through =
## (sin(yaw), cos(yaw))` (perpendicular to the gate's own fence line) and
## compares sign before/after. That sign is NOT "toward the village" in any
## intuitive sense -- it is which half of an INFINITE line through the gate a
## point falls on, and two points that both read as "near the village" can
## land on opposite halves (the well projects negative, the gate's own
## approach waypoint (26,-10) projects positive) because the line runs at the
## gate's yaw, not along any village-relative axis. What matters is only
## matching the sign of the player's actual pre-gate position, so this probe
## takes that from the same waypoint `smoke_opening.gd` uses.

func _init() -> void:
	var world: Node = load("res://scenes/world/meadows_playground.tscn").instantiate()
	root.add_child(world)
	for i in 240:
		await physics_frame

	var gate: Node3D = world.get_node_or_null(^"RoadGate") as Node3D
	if gate == null:
		print("NO RoadGate"); quit(1); return

	# Wing collision box centres, queried live from the built node rather than
	# re-derived by hand -- `_build_wings()` is the one source of truth for
	# where they actually land.
	var wing_centers: Array[Vector2] = []
	for child in gate.get_children():
		if child is StaticBody3D and String(child.name).begins_with("GateWingCollision"):
			var c: Vector3 = gate.to_global(child.position)
			wing_centers.append(Vector2(c.x, c.z))

	var landmarks := {
		"gate_leaf": Vector2(27.5, -16.0),
		"cottage_b": Vector2(21.0, -14.0),
		"cottage_a": Vector2(18.0, -2.0),
		"harvest_20_-16": Vector2(20.0, -16.0),
		"square_oak_a": Vector2(25.5, -9.5),
		"fence_14_-20": Vector2(14.0, -20.0),
		"fence_19.5_-25.5": Vector2(19.5, -25.5),
	}

	var gate_at := Vector2(27.5, -16.0)
	var yaw := gate.rotation.y
	var across := Vector2(cos(yaw), -sin(yaw))   # the fence line itself
	var through := Vector2(sin(yaw), cos(yaw))   # perpendicular -- the crossing direction

	# The player's real pre-gate waypoint (`smoke_opening.gd`'s own last stop
	# before it starts the blocked-approach check) -- whichever sign THIS
	# projects to is the side a candidate must match to be reachable without
	# crossing the seal.
	var approach_side: float = signf(through.dot(Vector2(26.0, -10.0) - gate_at))

	var best_score := -INF
	var best: Vector2 = Vector2.ZERO
	for xi in range(-6, 7):
		for zi in range(2, 9):
			var c: Vector2 = gate_at + float(xi) * across + float(zi) * through * approach_side
			var ground: float = float(world.call("ground_height_at", c.x, c.y))
			if is_nan(ground) or ground < 0.5:
				continue
			var min_wing_dist := INF
			for wc: Vector2 in wing_centers:
				min_wing_dist = min(min_wing_dist, wc.distance_to(c))
			var d_gate: float = c.distance_to(landmarks["gate_leaf"])
			var margins: Array[float] = [
				min_wing_dist - 6.0,
				d_gate - 6.4,   # matches this gate's own 4.0m + the key's 2.4m prompt radii
				c.distance_to(landmarks["harvest_20_-16"]) - 4.8,
				c.distance_to(landmarks["cottage_b"]) - 3.0,
				c.distance_to(landmarks["fence_14_-20"]) - 4.0,
				c.distance_to(landmarks["fence_19.5_-25.5"]) - 4.0,
				c.distance_to(landmarks["square_oak_a"]) - 2.5,
			]
			var worst: float = margins[0]
			for m: float in margins:
				worst = min(worst, m)
			if worst < 0.0:
				continue  # fails at least one clearance
			# Among every fully-clear site, prefer the one closest to the gate
			# -- SA7 wants "a short detour," not a hike back to the square.
			var score: float = -d_gate
			if score > best_score:
				best_score = score
				best = c

	if best_score == -INF:
		print("NO feasible site found in the searched grid")
		quit(1)
		return

	print("BEST candidate: (%.2f, %.2f), %.2fm from the gate" % [best.x, best.y, -best_score])
	var min_wing_dist := INF
	for wc: Vector2 in wing_centers:
		min_wing_dist = min(min_wing_dist, wc.distance_to(best))
	print("  ground=%.2f min_wing_center_dist=%.2f" % [
		float(world.call("ground_height_at", best.x, best.y)), min_wing_dist])
	for key in landmarks:
		print("  %s=%.2f" % [key, (landmarks[key] as Vector2).distance_to(best)])

	quit(0)
