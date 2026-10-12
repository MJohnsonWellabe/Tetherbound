extends "res://tests/test_case.gd"

## Realm-load profile (2026-10-12): the map bake asks path_factor_over() about
## only the road bands whose reach box holds the pixel, and skips the apron
## factor outside every footprint's reach. Both must equal the full calls.

const BAKER := preload("res://scripts/world/map_baker.gd")
const HEIGHTFIELD := preload("res://scripts/world/playground_heightfield.gd")
const WORLD_EXTENT := preload("res://scripts/world/world_extent.gd")


func test_filtered_path_and_apron_factors_equal_the_full_ones() -> void:
	var heightfield: RefCounted = HEIGHTFIELD.new()
	var bands: Array = heightfield.call("road_bands")
	assert_true(bands.size() > 0, "the Meadows config has road bands (non-vacuous)")
	var boxes: Array = BAKER._band_reach_boxes(heightfield, bands)
	var apron_box: Rect2 = BAKER._apron_reach_box(heightfield)
	var extent: Dictionary = WORLD_EXTENT.bounds()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1012
	var mismatches := 0
	var on_road := 0
	var points: Array[Vector2] = []
	for i in 6000:
		points.append(Vector2(rng.randf_range(float(extent.min_x), float(extent.max_x)),
			rng.randf_range(float(extent.min_z), float(extent.max_z))))
	# And points on and beside the roads themselves, where the edges matter.
	for band: Dictionary in bands.slice(0, 20):
		var line: PackedVector2Array = band["line"]
		for point: Vector2 in line:
			for offset: float in [0.0, float(band["half"]), float(band["half"]) + float(band["shoulder"])]:
				points.append(point + Vector2(offset, 0.0))
	for at: Vector2 in points:
		var full: float = heightfield.call("path_factor", at.x, at.y)
		var near: Array = []
		for b in bands.size():
			if (boxes[b] as Rect2).has_point(at):
				near.append(bands[b])
		var filtered: float = heightfield.call("path_factor_over", at.x, at.y, near) if not near.is_empty() else 0.0
		if full != filtered:
			mismatches += 1
		on_road += 1 if full > 0.0 else 0
		var apron_full: float = heightfield.call("building_apron_factor", at.x, at.y)
		var apron_filtered: float = heightfield.call("building_apron_factor", at.x, at.y) if apron_box.has_point(at) else 0.0
		if apron_full != apron_filtered:
			mismatches += 1
	assert_eq(mismatches, 0, "filtered factors equal the full calls")
	assert_true(on_road > 0, "some sampled points lie on a road")
