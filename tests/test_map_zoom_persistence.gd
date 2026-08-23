extends "res://tests/test_case.gd"

## OP23-03 (owner playtest 2026-08-23): "zoom level should persist" across map
## opens. `tab_map.gd::build()` runs every time the map tab (re)opens
## (`game_menu.gd` forces a rebuild on open/select) and used to hardcode
## `_zoom = MIN_ZOOM` unconditionally, so a player who zoomed in, closed the
## map, and reopened it always landed back at whole-world fit.
##
## `tests/smoke_gate_a_map_cycle.gd` already drives the real scene through a
## zoom/pan/close cycle with physical input; this pins the wiring itself
## (source-inspection, `test_case.gd`/D02: pure logic only) rather than
## duplicating that scene-boot cost for a check that does not need a live
## Terrain3D.

func _source(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s is missing" % path)
	return file.get_as_text() if file != null else ""


func test_game_state_carries_a_remembered_zoom_field() -> void:
	var source := _source("res://autoload/game_state.gd")
	assert_true(source.contains("var map_last_zoom"),
		"game_state.gd has no map_last_zoom field for tab_map.gd to persist zoom through")


func test_build_reads_the_remembered_zoom_instead_of_hardcoding_min_zoom() -> void:
	var source := _source("res://scripts/ui/tab_map.gd")
	var start := source.find("func build(")
	assert_true(start >= 0, "tab_map.gd has no build()")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	assert_true(body.contains("map_last_zoom"),
		"build() never reads Game.map_last_zoom; every map open still resets to MIN_ZOOM")
	assert_false(body.contains("_zoom = MIN_ZOOM"),
		"build() still hardcodes _zoom = MIN_ZOOM, which would override any remembered zoom")


func test_zooming_writes_the_remembered_zoom_back() -> void:
	var source := _source("res://scripts/ui/tab_map.gd")
	var start := source.find("func _read_navigation_input(")
	assert_true(start >= 0, "tab_map.gd has no _read_navigation_input()")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	assert_true(body.contains("map_last_zoom"),
		"_read_navigation_input() never writes map_last_zoom back; a zoom change would not "
		+ "survive the tab closing")
