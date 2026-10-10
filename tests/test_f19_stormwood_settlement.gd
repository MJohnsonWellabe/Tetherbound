extends "res://tests/test_case.gd"

## Exercise the production host decision cut with a real WorldLedger and split
## world file. Fixture seams supply scene ownership, not verdicts or flag writes.
const ENDING := preload("res://scripts/world/stormwood_ending.gd")
const WORLD := preload("res://autoload/world_state.gd")
const LEDGER := preload("res://scripts/net/world_ledger.gd")
const SAVE := preload("res://scripts/save/world_save.gd")
const FIXTURE := preload("res://tests/helpers/split_save_fixture.gd")
const REWARDS := preload("res://scripts/net/encounter_rewards.gd")

class HostSession extends Node:
	func is_host() -> bool: return true
	# This fixture covers the world writer/publication cut. The production
	# Session's canonical owner validation remains outside this fixture.
	func foundation_stormwood_answer(_source: Node, _peer: int, claim: Dictionary,
			_cut: Dictionary = {}, phase: String = "commit") -> bool:
		return phase == "rollback" or (phase in ["stage", "commit"] and claim.get("settled") == true)
	func _altar_current_epoch() -> String: return "host-epoch"

class Transport extends Node:
	var ledger: RefCounted
	var published: Array = []
	func publish_journaled_delta(delta: Dictionary) -> void: published.append(delta.duplicate(true))

class Chapter extends Node:
	var chapter: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_chapter.json"))

class Saver extends RefCounted:
	var refuse := false
	var store: RefCounted
	func finish_fallback() -> bool: return true
	func fallback_busy() -> bool: return false
	func save_world_prepared(game: Node, id: String) -> bool:
		if refuse: return false
		var snapshot: Dictionary = game.world.save_data()
		snapshot.progression = game.world.flags.save_data()
		return store.write(id, SAVE.partition(snapshot))

class GameFixture extends Node:
	var world: RefCounted
	var ledger: Node
	var session: Node
	var save_system: RefCounted
	var progression: RefCounted

class DecisionEnding extends "res://scripts/world/stormwood_ending.gd":
	var fixture: Node
	func _decision_game() -> Node: return fixture
	func _character_for_peer(peer: int) -> String: return "character-guest" if peer == 2 else "character-host"
	func _has(flag: String) -> bool: return fixture.world.flags.has(flag)
	func _saved_state() -> Dictionary: return fixture.world.realm_environment.stormwood.ending.duplicate(true)
	func _store_state(state: Dictionary) -> void: fixture.world.realm_environment.stormwood.ending = state.duplicate(true)
	func _save_world_claim() -> bool: return fixture.save_system.save_world_prepared(fixture, fixture.world.world_id)

var _dir := ""
var _game: GameFixture
var _ending: DecisionEnding
var _chapter: Chapter

func before_each() -> void:
	_dir = "user://f19_stormwood_%s/" % Crypto.new().generate_random_bytes(12).hex_encode()
	_game = GameFixture.new()
	_game.world = WORLD.new()
	_game.world.world_id = "f19-world"
	_game.world.reward_delivery_namespace = "f19-instance"
	_game.world.flags.set_flag(ENDING.FREED_FLAG)
	_game.world.flags.set_flag("stormwood:act_ii_complete") # Declared transaction fixture, not earned route proof.
	_game.world.realm_environment = {"stormwood": {"ending": {"participants": ["character-host", "character-guest"],
		"claims": {"character-guest": {"creature": {"uid": "claim-guest"}, "settled": false, "kept": false}}}}}
	_game.progression = _game.world.flags
	_game.session = HostSession.new()
	_game.ledger = Transport.new()
	_game.ledger.ledger = LEDGER.new(_game.world)
	_game.save_system = Saver.new()
	_game.save_system.store = SAVE.new(_dir)
	_ending = DecisionEnding.new()
	_ending.fixture = _game
	_ending.session = _game.session
	_ending._foundation_world_binding = weakref(_game.world)
	_chapter = Chapter.new()
	_ending._chapter = _chapter

func after_each() -> void:
	_ending.free()
	_chapter.free()
	_game.session.free()
	_game.ledger.free()
	_game.free()
	FIXTURE.wipe(_dir)

func _handoff() -> Dictionary:
	return REWARDS.chapter_hand_off("captain_marrow_dynamo_core", "stormwood")

func _assert_guest_first(kept: bool) -> void:
	assert_true(_ending._commit_world_decision(2, kept, true), "authenticated host saves the guest's first answer")
	assert_true(_game.world.flags.has(ENDING.resolution_flag(kept, "character-guest")))
	assert_false(_game.world.flags.has(ENDING.resolution_flag(kept, "character-host")))
	assert_true(_game.world.realm_environment.stormwood.ending.claims["character-guest"].settled)
	assert_eq(_game.world.realm_environment.stormwood.ending.claims["character-guest"].kept, kept)
	assert_true(REWARDS.chapter_delivery_ready(_handoff(), _game.world.flags.all_set()))
	var loaded := WORLD.new()
	loaded.load_data(_game.save_system.store.read(_game.world.world_id))
	assert_true(loaded.flags.has(ENDING.resolution_flag(kept, "character-guest")), "the real split file retains the original answer")
	assert_true(REWARDS.chapter_delivery_ready(_handoff(), loaded.flags.all_set()))
	assert_false(_game.ledger.published.is_empty(), "publication follows the successful world write")
	var original: Dictionary = _game.world.save_data()
	assert_false(_ending._commit_world_decision(2, not kept, true), "an opposite replay cannot change the saved decision")
	assert_eq(_game.world.save_data(), original)

func test_guest_first_acceptance_is_saved_and_releases_every_captured_boss_drop() -> void:
	_assert_guest_first(true)

func test_guest_first_refusal_is_saved_and_releases_every_captured_boss_drop() -> void:
	_assert_guest_first(false)

func test_failed_guest_first_write_rolls_back_and_retries_the_original_claim() -> void:
	var before: Dictionary = _game.world.save_data()
	var revision: int = _game.world.revision
	var flags_revision: int = _game.world.flags.revision
	var sequence: int = _game.ledger.ledger.seq
	_game.save_system.refuse = true
	assert_false(_ending._commit_world_decision(2, true, true))
	assert_eq(_game.world.save_data(), before)
	assert_eq(_game.world.revision, revision)
	assert_eq(_game.world.flags.revision, flags_revision)
	assert_eq(_game.ledger.ledger.seq, sequence)
	assert_eq(_game.ledger.published, [])
	assert_false(REWARDS.chapter_delivery_ready(_handoff(), _game.world.flags.all_set()))
	_game.save_system.refuse = false
	_assert_guest_first(true)

func test_non_owed_visibility_advancement_never_counts_as_a_ceremony_answer() -> void:
	assert_true(_ending._commit_world_decision(2, false, false))
	assert_true(_game.world.flags.has(ENDING.OFFER_FLAG), "preserve existing visitor/world presentation")
	assert_false(REWARDS.chapter_delivery_ready(_handoff(), _game.world.flags.all_set()))
	assert_false(_game.world.realm_environment.stormwood.ending.claims["character-guest"].settled)
	_assert_guest_first(false)
