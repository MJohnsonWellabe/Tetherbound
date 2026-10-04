extends "res://tests/test_case.gd"

const PROOF := preload("res://tools/net/f48_passive_witness.gd")
const SAVE := preload("res://scripts/save/save_game.gd")
const PARTY := preload("res://autoload/party.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const GAME_FIXTURE := preload("res://tests/test_canonical_guest_passive_fence.gd")
const MAP := preload("res://autoload/map_state.gd")
const FEED := preload("res://scripts/creatures/progression_feed.gd")

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
	var current_realm := "meadows"

class DiscoverySession extends Node:
	func _altar_current_epoch() -> String: return "epoch"
	func _owner_training_mutation_blocked(_player: RefCounted) -> bool: return false

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

func test_explicit_condition_clock_keeps_actual_full_tick() -> void:
	packet.condition_tick_applied = true
	PROOF._tick(state, packet)
	assert_eq(state.error, "")
	assert_eq(state.anchors.original.error, "")
	assert_true(PROOF.equal(state.anchors.original.expected, [packet.after]))
	assert_eq(state.events, 1)

func test_buff_only_observation_preserves_full_card_and_replays_actual_buffs() -> void:
	packet.condition_tick_applied = false
	packet.after = packet.before.duplicate(true)
	PROOF._tick(state, packet)
	assert_eq(state.error, "")
	assert_eq(state.anchors.original.error, "")
	assert_true(PROOF.equal(state.anchors.original.expected, [packet.before]))
	assert_true(state.anchors.original.buffs[packet.uid].is_empty(), "real buff expiry still advances")
	assert_true(packet.after.rested, "no condition expiry is invented")
	assert_eq(packet.after.rested_seconds_left, 0.25)
	assert_eq(state.events, 1)
	state.file.flush()
	var recorded: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path).strip_edges())
	assert_eq(recorded.condition_tick_applied, false, "retained diagnostic identifies the actual clock")

func test_buff_only_cannot_excuse_condition_change_or_unadvanced_buffs() -> void:
	packet.condition_tick_applied = false
	assert_true(PROOF.replay_packet(packet, CONDITION.config()).has("error"), "condition actually changed")
	packet.after = packet.before.duplicate(true)
	packet.buffs_after = packet.buffs_before.duplicate(true)
	assert_true(PROOF.replay_packet(packet, CONDITION.config()).has("error"), "buff clock must still advance")
	packet.buffs_after = []
	packet.after.attack += 1.0
	assert_true(PROOF.replay_packet(packet, CONDITION.config()).has("error"), "unrelated full-card change still fails")

func test_malformed_condition_clock_observation_is_refused_without_evidence() -> void:
	for invalid: Variant in [null, 0, 1, 0.0, 1.0, "false", [], {}]:
		packet.condition_tick_applied = invalid
		assert_true(PROOF.replay_packet(packet, CONDITION.config()).has("error"))
		PROOF._tick(state, packet)
		assert_eq(state.error, "Malformed actual condition-clock observation")
		assert_eq(state.events, 0)
		assert_eq(state.sequence, -1)
		assert_eq(state.file.get_position(), 0)
		state.error = ""

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

func _discovery_packet(before: Dictionary, sequence: int = 1) -> Dictionary:
	return {"operation": "discovery", "sequence": sequence, "delta": 0.0,
		"character_id": "owner", "world_namespace": "world", "session_epoch": "epoch", "realm": "meadows",
		"uid": before.uid, "before": before.duplicate(true), "after": before.duplicate(true),
		"buffs_before": packet.buffs_before.duplicate(true), "buffs_after": packet.buffs_before.duplicate(true),
		"condition_config": CONDITION.config().duplicate(true), "from": [0.0, 0.0, 0.0], "to": [3.0, 0.0, 4.0],
		"travel_valid": true, "discovery_elapsed": 0.5,
		"landmarks_before": {"original": true}, "landmarks_after": {"original": true}}

