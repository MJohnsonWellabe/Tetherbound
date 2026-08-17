extends "res://tests/test_case.gd"

## The playground's shape.
##
## These are not aesthetic judgements, which no test can make. They assert the
## things M1 actually needs from the terrain: that it is not flat, that there is
## somewhere low and somewhere steep, and that the spawn is not on a slope. The
## owner's direction for M1 was explicit — "avoid a flat test field" — and that
## is a checkable property.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const ALIGNMENT := preload("res://scripts/world/terrain_region_alignment.gd")

var _field: RefCounted
var _config: Dictionary


func before_each() -> void:
	_config = HEIGHTFIELD.load_config()
	_field = HEIGHTFIELD.new(_config)


func test_config_loads() -> void:
	assert_false(_config.is_empty(), "terrain_playground.json should parse")
	assert_true(_config.has("hills"), "config should describe the base hills")


func test_world_bounds_land_on_the_region_lattice() -> void:
	# §1.3(a)/(b): a region's world origin is
	# region_location * region_size * vertex_spacing, so the lattice pitch is
	# that product in METRES, not region_size alone. Extent divisibility
	# (the old `world_size % region_size` check) is not sufficient -- see
	# test_off_centre_extent_that_divides_region_size_still_fails below for the
	# case it missed. Every bound of the actual configured world must land on
	# the lattice, or the outermost regions bake as partly-flat gaps.
	var region_size: int = int(_config.get("region_size", 0))
	var spacing: float = float(_config.get("vertex_spacing", 0.0))
	assert_true(region_size > 0 and spacing > 0.0, "region_size and vertex_spacing must both be set")

	var bounds := ALIGNMENT.world_bounds(_config)
	var error := ALIGNMENT.check_alignment(bounds, region_size, spacing)
	assert_eq(error, "", "configured world bounds must land on the %.1fm region lattice" % (region_size * spacing))


func test_off_centre_extent_that_divides_region_size_still_fails() -> void:
	# This is the exact defect the guard has to catch, restated as a test that
	# can fail. Revision 1 of MEADOWS_MACRO_LAYOUT.md specified x in
	# [-768, +768] -- a 1536m extent, and 1536 % 512 == 0, so an extent-only
	# check (including the "obvious" fix `world_size % (region_size *
	# vertex_spacing)`) passes it. But at region_size 256 / vertex_spacing 2.0
	# the lattice pitch is 512m and neither -768 nor +768 is a multiple of it,
	# so the outermost regions would be only half-written. A guard that cannot
	# fail on this input is not testing the property it claims to.
	var bounds := {"min_x": -768.0, "max_x": 768.0, "min_z": -768.0, "max_z": 768.0}
	var error := ALIGNMENT.check_alignment(bounds, 256, 2.0)
	assert_false(error.is_empty(),
		"a -768..+768 world must be REJECTED: 1536 is a multiple of 512, but neither bound is")


func test_a_genuinely_aligned_off_centre_extent_passes() -> void:
	# The companion positive case: -1024..+1024 has the same 2048m extent as
	# the previous test's 1536m rejection would need to avoid a false-negative
	# guard (one that rejects everything). Both bounds are multiples of the
	# 512m pitch, so this must pass.
	var bounds := {"min_x": -1024.0, "max_x": 1024.0, "min_z": -1024.0, "max_z": 1024.0}
	var error := ALIGNMENT.check_alignment(bounds, 256, 2.0)
	assert_eq(error, "", "-1024..+1024 at a 512m pitch should be accepted: %s" % error)


func test_is_deterministic() -> void:
	# The same config must always bake the same playground, or "re-run the
	# builder" stops being a safe instruction.
	var other: RefCounted = HEIGHTFIELD.new(_config)
	for point in [Vector2(0, 0), Vector2(37, -84), Vector2(-150, 120), Vector2(200, 200)]:
		assert_almost_eq(
			_field.height_at(point.x, point.y),
			other.height_at(point.x, point.y),
			0.0001,
			"height at %s should be reproducible" % point
		)


func test_the_playground_is_not_flat() -> void:
	var lowest := INF
	var highest := -INF
	for z in range(-240, 241, 20):
		for x in range(-240, 241, 20):
			var height: float = _field.height_at(float(x), float(z))
			lowest = minf(lowest, height)
			highest = maxf(highest, height)
	assert_true(highest - lowest > 30.0,
		"relief was %.1fm; a movement playground needs real elevation change" % (highest - lowest))


func test_there_is_somewhere_low() -> void:
	var valley: Dictionary = _config.get("valley", {})
	var centre: Array = valley.get("centre", [0.0, 0.0])
	var in_valley: float = _field.height_at(float(centre[0]), float(centre[1]))
	var outside: float = _field.height_at(float(centre[0]) + 220.0, float(centre[1]))
	assert_true(in_valley < outside,
		"the valley centre (%.1fm) should sit below ground well outside it (%.1fm)" % [in_valley, outside])


func test_there_is_somewhere_steep_enough_to_matter() -> void:
	# Fall damage and the 45-degree slope limit are untestable on gentle ground.
	var steep := 0
	var samples := 0
	for z in range(-240, 241, 10):
		for x in range(-240, 241, 10):
			samples += 1
			if _field.slope_degrees_at(float(x), float(z)) >= 30.0:
				steep += 1
	var fraction := float(steep) / float(samples)
	assert_true(fraction > 0.02,
		"only %.1f%% of the surface is steeper than 30 degrees" % (fraction * 100.0))
	assert_true(fraction < 0.45,
		"%.1f%% steeper than 30 degrees; this is a playground, not a climbing wall" % (fraction * 100.0))


