extends "res://tests/test_case.gd"

const DIRECTOR := preload("res://scripts/story/sequence_director.gd")
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")

const GEAR := "mill_bridge_gear"
const RESCUE := "captive_rescued"
const MAKE_ROOM := "Make room in your satchel, then speak again."


class FakeDialogue extends CanvasLayer:
	var effects: Array[String] = []
	var closed := false

	func drain_effects() -> Array[String]:
		var drained := effects.duplicate()
		effects.clear()
		return drained

	func close() -> void:
		closed = true


class FakeGame extends Node:
	var items: RefCounted
	var inventory: RefCounted
	var messages: Array[String] = []

	func push_world_message(message: String) -> void:
		messages.append(message)


class HarnessDirector extends "res://scripts/story/sequence_director.gd":
	var test_game: Node
	var written_flags: Array[String] = []

	func _effect_game() -> Node:
		return test_game

	func _set_progression_flag(flag_id: String) -> void:
		written_flags.append(flag_id)


var _db: RefCounted
var _bag: RefCounted
var _game: FakeGame
var _dialogue: FakeDialogue
var _director: HarnessDirector


func before_each() -> void:
	_db = ITEM_DB.new()
	_bag = INVENTORY.new(_db)
	_game = FakeGame.new()
	_game.items = _db
	_game.inventory = _bag
	_dialogue = FakeDialogue.new()
	_director = HarnessDirector.new()
	_director.test_game = _game
	_director._dialogue = _dialogue


func after_each() -> void:
	_director.free()
	_dialogue.free()
	_game.free()


func test_full_bag_keeps_selas_gear_and_rescue_available_for_retry() -> void:
	_fill_every_slot()
	_drain(["give:%s:1" % GEAR, "flag:%s" % RESCUE])
	assert_eq(_bag.count(GEAR), 0, "the rejected handoff grants no gear")
	assert_false(_director.written_flags.has(RESCUE), "the rescue fact waits for the physical handoff")
	assert_true(_dialogue.closed, "the failed line closes so Sela can be spoken to again")
	assert_eq(_game.messages, [MAKE_ROOM])

	_bag.set_slot(23, null)
	_dialogue.closed = false
	_drain(["give:%s:1" % GEAR, "flag:%s" % RESCUE])
	assert_eq(_bag.count(GEAR), 1, "retry adds exactly one gear into the recovered slot")
	assert_eq(_director.written_flags.count(RESCUE), 1, "retry commits the rescue exactly once")
	assert_false(_dialogue.closed, "a successful handoff leaves normal dialogue flow alone")


func test_two_gifts_competing_for_one_slot_apply_nothing() -> void:
	_fill_every_slot()
	_bag.set_slot(23, null)
	_drain(["give:%s:1" % GEAR, "give:heartstone:1", "flag:%s" % RESCUE])
	assert_eq(_bag.count(GEAR), 0, "the first gift is not applied when the second cannot fit")
	assert_eq(_bag.count("heartstone"), 0)
	assert_false(_director.written_flags.has(RESCUE))


func test_an_existing_stack_with_room_accepts_the_batch() -> void:
	_fill_every_slot()
	var maximum := int(_db.call("stack_size", "wood"))
	_bag.set_slot(0, {"id": "wood", "n": maximum - 1})
	_drain(["give:wood:1", "flag:%s" % RESCUE])
	assert_eq(_bag.count("wood"), maximum)
	assert_true(_director.written_flags.has(RESCUE))
	assert_false(_dialogue.closed)


func test_failed_gift_blocks_a_flag_that_precedes_it_in_the_batch() -> void:
	_fill_every_slot()
	_drain(["flag:%s" % RESCUE, "give:heartstone:1"])
	assert_false(_director.written_flags.has(RESCUE), "preflight happens before effect ordering begins")
	assert_eq(_bag.count("heartstone"), 0)


func test_invalid_gifts_block_the_batch_before_any_flag_is_written() -> void:
	for gift: String in ["give:heartstone", "give:no_such_item:1", "give:heartstone:0"]:
		_director.written_flags.clear()
		_dialogue.closed = false
		_drain(["flag:%s" % RESCUE, gift])
		assert_false(_director.written_flags.has(RESCUE), "%s must reject the whole batch" % gift)
		assert_true(_dialogue.closed, "%s must close the failed conversation" % gift)


func _drain(effects: Array[String]) -> void:
	_dialogue.effects = effects.duplicate()
	_director._drain_effects()


func _fill_every_slot() -> void:
	for index in _bag.slot_count():
		_bag.set_slot(index, {"id": "axe", "n": 1})
