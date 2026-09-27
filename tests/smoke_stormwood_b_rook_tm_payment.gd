extends SceneTree

## F10#0 (WORLD: "one authored Electric TM reward through existing
## entitlement/receipt"): Rook's circuit payment on the engine path, not a
## stub. The production Game autoload, its world ledger and save system, and
## the real `RookCircuitReward` node mounted in a world:
##   - finishing Rook's return conversation claims through LEDGER_CLAIM ->
##     world_ledger `reward_grant` -> this character's inventory and the
##     world's delivery journal, and announces the payment once;
##   - Rook's thanks afterwards pays nothing again (once per character);
##   - after an ordinary save_game / load_game the TM and its receipt are
##     still there, and asking Rook again still pays nothing.
## DISCLOSED SHORTCUTS (owner ruling 2026-09-27): the circuit's own flags
## (offer accepted, three wins, completion) are set through the ledger instead
## of played; the chapter is a stub that records Rook's story events.

const REWARD := preload("res://scripts/world/stormwood_rook_circuit_reward.gd")
const GAME := preload("res://autoload/game_state.gd")
const SAVE_GAME := preload("res://scripts/save/save_game.gd")
const SLOT := 1
const TM := "tm_thunder_break"

var _failures: Array[String] = []


class ChapterStub extends Node:
	var events: Array[String] = []
	func emit_event(event: String) -> Dictionary:
		events.append(event)
		return {"accepted": true}


func _init() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String) -> void:
	print("ROOK TM CHECK %s: %s" % ["PASS" if ok else "FAIL", label])
	if not ok:
		_failures.append(label)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	var game := root.get_node_or_null(^"Game")
	if game == null:
		game = GAME.new()
		game.name = "Game"
		root.add_child(game)
	game.set("save_system", SAVE_GAME.new("user://stormwood_b_rook_tm_%d" % OS.get_process_id()))
	await process_frame
	game.call("reset_for_new_game")
	game.get("local").set("character_id", "rook-tm-host")
	game.get("world").set("world_id", "rook-tm-world")
	game.set("current_realm", "stormwood")
	for flag: String in ["stormwood:side_deepwood_circuit_1", REWARD.STEP_2, REWARD.COMPLETE]:
		game.get("ledger").call("submit", {"kind": "set_world_flag", "realm": "stormwood", "id": flag, "value": true})
	var world := Node3D.new()
	world.name = "StormwoodStub"
	root.add_child(world)
	var chapter := ChapterStub.new()
	world.add_child(chapter)
	var reward: Node = REWARD.new()
	chapter.add_child(reward)
	reward.call("mount", world)
	await _frames(3)
	var inventory: RefCounted = game.get("inventory")
	_check(int(inventory.call("count", TM)) == 0, "no TM before Rook's return")

	_check(bool(reward.call("dialogue_finished", REWARD.RETURN, chapter)), "Rook's return belongs to the reward node")
	_check(chapter.events == ["side:stormwood_deepwood_circuit:step_3"], "the return completes the chain story step (%s)" % str(chapter.events))
	await _frames(10)
	_check(int(inventory.call("count", TM)) == 1, "the return pays exactly one TM: Thunder Break (%d)" % int(inventory.call("count", TM)))
	_check(REWARD.paid_in_world(game.get("world"), "rook-tm-host"), "the world's delivery journal holds this character's receipt")
	_check(str(game.call("take_pending_world_message")) == REWARD.PAID_MESSAGE, "the payment is announced once")

	chapter.events.clear()
	_check(bool(reward.call("dialogue_finished", REWARD.THANKS, chapter)), "Rook's thanks belongs to the reward node")
	await _frames(10)
	_check(chapter.events.is_empty(), "the thanks never re-completes the chain")
	_check(int(inventory.call("count", TM)) == 1, "the thanks pays nothing more (%d)" % int(inventory.call("count", TM)))
	_check(str(game.call("take_pending_world_message")).is_empty(), "and announces nothing")
	_check(bool(game.call("player_flags").call("has", REWARD.RECEIVED_FLAG)), "Rook moves on for this character (greeting preference)")

	_check(bool(game.call("save_game", SLOT)), "ordinary save_game")
	inventory.call("remove", TM, int(inventory.call("count", TM)))
	_check(bool(game.call("load_game", SLOT)), "ordinary load_game")
	await _frames(10)
	inventory = game.get("inventory")
	_check(int(inventory.call("count", TM)) == 1, "the TM survives save/reload (%d)" % int(inventory.call("count", TM)))
	_check(REWARD.paid_in_world(game.get("world"), "rook-tm-host"), "and so does its receipt")
	reward.call("claim_reward")
	await _frames(10)
	_check(int(inventory.call("count", TM)) == 1, "asking Rook again after reload still pays nothing (%d)" % int(inventory.call("count", TM)))

	print("ROOK TM PAYMENT %s" % ("PASS" if _failures.is_empty() else "FAIL %s" % str(_failures)))
	quit(0 if _failures.is_empty() else 1)
