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


## F18 #4 (render 37334299323: gate stale_sample_1591ms): a guest's sample
## travels just ahead of its request, and the host's own save/admission work
## while handling that request must not age it out. Freshness is judged at
## the request's arrival; with no request it is judged now, as before.
func test_sample_freshness_is_judged_at_the_request_arrival() -> void:
	var LIFECYCLE := preload("res://scripts/net/foundation_travel_lifecycle.gd")
	var now := Time.get_ticks_msec()
	var observation := {"sample": {}, "seen_at": now - 1591}
	assert_false(LIFECYCLE.sample_fresh(observation), "1.6 s old against now: stale")
	assert_true(LIFECYCLE.sample_fresh(observation, now - 1590), "fresh at the request's arrival a moment after it")
	assert_false(LIFECYCLE.sample_fresh(observation, now - 1591 + 1100), "a request arriving over a second later still sees it stale")
	assert_false(LIFECYCLE.sample_fresh({"sample": {}, "seen_at": now}, now - 5), "a sample after the request does not vouch for it")


class PairingWorld extends RefCounted:
	var reward_delivery_namespace := "world_a"

class PairingGame extends Node:
	var world := PairingWorld.new()

class PairingSession extends Node:
	var game := PairingGame.new()
	func is_host() -> bool: return true
	func _authority_character(_peer: int) -> String: return "guest_a"
	func _altar_current_epoch() -> String: return "epoch_a"
	func _game() -> Node: return game
	func admitted_character_state(_peer: int) -> Dictionary: return {"character_id": "guest_a"}

func _pairing_sample(sequence: int, damage_revision: int = 0) -> Dictionary:
	return {"character_id": "guest_a", "world_instance_id": "world_a", "session_epoch": "epoch_a", "realm": "meadows",
		"damage_revision": damage_revision, "dialogue": false, "cutscene": false, "swimming": false, "flying": false,
		"downed": false, "station_ack_only": false, "ending_owner": true, "party_revision": 1,
		"party_signature": "a".repeat(64), "sequence": sequence}

## f20 render f20-fix-b (090fff3f): the guest's sample and its regional_ack
## landed a slow (~1 s) host frame apart, and the host judged the request's
## own sample stale ("stale_sample_1086ms last_refused=none") and refused the
## acknowledgement terminally. A request is judged at its paired sample.
func test_a_request_is_judged_at_its_paired_sample_a_slow_frame_later() -> void:
	var owner := PairingSession.new()
	var composition := Node.new()
	var lifecycle: Node = LIFECYCLE.new()
	owner.add_child(composition)
	composition.add_child(lifecycle)
	lifecycle.accept(2, _pairing_sample(1))
	var observation: Dictionary = lifecycle._observations.get(2, {})
	assert_false(observation.is_empty(), "the fixture sample is accepted")
	assert_true(lifecycle.has_method("take_paired_arrival"), "the host pairs a request with its sample")
	if not lifecycle.has_method("take_paired_arrival"):
		owner.free()
		return
	var slow_frame: int = int(observation.get("seen_at", 0)) + 1100
	var judged_at: int = lifecycle.take_paired_arrival(2, slow_frame)
	assert_eq(judged_at, int(observation.get("seen_at", -1)), "the request is judged at its sample's arrival")
	assert_true(LIFECYCLE.sample_fresh(observation, judged_at), "its own sample is fresh for it")
	assert_eq(lifecycle.take_paired_arrival(2, slow_frame), slow_frame, "a second request without a new sample is judged now")
	assert_false(LIFECYCLE.sample_fresh(observation, slow_frame), "and the old sample is stale for it")
	lifecycle.accept(2, _pairing_sample(2))
	lifecycle.accept(2, _pairing_sample(2))
	assert_eq(lifecycle.take_paired_arrival(2, slow_frame), slow_frame, "a refused last sample pairs nothing")
	owner.free()


## F18 #4 (render 37338210735: gate ending_fields party_decode): the host
## rebuilds a guest's party from its portable record, which deliberately
## drops each card's in-fight energy (character_record_rules, 187a3f24). The
## capture codec's card schema still carries energy, so every card failed to
## decode and every guest homecoming was refused.
func test_ending_fields_decode_the_portable_party_without_its_energy() -> void:
	var LIFECYCLE := preload("res://scripts/net/foundation_travel_lifecycle.gd")
	var HOME := preload("res://scripts/story/regional_homecoming.gd")
	var game := preload("res://autoload/game_state.gd").new()
	game.reset_for_new_game()
	game.local.character_id = "character-portable"
	for index in 5:
		var species: String = ["terrapup", "brooktail", "mosshell", "bramblebun", "trailpup"][index]
		assert_true(game.party.call("add", game.local.call("make_creature", species, "P%d" % index)))
	var personal: Dictionary = preload("res://scripts/net/character_record_rules.gd").portable_projection(game.local.save_data())
	assert_false((personal.party[0] as Dictionary).has("energy"), "the portable record carries no energy")
	var outcome := "stormwood:legendary_answer:f20_fixture:refused"
	var world := "world-portable"
	personal.redesign_character.transaction_receipts.append("starter_choice:character-portable:" + str(personal.party[0].uid))
	personal.redesign_character.transaction_receipts.append(HOME.return_prefix(world, outcome) + "travel:x:character-portable")
	var flags := {"stormwood:legendary_ceremony_settled": true, outcome: true}
	var sample := {"character_id": "character-portable", "world_instance_id": world, "session_epoch": "epoch",
		"party_revision": 5, "party_signature": HOME.party_signature(game.party), "party_identity": HOME.party_identity_signature(game.party)}
	var fields: Dictionary = LIFECYCLE.ending_fields(personal, flags, sample)
	assert_false(fields.is_empty(), "the guest's own five decode: " + LIFECYCLE.ending_fields_refusal)
	assert_eq(fields.get("party_signature"), sample.party_signature)
	sample.party_identity = "0".repeat(64)
	assert_true(LIFECYCLE.ending_fields(personal, flags, sample).is_empty(), "another party is still refused")
	game.free()

func test_lifecycle_publish_skips_a_host_link_that_is_disconnecting() -> void:
	# smoke_net_f20_ending (render f18-f20-ending-fix3): a guest dropping its
	# link sent a lifecycle sample after its graceful disconnect began, and
	# the engine refused it ("Unable to send packet ... max channels: 0").
	assert_true(LIFECYCLE.host_link_open(null), "no ENet transport: the session decides")
	var server := ENetMultiplayerPeer.new()
	var client := ENetMultiplayerPeer.new()
	var port := 39000 + randi() % 2000
	assert_eq(server.create_server(port), OK)
	assert_eq(client.create_client("127.0.0.1", port), OK)
	for i in 200:
		server.poll()
		client.poll()
		if client.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED: break
		OS.delay_msec(5)
	assert_eq(client.get_connection_status(), MultiplayerPeer.CONNECTION_CONNECTED)
	assert_true(LIFECYCLE.host_link_open(client), "a connected host link publishes")
	client.get_peer(1).peer_disconnect()
	assert_eq(client.get_connection_status(), MultiplayerPeer.CONNECTION_CONNECTED, "the status has not caught up yet")
	assert_false(LIFECYCLE.host_link_open(client), "a disconnecting host link does not")
	client.close()
	assert_false(LIFECYCLE.host_link_open(client), "a closed transport does not")
	server.close()
