extends "res://tests/test_case.gd"

const DUNES := preload("res://scripts/world/water_dune_cover.gd")
const VEGETATION := preload("res://scripts/world/water_vegetation.gd")
const ISLAND := {"id": "probe", "center_xz_m": [0.0, 0.0], "shore_radius_m": 100.0, "scatter_seed": 2042}

class ReliefField:
	extends RefCounted
	var gradient := 0.2
	var base_height := 60.0
	func height_at(x: float, _z: float) -> float:
		return base_height - gradient * x
	func normal_at(_x: float, _z: float, _step: float) -> Vector3:
		return Vector3(gradient, 1.0, 0.0).normalized()


func _settings() -> Dictionary:
	return {"enabled": true, "preserve_islands": ["veilfall"],
		"layers": {"trees": {"_dune_sheltered": true}, "shrubs": {"_dune_sheltered": true}},
		"shelter": {"shared_groves": true, "lee_direction_xz": [1.0, 0.0],
			"min_projection": 0.04, "max_radius_fraction": 0.78,
			"upwind_samples_m": [12.0, 24.0, 40.0], "ridge_relief_m": 3.0,
			"grove_search_attempts": 128, "grove_spacing_m": 20.0}}


func _vegetation(field: ReliefField, settings: Dictionary) -> Node3D:
	var node := VEGETATION.new()
	node._field = field
	node._dune_settings = settings.duplicate(true)
	var layer := {"models": ["probe_model"], "clusters": 4, "per_cluster": [2, 3],
		"cluster_radius_m": [2.0, 3.0], "scale": [1.0, 1.0], "min_height_m": 1.0, "max_slope_deg": 24.0}
	node._rules = {"layers": {"trees": layer.duplicate(true), "shrubs": layer.duplicate(true)},
		"shore_margin_m": 10.0}
	return node


func test_relief_reads_upwind_terrain_and_rejects_flat_or_reversed_slope() -> void:
	var field := ReliefField.new()
	var settings := _settings()
	var result := DUNES.ridge_shelter(Vector2(30, 0), Callable(field, "height_at"), settings)
	assert_true(result.valid)
	assert_almost_eq(float(result.relief_m), 8.0)
	assert_almost_eq(float(result.upwind_distance_m), 40.0)
	field.gradient = 0.0
	assert_false(DUNES.ridge_shelter(Vector2(30, 0), Callable(field, "height_at"), settings).valid)
	field.gradient = -0.2
	assert_false(DUNES.ridge_shelter(Vector2(30, 0), Callable(field, "height_at"), settings).valid)
	assert_false(DUNES.ridge_shelter(Vector2(30, 0), Callable(), settings).valid)
	settings.shelter.lee_direction_xz = [0.0, 0.0]
	assert_false(DUNES.ridge_shelter(Vector2(30, 0), Callable(field, "height_at"), settings).valid)


func test_canopy_and_understory_reuse_deterministic_validated_centres() -> void:
	var first := _vegetation(ReliefField.new(), _settings())
	var second := _vegetation(ReliefField.new(), _settings())
	var a := {}
	var b := {}
	first._place_island(ISLAND, a)
	second._place_island(ISLAND, b)
	assert_eq(a, b, "same island seed reproduces member transforms and assignments")
	assert_eq(first._grove_receipts, second._grove_receipts)
	var receipt: Dictionary = first._grove_receipts.probe
	assert_true(int(receipt.accepted) > 0)
	assert_true(int(receipt.accepted) <= int(receipt.requested))
	for centre: Dictionary in receipt.centres:
		assert_true(float(centre.relief_m) >= 3.0)
		assert_true(int(centre.accepted_members.trees) > 0)
		assert_true(int(centre.accepted_members.shrubs) > 0)
	for batch: Dictionary in a.values():
		for placement: Dictionary in batch.placements:
			assert_true(placement.has("grove_index"))
			var raw: Array = receipt.centres[int(placement.grove_index)].point_xz
			var centre := Vector2(float(raw[0]), float(raw[1]))
			var point := Vector2(placement.position.x, placement.position.z)
			assert_true(point.distance_to(centre) <= 3.001, "both layers use the recorded grove centre")
	first.free()
	second.free()


func test_no_relief_exhausts_bounded_search_without_fallback_groves() -> void:
	var flat := ReliefField.new()
	flat.gradient = 0.0
	var node := _vegetation(flat, _settings())
	var batches := {}
	node._place_island(ISLAND, batches)
	assert_eq(batches, {})
	var receipt: Dictionary = node._grove_receipts.probe
	assert_eq(receipt.accepted, 0)
	assert_eq(receipt.attempts, 128)
	assert_true(int(receipt.rejected_relief) > 0)
	node.free()


func test_clearance_and_slope_rejections_are_not_bypassed_for_groves() -> void:
	var node := _vegetation(ReliefField.new(), _settings())
	node._exclusion_points.append({"at": Vector2.ZERO, "radius": 200.0})
	var batches := {}
	node._place_island(ISLAND, batches)
	assert_eq(batches, {})
	assert_eq(node._grove_receipts.probe.rejected_ground_or_clearance, 128)
	node.free()
	var steep := ReliefField.new()
	steep.gradient = 2.0
	node = _vegetation(steep, _settings())
	node._place_island(ISLAND, batches)
	assert_eq(batches, {})
	assert_eq(node._grove_receipts.probe.accepted, 0)
	node.free()


func test_disabled_groves_leave_the_original_placement_stream_exact() -> void:
	var flat := ReliefField.new()
	flat.gradient = 0.0
	var disabled := _settings()
	disabled.enabled = false
	var ordinary := _vegetation(flat, {})
	var candidate := _vegetation(flat, disabled)
	var a := {}
	var b := {}
	ordinary._place_island(ISLAND, a)
	candidate._place_island(ISLAND, b)
	assert_false(a.is_empty(), "ordinary vegetation still populates flat unsheltered land")
	assert_eq(a, b, "disabled grove settings consume no extra random draws")
	assert_eq(candidate._grove_receipts, {})
	assert_false(DUNES.shared_groves_enabled("veilfall", _settings()))
	assert_false(DUNES.shared_groves_enabled("probe", {}))
	ordinary.free()
	candidate.free()
