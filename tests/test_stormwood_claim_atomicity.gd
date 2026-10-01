extends "res://tests/test_case.gd"

## Actual world ledger and ending decision path with bool-writer/publication
## doubles. This covers ordering/rollback only, not a physical earned finale.
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const ENDING := preload("res://scripts/world/stormwood_ending.gd")

class SessionFixture extends Node:
	func is_host() -> bool: return true
	func _altar_current_epoch() -> String: return "session_a"

class TransportFixture extends Node:
	var ledger: RefCounted
	var published: Array[Dictionary] = []
	func publish_journaled_delta(delta: Dictionary) -> void: published.append(delta.duplicate(true))

class GameFixture extends Node:
	var world: RefCounted
	var ledger: Node
	var save_system: RefCounted
	var progression: RefCounted

class ChapterFixture extends Node:
	var chapter := {"acts": [{"entry_flags": [], "objectives": [{"id": "offer", "flag_id": "stormwood:legendary_offer_made",
		"scope": "world", "requires_flags": ["stormwood:legendary_freed"], "completion_event": "legendary:offer_shown"}]}]}

class EndingFixture extends "res://scripts/world/stormwood_ending.gd":
	var fixture: Node
	var write_ok := false
	var written: Dictionary = {}
	func _decision_game() -> Node: return fixture
	func _character_for_peer(_peer: int) -> String: return "character_a"
	func _has(flag: String) -> bool: return fixture.world.flags.has(flag)
	func _saved_state() -> Dictionary: return fixture.world.realm_environment.stormwood.ending.duplicate(true)
	func _store_state(state: Dictionary) -> void: fixture.world.realm_environment.stormwood.ending = state.duplicate(true)
	func _save_world_claim() -> bool:
		written = fixture.world.save_data().duplicate(true)
		return write_ok

func test_failed_answer_publishes_nothing_and_retry_can_keep_the_original_opposite_choice() -> void:
	var game := GameFixture.new()
	game.world = WORLD.new()
	game.world.world_id = "world_a"
	game.world.reward_delivery_namespace = "namespace_a"
	game.world.flags.set_flag(ENDING.FREED_FLAG)
	game.world.realm_environment = {"stormwood": {"ending": {"participants": ["character_a"],
		"claims": {"character_a": {"creature": {"uid": "original_reserved_card"}, "kept": false, "settled": false}}}}}
	game.progression = game.world.flags
	var transport := TransportFixture.new()
	transport.ledger = LEDGER.new(game.world)
	game.ledger = transport
	var source := EndingFixture.new()
	source.fixture = game
	source.session = SessionFixture.new()
	source._chapter = ChapterFixture.new()
	source._foundation_world_binding = weakref(game.world)
	var before: Dictionary = game.world.save_data().duplicate(true)
	var sequence := int(transport.ledger.seq)
	assert_false(source._commit_world_decision(1, true, true))
	assert_true(transport.published.is_empty())
	assert_eq(game.world.save_data(), before)
	assert_eq(transport.ledger.seq, sequence)
	assert_false(game.world.flags.has(ENDING.resolution_flag(true, "character_a")))
	assert_false(game.world.flags.has(ENDING.OFFER_FLAG))
	source.write_ok = true
	assert_true(source._commit_world_decision(1, false, true))
	assert_true(game.world.flags.has(ENDING.resolution_flag(false, "character_a")))
	assert_false(game.world.flags.has(ENDING.resolution_flag(true, "character_a")))
	assert_true(game.world.flags.has(ENDING.OFFER_FLAG))
	assert_eq(source._saved_state().claims.character_a.creature.uid, "original_reserved_card")
	assert_true(source._saved_state().claims.character_a.settled)
	assert_false(source._saved_state().claims.character_a.kept)
	assert_false(transport.published.is_empty())
	assert_eq(source.written, game.world.save_data())
	source._chapter.free()
	source.session.free()
	source.free()
	transport.free()
	game.free()
