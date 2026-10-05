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
	var epoch := "epoch"
	func portal_runtime_ready() -> bool: return true
	func is_host() -> bool: return hosting
	func _altar_current_epoch() -> String: return epoch
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
	var grant_result := true
	func push_world_message(_message: String) -> void: pass
	func grant_home_key_from_opening(_source: Node) -> bool:
		grants += 1
		return grant_result

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


func test_guest_gift_lost_to_an_epoch_change_releases_input_and_keeps_the_orbs() -> void:
	_session.hosting = false
	_session.blocked = false
	_game.grant_result = false # The host refused silently / the reply never came.
	_dialogue.effects = ["home_key:grant", "give:orb_basic:50"]
	_drain()
	assert_true(_director.owns_input(), "Grandpa holds input while the gift is in flight")
	assert_eq(_bag.count("orb_basic"), 0)
	_session.epoch = "reconnected-epoch"
	_drain()
	assert_false(_director.owns_input(), "a changed session epoch releases the player")
	assert_false(_director._f18_pending_effects.has("home_key:grant"), "the stale key request is dropped")
	assert_eq(_bag.count("orb_basic"), 50, "the spoken orbs still land")
	var requests := _game.grants
	_drain()
	assert_eq(_game.grants, requests, "no further key requests after the exit")


func test_unsettled_gift_gives_up_after_the_bound() -> void:
	_session.blocked = false
	_game.grant_result = false
	_dialogue.effects = ["home_key:grant", "give:orb_basic:50"]
	_drain()
	assert_true(_director.owns_input())
	_director._f18_home_key_started_at = Time.get_ticks_msec() - _director.F18_HOME_KEY_GIVE_UP_MS - 1
	_drain()
	assert_false(_director.owns_input(), "the bounded exit restores input")
	assert_eq(_bag.count("orb_basic"), 50)


func test_released_gift_still_waits_for_a_held_owner_record_without_holding_input() -> void:
	_session.blocked = true
	_game.grant_result = false
	_dialogue.effects = ["home_key:grant", "give:orb_basic:50"]
	_drain()
	_director._f18_home_key_started_at = Time.get_ticks_msec() - _director.F18_HOME_KEY_GIVE_UP_MS - 1
	_drain()
	assert_false(_director.owns_input())
	assert_eq(_bag.count("orb_basic"), 0, "a held record would refuse the orbs; they wait")
	_session.blocked = false
	_drain()
	assert_eq(_bag.count("orb_basic"), 50)


func test_guest_beat_comes_from_its_own_opening_history() -> void:
	var opening := preload("res://scripts/net/opening_home_key.gd")
	assert_eq(opening.peer_beat({}), "")
	assert_eq(opening.peer_beat({"opening:beat:wake": true, "opening:beat:house": true, "opening:beat:choose": true,
		"opening:beat:name": true, "opening:beat:return_starter": true}), "return_starter")
	assert_eq(opening.peer_beat({"opening:beat:return_starter": true, "opening:beat:walk_out": true}), "walk_out")
