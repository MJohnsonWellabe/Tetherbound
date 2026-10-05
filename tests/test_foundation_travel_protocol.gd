extends "res://tests/test_case.gd"

## Exercises the real permit consumer and retained arrival coordinator.
## Contact and durable writer are doubles: physical co-op/save proof is separate.
const POLICY := preload("res://scripts/net/portal_action_policy.gd")
const LIFECYCLE := preload("res://scripts/net/foundation_travel_lifecycle.gd")
const WORLD := preload("res://autoload/world_state.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")
const PASSIVE := preload("res://scripts/net/owner_passive_sync.gd")
const PREPARATION := preload("res://scripts/net/owner_passive_preparation.gd")

class GameFixture extends Node:
	var world := WORLD.new()

class SessionFixture extends Node:
	signal peer_left(peer: int)
	signal session_ended(reason: String)
	var game := GameFixture.new()
	var _portal_policy := POLICY.new()
	var _character_authority := preload("res://scripts/net/character_authority.gd").new()
	var passive: RefCounted
	var context: Dictionary = {}
	var sent: Dictionary = {}
	var reply: Dictionary = {}
	var writer_saved: bool = false
	var journal_calls: int = 0
	func is_host() -> bool: return true
	func local_peer_id() -> int: return 1
	func _game() -> Node: return game
	func _authority_character(peer: int) -> String: return "guest_a" if peer == 2 else "host_a"
	func _owner_passive_service() -> RefCounted:
		if passive == null: passive = PASSIVE.new(self)
		return passive
	func _host_portal_context(_peer: int) -> Dictionary: return context
	func _portal_envelope_valid(peer: int, envelope: Dictionary) -> bool:
		return peer == 2 and envelope.character_id == "guest_a" and envelope.session_epoch == "epoch_a"
	func send_portal_owner_permit(_producer: Node, _peer: int, envelope: Dictionary, permit: Dictionary) -> void:
		sent = {"envelope": envelope.duplicate(true), "permit": permit.duplicate(true)}
	func _portal_reply(_peer: int, _envelope: Dictionary, result: Dictionary) -> void: reply = result.duplicate(true)
	func foundation_grounded_arrival(_producer: Node, _envelope: Dictionary, _permit: Dictionary) -> Dictionary:
		journal_calls += 1
		return {"ok": writer_saved, "saved": writer_saved, "durable": true}

class ArrivalFixture extends "res://scripts/net/foundation_portal_arrival.gd":
	var actual_contact: bool = false
	func _remote_binding(_peer: int, _original: Dictionary) -> bool: return actual_contact

func _sample() -> Dictionary:
	return {"character_id": "guest_a", "world_instance_id": "world_a", "session_epoch": "epoch_a",
		"realm": "meadows", "sequence": 1, "damage_revision": 0, "dialogue": false,
		"cutscene": false, "swimming": false, "flying": false, "downed": false,
		"ending_owner": false, "station_ack_only": false, "party_revision": 0, "party_signature": "[]".sha256_text()}

func test_lifecycle_has_no_action_or_coordinates_and_requires_every_observation() -> void:
	var sample := _sample()
	assert_true(LIFECYCLE.valid_sample(sample))
	sample.position = Vector3.ZERO
	assert_false(LIFECYCLE.valid_sample(sample))
	sample = _sample()
	sample.erase("downed")
	assert_false(LIFECYCLE.valid_sample(sample))
	sample = _sample()
	sample.sequence = 0
	assert_false(LIFECYCLE.valid_sample(sample))
	sample = _sample()
	sample.damage_revision = -1
	assert_false(LIFECYCLE.valid_sample(sample))

func test_local_swimming_observation_matches_actual_realm_controller_lifecycle() -> void:
	for realm: String in ["meadows", "cloudreach", "stormwood"]:
		assert_eq(LIFECYCLE.swimming_observation(realm, null), {"swimming": false},
			"ordinary non-Water player has no SwimController: " + realm)
	assert_true(LIFECYCLE.swimming_observation("water", null).is_empty(), "Water cannot sample before its swimmer mounts")
	assert_true(LIFECYCLE.swimming_observation("unknown", null).is_empty())
	var swim := preload("res://scripts/player/swim_controller.gd").new()
	assert_eq(LIFECYCLE.swimming_observation("water", swim), {"swimming": false}, "installed Water observer begins on land")
	swim.state.enter_water(false, 0.0)
	assert_eq(LIFECYCLE.swimming_observation("water", swim), {"swimming": true}, "actual human swimming is observed")
	swim.state.leave_water()
	assert_eq(LIFECYCLE.swimming_observation("water", swim), {"swimming": false}, "actual return to land is observed")
	swim.free()
	var missing_observer := Node.new()
	assert_true(LIFECYCLE.swimming_observation("water", missing_observer).is_empty())
	missing_observer.free()

