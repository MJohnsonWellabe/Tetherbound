extends "res://tests/test_case.gd"

const NOTICE := preload("res://scripts/world/water_first_shore_current_notice.gd")
const FLAGS := preload("res://autoload/progression_state.gd")
const BOUNDS := preload("res://scripts/characters/render_bounds.gd")

class Shore extends Node3D:
	func ground_height_at(_x: float, _z: float) -> float:
		return 1.4

class WorldFacts extends RefCounted:
	var flags := FLAGS.new()

class GameFixture extends Node:
	var world := WorldFacts.new()

func test_notice_is_grounded_beside_the_route_and_never_adds_a_boundary() -> void:
	var shore := Shore.new()
	var game := GameFixture.new()
	var notice := NOTICE.new()
	notice.build(shore, game)
	var bounds: AABB = notice.transform * BOUNDS.measure(notice)
	assert_almost_eq(bounds.position.y, 1.4, 0.001)
	assert_true(bounds.end.x < -6.0, "notice leaves the full eight-metre approach clear")
	assert_true(bounds.size.x < 2.5, "guidance and its lantern are a compact shore prop")
	assert_eq(notice.find_children("*", "CollisionObject3D", true, false).size(), 0)
	assert_eq(notice.find_children("*", "Area3D", true, false).size(), 0)
	notice.free()
	game.free()
	shore.free()

func test_existing_world_lesson_flag_updates_the_same_notice_and_reload_rebinds_it() -> void:
	var shore := Shore.new()
	var game := GameFixture.new()
	var notice := NOTICE.new()
	notice.build(shore, game)
	var label := notice.get_node("PaintedRouteNotice") as Label3D
	var closed := label.text
	assert_true(closed.contains("STRONG CURRENT"))
	game.world.flags.set_flag("water_swim_lesson_complete")
	notice._refresh()
	assert_true(label.text.contains("CHANNEL OPEN"))
	assert_true(notice.get_node("PaintedRouteNotice") == label, "the station persists")
	game.world = WorldFacts.new()
	notice.restore_progression_from_game(game)
	assert_eq(label.text, closed, "a different world's closed route is shown after reload")
	assert_false(game.world.flags.has("water_swim_lesson_complete"), "notice never writes progression")
	notice.free()
	game.free()
	shore.free()
