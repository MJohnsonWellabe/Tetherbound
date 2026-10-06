extends "res://tests/test_case.gd"

## F01#6a x F18: a guest's dialogue gifts are host-delivered reward_grants
## claimed under the conversation that spoke them. Grandpa's first-catch batch
## is held behind his Home Key (sequence_director._drain_effects) and applied
## after the dialogue box has closed, when the runner names no conversation;
## the claim must still name grandpa_first_catch, never be dropped.
const ITEM_DB := preload("res://autoload/item_db.gd")
const INVENTORY := preload("res://autoload/inventory.gd")
const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")

class Runner extends RefCounted:
	var id := "grandpa_first_catch"
	func conversation_id() -> String: return id

class FakeDialogue extends CanvasLayer:
	var effects: Array[String] = []
	var open_runner: RefCounted = Runner.new()
	func drain_effects() -> Array[String]:
		var drained := effects.duplicate()
		effects.clear()
		return drained
	func runner() -> RefCounted: return open_runner
	func close() -> void: open_runner = null

class FakeSession extends Node:
	var blocked := false
	func local_peer_id() -> int: return 2
	func arm_legacy_home_key_check(_peer: int) -> void: pass
	func portal_runtime_ready() -> bool: return true
	func is_host() -> bool: return false
	func is_multi_peer() -> bool: return true
	func client_character_save_ready() -> bool: return true
	func _altar_current_epoch() -> String: return "epoch"
	func _owner_training_mutation_blocked(_player: RefCounted) -> bool: return blocked

class Record extends RefCounted:
	var character_id := "character-guest"
	var reward_delivery_namespace := "world-gift"

class FakeGame extends Node:
	var items: RefCounted
	var inventory: RefCounted
	var session: Node
	var local: RefCounted = Record.new()
	var world: RefCounted = Record.new()
	var current_realm := "meadows"
	var grant_result := false
	func push_world_message(_message: String) -> void: pass
	func grant_home_key_from_opening(_source: Node) -> bool: return grant_result

class HarnessDirector extends "res://scripts/story/sequence_director.gd":
	var test_game: Node
	var claims: Array[Dictionary] = []
	func _effect_game() -> Node: return test_game
	func _submit_gift_claim(intent: Dictionary) -> void: claims.append(intent.duplicate(true))

var _game: FakeGame
var _session: FakeSession
var _dialogue: FakeDialogue
var _director: HarnessDirector

func before_each() -> void:
	var db := ITEM_DB.new()
	_session = FakeSession.new()
	_game = FakeGame.new()
	_game.items = db
	_game.inventory = INVENTORY.new(db)
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

func test_a_held_gift_is_claimed_under_its_conversation_after_the_box_closed() -> void:
	_dialogue.effects = ["home_key:grant", "give:orb_basic:50"] as Array[String]
	_drain()
	assert_true(_director.claims.is_empty(), "held behind the Home Key: nothing claimed yet")
	_dialogue.close() # the player dismissed Grandpa while the key settled
	_game.grant_result = true
	_drain()
	assert_eq(_director.claims.size(), 1, "the gift is claimed once the key settles")
	if _director.claims.size() == 1:
		assert_eq(str(_director.claims[0].get("source")),
			WORLD_LEDGER.dialogue_give_source("grandpa_first_catch", "orb_basic"),
			"under the conversation that spoke it")
		assert_eq(int(_director.claims[0].get("count")), 50)
	assert_eq(int(_game.inventory.call("count", "orb_basic")), 0, "a guest never adds its own gift")

func test_an_open_conversation_still_names_itself() -> void:
	_game.grant_result = true
	_dialogue.effects = ["give:orb_basic:50"] as Array[String]
	_drain()
	assert_eq(_director.claims.size(), 1)
	if _director.claims.size() == 1:
		assert_eq(str(_director.claims[0].get("source")),
			WORLD_LEDGER.dialogue_give_source("grandpa_first_catch", "orb_basic"))

func test_a_conversation_spoken_while_one_is_held_keeps_its_own_name() -> void:
	_dialogue.effects = ["home_key:grant", "give:orb_basic:50"] as Array[String]
	_drain()
	_dialogue.close()
	# The player walks off and another villager hands something over while
	# Grandpa's batch still waits on the key.
	var smith := Runner.new()
	smith.id = "tam_tools"
	_dialogue.open_runner = smith
	_dialogue.effects = ["give:potion_small:1"] as Array[String]
	_drain()
	assert_true(_director.claims.is_empty(), "neither batch is claimed while the first is held")
	_dialogue.close()
	_game.grant_result = true
	_drain()
	assert_eq(_director.claims.size(), 1, "the held batch applies alone")
	_drain()
	assert_eq(_director.claims.size(), 2, "then the batch spoken behind it")
	if _director.claims.size() == 2:
		assert_eq(str(_director.claims[0].get("source")),
			WORLD_LEDGER.dialogue_give_source("grandpa_first_catch", "orb_basic"),
			"Grandpa's gift is claimed under Grandpa")
		assert_eq(str(_director.claims[1].get("source")),
			WORLD_LEDGER.dialogue_give_source("tam_tools", "potion_small"),
			"the later gift is claimed under the conversation that spoke it")

func test_the_played_shape_key_first_then_gifts_on_later_lines() -> void:
	# opening.json: the key is spoken on line 0, the gifts on later lines, and
	# the box closes before the key settles.
	_dialogue.effects = ["home_key:grant"] as Array[String]
	_drain()
	_dialogue.effects = ["give:orb_basic:50"] as Array[String]
	_drain()
	_dialogue.effects = ["give:potion_small:3"] as Array[String]
	_drain()
	assert_true(_director.claims.is_empty(), "nothing is claimed while the key is held")
	_dialogue.close()
	_game.grant_result = true
	for frame in 4: _drain()
	assert_eq(_director.claims.size(), 2, "both gifts are claimed once the key settles")
	for claim: Dictionary in _director.claims:
		assert_true(str(claim.get("source")).begins_with("dialogue_give:grandpa_first_catch:"),
			"each under Grandpa's conversation (%s)" % str(claim.get("source")))

func test_a_batch_drained_with_no_conversation_is_not_claimed_under_another() -> void:
	_dialogue.effects = ["home_key:grant"] as Array[String]
	_drain()
	_dialogue.close() # a confirmation line closes its runner before the drain
	_dialogue.effects = ["give:orb_basic:50"] as Array[String]
	_drain()
	var later := Runner.new()
	later.id = "nessa_berries"
	_dialogue.open_runner = later
	_game.grant_result = true
	for frame in 3: _drain()
	assert_true(_director.claims.is_empty(), "an unnamed gift is never claimed under whichever conversation is open")
