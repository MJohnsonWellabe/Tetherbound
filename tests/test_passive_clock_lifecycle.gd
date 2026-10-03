extends "res://tests/test_case.gd"

## Actual lifecycle validation/authentication and Godot pause predicate with
## disclosed minimal identity fixtures. No transport, terrain, or F48 proof.
const LIFECYCLE := preload("res://scripts/net/foundation_travel_lifecycle.gd")
const NATIVE_CASE := preload("res://tests/helpers/passive_native_case.gd")
var _native_completed := false

class ClockPlayer extends RefCounted:
	var character_id := "clock-owner"

class ClockWorld extends RefCounted:
	var reward_delivery_namespace := "clock-world"

class ClockGame extends Node:
	var local: RefCounted = ClockPlayer.new()
	var world: RefCounted = ClockWorld.new()

class ClockSession extends Node:
	var game: Node
	var hosting := true
	var active := true
	var blocked := false
	var epoch := "clock-epoch"
	var character := "clock-owner"
	var realm := "meadows"
	var admissions := 0
	func is_host() -> bool: return hosting
	func is_active() -> bool: return active
	func _game() -> Node: return game
	func _authority_character(peer: int) -> String: return character if peer == 2 else ""
	func realm_of(peer: int) -> String: return realm if peer == 2 else ""
	func _altar_current_epoch() -> String: return epoch
	func admitted_character_state(_peer: int) -> Dictionary:
		admissions += 1
		return {"disclosed_admitted_fixture": true}
	func _owner_training_mutation_blocked(_player: RefCounted) -> bool: return blocked

class Observation extends LIFECYCLE:
	var fixture: Node
	func session() -> Node: return fixture
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass

func _sample() -> Dictionary:
	return {"character_id": "clock-owner", "world_instance_id": "clock-world", "session_epoch": "clock-epoch",
		"realm": "meadows", "damage_revision": 0, "dialogue": false, "cutscene": false,
		"swimming": false, "flying": false, "downed": false, "station_ack_only": false,
		"ending_owner": false, "party_revision": 0, "party_signature": "a".repeat(64), "sequence": 1}

func test_legacy_and_new_shapes_validate_without_accepting_unknown_or_malformed_fields() -> void:
	var legacy := _sample()
	assert_true(LIFECYCLE.valid_sample(legacy))
	var equipment := legacy.duplicate(true)
	equipment.equipped_tool = "hoe"
	assert_true(LIFECYCLE.valid_sample(equipment))
	var clock := legacy.duplicate(true)
	clock.passive_clock_active = true
	assert_true(LIFECYCLE.valid_sample(clock))
	clock.equipped_tool = "hoe"
	assert_true(LIFECYCLE.valid_sample(clock))
	for value: Variant in [null, 0, 1, "true", [], {}]:
		var bad := clock.duplicate(true)
		bad.passive_clock_active = value
		assert_false(LIFECYCLE.valid_sample(bad))
	var unknown := legacy.duplicate(true)
	unknown.unrecognized = true
	assert_false(LIFECYCLE.valid_sample(unknown), "sixteenth field must be a supported optional field")
	unknown = clock.duplicate(true)
	unknown.erase("dialogue")
	unknown.unrecognized = false
	assert_false(LIFECYCLE.valid_sample(unknown), "same count cannot conceal a missing required field")
	clock.equipped_tool = 1
	assert_false(LIFECYCLE.valid_sample(clock))

func test_accessor_requires_authenticated_fresh_current_scope_and_explicit_active_flag() -> void:
	var game := ClockGame.new()
	var owner := ClockSession.new()
	owner.game = game
	var observer := Observation.new()
	observer.fixture = owner
	assert_false(observer.host_passive_clock_active(2))
	var sample := _sample()
	observer.accept(2, sample)
	assert_false(observer.host_passive_clock_active(2), "legacy packet has no clock authority")
	sample.sequence = 2
	sample.passive_clock_active = true
	observer.accept(3, sample)
	assert_false(observer.host_passive_clock_active(3), "foreign peer cannot seed this character")
	observer.accept(2, sample)
	var admissions: int = owner.admissions
	assert_true(observer.host_passive_clock_active(2))
	assert_eq(owner.admissions, admissions, "accessor does not refresh admission")
	var stale_packet := sample.duplicate(true)
	stale_packet.passive_clock_active = false
	observer.accept(2, stale_packet)
	assert_true(observer.host_passive_clock_active(2), "existing monotonic sequence rejects replay")
	owner.epoch = "changed"
	assert_false(observer.host_passive_clock_active(2))
	owner.epoch = "clock-epoch"
	game.world.reward_delivery_namespace = "changed"
	assert_false(observer.host_passive_clock_active(2))
	game.world.reward_delivery_namespace = "clock-world"
	owner.character = "changed"
	assert_false(observer.host_passive_clock_active(2))
	owner.character = "clock-owner"
	owner.realm = "water"
	assert_false(observer.host_passive_clock_active(2), "old realm sample cannot authorize a new body")
	owner.realm = "meadows"
	owner.active = false
	assert_false(observer.host_passive_clock_active(2))
	owner.active = true
	owner.hosting = false
	assert_false(observer.host_passive_clock_active(2))
	owner.hosting = true
	observer._observations[2].seen_at = Time.get_ticks_msec() - 60000
	assert_false(observer.host_passive_clock_active(2), "stale authentic observation cannot extend care time")
	sample.sequence = 3
	sample.passive_clock_active = false
	observer.accept(2, sample)
	assert_false(observer.host_passive_clock_active(2))
	observer.free()
	owner.free()
	game.free()

func _native_case_actual_game_pause_and_transaction_fence_control_clock_not_modal_flags() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var game := ClockGame.new()
	game.process_mode = Node.PROCESS_MODE_PAUSABLE
	tree.root.add_child(game)
	game.set_process(true)
	var owner := ClockSession.new()
	owner.game = game
	var was_paused: bool = tree.paused
	tree.paused = false
	assert_true(LIFECYCLE.local_passive_clock_active(game, owner))
	var modal_sample := _sample()
	modal_sample.dialogue = true
	modal_sample.cutscene = true
	modal_sample.passive_clock_active = LIFECYCLE.local_passive_clock_active(game, owner)
	assert_true(LIFECYCLE.valid_sample(modal_sample))
	assert_true(modal_sample.passive_clock_active, "D102 input modals do not imply actual tree pause")
	tree.paused = true
	assert_false(LIFECYCLE.local_passive_clock_active(game, owner), "actual paused Game cannot tick")
	tree.paused = false
	owner.blocked = true
	assert_false(LIFECYCLE.local_passive_clock_active(game, owner), "original pending transaction freezes condition")
	owner.blocked = false
	game.set_process(false)
	assert_false(LIFECYCLE.local_passive_clock_active(game, owner), "disabled process callback cannot tick")
	game.set_process(true)
	game.process_mode = Node.PROCESS_MODE_DISABLED
	assert_false(LIFECYCLE.local_passive_clock_active(game, owner))
	tree.paused = was_paused
	owner.free()
	game.free()
	_native_completed = true

func test_actual_game_pause_and_transaction_fence_control_clock_not_modal_flags() -> void:
	NATIVE_CASE.run_case(self, "res://tests/test_passive_clock_lifecycle.gd", "_native_case_actual_game_pause_and_transaction_fence_control_clock_not_modal_flags", 7)
