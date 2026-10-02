extends "res://tests/test_case.gd"

const PROOF := preload("res://tools/net/f48_passive_witness.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const PARTY := preload("res://autoload/party.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")

class Identity extends RefCounted:
	var character_id := "owner"
	var reward_delivery_namespace := "world"

class Epoch extends RefCounted:
	var value := "epoch"
	func _altar_current_epoch() -> String: return value

class Context extends RefCounted:
	var world := Identity.new()
	var local := Identity.new()
	var session := Epoch.new()

var context: Context
var state: Dictionary
var packet: Dictionary
var path: String

func before_each() -> void:
	context = Context.new()
	path = "user://f48-passive-control-%d.jsonl" % Time.get_ticks_usec()
	var file := FileAccess.open(path, FileAccess.WRITE)
	var party: RefCounted = PARTY.new()
	var original: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/f48-passive-card.json"))
	var saver: RefCounted = SAVE.new()
	saver.call("_array_to_party", [original.card], party)
	assert_eq(party.call("size"), 1, "the actual complete original owned card must load")
	var creature: RefCounted = party.call("members")[0]
	creature.set("rested", true)
	creature.set("rested_seconds_left", 0.25)
	var buffs: Array[Dictionary] = [{"id": "control", "remaining_s": 0.25, "attack": 1.2}]
	creature.set("active_buffs", buffs)
	var before: Dictionary = saver.call("_party_to_array", party)[0]
	var buffs_before: Array = creature.get("active_buffs").duplicate(true)
	creature.call("tick_buffs", 0.5)
	CONDITION.tick(creature, CONDITION.config(), 0.5)
	packet = {"sequence": 1, "delta": 0.5, "character_id": "owner", "world_namespace": "world", "session_epoch": "epoch",
		"uid": before.uid, "before": before, "after": saver.call("_party_to_array", party)[0],
		"buffs_before": buffs_before, "buffs_after": creature.get("active_buffs").duplicate(true), "condition_config": CONDITION.config().duplicate(true)}
	state = {"sequence": -1, "events": 0, "error": "", "file": file, "chain_sha256": "", "configuration": CONDITION.config(),
		"game_ref": weakref(context), "world_ref": weakref(context.world), "session_ref": weakref(context.session),
		"character_id": "owner", "world_namespace": "world", "epoch": "epoch", "anchors": {"original": {
			"character_id": "owner", "world_namespace": "world", "initial": [before.duplicate(true)],
			"expected": [before.duplicate(true)], "error": "", "buffs": {before.uid: buffs_before.duplicate(true)}}}}

func after_each() -> void:
	state.file.close()
	DirAccess.remove_absolute(path)

func test_actual_full_card_buffs_and_rested_expiry_replay_without_rng_use() -> void:
	seed(417)
	var expected_random := randf()
	seed(417)
	PROOF._tick(state, packet)
	assert_eq(randf(), expected_random, "detached evidence must not consume gameplay RNG")
	assert_eq(state.error, "")
	assert_eq(state.anchors.original.error, "")
	assert_true(PROOF.equal(state.anchors.original.expected, [packet.after]))
	assert_false(packet.after.rested)
	assert_eq(packet.buffs_after.size(), 0)
	assert_eq(state.events, 1)

func test_integral_json_card_fields_roundtrip_without_losing_full_fields() -> void:
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(packet))
	parsed.delta = 0.0
	parsed.after = parsed.before.duplicate(true)
	parsed.buffs_after = parsed.buffs_before.duplicate(true)
	var result := PROOF.replay_packet(parsed, CONDITION.config())
	assert_false(result.has("error"), str(result))
	assert_true(PROOF.equal(result.after, parsed.before))

func test_missing_sequence_is_refused() -> void:
	state.sequence = 1
	packet.sequence = 3
	PROOF._tick(state, packet)
	assert_false(state.error.is_empty())
	assert_eq(state.events, 0)

func test_replaced_uid_cannot_be_excused_as_passive_time() -> void:
	packet.after.uid = "creature-00000000000000000000000000000000"
	PROOF._tick(state, packet)
	assert_false(state.error.is_empty())

func test_arbitrary_full_card_mutation_is_refused() -> void:
	packet.after.attack += 1.0
	PROOF._tick(state, packet)
	assert_false(state.error.is_empty())

func test_unobserved_mutation_before_a_valid_tick_invalidates_original_anchor() -> void:
	packet.before.attack += 1.0
	packet.after.attack += 1.0
	PROOF._tick(state, packet)
	assert_eq(state.error, "", "the tick itself is valid")
	assert_false(state.anchors.original.error.is_empty(), "full original card continuity must still fail")

func test_owner_world_and_epoch_replacements_are_refused() -> void:
	context.local.character_id = "other"
	PROOF._tick(state, packet)
	assert_false(state.error.is_empty())
	state.error = ""
	context.local.character_id = "owner"
	var original_world: Identity = context.world
	context.world = Identity.new()
	PROOF._tick(state, packet)
	assert_false(state.error.is_empty())
	state.error = ""
	context.world = original_world
	context.session.value = "new-epoch"
	PROOF._tick(state, packet)
	assert_false(state.error.is_empty())

func test_configuration_change_is_refused() -> void:
	packet.condition_config.nourishment.drain_per_minute += 1.0
	PROOF._tick(state, packet)
	assert_false(state.error.is_empty())

func test_bounded_evidence_overflow_is_refused_before_dropping_transition() -> void:
	state.events = PROOF.MAX_EVENTS
	PROOF._tick(state, packet)
	assert_false(state.error.is_empty())
	assert_eq(state.sequence, -1)