func test_discovery_between_care_ticks_preserves_full_original_anchor() -> void:
	PROOF._tick(state, packet)
	var discovery := _discovery_packet(packet.after, 2)
	discovery.buffs_before = packet.buffs_after.duplicate(true)
	discovery.buffs_after = packet.buffs_after.duplicate(true)
	discovery.after.distance_m_together += 5.0
	var original: Array = state.anchors.original.initial.duplicate(true)
	PROOF._tick(state, discovery)
	var care := packet.duplicate(true)
	care.sequence = 3
	care.delta = 0.0
	care.before = discovery.after.duplicate(true)
	care.after = discovery.after.duplicate(true)
	care.buffs_before = discovery.buffs_after.duplicate(true)
	care.buffs_after = discovery.buffs_after.duplicate(true)
	PROOF._tick(state, care)
	assert_eq(state.error, "")
	assert_eq(state.anchors.original.error, "")
	assert_eq(state.sequence, 3)
	assert_eq(state.events, 3)
	assert_true(PROOF.equal(state.anchors.original.expected, [care.after]))
	assert_true(PROOF.equal(state.anchors.original.initial, original), "original anchor is never rebased")
	state.file.flush()
	var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	var recorded: Dictionary = JSON.parse_string(lines[1])
	assert_eq(recorded.operation, "discovery")
	assert_eq(recorded.from, discovery.from)
	assert_eq(recorded.to, discovery.to)
	assert_eq(recorded.landmarks_before, discovery.landmarks_before)
	assert_eq(recorded.landmarks_after, discovery.landmarks_after)
	assert_eq(recorded.b, JSON.stringify(discovery.before).sha256_text())
	assert_eq(recorded.a, JSON.stringify(discovery.after).sha256_text())

func test_discovery_credits_one_visit_for_multiple_original_new_landmarks() -> void:
	var discovery := _discovery_packet(packet.before)
	discovery.landmarks_after["new-a"] = true
	discovery.landmarks_after["new-b"] = true
	discovery.after.distance_m_together += 5.0
	discovery.after.landmarks_visited_together += 1
	var feed_revision := FEED.revision()
	seed(417)
	var expected_random := randf()
	seed(417)
	PROOF._tick(state, discovery)
	assert_eq(randf(), expected_random, "detached discovery replay consumes no gameplay RNG")
	assert_eq(FEED.revision(), feed_revision, "detached discovery replay publishes no progression feedback")
	assert_eq(state.error, "")
	assert_eq(state.anchors.original.error, "")
	assert_true(PROOF.equal(state.anchors.original.expected, [discovery.after]))
	assert_true(PROOF.equal(state.anchors.original.buffs[discovery.uid], discovery.buffs_before), "discovery never advances buffs")
	discovery.after.landmarks_visited_together += 1
	assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), "two landmarks in one poll still earn just one visit")

func test_discovery_teleport_and_invalid_baseline_earn_no_distance() -> void:
	var discovery := _discovery_packet(packet.before)
	discovery.to = [31.0, 0.0, 0.0]
	assert_false(PROOF.replay_packet(discovery, CONDITION.config()).has("error"))
	discovery.after.distance_m_together += 31.0
	assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), "teleport credit is refused")
	discovery.after = discovery.before.duplicate(true)
	discovery.to = [3.0, 0.0, 4.0]
	discovery.travel_valid = false
	assert_false(PROOF.replay_packet(discovery, CONDITION.config()).has("error"))
	discovery.after.distance_m_together += 5.0
	assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), "a fresh travel baseline grants nothing")
	discovery.travel_valid = true
	discovery.to = [30.0, 0.0, 0.0]
	discovery.after.distance_m_together = discovery.before.distance_m_together + 30.0
	assert_false(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), "the shipping 30 m boundary remains inclusive")

func test_discovery_cannot_excuse_other_full_card_or_buff_changes() -> void:
	for field: String in ["attack", "hp", "nourishment", "happiness", "landmarks_visited_together"]:
		var discovery := _discovery_packet(packet.before)
		discovery.after.distance_m_together += 5.0
		discovery.after[field] += 1.0
		assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), field)
	var discovery := _discovery_packet(packet.before)
	discovery.after.distance_m_together += 5.0
	discovery.buffs_after = []
	assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), "discovery cannot expire an original buff")
	discovery = _discovery_packet(packet.before)
	discovery.before.attack += 1.0
	discovery.after.attack += 1.0
	discovery.after.distance_m_together += 5.0
	PROOF._tick(state, discovery)
	assert_eq(state.error, "", "the isolated discovery itself replays")
	assert_false(state.anchors.original.error.is_empty(), "unobserved prior mutation still breaks the full original anchor")

