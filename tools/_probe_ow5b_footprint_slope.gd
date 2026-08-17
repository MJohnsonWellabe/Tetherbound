extends SceneTree

## OW5B. Sweep the WHOLE new corridor footprint for slope before baking
## anything, per the constraint OF15 left behind: the confirmed wedge at
## (60, -106) turned out to be terrain slope, not props, and a second lane
## independently found a creature's chase wedging on terrain near its own
## spawn tonight (`CI-AGGRESSION`, near (53, -122) -- ~13m from the OF15 spot).
## `height_at` is analytic and unbounded, so the whole footprint can be probed
## without a bake. This is that probe.
##
##   godot --headless --path . --script tools/_probe_ow5b_footprint_slope.gd
##
## What it does: walks a grid over the corridor bounds (x [-1024,1024],
## z [-512,7680]) at COARSE_STEP metre spacing, and at each point measures
## slope on the GRID-RECONSTRUCTED surface Terrain3D will actually build at
## vertex_spacing 2.0 (not the raw analytic field -- `_probe_corridor_
## footprint.gd`'s own finding: the analytic field reports the angle the
## config asks for, the grid is what a body actually stands on) using a
## finite difference at the bake's own 2.0m spacing.
##
## Every authored steep feature (rises, valley, spoke carves, river/crossing
## carves) lives entirely inside the OLD 512m square -- checked directly
## against terrain_playground.json below (KNOWN_FEATURE_BOX). So the question
## this probe answers is really about the NEW territory: does the raw
## hills+detail FBM noise, extended over 16.78 km^2 it was never walked on
## before, ever exceed the player's floor_max_angle (45deg) on its own,
## unintentionally? Points inside KNOWN_FEATURE_BOX are expected to exceed it
## (that is what a carve/rise IS) and are reported separately, not as hazards.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

const MIN_X := -1024.0
const MAX_X := 1024.0
const MIN_Z := -512.0
const MAX_Z := 7680.0

const COARSE_STEP := 8.0
const GRID_SPACING := 2.0  # the corridor bake's own vertex_spacing

const PLAYER_LIMIT := 45.0
const RIDDEN_LIMIT := 60.0

# Superset of every rise peak (radius 24-78, centres within x[-223,218]
# z[-223,219]), the valley (centre -120,130 radius 150), and every spoke/
# crossing/river carve -- all authored against the original 512m square.
# Padded generously past the loosest of those (valley: x[-270,30] z[-20,280]).
const KNOWN_FEATURE_BOX := {"min_x": -320.0, "max_x": 320.0, "min_z": -320.0, "max_z": 320.0}


func _in_known_box(x: float, z: float) -> bool:
	return (x >= KNOWN_FEATURE_BOX["min_x"] and x <= KNOWN_FEATURE_BOX["max_x"]
		and z >= KNOWN_FEATURE_BOX["min_z"] and z <= KNOWN_FEATURE_BOX["max_z"])


func _grid_height(field: RefCounted, x: float, z: float) -> float:
	var gx := floorf(x / GRID_SPACING) * GRID_SPACING
	var gz := floorf(z / GRID_SPACING) * GRID_SPACING
	var tx := (x - gx) / GRID_SPACING
	var tz := (z - gz) / GRID_SPACING
	var h00: float = field.call("height_at", gx, gz)
	var h10: float = field.call("height_at", gx + GRID_SPACING, gz)
	var h01: float = field.call("height_at", gx, gz + GRID_SPACING)
	var h11: float = field.call("height_at", gx + GRID_SPACING, gz + GRID_SPACING)
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


func _slope_deg(field: RefCounted, x: float, z: float) -> float:
	var step := GRID_SPACING
	var dx := _grid_height(field, x + step, z) - _grid_height(field, x - step, z)
	var dz := _grid_height(field, x, z + step) - _grid_height(field, x, z - step)
	var normal := Vector3(-dx, 2.0 * step, -dz).normalized()
	return rad_to_deg(acos(clampf(normal.y, -1.0, 1.0)))


func _init() -> void:
	var config: Dictionary = HEIGHTFIELD.load_config()
	if config.is_empty():
		push_error("no terrain config")
		quit(1)
		return
	var field: RefCounted = HEIGHTFIELD.new(config)

	var t0 := Time.get_ticks_usec()
	var checked := 0
	var known_over_45 := 0
	var known_over_60 := 0
	var known_max := 0.0
	var unknown_over_45 := 0
	var unknown_over_60 := 0
	var unknown_max := 0.0
	var worst_unknown: Array = []  # up to 20 worst offenders, [deg, x, z]

	var z := MIN_Z
	var row := 0
	var total_rows := int((MAX_Z - MIN_Z) / COARSE_STEP) + 1
	while z <= MAX_Z:
		var x := MIN_X
		while x <= MAX_X:
			var deg := _slope_deg(field, x, z)
			checked += 1
			if _in_known_box(x, z):
				known_max = maxf(known_max, deg)
				if deg >= PLAYER_LIMIT:
					known_over_45 += 1
				if deg >= RIDDEN_LIMIT:
					known_over_60 += 1
			else:
				unknown_max = maxf(unknown_max, deg)
				if deg >= PLAYER_LIMIT:
					unknown_over_45 += 1
					worst_unknown.append([deg, x, z])
				if deg >= RIDDEN_LIMIT:
					unknown_over_60 += 1
			x += COARSE_STEP
		row += 1
		if row % 32 == 0:
			print("  progress: row %d/%d (z=%.0f), %.1fs elapsed" % [row, total_rows, z, (Time.get_ticks_usec() - t0) / 1e6])
		z += COARSE_STEP

	worst_unknown.sort_custom(func(a, b): return a[0] > b[0])

	var us := Time.get_ticks_usec() - t0
	print("=== OW5B pre-bake footprint slope sweep ===")
	print("bounds x[%.0f,%.0f] z[%.0f,%.0f] at %.1fm grid, slope measured at %.1fm spacing (the bake's own)" % [
		MIN_X, MAX_X, MIN_Z, MAX_Z, COARSE_STEP, GRID_SPACING])
	print("%d points checked in %.1fs\n" % [checked, us / 1e6])

	print("KNOWN_FEATURE_BOX x[%.0f,%.0f] z[%.0f,%.0f] (rises/valley/carves live here BY DESIGN):" % [
		KNOWN_FEATURE_BOX["min_x"], KNOWN_FEATURE_BOX["max_x"], KNOWN_FEATURE_BOX["min_z"], KNOWN_FEATURE_BOX["max_z"]])
	print("  max slope %.1f deg, %d points >=45deg, %d points >=60deg (expected -- carves/rises are meant to exceed these)\n" % [
		known_max, known_over_45, known_over_60])

	print("EVERYWHERE ELSE -- the new territory, hills+detail noise only, no authored carve or rise:")
	print("  max slope %.1f deg, %d points >=45deg (player floor_max_angle), %d points >=60deg (ridden limit)" % [
		unknown_max, unknown_over_45, unknown_over_60])
	if unknown_over_45 == 0:
		print("  CLEAN: no unintentional slope over the player's 45deg limit anywhere in the new territory.")
	else:
		print("  WORST OFFENDERS (up to 20, in the new/unauthored territory):")
		for i in mini(20, worst_unknown.size()):
			var e: Array = worst_unknown[i]
			print("    %.1f deg at (%.1f, %.1f)" % [e[0], e[1], e[2]])
	quit(0)
