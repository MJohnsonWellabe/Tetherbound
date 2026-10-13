extends "res://tests/test_case.gd"

## Realm-load profile (2026-10-12): the Meadows cover-clearance test runs once
## per scatter placement, so its zones are precomputed. The fast path must give
## exactly the original per-zone answer everywhere, including at zone edges.

const CATALOG := preload("res://scripts/world/meadows_catalog_presentation.gd")


func _reference(at: Vector2) -> bool:
	for zone: Dictionary in CATALOG.settings().get("cover_clearances", []):
		var centre := Vector2(float(zone.at[0]), float(zone.at[1]))
		if at.distance_to(centre) < float(zone.radius_m):
			return true
	return false


func test_precomputed_clearance_matches_the_per_zone_test_everywhere() -> void:
	var zones: Array = CATALOG.settings().get("cover_clearances", [])
	assert_true(zones.size() > 0, "the Meadows catalog declares cover clearances")
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261012
	var mismatches := 0
	var inside := 0
	for i in 20000:
		var at := Vector2(rng.randf_range(-400.0, 400.0), rng.randf_range(-400.0, 1600.0))
		var expected := _reference(at)
		inside += 1 if expected else 0
		if CATALOG.in_cover_clearance(at) != expected:
			mismatches += 1
	# Every zone's centre, a point just inside and exactly on its rim.
	for zone: Dictionary in zones:
		var centre := Vector2(float(zone.at[0]), float(zone.at[1]))
		var radius := float(zone.radius_m)
		for at: Vector2 in [centre, centre + Vector2(radius * 0.999, 0), centre + Vector2(radius, 0),
				centre + Vector2(0, -radius * 1.001)]:
			if CATALOG.in_cover_clearance(at) != _reference(at):
				mismatches += 1
	assert_eq(mismatches, 0, "precomputed clearance must equal the per-zone test")
	assert_true(inside > 0, "the sample reached inside some zones (non-vacuous)")


func test_suppress_cover_keeps_its_harvest_and_collision_exemptions() -> void:
	var zone: Dictionary = (CATALOG.settings().get("cover_clearances", []) as Array)[0]
	var at := Vector3(float(zone.at[0]), 0.0, float(zone.at[1]))
	var layer: String = (CATALOG.settings().get("cover_layers", []) as Array)[0]
	if not CATALOG.enabled():
		assert_false(CATALOG.suppress_cover(layer, {"position": at}), "disabled catalog suppresses nothing")
		return
	assert_true(CATALOG.suppress_cover(layer, {"position": at}), "plain cover inside a clearance is suppressed")
	assert_false(CATALOG.suppress_cover(layer, {"position": at, "harvest_item": "x"}), "harvestables never")
	assert_false(CATALOG.suppress_cover(layer, {"position": at, "collide": true}), "colliders never")
	assert_false(CATALOG.suppress_cover("not_a_cover_layer", {"position": at}), "other layers never")
