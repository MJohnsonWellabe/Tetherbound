extends "res://tests/test_case.gd"

## F04: Grandpa's house hands the camera to the trainer on entry/exit, but only
## while the camera is already on the trainer. A fight (camera on the piloted
## ally) or the catch close-up (camera on the orb) keeps it. The guardian
## witness found the unguarded exit snapping the Warrens fight camera back to
## the trainer, facing away from the guardian through both tells.

const HOUSE := preload("res://scripts/world/grandpa_house.gd")


class Rig extends Node3D:
	var _target: Node3D = null
	var calls: Array = []

	func set_target(target: Node3D, profile: Dictionary = {}) -> void:
		_target = target
		calls.append([target, profile])


func _house(rig: Rig, player: Node3D) -> Node3D:
	var house: Node3D = HOUSE.new()
	house.set("_camera_rig", rig)
	house.set("_player", player)
	return house


func test_leaving_the_house_mid_fight_keeps_the_fight_camera() -> void:
	var rig := Rig.new()
	var player := Node3D.new()
	var ally := Node3D.new()
	var house := _house(rig, player)
	rig._target = ally
	house.call("_on_body_exited", player)
	assert_eq(rig._target, ally, "the fight owns the camera; leaving the house must not take it")
	assert_eq(rig.calls.size(), 0)
	house.call("_on_body_entered", player)
	assert_eq(rig._target, ally, "entering mid-fight must not take it either")
	house.free(); rig.free(); player.free(); ally.free()


func test_the_catch_close_up_keeps_the_camera() -> void:
	var rig := Rig.new()
	var player := Node3D.new()
	var orb := Node3D.new()
	var house := _house(rig, player)
	rig._target = orb
	house.call("_on_body_exited", player)
	assert_eq(rig._target, orb)
	house.free(); rig.free(); player.free(); orb.free()


func test_the_house_still_swaps_the_profile_when_the_camera_is_on_the_trainer() -> void:
	var rig := Rig.new()
	var player := Node3D.new()
	var other := Node3D.new()
	var house := _house(rig, player)
	rig._target = player
	house.call("_on_body_entered", player)
	assert_eq(rig.calls.size(), 1, "entering hands the trainer the interior profile")
	assert_false((rig.calls[0][1] as Dictionary).is_empty(), "the interior profile is not the default")
	house.call("_on_body_exited", player)
	assert_eq(rig.calls.size(), 2, "leaving hands the default profile back")
	assert_true((rig.calls[1][1] as Dictionary).is_empty())
	house.call("_on_body_exited", other)
	assert_eq(rig.calls.size(), 2, "another body leaving changes nothing")
	house.free(); rig.free(); player.free(); other.free()
