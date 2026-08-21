extends "res://tests/test_case.gd"

## `scripts/world/map_baker.gd` — the minimap's baked terrain texture (D33).
##
## Pure-logic only, per D02/`test_case.gd`'s own scope: this cannot judge
## whether the bake LOOKS right (that is `tools/capture_minimap.gd` and a
## human eye), but it can hold the two properties a baker must never break
## without anyone noticing — a deep basin reads as water and a hill reads as
## something other than flat ground — and that re-baking the same world
## twice never produces a different picture, which is what makes
## `bake_cached()`'s disk cache trustworthy instead of merely fast.
##
## `FakeWorld` never touches Terrain3D or the scene tree — `map_baker.gd`
## only asks its `world` argument for `ground_height_at`, so a bare
## `RefCounted` with that one method is a complete stand-in.

const MAP_BAKER := preload("res://scripts/world/map_baker.gd")
const RESOLUTION := 64
const TEST_BOUNDS := {
	"min_x": -256.0,
	"max_x": 256.0,
	"min_z": -256.0,
	"max_z": 256.0,
}

## A single hill and a single below-water basin, at fixed world coordinates,
## as a deterministic closed-form function — no noise, no state, so two
## instances always agree pixel-for-pixel.
class FakeWorld extends RefCounted:
	const HILL_CENTRE := Vector2(100.0, 100.0)
	const BASIN_CENTRE := Vector2(-100.0, -100.0)
	const FEATURE_RADIUS := 60.0

	func ground_height_at(x: float, z: float) -> float:
		var height := 0.0
		var to_hill := Vector2(x, z).distance_to(HILL_CENTRE)
		if to_hill < FEATURE_RADIUS:
			height += (1.0 - to_hill / FEATURE_RADIUS) * 40.0
		var to_basin := Vector2(x, z).distance_to(BASIN_CENTRE)
		if to_basin < FEATURE_RADIUS:
			# Well below the project's real water level (-22.5m,
			# `data/config/terrain_playground.json`'s `water.level`), so this
			# is unambiguously underwater regardless of tuning drift there.
			height -= (1.0 - to_basin / FEATURE_RADIUS) * 40.0
		return height


func _cleanup(cache_path: String) -> void:
	var key_path := cache_path + ".key"
	if FileAccess.file_exists(cache_path):
		DirAccess.remove_absolute(cache_path)
	if FileAccess.file_exists(key_path):
		DirAccess.remove_absolute(key_path)


func _world_to_pixel(world_position: Vector2) -> Vector2i:
	var step_x := (TEST_BOUNDS.max_x - TEST_BOUNDS.min_x) / float(RESOLUTION)
	var step_z := (TEST_BOUNDS.max_z - TEST_BOUNDS.min_z) / float(RESOLUTION)
	return Vector2i(
		int((world_position.x - TEST_BOUNDS.min_x) / step_x),
		int((world_position.y - TEST_BOUNDS.min_z) / step_z),
	)


# --- bake() ------------------------------------------------------------------

func test_bake_returns_a_texture_of_the_requested_resolution() -> void:
	var texture := MAP_BAKER.bake(FakeWorld.new(), RESOLUTION, TEST_BOUNDS)
	var image := texture.get_image()
	assert_eq(image.get_width(), RESOLUTION)
	assert_eq(image.get_height(), RESOLUTION)


func test_a_deep_basin_pixel_reads_as_water() -> void:
	var texture := MAP_BAKER.bake(FakeWorld.new(), RESOLUTION, TEST_BOUNDS)
	var image := texture.get_image()

	# Keep this synthetic feature test at a resolution where the 60m basin is
	# actually sampled. The production default is now the 8km Meadows corridor;
	# at 64px its 128m z step can legitimately skip this deliberately tiny fake.
	var basin_pixel := _world_to_pixel(FakeWorld.BASIN_CENTRE)

	var basin_colour := image.get_pixelv(basin_pixel)
	assert_true(basin_colour.b > basin_colour.r,
		"a deep underwater pixel must read bluer than red, got %s" % basin_colour)


func test_a_hill_pixel_differs_from_flat_ground() -> void:
	var texture := MAP_BAKER.bake(FakeWorld.new(), RESOLUTION, TEST_BOUNDS)
	var image := texture.get_image()

	var hill_pixel := _world_to_pixel(FakeWorld.HILL_CENTRE)

	# A corner far from both features: world height 0 there, ordinary flat
	# ground.
	var flat_colour: Color = image.get_pixel(0, 0)
	var hill_colour: Color = image.get_pixelv(hill_pixel)

	assert_true(flat_colour != hill_colour,
		"the hill's summit must read as visually different from flat ground")


func test_bake_is_deterministic() -> void:
	var first := MAP_BAKER.bake(FakeWorld.new(), RESOLUTION, TEST_BOUNDS).get_image()
	var second := MAP_BAKER.bake(FakeWorld.new(), RESOLUTION, TEST_BOUNDS).get_image()
	assert_eq(first.get_data(), second.get_data(),
		"baking the same world twice must produce byte-identical images")


# --- bake_cached() -------------------------------------------------------

func test_bake_cached_bakes_once_then_hits_the_cache() -> void:
	var cache_path := "user://cache/test_map_baker_cache.png"
	_cleanup(cache_path)

	var world := FakeWorld.new()
	var first := MAP_BAKER.bake_cached(world, cache_path)
	assert_false(MAP_BAKER.last_bake_was_cache_hit,
		"the first call has nothing to load yet and must actually bake")
	assert_true(FileAccess.file_exists(cache_path), "bake_cached must write the PNG")
	assert_true(FileAccess.file_exists(cache_path + ".key"), "bake_cached must write the key sidecar")

	var second := MAP_BAKER.bake_cached(world, cache_path)
	assert_true(MAP_BAKER.last_bake_was_cache_hit,
		"a second call against an unchanged config must load the cache, not re-bake")
	assert_eq(second.get_image().get_data(), first.get_image().get_data(),
		"a cache hit must return the same pixels the original bake wrote")

	_cleanup(cache_path)
