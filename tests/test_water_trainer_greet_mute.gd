extends "res://tests/test_case.gd"

## F14#1: a reused story NPC's Greet prompt is switched off during that
## trainer's own fight and back on when it ends. Other NPCs' prompts, and one
## already off, are left alone.

const INTERACTABLE := preload("res://scripts/world/interactable.gd")


class Director extends "res://scripts/combat/water_encounter_director.gd":
	var fighting_id := ""
	func trainer_battle_active() -> bool: return not fighting_id.is_empty()
	func trainer_battle_id() -> String: return fighting_id


class Body extends Node3D:
	var greeting: Node3D
	func prompt_node() -> Node3D: return greeting


func _body(enabled: bool) -> Body:
	var body := Body.new()
	body.greeting = INTERACTABLE.new()
	body.greeting.enabled = enabled
	body.add_child(body.greeting)
	return body


func test_own_fight_mutes_then_restores_the_greeting() -> void:
	var director := Director.new()
	var venn := _body(true)
	var other := _body(true)
	director.trainer_nodes = {"water_trainer_venn": venn, "water_trainer_odan": other}
	director.fighting_id = "water_trainer_venn"
	director.call("_mute_greeting_during_own_fight")
	assert_false(venn.greeting.enabled, "Venn's Greet is off during his fight")
	assert_true(other.greeting.enabled, "another trainer's Greet is untouched")
	director.call("_mute_greeting_during_own_fight")
	assert_false(venn.greeting.enabled, "stays off on later frames of the fight")
	director.fighting_id = ""
	director.call("_mute_greeting_during_own_fight")
	assert_true(venn.greeting.enabled, "restored when the fight ends")
	for node: Node in [director, venn, other]:
		node.free()


func test_a_greeting_already_off_is_not_switched_on() -> void:
	var director := Director.new()
	var venn := _body(false)
	director.trainer_nodes = {"water_trainer_venn": venn}
	director.fighting_id = "water_trainer_venn"
	director.call("_mute_greeting_during_own_fight")
	director.fighting_id = ""
	director.call("_mute_greeting_during_own_fight")
	assert_false(venn.greeting.enabled, "a prompt something else switched off stays off")
	for node: Node in [director, venn]:
		node.free()
