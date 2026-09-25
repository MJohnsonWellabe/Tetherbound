extends "res://tests/test_case.gd"

## X05 (main-red host stall): the grid index `band_pickups.gd` now asks must
## answer exactly what `vegetation.gd::has_solid_scatter_near()`'s linear scan
## answers, including at the boundary distance.

const INDEX := preload("res://scripts/world/scatter_proximity_index.gd")


static func _brute(spots: Array, centre: Vector3, extra: float) -> bool:
	for s: Array in spots:
		var reach: float = float(s[2]) + extra
		if Vector2(float(s[0]) - centre.x, float(s[1]) - centre.z).length_squared() <= reach * reach:
			return true
	return false


func test_index_matches_the_linear_scan_everywhere() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7071
	var spots: Array = []
	var index := INDEX.new(8.0)
	for i in 600:
		var s := [rng.randf_range(-300.0, 300.0), rng.randf_range(-300.0, 300.0),
			[0.4, 1.1, 2.5, 6.0][i % 4]]
		spots.append(s)
		index.add(float(s[0]), float(s[1]), float(s[2]))
	assert_eq(index.size(), 600)
	var mismatches := 0
	for i in 4000:
		var centre := Vector3(rng.randf_range(-320.0, 320.0), rng.randf_range(-5.0, 40.0),
			rng.randf_range(-320.0, 320.0))
		var extra: float = [0.0, 0.75, 1.5, 9.0][i % 4]
		if index.has_near(centre, extra) != _brute(spots, centre, extra):
			mismatches += 1
	assert_eq(mismatches, 0, "the grid must answer every query exactly as the linear scan does")


func test_boundary_distance_counts_as_near_like_the_scan() -> void:
	var index := INDEX.new(8.0)
	index.add(6.0, 0.0, 1.0)
	# Exactly radius + extra away (3.0) along x, in the next cell over (8-16).
	assert_true(index.has_near(Vector3(9.0, 0.0, 0.0), 2.0))
	assert_false(index.has_near(Vector3(9.01, 0.0, 0.0), 2.0))
	# A negative extra reaches |radius + extra|, exactly as the scan's square does.
	assert_eq(index.has_near(Vector3(-4.0, 0.0, 0.0), -12.0), _brute([[6.0, 0.0, 1.0]], Vector3(-4.0, 0.0, 0.0), -12.0))
	# A large footprint reaches across more than one cell.
	index.add(-40.0, -40.0, 20.0)
	assert_true(index.has_near(Vector3(-40.0, 0.0, -18.5), 1.5))
	assert_false(INDEX.new().has_near(Vector3.ZERO, 5.0), "an empty index holds no scatter")
