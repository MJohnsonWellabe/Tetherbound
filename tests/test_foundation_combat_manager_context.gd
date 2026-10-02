extends "res://tests/test_case.gd"

## Actual production manager scripts and their inherited state predicate.
## Detached world ownership is disclosed; this does not claim a played route.
const SESSION := preload("res://scripts/net/session.gd")
const BASE := preload("res://scripts/combat/combat_manager.gd")
const CLOUD := preload("res://scripts/combat/cloudreach_combat_manager.gd")
const STORM := preload("res://scripts/combat/stormwood_combat_manager.gd")

class MethodOnlyManager extends Node:
	func is_fighting() -> bool: return false

func test_each_production_manager_allows_idle_and_refuses_active_or_resolving() -> void:
	for script: Script in [BASE, CLOUD, STORM]:
		var world := Node.new()
		var manager: Node = script.new()
		world.add_child(manager)
		assert_false(SESSION._foundation_local_manager_in_combat(world), script.resource_path + " idle")
		manager.set("state", BASE.State.ACTIVE)
		assert_true(SESSION._foundation_local_manager_in_combat(world), script.resource_path + " active")
		manager.set("state", BASE.State.RESOLVING)
		assert_true(SESSION._foundation_local_manager_in_combat(world), script.resource_path + " resolving")
		manager.set("state", BASE.State.INACTIVE)
		assert_false(SESSION._foundation_local_manager_in_combat(world), script.resource_path + " returned idle")
		world.free()

func test_missing_or_method_only_manager_cannot_authorize_local_action() -> void:
	assert_true(SESSION._foundation_local_manager_in_combat(null))
	var world := Node.new()
	assert_true(SESSION._foundation_local_manager_in_combat(world))
	world.add_child(MethodOnlyManager.new())
	assert_true(SESSION._foundation_local_manager_in_combat(world), "method presence is not production ownership")
	world.free()

func test_hosted_sibling_manager_cannot_answer_for_local_owner() -> void:
	var local_world := Node.new()
	var hosted_world := Node.new()
	var hosted_manager := STORM.new()
	hosted_world.add_child(hosted_manager)
	assert_false(SESSION._foundation_local_manager_in_combat(hosted_world))
	assert_true(SESSION._foundation_local_manager_in_combat(local_world), "another realm's idle manager cannot replace the owner")
	var local_manager := CLOUD.new()
	local_world.add_child(local_manager)
	local_manager.state = BASE.State.ACTIVE
	assert_true(SESSION._foundation_local_manager_in_combat(local_world))
	local_manager.state = BASE.State.INACTIVE
	hosted_manager.state = BASE.State.ACTIVE
	assert_false(SESSION._foundation_local_manager_in_combat(local_world), "unrelated remote fight does not change local manager state")
	assert_true(SESSION._foundation_local_manager_in_combat(hosted_world))
	local_world.free()
	hosted_world.free()
