extends "res://tests/test_case.gd"

## F39#3 r2: the Drowned Garden flood sheet holds water only over ground inside
## its depth band (never over a slope), and builds nothing while OFF.
const FLOOD := preload("res://scripts/world/water_garden_flood.gd")


class SlopeWorld extends Node:
	## Flat 28.3 m crest for x >= 1105, falling 1 m per metre west of it.
	func ground_height_at(x: float, _z: float) -> float:
		return 28.3 if x >= 1105.0 else 28.3 - (1105.0 - x)


func test_wet_band() -> void:
	assert_true(FLOOD.wet(28.3, 28.15, 28.47), "crest ground under the sheet holds water")
	assert_false(FLOOD.wet(27.0, 28.15, 28.47), "ground far below (a slope) holds none: no floating edge")
	assert_false(FLOOD.wet(28.49, 28.15, 28.47), "ground at or above the surface stays dry")
	assert_false(FLOOD.wet(INF, 28.15, 28.47), "an unsampled point stays dry")


func test_shipped_config_is_off_and_builds_nothing() -> void:
	var cfg := FLOOD.settings()
	assert_false(bool(cfg.get("enabled", true)), "OFF until judged")
	var flood := FLOOD.new()
	var world := SlopeWorld.new()
	assert_eq(flood.build(world), 0, "an OFF flood builds no cells")
	assert_eq(flood.get_child_count(), 0)
	flood.free()
	world.free()


func test_cells_stop_at_the_slope() -> void:
	var cfg := FLOOD.settings()
	var level := float(cfg.surface_y)
	var deepest := level - float(cfg.max_depth_m)
	var region: Array = cfg.region_xz
	# Every column west of the crest edge whose centre drops below the band is dry.
	var world := SlopeWorld.new()
	var cell := float(cfg.cell_m)
	var x := float(region[0]) + cell * 0.5
	while x < float(region[2]):
		var ground := world.ground_height_at(x, 0.0)
		assert_eq(FLOOD.wet(ground, deepest, level - float(cfg.min_depth_m)), ground >= deepest,
			"column x=%.2f follows the depth band" % x)
		x += cell
	world.free()
