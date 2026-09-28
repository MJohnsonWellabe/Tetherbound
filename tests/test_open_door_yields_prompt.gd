extends "res://tests/test_case.gd"

## F01#2 (village walk day r2): an open house door's "Close Door" yields to any
## other prompt in reach (Mira's greeting at her counter), and is still offered
## when nothing else is.

const VILLAGE_DOOR := preload("res://scripts/world/village_door.gd")
const ARBITER := preload("res://scripts/world/prompt_arbiter.gd")


func test_open_door_prompt_sits_below_ordinary_prompts() -> void:
	var holder := Node3D.new()
	var leaf := Node3D.new()
	holder.add_child(leaf)
	var door: Node3D = VILLAGE_DOOR.new()
	holder.add_child(door)
	door.call("setup", leaf, Vector3.ZERO, "Door")
	var prompt := door.get_node("Prompt")
	assert_eq(int(prompt.get("priority")), 0, "a shut door's Open prompt is ordinary")
	door.call("_on_activated")
	assert_eq(str(prompt.get("label")), "Close Door")
	assert_true(int(prompt.get("priority")) < 0, "an open door's Close prompt yields")
	var close := ARBITER.offer("Close Door", 2.0, int(prompt.get("priority")))
	var greet := ARBITER.offer("Greet Mira", 2.7, 0)
	assert_eq(str(ARBITER.choose([close, greet]).get("label", "")), "Greet Mira",
		"a nearer open door does not beat a greeting in reach")
	assert_eq(str(ARBITER.choose([close]).get("label", "")), "Close Door",
		"alone, the open door is still offered")
	door.call("_on_activated")
	assert_eq(int(prompt.get("priority")), 0, "shut again, it is ordinary again")
	holder.free()
