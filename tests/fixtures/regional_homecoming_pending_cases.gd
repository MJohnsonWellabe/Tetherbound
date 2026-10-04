extends "res://tests/test_case.gd"

## Required by smoke_regional_homecoming_pending.gd after the real SceneTree
## starts. These synthetic owner cases prove frame/receipt rejection behavior,
## not an earned finale, disk receipt or multiplayer acceptance.
const HOMECOMING := preload("res://scripts/story/regional_homecoming.gd")
const OWNER := preload("res://tests/fixtures/regional_ending_owner.gd")

class PendingOwner:
	extends Node
	var delegate: RefCounted = OWNER.new()
	var local: RefCounted:
		get: return delegate.local
	var party: RefCounted:
		get: return delegate.party
	var pending_intent: Dictionary = {}
	var polls := 0
	var change_session_on_poll := false

	func regional_ending_context() -> Dictionary:
		return delegate.regional_ending_context()

	func commit_regional_ending_ack(intent: Dictionary) -> Dictionary:
		pending_intent = intent.duplicate(true)
		return {"status": "pending"}

	func regional_ending_ack_result(_id: String) -> Dictionary:
		polls += 1
		if change_session_on_poll:
			delegate.session_epoch = "reconnected"
			return {"status": "rejected"}
		return delegate.commit_regional_ending_ack(pending_intent)

	func push_world_message(message: String) -> void:
		delegate.push_world_message(message)

var _nodes: Array[Node] = []
var completed_cases := {
	"test_pending_owner_acknowledgement_waits_for_receipt": false,
	"test_pending_owner_result_cannot_cross_reconnect_generation": false,
}


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _attach_pending_owner() -> PendingOwner:
	var tree := Engine.get_main_loop() as SceneTree
	assert_true(tree != null, "pending acknowledgement requires the started SceneTree")
	if tree == null:
		return null
	var game := PendingOwner.new()
	_nodes.append(game)
	game.delegate.accepted_outcome = true
	game.delegate.world.flags.set_flag(HOMECOMING.WORLD_FLAG)
	tree.root.add_child(game)
	return game


func test_pending_owner_acknowledgement_waits_for_receipt() -> void:
	var game := _attach_pending_owner()
	if game == null:
		return
	var frozen := HOMECOMING.context(game)
	assert_true(await HOMECOMING.complete(game, game.local.character_id, frozen))
	assert_eq(game.polls, 1)
	assert_eq(game.delegate.save_system.calls, 1)
	assert_true(game.local.flags.has(HOMECOMING.SEEN_FLAG))
	completed_cases["test_pending_owner_acknowledgement_waits_for_receipt"] = true


func test_pending_owner_result_cannot_cross_reconnect_generation() -> void:
	var game := _attach_pending_owner()
	if game == null:
		return
	game.change_session_on_poll = true
	var frozen := HOMECOMING.context(game)
	assert_false(await HOMECOMING.complete(game, game.local.character_id, frozen))
	assert_eq(game.delegate.save_system.calls, 0)
	assert_false(game.local.flags.has(HOMECOMING.SEEN_FLAG))
	completed_cases["test_pending_owner_result_cannot_cross_reconnect_generation"] = true
