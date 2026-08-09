extends "res://tests/test_case.gd"

## The playground's shape.
##
## These are not aesthetic judgements, which no test can make. They assert the
## things M1 actually needs from the terrain: that it is not flat, that there is
## somewhere low and somewhere steep, and that the spawn is not on a slope. The
## owner's direction for M1 was explicit — "avoid a flat test field" — and that
## is a checkable property.

const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")

var _field: RefCounted
var _config: Dictionary


func before_each() -> void:
	_config = HEIGHTFIELD.load_config()
	_field = HEIGHTFIELD.new(_config)


func test_config_loads() -> void:
	assert_false(_config.is_empty(), "terrain_playground.json should parse")
	assert_true(_config.has("hills"), "config should describe the base hills")


func test_world_size_divides_by_region_size() -> void:
	# If it does not, the bake straddles Terrain3D region boundaries and leaves
	# unfilled flat gaps inside partially written regions. Caught the hard way.
	var world_size: int = int(_config.get("world_size", 0))
	var region_size: int = int(_config.get("region_size", 1))
	assert_true(world_size > 0 and region_size > 0, "both sizes must be set")
	assert_eq(world_size % region_size, 0,
		"world_size %d must be a multiple of region_size %d" % [world_size, region_size])


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
	for entry: Variant in _config.get("flats", []):
		if not entry is Dictionary:
			continue
		var flat: Dictionary = entry
		var centre: Array = flat.get("centre", [0.0, 0.0])
		var radius := float(flat.get("radius", 10.0))
		var middle: float = _field.height_at(float(centre[0]), float(centre[1]))
		for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
			var x := float(centre[0]) + cos(angle) * radius * 0.7
			var z := float(centre[1]) + sin(angle) * radius * 0.7
			var rim: float = _field.height_at(x, z)
			assert_true(absf(rim - middle) < 0.15,
				"flat at %s rises %.2fm inside its own radius" % [str(centre), absf(rim - middle)])


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
	var width := float(paths.get("width", 3.0))
	var shoulder := float(paths.get("shoulder", 1.5))
	var first: Array = (routes[0] as Dictionary).get("points", [])
	var far: float = _field.path_factor(float(first[0][0]) + width + shoulder + 5.0,
		float(first[0][1]) + width + shoulder + 5.0)
	assert_almost_eq(far, 0.0, 0.01, "well off the road should be untouched meadow")
