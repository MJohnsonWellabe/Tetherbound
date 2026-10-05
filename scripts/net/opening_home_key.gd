extends RefCounted

## Typed opening producer. Requests contain identity fences only; the host
## reads the admitted original starter and its actual Grandpa/body geometry.
## Delivery and owner durability use the existing finite reward journal.
const REWARD := preload("res://scripts/net/reward_delivery.gd")
const OPENING := preload("res://scripts/story/opening_beats.gd")
const HOME_ACTION := preload("res://scripts/net/home_key_action.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const SOURCE_SCRIPT := "res://scripts/story/sequence_director.gd"


static func envelope(character: String, world_namespace: String, epoch: String) -> Dictionary:
	return {"character_id": character, "world_instance_id": world_namespace, "session_epoch": epoch}


static func valid_envelope(raw: Dictionary, character: String, world_namespace: String, epoch: String,
		settlement: bool = false) -> bool:
	if raw.size() != (4 if settlement else 3): return false
	var expected := envelope(character, world_namespace, epoch)
	for key: String in expected:
		if not raw.get(key) is String or raw[key].is_empty() or raw[key].length() > 192 or raw[key] != expected[key]: return false
	return not settlement or (raw.get("delivery_id") is String and raw.delivery_id.length() == 64)


static func starter_uid(personal: Dictionary, flags: Dictionary) -> String:
	var character: Variant = personal.get("character_id")
	if not character is String or character.is_empty() or character.contains(":") \
		or flags.get("opening:starter_granted") != true: return ""
	var found := ""
	var prefix: String = "starter_choice:%s:" % character
	var receipts: Variant = personal.get("redesign_character", {}).get("transaction_receipts", [])
	if not receipts is Array: return ""
	for receipt: Variant in receipts:
		if not receipt is String: return ""
		if not receipt.begins_with(prefix): continue
		var uid: String = receipt.trim_prefix(prefix)
		if uid.is_empty() or uid.contains(":") or not found.is_empty(): return ""
		found = uid
	if found.is_empty() or not personal.get("party") is Array: return ""
	var matches := 0
	var species: Array = OPENING.config().get("starters", {}).get("species", [])
	for card: Variant in personal.party:
		if not card is Dictionary: return ""
		if card.get("uid") == found:
			if not species.has(card.get("species_id")): return ""
			matches += 1
	return found if matches == 1 else ""


static func valid_row(raw: Variant, world: RefCounted, character: String) -> bool:
	if not raw is Dictionary or raw.get("status") not in ["pending", "accepted"]: return false
	var expected := REWARD.make_record(world.world_id, world.reward_delivery_namespace,
		"home_key:grant:" + character, character, "home_key", 1, "home_key_given")
	if expected.is_empty(): return false
	expected.status = raw.status
	return ESSENCE._equivalent(raw, expected)


static func owner_physically_settled(player: RefCounted, id: String) -> bool:
	if player == null or player.inventory.count("home_key") != 1 or player.flags.call("has", "home_key_given") != true: return false
	var row: Variant = player.satchel_escrow.get(id)
	return row is Dictionary and row.get("kind") == "reward_delivery" and row.get("status") == "settled" \
		and row.get("character_id") == player.character_id and row.get("delivery_id") == id \
		and row.get("source") == "home_key:grant:" + str(player.character_id) \
		and REWARD.delivery_id(str(row.get("world_namespace", "")), str(row.source), str(player.character_id)) == id


static func _binding(session: Node, peer: int, request: Dictionary, settlement: bool = false) -> Dictionary:
	if session == null or session.call("is_host") != true or session.call("portal_runtime_ready") != true: return {}
	var game: Node = session.call("_game")
	if game == null or game.get("world") == null: return {}
	var world: RefCounted = game.get("world")
	var character: String = session.call("_authority_character", peer)
	if not valid_envelope(request, character, world.reward_delivery_namespace,
		str(session.call("_altar_current_epoch")), settlement): return {}
	var personal: Dictionary = session.call("admitted_character_state", peer)
	if personal.get("character_id") != character: return {}
	return {"game": game, "world": world, "character": character, "personal": personal, "request": request.duplicate(true)}


static func _opening_source(session: Node, peer: int) -> Node:
	var world_node: Node3D = session.call("_portal_world_node", "meadows")
	if world_node == null or not world_node.is_inside_tree(): return null
	var actor: CharacterBody3D
	if peer == session.call("local_peer_id"):
		if session.call("_game").get("current_realm") != "meadows": return null
		actor = session.call("_game").call("find_player") as CharacterBody3D
	else:
		var lifecycle: Node = session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
		if lifecycle == null: return null
		actor = lifecycle.call("remote_body", peer) as CharacterBody3D
		if actor == null or actor.get("net_realm") != "meadows": return null
	if actor == null or not actor.is_inside_tree() or actor.is_queued_for_deletion() \
		or not world_node.is_ancestor_of(actor) or session.call("_altar_peer_in_combat", peer) == true: return null
	var found: Node
	for candidate: Node in world_node.find_children("*", "Node", true, false):
		if candidate.get_script() == null or candidate.get_script().resource_path != SOURCE_SCRIPT: continue
		if found != null: return null # Ambiguous authored source fails closed.
		found = candidate
	if found == null or found.is_queued_for_deletion(): return null
	var grandpa: Node3D = found.get("_grandpa")
	var prompt: Node3D = found.get("_grandpa_prompt")
	if grandpa == null or prompt == null or not grandpa.is_ancestor_of(prompt) \
		or not world_node.is_ancestor_of(grandpa) or not prompt.is_inside_tree() \
		or grandpa.is_queued_for_deletion() or prompt.is_queued_for_deletion(): return null
	var radius: Variant = prompt.get("radius")
	if not (radius is float or radius is int) or not is_finite(float(radius)) or float(radius) <= 0.0 \
		or not actor.global_position.is_finite(): return null
	if actor.global_position.distance_to(prompt.global_position) <= float(radius): return found
	# The same conversation is also opened by the authored door callout: on the
	# return_starter beat, walking at the farmhouse door calls the player back
	# to Grandpa from beyond his talk radius (sequence_director
	# _refresh_door_gate). Accept exactly that authored geometry too.
	var house: Node3D = found.get("_house")
	var constants: Dictionary = (found.get_script() as Script).get_script_constant_map()
	var callout: Variant = constants.get("DOOR_CALLOUT_RADIUS")
	var callout_beats: Variant = constants.get("DOOR_CALLOUT_BEATS")
	# The host's director tracks the host's own opening. A guest's beat is its
	# own persisted opening history (sequence_director _persist_beat_history).
	var beat: Variant = found.call("beat") if peer == session.call("local_peer_id") and found.has_method("beat") \
		else peer_beat(session.call("_foundation_flags", peer))
	if not callout_beats is Array or not (callout_beats as Array).has(beat): return null
	if house == null or not world_node.is_ancestor_of(house) or house.is_queued_for_deletion() \
		or not house.has_method("marker") or not (callout is float or callout is int) or float(callout) <= 0.0: return null
	var door: Variant = house.call("marker", "door")
	if not door is Vector3 or not (door as Vector3).is_finite() \
		or actor.global_position.distance_to(door) > float(callout): return null
	return found


## The furthest opening beat recorded in a character's persisted flags.
static func peer_beat(flags: Dictionary) -> String:
	var reached := ""
	for beat: String in preload("res://scripts/story/opening_beats.gd").order():
		if flags.get("opening:beat:" + beat) == true: reached = beat
	return reached


static func host_grant(session: Node, peer: int, request: Dictionary) -> Dictionary:
	var bound := _binding(session, peer, request)
	if bound.is_empty(): return {"durable": false, "code": "not_admitted"}
	if _opening_source(session, peer) == null \
		or starter_uid(bound.personal, session.call("_foundation_flags", peer)).is_empty():
		return {"durable": false, "code": "opening_context_changed"}
	# A verified gift request is the host's own evidence that this character
	# reached Grandpa's first-catch gift; a guest's opening beats stay local.
	# It is recorded only after the checks above pass, and stands even if a
	# later re-check (writer flush, geometry) fails this request: the armed
	# reconcile then redelivers the key under its own gates.
	if session.has_method("note_opening_gift_requested"): session.call("note_opening_gift_requested", peer)
	var game: Node = bound.game
	var saver: RefCounted = game.get("save_system")
	if saver == null or not bool(saver.call("finish_fallback")) or saver.call("fallback_busy") == true:
		return {"durable": false, "code": "writer_busy"}
	# The fallback writer may run callbacks; re-read identity, roster and geometry.
	bound = _binding(session, peer, request)
	if bound.is_empty() or _opening_source(session, peer) == null \
		or starter_uid(bound.personal, session.call("_foundation_flags", peer)).is_empty():
		return {"durable": false, "code": "opening_context_changed"}
	var gift := _journal_prepared(session, peer, bound)
	# A guest's own delivery request settles it (after its finds have
	# replayed); only the host's own character reconciles here at once.
	if gift.get("durable") == true and peer == session.call("local_peer_id"):
		var reconcile := request.duplicate(true)
		reconcile.delivery_id = gift.delivery_id
		reconcile.origin_namespace = bound.world.reward_delivery_namespace
		host_reconcile(session, peer, reconcile)
	return gift


## Saves made while the portal runtime was off finished Grandpa's first-catch
## conversation without a Home Key; with portals on they would be stranded
## outside Meadows. The host journals the same deterministic grant row for any
## admitted character past that beat who holds no key, no owed escrow and no
## home_key_given fact. Idempotent: the row id is fixed per character/world and
## the ordinary delivery path settles it exactly once.
const PAST_FIRST_CATCH_FLAG := "opening:beat:walk_out"

static func legacy_grant_due(personal: Dictionary, flags: Dictionary, character: String) -> bool:
	if character.is_empty() or personal.get("character_id") != character: return false
	if flags.get(PAST_FIRST_CATCH_FLAG) != true or flags.get("home_key_given") == true: return false
	if HOME_ACTION.key_count(personal) != 0: return false
	var escrow: Variant = personal.get("portal_escrow", {})
	if escrow is Dictionary:
		for row: Variant in (escrow as Dictionary).values():
			if HOME_ACTION.valid_escrow(row, character): return false
	return true


static func host_legacy_grant(session: Node, peer: int) -> Dictionary:
	if session == null or session.call("is_host") != true or session.call("portal_runtime_ready") != true: return {}
	var game: Node = session.call("_game")
	if game == null or game.get("world") == null: return {}
	var world: RefCounted = game.get("world")
	var character: String = session.call("_authority_character", peer)
	if character.is_empty(): return {"durable": false, "code": "not_ready"}
	# Cheap gates first; the admitted record re-projects the whole character.
	var flags: Dictionary = session.call("_foundation_flags", peer).duplicate()
	if flags.get("home_key_given") == true: return {}
	if session.has_method("opening_gift_requested") and session.call("opening_gift_requested", peer) == true:
		flags[PAST_FIRST_CATCH_FLAG] = true
	# Not yet past the first catch: keep the arm (its window bounds it), the
	# beat may still be on its way (the host's own batch writes it after).
	if flags.get(PAST_FIRST_CATCH_FLAG) != true: return {"durable": false, "code": "not_past_first_catch"}
	if peer == session.call("local_peer_id") and game.get("inventory").count("home_key") != 0: return {}
	var personal: Dictionary = session.call("admitted_character_state", peer)
	if personal.is_empty(): return {"durable": false, "code": "not_ready"}
	if not legacy_grant_due(personal, flags, character): return {}
	var saver: RefCounted = game.get("save_system")
	if saver == null or not bool(saver.call("finish_fallback")) or saver.call("fallback_busy") == true:
		return {"durable": false, "code": "writer_busy"}
	var request := envelope(character, world.reward_delivery_namespace, str(session.call("_altar_current_epoch")))
	var bound := _binding(session, peer, request)
	if bound.is_empty(): return {"durable": false, "code": "not_admitted"}
	var gift := _journal_prepared(session, peer, bound)
	# A guest's own delivery request settles it (after its finds have
	# replayed); only the host's own character reconciles here at once.
	if gift.get("durable") == true and peer == session.call("local_peer_id"):
		var reconcile := request.duplicate(true)
		reconcile.delivery_id = gift.delivery_id
		reconcile.origin_namespace = world.reward_delivery_namespace
		host_reconcile(session, peer, reconcile)
	return gift


static func _journal_prepared(session: Node, peer: int, bound: Dictionary) -> Dictionary:
	var game: Node = bound.game
	var saver: RefCounted = game.get("save_system")
	var world: RefCounted = bound.world
	var character: String = bound.character
	var row := REWARD.make_record(world.world_id, world.reward_delivery_namespace,
		"home_key:grant:" + character, character, "home_key", 1, "home_key_given")
	if row.is_empty(): return {"durable": false, "code": "invalid_gift"}
	var prior: Variant = world.reward_deliveries.get(row.delivery_id)
	if prior != null:
		return {"durable": valid_row(prior, world, character), "duplicate": true, "delivery_id": row.delivery_id}
	var transport: Node = session.get_node_or_null(^"LedgerRpc")
	if transport == null: return {"durable": false, "code": "ledger_missing"}
	transport.call("_ensure_ledger")
	var ledger: RefCounted = transport.get("ledger")
	if ledger == null or ledger.get("world") != world: return {"durable": false, "code": "ledger_changed"}
	var before: Dictionary = world.save_data()
	var revision := int(world.revision)
	var sequence := int(ledger.get("seq"))
	var ops: Array = [{"op": "reward_delivery_journal", "scope": "world", "realm": "meadows",
		"delivery_id": row.delivery_id, "delivery": row}]
	var verdict: Dictionary = ledger.call("_commit", ops, "opening_home_key", peer, "meadows")
	if verdict.get("ok") != true: return {"durable": false, "code": "journal_refused"}
	if world.reward_deliveries.get(row.delivery_id) != row or saver.call("save_world_prepared", game, world.world_id) != true:
		world.load_data(before)
		world.revision = revision
		ledger.set("seq", sequence)
		return {"durable": false, "code": "journal_failed"}
	# Physical delivery and owed debt use the existing Foundation owner-save
	# CAS, never generic reward.apply or an unverified possession notification.
	var live := _binding(session, peer, bound.request)
	if live.is_empty() or live.world != world or live.character != character \
		or world.reward_deliveries.get(row.delivery_id) != row:
		return {"durable": true, "published": false, "delivery_id": row.delivery_id}
	transport.call("publish_journaled_delta", verdict.delta)
	return {"durable": true, "duplicate": false, "delivery_id": row.delivery_id}


## Notifications alone confer nothing. Physical possession must already exist
## on the host-authored admitted inventory with every owner-save CAS unlocked.
static func host_confirm_settled(session: Node, peer: int, request: Dictionary) -> bool:
	var bound := _binding(session, peer, request, true)
	if bound.is_empty() or not valid_row(bound.world.reward_deliveries.get(request.delivery_id), bound.world, bound.character): return false
	var authority: RefCounted = session.get("_character_authority")
	if authority == null or authority.call("_training_locked", bound.character) == true \
		or HOME_ACTION.key_count(bound.personal) != 1: return false
	authority.call("record_personal_flag", bound.character, "home_key_given", true)
	return true


static func host_reconcile(session: Node, peer: int, request: Dictionary) -> Dictionary:
	if request.size() != 5 or not request.get("delivery_id") is String or request.delivery_id.length() != 64 \
		or not request.get("origin_namespace") is String or request.origin_namespace.is_empty() \
		or request.origin_namespace.length() > 192: return {"ok": false, "code": "invalid_home_key_reconcile"}
	var identity := request.duplicate() # Validate primitive identity fields before any deep copy.
	identity.erase("delivery_id")
	identity.erase("origin_namespace")
	var bound := _binding(session, peer, identity)
	if bound.is_empty(): return {"ok": false, "code": "not_admitted"}
	var saver: RefCounted = bound.game.get("save_system")
	if saver == null or saver.call("finish_fallback") != true or saver.call("fallback_busy") == true:
		return {"ok": false, "code": "writer_busy"}
	bound = _binding(session, peer, identity)
	if bound.is_empty(): return {"ok": false, "code": "not_admitted"}
	var authority: RefCounted = session.get("_character_authority")
	if authority == null or authority.call("_training_locked", bound.character) == true:
		return {"ok": false, "code": "owner_action_pending"}
	if _owner_delivery_unsettled(bound.world, bound.character, request.delivery_id):
		return {"ok": false, "code": "owner_delivery_pending"}
	if session.call("_altar_peer_in_combat", peer) == true: return {"ok": false, "code": "actor_in_combat"}
	var source: Variant = bound.personal.get("portal_escrow", {}).get(request.delivery_id)
	var action := "home_key_deliver"
	if source == null:
		# A first debt comes only from this host's actual saved opening producer.
		# An old world's ID without its admitted finite escrow is refused.
		if request.origin_namespace != bound.world.reward_delivery_namespace:
			return {"ok": false, "code": "admitted_home_key_debt_required"}
		var canonical: Variant = bound.world.reward_deliveries.get(request.delivery_id)
		if not valid_row(canonical, bound.world, bound.character): return {"ok": false, "code": "finite_home_key_source_required"}
		source = HOME_ACTION.due(canonical, bound.character)
		action = "home_key_owe"
	if not HOME_ACTION.valid_escrow(source, bound.character) or source.world_namespace != request.origin_namespace:
		return {"ok": false, "code": "admitted_home_key_debt_required"}
	# A copied packet cannot introduce another world's escrow. The source is
	# the host's admitted baseline or its own saved original opening decision.
	var mirrored := _journal_prepared(session, peer, bound)
	if mirrored.get("durable") != true: return {"ok": false, "code": "home_key_mirror_failed"}
	bound = _binding(session, peer, identity)
	if bound.is_empty() or authority.call("_training_locked", bound.character) == true:
		return {"ok": false, "code": "owner_action_pending"}
	if source.status == "settled":
		return {"ok": HOME_ACTION.key_count(bound.personal) == 1, "durable": true, "resolved": true}
	var intent := {"delivery_id": request.delivery_id, "origin_namespace": request.origin_namespace}
	var context := {"character_id": bound.character, "expected_revision": int(authority.call("revision", bound.character)),
		"in_range": true, "in_combat": false, "foundation_runtime_authorized": true,
		"home_key_authorized": true, "home_key_record": source.duplicate(true),
		"source_key": "opening_home_key:" + request.delivery_id}
	var actions: Script = load("res://scripts/net/foundation_actions.gd")
	return actions.commit(authority, session.get_node(^"LedgerRpc"), peer, bound.character,
		context.expected_revision, action, intent, context)


## A reward delivery (a find, a gather batch) the owner may already hold but
## the host has not yet accepted: the admitted record lacks it, so a
## full-record Home Key row staged now would conflict on the owner's baseline
## and hold every later owner write. The owner re-sends its delivery request,
## so this waits for the next one. Typed rows have their own guards; the gift's
## own row is the one being reconciled.
static func _owner_delivery_unsettled(world: RefCounted, character: String, gift_id: String) -> bool:
	for row: Dictionary in REWARD.pending_for_character(world, character):
		if row.get("delivery_id") != gift_id and not row.has("kind"): return true
	return false


static func authoritative_owned(session: Node, peer: int) -> bool:
	if session == null or session.call("is_host") != true: return false
	var character: String = session.call("_authority_character", peer)
	var authority: RefCounted = session.get("_character_authority")
	if character.is_empty() or authority == null or authority.call("_training_locked", character) == true: return false
	var personal: Dictionary = session.call("admitted_character_state", peer)
	return authority.call("_training_locked", character) != true and HOME_ACTION.key_count(personal) == 1


static func accepted(session: Node, peer: int, row: Dictionary) -> void:
	if row.get("action") not in HOME_ACTION.ACTIONS or row.get("status") != "accepted" \
		or session.call("_training_decision", peer, row).get("ok") != true: return
	var game: Node = session.call("_game")
	var character: String = session.call("_authority_character", peer)
	var id := REWARD.delivery_id(game.get("world").reward_delivery_namespace, "home_key:grant:" + character, character)
	var transport: Node = session.get_node_or_null(^"LedgerRpc")
	if transport != null: transport.call("_accept_reward_delivery", id, peer)
	if row.action == "home_key_deliver" and authoritative_owned(session, peer):
		session.get("_character_authority").call("record_personal_flag", character, "home_key_given", true)