func test_the_spawn_is_walkable() -> void:
	# Nobody's first impression of the movement should be a slope they slide off.
	var slope: float = _field.slope_degrees_at(0.0, 0.0)
	assert_true(slope < 12.0, "spawn slope is %.1f degrees; it should be near level" % slope)


func test_the_spawn_pad_blends_out() -> void:
	# The pad must not leave a visible disc edge. Sampling a ring just inside its
	# radius against one just outside should not show a cliff.
	var pad: Dictionary = _config.get("spawn_pad", {})
	var radius := float(pad.get("radius", 34.0))
	var inside: float = _field.height_at(radius * 0.92, 0.0)
	var outside: float = _field.height_at(radius * 1.08, 0.0)
	assert_true(absf(inside - outside) < 3.0,
		"%.2fm step across the spawn pad edge; it should blend" % absf(inside - outside))


func test_the_building_pads_are_genuinely_flat() -> void:
	# A barn on an 0.85-flattened slope still tilts; the flats promise FULL
	# flatten inside their radius, and the structures placed on them lean on it.
	#
	# Compared against the flat's own AUTHORED height, not a freshly-measured
	# centre point: EV6-remainder's mill-crossing pad ([-134.5,110]) has the
	# stream's carve running through its middle by design (playground_
	# heightfield.gd applies the carve AFTER flats, so a bridge/mill pad can
	# still promise level BANKS either side of a real channel). Measuring the
	# centre there reads the carved streambed, not the pad -- which made every
	# rim point "fail" against a middle that was never meant to represent the
	# pad's own height in the first place. The rim is what structures actually
	# stand on, and every flat authors its own `height` explicitly, so that is
	# the correct baseline for all of them, carved or not.
	for entry: Variant in _config.get("flats", []):
		if not entry is Dictionary:
			continue
		var flat: Dictionary = entry
		var centre: Array = flat.get("centre", [0.0, 0.0])
		var radius := float(flat.get("radius", 10.0))
		var target: float = float(flat.get("height", _field.height_at(float(centre[0]), float(centre[1]))))
		for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
			var x := float(centre[0]) + cos(angle) * radius * 0.7
			var z := float(centre[1]) + sin(angle) * radius * 0.7
			var rim: float = _field.height_at(x, z)
			assert_true(absf(rim - target) < 0.15,
				"flat at %s rises %.2fm inside its own radius" % [str(centre), absf(rim - target)])


func test_the_paths_reach_where_they_promise() -> void:
	# path_factor is the single reader every consumer trusts: 1 on the
	# centreline, gone past the shoulder. A broken segment walk would paint no
	# road and strip no vegetation, silently.
	var paths: Dictionary = _config.get("paths", {})
	var routes: Array = paths.get("routes", [])
	assert_true(routes.size() >= 3, "the meadow should have a path network, not a single trail")
	for entry: Variant in routes:
		var points: Array = (entry as Dictionary).get("points", [])
		assert_true(points.size() >= 2, "a route needs at least two points")
		for point: Variant in points:
			var on: float = _field.path_factor(float(point[0]), float(point[1]))
			assert_almost_eq(on, 1.0, 0.01, "a route's own waypoint should be fully on the path")
	# OW5C: this used to be a fixed offset from routes[0]'s own first point
	# (width + shoulder + 5m out). That stopped being "well off the road" once
	# `road_polylines()` started unioning the corridor's own spine and loops
	# (section 11) alongside `paths.routes`/spokes/crossings -- Band 1's spine
	# starts right at the road gate the village routes already end at, so a
	# fixed nearby offset landed within the new spine's own shoulder fade
	# (measured ~2m off it, well inside width+shoulder). A point genuinely far
	# from every road this config can produce is the honest fix, not shrinking
	# the offset back to fit around whatever roads happen to exist today.
	var far: float = _field.path_factor(500.0, -500.0)
	assert_almost_eq(far, 0.0, 0.01, "well off the road should be untouched meadow")


func test_nearest_point_on_paths_lands_on_the_road() -> void:
	# EV3: path-biased scatter clumps (path_stones) snap here. A point this
	# returns must itself read as fully on the path, or a "biased" clump would
	# still land off the road.
	var paths: Dictionary = _config.get("paths", {})
	var routes: Array = paths.get("routes", [])
	var first: Array = (routes[0] as Dictionary).get("points", [])
	var somewhere_off_the_road := Vector2(float(first[0][0]) + 40.0, float(first[0][1]) - 25.0)
	var on: Vector2 = _field.nearest_point_on_paths(somewhere_off_the_road.x, somewhere_off_the_road.y)
	assert_true(on != Vector2.INF, "a config with routes should always find a nearest point")
	var factor: float = _field.path_factor(on.x, on.y)
	assert_almost_eq(factor, 1.0, 0.01,
		"nearest_point_on_paths returned a point that isn't itself on the path (path_factor %.2f)" % factor)


func test_nearest_point_on_paths_is_actually_nearest() -> void:
	# A route waypoint lies on some segment, so the true nearest point on the
	# whole network can never be farther from a nearby probe than that
	# waypoint is — catches a version that returns the first route/segment
	# tried instead of genuinely comparing all of them.
	var paths: Dictionary = _config.get("paths", {})
	var routes: Array = paths.get("routes", [])
	var points: Array = (routes[0] as Dictionary).get("points", [])
	var waypoint := Vector2(float(points[0][0]), float(points[0][1]))
	var probe := waypoint + Vector2(1.5, -0.7)
	var on: Vector2 = _field.nearest_point_on_paths(probe.x, probe.y)
	assert_true(on.distance_to(probe) <= probe.distance_to(waypoint) + 0.01,
		"nearest_point_on_paths (%.2fm away) is farther from the probe than the known waypoint (%.2fm)" % [
			on.distance_to(probe), probe.distance_to(waypoint)
		])
