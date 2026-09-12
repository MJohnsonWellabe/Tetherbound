extends "res://tests/test_case.gd"

## Owner 2026-09-12 Tier 1 #5 / Tier 4 #1: personal, durable map pins and
## visible same-realm co-op trainers on the full map.

const GAME := preload("res://autoload/game_state.gd")
const MAP_STATE := preload("res://autoload/map_state.gd")
const TAB_MAP := preload("res://scripts/ui/tab_map.gd")


class MenuDouble extends Node:
	var game: Node = null
	var messages: Array[String] = []

	func say(message: String) -> void:
		messages.append(message)


class RemoteTrainerDouble extends Node3D:
	var net_realm := "meadows"
	var peer_id := 2
	var display_name := "Juniper"


var game: Node = null
var menu: MenuDouble = null
var tab: Control = null


func before_each() -> void:
	game = GAME.new()
	game.call("reset_for_new_game")
	menu = MenuDouble.new()
	menu.game = game
	tab = TAB_MAP.new()
	tab.set("menu", menu)


func after_each() -> void:
	tab.free()
	menu.free()
	game.free()


func test_canvas_world_mapping_round_trips_at_handheld_zoom_and_pan() -> void:
	tab.set("_zoom", 8.0)
	tab.set("_pan_world", Vector2(40.0, 2100.0))
	var rect: Rect2 = tab.call("_map_rect_for_canvas", Vector2(1180.0, 520.0))
	var authored := Vector2(32.0, 2050.0)
	var canvas: Vector2 = tab.call("_world_to_canvas", authored, rect)
	var restored: Vector2 = tab.call("_canvas_to_world", canvas, rect)
	assert_almost_eq(restored.x, authored.x, 0.01)
	assert_almost_eq(restored.y, authored.y, 0.01)


func test_pixel_hit_testing_removes_only_the_pin_under_the_cursor() -> void:
	var map: RefCounted = game.get("map")
	var first: String = map.call("add_player_marker", Vector3(10.0, 0.0, 100.0))
	map.call("add_player_marker", Vector3(90.0, 0.0, 2100.0))
	tab.set("_zoom", 4.0)
	tab.set("_pan_world", Vector2.ZERO)
	var rect: Rect2 = tab.call("_map_rect_for_canvas", Vector2(900.0, 520.0))
	var first_point: Vector2 = tab.call("_world_to_canvas", Vector2(10.0, 100.0), rect)
	var nearest: Dictionary = tab.call("_nearest_player_marker_to_canvas", map,
		first_point + Vector2(5.0, 2.0), rect, 38.0)
	assert_eq(str(nearest.get("id", "")), first)
	assert_true((tab.call("_nearest_player_marker_to_canvas", map,
		Vector2(-500.0, -500.0), rect, 38.0) as Dictionary).is_empty())


func test_remote_player_record_keeps_visible_same_realm_friend_and_name() -> void:
	var remote := RemoteTrainerDouble.new()
	remote.position = Vector3(21.0, 4.0, 305.0)
	var record: Dictionary = TAB_MAP.remote_player_marker_record(remote, "meadows")
	assert_eq(int(record.get("peer_id", 0)), 2)
	assert_eq(str(record.get("display_name", "")), "Juniper")
	assert_eq(record.get("position"), remote.position)

	assert_true(TAB_MAP.remote_player_marker_record(remote, "cloudreach").is_empty(),
		"a Meadows trainer must not be painted onto another realm")
	remote.visible = false
	assert_true(TAB_MAP.remote_player_marker_record(remote, "meadows").is_empty(),
		"the local owner's hidden replication proxy must not become a second dot")
	remote.free()


func test_map_draw_path_and_controller_legend_expose_both_new_verbs() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/tab_map.gd")
	assert_true(source.contains("for remote: Dictionary in _remote_player_rows(world)"),
		"the full-map draw path must consume replicated remote trainers")
	assert_true(source.contains("_draw_player_pin(canvas, map_rect, entry)"),
		"personal pins must be drawn as a distinct full-map marker")
	assert_true(source.contains("A  Place marker") and source.contains("X  Remove marker"),
		"the handheld map must say both context-scoped controller verbs on screen")
