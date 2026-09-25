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


class FakeManager extends Node:
	signal exited(outcome: String)
	var fighting := true

	func is_fighting() -> bool:
		return fighting


func test_throw_aim_mid_fight_keeps_its_profile_at_the_door() -> void:
	# Throw aim puts the camera on the trainer mid-fight; the door must not
	# replace the aim profile while the fight runs.
	var world := Node3D.new()
	var manager := FakeManager.new()
	manager.name = "CombatManager"
	world.add_child(manager)
	var rig := Rig.new()
	var player := Node3D.new()
	var house := _house(rig, player)
	world.add_child(house)
	rig._target = player
	house.call("_on_body_exited", player)
	house.call("_on_body_entered", player)
	assert_eq(rig.calls.size(), 0, "a running fight owns the camera even while it is on the trainer")
	manager.fighting = false
	house.call("_on_body_entered", player)
	assert_eq(rig.calls.size(), 1, "after the fight the house swaps the profile again")
	world.free(); rig.free(); player.free()



## Where the trainer stands is the house's own box measurement; stubbed here so
## the test needs no scene tree.
class PlacedHouse extends "res://scripts/world/grandpa_house.gd":
	var inside := true

	func _player_is_inside() -> bool:
		return inside


func test_a_fight_that_ends_indoors_restores_the_interior_profile() -> void:
	# The crossing is skipped while the fight owns the camera; the fight then
	# hands the trainer back on the default profile. Indoors that is wrong, so
	# the skipped crossing settles itself when the fight exits.
	var world := Node3D.new()
	var manager := FakeManager.new()
	manager.name = "CombatManager"
	world.add_child(manager)
	var rig := Rig.new()
	var player := Node3D.new()
	var ally := Node3D.new()
	var house := PlacedHouse.new()
	house.set("_camera_rig", rig)
	house.set("_player", player)
	world.add_child(house)
	rig._target = ally
	house.call("_on_body_entered", player)
	assert_eq(rig.calls.size(), 0, "mid-fight the crossing is skipped")
	var settle := Callable(house, "_on_fight_exited_after_crossing")
	assert_true(manager.is_connected("exited", settle), "the skipped crossing waits for the fight to end")
	house.call("_on_body_exited", player)
	house.call("_on_body_entered", player)
	# The fight ends: released to the trainer on the default profile.
	manager.fighting = false
	rig._target = player
	manager.exited.emit("won")
	assert_false(manager.is_connected("exited", settle), "one settle per fight")
	house.call("_apply_profile_for_where_the_player_is")
	assert_eq(rig.calls.size(), 1, "indoors after the fight: the interior profile is restored")
	assert_false((rig.calls[0][1] as Dictionary).is_empty())
	# Outdoors after a fight nothing changes: the default profile is right.
	house.inside = false
	house.call("_apply_profile_for_where_the_player_is")
	assert_eq(rig.calls.size(), 1, "outdoors the fight's default profile stands")
	world.free(); rig.free(); player.free(); ally.free()
