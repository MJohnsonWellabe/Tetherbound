extends "res://tests/test_case.gd"

## Shared-file grant (#299): the minimap draws the Dark Arches road markers
## (`stormwood_arch_road_*`, written by stormwood_arch_runtime.gd) as an arch
## glyph; every other dynamic marker keeps its existing glyph.
const MINIMAP := preload("res://scripts/ui/minimap.gd")
const MAP_STATE := preload("res://autoload/map_state.gd")


func test_arch_road_markers_draw_as_an_arch_gate() -> void:
	assert_eq(MINIMAP.dynamic_marker_glyph("stormwood_arch_road_rodline_post"), "arch_gate")
	assert_eq(MINIMAP.ARCH_ROAD_MARKER_PREFIX, "stormwood_arch_road_")


func test_other_dynamic_markers_keep_their_glyphs() -> void:
	assert_eq(MINIMAP.dynamic_marker_glyph(MAP_STATE.ALPHA_MARKER_PREFIX + "2011"), "alpha")
	assert_eq(MINIMAP.dynamic_marker_glyph("camp_ashfoot_waycamp"), "camp")
	assert_eq(MINIMAP.dynamic_marker_glyph(""), "camp")
	assert_eq(MINIMAP.dynamic_marker_glyph("stormwood_arch_ashfoot"), "camp",
		"only the road-marker prefix changes glyph")


func test_arch_glyph_is_an_open_arch_not_a_dot() -> void:
	var points: PackedVector2Array = MINIMAP.arch_gate_points(Vector2(50, 50), 7.0)
	assert_eq(points.size(), 11)
	# Both feet sit on the same baseline below the centre; the head is above it.
	assert_almost_eq(points[0].y, 57.0, 0.001)
	assert_almost_eq(points[points.size() - 1].y, 57.0, 0.001)
	assert_true(points[0].x < 50.0 and points[points.size() - 1].x > 50.0, "posts either side")
	var top := INF
	for point: Vector2 in points:
		top = minf(top, point.y)
	assert_almost_eq(top, 50.0 - 0.7 - 4.9, 0.001, "rounded head above the centre")