func test_discovery_rejects_malformed_inputs_and_removed_original_landmarks() -> void:
	for field: String in ["from", "to", "travel_valid", "discovery_elapsed", "landmarks_before", "landmarks_after"]:
		var discovery := _discovery_packet(packet.before)
		discovery.erase(field)
		assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), field)
	for invalid: Variant in [[0.0, INF, 0.0], [0.0, NAN, 0.0], [0.0, 0.0], ["0", 0.0, 0.0]]:
		var discovery := _discovery_packet(packet.before)
		discovery.to = invalid
		assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"))
	var discovery := _discovery_packet(packet.before)
	discovery.landmarks_after = {}
	assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), "original discoveries cannot disappear")
	discovery = _discovery_packet(packet.before)
	discovery.landmarks_after["new"] = 1
	assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), "only actual discovered markers are accepted")
	discovery = _discovery_packet(packet.before)
	discovery.discovery_elapsed = 0.49
	assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), "the original discovery poll must have reached its cadence")
	discovery = _discovery_packet(packet.before)
	discovery.delta = 0.5
	assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"), "a discovery never carries another care tick")
	discovery = _discovery_packet(packet.before)
	discovery.operation = "grant"
	assert_true(PROOF.replay_packet(discovery, CONDITION.config()).has("error"))

func test_discovery_preserves_sequence_realm_and_owner_lifetime_guards() -> void:
	var discovery := _discovery_packet(packet.before)
	discovery.after.distance_m_together += 5.0
	discovery.realm = "water"
	PROOF._tick(state, discovery)
	assert_eq(state.error, "Actual discovery realm changed")
	assert_eq(state.events, 0)
	state.error = ""
	discovery.realm = "meadows"
	state.sequence = 1
	discovery.sequence = 3
	PROOF._tick(state, discovery)
	assert_false(state.error.is_empty())
	assert_eq(state.events, 0)
	state.error = ""
	state.sequence = -1
	discovery.sequence = 1
	context.session.value = "rejoined"
	PROOF._tick(state, discovery)
	assert_eq(state.error, "Actual passive owner/world/session lifetime changed")
	assert_eq(state.events, 0)

func _shipping_game_case(tree: SceneTree) -> bool:
	# Real Game._process, real MapState and creature writers; only Session's
	# epoch/fence decision and unrelated maintenance are disclosed doubles.
	var original_feed: RefCounted = FEED._active
	var game := GAME_FIXTURE.GameFixture.new()
	var actor := Node3D.new()
	tree.root.add_child(actor)
	game.actor = actor
	var owner_session := DiscoverySession.new()
	game.session = owner_session
	game.local.character_id = "owner"
	game.world.reward_delivery_namespace = "world"
	game.quest_log = GAME_FIXTURE.QuestFixture.new()
	var actual_map := MAP.new()
	actual_map.set_extent(Vector2(-16, -16), 16, 16, 4.0)
	actual_map.configure({"reveal_radius": 1.0, "landmarks": [
		{"id": "near-a", "position": [3.0, 0.0], "discover_radius": 0.25},
		{"id": "near-b", "position": [3.0, 0.0], "discover_radius": 0.25}]})
	game.map = actual_map
	SAVE.new().call("_array_to_party", [packet.before], game.party)
	var creature: RefCounted = game.party.call("members")[0]
	var buffs: Array = creature.get("active_buffs")
	buffs.assign(packet.buffs_before.duplicate(true))
	assert_true(PROOF.equal(SAVE.new().call("_party_to_array", game.party), state.anchors.original.initial), "native fixture begins with the exact original complete card")
	state.game_ref = weakref(game)
	state.world_ref = weakref(game.world)
	state.session_ref = weakref(owner_session)
	game._travel_pos = Vector3.ZERO
	game._travel_pos_valid = true
	game._discovery_elapsed = 0.0
	var observed: Array[Dictionary] = []
	var observer := func(actual: Dictionary) -> void:
		observed.append(actual.duplicate(true))
		PROOF._tick(state, actual)
	game.party_passive_tick.connect(observer)
	var original_anchor: Array = state.anchors.original.initial.duplicate(true)
	game._process(0.5)
	actor.position = Vector3(3, 0, 0)
	game._process(0.5)
	actor.position = Vector3(3, 0, 4)
	game._process(0.5)
	actor.position = Vector3(103, 0, 4)
	game._process(0.5)
	assert_eq(observed.size(), 8, "each shipping poll exposes one original care and one original discovery transition")
	var operations: Array[String] = []
	for actual: Dictionary in observed: operations.append(str(actual.get("operation", "clock")))
	assert_eq(operations, ["clock", "discovery", "clock", "discovery", "clock", "discovery", "clock", "discovery"])
	assert_eq(state.error, "")
	assert_eq(state.anchors.original.error, "", "original anchor follows actual interleaved shipping writers")
	assert_eq(state.events, 8)
	assert_eq(state.sequence, 8)
	assert_eq(creature.distance_m_together, packet.before.distance_m_together + 7.0)
	assert_eq(creature.landmarks_visited_together, packet.before.landmarks_visited_together + 1)
	assert_true(PROOF.equal(state.anchors.original.expected, SAVE.new().call("_party_to_array", game.party)))
	assert_true(PROOF.equal(state.anchors.original.initial, original_anchor))
	if observed.size() == 8:
		assert_eq(observed[3].from, [0.0, 0.0, 0.0])
		assert_eq(observed[3].to, [3.0, 0.0, 0.0])
		assert_eq(observed[3].landmarks_before, {})
		assert_eq(observed[3].landmarks_after, {"near-a": true, "near-b": true})
		assert_eq(observed[7].before.distance_m_together, observed[7].after.distance_m_together, "actual >30 m relocation earns nothing")
		assert_true(PROOF.equal(observed[3].buffs_before, observed[3].buffs_after))
		for index: int in observed.size():
			assert_eq(observed[index].sequence, index + 1, "clock and discovery share the original monotonic sequence")
	game.party_passive_tick.disconnect(observer)
	actor.free()
	game.free()
	owner_session.free()
	FEED.set_active(original_feed)
	return true # Native wrapper requires this terminal value, not merely exit 0.

