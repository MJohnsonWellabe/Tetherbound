extends Node

## SYNTHETIC owner facade for the isolated credits disk/UI smoke only.
## The real Game autoload remains alive; all containers and writes belong to it.
## This fixture supplies missing ending APIs, never earned finale/Home Key proof.
const HOMECOMING := preload("res://scripts/story/regional_homecoming.gd")
const OWNER := preload("res://tests/fixtures/regional_ending_owner.gd")

var real_game: Node = null
var delegate: RefCounted = OWNER.new()
var pending_intent: Dictionary = {}
var receipt_overrides: Dictionary = {}
var reject_write := false
var writes := 0
var polls := 0


static func return_marker(character_id: String) -> String:
	# Existing player-scoped opening prefix; NOT a production Home Key receipt.
	return "opening:synthetic_f20_home_return:" + character_id


func bind(game: Node) -> void:
	real_game = game
	delegate.starter_uid = str(game.get("party").members()[0].uid)
	delegate.home_return_receipt = return_marker(HOMECOMING.character_id(game))


func _get(property: StringName) -> Variant:
	return real_game.get(property) if is_instance_valid(real_game) else null


func menu() -> CanvasLayer:
	return real_game.call("menu") as CanvasLayer


## Persistent transport polls and UI readers still ask /root/Game while this
## facade is mounted. Keep those answers on the actual autoload/session.
func is_host() -> bool:
	return bool(real_game.call("is_host"))


func is_multi_peer() -> bool:
	return bool(real_game.call("is_multi_peer"))


func find_player() -> Node3D:
	return real_game.call("find_player") as Node3D


func _find_player() -> Node3D:
	return real_game.call("_find_player") as Node3D


func last_input_was_gamepad() -> bool:
	return bool(real_game.call("last_input_was_gamepad"))


func regional_ending_context() -> Dictionary:
	delegate.local = real_game.get("local")
	delegate.world = real_game.get("world")
	delegate.party = real_game.get("party")
	delegate.accepted_outcome = delegate.local.flags.has(delegate.home_return_receipt)
	return delegate.regional_ending_context()


func commit_regional_ending_ack(intent: Dictionary) -> Dictionary:
	if not _intent_is_current(intent):
		return {"status": "rejected", "durable": false}
	pending_intent = intent.duplicate(true)
	return {"status": "pending"}


func regional_ending_ack_result(transaction_id: String) -> Dictionary:
	polls += 1
	var intent := pending_intent.duplicate(true)
	pending_intent.clear()
	if transaction_id != intent.get("transaction_id") or not _intent_is_current(intent):
		return {"status": "rejected", "durable": false}
	var receipt := intent.duplicate(true)
	receipt.merge({"status": "committed", "durable": true})
	receipt.merge(receipt_overrides, true)
	# Fault injection cannot claim durability or mutate the real character.
	if reject_write or not HOMECOMING.receipt_matches(receipt, intent):
		return {"status": "rejected", "durable": false} if reject_write else receipt
	var local: RefCounted = real_game.get("local")
	var stage := str(intent.stage)
	var was_seen: bool = local.flags.has(stage)
	local.flags.set_flag(stage)
	writes += 1
	# Freeze the personal stage BEFORE the actual split character writer.
	# Return committed only after that writer succeeds; restore on failure.
	if not bool(real_game.get("save_system").call("save_character", real_game, local.character_id)):
		local.flags.set_flag(stage, was_seen)
		return {"status": "rejected", "durable": false}
	return receipt


func _intent_is_current(intent: Dictionary) -> bool:
	var stage := str(intent.get("stage", ""))
	var expected := HOMECOMING.acknowledgement_intent(HOMECOMING.context(self), stage)
	return not expected.is_empty() and intent == expected \
		and (stage != HOMECOMING.CREDITS_SEEN_FLAG or HOMECOMING.credits_available(self))


func push_world_message(message: String) -> void:
	real_game.call("push_world_message", message)
