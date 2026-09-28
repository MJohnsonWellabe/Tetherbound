extends "res://tests/test_case.gd"

## F04#1/#2 (judge r4 7121d40c): every captain's wind-up read the same
## "! incoming — move", and Vess's DIVER looked like Halder's CHARGER. The
## wind-up now names the question from the creature's own authored attack.

const MANAGER := preload("res://scripts/combat/combat_manager.gd")


class WindingUp:
	extends Node3D
	var cfg := {}
	var combat_override := {}
	func is_winding_up() -> bool:
		return true
	func combat_config() -> Dictionary:
		return cfg


func _shape(cfg: Dictionary, authored: Dictionary = {}) -> String:
	var manager := MANAGER.new()
	var wild := WindingUp.new()
	wild.cfg = cfg
	wild.combat_override = authored
	manager.set("_wild", wild)
	var shape := str(manager.call("enemy_windup_shape"))
	wild.free()
	manager.free()
	return shape


func test_a_travelling_lunge_is_a_charge_and_a_far_reposition_makes_it_a_dive() -> void:
	# Halder's and Vance's Tuskroot, Vess's Galecrest, as authored in band data.
	var tuskroot := {"lunge": 7.0, "lunge_travels": true, "preferred_range": 4.5}
	var galecrest := {"lunge": 5.5, "lunge_travels": true, "reposition_distance": 7.0}
	assert_eq(_shape(tuskroot, tuskroot), "charge")
	assert_eq(_shape(galecrest, galecrest), "dive")
	# Render 5e8c3de3: the merged config carries the species' base movement,
	# which read a Tuskroot CHARGER as a dive. Only the authored shape counts.
	var merged := tuskroot.duplicate()
	merged["reposition_distance"] = 6.0
	assert_eq(_shape(merged, tuskroot), "charge", "a species' base reposition is not a DIVER")
	assert_eq(_shape({"lunge": 6.5, "cone_degrees": 72}), "", "the Warden's HEAVY does not travel")
	assert_eq(_shape({"telegraph": 0.9}), "", "a baseline slot has no named question")


func test_the_words_are_config_and_name_what_to_do() -> void:
	var tell := preload("res://scripts/combat/combat_math.gd").config()["telegraph"] as Dictionary
	assert_true(str(tell["charge_text"]).contains("lane"), "a charge says leave the lane")
	assert_true(str(tell["dive_text"]).contains("line"), "a dive says leave its line")
	assert_ne(tell["charge_text"], tell["dive_text"], "the two read apart")
