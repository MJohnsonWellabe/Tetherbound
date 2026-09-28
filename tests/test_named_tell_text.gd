extends "res://tests/test_case.gd"

## F04#1/#2 (judge r4 7121d40c): every captain's wind-up read the same
## "! incoming — move", and Vess's DIVER looked like Halder's CHARGER. The
## wind-up now names the question from the creature's own authored attack.

const MANAGER := preload("res://scripts/combat/combat_manager.gd")


class WindingUp:
	extends Node3D
	var cfg := {}
	func is_winding_up() -> bool:
		return true
	func combat_config() -> Dictionary:
		return cfg


func _shape(cfg: Dictionary) -> String:
	var manager := MANAGER.new()
	var wild := WindingUp.new()
	wild.cfg = cfg
	manager.set("_wild", wild)
	var shape := str(manager.call("enemy_windup_shape"))
	wild.free()
	manager.free()
	return shape


func test_a_travelling_lunge_is_a_charge_and_a_far_reposition_makes_it_a_dive() -> void:
	# Halder's and Vance's Tuskroot, Vess's Galecrest, as authored in band data.
	assert_eq(_shape({"lunge": 7.0, "lunge_travels": true, "preferred_range": 4.5}), "charge")
	assert_eq(_shape({"lunge": 5.5, "lunge_travels": true, "reposition_distance": 7.0}), "dive")
	assert_eq(_shape({"lunge": 6.5, "cone_degrees": 72}), "", "the Warden's HEAVY does not travel")
	assert_eq(_shape({"telegraph": 0.9}), "", "a baseline slot has no named question")


func test_the_words_are_config_and_name_what_to_do() -> void:
	var tell := preload("res://scripts/combat/combat_math.gd").config()["telegraph"] as Dictionary
	assert_true(str(tell["charge_text"]).contains("lane"), "a charge says leave the lane")
	assert_true(str(tell["dive_text"]).contains("line"), "a dive says leave its line")
	assert_ne(tell["charge_text"], tell["dive_text"], "the two read apart")
