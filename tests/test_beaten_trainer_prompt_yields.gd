extends "res://tests/test_case.gd"

## F02 / earned-save blocker B1 (Cloudreach issue #229). The South Bridge
## guardian walks to the player at the gate (`south_bridge.gd::
## _challenge_the_guardian`, GRUNT_APPROACH_STOP 2.2 m) and is still standing
## there, beside the gate, when he loses. His prompt (4.2 m radius) then keeps
## publishing a priority-0 "Greet" offer that is NEARER than the gate's own
## 4.0 m prompt, so the arbiter hands Interact to a beaten, non-rechallengeable
## trainer and the gate the player just earned the key for never gets it.
##
## Built from the real pieces: `trainer_npc.gd`'s own relabel pass, two real
## `interactable.gd` prompts and `prompt_arbiter.gd`'s real choice. The unit
## runner has no SceneTree yet (see test_combat_realm_owned_begin.gd), so each
## offer is built from the prompt's own label/priority/actionable at the
## measured distance -- exactly what `interactable.gd::interaction_offer`
## returns once both are in range and in sight.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const INTERACTABLE := preload("res://scripts/world/interactable.gd")
const ARBITER := preload("res://scripts/world/prompt_arbiter.gd")

const GRUNT := "south_bridge_grunt"
const GATE_LABEL := "Try the bridge gate"


class Progression extends RefCounted:
	var flags: Dictionary = {}
	var revision := 0
	func has(flag: String) -> bool:
		return flags.has(flag)


## The two methods `_refresh_prompts()` reads off a placed trainer body.
class Body extends Node3D:
	var prompt: Node3D = null
	func prompt_node() -> Node3D:
		return prompt


var _root: Node3D


func before_each() -> void:
	_root = Node3D.new()


func after_each() -> void:
	if is_instance_valid(_root):
		_root.free()


## Player at the gate; the gate's prompt 2.8 m away, the guardian 2.2 m away.
func _stand_up() -> Dictionary:
	var placer: Node3D = TRAINERS.new()
	_root.add_child(placer)
	var body := Body.new()
	body.set_meta("trainer_id", GRUNT)
	placer.add_child(body)
	body.position = Vector3(2.2, 0.0, 0.0)
	var grunt_prompt: Node3D = INTERACTABLE.new()
	body.add_child(grunt_prompt)
	grunt_prompt.call("configure", "Challenge Tether Grunt", TRAINERS.PROMPT_RADIUS, true)
	body.prompt = grunt_prompt
	var gate: Node3D = INTERACTABLE.new()
	_root.add_child(gate)
	gate.position = Vector3(-2.8, 0.0, 0.0)
	gate.call("configure", GATE_LABEL, 4.0, true)
	return {"placer": placer, "grunt": grunt_prompt, "gate": gate}


## Called by name so this file still parses against a trainer_npc.gd that
## predates the rule (the failing-first run).
func _priority(spec: Dictionary, progression: RefCounted) -> int:
	return int((TRAINERS as GDScript).call("prompt_priority_for", spec, progression))


func _offer(prompt: Node3D, distance: float) -> Dictionary:
	if not bool(prompt.get("enabled")) or distance > float(prompt.get("radius")):
		return {}
	return ARBITER.offer(str(prompt.get("label")), distance,
		int(prompt.get("priority")), bool(prompt.get("actionable")))


func _winner(parts: Dictionary) -> Dictionary:
	return ARBITER.choose([_offer(parts.grunt, 2.2), _offer(parts.gate, 2.8)])


func test_beaten_south_bridge_guardian_does_not_outrank_the_gate() -> void:
	var spec := TRAINERS.trainer(GRUNT)
	assert_false(bool(spec.get("rechallenge", true)), "the guardian is a one-time fight")
	var parts := _stand_up()
	var progression := Progression.new()
	progression.flags[str(spec.defeat_flag)] = true
	(parts.placer as Node).call("_refresh_prompts", progression)
	var winner := _winner(parts)
	assert_eq(str(winner.get("label", "")), GATE_LABEL,
		"a beaten guardian standing beside the gate must not take Interact from it")
	assert_true(ARBITER.is_actionable(winner))
	# Walking away from the gate still leaves him greetable: the post-battle
	# line is kept, it just no longer outranks anything else.
	(parts.gate as Node3D).call("set_enabled", false)
	winner = _winner(parts)
	assert_eq(str(winner.get("label", "")), TRAINERS.prompt_for(spec, progression))


func test_unbeaten_guardian_keeps_ordinary_priority() -> void:
	var spec := TRAINERS.trainer(GRUNT)
	var parts := _stand_up()
	var progression := Progression.new()
	(parts.placer as Node).call("_refresh_prompts", progression)
	assert_eq(str(_winner(parts).get("label", "")), TRAINERS.prompt_for(spec, progression),
		"an open challenge is still decided by distance, exactly as before")
	assert_eq(_priority(spec, progression), 0)
	progression.flags[str(spec.defeat_flag)] = true
	assert_true(_priority(spec, progression) < 0)
	var again := spec.duplicate(true)
	again["rechallenge"] = true
	assert_eq(_priority(again, progression), 0,
		"a rechallengeable trainer's fight is still a real offer after a win")
