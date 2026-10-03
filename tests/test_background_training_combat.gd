extends "res://tests/test_case.gd"

## Real adapters and canonical authority/codecs; the disclosed writer refuses
## disk writes. These checks claim neither played combat nor owner-save ACKs.
const FIXTURE := preload("res://tests/test_foundation_retry_admission.gd")
const DATA := preload("res://tests/test_foundation_resources.gd")
const RESEARCH := preload("res://scripts/creatures/research_actions.gd")
const BOUNTY := preload("res://scripts/world/bounty_host_adapter.gd")
const BOARD_TEST := preload("res://tests/test_bounty_board.gd")
const ACTIONS := preload("res://scripts/net/character_action_rules.gd")
const DELIVERY := preload("res://scripts/net/character_action_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const WORLD := preload("res://autoload/world_state.gd")

class Source extends RefCounted:
	var context: Dictionary
	var event: Dictionary = {}
	func actual_context(_peer: int) -> Dictionary: return context.duplicate(true)
	func accepted_event(_peer: int, token: String) -> Dictionary:
		return event.duplicate(true) if token == "original-host-event" else {}

class MissingCombatSession extends Node:
	var fixture: Node
	var _character_authority: RefCounted
	func is_host() -> bool: return true
	func _game() -> Node: return fixture
	func _authority_character(_peer: int) -> String: return DATA.CHARACTER
	func admitted_character_state(_peer: int) -> Dictionary:
		return _character_authority.call("actor_stat_state", DATA.CHARACTER)

class MalformedCombatSession extends MissingCombatSession:
	func _altar_peer_in_combat(_peer: int) -> Variant: return "false"

func _fixture(before: Dictionary = {}) -> Dictionary:
	var helper := FIXTURE.new()
	var fixture := helper._research_fixture(DATA.new()._before() if before.is_empty() else before)
	assert_eq(helper.failures, [], "fixture passes canonical admission")
	return fixture

func _free(fixture: Dictionary) -> void:
	fixture.session.free()
	fixture.game.free()

func _research_event(id: String = "combat-fresh") -> Dictionary:
	return FIXTURE.new()._research_context(id, "sight")

func _source(fixture: Dictionary) -> Source:
	var source := Source.new()
	source.context = BOARD_TEST.new()._context(fixture.authority.state(DATA.CHARACTER),
		fixture.authority.revision(DATA.CHARACTER), 1, fixture.world.reward_delivery_namespace)
	return source

func _adapter(fixture: Dictionary, source: Source) -> Node:
	var adapter := BOUNTY.new()
	assert_true(adapter.configure(fixture.session, source.actual_context, source.accepted_event))
	return adapter

func _pending(fixture: Dictionary, action: String, context: Dictionary) -> Dictionary:
	var before: Dictionary = fixture.authority.state(DATA.CHARACTER)
	var exact := context.duplicate(true)
	exact.character_id = DATA.CHARACTER
	exact.expected_revision = fixture.authority.revision(DATA.CHARACTER)
	exact.in_range = true
	var proposal := ACTIONS.stage(before, int(exact.expected_revision), action, {}, exact, RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true: return {}
	proposal.character_revision = int(exact.expected_revision) + 1
	var row := DELIVERY.make_record(fixture.world.world_id, fixture.world.reward_delivery_namespace,
		"resource-epoch", proposal, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty(): return {}
	assert_true(WORLD.training_row_valid(row, fixture.world.reward_delivery_namespace, fixture.world.world_id))
	assert_true(fixture.authority.refresh_host_local(proposal.state, DATA.CHARACTER).get("ok") == true)
	fixture.world.reward_deliveries[row.delivery_id] = row
	return row

func test_research_fresh_waits_for_combat_then_retries_same_event() -> void:
	var fixture := _fixture()
	var before: Dictionary = fixture.authority.state(DATA.CHARACTER)
	var event := _research_event()
	fixture.session.fighting = true
	assert_eq(RESEARCH.commit(fixture.session, 1, "research_event", {}, event).get("code"), "combat_still_active")
	assert_true(fixture.writer.proposals.is_empty())
	assert_true(fixture.world.reward_deliveries.is_empty())
	assert_eq(fixture.authority.state(DATA.CHARACTER), before)
	fixture.session.fighting = false
	assert_eq(RESEARCH.commit(fixture.session, 1, "research_event", {}, event).get("code"), "fixture_no_write")
	assert_eq(fixture.writer.proposals.size(), 1)
	assert_eq(fixture.authority.state(DATA.CHARACTER), before, "failed writer retains original baseline")
	_free(fixture)

func test_research_pending_and_accepted_receipt_precede_combat_deferral() -> void:
	var fixture := _fixture()
	var event := _research_event("combat-original")
	var row := _pending(fixture, "research_event", event)
	if row.is_empty():
		_free(fixture)
		return
	var original := var_to_bytes(row)
	fixture.session.fighting = true
	var result := RESEARCH.commit(fixture.session, 1, "research_event", {}, event)
	assert_true(result.get("ok") == true and result.get("durable") == true)
	assert_false(result.get("resolved") == true)
	assert_eq(fixture.writer.rows.size(), 1)
	if fixture.writer.rows.size() == 1: assert_eq(var_to_bytes(fixture.writer.rows[0]), original)
	assert_eq(var_to_bytes(row), original)
	assert_true(fixture.writer.proposals.is_empty())
	row.status = "accepted"
	result = RESEARCH.commit(fixture.session, 1, "research_event", {}, event)
	assert_true(result.get("resolved") == true)
	assert_eq(fixture.writer.rows.size(), 1)
	assert_eq(RESEARCH.commit(fixture.session, 1, "research_event", {}, _research_event("other-sight")).get("code"), "research_no_progress")
	_free(fixture)

func test_research_missing_or_malformed_combat_witness_refuses_fresh() -> void:
	for malformed: bool in [false, true]:
		var fixture := _fixture()
		var session: MissingCombatSession = MalformedCombatSession.new() if malformed else MissingCombatSession.new()
		session.fixture = fixture.game
		session._character_authority = fixture.authority
		fixture.session.remove_child(fixture.writer)
		session.add_child(fixture.writer)
		fixture.session.free()
		fixture.session = session
		fixture.game.session = session
		assert_eq(RESEARCH.commit(session, 1, "research_event", {}, _research_event()).get("code"), "research_combat_state_unavailable")
		assert_true(fixture.writer.proposals.is_empty())
		_free(fixture)

func test_bounty_rotation_fresh_waits_and_original_pending_redelivers_in_combat() -> void:
	var fixture := _fixture()
	var source := _source(fixture)
	var adapter := _adapter(fixture, source)
	source.context.in_combat = true
	assert_eq(adapter.call("morning", 1).get("code"), "combat_still_active")
	assert_true(fixture.writer.proposals.is_empty())
	assert_true(fixture.world.reward_deliveries.is_empty())
	source.context.in_combat = false
	assert_eq(adapter.call("morning", 1).get("code"), "fixture_no_write")
	assert_eq(fixture.writer.proposals.size(), 1)
	var row := _pending(fixture, "bounty_rotate", source.context)
	if not row.is_empty():
		var original := var_to_bytes(row)
		source.context.expected_revision = fixture.authority.revision(DATA.CHARACTER)
		source.context.in_combat = true
		var result: Dictionary = adapter.call("morning", 1)
		assert_eq(result.get("code"), "awaiting_saved_decision")
		assert_false(result.get("ok") == true or result.get("resolved") == true)
		assert_eq(fixture.writer.rows.size(), 1)
		if fixture.writer.rows.size() == 1: assert_eq(var_to_bytes(fixture.writer.rows[0]), original)
		assert_eq(var_to_bytes(row), original)
		row.status = "accepted"
		assert_eq(adapter.call("morning", 1).get("code"), "morning_already_seen")
		assert_eq(fixture.writer.rows.size(), 1)
	adapter.free()
	_free(fixture)

func test_bounty_event_authenticated_scope_combat_and_postbattle_retry() -> void:
	var before: Dictionary = BOARD_TEST.new()._issued()
	before.character_id = DATA.CHARACTER
	before.redesign_character.bounties.anchor_world = "resource-namespace"
	var fixture := _fixture(before)
	var source := _source(fixture)
	source.event = {"event_confirmed": true, "character_id": DATA.CHARACTER,
		"world_namespace": "resource-namespace", "event_id": "actual-catch", "kind": "catch_trait", "biome": "meadows",
		"traits": ["bold"], "participants": [DATA.CHARACTER], "issued_instances": ["catch".sha256_text()]}
	var adapter := _adapter(fixture, source)
	source.context.in_combat = true
	assert_eq(adapter.call("confirmed_event", 1, "original-host-event").get("code"), "combat_still_active")
	assert_true(fixture.writer.proposals.is_empty())
	assert_eq(adapter.call("confirmed_event", 1, "owner-claim").get("code"), "accepted_host_event_required")
	source.event.character_id = "foreign-character"
	assert_eq(adapter.call("confirmed_event", 1, "original-host-event").get("code"), "accepted_host_event_required")
	source.event.character_id = DATA.CHARACTER
	source.event.world_namespace = "foreign-world"
	assert_eq(adapter.call("confirmed_event", 1, "original-host-event").get("code"), "accepted_host_event_required")
	source.event.world_namespace = "resource-namespace"
	source.context.world_namespace = "foreign-world"
	assert_eq(adapter.call("morning", 1).get("code"), "host_morning_required")
	source.context.world_namespace = "resource-namespace"
	source.context.expected_revision = 99
	assert_eq(adapter.call("morning", 1).get("code"), "host_morning_required")
	source.context.expected_revision = fixture.authority.revision(DATA.CHARACTER)
	source.context.in_combat = false
	assert_eq(adapter.call("confirmed_event", 1, "original-host-event").get("code"), "fixture_no_write")
	assert_eq(fixture.writer.proposals.size(), 1)
	assert_eq(fixture.authority.state(DATA.CHARACTER), before)
	var context := source.context.duplicate(true)
	context.merge(source.event, true)
	context.source_key = "halda_bounty_event"
	var row := _pending(fixture, "bounty_event", context)
	if not row.is_empty():
		var original := var_to_bytes(row)
		source.context.expected_revision = fixture.authority.revision(DATA.CHARACTER)
		source.context.in_combat = true
		assert_eq(adapter.call("confirmed_event", 1, "original-host-event").get("code"), "awaiting_saved_decision")
		assert_eq(fixture.writer.rows.size(), 1)
		if fixture.writer.rows.size() == 1: assert_eq(var_to_bytes(fixture.writer.rows[0]), original)
		assert_eq(var_to_bytes(row), original)
		row.status = "accepted"
		assert_eq(adapter.call("confirmed_event", 1, "original-host-event").get("code"), "no_matching_bounty")
		assert_eq(fixture.writer.rows.size(), 1)
	adapter.free()
	_free(fixture)

func test_bounty_pending_other_action_is_exact_and_never_claims_fresh_bounty() -> void:
	var fixture := _fixture()
	var row := _pending(fixture, "research_event", _research_event("other-pending"))
	var source := _source(fixture)
	var adapter := _adapter(fixture, source)
	source.context.in_combat = true
	if not row.is_empty():
		var original := var_to_bytes(row)
		var result: Dictionary = adapter.call("morning", 1)
		assert_false(result.get("ok") == true or result.get("resolved") == true)
		assert_eq(result.get("code"), "awaiting_saved_decision")
		assert_eq(fixture.writer.rows.size(), 1)
		if fixture.writer.rows.size() == 1: assert_eq(var_to_bytes(fixture.writer.rows[0]), original)
		assert_eq(var_to_bytes(row), original)
		assert_true(fixture.writer.proposals.is_empty())
		row.host_context.world_namespace = "foreign-world"
		assert_false(WORLD.training_row_valid(row, fixture.world.reward_delivery_namespace, fixture.world.world_id))
		adapter.call("morning", 1)
		assert_eq(fixture.writer.rows.size(), 1, "invalid original cannot be redelivered")
	adapter.free()
	_free(fixture)

func test_bounty_missing_or_nonboolean_combat_witness_refuses_fresh() -> void:
	var fixture := _fixture()
	var source := _source(fixture)
	var adapter := _adapter(fixture, source)
	for invalid: Variant in [null, "false", 0]:
		if invalid == null: source.context.erase("in_combat")
		else: source.context.in_combat = invalid
		assert_eq(adapter.call("morning", 1).get("code"), "bounty_combat_state_unavailable")
	assert_true(fixture.writer.proposals.is_empty())
	assert_true(fixture.world.reward_deliveries.is_empty())
	adapter.free()
	_free(fixture)
