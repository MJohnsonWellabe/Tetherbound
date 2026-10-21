extends "res://tests/test_case.gd"

## Homestead gathering after the bridge piece (F49#0 training_t1_altar_1):
## the Altar's rootstone lies in the quarry across the South Bridge gully.
## A straight walk from home met the gully far east of the span and never
## arrived; supply walks must cross on the open bridge, both ways.
const MATERIAL := preload("res://tests/helpers/meadows_earned_material_segment.gd")

class FakeBridge extends Node:
	var open := true
	func is_open() -> bool: return open
	func depth_past_crossing(spot: Vector2) -> float: return spot.y - 1330.0
	func near_point(distance: float) -> Vector2: return Vector2(8.0, 1330.0 - distance)
	func far_point(distance: float) -> Vector2: return Vector2(8.0, 1330.0 + distance)

func _world(open: bool) -> Node:
	var world := Node.new()
	var bridge := FakeBridge.new()
	bridge.name = "SouthBridge"
	bridge.open = open
	world.add_child(bridge)
	return world

func test_home_to_quarry_crosses_on_the_bridge_and_back() -> void:
	var world := _world(true)
	var home := Vector2(-22.7, 22.7)
	var quarry := Vector2(399.0, 1792.0)
	var out := MATERIAL.bridge_legs(world, home, quarry)
	assert_true(out.size() >= 2, "outbound walk gets bridge waypoints")
	assert_eq(out[out.size() - 1], Vector2(8.0, 1340.0), "outbound ends on the far bank")
	assert_eq(out[out.size() - 2], Vector2(8.0, 1320.0), "outbound reaches the near bank first")
	var back := MATERIAL.bridge_legs(world, quarry, home)
	assert_eq(back[0], Vector2(8.0, 1340.0), "return starts on the far bank")
	assert_eq(back[1], Vector2(8.0, 1320.0), "return then crosses to the near bank")
	assert_eq(back.size(), out.size(), "same authored approach both ways")
	world.free()

func test_same_side_or_closed_bridge_adds_no_legs() -> void:
	var world := _world(true)
	assert_eq(MATERIAL.bridge_legs(world, Vector2(-22.7, 22.7), Vector2(20.0, 14.0)).size(), 0)
	assert_eq(MATERIAL.bridge_legs(world, Vector2(399.0, 1792.0), Vector2(-361.0, 2576.0)).size(), 0)
	world.free()
	var closed := _world(false)
	assert_eq(MATERIAL.bridge_legs(closed, Vector2(-22.7, 22.7), Vector2(399.0, 1792.0)).size(), 0)
	closed.free()