func test_shipping_game_discovery_writer_matches_full_card_replay() -> void:
	# Unit tests run in SceneTree._init; the actor needs an initialized native
	# child tree. Keep this lifecycle adapter local to this focused suite.
	var suffix := str(Time.get_ticks_usec())
	var helper := "user://f48-discovery-native-" + suffix + ".gd"
	var log_path := "user://f48-discovery-native-" + suffix + ".log"
	assert_false(FileAccess.file_exists(helper) or FileAccess.file_exists(log_path))
	var file := FileAccess.open(helper, FileAccess.WRITE)
	assert_true(file != null)
	if file == null: return
	file.store_string("extends SceneTree\nfunc _initialize() -> void:\n\tcall_deferred(\"_run\")\nfunc _run() -> void:\n\tvar test = load(\"res://tests/test_f48_passive_witness.gd\").new()\n\ttest.before_each()\n\tvar completed = test._shipping_game_case(self)\n\ttest.after_each()\n\tvar result = {\"completed\": completed == true, \"assertions\": test.assertion_count, \"failures\": test.failures.duplicate()}\n\ttest = null\n\tawait process_frame\n\tprint(\"F48_DISCOVERY_NATIVE_RESULT=\" + JSON.stringify(result))\n\tquit(0 if result.completed and result.failures.is_empty() else 1)\n")
	file.close()
	var output: Array = []
	var code := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", ProjectSettings.globalize_path(helper), "--log-file", ProjectSettings.globalize_path(log_path)], output, true)
	var combined := "\n".join(output)
	var results: Array[Dictionary] = []
	for line: String in combined.split("\n"):
		if line.begins_with("F48_DISCOVERY_NATIVE_RESULT="):
			print(line) # Preserve the original child result in the hosted artifact.
			var parsed: Variant = JSON.parse_string(line.trim_prefix("F48_DISCOVERY_NATIVE_RESULT="))
			if parsed is Dictionary: results.append(parsed)
	assert_true(FileAccess.file_exists(log_path), "the original native --log-file must exist")
	if FileAccess.file_exists(log_path): combined += "\n" + FileAccess.get_file_as_string(log_path)
	assert_eq(results.size(), 1, combined)
	if results.size() == 1:
		assert_true(results[0].get("completed") == true, combined)
		assert_eq(results[0].get("failures", ["missing result"]), [], combined)
		assert_eq(results[0].get("assertions", 0), 26, "all original writer assertions executed")
	assert_false(combined.contains("ERROR:") or combined.contains("ObjectDB instances") or combined.contains("resources still in use")
		or combined.contains("RID allocations") or combined.contains("RIDs of type"), combined)
	assert_eq(code, 0, combined)
	DirAccess.remove_absolute(helper)
