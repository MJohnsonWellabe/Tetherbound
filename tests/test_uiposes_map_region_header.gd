extends "res://tests/test_case.gd"

## P2-048 UIPOSES candidate: menu.json map_region_header ships OFF; the "You
## are here" line names the map state's current region.

const TAB := preload("res://scripts/ui/tab_map.gd")


class FakeMap:
	extends RefCounted
	var _current_region_id := "lower_cliffs"
	func regions() -> Array:
		return [{"id": "gate", "display_name": "Cloudreach Gate"}, {"id": "lower_cliffs", "display_name": "Cloudreach Gate / Lower Cliffs"}]


func test_ships_off() -> void:
	assert_false(TAB.map_region_header_enabled())


func test_here_text_names_current_region() -> void:
	var map := FakeMap.new()
	assert_eq(TAB.here_text(map), "You are here: Cloudreach Gate / Lower Cliffs")
	map._current_region_id = ""
	assert_eq(TAB.here_text(map), "")
	assert_eq(TAB.here_text(null), "")
