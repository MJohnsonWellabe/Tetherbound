extends "res://tests/test_case.gd"

## Real retry scan and canonical event/delivery codecs with counted admission
## seams and explicit no-write recorders. Research runs the real adapter and
## authority; mastery uses a refusing seam. No played combat, disk write or
## owner ACK is claimed. Pending work must redeliver its exact original row.
const DATA := preload("res://tests/test_foundation_resources.gd")
const MASTERY := preload("res://tests/test_combat_mastery_delivery.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const DELIVERY := preload("res://scripts/net/foundation_delivery.gd")
const ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const RESEARCH := preload("res://scripts/creatures/research_log.gd")
const CHARACTER_ACTIONS := preload("res://scripts/net/character_action_rules.gd")
const CHARACTER_DELIVERY := preload("res://scripts/net/character_action_delivery.gd")

class FixtureGame extends Node:
	var world: RefCounted
	var session: Node
	var save_system: RefCounted

class DeliveryRecorder extends Node:
	var rows: Array[Dictionary] = []
	func _process_creature_training(row: Dictionary) -> void:
		rows.append(row.duplicate(true))

class CountedSession extends "res://scripts/net/session.gd":
	var fixture: Node
	var fixture_root: Node
	var fighting := false
	var admission_calls := 0
	func _game() -> Node: return fixture
	func is_host() -> bool: return true
	func _retry_combat_mastery_sources() -> void: pass
	func _foundation_realm_roots() -> Array[Node]:
		var roots: Array[Node] = []
		if fixture_root != null: roots.append(fixture_root)
		return roots
	func local_peer_id() -> int: return 1
	func _altar_peer_in_combat(peer: int) -> bool:
		return super._altar_peer_in_combat(peer) if fixture_root != null else fighting
	func admitted_character_state(_peer: int) -> Dictionary:
		admission_calls += 1
		return {} # Named seam: real scan still must consult it for eligible work.

class ResearchSaver extends RefCounted:
	func finish_fallback() -> void: pass
	func fallback_busy() -> bool: return false

class ResearchRecorder extends DeliveryRecorder:
	var proposals: Array[Dictionary] = []
	func journal_creature_training_prepared(_peer: int, _character: String, accepted: Dictionary) -> Dictionary:
		proposals.append(accepted.duplicate(true))
		return {"ok": false, "durable": false, "code": "fixture_no_write"}
	func publish_creature_training(_peer: int, _character: String, _receipt: String) -> bool: return false

class ResearchSession extends CountedSession:
	# Counted admission seam over the real authority. An optional valid local
	# refresh models a revision change during admission; it grants no reward.
	var refresh_at_admission := 0
	var refresh_record := {}
	var refresh_result := {}
	func _authority_character(peer: int) -> String:
		return str(get("_registry").call("row", peer).get("character_id", ""))
	func admitted_character_state(peer: int) -> Dictionary:
		admission_calls += 1
		var authority: RefCounted = get("_character_authority")
		var character := _authority_character(peer)
		if admission_calls == refresh_at_admission:
			refresh_result = authority.call("refresh_host_local", refresh_record, character)
		return authority.call("actor_stat_state", character)

func _saturated_research_record() -> Dictionary:
	# Explicit detached history, not an earned player-path witness.
	var before: Dictionary = DATA.new()._before()
	before.redesign_character.research = RESEARCH.empty_log()
	before.redesign_character.research.species.terrapup = {
		"seen": true, "caught": false, "tasks": {"sight": 1, "casts": 3}}
	return before

func _research_fixture(before: Dictionary) -> Dictionary:
	var game := FixtureGame.new()
	game.world = DATA.new()._world()
	game.save_system = ResearchSaver.new()
	var session := ResearchSession.new()
	session.fixture = game
	game.session = session
	var writer := ResearchRecorder.new()
	writer.name = "LedgerRpc"
	session.add_child(writer)
	var authority := preload("res://scripts/net/character_authority.gd").new()
	assert_true(authority.bind_world(game.world.reward_delivery_namespace))
	assert_true(authority.seed_admitted_character(before, DATA.CHARACTER).get("ok") == true)
	session.set("_character_authority", authority)
	session.get("_registry").call("add", 1, DATA.CHARACTER)
	return {"game": game, "session": session, "world": game.world, "writer": writer, "authority": authority}

func _free_research_fixture(fixture: Dictionary) -> void:
	fixture.session.free()
	fixture.game.free()

func _research_context(event_id: String, kind: String, move_id: String = "pebble_toss") -> Dictionary:
	var context := {"source_key": "encounter:retry-fixture", "event_confirmed": true,
		"world_namespace": "resource-namespace", "session_id": "resource-epoch", "event_id": event_id,
		"participants": [DATA.CHARACTER], "species_id": "terrapup", "kind": kind}
	if kind == "cast": context.move_id = move_id
	if kind == "catch":
		context.wild = true
		context.night = false
	if kind == "defeat": context.opponent_defeated = true
	return context

func _append_research_event(fixture: Dictionary, event_id: String, kind: String = "cast", move_id: String = "pebble_toss") -> Dictionary:
	var duty := {"character_id": DATA.CHARACTER, "action": "research_event", "intent": {},
		"context": _research_context(event_id, kind, move_id)}
	var event := EVENT.make(fixture.world, "resource-epoch", event_id, [duty])
	assert_false(event.is_empty())
	if not event.is_empty(): fixture.world.reward_deliveries[event.delivery_id] = event
	return event

func test_retry_saturated_casts_bound_admission_without_starving_later_catch() -> void:
	var before := _saturated_research_record()
	var fixture := _research_fixture(before)
	for index: int in 116: _append_research_event(fixture, "saturated-cast-%d" % index)
	_append_research_event(fixture, "eligible-catch", "catch")
	var originals := var_to_bytes(fixture.world.reward_deliveries)
	fixture.session._retry_foundation_events()
	assert_eq(fixture.session.admission_calls, 4, "one saturated bucket and the later catch each perform both real adapter admissions")
	assert_eq(fixture.writer.proposals.size(), 1, "a different kind must still reach the canonical writer")
	if fixture.writer.proposals.size() == 1:
		assert_true(fixture.writer.proposals[0].state.redesign_character.research.species.terrapup.caught)
	assert_eq(fixture.authority.state(DATA.CHARACTER), before, "the explicit failed writer rolls back the eligible candidate")
	assert_eq(var_to_bytes(fixture.world.reward_deliveries), originals, "no original is acknowledged or rewritten")
	_free_research_fixture(fixture)

func test_retry_saturated_cast_bucket_keeps_different_move_signature_progress() -> void:
	var fixture := _research_fixture(_saturated_research_record())
	_append_research_event(fixture, "ordinary-cast-1")
	_append_research_event(fixture, "ordinary-cast-2")
	_append_research_event(fixture, "signature-cast", "cast", "stone_rush")
	fixture.session._retry_foundation_events()
	assert_eq(fixture.session.admission_calls, 4)
	assert_eq(fixture.writer.proposals.size(), 1, "saturated ordinary casts cannot hide the actual signature move")
	if fixture.writer.proposals.size() == 1:
		assert_eq(fixture.writer.proposals[0].state.redesign_character.research.species.terrapup.tasks.signature, 1)
	_free_research_fixture(fixture)

func test_retry_no_progress_uses_post_admission_revision_and_each_scan_admits_fresh() -> void:
	var before := _saturated_research_record()
	var fixture := _research_fixture(before)
	_append_research_event(fixture, "post-admission-cast-1")
	_append_research_event(fixture, "post-admission-cast-2")
	var refreshed := before.duplicate(true)
	refreshed.redesign_character.research.species.terrapup.caught = true
	fixture.session.refresh_at_admission = 2
	fixture.session.refresh_record = refreshed
	fixture.session._retry_foundation_events()
	assert_true(fixture.session.refresh_result.get("ok") == true)
	assert_eq(fixture.authority.revision(DATA.CHARACTER), 1)
	assert_eq(fixture.session.admission_calls, 2, "memo records the revision after the adapter's second fresh admission")
	fixture.session._retry_foundation_events()
	assert_eq(fixture.session.admission_calls, 4, "a new scan cannot reuse the previous no-progress observation")
	assert_true(fixture.writer.proposals.is_empty())
	_free_research_fixture(fixture)

func test_retry_revision_change_rechecks_previously_saturated_semantics() -> void:
	var before := _saturated_research_record()
	var fixture := _research_fixture(before)
	_append_research_event(fixture, "before-revision-cast")
	_append_research_event(fixture, "revision-trigger-sight", "sight")
	_append_research_event(fixture, "after-revision-cast")
	var refreshed := before.duplicate(true)
	refreshed.redesign_character.research.species.terrapup.tasks.casts = 2
	fixture.session.refresh_at_admission = 3
	fixture.session.refresh_record = refreshed
	fixture.session._retry_foundation_events()
	assert_true(fixture.session.refresh_result.get("ok") == true)
	assert_eq(fixture.session.admission_calls, 6, "a different-kind admission changes revision, invalidating the earlier cast exclusion")
	assert_eq(fixture.writer.proposals.size(), 1)
	if fixture.writer.proposals.size() == 1:
		assert_eq(fixture.writer.proposals[0].expected_character_revision, 1)
		assert_eq(fixture.writer.proposals[0].state.redesign_character.research.species.terrapup.tasks.casts, 3)
	assert_eq(fixture.authority.revision(DATA.CHARACTER), 1, "failed world writer does not retain its hidden promotion")
	_free_research_fixture(fixture)

func test_retry_invalid_original_cannot_enter_no_progress_bucket() -> void:
	var fixture := _research_fixture(_saturated_research_record())
	var forged := _append_research_event(fixture, "forged-cast")
	forged.duties[0].context.event_confirmed = false
	assert_false(EVENT.valid(forged, fixture.world.reward_delivery_namespace, fixture.world.world_id))
	_append_research_event(fixture, "valid-cast-1")
	_append_research_event(fixture, "valid-cast-2")
	var originals := var_to_bytes(fixture.world.reward_deliveries)
	fixture.session._retry_foundation_events()
	assert_eq(fixture.session.admission_calls, 2, "invalid provenance is rejected before admission; valid originals still check freshly")
	assert_true(fixture.writer.proposals.is_empty())
	assert_eq(var_to_bytes(fixture.world.reward_deliveries), originals)
	_free_research_fixture(fixture)

func test_retry_pending_receipt_redelivers_original_before_no_progress_exclusion() -> void:
	var before := _saturated_research_record()
	before.redesign_character.research.species.terrapup.tasks.casts = 2
	var fixture := _research_fixture(before)
	var retained := EVENT.make(fixture.world, "resource-epoch", "pending-third-cast", [{
		"character_id": DATA.CHARACTER, "action": "research_event", "intent": {},
		"context": _research_context("pending-third-cast", "cast")}])
	assert_false(retained.is_empty())
	var context: Dictionary = retained.duties[0].context.duplicate(true)
	context.character_id = DATA.CHARACTER
	context.expected_revision = 0
	context.in_range = true
	context.retained_event = retained.delivery_id
	var proposal := CHARACTER_ACTIONS.stage(before, 0, "research_event", {}, context, RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") != true:
		_free_research_fixture(fixture)
		return
	proposal.character_revision = 1
	var row := CHARACTER_DELIVERY.make_record(fixture.world.world_id, fixture.world.reward_delivery_namespace,
		"resource-epoch", proposal, null, RECORD.errors)
	assert_false(row.is_empty())
	if row.is_empty():
		_free_research_fixture(fixture)
		return
	assert_true(fixture.authority.refresh_host_local(proposal.state, DATA.CHARACTER).get("ok") == true)
	_append_research_event(fixture, "unreceipted-saturated-cast")
	fixture.world.reward_deliveries[retained.delivery_id] = retained
	fixture.world.reward_deliveries[row.delivery_id] = row
	var originals := var_to_bytes(fixture.world.reward_deliveries)
	var pending := var_to_bytes(row)
	fixture.session._retry_foundation_events()
	assert_eq(fixture.session.admission_calls, 2)
	assert_eq(fixture.writer.rows.size(), 1, "the same semantic bucket still redelivers a retained pending receipt")
	if fixture.writer.rows.size() == 1: assert_eq(var_to_bytes(fixture.writer.rows[0]), pending)
	assert_true(fixture.writer.proposals.is_empty(), "retry never prepares a substitute for the pending original")
	assert_eq(var_to_bytes(fixture.world.reward_deliveries), originals)
	row.status = "accepted"
	fixture.session._retry_foundation_events()
	assert_eq(fixture.session.admission_calls, 4, "only the unreceipted bucket freshly admits in the next scan")
	assert_eq(fixture.writer.rows.size(), 1, "accepted receipt adds no redelivery")
	assert_eq(fixture.world.reward_deliveries[row.delivery_id], row)
	_free_research_fixture(fixture)

func test_retry_skips_fighting_and_accepted_duties_before_projection_but_admits_pending() -> void:
	var before: Dictionary = DATA.new()._before()
	var world: RefCounted = DATA.new()._world()
	var helper := MASTERY.new()
	var duty: Dictionary = helper._duty(before)
	var event := EVENT.make(world, "resource-epoch", "mastery:" + MASTERY.ACTION_ID, [duty])
	assert_false(event.is_empty())
	world.reward_deliveries[event.delivery_id] = event
	var game := FixtureGame.new()
	game.world = world
	var session := CountedSession.new()
	session.fixture = game
	var redelivery := DeliveryRecorder.new()
	redelivery.name = "LedgerRpc"
	session.add_child(redelivery)
	session.set("_character_authority", preload("res://scripts/net/character_authority.gd").new())
	var peers: RefCounted = session.get("_registry")
	peers.call("add", 1, DATA.CHARACTER)
	var original := var_to_bytes(event)
	session.fighting = true
	session._retry_foundation_events()
	assert_eq(session.admission_calls, 0, "in-fight mastery is already deferred, so no full save projection is needed")
	session.fighting = false
	session._retry_foundation_events()
	assert_eq(session.admission_calls, 1, "eligible retained duty must still perform fresh authority admission")
	var proposal := ACTIONS.stage(before, 0, "combat_mastery", duty.intent, helper._context(duty, event), RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") == true:
		proposal.character_revision = 1
		var delivery := DELIVERY.make_record(world.world_id, world.reward_delivery_namespace, "resource-epoch", proposal, null, RECORD.errors)
		assert_false(delivery.is_empty())
		if not delivery.is_empty():
			delivery.status = "accepted"
			assert_true(DELIVERY.valid(delivery, RECORD.errors))
			world.reward_deliveries[delivery.delivery_id] = delivery
			session._retry_foundation_events()
			assert_eq(session.admission_calls, 1, "actual accepted receipt skips repeated save projection")
			assert_true(redelivery.rows.is_empty(), "an accepted row requires no owner redelivery")
			delivery.status = "pending"
			var pending_bytes := var_to_bytes(delivery)
			session._retry_foundation_events()
			assert_eq(redelivery.rows.size(), 1, "pending owner ACK must invoke actual original-row redelivery")
			if redelivery.rows.size() == 1:
				assert_eq(var_to_bytes(redelivery.rows[0]), pending_bytes, "retry cannot substitute a newly prepared row")
			assert_eq(var_to_bytes(world.reward_deliveries[delivery.delivery_id]), pending_bytes)
			assert_eq(session.admission_calls, 1, "original pending row needs redelivery, not a new baseline admission")
	assert_eq(var_to_bytes(world.reward_deliveries[event.delivery_id]), original, "original obligations stay immutable")
	session.free()
	game.free()

func test_trainer_send_out_gap_defers_mastery_and_preserves_original_pending_delivery() -> void:
	# Detached real manager/director/arbiter with explicit inter-round state;
	# this exercises scheduling, not played combat or earned mastery.
	var before: Dictionary = DATA.new()._before()
	var world: RefCounted = DATA.new()._world()
	var helper := MASTERY.new()
	var duty: Dictionary = helper._duty(before)
	var event := EVENT.make(world, "resource-epoch", "mastery:" + MASTERY.ACTION_ID, [duty])
	assert_false(event.is_empty())
	world.reward_deliveries[event.delivery_id] = event
	var original_event := var_to_bytes(event)
	var game := FixtureGame.new()
	game.world = world
	var session := CountedSession.new()
	session.fixture = game
	session.set("_character_authority", preload("res://scripts/net/character_authority.gd").new())
	var peers: RefCounted = session.get("_registry")
	peers.call("add", 2, DATA.CHARACTER)
	var redelivery := DeliveryRecorder.new()
	redelivery.name = "LedgerRpc"
	session.add_child(redelivery)
	var root := Node3D.new()
	session.fixture_root = root
	var manager := preload("res://scripts/combat/combat_manager.gd").new()
	root.add_child(manager)
	var director := preload("res://scripts/combat/encounter_director.gd").new()
	root.add_child(director)
	director.set("_session", session)
	director.set("_manager", manager)
	director.call("_ensure_encounter_arbiters")
	var host: RefCounted = director.get("_encounter_host")
	var round_record: Dictionary = host.call("open", 2, "meadows", "trainer",
		{"hp": 100.0, "hp_max": 100.0, "position": [2.0, 0.0, 0.0]}, before.party[0].uid, DATA.CHARACTER)
	assert_false(round_record.is_empty())
	host.call("close", round_record.encounter_id)
	director.set("_trainer_spec", {"id": "warden_aldis"})
	director.set("_trainer_battle_participants", {1: true, 2: true})
	director.set("_trainer_send_delay", 1.6)
	assert_false(manager.is_fighting(), "manager is actually inactive between rounds")
	assert_eq(host.call("phase", round_record.encounter_id), "done")
	assert_true(director.trainer_battle_active())
	assert_true(session._altar_peer_in_combat(1), "local host remains in the whole trainer battle")
	assert_true(session._altar_peer_in_combat(2), "retained guest remains in the same battle")
	assert_false(session._altar_peer_in_combat(3), "unrelated guest is not fenced by another battle")
	session._retry_foundation_events()
	assert_eq(session.admission_calls, 0, "round gap cannot prepare a new mastery row")
	assert_eq(world.reward_deliveries.size(), 1, "only the original hit obligation exists")
	var proposal := ACTIONS.stage(before, 0, "combat_mastery", duty.intent, helper._context(duty, event), RECORD.errors)
	assert_true(proposal.get("ok") == true, str(proposal))
	if proposal.get("ok") == true:
		proposal.character_revision = 1
		var delivery := DELIVERY.make_record(world.world_id, world.reward_delivery_namespace, "resource-epoch", proposal, null, RECORD.errors)
		assert_false(delivery.is_empty())
		if not delivery.is_empty():
			assert_eq(delivery.status, "pending")
			world.reward_deliveries[delivery.delivery_id] = delivery
			var original_pending := var_to_bytes(delivery)
			session._retry_foundation_events()
			assert_true(redelivery.rows.is_empty(), "existing pending row waits while the full battle is active")
			assert_eq(var_to_bytes(world.reward_deliveries[delivery.delivery_id]), original_pending)
			director.set("_trainer_spec", {})
			director.set("_trainer_battle_participants", {})
			assert_false(session._altar_peer_in_combat(2), "whole battle completion permits recovery")
			session._retry_foundation_events()
			assert_eq(redelivery.rows.size(), 1)
			if redelivery.rows.size() == 1: assert_eq(var_to_bytes(redelivery.rows[0]), original_pending)
			assert_eq(var_to_bytes(world.reward_deliveries[delivery.delivery_id]), original_pending, "retry does not acknowledge or rewrite the journal")
			assert_eq(session.admission_calls, 0, "original pending row never re-enters new-baseline admission")
	assert_eq(var_to_bytes(world.reward_deliveries[event.delivery_id]), original_event)
	root.free()
	session.free()
	game.free()
