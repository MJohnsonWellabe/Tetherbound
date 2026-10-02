extends "res://tests/test_case.gd"

## Detached real-script ownership controls, not live SceneTree index,
## actual combat/refusal/input, portal save/ACK or heartbeat timing proof.
const SESSION := preload("res://scripts/net/session.gd")
const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")

class MethodLookalike extends Node:
	var _session: Node
	func trainer_battle_active() -> bool: return false
	func encounter_record(_id: String) -> Dictionary: return {}

func test_actual_director_binding_tracks_current_world_owner_and_reparenting() -> void:
	var world := Node3D.new()
	var replacement_world := Node3D.new()
	var owner := Node.new()
	var foreign_owner := Node.new()
	var director: Node = DIRECTOR.new()
	director.set("_session", owner)
	world.add_child(director)
	assert_true(SESSION._portal_director_owned_by(world, owner, director))
	assert_false(SESSION._portal_director_owned_by(replacement_world, owner, director))
	assert_false(SESSION._portal_director_owned_by(world, foreign_owner, director))
	world.remove_child(director)
	replacement_world.add_child(director)
	assert_false(SESSION._portal_director_owned_by(world, owner, director))
	assert_true(SESSION._portal_director_owned_by(replacement_world, owner, director))
	director.set("_session", foreign_owner)
	assert_false(SESSION._portal_director_owned_by(replacement_world, owner, director))
	var retained := weakref(director)
	director.free()
	assert_false(SESSION._portal_director_owned_by(replacement_world, owner, retained.get_ref()))
	world.free()
	replacement_world.free()
	owner.free()
	foreign_owner.free()

func test_group_membership_or_method_names_cannot_substitute_for_actual_script_ownership() -> void:
	var world := Node3D.new()
	var owner := Node.new()
	var lookalike: Node = MethodLookalike.new()
	lookalike.set("_session", owner)
	lookalike.add_to_group(&"foundation_portal_directors")
	world.add_child(lookalike)
	assert_false(SESSION._portal_director_owned_by(world, owner, lookalike))
	assert_false(SESSION._portal_director_owned_by(world, owner, null))
	assert_false(SESSION._portal_director_owned_by(null, owner, lookalike))
	world.free()
	owner.free()
