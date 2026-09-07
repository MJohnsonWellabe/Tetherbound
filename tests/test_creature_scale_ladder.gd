extends "res://tests/test_case.gd"

## Owner directive 2026-09-07: Palworld-like creature scale. The 1.80m
## trainer is the fixed ruler; every creature must be taller, the smallest
## class only just, while regional apex/legendary bodies must be much larger.

const TRAINER_HEIGHT_M := 1.80
const SPECIES_PATH := "res://data/creatures/species.json"
const WATER_ROSTER_PATH := "res://data/config/water_roster.json"
const WATER_MOUNTS_PATH := "res://data/config/water_mounts.json"


func test_every_global_creature_clears_the_trainer_and_keeps_physical_proportions() -> void:
	var species: Dictionary = _json(SPECIES_PATH).get("species", {})
	assert_eq(species.size(), 57, "the scale gate must cover the complete installed roster")
	var heights: Array[float] = []
	for id: String in species:
		var look: Dictionary = species[id].get("placeholder", {})
		var height := float(look.get("height", 0.0))
		var radius := float(look.get("radius", 0.0))
		heights.append(height)
		assert_true(height > TRAINER_HEIGHT_M,
			"%s is %.2fm and does not stand taller than the 1.80m trainer" % [id, height])
		assert_true(radius / height >= 0.25 and radius / height <= 0.50,
			"%s radius/height %.3f no longer matches its grown body" % [id, radius / height])
	heights.sort()
	assert_almost_eq(heights[0], 1.90, 0.001, "the smallest class should sit just over the trainer")
	assert_true(heights[-1] >= 7.0, "the largest creature must tower over the trainer")
	assert_true(_count_between(heights, 1.90, 2.15) >= 5, "the small class disappeared")
	assert_true(_count_between(heights, 2.30, 3.10) >= 10, "the medium class disappeared")
	assert_true(_count_between(heights, 3.25, 3.85) >= 20, "the large class disappeared")
	assert_true(_count_between(heights, 4.00, 4.99) >= 5, "the giant class disappeared")
	assert_true(_count_between(heights, 5.00, 99.0) >= 5, "the apex class disappeared")


func test_water_targets_and_rider_geometry_share_the_larger_scale() -> void:
	var roster: Dictionary = _json(WATER_ROSTER_PATH).get("species", {})
	var mounts: Dictionary = _json(WATER_MOUNTS_PATH).get("mounts", {})
	assert_eq(roster.size(), 12)
	var maximum := 0.0
	for id: String in roster:
		var target := float(roster[id].get("placeholder", {}).get("target_height_m", 0.0))
		assert_true(target > TRAINER_HEIGHT_M, "water_%s does not clear the trainer" % id)
		maximum = maxf(maximum, target)
		var runtime_id := "water_" + id
		if not mounts.has(runtime_id):
			continue
		var geometry: Dictionary = mounts[runtime_id]
		var seat: Array = geometry.get("mount_offset", [])
		assert_eq(seat.size(), 3, runtime_id + " has no measured rider seat")
		if seat.size() == 3:
			assert_true(float(seat[1]) > 0.0 and float(seat[1]) < target,
				runtime_id + " rider seat is outside the grown body")
		var collision_radius := float(geometry.get("measurement", {}).get("collision_radius_m", 0.0))
		assert_true(float(geometry.get("dismount_distance", 0.0)) >= collision_radius + 0.65,
			runtime_id + " dismount clearance did not grow with its collision radius")
	assert_true(maximum >= 7.0, "Water's legendary no longer reads as an apex body")


func _count_between(values: Array[float], minimum: float, maximum: float) -> int:
	var count := 0
	for value: float in values:
		if value >= minimum and value <= maximum:
			count += 1
	return count


func _json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, path + " must parse")
	return parsed as Dictionary if parsed is Dictionary else {}
