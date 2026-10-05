extends "res://tests/test_case.gd"

## Grandpa's spoken batch (Home Key + 50 Basic Orbs) is applied only once the
## key's owner-save CAS has released the owner record. While it is held the
## satchel refuses every add, so applying early would drop the orbs for good.
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")

class FakeDialogue extends CanvasLayer:
	var effects: Array[String] = []
	func drain_effects() -> Array[String]:
		var drained := effects.duplicate()
		effects.clear()
		return drained
	func close() -> void: pass

class FakeSession extends Node:
	var blocked := true
	var hosting := true
	func portal_runtime_ready() -> bool: return true
	func is_host() -> bool: return hosting
	func _altar_current_epoch() -> String: return "epoch"
	func _owner_training_mutation_blocked(_player: RefCounted) -> bool: return blocked

class Record extends RefCounted:
	var character_id := "character-gift"
	var reward_delivery_namespace := "world-gift"

class FakeGame extends Node:
	var items: RefCounted
	var inventory: RefCounted
	var session: Node
	var local: RefCounted = Record.new()
	var world: RefCounted = Record.new()
	var grants := 0
	func push_world_message(_message: String) -> void: pass
	func grant_home_key_from_opening(_source: Node) -> bool:
		grants += 1
		return true

class HarnessDirector extends "res://scripts/story/sequence_director.gd":
	var test_game: Node
	func _effect_game() -> Node: return test_game

var _bag: RefCounted
var _game: FakeGame
var _session: FakeSession
var _dialogue: FakeDialogue
var _director: HarnessDirector

func before_each() -> void:
	var db := ITEM_DB.new()
	_bag = INVENTORY.new(db)
	_session = FakeSession.new()
	_game = FakeGame.new()
	_game.items = db
	_game.inventory = _bag
	_game.session = _session
	_dialogue = FakeDialogue.new()
	_director = HarnessDirector.new()
	_director.test_game = _game
	_director._dialogue = _dialogue
	_director._f18_opening_conversation_id = "grandpa_first_catch"

func after_each() -> void:
	_director.free()
	_dialogue.free()
	_session.free()
	_game.free()

func _drain() -> void:
	_director._f18_home_key_retry_at = 0
	_director._drain_effects()

func test_orbs_wait_for_the_owner_record_then_land_once() -> void:
	_dialogue.effects = ["home_key:grant", "give:orb_basic:50"]
	_drain()
	assert_eq(_bag.count("orb_basic"), 0, "nothing is applied while the owner record is held")
	assert_eq(_director._f18_pending_effects, ["home_key:grant", "give:orb_basic:50"], "the spoken batch is retained")
	assert_true(_director.owns_input(), "input stays with the director while the gift settles")
	_drain()
	assert_eq(_bag.count("orb_basic"), 0)
	_session.blocked = false
	_drain()
	assert_eq(_bag.count("orb_basic"), 50, "the full gift lands once the owner record is free")
	assert_true(_director._f18_pending_effects.is_empty())
	assert_false(_director.owns_input())
	_drain()
	assert_eq(_bag.count("orb_basic"), 50, "the batch is applied exactly once")

func test_guest_retry_backs_off() -> void:
	_session.hosting = false
	_dialogue.effects = ["home_key:grant", "give:orb_basic:50"]
	var gaps: Array[int] = []
	for _i in 4:
		var before := Time.get_ticks_msec()
		_drain()
		gaps.append(_director._f18_home_key_retry_at - before)
	assert_true(gaps[0] <= 300 and gaps[1] >= 900 and gaps[2] >= 2900 and gaps[3] >= 2900,
		"guest retry backs off 250 ms / 1 s / 3 s: " + str(gaps))