func test_consumed_guest_permit_survives_failed_save_and_requires_correlated_notice() -> void:
	var session := SessionFixture.new()
	session.game.world.reward_delivery_namespace = "world_a"
	session.context = {"world_instance_id": "world_a", "character_id": "guest_a", "peer_id": 2,
		"realm": "meadows", "position": Vector3.ZERO, "damage_revision": 0, "combat": false,
		"dialogue": false, "cutscene": false, "swimming": false, "flying": false, "downed": false,
		"character_unlocks": [], "world_unlocks": [], "last_waystones": {}, "waystones_activated": {},
		"arch_positions": {"home": Vector3.ZERO}}
	session._portal_policy.bind_world("world_a")
	var envelope := {"request_id": "epoch_a:44", "session_epoch": "epoch_a", "character_id": "guest_a",
		"world_instance_id": "world_a", "payload": {"kind": "portal_enter", "arch_id": "home"}}
	var result := session._portal_policy.evaluate(envelope.payload, session.context,
		DATA.json("res://data/config/portals.json"), DATA.json("res://data/config/waystones.json"), 100)
	assert_true(result.get("ok", false))
	if result.get("ok") != true:
		session.game.free()
		session.free()
		return
	var arrival := ArrivalFixture.new()
	arrival.travel(session, 2, envelope, result)
	var permit: Dictionary = session.sent.permit
	assert_true(permit.request_id != envelope.request_id)
	assert_true(session._portal_policy.consume_permit(permit.request_id, 2, "guest_a", "world_a", "meadows").is_empty())
	assert_true(arrival._remote.has(2))
	assert_false(arrival.transition_authorized(2, "meadows"), "consumed permission alone cannot substitute for the prepared origin save")
	# This consumer fixture begins after the authenticated origin BOOL grant.
	# Supply only its shipping departure predicate's exact checkpoint fields;
	# no preparation packet, disk save, or earned travel credit is fabricated.
	var passive: RefCounted = session._owner_passive_service()
	assert_true(passive.get("hosts").get("guest_a", {}).get("checkpoint", {}).is_empty())
	var request: Dictionary = PREPARATION.portal_request(envelope, permit)
	var checkpoint: Dictionary = {"source_kind": "portal_arrival", "request": request, "travel_ready": true}
	passive.get("hosts")["guest_a"] = {"checkpoint": checkpoint}
	assert_true(arrival.transition_authorized(2, "meadows"), "consumed retained host permit authorizes its destination")
	assert_false(arrival.transition_authorized(2, "stormwood"), "raw alternate destination is refused")
	assert_false(arrival.transition_authorized(3, "meadows"), "another peer cannot borrow the permit")
	checkpoint.travel_ready = false
	assert_false(arrival.transition_authorized(2, "meadows"), "unsaved origin cannot depart")
	checkpoint.travel_ready = true
	var wrong_request: Dictionary = request.duplicate(true)
	wrong_request.session_epoch = "prior_generation"
	checkpoint.request = wrong_request
	assert_false(arrival.transition_authorized(2, "meadows"), "another prepared generation cannot authorize the original permit")
	checkpoint.request = request
	arrival.owner_notice(2, envelope, envelope.request_id)
	assert_false(arrival._remote[2].owner_saved)
	var stale := envelope.duplicate(true)
	stale.session_epoch = "old_epoch"
	arrival.owner_notice(2, stale, permit.request_id)
	assert_false(arrival._remote[2].owner_saved)
	arrival.owner_notice(2, envelope, permit.request_id)
	assert_false(arrival.transition_authorized(2, "meadows"), "settled owner cannot load again on the same permit")
	arrival._process(1.0)
	assert_eq(session.journal_calls, 0) # A notice cannot substitute for contact.
	arrival.actual_contact = true
	arrival._process(1.0)
	assert_eq(session.journal_calls, 1)
	assert_true(arrival._remote.has(2))
	assert_true(session.reply.is_empty()) # Saved acceptance has not happened.
	assert_eq(arrival._remote[2].permit, permit)
	session.writer_saved = true
	arrival._process(1.0)
	assert_false(arrival._remote.has(2))
	assert_true(session.reply.saved)
	assert_eq(session.reply.permit_id, permit.request_id)
	arrival.free()
	session.game.free()
	session.free()

