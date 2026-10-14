extends "res://tests/test_case.gd"

const COVER := preload("res://scripts/world/cloudreach_ground_cover.gd")
const INDEX := preload("res://scripts/world/cloudreach_cover_exclusion_index.gd")


func test_index_preserves_linear_results_at_rotated_sloping_and_stacked_boundaries() -> void:
	var exclusions: Array[Dictionary] = [
		{"kind": "segment", "a": Vector3(-90, -8, -65), "b": Vector3(75, 12, 70), "half_width": 2.75},
		{"kind": "segment", "a": Vector3(-32, 0, 32), "b": Vector3(-32, 0, 32), "half_width": 3.0},
		{"kind": "rect", "centre": Vector3(32, 0, -32), "half": Vector2(7, 2), "rotation": 0.73},
		{"kind": "ellipse", "centre": Vector3(-32, 0, -32), "half": Vector2(10, 3), "rotation": -0.43},
		{"kind": "rect", "centre": Vector3(32, 40, -32), "half": Vector2(15, 6), "rotation": 1.13},
	]
	var cover := COVER.new()
	cover._active_exclusions = exclusions
	var probes: Array[Vector3] = []
	# Independent random probes plus exact rotated edges and vertical gates.
	var rng := RandomNumberGenerator.new()
	rng.seed = 41023
	for index in 1800:
		probes.append(Vector3(rng.randf_range(-100, 100), rng.randf_range(-12, 45), rng.randf_range(-100, 100)))
	for exclusion: Dictionary in exclusions:
		if str(exclusion.kind) == "segment":
			for t: float in [0.0, 0.25, 0.5, 1.0]:
				var at: Vector3 = (exclusion.a as Vector3).lerp(exclusion.b, t)
				for delta: float in [-3.0, -2.999, 0.0, 2.999, 3.0]:
					probes.append(at + Vector3.UP * delta)
		else:
			var half: Vector2 = exclusion.half
			for local: Vector2 in [Vector2(half.x, 0), Vector2(0, half.y), half, -half]:
				var offset := local.rotated(float(exclusion.rotation))
				for delta: float in [-3.0, -2.999, 0.0, 2.999, 3.0]:
					probes.append((exclusion.centre as Vector3) + Vector3(offset.x, delta, offset.y))
	for x: float in [-64.001, -64.0, -32.001, -32.0, -0.001, 0.0, 31.999, 32.0, 64.0]:
		for z: float in [-64.0, -32.0, 0.0, 32.0, 64.0]:
			probes.append(Vector3(x, 0, z))
	for at: Vector3 in probes:
		assert_eq(cover._excluded(at, true), cover._excluded_from(at, exclusions), "same exclusion at " + str(at))
	cover.free()


func test_index_rebuild_and_oversized_fallback_keep_all_matches() -> void:
	var cover := COVER.new()
	var huge := {"kind": "rect", "centre": Vector3.ZERO, "half": Vector2(100000, 100000), "rotation": 0.0}
	cover._active_exclusions = [huge]
	assert_eq(cover._active_index.unbounded.size(), 1)
	assert_true(cover._excluded(Vector3(99000, 0, 99000), true))
	assert_false(cover._excluded(Vector3(99000, 40, 99000), true))
	cover._active_exclusions = []
	assert_false(cover._excluded(Vector3.ZERO, true), "rebuild clears old fallback shapes")
	cover._active_exclusions = [{"kind": "rect", "centre": Vector3.ZERO, "half": Vector2.ONE, "rotation": 0.0}]
	assert_true(cover._excluded(Vector3.ZERO, true))
	cover._active_exclusions = [{"kind": "rect", "centre": Vector3(64, 0, 64), "half": Vector2.ONE, "rotation": 0.0}]
	assert_false(cover._excluded(Vector3.ZERO, true), "same-sized replacement rebuilds cells")
	assert_true(cover._excluded(Vector3(64, 0, 64), true))
	cover.free()


func test_index_budget_falls_back_without_dropping_later_shapes() -> void:
	var exclusions: Array[Dictionary] = []
	for i in 10:
		exclusions.append({"kind": "rect", "centre": Vector3(i * 3000, 0, 0),
			"half": Vector2(960, 960), "rotation": 0.0})
	var cover := COVER.new()
	cover._active_exclusions = exclusions
	assert_true(cover._active_index.unbounded.size() > 0, "allocation budget takes the linear fallback")
	for exclusion: Dictionary in exclusions:
		assert_true(cover._excluded(exclusion.centre, true), "later shapes survive the index budget")
	cover.free()


func test_sparse_query_examines_local_shapes_instead_of_the_whole_patch() -> void:
	var exclusions: Array[Dictionary] = []
	for x in 20:
		for z in 20:
			exclusions.append({"kind": "rect", "centre": Vector3(x * 64 + 16, 0, z * 64 + 16),
				"half": Vector2(3, 3), "rotation": 0.2})
	var index := INDEX.new()
	index.build(exclusions)
	assert_eq(index.candidates(Vector3(16, 0, 16)).size(), 1, "one candidate instead of 400")
	assert_eq(index.unbounded.size(), 0)


func test_packed_overflow_preserves_linear_boundaries_and_rebuilds() -> void:
	var exclusions: Array[Dictionary] = [
		{"kind": "segment", "a": Vector3(-100000, -4, -100000),
			"b": Vector3(100000, 4, 100000), "half_width": 2.75},
		{"kind": "rect", "centre": Vector3(0, 20, 0),
			"half": Vector2(100000, 2), "rotation": 0.73},
		{"kind": "ellipse", "centre": Vector3(0, 40, 0),
			"half": Vector2(100000, 3), "rotation": -0.43},
		{"kind": "rect", "centre": Vector3(64, 60, 64),
			"half": Vector2.ONE, "rotation": 0.0},
	]
	var cover := COVER.new()
	cover._active_exclusions = exclusions
	assert_eq(cover._active_index.unbounded.size(), 3)
	var probes: Array[Vector3] = [Vector3(64, 60, 64), Vector3(66, 60, 64)]
	for delta: float in [-3.001, -3.0, -2.999, 0.0, 2.999, 3.0, 3.001]:
		for offset: float in [0.0, 2.749, 2.75, 2.751]:
			probes.append(Vector3(offset, delta, -offset) / Vector3(sqrt(2.0), 1, sqrt(2.0)))
		for i in [1, 2]:
			var shape: Dictionary = exclusions[i]
			var half: Vector2 = shape.half
			for local: Vector2 in [Vector2.ZERO, Vector2(half.x, 0), Vector2(0, half.y), half]:
				var xz := local.rotated(float(shape.rotation))
				probes.append((shape.centre as Vector3) + Vector3(xz.x, delta, xz.y))
	for at: Vector3 in probes:
		assert_eq(cover._excluded(at, true), cover._excluded_from(at, exclusions),
			"packed overflow and bounded cells preserve the original narrow phase at %s" % at)
	cover._active_exclusions = []
	assert_false(cover._excluded(Vector3.ZERO, true), "rebuild clears the packed segment")
	assert_false(cover._excluded(Vector3(0, 20, 0), true), "rebuild clears the packed box")
	assert_false(cover._excluded(Vector3(0, 40, 0), true), "rebuild clears the packed ellipse")
	cover.free()
