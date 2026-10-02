extends "res://tests/test_case.gd"

const STONES := preload("res://scripts/world/waystone.gd")
class BakeSource extends Node3D:
	var field := preload("res://scripts/world/water_heightfield.gd").new()
	func ground_height_at(x: float, z: float) -> float: return field.height_at(x, z)

func test_salt_crown_shrine_and_arrival_fit_original_bake_surface_without_relaxing_support() -> void:
	var row: Dictionary = {}
	for candidate: Dictionary in STONES.load_config().waystones:
		if candidate.id == "tidewake_salt_crown": row = candidate
	assert_false(row.is_empty())
	var world := BakeSource.new()
	assert_true(STONES.resolve_position(world, row).is_finite())
	assert_true(STONES.resolve_position(world, row, true).is_finite())
	var old := row.duplicate(true)
	old.offset_xz = [0.0, -7.0]
	assert_false(STONES.resolve_position(world, old).is_finite(), "old pad crosses steep terrain perimeter")
	world.free()