func test_guest_ending_fields_require_original_personal_answer_home_receipt_and_canonical_party() -> void:
	var sample := _sample()
	var personal := {"character_id": "guest_a", "party": [], "redesign_character": {"creatures": {},
		"transaction_receipts": ["starter_choice:guest_a:starter_uid", "craft:home_return_world_a_original_permit:guest_a"]}}
	var flags := {"stormwood:legendary_ceremony_settled": true,
		"stormwood:regional_outcome:original_claim:refused": true, "stormwood:legendary_answer:original_claim:refused": true}
	assert_true(LIFECYCLE.ending_fields(personal, flags, sample).is_empty(), "a home return before the finale cannot unlock the ending")
	var ending := preload("res://scripts/story/regional_homecoming.gd")
	personal.redesign_character.transaction_receipts.append(ending.return_prefix("world_a", "stormwood:legendary_answer:original_claim:refused") + "actual_home_key_permit:guest_a")
	var expected := LIFECYCLE.ending_fields(personal, flags, sample)
	assert_false(expected.is_empty())
	if expected.is_empty(): return
	assert_eq(expected.outcome_id, "stormwood:legendary_answer:original_claim:refused")
	assert_eq(expected.party_signature, "[]".sha256_text())
	var changed := sample.duplicate(true)
	changed.party_signature = "another_party".sha256_text()
	assert_true(LIFECYCLE.ending_fields(personal, flags, changed).is_empty())
	changed = sample.duplicate(true)
	changed.world_instance_id = "foreign_world"
	assert_true(LIFECYCLE.ending_fields(personal, flags, changed).is_empty())
	changed = sample.duplicate(true)
	changed.character_id = "another_character"
	assert_true(LIFECYCLE.ending_fields(personal, flags, changed).is_empty())
	var ambiguous := flags.duplicate(true)
	ambiguous["stormwood:regional_outcome:other_claim:accepted"] = true
	ambiguous["stormwood:legendary_answer:other_claim:accepted"] = true
	assert_true(LIFECYCLE.ending_fields(personal, ambiguous, sample).is_empty())
	var only_shared := {"stormwood:stormheart_freed": true}
	assert_true(LIFECYCLE.ending_fields(personal, only_shared, sample).is_empty())

func test_guest_ending_fields_tolerate_passive_landmark_drift_but_not_another_party() -> void:
	# The guest's live party keeps accruing landmarks walked together; the host's
	# copy lags until an owner-passive gate. Identity (uid, name, battles, rests,
	# feeds) still has to match; the guest's own full signature is kept.
	var ending := preload("res://scripts/story/regional_homecoming.gd")
	var personal := {"character_id": "guest_a", "party": [], "redesign_character": {"creatures": {},
		"transaction_receipts": ["starter_choice:guest_a:starter_uid",
			ending.return_prefix("world_a", "stormwood:legendary_answer:original_claim:refused") + "actual_home_key_permit:guest_a"]}}
	var flags := {"stormwood:legendary_ceremony_settled": true,
		"stormwood:regional_outcome:original_claim:refused": true, "stormwood:legendary_answer:original_claim:refused": true}
	var drifted := _sample()
	drifted.party_signature = "guest_live_party_with_one_more_landmark".sha256_text()
	drifted.party_identity = "[]".sha256_text()
	assert_true(LIFECYCLE.valid_sample(drifted))
	var expected := LIFECYCLE.ending_fields(personal, flags, drifted)
	assert_false(expected.is_empty(), "passive care drift is not another party")
	assert_eq(expected.get("party_signature"), drifted.party_signature, "the guest's own signature is what its intent carries")
	var other := drifted.duplicate(true)
	other.party_identity = "another_party".sha256_text()
	assert_true(LIFECYCLE.ending_fields(personal, flags, other).is_empty(), "a different party is still refused")
	var legacy := _sample()
	legacy.party_signature = "guest_live_party_with_one_more_landmark".sha256_text()
	assert_true(LIFECYCLE.ending_fields(personal, flags, legacy).is_empty(), "without party_identity the exact comparison stands")
	var malformed := drifted.duplicate(true)
	malformed.party_identity = "short"
	assert_false(LIFECYCLE.valid_sample(malformed))
