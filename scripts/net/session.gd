extends Node
const RETAINED_SETTLEMENT := preload("res://scripts/net/retained_settlement.gd")
const ALTAR_TRACE := preload("res://scripts/net/altar_commit_trace.gd")
const BACKGROUND_TRACE := preload("res://scripts/net/background_work_trace.gd")

const FOUNDATION_ACTIONS := preload("res://scripts/net/foundation_actions.gd")
const CHARACTER_ACTIONS := preload("res://scripts/net/character_action_rules.gd")
const FOUNDATION_RETRY_ORDER := preload("res://scripts/net/foundation_retry_order.gd")
const WILD_ACTOR_SCOPE := preload("res://scripts/net/wild_actor_scope.gd")
const COMBAT_ROUND_REWARD := preload("res://scripts/net/combat_round_reward.gd")
const STATION_RULES := preload("res://scripts/build/station_rules.gd")
const HOMESTEAD_BUILDING := preload("res://scripts/net/homestead_building_delivery.gd")
const GROOM_PASSIVE := preload("res://scripts/net/groom_passive_sync.gd")
var _groom_passive: RefCounted
const OWNER_PASSIVE := preload("res://scripts/net/owner_passive_sync.gd")
var _owner_passive: RefCounted
var _owner_passive_altar_original: Dictionary = {}
var _altar_traits_transport: Node
const FOUNDATION_DIRECTORS := ["res://scripts/combat/encounter_director.gd", "res://scripts/combat/stormwood_encounter_director.gd", "res://scripts/combat/cloudreach_encounter_director.gd", "res://scripts/combat/water_encounter_director.gd", "res://scripts/world/cloudreach_scene_encounters.gd"]
const FOUNDATION_COMBAT_MANAGERS := ["res://scripts/combat/combat_manager.gd", "res://scripts/combat/cloudreach_combat_manager.gd", "res://scripts/combat/stormwood_combat_manager.gd"]
## Joined in each script's _enter_tree (encounter_director.gd, combat_manager.gd).
const FOUNDATION_DIRECTOR_GROUP := &"foundation_portal_directors"
const FOUNDATION_COMBAT_MANAGER_GROUP := &"foundation_combat_managers"
signal homestead_action_completed(action: String, original: Dictionary, result: Dictionary)
signal homestead_personal_view_completed()
signal foundation_reply_received(envelope: Dictionary, result: Dictionary)
signal altar_trait_completed(station_key: String, action_id: String, result: Dictionary)
signal altar_trait_quote_completed(station_key: String, uid: String)
var _homestead_stations: Dictionary = {}
var _foundation_requests: Dictionary = {}
var _foundation_personal_cache: Dictionary = {}
var _foundation_personal_cache_scope: Dictionary = {}
var _foundation_camp_pending: Dictionary = {}
## Host: the last rejoin_admission outcome per character (diagnostic/proof).
var last_rejoin_admission: Dictionary = {}
## Bound on a hello's settled/owed delivery ids. A malformed or oversized list
## keeps the held record and refuses the stream (never read as behind, which
## would cost the owner its progress; review L1).
const MAX_SETTLED_DELIVERIES := 16384


## The hello's settled and owed payout ids, filtered to this world's rows --
## and to folds this character has not yet confirmed, whose rows may already
## be pruned (review L1: a lost "readmitted" must not read as behind).
func rejoin_payout_lists(summary: Dictionary) -> Dictionary:
	var out := {"valid": true, "settled": [], "owed": []}
	var rows: Dictionary = (_game().get("world").reward_deliveries as Dictionary).duplicate() if _game() != null else {}
	if _character_authority != null:
		for fold: Variant in _character_authority.call("unconfirmed_folds", str(summary.get("character_id", ""))):
			if fold is Dictionary: rows[str(fold.get("delivery_id", ""))] = true
	for key: String in ["settled", "owed"]:
		var raw: Variant = summary.get(key + "_deliveries", [])
		if not raw is Array or (raw as Array).size() > MAX_SETTLED_DELIVERIES \
			or (raw as Array).any(func(id: Variant) -> bool: return not id is String or (id as String).length() > 160):
			out.valid = false
			continue
		out[key] = (raw as Array).filter(func(id: String) -> bool: return rows.has(id))
	return out


## The hello's rejoin decision; records its code for owner-passive admission.
func rejoin_admission_for(character_id: String, portable: Dictionary, summary: Dictionary, lists: Dictionary) -> Dictionary:
	var rejoin: Dictionary = {"ok": false, "code": "payout_list_invalid"}
	# A post-ACK declaration passes the same portable checks as the hello.
	if not CHARACTER_AUTHORITY.errors(portable, character_id).is_empty() \
		or not CHARACTER_AUTHORITY.personal_flags_valid(summary.get("personal_flags", {"flags": []})) \
		or _groom_service().call("admission_valid", summary.get("discovered_landmarks"), true) != true:
		rejoin = {"ok": false, "code": "invalid_character"}
	elif lists.get("valid") == true:
		rejoin = _character_authority.call("rejoin_admission", character_id, portable, _game().get("world").reward_deliveries,
			(summary.get("personal_flags", {"flags": []}) as Dictionary).get("flags", []), lists.settled, lists.owed)
	last_rejoin_admission[character_id] = str(rejoin.get("code", ""))
	return rejoin


## A gather batch now in the character's record is credited, as its live
## replay would mark it, so its row can be pruned once ACKed.
func credit_rejoin_gathers(character_id: String, ids: Array) -> void:
	var gather_writer: Node = get_node_or_null(^"LedgerRpc")
	for delivery_id: Variant in ids:
		var row: Variant = _game().get("world").reward_deliveries.get(delivery_id)
		if gather_writer != null and row is Dictionary: gather_writer.call("mark_gather_replayed", character_id, row)
var _camp_view_requested_ms := -1000000
var _process_exit_in_flight := false
var _process_exit_refusal := ""

func _groom_service() -> RefCounted:
	if _groom_passive == null: _groom_passive = GROOM_PASSIVE.new(self)
	return _groom_passive

func _owner_passive_service() -> RefCounted:
	if _owner_passive == null: _owner_passive = OWNER_PASSIVE.new(self)
	return _owner_passive

func owner_passive_recording_active() -> bool:
	return _owner_passive != null and _owner_passive.call("recording_active") == true

func record_owner_passive_input(packet: Dictionary) -> void:
	if _owner_passive != null: _owner_passive.call("record_input", packet)

## Host-only callers: the landing arbiter's accepted fly placement (exact
## guest-claimed pose) and an accepted grounded portal/Home Key arrival
## (foundation_portal_arrival, arrival_endpoint).
func owner_passive_travel_reset_confirmed(peer: int, realm: String, anchor: Vector3, arrival_endpoint: bool = false) -> void:
	if is_host() and _owner_passive != null:
		_owner_passive.call("travel_reset_confirmed", peer, realm, anchor, arrival_endpoint)

func owner_passive_research_gate(peer: int, action: String, intent: Dictionary, event: Dictionary) -> Dictionary:
	return _owner_passive_service().call("gate", peer, action, intent, event)

func _owner_passive_request_matches(source_kind: String, request: Dictionary) -> bool:
	if source_kind == "tether_item":
		var game := _game()
		if game == null or game.get("local") == null or game.get("world") == null \
			or request.get("character_id") != str(game.get("local").get("character_id")) \
			or request.get("world_namespace") != game.get("world").get("reward_delivery_namespace") \
			or request.get("session_epoch") != _altar_current_epoch(): return false
		for director: Node in _foundation_directors_under(_foundation_realm_roots()):
			if director.has_method("owner_tether_item_request_matches") \
				and director.call("owner_tether_item_request_matches", request) == true: return true
		return false
	if source_kind == "portal_arrival":
		var arrival := get_node_or_null(^"FoundationComposition/PortalArrival")
		return arrival != null and request.get("envelope") is Dictionary \
			and preload("res://scripts/net/owner_passive_preparation.gd").exact(_portal_requests.get(request.envelope.get("request_id")), request.envelope) \
			and arrival.call("owner_request_matches", request) == true
	if source_kind == "waystone_touch":
		return request.get("envelope") is Dictionary \
			and preload("res://scripts/net/owner_passive_preparation.gd").exact(_portal_requests.get(request.envelope.get("request_id")), request.envelope) \
			and request.envelope.get("payload") is Dictionary and request.envelope.payload.get("kind") == "waystone_touch"
	if source_kind == "home_key":
		return request.get("envelope") is Dictionary \
			and preload("res://scripts/net/owner_passive_preparation.gd").exact(_home_key_requests_sent.get(request.envelope.get("delivery_id")), request.envelope)
	if source_kind == "altar_spend":
		return preload("res://scripts/net/owner_passive_preparation.gd").exact(_owner_passive_altar_original, request)
	if source_kind == "altar_traits": return _altar_traits_service().call("owner_request_matches", request) == true
	if source_kind not in ["foundation_request", "manual_refine"]: return false
	var correlation := JSON.stringify([request.get("op"), request.get("station_key"), request.get("intent"), request.get("revision")]).sha256_text()
	return preload("res://scripts/net/owner_passive_preparation.gd").exact(_foundation_requests.get(correlation), request)

func _owner_passive_commit_request(peer: int, source_kind: String, request: Dictionary, context: Dictionary) -> Dictionary:
	match source_kind:
		"bounty_rotation":
			var bounty := get_node_or_null(^"FoundationComposition/BountyHost")
			return bounty.call("commit_rotation_prepared", peer, request, context) if bounty != null \
				else {"ok": false, "durable": false, "resolved": true, "terminal_refusal": true, "code": "bounty_source_unavailable"}
		"tether_item":
			for director: Node in _foundation_directors_under(_foundation_realm_roots()):
				var host: RefCounted = director.get("_encounter_host")
				if host == null: continue
				for original: Dictionary in host.call("pending_tether_items", str(request.get("intent", {}).get("request", {}).get("encounter_id", ""))):
					if ESSENCE._equivalent(original.get("checkpoint_request"), request) and ESSENCE._equivalent(original.context, context):
						return _tether_item_commit_original(director, original)
			return FOUNDATION_ACTIONS.deny("item_original_unavailable")
		"portal_arrival":
			var result := foundation_grounded_arrival(get_node_or_null(^"FoundationComposition/PortalArrival"), request.envelope, request.permit)
			if result.get("code") == "arrival_binding_changed":
				result.resolved = true
				result.terminal_refusal = true
			return result
		"foundation_request": return _foundation_handle(peer, request)
		"waystone_touch": return _waystone_commit_prepared(peer, request.envelope, context)
		"home_key": return OPENING_HOME_KEY.commit_reconcile(self, peer, request.envelope, context)
		"altar_spend": return _handle_altar_spend(peer, request)
		"altar_traits": return _altar_traits_service().call("commit_prepared", peer, request)
		"manual_refine":
			var forge := get_node_or_null(^"FoundationComposition/ForgeHost")
			return forge.call("commit_prepared", peer, request, context) if forge != null else FOUNDATION_ACTIONS.deny("forge_unavailable")
	return FOUNDATION_ACTIONS.deny("owner_passive_request_kind")

func _owner_passive_request_terminal(source_kind: String, request: Dictionary, result: Dictionary) -> void:
	if is_host() or result.get("terminal_refusal") != true or result.get("resolved") != true \
		or result.get("durable") == true or not _owner_passive_request_matches(source_kind, request): return
	if source_kind in ["portal_arrival", "waystone_touch"]:
		var reply := result.duplicate(true)
		var envelope: Dictionary = request.envelope
		for field: String in ["request_id", "character_id", "world_instance_id", "session_epoch"]: reply[field] = envelope[field]
		reply.kind = envelope.payload.kind
		if envelope.payload.kind == "waystone_touch": reply.waystone_id = envelope.payload.waystone_id
		_receive_portal_reply(reply)
	elif source_kind == "altar_traits":
		var reply := result.duplicate(true)
		reply.terminal = true # Existing Traits UI's terminal presentation flag.
		_altar_traits_service().call("receive_result", request, reply)
	elif source_kind == "altar_spend":
		_owner_passive_altar_original.clear()
		_altar_spend_request.clear()
		altar_essence_spend_completed.emit(request.station_key, request.intent.spend_id, result.duplicate(true))
	elif source_kind in ["foundation_request", "manual_refine"]:
		_rpc_foundation_reply(request, result) # Existing exact correlation/presentation path, no RPC send.

## Typed delivery installs record only a receipt binding into the same care
## stream. HP and condition values are resolved from the host's original row.
## The world writer's epoch is independent of the authenticated transport.
## Resolve it from the actual mounted writer, never from an owner packet.
func _ordinary_actor_vitals_journal_epoch() -> String:
	var game: Node = _game()
	var writer: Node = get_node_or_null(^"LedgerRpc")
	if not is_host() or game == null or game.get("session") != self or writer == null \
		or game.get("world") == null or writer.get_parent() != self: return ""
	var script: Script = writer.get_script()
	while script != null and script.resource_path != "res://scripts/net/ledger_rpc.gd":
		script = script.get_base_script()
	if script == null: return ""
	var ledger: RefCounted = writer.get("ledger")
	var epoch: Variant = writer.get("_actor_vitals_session_id")
	if writer.call("_game") != game or ledger == null or ledger.get("world") != game.get("world") \
		or not _altar_hex_id(epoch): return ""
	return epoch

static func _ordinary_actor_vitals_original_row(proof: Dictionary, row: Dictionary) -> bool:
	var original: Dictionary = proof.get("row", {})
	if original.is_empty() or not _altar_hex_id(proof.get("journal_epoch")) \
		or original.get("session_id") != proof.journal_epoch or row.get("session_id") != proof.journal_epoch: return false
	var compared: Dictionary = row.duplicate(true)
	compared["status"] = original.get("status")
	return ESSENCE._equivalent(compared, original)

## Once the actual ordinary source owns an id, loss of current readiness is
## a refusal, never permission to install it through legacy recovery.
func _ordinary_actor_vitals_owned_origin(director: Node, row: Dictionary) -> bool:
	if director.get("_session") != self: return false
	var receipt: Variant = row.get("receipt")
	if not receipt is Dictionary: return false
	var id: String = str(receipt.get("encounter_id", ""))
	if id.is_empty(): return false
	if is_host():
		var owners: Dictionary = director.get("_ordinary_combat_reward_owners")
		if owners.has(id): return true
		var proof: Dictionary = director.get_meta("foundation_ordinary_vitals_commits", {}).get(receipt.get("receipt_id"), {})
		if proof.get("proposal", {}).get("encounter_id") == id or proof.get("scope", {}).get("encounter_id") == id: return true
	else:
		var record: Dictionary = director.get("_encounter")
		if record.get("encounter_id") == id and (record.has("ordinary_combat_reward_owner") or record.has("wild_actor_owner")): return true
	var manager: Node = director.get("_manager") as Node
	return is_instance_valid(manager) and manager.get_script() != null \
		and FOUNDATION_COMBAT_MANAGERS.has(manager.get_script().resource_path) \
		and manager.get("_encounter_link") == director and manager.get("_encounter_id") == id \
		and manager.get("_ordinary_reward_owned_id") == id

## Transport ownership and the original journal source are independently bound.
## Guest records already came through the authoritative replicated world door.
func _owner_passive_actor_vitals_scope(row: Dictionary) -> Dictionary:
	var game: Node = _game()
	var actor: Script = preload("res://scripts/net/actor_vitals_delivery.gd")
	if game == null or game.get("session") != self or game.get("world") == null or game.get("local") == null: return {}
	var world: RefCounted = game.get("world")
	if not actor.valid(row, str(game.get("local").get("character_id")), str(world.get("reward_delivery_namespace"))) \
		or row.world_id != world.get("world_id") \
		or not ESSENCE._equivalent(world.get("reward_deliveries").get(row.delivery_id), row): return {}
	for director: Node in _foundation_directors_under(_foundation_realm_roots()):
		if _ordinary_actor_vitals_owned_origin(director, row):
			var record: Dictionary = director.get("_encounter_host").call("record", str(row.receipt.encounter_id)) \
				if is_host() and director.get("_encounter_host") != null else director.get("_encounter")
			var scope: Dictionary = director.get("_ordinary_combat_reward_owners").get(str(row.receipt.encounter_id), {}) \
				if is_host() else record.get("ordinary_combat_reward_owner", {})
			var wild_scope := false
			if scope.is_empty():
				scope = record.get("wild_actor_owner", {})
				wild_scope = WILD_ACTOR_SCOPE.owns(scope, record, str(row.receipt.encounter_id))
			if not (wild_scope or COMBAT_ROUND_REWARD.scope_valid(scope)) or scope.session_id != _altar_current_epoch() \
				or scope.encounter_id != row.receipt.encounter_id or scope.world_namespace != row.world_namespace: return {}
			if is_host():
				var proof: Dictionary = director.get_meta("foundation_ordinary_vitals_commits", {}).get(row.receipt.receipt_id, {})
				if not ESSENCE._equivalent(proof.get("scope"), scope) or proof.get("character_id") != row.character_id \
					or proof.get("world_id") != row.world_id or not _ordinary_actor_vitals_original_row(proof, row) \
					or not ESSENCE._equivalent(proof.get("proposal", {}).get("settlement_receipt"), row.receipt): return {}
			return {"character_id": row.character_id, "world_id": row.world_id, "world_namespace": row.world_namespace,
				"session_epoch": scope.session_id, "journal_session_id": row.session_id}
	return {}

## A guest payout moves its satchel; its owner-passive stream must carry that.
## The owner-passive discovery identity this guest's host replays against.
func owner_passive_discoveries() -> Variant:
	if is_host() or _owner_passive == null or (_owner_passive.get("local") as Dictionary).is_empty(): return null
	return _owner_passive.call("_discoveries")

func _owner_passive_delivery_ready() -> bool:
	if is_host() or _owner_passive == null or (_owner_passive.get("local") as Dictionary).is_empty(): return true
	return _owner_passive.call("delivery_ready") == true

func _owner_passive_delivery_record(row: Dictionary) -> void:
	if is_host() or _owner_passive == null or (_owner_passive.get("local") as Dictionary).is_empty(): return
	_owner_passive.call("record_delivery", row)

func _owner_passive_actor_vitals_record(row: Dictionary, saved: bool) -> bool:
	var receipt: Variant = row.get("receipt")
	if not receipt is Dictionary: return false
	var bound: Dictionary = _owner_passive_actor_vitals_scope(row)
	if not bound.is_empty():
		if is_host(): return true # Actual host PlayerState owns its passive baseline.
		return _owner_passive_service().call("record_vitals", row, saved) == true
	# Keep existing unowned typed recovery, but an owned source never falls back.
	for director: Node in _foundation_directors_under(_foundation_realm_roots()):
		if _ordinary_actor_vitals_owned_origin(director, row): return false
	var game: Node = _game()
	var actor: Script = preload("res://scripts/net/actor_vitals_delivery.gd")
	if game == null or game.get("world") == null or game.get("local") == null: return false
	var world: RefCounted = game.get("world")
	if not actor.valid(row, str(game.get("local").get("character_id")), str(world.get("reward_delivery_namespace"))) \
		or row.world_id != world.get("world_id") or not ESSENCE._equivalent(world.get("reward_deliveries").get(row.delivery_id), row): return false
	return true # Unowned legacy deliveries have no ordinary reward checkpoint.

func _owner_passive_actor_vitals_context(peer: int, binding: Dictionary) -> Dictionary:
	if not is_host() or binding.size() != 6 or binding.get("version") != 1 \
		or binding.get("op") not in ["actor_vitals_applied", "actor_vitals_saved"] \
		or not binding.get("sequence") is int or int(binding.sequence) < 1 \
		or not binding.get("journal_revision") is int or int(binding.journal_revision) < 1 \
		or not binding.get("delivery_id") is String or not binding.get("receipt_hash") is String: return {}
	var character: String = _authority_character(peer)
	var world: RefCounted = _game().get("world")
	var actor: Script = preload("res://scripts/net/actor_vitals_delivery.gd")
	if character.is_empty() or world == null: return {}
	for director: Node in _foundation_directors_under(_foundation_realm_roots()):
		if not _ordinary_combat_director_live(director): continue
		var proofs: Dictionary = director.get_meta("foundation_ordinary_vitals_commits", {})
		for proof: Dictionary in proofs.values():
			var row: Dictionary = proof.get("row", {})
			if row.get("delivery_id") != binding.delivery_id or row.get("journal_revision") != binding.journal_revision \
				or preload("res://scripts/net/research_passive_preparation.gd").fingerprint(row.get("receipt", {})) != binding.receipt_hash: continue
			var proposal: Dictionary = proof.get("proposal", {})
			if proof.get("character_id") != character or proof.get("world_id") != world.get("world_id") \
				or not actor.valid(row, character, str(world.get("reward_delivery_namespace"))) \
				or proof.get("scope", {}).get("session_id") != _altar_current_epoch() \
				or not _ordinary_actor_vitals_original_row(proof, row) \
				or not ESSENCE._equivalent(row.receipt, proposal.get("settlement_receipt")) \
				or not ESSENCE._equivalent(row.expected_hp, proposal.get("hp_before")) \
				or not ESSENCE._equivalent(row.hp, proposal.get("hp_after")) \
				or not ESSENCE._equivalent(row.max_hp, proposal.get("max_hp")) \
				or row.fainted != proposal.get("fainted") or int(row.character_revision) != int(proof.get("revision_before", -1)) + 1: return {}
			var latest: Dictionary = world.get("reward_deliveries").get(row.delivery_id, {})
			var accepted: bool = proof.get("accepted") == true
			if not accepted and not ESSENCE._equivalent(latest, row): return {}
			if binding.op == "actor_vitals_saved" and not accepted: return {}
			var original_row: Dictionary = row.duplicate(true)
			if accepted: original_row.status = "accepted"
			return {"row": original_row, "hp_before": float(proposal.hp_before),
				"fainted_before": float(proposal.hp_before) == 0.0, "revision_before": int(proof.revision_before)}
	return {}

func _owner_passive_commit_retained(peer: int, binding: Dictionary) -> Dictionary:
	if not is_host() or binding.get("character") != _authority_character(peer) \
		or binding.get("action") not in ["master_win", "boss_relic", "combat_mastery", "combat_round_reward", "wild_defeat_share"]:
		return FOUNDATION_ACTIONS.deny("owner_passive_original_duty_required")
	var world: RefCounted = _game().get("world")
	if binding.action == "boss_relic":
		var handoff := preload("res://scripts/net/encounter_rewards.gd").chapter_hand_off(str(binding.intent.trainer_id), str(binding.event.realm))
		if not preload("res://scripts/net/encounter_rewards.gd").chapter_delivery_ready(handoff, world.flags.all_set()):
			return FOUNDATION_ACTIONS.deny("boss_settlement_world_pending")
	if binding.action == "combat_mastery" and (_altar_peer_in_combat(peer) \
		or _ordinary_round_pending_characters().has(binding.character)): return FOUNDATION_ACTIONS.deny("combat_still_active")
	var context: Dictionary = binding.event.duplicate(true)
	context.expected_revision = int(_character_authority.call("revision", binding.character))
	var writer := get_node_or_null(^"LedgerRpc")
	if binding.action in FOUNDATION_ACTIONS.ACTIONS:
		return FOUNDATION_ACTIONS.commit(_character_authority, writer, peer, binding.character,
			context.expected_revision, binding.action, binding.intent, context)
	return preload("res://scripts/net/character_action_rules.gd").commit_host_action(_character_authority,
		writer, peer, binding.character, context.expected_revision, binding.action, binding.intent, context)

func _altar_traits_service() -> Node:
	if _altar_traits_transport == null:
		_altar_traits_transport = load("res://scripts/net/altar_traits_transport.gd").new(self)
		_altar_traits_transport.name = "AltarTraitsTransport"
		add_child(_altar_traits_transport)
	return _altar_traits_transport

func quote_altar_traits(key: String, uid: String) -> Dictionary:
	return _altar_traits_service().call("quote", key, uid)

func invalidate_altar_trait_quote() -> void:
	_altar_traits_service().call("invalidate_quote")

func submit_altar_trait(key: String, intent: Dictionary) -> Dictionary:
	return _altar_traits_service().call("send", key, intent, false)

func reconcile_altar_trait(key: String, intent: Dictionary) -> Dictionary:
	return _altar_traits_service().call("send", key, intent, true)

func _altar_traits_send_quote(envelope: Dictionary) -> void:
	if not is_host() and is_active(): rpc_id(HOST_PEER_ID, "_rpc_altar_traits_quote", envelope)

func _altar_traits_send(envelope: Dictionary, reconcile: bool) -> void:
	if not is_host() and is_active(): rpc_id(HOST_PEER_ID, "_rpc_altar_traits", envelope, reconcile)

@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_traits_quote(envelope: Dictionary) -> void:
	if not is_host(): return
	var peer := multiplayer.get_remote_sender_id()
	var result: Dictionary = _altar_traits_service().call("handle_quote", peer, envelope)
	if _registry.call("has", peer) == true: rpc_id(peer, "_rpc_altar_traits_quote_reply", envelope, result)

@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_traits(envelope: Dictionary, reconcile: bool) -> void:
	if not is_host(): return
	var peer := multiplayer.get_remote_sender_id()
	var result: Dictionary = _altar_traits_service().call("handle", peer, envelope, reconcile)
	if _registry.call("has", peer) == true: rpc_id(peer, "_rpc_altar_traits_reply", envelope, result)

@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_traits_quote_reply(envelope: Dictionary, result: Dictionary) -> void:
	if not is_host() and multiplayer.get_remote_sender_id() == HOST_PEER_ID:
		_altar_traits_service().call("receive_quote", envelope, result)

@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_traits_reply(envelope: Dictionary, result: Dictionary) -> void:
	if not is_host() and multiplayer.get_remote_sender_id() == HOST_PEER_ID:
		_altar_traits_service().call("receive_result", envelope, result)

func _owner_passive_send_host(packet: Dictionary) -> void:
	# The flush re-sends its unacknowledged inputs; skip a disconnecting link.
	if not is_host() and is_active() and preload("res://scripts/net/foundation_travel_lifecycle.gd").host_link_open(multiplayer.multiplayer_peer):
		rpc_id(HOST_PEER_ID, "_rpc_owner_passive_input", packet)

func _owner_passive_send_peer(peer: int, packet: Dictionary) -> void:
	if is_host() and _registry.call("has", peer) == true: rpc_id(peer, "_rpc_owner_passive_reply", packet)

@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_owner_passive_input(packet: Dictionary) -> void:
	if is_host(): _owner_passive_service().call("receive_host", multiplayer.get_remote_sender_id(), packet)

@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_owner_passive_reply(packet: Dictionary) -> void:
	if not is_host() and multiplayer.get_remote_sender_id() == HOST_PEER_ID and _owner_passive != null:
		_owner_passive.call("receive_owner", packet)

func groom_original_pending(original: Dictionary) -> bool:
	return _groom_passive != null and _groom_passive.call("pending_original", original) == true

## All transport envelopes reuse the Session generation/character/world fence.
## The peer sends a source key and original intent, never a price or context.
func _foundation_send(op: String, key: String, intent: Dictionary, revision: int) -> Dictionary:
	var envelope := _altar_envelope(op, key)
	if envelope.is_empty(): return FOUNDATION_ACTIONS.deny("authority_missing")
	envelope.intent = intent.duplicate(true)
	envelope.revision = revision
	var correlation := JSON.stringify([op, key, intent, revision]).sha256_text()
	_foundation_requests[correlation] = envelope.duplicate(true)
	if is_host(): return _foundation_handle(local_peer_id(), envelope)
	if not is_active(): return FOUNDATION_ACTIONS.deny("authority_missing")
	if op in ["regional_ack", "refine_start", "master_duel", "resource", "groom", "rematch_start"]:
		var lifecycle := get_node_or_null(^"FoundationComposition/TravelLifecycle")
		if lifecycle == null or lifecycle.call("publish_now") != true: return FOUNDATION_ACTIONS.deny("ending_context_changed")
	rpc_id(HOST_PEER_ID, "_rpc_foundation_action", envelope)
	return {"ok": false, "resolved": false, "code": "awaiting_saved_decision"}

@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_foundation_action(envelope: Dictionary) -> void:
	if not is_host(): return
	var peer := multiplayer.get_remote_sender_id()
	# The guest publishes its lifecycle sample just before this request on the
	# same reliable channel; judge that sample's freshness at its own arrival,
	# not a slow host frame later or after this handler's save/admission work.
	var lifecycle := get_node_or_null(^"FoundationComposition/TravelLifecycle")
	_foundation_request_arrived_at = int(lifecycle.call("take_paired_arrival", peer, Time.get_ticks_msec())) if lifecycle != null and lifecycle.has_method("take_paired_arrival") else Time.get_ticks_msec()
	var result := _foundation_handle(peer, envelope)
	_foundation_request_arrived_at = -1
	if envelope.get("op") == "regional_ack" and result.get("ok") != true and _regional_ack_refusal_new(peer, result):
		print("[regional_ack] host answered peer %d %s: %s resolved=%s gate=%s" % [peer, str(envelope.get("intent", {}).get("stage", "")), str(result.get("code", result.get("reason", ""))), str(result.get("resolved")), str(lifecycle.get("ending_refusal")) if lifecycle != null else "-"])
	if bool(_registry.call("has", peer)): rpc_id(peer, "_rpc_foundation_reply", envelope, result)

var _foundation_request_arrived_at := -1

## Diagnostic log once per guest and refusal code; re-sends stay quiet.
var _regional_ack_refusals_logged: Dictionary = {}
func _regional_ack_refusal_new(peer: int, result: Dictionary) -> bool:
	var key := "%d:%s" % [peer, str(result.get("code", result.get("reason", "")))]
	if _regional_ack_refusals_logged.has(key): return false
	_regional_ack_refusals_logged[key] = true
	return true

@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_foundation_reply(envelope: Dictionary, result: Dictionary) -> void:
	if is_host() or envelope.get("session_epoch") != _altar_current_epoch() \
		or envelope.get("character_id") != _local_character_id() \
		or envelope.get("world_namespace") != _game().get("world").reward_delivery_namespace: return
	var correlation := JSON.stringify([envelope.get("op"), envelope.get("station_key"), envelope.get("intent"), envelope.get("revision")]).sha256_text()
	if not ESSENCE._equivalent(_foundation_requests.get(correlation), envelope): return
	if result.get("ok") == true and result.get("resolved") == true:
		var row := _owner_training_row()
		if row.get("receipt") != result.get("receipt") or _training_decision(local_peer_id(), row).get("ok") != true:
			if envelope.op == "regional_ack": print("[regional_ack] committed reply ahead of the local row: local=%s/%s" % [str(row.get("action", "")), str(row.get("status", ""))])
			return
	if envelope.op in ["groom_prepare", "groom_commit", "groom_resume", "groom_cancel"]:
		_groom_service().call("receive", envelope, result)
		_foundation_requests.erase(correlation)
	elif envelope.op == "personal_view":
		_foundation_personal_cache = result.duplicate(true)
		_foundation_personal_cache_scope = _foundation_view_scope(envelope)
		homestead_personal_view_completed.emit()
	elif envelope.op in FOUNDATION_ACTIONS.ACTIONS or envelope.op in CHARACTER_ACTIONS.ACTIONS:
		# F34#4: a guest's camp request ends on the host's settled or refused
		# answer (the host already holds any durable row); the revision moved.
		if envelope.op == "camp_build" and ESSENCE._equivalent(_foundation_camp_pending.get("original"), envelope.intent) \
			and (result.get("settled") == true or result.get("terminal_refusal") == true):
			_foundation_camp_pending.clear()
			_foundation_requests.erase(correlation)
			_foundation_personal_cache.erase("registry_revision")
			homestead_personal_view()
		homestead_action_completed.emit(envelope.op, envelope.intent, result)
	elif envelope.op == "refine_start" and result.get("ok") != true:
		_game().call("push_world_message", str(result.get("reason", result.get("code", "Refining could not start."))))
	elif envelope.op == "master_duel" and result.get("ok") == true:
		_foundation_requests.erase(correlation) # A replay cannot cancel an admitted fight.
		var service := get_node_or_null(^"FoundationComposition/BreakthroughService")
		if service == null or service.call("accept_duel_offer", envelope.intent, result) != true:
			# Admission is already authoritative; inability to present must leave
			# that same encounter rather than create a second challenge.
			var world_node := _portal_world_node(str(_game().get("current_realm")))
			if world_node != null:
				for candidate: Node in world_node.find_children("*", "Node", true, false):
					if candidate.get_script() != null and FOUNDATION_DIRECTORS.has(candidate.get_script().resource_path):
						candidate.call("submit_encounter_intent", {"kind": "disengage", "encounter_id": result.get("encounter_id", "")})
	elif envelope.op == "rematch_start" and result.get("ok") == true:
		_foundation_requests.erase(correlation)
	foundation_reply_received.emit(envelope.duplicate(true), result.duplicate(true))


func foundation_rematch_start(trainer_id: String, tier: String, creature_uid: String,
		action_id: String = "") -> Dictionary:
	if action_id.is_empty(): action_id = Crypto.new().generate_random_bytes(16).hex_encode()
	if not is_host():
		var lifecycle := get_node_or_null(^"FoundationComposition/TravelLifecycle")
		if lifecycle == null or lifecycle.call("publish_now") != true: return FOUNDATION_ACTIONS.deny("rematch_context_changed")
	return _foundation_send("rematch_start", "rematch:" + trainer_id,
		{"trainer_id": trainer_id, "tier": tier, "creature_uid": creature_uid, "action_id": action_id}, -1)

func _foundation_handle(peer: int, envelope: Dictionary) -> Dictionary:
	if not _altar_envelope_matches(peer, envelope, ["op", "session_epoch", "world_namespace", "character_id", "station_key", "intent", "revision"]) \
		or not envelope.intent is Dictionary or not ESSENCE._integer(envelope.revision, -1, 2147483646): return FOUNDATION_ACTIONS.deny("invalid_station_envelope")
	if envelope.op == "personal_view": return _foundation_personal_view(peer)
	if envelope.op == "groom_prepare": return _groom_service().call("host_prepare", peer, envelope)
	if envelope.op == "groom_commit": return _groom_service().call("host_commit", peer, envelope)
	if envelope.op == "groom_resume": return _groom_service().call("host_resume", peer, envelope)
	if envelope.op == "groom_cancel": return _groom_service().call("host_cancel", peer, envelope)
	if envelope.op == "refine_start":
		var forge := get_node_or_null(^"FoundationComposition/ForgeHost")
		return forge.call("start", peer, envelope) if forge != null else _foundation_refusal("forge_unavailable")
	if envelope.op == "wild_capture_quote":
		var context := _foundation_capture_context(peer, envelope.station_key)
		if context.is_empty(): return _foundation_refusal("capture_offer_unavailable")
		var current: Dictionary = _character_authority.call("state", context.character_id)
		var quote := preload("res://scripts/net/foundation_capture_rules.gd").stage(current, envelope.intent, context)
		if quote.get("ok") != true: return _foundation_refusal(str(quote.get("code", "capture_choice_refused")))
		return {"ok": true, "pending_uid": context.creature.uid, "released_uid": envelope.intent.released_uid,
			"ceremony_id": context.offer_id, "expected_character_revision": context.expected_revision, "payout": quote.payout}
	if envelope.op in ["portal_arrival", "boss_relic", "dock_conclusion", "combat_mastery", "combat_round_reward", "waystone_touch", "home_key_owe", "home_key_deliver"]: return _foundation_refusal("host_producer_required")
	if envelope.op == "rematch_start":
		if envelope.intent.size() != 4 or envelope.revision != -1 \
			or not ESSENCE._component(envelope.intent.get("trainer_id")) or envelope.intent.get("tier") not in ["r1", "endgame"] \
			or not ESSENCE._component(envelope.intent.get("creature_uid")) \
			or not envelope.intent.get("action_id") is String or envelope.intent.action_id.length() != 32 \
			or not envelope.intent.action_id.is_valid_hex_number(false) or envelope.intent.action_id.to_lower() != envelope.intent.action_id \
			or envelope.station_key != "rematch:" + str(envelope.intent.trainer_id): return _foundation_refusal("invalid_rematch_intent")
		var rematches := get_node_or_null(^"FoundationComposition/Rematches")
		return rematches.call("request_start", peer, envelope.intent) if rematches != null and rematches.has_method("request_start") else _foundation_refusal("rematch_unavailable")
	if envelope.op == "master_duel":
		if envelope.intent.size() != 2 or not envelope.intent.get("master_id") is String or not envelope.intent.get("creature_uid") is String: return _foundation_refusal("invalid_duel_intent")
		var site := _foundation_master_site(peer, envelope.intent.master_id, false)
		var director := _foundation_master_director(site)
		if site == null or director == null: return _foundation_refusal("master_arena_unavailable")
		if peer != local_peer_id():
			return director.call("start_guest_master_duel", site, peer, _authority_character(peer), envelope.intent.creature_uid, preload("res://scripts/creatures/breakthrough.gd").master(envelope.intent.master_id))
		return director.call("start_master_duel", site, _authority_character(peer), envelope.intent.creature_uid, preload("res://scripts/creatures/breakthrough.gd").master(envelope.intent.master_id))
	if envelope.op == "research_claim":
		if preload("res://scripts/creatures/research_log.gd").config().get("runtime_enabled") != true: return _foundation_refusal("research_disabled")
		if envelope.intent.size() != 2 or not envelope.intent.get("species_id") is String or not envelope.intent.get("task_id") is String: return _foundation_refusal("invalid_research_claim")
		var world: RefCounted = _game().get("world")
		var character := _authority_character(peer)
		var row: Variant = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character))
		if row is Dictionary and row.get("action") == "research_claim" and row.get("intent") == envelope.intent: return _foundation_decision(peer, row)
		var result := preload("res://scripts/creatures/research_actions.gd").commit(self, peer, "research_claim", envelope.intent, {}, Callable(self, "_foundation_envelope_live").bind(peer, envelope.duplicate(true)))
		if result.get("durable") != true: return _foundation_refusal(str(result.get("code", "research_claim_refused")))
		row = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character))
		return _foundation_decision(peer, row) if row is Dictionary else FOUNDATION_ACTIONS.deny("research_decision_unavailable")
	if envelope.op in ["bounty_view", "bounty_claim", "bounty_reconcile"]:
		var composition := get_node_or_null(^"FoundationComposition")
		var host_adapter := composition.get_node_or_null(^"BountyHost") if composition != null else null
		if host_adapter == null: return FOUNDATION_ACTIONS.deny("bounty_unavailable")
		if envelope.op == "bounty_view": return host_adapter.call("personal_view", peer)
		if envelope.intent.size() != 1 or not envelope.intent.get("instance") is String: return _foundation_refusal("invalid_claim")
		var world: RefCounted = _game().get("world")
		var character := _authority_character(peer)
		var existing: Variant = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character))
		if existing is Dictionary and existing.get("action") == "bounty_claim" and existing.get("intent") == envelope.intent:
			return _foundation_decision(peer, existing)
		if envelope.op == "bounty_reconcile": return FOUNDATION_ACTIONS.deny("original_decision_unavailable")
		var saver: RefCounted = _game().get("save_system")
		if saver == null: return FOUNDATION_ACTIONS.deny("writer_unavailable")
		saver.call("finish_fallback")
		if saver.call("fallback_busy") == true or not _altar_envelope_matches(peer, envelope, ["op", "session_epoch", "world_namespace", "character_id", "station_key", "intent", "revision"]): return FOUNDATION_ACTIONS.deny("writer_busy")
		# Preserve the original board request's -1 quote and actual instance.
		# Re-entry after the saved care checkpoint remeasures this same live
		# actor/board/day context; immutable decisions above still redeliver first.
		if peer != local_peer_id():
			var context: Dictionary = host_adapter.call("_context", peer)
			if context.is_empty(): return _foundation_refusal("bounty_source_unavailable")
			var proposal := preload("res://scripts/world/bounty_board.gd").stage(
				_character_authority.call("state", character), int(context.expected_revision), "bounty_claim", envelope.intent, context)
			if proposal.get("ok") != true: return _foundation_refusal(str(proposal.get("code", "claim_refused")))
			var ready: Dictionary = _owner_passive_service().call("action_gate", peer, "foundation_request", envelope, context)
			if ready.get("ok") != true: return ready
		var result: Dictionary = host_adapter.call("claim", peer, envelope.intent)
		if result.get("durable") != true: return _foundation_refusal(str(result.get("code", "claim_refused")))
		var row: Dictionary = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character), {})
		return _foundation_decision(peer, row)
	if envelope.op == "loadout_quote":
		if _foundation_source(peer, envelope.station_key).is_empty(): return FOUNDATION_ACTIONS.deny("station_unavailable")
		var view := _foundation_personal_view(peer)
		for card: Dictionary in view.get("party", []):
			if card.uid == envelope.intent.get("creature_uid"):
				return {"ok": true, "creature_uid": card.uid, "loadout_revision": card.get("loadout_revision", 0), "registry_revision": view.registry_revision}
		return FOUNDATION_ACTIONS.deny("not_owned")
	if envelope.op not in FOUNDATION_ACTIONS.ACTIONS and envelope.op not in ["feast_cook", "feast_feed", "candy_feed", "master_chest", "essence_release"]: return FOUNDATION_ACTIONS.deny("action_unavailable")
	var character := _authority_character(peer)
	var world: RefCounted = _game().get("world")
	var row: Variant = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character))
	if row is Dictionary and row.get("action") == envelope.op and ESSENCE._equivalent(row.get("intent"), envelope.intent):
		return _foundation_decision(peer, row)
	if envelope.op == "groom" and peer != local_peer_id() \
		and (_groom_passive == null or not ESSENCE._equivalent(_groom_passive.get("committing"), envelope)):
		return _foundation_refusal("groom_prepared_baseline_required")
	# A removed source is allowed only when recovering that exact durable row.
	var saver: RefCounted = _game().get("save_system")
	if saver == null: return FOUNDATION_ACTIONS.deny("writer_unavailable")
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true or not _altar_envelope_matches(peer, envelope,
		["op", "session_epoch", "world_namespace", "character_id", "station_key", "intent", "revision"]) \
		or admitted_character_state(peer).is_empty(): return FOUNDATION_ACTIONS.deny("character_busy")
	var part := "bed" if envelope.op == "camp_rest" else "workbench"
	if envelope.op == "station_craft":
		var recipe: Dictionary = _game().get("items").call("recipe", str(envelope.intent.get("recipe_id", "")))
		var route := preload("res://scripts/build/forward_camp_rules.gd").recipe(str(envelope.intent.get("recipe_id", "")), recipe)
		if route.get("ok") == true: part = route.part
	var context: Dictionary = {}
	if envelope.op == "tm_teach": context = _personal_tm_context(peer, envelope.station_key)
	elif envelope.op == "tether_pouch": context = _personal_pouch_context(peer, envelope.station_key)
	elif envelope.op == "resource":
		var resources := get_node_or_null(^"FoundationComposition/Resources")
		if resources != null: context = resources.call("host_context", peer, envelope.station_key, envelope.intent)
	elif envelope.op == "groom": context = _foundation_groom_context(peer, envelope.station_key)
	elif envelope.op == "camp_build": context = _foundation_build_context(peer, envelope.intent)
	elif envelope.op == "starter_choice": context = _foundation_starter_context(peer)
	else: context = _foundation_source(peer, envelope.station_key, part)
	if envelope.op == "wild_capture": context = _foundation_capture_context(peer, envelope.station_key)
	if envelope.op == "relic_hang": context = _foundation_relic_context(peer, str(envelope.intent.get("biome", "")))
	if envelope.op == "relic_power": context = _foundation_relic_power_context(peer)
	if envelope.op == "regional_ack":
		var ending := preload("res://scripts/story/regional_homecoming.gd")
		var expected: Dictionary = ending.context(_game()) if peer == local_peer_id() else {}
		if peer != local_peer_id():
			var lifecycle := get_node_or_null(^"FoundationComposition/TravelLifecycle")
			if lifecycle != null: expected = lifecycle.call("host_ending_context", peer, _foundation_request_arrived_at)
		if config().get("redesign_ending_runtime_enabled") != true \
			or ending.acknowledgement_intent(expected, str(envelope.intent.get("stage", ""))) != envelope.intent \
			or (envelope.intent.get("stage") == ending.CREDITS_SEEN_FLAG \
				and not _character_authority.call("state", character).redesign_character.transaction_receipts.has("craft:regional_ending_homecoming_seen:" + character)): return _foundation_refusal("ending_context_changed")
		context = {"character_id": character, "expected_revision": int(_character_authority.call("revision", character)),
			"in_range": true, "in_combat": false, "earned_ending_ack": true, "source_key": "regional_ending:" + character}
	if envelope.op == "master_chest":
		if envelope.intent.size() != 1 or not envelope.intent.get("master_id") is String: return _foundation_refusal("invalid_chest_intent")
		var site := _foundation_master_site(peer, envelope.intent.master_id, true)
		if site != null:
			context = {"character_id": character, "expected_revision": int(_character_authority.call("revision", character)), "in_range": true, "in_combat": false,
				"master_id": envelope.intent.master_id, "source_key": "master_chest:" + envelope.intent.master_id}
	if envelope.op == "feast_feed" and STATION_RULES.config().get("runtime_enabled") == true and not _altar_peer_in_combat(peer):
		context = {"character_id": character, "expected_revision": int(_character_authority.call("revision", character)),
			"in_range": true, "in_combat": false, "owns_character": true, "source_key": "personal_feast_feed"}
	if envelope.op == "candy_feed" and envelope.station_key == "personal_candy_feed" and not _altar_peer_in_combat(peer):
		context = {"character_id": character, "expected_revision": int(_character_authority.call("revision", character)),
			"in_range": true, "in_combat": false, "owns_character": true, "source_key": "personal_candy_feed"}
	if envelope.op == "essence_release":
		# F27#1 guest release: the host pays only for a creature in this
		# admitted record (essence.stage_release); the newcomer stays the
		# owner's own untyped catch. The ceremony itself is owner-local.
		context = {}
		if peer != local_peer_id() and ESSENCE.config().get("ordinary_release_payout_enabled") == true \
			and str(envelope.station_key).begins_with("release_ceremony:") and str(envelope.station_key).length() <= 128 \
			and not _altar_peer_in_combat(peer):
			context = {"character_id": character, "expected_revision": int(_character_authority.call("revision", character)),
				"source_key": envelope.station_key, "in_range": true, "in_combat": false, "release_ceremony": true}
		if context.is_empty(): return _foundation_refusal("release_ceremony_unavailable") # Terminal: the guest releases unpaid.
	if context.is_empty() or context.expected_revision != envelope.revision: return _foundation_refusal("source_or_revision_changed")
	var cfg := STATION_RULES.config()
	if envelope.op in ["boss_relic", "tether_item"]: return _foundation_refusal("host_outcome_required")
	if envelope.op == "station_craft" and cfg.get("craft_runtime_enabled") != true: return _foundation_refusal("craft_disabled")
	if envelope.op == "feast_cook" and cfg.get("craft_runtime_enabled") != true: return _foundation_refusal("craft_disabled")
	if envelope.op == "den" and cfg.get("den_runtime_enabled") != true: return _foundation_refusal("den_disabled")
	if envelope.op == "gear":
		if preload("res://scripts/creatures/creature_gear.gd").config().get("feature_flags", {}).get("runtime_enabled") != true: return _foundation_refusal("gear_disabled")
		context.gear_runtime_authorized = true
	context.foundation_runtime_authorized = true
	var full: Dictionary = _character_authority.call("state", character)
	if envelope.op == "station_craft":
		var recipe_id := str(envelope.intent.get("recipe_id", ""))
		var recipe: Dictionary = _game().get("items").call("recipe", recipe_id)
		var unlock := str(recipe.get("unlocked_by", ""))
		# Flags are the admitted character's actual portable progression, not the host's merged view.
		var flags: Dictionary = _foundation_flags(peer)
		context.recipe_known = not recipe.is_empty() and (unlock.is_empty() or flags.get(unlock) == true) \
			and preload("res://scripts/creatures/creature_gear.gd").recipe_known(full, recipe, preload("res://scripts/creatures/creature_gear.gd").config())
		for flag: String in recipe.get("requires_personal_flags", []):
			if flags.get(flag) != true: context.recipe_known = false
	# A retained catch offer is a new full-character decision after its research
	# duties. Flush the exact owner's intervening care inputs before staging it.
	# Matching immutable pending/accepted decisions returned above stay untouched.
	if envelope.op == "wild_capture" and peer != local_peer_id():
		var ready: Dictionary = _owner_passive_service().call("capture_gate", peer, envelope, context)
		if ready.get("ok") != true: return ready
	if envelope.op in OWNER_PASSIVE.REQUEST_ACTIONS and peer != local_peer_id():
		var rules: Script = FOUNDATION_ACTIONS if envelope.op in FOUNDATION_ACTIONS.ACTIONS else preload("res://scripts/net/character_action_rules.gd")
		var preview: Dictionary = rules.stage(full, envelope.revision, envelope.op, envelope.intent, context,
			preload("res://scripts/net/character_record_rules.gd").errors)
		if preview.get("ok") != true: return _foundation_refusal(str(preview.get("code", "stage_refused")))
		var ready: Dictionary = _owner_passive_service().call("action_gate", peer, "foundation_request", envelope, context)
		if ready.get("ok") != true: return ready
	var stage: Dictionary = _character_authority.call("stage_character_action", character, envelope.revision, envelope.op, envelope.intent, context)
	if stage.get("ok") != true: return _foundation_refusal(str(stage.get("code", stage.get("reason", "stage_refused"))))
	var accepted: Dictionary = _character_authority.call("staged_creature_training", stage)
	var writer := get_node_or_null(^"LedgerRpc")
	var journal: Dictionary = writer.call("journal_creature_training_prepared", peer, character, accepted) if writer != null else {}
	var saved: bool = journal.get("ok") == true and journal.get("durable") == true
	if _character_authority.call("finish_creature_training", stage, saved) != true: return FOUNDATION_ACTIONS.deny("stage_changed")
	if not saved: return _foundation_journal_refusal(envelope.op, journal)
	writer.call("publish_creature_training", peer, character, accepted.receipt)
	if envelope.op == "starter_choice": _character_authority.call("record_personal_flag", character, STARTER_CHOICE.FLAG, true)
	return _foundation_decision(peer, world.reward_deliveries.get(journal.delivery_id, {}))

func _foundation_journal_refusal(action: String, journal: Dictionary) -> Dictionary:
	var code := str(journal.get("code", "world_save_failed"))
	# The actual prepared BOOL writer rolls back the hidden host stage. Keep
	# the TM's original request for its next attempt, rather than minting a new
	# teach ID. Malformed/foreign/semantic refusals retain their terminal meaning.
	if action in ["tm_teach", "resource", "groom", "tether_pouch"] and code in ["training_journal_failed", "world_not_prepared", "world_save_failed"]:
		return {"ok": false, "resolved": false, "durable": false, "terminal_refusal": false, "code": code, "reason": code}
	return _foundation_refusal(code)

func _foundation_refusal(code: String) -> Dictionary:
	return {"ok": false, "code": code, "reason": code, "resolved": true, "durable": false, "terminal_refusal": true}

func _foundation_envelope_live(peer: int, envelope: Dictionary) -> bool:
	return _altar_envelope_matches(peer, envelope, ["op", "session_epoch", "world_namespace", "character_id", "station_key", "intent", "revision"]) and not admitted_character_state(peer).is_empty()

func _foundation_decision(peer: int, row: Dictionary) -> Dictionary:
	var result := _training_decision(peer, row)
	result.settled = result.get("ok") == true and result.get("saved") == true
	result.owner_saved = result.settled
	result.owner_acknowledged = result.settled
	return result

func _foundation_flags(peer: int) -> Dictionary:
	if peer == local_peer_id():
		var flags := {}
		for id: String in _game().get("local").flags.call("save_data").get("flags", []): flags[id] = true
		return flags
	return _character_authority.call("personal_flags", _authority_character(peer))

func foundation_record_personal_flags(delta: Dictionary) -> void:
	if not is_host() or _character_authority == null: return
	for op: Variant in delta.get("ops", []):
		if not op is Dictionary or op.get("scope") != "player" or op.get("op") != "flag": continue
		for peer: int in op.get("peers", []):
			var character := _authority_character(peer)
			if not character.is_empty(): _character_authority.call("record_personal_flag", character, str(op.get("id", "")), op.get("value", true) == true)
			# A host-authored walk_out flag op arms the reconcile too. Opening
			# beats are otherwise guest-local; a guest's verified gift request
			# (note_opening_gift_requested) is the host's usual evidence.
			if str(op.get("id", "")) == OPENING_HOME_KEY.PAST_FIRST_CATCH_FLAG and op.get("value", true) == true: arm_legacy_home_key_check(peer)

## The actual host ending calls this only after its original claim saves.
## Guests cannot replace a flag dictionary or choose another claim/character.
func foundation_stormwood_answer(source: Node, peer: int, claim: Dictionary) -> bool:
	if not is_host() or not is_instance_valid(source) or source.get_script() != preload("res://scripts/world/stormwood_ending.gd") \
		or _game() == null or _game().session != self or source.get("session") != self \
		or source.get("world") != _portal_world_node("stormwood") or source.get("_foundation_world_binding") == null \
		or source.get("_foundation_world_binding").get_ref() != _game().world: return false
	var character := _authority_character(peer)
	if character.is_empty() or admitted_character_state(peer).is_empty() or claim.get("settled") != true \
		or not claim.get("kept") is bool or source.call("_saved_state").get("claims", {}).get(character, {}) != claim: return false
	var id := preload("res://scripts/world/stormwood_ending.gd").claim_id(claim)
	var kept: bool = claim.kept
	if id.is_empty() or not _game().world.flags.call("has", preload("res://scripts/world/stormwood_ending.gd").resolution_flag(kept, character)): return false
	var flags: Dictionary = _character_authority.call("personal_flags", character)
	var marker := "stormwood:regional_outcome:%s:%s" % [id, "accepted" if kept else "refused"]
	var has_original := false
	for flag: String in flags:
		if flag.begins_with("stormwood:regional_outcome:"): has_original = true
	for flag: String in ["stormwood:legendary_ceremony_settled", preload("res://scripts/world/stormwood_ending.gd").answer_flag(id, kept)]:
		_character_authority.call("record_personal_flag", character, flag, true)
	if not has_original: _character_authority.call("record_personal_flag", character, marker, true)
	if kept: _character_authority.call("record_personal_flag", character, "stormwood:legendary_offer_accepted", true)
	return true

func _foundation_personal_view(peer: int) -> Dictionary:
	if admitted_character_state(peer).is_empty(): return {}
	var character := _authority_character(peer)
	var full: Dictionary = _character_authority.call("state", character)
	full.registry_revision = int(_character_authority.call("revision", character))
	return full

## A settled owner row is this character's record at its new host revision.
## The cached view must not quote an older one: the next request (a relic
## power chosen right after a Home Key trip home) would be refused as stale.
func _advance_personal_view_revision(row: Dictionary) -> void:
	var revision: Variant = row.get("character_revision")
	if is_host() or (not revision is int and not revision is float) \
		or _foundation_personal_cache.get("character_id") != row.get("character_id"): return
	if int(_foundation_personal_cache.get("registry_revision", -1)) < int(revision):
		_foundation_personal_cache.registry_revision = int(revision)

func homestead_personal_view() -> Dictionary:
	if is_host(): return _foundation_personal_view(local_peer_id())
	var scope := _foundation_view_scope(_altar_envelope("personal_view", "homestead_view"))
	_personal_view_for_scope(scope)
	_foundation_send("personal_view", "homestead_view", {}, -1)
	return _personal_view_for_scope(scope)

static func _foundation_view_scope(envelope: Dictionary) -> Dictionary:
	if envelope.is_empty(): return {}
	return {"character_id": envelope.get("character_id"), "world_namespace": envelope.get("world_namespace"), "session_epoch": envelope.get("session_epoch")}

func _personal_view_for_scope(scope: Dictionary) -> Dictionary:
	if scope.is_empty() or scope != _foundation_personal_cache_scope \
		or _foundation_personal_cache.get("character_id") != scope.get("character_id"):
		_foundation_personal_cache = {}
		_foundation_personal_cache_scope = {}
	return _foundation_personal_cache.duplicate(true)

func foundation_dock_conclusion(source: Node, original: Dictionary) -> Dictionary:
	if not is_host() or not is_instance_valid(source) or source.get_script() == null \
		or source.get_script().resource_path != "res://scripts/world/water_chapter.gd" \
		or source.get("_game") != _game() or source.get("_dock_pending") != original \
		or config().get("redesign_ending_runtime_enabled") != true: return FOUNDATION_ACTIONS.deny("actual_dock_producer_required")
	var character := _authority_character(local_peer_id())
	var world: RefCounted = _game().get("world")
	if original.get("character_id") != character or original.get("world_namespace") != world.reward_delivery_namespace: return FOUNDATION_ACTIONS.deny("dock_context_changed")
	var row: Dictionary = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character), {})
	if row.get("action") == "dock_conclusion" and row.get("intent") == original:
		get_node(^"LedgerRpc").call("_process_creature_training", row)
		return _foundation_decision(local_peer_id(), world.reward_deliveries.get(row.delivery_id, {}))
	if source.call("dock_departure_ready") != true or _altar_peer_in_combat(local_peer_id()): return FOUNDATION_ACTIONS.deny("dock_departure_not_ready")
	# The local five accumulate passive care and travel between offers. Freeze
	# their current admitted record at this real producer, as station actions do.
	if admitted_character_state(local_peer_id()).is_empty(): return FOUNDATION_ACTIONS.deny("character_busy")
	var context := {"character_id": character, "expected_revision": int(_character_authority.call("revision", character)),
		"source_key": original.dock_id, "world_namespace": world.reward_delivery_namespace, "realm": "water",
		"in_range": true, "in_combat": false, "civilian_departure_ready": true, "foundation_runtime_authorized": true}
	var result := FOUNDATION_ACTIONS.commit(_character_authority, get_node(^"LedgerRpc"), local_peer_id(), character,
		context.expected_revision, "dock_conclusion", original, context)
	if result.get("durable") != true: return result
	return _foundation_decision(local_peer_id(), world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character), {}))

## F27#1: a guest's ordinary catch-overflow release, paid by the host from
## its admitted record (scripts/net/essence_release_service.gd).
func request_essence_release(pending_uid: String, intent: Dictionary, revision: int) -> Dictionary:
	if is_host(): return _foundation_refusal("host_release_is_local")
	return _foundation_send("essence_release", "release_ceremony:" + pending_uid, intent, revision)

func request_research_claim(intent: Dictionary) -> Dictionary:
	return _foundation_send("research_claim", "research_journal", intent, -1)

func request_relic_hang(biome: String) -> Dictionary:
	var view := homestead_personal_view()
	return _foundation_send("relic_hang", "shrine:" + biome, {"biome": biome}, int(view.get("registry_revision", -1)))

func foundation_grounded_arrival(producer: Node, envelope: Dictionary, permit: Dictionary) -> Dictionary:
	var peer: int = int(permit.get("peer_id", 0))
	if producer != get_node_or_null(^"FoundationComposition/PortalArrival") or not is_host() \
		or peer < 1 or envelope.get("session_epoch") != _altar_current_epoch() or envelope.get("character_id") != _authority_character(peer) \
		or envelope.get("world_instance_id") != _game().get("world").reward_delivery_namespace \
		or producer.call("arrival_binding", envelope, permit) != true: return FOUNDATION_ACTIONS.deny("arrival_binding_changed")
	var character: String = envelope.character_id
	var intent := {"permit_id": str(permit.request_id), "realm": str(permit.realm), "entry_id": str(permit.entry_id)}
	var world: RefCounted = _game().get("world")
	var row: Dictionary = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character), {})
	if row.get("action") == "portal_arrival" and row.get("intent") == intent:
		get_node(^"LedgerRpc").call("_process_creature_training", row)
		return _foundation_decision(peer, row)
	if peer != local_peer_id():
		var request := preload("res://scripts/net/owner_passive_preparation.gd").portal_request(envelope, permit)
		var passive := _owner_passive_service()
		var binding: Dictionary = passive.get("committing")
		if binding.get("source_kind") != "portal_arrival" or binding.get("character") != character \
			or not preload("res://scripts/net/owner_passive_preparation.gd").exact(binding.get("envelope"), request):
			return passive.call("portal_grounded", peer, request)
	# The host's own record drifts (care, bond walking) through the raise, fade
	# and load. Refresh it from the live save right before staging, as every
	# other host-local request does, so the owner apply baseline matches.
	elif admitted_character_state(peer).is_empty(): return FOUNDATION_ACTIONS.deny("character_unavailable")
	var context := {"character_id": character, "expected_revision": int(_character_authority.call("revision", character)),
		"in_range": true, "in_combat": false, "foundation_runtime_authorized": true, "grounded_arrival": true,
		"source_key": "arrival:" + intent.permit_id, "permit_id": intent.permit_id, "realm": intent.realm, "entry_id": intent.entry_id,
		"world_namespace": world.reward_delivery_namespace}
	if envelope.get("payload", {}).get("kind") == "home_key_finish":
		context.ending_outcome = preload("res://scripts/story/regional_homecoming.gd").personal_outcome(_foundation_flags(peer))
	var result := FOUNDATION_ACTIONS.commit(_character_authority, get_node(^"LedgerRpc"), peer, character, context.expected_revision, "portal_arrival", intent, context)
	if result.get("durable") != true: return result
	return _foundation_decision(peer, world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character), {}))

## F31#2: the relic power screen opens at ANY Shrine Room pedestal outside
## combat (UX §shrine). Same actual-position proof as a hang, any pedestal.
func _foundation_relic_power_context(peer: int) -> Dictionary:
	if not portal_runtime_ready() or _altar_peer_in_combat(peer): return {}
	var writer := get_node_or_null(^"LedgerRpc")
	if writer == null: return {}
	var actor: Dictionary = writer.call("_water_actor_context", peer, {})
	if actor.get("realm") != "meadows" or not actor.get("position") is Vector3: return {}
	var meadows := _portal_world_node("meadows")
	if meadows == null: return {}
	var radius := float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").arch.interaction_radius_m)
	for pedestal: Node in get_tree().get_nodes_in_group("crossing_hall_pedestals"):
		if meadows.is_ancestor_of(pedestal) and actor.position.distance_to((pedestal as Node3D).global_position) <= radius:
			return {"character_id": _authority_character(peer), "expected_revision": int(_character_authority.call("revision", _authority_character(peer))),
				"in_range": true, "in_combat": false, "shrine_power": true, "realm": "meadows", "source_key": "shrine_power"}
	return {}


func request_relic_power(heart_id: String) -> Dictionary:
	var view := homestead_personal_view()
	var edit_id := Crypto.new().generate_random_bytes(16).hex_encode()
	return _foundation_send("relic_power", "shrine_power", {"heart_id": heart_id, "edit_id": edit_id}, int(view.get("registry_revision", -1)))


func _foundation_relic_context(peer: int, biome: String) -> Dictionary:
	if not portal_runtime_ready() or _altar_peer_in_combat(peer): return {}
	var writer := get_node_or_null(^"LedgerRpc")
	if writer == null: return {}
	var actor: Dictionary = writer.call("_water_actor_context", peer, {})
	if actor.get("realm") != "meadows" or not actor.get("position") is Vector3: return {}
	var found: Node3D
	var meadows := _portal_world_node("meadows")
	if meadows == null: return {}
	for pedestal: Node in get_tree().get_nodes_in_group("crossing_hall_pedestals"):
		if pedestal.get_meta("biome", "") != biome or not meadows.is_ancestor_of(pedestal): continue
		if found != null: return {}
		found = pedestal as Node3D
	if found == null or actor.position.distance_to(found.global_position) > float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").arch.interaction_radius_m): return {}
	return {"character_id": _authority_character(peer), "expected_revision": int(_character_authority.call("revision", _authority_character(peer))),
		"in_range": true, "in_combat": false, "realm": "meadows", "pedestal_biome": biome, "source_key": "shrine:" + biome}

func foundation_research_source(director: Node, encounter_id: String, peer: int, kind: String, source_id: String, species: String, move_id: String = "", night: Variant = null) -> Dictionary:
	if not is_host() or not is_instance_valid(director) or director.get("_session") != self \
		or director.get_script() == null or not FOUNDATION_DIRECTORS.has(director.get_script().resource_path): return {"ok": false}
	var research_enabled: bool = preload("res://scripts/creatures/research_log.gd").config().get("runtime_enabled") == true
	var bounty_enabled: bool = preload("res://scripts/world/bounty_board.gd").config().get("runtime_enabled") == true
	var host: RefCounted = director.get("_encounter_host")
	var original: Dictionary = director.call("retained_research_source", source_id)
	if not research_enabled and not (bounty_enabled and kind == "catch") and original.get("capture_offer", {}).is_empty():
		return {"ok": true, "durable": true, "disabled": true}
	if original.get("world_namespace") != _game().get("world").reward_delivery_namespace or original.get("session_id") != _altar_current_epoch() \
		or original.get("encounter_id") != encounter_id or original.get("peer") != peer or original.get("kind") != kind \
		or original.get("species") != species or original.get("move_id") != move_id or original.get("night") != night: return {"ok": false}
	var record: Dictionary = original.get("record", {})
	var character := str(record.get("participants", {}).get(peer, {}).get("character_id", ""))
	if character.is_empty(): return {"ok": false}
	if kind in ["sight", "catch"] and record.get("opponent", {}).get("species_id") != species: return {"ok": false}
	if kind == "catch" and (record.get("kind") != "wild" or (research_enabled and not night is bool)): return {"ok": false}
	var context := {"source_key": "encounter:" + encounter_id, "event_confirmed": true,
		"world_namespace": _game().get("world").reward_delivery_namespace, "session_id": _altar_current_epoch(),
		"event_id": source_id, "participants": [character], "species_id": species, "kind": kind}
	if kind == "cast": context.move_id = move_id
	if kind == "catch":
		context.wild = true
		context.night = night
	var duties: Array = []
	if kind == "catch" and not original.get("capture_offer", {}).is_empty():
		var offer: Dictionary = original.capture_offer
		if not preload("res://scripts/net/foundation_capture_rules.gd").original_offer_matches(offer,
			original.get("capture_card", {}), original.world_namespace, original.session_id, str(record.get("realm", "")), character): return {"ok": false}
		duties.append({"character_id": character, "action": "capture_offer", "intent": {}, "context": offer.duplicate(true)})
	if research_enabled: duties.append({"character_id": character, "action": "research_event", "intent": {}, "context": context})
	if bounty_enabled and kind == "catch":
		var captured: Dictionary = original.get("capture_card", {})
		if captured.get("species_id") != species or str(captured.get("uid", "")).is_empty(): return {"ok": false}
		var instances: Array = record.participants[peer].get("foundation_bounty_instances", [])
		if not instances.is_empty():
			duties.append({"character_id": character, "action": "bounty_event", "intent": {}, "context": {
				"source_key": "halda_bounty_event", "event_confirmed": true, "world_namespace": original.world_namespace,
				"session_id": original.session_id, "event_id": source_id, "participants": [character],
				"issued_instances": instances.duplicate(), "kind": "catch_trait", "biome": preload("res://scripts/data/biome_order.gd").canonical_id(str(record.realm)),
				"traits": captured.get("rolled_traits", []).duplicate()}})
	if duties.is_empty(): return {"ok": true, "durable": true, "disabled": true}
	return get_node(^"LedgerRpc").call("journal_foundation_event", source_id, duties)

func foundation_alpha_resolution(director: Node, encounter_id: String, outcome: String, capture: Dictionary = {}) -> Dictionary:
	var producer := get_node_or_null(^"FoundationComposition/Alphas")
	return producer.call("resolution", director, encounter_id, outcome, capture) if producer != null else {"ok": false, "durable": false}

func foundation_alpha_first_spawn(director: Node, site_id: String) -> Dictionary:
	var producer := get_node_or_null(^"FoundationComposition/Alphas")
	return producer.call("first_spawn", director, site_id) if producer != null else {}

func foundation_defeat_obligations(director: Node, original: Dictionary) -> Dictionary:
	var research_enabled: bool = preload("res://scripts/creatures/research_log.gd").config().get("runtime_enabled") == true
	var bounty_enabled: bool = preload("res://scripts/world/bounty_board.gd").config().get("runtime_enabled") == true
	if not research_enabled and not bounty_enabled: return {"ok": true, "durable": true, "disabled": true}
	if not is_host() or director.get("_session") != self or director.get_script() == null or not FOUNDATION_DIRECTORS.has(director.get_script().resource_path) \
		or director.call("host_wild_victory_source", str(original.get("record", {}).get("encounter_id", ""))) != original \
		or original.get("world_namespace") != _game().get("world").reward_delivery_namespace or original.get("session_id") != _altar_current_epoch() \
		or original.get("accepted", {}).get("delta", {}).get("killed") != true or original.get("enemy_record", {}).get("fainted") != true: return {"ok": false, "durable": false}
	var participants: Array[String] = []
	for participant: Variant in original.record.participants.values():
		if not participant is Dictionary or str(participant.get("character_id", "")).is_empty(): return {"ok": false, "durable": false}
		participants.append(participant.character_id)
	var duties: Array = []
	for character: String in participants:
		if research_enabled: duties.append({"character_id": character, "action": "research_event", "intent": {}, "context": {
			"source_key": "encounter:" + str(original.record.encounter_id), "event_confirmed": true,
			"world_namespace": original.world_namespace, "session_id": original.session_id, "event_id": original.source_id,
			"participants": participants.duplicate(), "species_id": original.enemy_record.species_id, "kind": "defeat", "opponent_defeated": true}})
		if bounty_enabled:
			var runtime: Node = director.call("_shared_host_fight", str(original.record.encounter_id))
			var body: Node3D = runtime.call("body") if runtime != null else null
			if body == null or preload("res://scripts/repeatables/alpha_respawns.gd").site(str(body.get_meta("foundation_alpha_site", ""))).is_empty(): continue
			for participant: Dictionary in original.record.participants.values():
				var instances: Array = participant.get("foundation_bounty_instances", [])
				if participant.character_id != character or instances.is_empty(): continue
				duties.append({"character_id": character, "action": "bounty_event", "intent": {}, "context": {
					"source_key": "halda_bounty_event", "event_confirmed": true, "world_namespace": original.world_namespace,
					"session_id": original.session_id, "event_id": "defeat:" + str(original.source_id), "participants": participants.duplicate(),
					"issued_instances": instances.duplicate(), "kind": "defeat_alpha", "biome": preload("res://scripts/data/biome_order.gd").canonical_id(str(original.record.realm)), "traits": []}})
	if duties.is_empty(): return {"ok": true, "durable": true, "no_duties": true}
	return get_node(^"LedgerRpc").call("journal_foundation_event", "defeat:" + str(original.source_id), duties)

func foundation_rematch_participant_context(peer: int) -> Dictionary:
	if not is_host() or admitted_character_state(peer).is_empty(): return {}
	var character := _authority_character(peer)
	var flags := _foundation_flags(peer)
	var full: Dictionary = _character_authority.call("state", character)
	if full.redesign_character.transaction_receipts.has("craft:regional_ending_regional_credits_seen:" + character): flags.regional_credits_seen = true
	var instances: Array[String] = []
	for slot: Dictionary in full.redesign_character.get("bounties", {}).get("slots", []):
		if slot.get("complete") != true and not instances.has(str(slot.get("instance", ""))): instances.append(str(slot.instance))
	return {"character_id": character, "world_flags": _game().world.flags.call("all_set"), "personal_flags": flags.keys(),
		"bounty_instances": instances}

func foundation_rematch_join_allowed(peer: int, spec: Dictionary) -> bool:
	var context := foundation_rematch_participant_context(peer)
	return not context.is_empty() and preload("res://scripts/repeatables/rematch_rules.gd").available(str(spec.get("id", "")),
		str(spec.get("rematch", {}).get("tier", "")), context.world_flags, context.personal_flags)

func foundation_rematch_outcome(director: Node, spec: Dictionary, won: bool) -> Dictionary:
	if not is_host() or not is_instance_valid(director) or director.get("_session") != self \
		or director.get_script() == null or not FOUNDATION_DIRECTORS.has(director.get_script().resource_path) \
		or spec != director.get("_trainer_spec") or not spec.get("rematch") is Dictionary: return {"ok": false}
	var outcome: String = director.get("_manager").call("outcome")
	if not won: return {"ok": outcome in ["lost", "fled"], "durable": outcome in ["lost", "fled"]}
	if outcome != "won": return {"ok": false}
	var original: Dictionary = director.get_meta("foundation_rematch_pending", {})
	if original.is_empty():
		var record: Dictionary = director.get("_encounter")
		var participants: Array = director.call("retained_boss_participants")
		if participants.is_empty() or str(record.get("encounter_id", "")).is_empty(): return {"ok": false}
		var game := _game()
		game.call("_sync_clock_state")
		if not is_finite(float(game.world.clock_elapsed_seconds)) or float(game.world.clock_elapsed_seconds) < 0: return {"ok": false}
		var duties: Array = []
		var source_id := "rematch:%s:%s" % [spec.id, record.encounter_id]
		for character: String in participants:
			var admission: Dictionary = director.get("_trainer_foundation_admissions").get(character, {})
			if admission.get("character_id") != character: return {"ok": false}
			var intent := {"trainer_id": str(spec.id), "tier": str(spec.rematch.tier), "encounter_id": str(record.encounter_id)}
			duties.append({"character_id": character, "action": "rematch_win", "intent": intent, "context": {
				"source_key": "rematch:" + str(spec.id), "validated_host_outcome": "win", "encounter_id": record.encounter_id,
				"trainer_id": str(spec.id), "tier": str(spec.rematch.tier), "participants": participants.duplicate(),
				"world_namespace": game.world.reward_delivery_namespace, "session_id": _altar_current_epoch(),
				"world_seconds": int(floor(game.world.clock_elapsed_seconds)), "world_flags": admission.world_flags.duplicate(),
				"personal_flags": admission.personal_flags.duplicate()}})
			if preload("res://scripts/repeatables/rematch_rules.gd").profile(str(spec.id)).kind == "master":
				duties.back().context.single_creature_duel = true
				duties.back().context.creature_uid = str(director.get("_master_duel").get("creature_uid", ""))
			if preload("res://scripts/world/bounty_board.gd").config().get("runtime_enabled") == true and not admission.get("bounty_instances", []).is_empty():
				duties.append({"character_id": character, "action": "bounty_event", "intent": {}, "context": {
					"source_key": "halda_bounty_event", "event_confirmed": true, "world_namespace": game.world.reward_delivery_namespace,
					"session_id": _altar_current_epoch(), "event_id": source_id, "participants": participants.duplicate(),
					"issued_instances": admission.bounty_instances.duplicate(), "kind": "rematch",
					"biome": preload("res://scripts/data/biome_order.gd").canonical_id(str(record.realm)), "traits": []}})
		original = {"source_id": source_id, "duties": duties}
		director.set_meta("foundation_rematch_pending", original.duplicate(true))
	var result: Dictionary = get_node(^"LedgerRpc").call("journal_foundation_event", original.source_id, original.duties)
	if result.get("durable") == true: director.remove_meta("foundation_rematch_pending")
	return result

func foundation_boss_outcome(director: Node, spec: Dictionary, record: Dictionary) -> Dictionary:
	var handoff := preload("res://scripts/net/encounter_rewards.gd").chapter_hand_off(str(spec.get("id", "")), str(director.call("_encounter_realm")))
	if handoff.is_empty() or config().get("redesign_boss_handoff_runtime_enabled") != true: return {"ok": true, "durable": true, "disabled": true}
	if not is_host() or director.get("_session") != self or director.get_script() == null \
		or not FOUNDATION_DIRECTORS.has(director.get_script().resource_path) or director.get("_trainer_spec") != spec \
		or director.get("_manager").call("outcome") != "won" or str(record.get("encounter_id", "")).is_empty(): return {"ok": false, "durable": false}
	var participants: Array = director.call("retained_boss_participants")
	if participants.is_empty(): return {"ok": false, "durable": false}
	var duties: Array = []
	for character: String in participants:
		duties.append({"character_id": character, "action": "boss_relic",
			"intent": {"trainer_id": str(spec.id), "biome": handoff.relic_biome, "encounter_id": record.encounter_id},
			"context": {"source_key": "boss:" + str(spec.id), "realm": handoff.runtime_realm,
				"validated_host_outcome": "win", "encounter_id": record.encounter_id, "participants": participants.duplicate()}})
	return get_node(^"LedgerRpc").call("journal_foundation_event", "boss:" + str(spec.id) + ":" + str(record.encounter_id), duties)

func _retry_foundation_events() -> void:
	if not is_host() or _game() == null or _character_authority == null: return
	_retry_combat_mastery_sources()
	var world: RefCounted = _game().get("world")
	var handled := {}
	var research_no_progress := {}
	var ordinary_waiting: Dictionary = _ordinary_round_pending_characters()
	var combat_held := {}
	var share_wait := {}
	for work: Dictionary in FOUNDATION_RETRY_ORDER.ordered(world.reward_deliveries, world.reward_delivery_namespace, world.world_id):
		var raw: Dictionary = work.event
		var duty: Dictionary = work.duty
		if duty.action == "capture_offer": continue # Requires the owner's real five-slot choice.
		# Ruling R2: settled durably in the world, whatever its receipt's fate.
		if RETAINED_SETTLEMENT.duty_settled(world.redesign_world, str(raw.delivery_id), duty): continue
		if duty.action == "boss_relic":
			var handoff := preload("res://scripts/net/encounter_rewards.gd").chapter_hand_off(str(duty.intent.trainer_id), str(duty.context.realm))
			if not preload("res://scripts/net/encounter_rewards.gd").chapter_delivery_ready(handoff, world.flags.all_set()): continue
		var peer := int(_registry.call("peer_for_character", duty.character_id))
		if peer < 1 or handled.has(duty.character_id): continue
		if combat_held.has(duty.character_id) and duty.action not in ["combat_round_reward", "wild_defeat_share"]: continue
		# F27: a guest's wild-win share settles its fight HP first; that fight's
		# research/bounty duties wait behind it, as trainer rounds' do.
		if duty.action != "wild_defeat_share" and peer != local_peer_id():
			if not share_wait.has(duty.character_id): share_wait[duty.character_id] = _guest_wild_share_outstanding(duty.character_id, world)
			if share_wait[duty.character_id] == true: continue
		if duty.action == "combat_mastery" and _altar_peer_in_combat(peer): continue
		var latest: Dictionary = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, duty.character_id), {})
		var receipt := _foundation_duty_receipt(duty, world.reward_delivery_namespace)
		if not receipt.is_empty() and TRAINING_WORLD.training_row_valid(latest, world.reward_delivery_namespace, world.world_id) \
			and latest.status == "accepted" and latest.after.redesign_character.transaction_receipts.has(receipt): continue
		if not receipt.is_empty() and TRAINING_WORLD.training_row_valid(latest, world.reward_delivery_namespace, world.world_id) \
			and latest.status == "pending" and latest.after.redesign_character.transaction_receipts.has(receipt):
			get_node(^"LedgerRpc").call("_process_creature_training", latest)
			handled[duty.character_id] = true
			continue # Re-deliver the immutable original; never prepare it again.
		if duty.action == "combat_mastery" and ordinary_waiting.has(duty.character_id): continue
		var research_signature := ""
		if duty.action == "research_event":
			research_signature = JSON.stringify([duty.character_id, peer, duty.context.world_namespace,
				duty.context.session_id, duty.context.species_id, duty.context.kind,
				duty.context.get("move_id"), duty.context.get("night")])
			# A real no-progress result excludes only equivalent research in
			# this synchronous scan at the same authority revision. Retained
			# originals and receipt/ACK recovery above still run for every duty.
			if research_no_progress.has(research_signature) \
				and research_no_progress[research_signature] == int(_character_authority.call("revision", duty.character_id)): continue
		# Retained historical duties and in-fight mastery need no new action.
		# Project/recover authority only after those exclusions; a long fight
		# can retain hundreds of mastery sources for this same character.
		if admitted_character_state(peer).is_empty(): continue
		if duty.action == "boss_relic" and (_character_authority.call("state", duty.character_id) as Dictionary).get("redesign_character", {}).get("transaction_receipts", []).has("defeat:boss_%s:%s" % [duty.intent.trainer_id, duty.character_id]):
			# Legacy personal decisions are complete; preserve their original
			# identity without starving this character's later owed duties.
			continue
		var context: Dictionary = duty.context.duplicate(true)
		if duty.action == "boss_relic":
			context.boss_settlement_world_flags = world.flags.all_set().duplicate()
			context.world_namespace = world.reward_delivery_namespace
		context.character_id = duty.character_id
		context.expected_revision = int(_character_authority.call("revision", duty.character_id))
		context.in_range = true
		context.retained_event = raw.delivery_id
		var result: Dictionary
		if duty.action == "research_event":
			result = preload("res://scripts/creatures/research_actions.gd").commit(self, peer, duty.action, duty.intent, context)
		elif duty.action == "bounty_event":
			var bounty := get_node_or_null(^"FoundationComposition/BountyHost")
			if bounty == null: continue
			result = bounty.call("confirmed_event", peer, str(duty.context.event_id))
		else:
			context.in_combat = false
			context.foundation_runtime_authorized = true
			if peer != local_peer_id() and duty.action in ["master_win", "boss_relic", "combat_mastery", "combat_round_reward", "wild_defeat_share"]:
				var ready: Dictionary = _owner_passive_service().call("gate", peer, duty.action, duty.intent, context)
				if ready.get("ok") != true:
					_note_duty_hold(duty, "owner passive gate " + str(ready.get("code", "")))
					handled[duty.character_id] = true
					continue
			if duty.action in FOUNDATION_ACTIONS.ACTIONS:
				result = FOUNDATION_ACTIONS.commit(_character_authority, get_node(^"LedgerRpc"), peer, duty.character_id, context.expected_revision, duty.action, duty.intent, context)
			else: result = preload("res://scripts/net/character_action_rules.gd").commit_host_action(_character_authority, get_node(^"LedgerRpc"), peer, duty.character_id, context.expected_revision, duty.action, duty.intent, context)
		if duty.action == "wild_defeat_share" and result.get("ok") != true and result.get("durable") != true \
			and _wild_share_permanent(str(result.get("code", ""))):
			# Bounded release: a share that can never stage stops holding this
			# guest's requests and duties (logged once; never paid twice).
			var refused_key: String = str(raw.delivery_id) + "|" + str(duty.character_id)
			if not _wild_share_refused.has(refused_key):
				_wild_share_refused[refused_key] = str(result.code)
				push_warning("[session] wild_defeat_share for %s refused for good: %s" % [duty.character_id, str(result.code)])
		if duty.action == "research_event" and result.get("code") == "research_no_progress":
			# Admission inside the real research adapter may refresh the local
			# record; remember its resulting revision, never a character state.
			research_no_progress[research_signature] = int(_character_authority.call("revision", duty.character_id))
		# Research from a fight waits for that fight to end, and the fight's next
		# round waits on this character's round reward behind it. Only that
		# round reward may pass a research duty held by combat; every other
		# later duty keeps waiting in order, as before.
		if duty.action == "research_event" and result.get("code") == "combat_still_active":
			combat_held[duty.character_id] = true
			continue
		if result.get("resolved") != true and result.get("code") not in ["research_no_progress", "no_matching_bounty"]:
			_note_duty_hold(duty, str(result.get("code", "unresolved %s" % JSON.stringify(result).left(160))))
			handled[duty.character_id] = true
		elif result.get("resolved") == true:
			_note_duty_released(duty)

## Logged once per character/action/code: a held duty retries every frame,
## and a fight's next round can wait on it without any other trace.
var _duty_holds: Dictionary = {}


func _note_duty_hold(duty: Dictionary, code: String) -> void:
	var key := "%s %s" % [str(duty.character_id), str(duty.action)]
	if _duty_holds.get(key) == code:
		return
	_duty_holds[key] = code
	print("[session] %s duty for %s held: %s (t=%dms)" % [str(duty.action), str(duty.character_id), code, Time.get_ticks_msec()])


func _note_duty_released(duty: Dictionary) -> void:
	var key := "%s %s" % [str(duty.character_id), str(duty.action)]
	if _duty_holds.erase(key):
		print("[session] %s duty for %s released (t=%dms)" % [str(duty.action), str(duty.character_id), Time.get_ticks_msec()])

func _foundation_duty_receipt(duty: Dictionary, world_namespace: String = "") -> String:
	if duty.action == "combat_round_reward": return COMBAT_ROUND_REWARD.receipt(duty.character_id, duty.intent, duty.context)
	if duty.action == "combat_mastery": return "craft:combat_mastery_%s:%s" % [str(duty.intent.action_id).sha256_text(), duty.character_id]
	if duty.action == "rematch_win": return "rematch:%s:%s:%s:win:%s:%s:%s" % [duty.intent.trainer_id, duty.intent.tier, duty.character_id, duty.context.world_namespace, duty.context.session_id, str(duty.intent.encounter_id).sha256_text()]
	if duty.action == "master_win": return "master_recipe:%s:%s:win" % [duty.intent.master_id, duty.character_id]
	if duty.action == "wild_defeat_share": return ESSENCE.defeat_receipt(duty.character_id, duty.intent)
	if duty.action == "boss_relic": return FOUNDATION_ACTIONS.boss_receipt(world_namespace, duty.intent.trainer_id, duty.character_id)
	if duty.action == "research_event":
		var event: Dictionary = duty.context
		return "research:event_%s:%s" % [JSON.stringify([event.world_namespace, event.session_id, event.event_id, event.species_id, event.kind]).sha256_text(), duty.character_id]
	if duty.action == "bounty_event": return "bounty:event_%s:%s" % [JSON.stringify([duty.context.world_namespace, duty.context.event_id]).sha256_text(), duty.character_id]
	return ""


## Called by the actual host resolver after its real HP writer, or by the
## retry scan over that same retained action. A guest cannot send an outcome.
func _ordinary_combat_director_live(director: Node) -> bool:
	var game: Node = _game()
	if not is_host() or not is_instance_valid(director) or game == null or game.get("session") != self \
		or director.get_script() == null or not FOUNDATION_DIRECTORS.has(director.get_script().resource_path) \
		or director.get("_session") != self or not director.is_inside_tree() or director.is_queued_for_deletion(): return false
	var manager: Node = director.get("_manager") as Node
	if not is_instance_valid(manager) or not manager.is_inside_tree() or manager.is_queued_for_deletion() \
		or manager.get_script() == null or not FOUNDATION_COMBAT_MANAGERS.has(manager.get_script().resource_path): return false
	for root: Node in _foundation_realm_roots():
		if root.is_ancestor_of(director) and root.is_ancestor_of(manager): return true
	return false


func _tether_item_admission_ready(peer: int) -> bool:
	var character := _authority_character(peer)
	if character.is_empty() or _character_authority == null \
		or _character_authority.call("creature_training_is_pending", character) == true \
		or _character_authority.call("_research_other_transaction", character) == true: return false
	if peer == local_peer_id(): return true
	var stream: Dictionary = _owner_passive_service().get("hosts").get(character, {})
	return not stream.is_empty() and str(stream.get("error", "")).is_empty() \
		and not stream.has("readmit") and stream.get("checkpoint", {}).is_empty()


func _cancel_unjournaled_departed_items(peer: int) -> void:
	var game := _game()
	if not is_host() or game == null or game.get("world") == null: return
	var world: RefCounted = game.get("world")
	for director: Node in _foundation_directors_under(_foundation_realm_roots()):
		if not _ordinary_combat_director_live(director): continue
		var host: RefCounted = director.get("_encounter_host")
		if host == null or not host.has_method("cancel_unjournaled_tether_item"): continue
		for id: String in host.get("encounters"):
			for original: Dictionary in host.call("pending_tether_items", id):
				if int(original.peer_id) == peer:
					host.call("cancel_unjournaled_tether_item", original, world.reward_deliveries, world.reward_delivery_namespace)


## Offline local owners have no network registry row. Guests retain the
## existing stable-character registry lookup and ingress revalidates identity.
func _saved_actor_delivery_peer(character: String) -> int:
	if character.is_empty(): return 0
	var local_peer: int = local_peer_id()
	if _authority_character(local_peer) == character: return local_peer
	return int(_registry.call("peer_for_character", character))


## Private actual-combat ingress. The sole Host participant owns the original;
## no RPC or public station envelope can author an effect or body binding.
func _tether_item_commit_original(director: Node, original: Dictionary) -> Dictionary:
	if not _ordinary_combat_director_live(director) or original.get("presented") == true:
		return FOUNDATION_ACTIONS.deny("item_original_unavailable")
	var host: RefCounted = director.get("_encounter_host")
	var found := false
	if host == null or host.get_script() != preload("res://scripts/combat/accepted_action_host.gd"):
		return FOUNDATION_ACTIONS.deny("item_original_unavailable")
	for pending: Dictionary in host.call("pending_tether_items", str(original.get("encounter_id", ""))):
		if is_same(pending, original): found = true
	if not found or director.call("uses_saved_actor_vitals", str(original.encounter_id)) != true:
		return FOUNDATION_ACTIONS.deny("item_original_unavailable")
	if not _tether_item_live_consumer_ready({"action": "tether_item", "intent": original.intent}):
		return FOUNDATION_ACTIONS.deny("item_buff_consumer_unavailable")
	var game := _game()
	var world: RefCounted = game.get("world")
	var character: String = original.character_id
	var peer: int = _saved_actor_delivery_peer(character)
	if peer < 1 or _authority_character(peer) != character or world == null \
		or original.context.world_namespace != world.reward_delivery_namespace:
		return FOUNDATION_ACTIONS.deny("item_owner_unavailable")
	var writer := get_node_or_null(^"LedgerRpc")
	if writer == null: return FOUNDATION_ACTIONS.deny("writer_unavailable")
	var prior: Dictionary = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character), {})
	if prior.get("action") == "tether_item" and ESSENCE._equivalent(prior.get("intent"), original.intent) \
		and ESSENCE._equivalent(prior.get("host_context"), original.context):
		if not TRAINING_WORLD.training_row_valid(prior, world.reward_delivery_namespace, world.world_id):
			return FOUNDATION_ACTIONS.deny("item_decision_changed")
		writer.call("publish_creature_training", peer, character, prior.receipt)
		return _foundation_decision(peer, world.reward_deliveries.get(prior.delivery_id, {}))
	# Authenticate the original writer before the first journal. Its identity
	# remains frozen even when an owner-save retry reaches a different peer ID.
	if original.context.session_id != _ordinary_actor_vitals_journal_epoch():
		return FOUNDATION_ACTIONS.deny("item_writer_changed")
	var saver: RefCounted = game.get("save_system")
	if saver == null: return FOUNDATION_ACTIONS.deny("writer_unavailable")
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true: return FOUNDATION_ACTIONS.deny("writer_busy")
	if not original.has("checkpoint_request"):
		original["checkpoint_request"] = preload("res://scripts/combat/accepted_action_host.gd")._original({
			"op": "tether_item", "session_epoch": _altar_current_epoch(), "world_namespace": world.reward_delivery_namespace,
			"character_id": character, "station_key": original.context.source_key,
			"intent": original.intent, "revision": original.context.expected_revision})
	var request: Dictionary = original.checkpoint_request
	if request.session_epoch != _altar_current_epoch() or admitted_character_state(peer).is_empty():
		return FOUNDATION_ACTIONS.deny("item_owner_unavailable")
	if peer != local_peer_id():
		var ready: Dictionary = _owner_passive_service().call("action_gate", peer, "tether_item", request, original.context)
		if ready.get("ok") != true: return ready
	var result := FOUNDATION_ACTIONS.commit(_character_authority, writer, peer, character,
		int(request.revision), "tether_item", original.intent, original.context)
	if result.get("durable") != true: return result
	return _foundation_decision(peer, world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character), {}))

## Exact ordinary shared-round ownership is announced before Manager binding.
## An unavailable canonical writer refuses ownership; it never permits a local award.
func ordinary_combat_reward_owner(director: Node, encounter_id: String) -> Dictionary:
	var unavailable: Dictionary = {"enabled": true, "ready": false, "scope": {}}
	if not _ordinary_combat_director_live(director) or not _bind_character_authority() \
		or get_node_or_null(^"LedgerRpc") == null \
		or not director.has_method("ordinary_combat_vitals_ready"): return unavailable
	var vitals_ready: Variant = director.call("ordinary_combat_vitals_ready", encounter_id)
	if not vitals_ready is bool or vitals_ready != true: return unavailable
	var game: Node = _game()
	var world: RefCounted = game.get("world")
	var host: RefCounted = director.get("_encounter_host")
	var spec: Dictionary = director.get("_trainer_spec")
	if world == null or host == null or host.get_script() not in [preload("res://scripts/net/encounter_host.gd"), preload("res://scripts/combat/accepted_action_host.gd")] \
		or spec.is_empty() or spec.has("master") or spec.has("rematch") \
		or preload("res://scripts/world/trainer_npc.gd").trainer(str(spec.get("id", ""))).is_empty() \
		or not (director.get("_master_duel") as Dictionary).is_empty(): return unavailable
	var record: Dictionary = host.call("record", encounter_id)
	var realm: String = preload("res://scripts/data/biome_order.gd").canonical_id(str(director.call("_encounter_realm")))
	if record.get("encounter_id") != encounter_id or record.get("kind") not in ["trainer", "boss"] \
		or preload("res://scripts/data/biome_order.gd").canonical_id(str(record.get("realm"))) != realm or record.get("opponent", {}).get("owner_npc") != spec.get("id") \
		or record.get("phase") not in ["active", "done"]: return unavailable
	var scope: Dictionary = COMBAT_ROUND_REWARD.scope(str(world.get("reward_delivery_namespace")),
		_altar_current_epoch(), realm, str(spec.get("id", "")), encounter_id)
	if scope.is_empty(): return unavailable
	var scopes: Dictionary = director.get_meta("foundation_ordinary_combat_scopes", {})
	if scopes.has(encounter_id) and not ESSENCE._equivalent(scopes[encounter_id], scope): return unavailable
	scopes[encounter_id] = scope.duplicate(true)
	director.set_meta("foundation_ordinary_combat_scopes", scopes)
	return {"enabled": true, "ready": true, "scope": scope}

## Only the installed, explicitly disclosed mechanics provider may request
## this host-derived full heal. There is no RPC or caller-supplied HP amount.
func _ordinary_fixture_topup_source(provider: Node, director: Node, encounter_id: String,
		peer: int, proposal: Dictionary) -> bool:
	if not _ordinary_combat_director_live(director) or not is_instance_valid(provider) \
		or not provider.is_inside_tree() or provider.is_queued_for_deletion() or not is_inside_tree() \
		or provider.get_script() == null or provider.get_script().resource_path != "res://tools/net/f48_actor_topup.gd" \
		or provider.get_parent() != get_tree().root or get_tree().root.get_node_or_null(^"F48ActorTopup") != provider: return false
	var runner_ref: Variant = provider.get("fixture_runner")
	var runner: SceneTree = runner_ref.get_ref() as SceneTree if runner_ref is WeakRef else null
	if runner == null or runner != get_tree() or runner.get_script() == null \
		or provider.get_script().call("runner_script_valid", runner.get_script()) != true \
		or runner.get("_role") != "host": return false
	var required: Dictionary = {"scope": "named_mechanics_only", "self_hp_topups": true,
		"ally_placement": true, "enemy_hp_ceiling": 0, "earned_campaign_credit": false}
	if not ESSENCE._equivalent(provider.get("fixture_disclosure"), required): return false
	var scope: Dictionary = director.get_meta("foundation_ordinary_combat_scopes", {}).get(encounter_id, {})
	var world: RefCounted = _game().get("world")
	if world == null or peer != local_peer_id() or not COMBAT_ROUND_REWARD.scope_valid(scope) or scope.trainer_id != "warden_aldis" \
		or scope.world_namespace != world.get("reward_delivery_namespace") or scope.session_id != _altar_current_epoch(): return false
	var originals: Dictionary = provider.get("_actor_vitals_proposals")
	var original: Dictionary = originals.get(proposal.get("action_id"), {})
	var source: Dictionary = original.get("fixture_source", {})
	var source_ref: Variant = original.get("fixture_provider")
	var host_record: Dictionary = original.get("host_record", {})
	var member: Dictionary = host_record.get("participants", {}).get(peer, {})
	var actor: Dictionary = member.get("actor_vitals", {}).get(proposal.get("creature_uid"), {})
	var character: String = str(member.get("character_id", ""))
	var source_valid: bool = source_ref is WeakRef and source_ref.get_ref() == provider \
		and (director.get("_ordinary_actor_vitals_proposals") as Dictionary).get(proposal.get("action_id")) == original \
		and ESSENCE._equivalent(original.get("fixture_disclosure"), required) \
		and source.size() == 6 and ESSENCE._equivalent(source.get("scope"), scope) \
		and source.get("world_id") == world.get("world_id") and source.get("character_id") == character \
		and not character.is_empty() and source.get("creature_uid") == proposal.get("creature_uid") \
		and source.get("body_instance_id") == actor.get("body_instance_id") and int(source.get("body_instance_id", 0)) > 0 \
		and source.get("body_generation") == actor.get("body_generation") \
		and source.get("body_generation") == proposal.get("body_generation") \
		and original.get("encounter_id") == encounter_id and original.get("peer_id") == peer \
		and host_record.get("encounter_id") == encounter_id and host_record.get("phase") == "active" \
		and host_record.get("kind") == "boss" and host_record.get("opponent", {}).get("owner_npc") == "warden_aldis" \
		and member.get("actor_bound_uid") == proposal.get("creature_uid") \
		and ESSENCE._equivalent(original.get("proposal"), proposal) \
		and proposal.get("kind") == "heal" and actor.get("fainted") == false \
		and float(actor.get("hp", 0.0)) > 0.0 and float(actor.get("hp", 0.0)) < float(actor.get("max_hp", 0.0)) \
		and ESSENCE._equivalent(proposal.get("amount"), float(actor.max_hp) - float(actor.hp)) \
		and ESSENCE._equivalent(proposal.get("hp_after"), actor.get("max_hp"))
	if not source_valid: return false
	var manifest: Dictionary = {"encounter_id": encounter_id, "peer_id": peer, "proposal": proposal,
		"character_revision": original.get("character_revision"), "binding": original.get("binding"),
		"host_record": host_record, "fixture_source": source, "fixture_disclosure": required}
	var authenticated: Dictionary = director.get_meta("foundation_fixture_topup_sources", {})
	var prior: Dictionary = authenticated.get(proposal.get("action_id"), {})
	if not prior.is_empty():
		return prior.provider.get_ref() == provider and prior.runner.get_ref() == runner \
			and ESSENCE._equivalent(prior.manifest, manifest)
	if runner.get("_trainer_fight_director") != director \
		or runner.get("_trainer_fight_observed_encounter_id") != encounter_id \
		or (runner.get("_trainer_fight_progress") as Dictionary).get("running") != true: return false
	# Authentication precedes the first writer and survives that writer's
	# refusal/terminal/departure. It never becomes permission for another heal.
	authenticated[proposal.action_id] = {"provider": weakref(provider), "runner": weakref(runner),
		"manifest": preload("res://scripts/combat/accepted_action_host.gd")._original(manifest)}
	director.set_meta("foundation_fixture_topup_sources", authenticated)
	return true


func ordinary_fixture_actor_topup_commit(provider: Node, director: Node, encounter_id: String,
		peer: int, proposal: Dictionary) -> Dictionary:
	if not _ordinary_fixture_topup_source(provider, director, encounter_id, peer, proposal):
		return {"ok": false, "durable": false, "resolved": false, "code": "actual_disclosed_fixture_topup_required"}
	return _ordinary_actor_vitals_commit_source(director, encounter_id, peer, proposal, provider)

## The shipping producer has already retained one actual hit/self-heal proposal.
## Journal its canonical HP transition before the private actor/resource commit.
func ordinary_actor_vitals_commit(director: Node, encounter_id: String, peer: int, proposal: Dictionary) -> Dictionary:
	return _ordinary_actor_vitals_commit_source(director, encounter_id, peer, proposal)

func _ordinary_actor_vitals_commit_source(director: Node, encounter_id: String, peer: int,
		proposal: Dictionary, fixture_provider: Node = null) -> Dictionary:
	var refused: Dictionary = {"ok": false, "durable": false, "resolved": false, "code": "original_actor_proposal_required"}
	if not _ordinary_combat_director_live(director): return refused
	var scopes: Dictionary = director.get_meta("foundation_ordinary_combat_scopes", {})
	var scope: Dictionary = scopes.get(encounter_id, {})
	var world: RefCounted = _game().get("world")
	var host: RefCounted = director.get("_encounter_host")
	# F27: a guest's vitals in a canonical wild fight use the same carrier
	# under their own encounter-keyed scope (never a trainer/round scope).
	var wild_scope := false
	if scope.is_empty() and host != null and director.has_method("uses_wild_actor_vitals") \
		and director.call("uses_wild_actor_vitals", encounter_id) == true:
		scope = (host.call("record", encounter_id) as Dictionary).get("wild_actor_owner", {}).duplicate(true)
		wild_scope = WILD_ACTOR_SCOPE.scope_valid(scope)
	if world == null or host == null or not (wild_scope or COMBAT_ROUND_REWARD.scope_valid(scope)) \
		or scope.world_namespace != world.get("reward_delivery_namespace") or scope.session_id != _altar_current_epoch() \
		or host.get_script() not in [preload("res://scripts/net/encounter_host.gd"), preload("res://scripts/combat/accepted_action_host.gd")]: return refused
	var pending: Dictionary = director.get("_ordinary_actor_vitals_proposals")
	var original: Dictionary = pending.get(proposal.get("action_id"), {})
	if original.has("fixture_provider"):
		if fixture_provider == null or not _ordinary_fixture_topup_source(fixture_provider, director, encounter_id, peer, proposal): return refused
	elif fixture_provider != null: return refused
	if original.get("encounter_id") != encounter_id or original.get("peer_id") != peer \
		or not ESSENCE._equivalent(original.get("proposal"), proposal) \
		or proposal.get("encounter_id") != encounter_id or proposal.get("peer_id") != peer \
		or not proposal.get("settlement_receipt") is Dictionary: return refused
	var source_record: Dictionary = original.get("host_record", {})
	var source_member: Dictionary = source_record.get("participants", {}).get(peer, {})
	var character: String = str(source_member.get("character_id", ""))
	var delivery_peer: int = _saved_actor_delivery_peer(character)
	if delivery_peer < 1 or _authority_character(delivery_peer) != character:
		return {"ok": false, "durable": false, "resolved": false, "code": "original_actor_owner_unavailable"}
	var record: Dictionary = host.call("record", encounter_id)
	var member: Dictionary = record.get("participants", {}).get(peer, {})
	if member.is_empty(): member = record.get("retained_actor_participants", {}).get(character, {})
	var uid: String = str(proposal.get("creature_uid", ""))
	var actor: Dictionary = member.get("actor_vitals", {}).get(uid, {})
	if character.is_empty() or member.get("character_id") != character \
		or source_record.get("encounter_id") != encounter_id or source_record.get("phase") != "active" \
		or preload("res://scripts/data/biome_order.gd").canonical_id(str(record.get("realm"))) != scope.realm \
		or (wild_scope and not WILD_ACTOR_SCOPE.owns(record.get("wild_actor_owner"), record, encounter_id)) \
		or (not wild_scope and record.get("opponent", {}).get("owner_npc") != scope.trainer_id) \
		or source_member.get("actor_bound_uid") != uid or member.get("actor_bound_uid") != uid \
		or int(actor.get("body_instance_id", 0)) <= 0 \
		or actor.get("body_instance_id") != source_member.get("actor_vitals", {}).get(uid, {}).get("body_instance_id") \
		or actor.get("body_generation") != proposal.get("body_generation"): return refused
	var receipt: Dictionary = proposal.settlement_receipt
	var actor_delivery: Script = preload("res://scripts/net/actor_vitals_delivery.gd")
	var existing: Dictionary = world.get("reward_deliveries").get(actor_delivery.delivery_id(scope.world_namespace, character, uid), {})
	var proofs: Dictionary = director.get_meta("foundation_ordinary_vitals_commits", {})
	var prior_proof: Dictionary = proofs.get(receipt.receipt_id, {})
	var journal_epoch: String = _ordinary_actor_vitals_journal_epoch() if prior_proof.is_empty() else str(prior_proof.get("journal_epoch", ""))
	if journal_epoch.is_empty(): return refused
	if prior_proof.has("row"):
		if not _ordinary_actor_vitals_original_row(prior_proof, existing): return refused
	elif not prior_proof.is_empty() and journal_epoch != _ordinary_actor_vitals_journal_epoch(): return refused
	if original.get("committed") != true:
		if proposal.get("kind") == "damage" and (not host.has_method("verify_original_actor_vitals") \
			or host.call("verify_original_actor_vitals", proposal, source_record) != true): return refused
		var heal: Dictionary = original.get("heal_bundle", {})
		if fixture_provider != null:
			if not host.has_method("verify_original_fixture_actor_topup") \
				or host.call("verify_original_fixture_actor_topup", proposal, source_record) != true: return refused
		elif proposal.get("kind") == "heal":
			if heal.is_empty() or not ESSENCE._equivalent(heal.get("vitals_proposal"), proposal): return refused
			var heal_verified: Dictionary = host.call("stage_actor_heal_utility", heal.intent, peer, heal.view,
				heal.move_id, heal.wind_profile, int(heal.receipt_limit))
			if heal_verified.get("ok") != true or not ESSENCE._equivalent(heal_verified, heal): return refused
		var canonical: Dictionary = _character_authority.call("state", character)
		var owned: Dictionary = {}
		for card: Dictionary in canonical.get("party", []):
			if card.get("uid") == uid: owned = card
		var original_saved: bool = actor_delivery.valid(existing, character, scope.world_namespace) \
			and existing.world_id == str(world.get("world_id")) and existing.session_id == journal_epoch \
			and ESSENCE._equivalent(existing.receipt, receipt) \
			and ESSENCE._equivalent(existing.hp, proposal.get("hp_after")) and existing.fainted == proposal.get("fainted") \
			and ESSENCE._equivalent(existing.expected_hp, proposal.get("hp_before"))
		if owned.is_empty() or (not ESSENCE._equivalent(owned.get("hp"), proposal.get("hp_before")) \
			and not (original_saved and ESSENCE._equivalent(owned.get("hp"), proposal.get("hp_after")))) \
			or not ESSENCE._equivalent(owned.get("max_hp"), proposal.get("max_hp")) \
			or (owned.get("fainted") != (float(proposal.hp_before) == 0.0) \
				and not (original_saved and owned.get("fainted") == proposal.get("fainted"))): return refused
		proofs[receipt.receipt_id] = {"scope": scope.duplicate(true), "world_id": str(world.get("world_id")),
			"journal_epoch": journal_epoch,
			"character_id": character, "proposal": proposal.duplicate(true), "source_record": source_record.duplicate(true),
			"revision_before": int(original.get("character_revision", -1))}
		if fixture_provider != null:
			proofs[receipt.receipt_id]["fixture_source"] = original.fixture_source.duplicate(true)
			proofs[receipt.receipt_id]["fixture_disclosure"] = original.fixture_disclosure.duplicate(true)
		director.set_meta("foundation_ordinary_vitals_commits", proofs)
		if not original_saved:
			var saved: Dictionary = host_commit_creature_vitals(delivery_peer, uid, int(original.get("character_revision", -1)),
				float(proposal.hp_before), float(proposal.hp_before) == 0.0,
				float(proposal.hp_after), bool(proposal.fainted), receipt)
			if saved.get("ok") != true or saved.get("durable") != true:
				return {"ok": false, "durable": false, "resolved": false, "code": "actor_world_save_pending"}
		var durable_row: Dictionary = world.get("reward_deliveries").get(actor_delivery.delivery_id(scope.world_namespace, character, uid), {})
		if not actor_delivery.valid(durable_row, character, scope.world_namespace) or durable_row.session_id != journal_epoch \
			or not ESSENCE._equivalent(durable_row.receipt, receipt): return refused
		proofs[receipt.receipt_id]["row"] = durable_row.duplicate(true)
		director.set_meta("foundation_ordinary_vitals_commits", proofs)
		var commit_record_before: Dictionary = host.call("record", encounter_id).duplicate(true)
		var committed: Dictionary
		if fixture_provider != null: committed = host.call("commit_original_fixture_actor_topup", proposal, source_record)
		elif proposal.kind == "heal": committed = host.call("commit_actor_heal_utility", heal)
		else: committed = host.call("commit_original_actor_vitals", proposal, source_record)
		if committed.get("ok") != true:
			return {"ok": false, "durable": true, "resolved": false, "code": "actor_commit_pending"}
		original["committed"] = true
		proofs[receipt.receipt_id]["record_before"] = commit_record_before
		proofs[receipt.receipt_id]["record_after"] = host.call("record", encounter_id).duplicate(true)
		director.set_meta("foundation_ordinary_vitals_commits", proofs)
		if proposal.kind == "heal" and fixture_provider == null: original["heal_verdict"] = committed.get("verdict", {}).duplicate(true)
		host_finalize_creature_vitals(delivery_peer, uid, receipt)
	var latest: Dictionary = world.get("reward_deliveries").get(actor_delivery.delivery_id(scope.world_namespace, character, uid), {})
	var resolved: bool = actor_delivery.valid(latest, character, scope.world_namespace) \
		and latest.get("status") == "accepted" and ESSENCE._equivalent(latest.get("receipt"), receipt) \
		and host_ack_creature_vitals(delivery_peer, uid, int(latest.get("character_revision", -1)), receipt)
	return {"ok": true, "durable": true, "resolved": resolved,
		"code": "actor_owner_saved" if resolved else "actor_owner_save_pending", "receipt": receipt.duplicate(true)}

## Derive the full terminal continuation exclusively from the original
## typed proposals and accepted BOOL decisions. No card field is excluded.
static func _ordinary_combat_settled_record(original: Dictionary, settled: Dictionary,
		proofs: Dictionary, leaves: Array = []) -> bool:
	if original.is_empty() or settled.is_empty() or original.get("phase") != "done": return false
	var scope: Dictionary = original.get("ordinary_combat_reward_owner", {})
	if not COMBAT_ROUND_REWARD.scope_valid(scope): return false
	var expected: Dictionary = original.duplicate(true)
	var applied: Dictionary = {}
	var actor_codec: Script = preload("res://scripts/net/actor_vitals_delivery.gd")
	for step: int in proofs.size() * 2 + leaves.size() + 1:
		if ESSENCE._equivalent(expected, settled): return true
		var progressed: bool = false
		for proof_key: Variant in proofs:
			var proof: Dictionary = proofs[proof_key]
			var proposal: Dictionary = proof.get("proposal", {})
			if proposal.get("encounter_id") != scope.encounter_id: continue
			var character: String = str(proof.get("character_id", ""))
			var peer: int = int(proposal.get("peer_id", 0))
			var uid: String = str(proposal.get("creature_uid", ""))
			var member: Dictionary = expected.get("participants", {}).get(peer, {})
			if member.is_empty(): member = expected.get("retained_actor_participants", {}).get(character, {})
			var current: Dictionary = member.get("actor_vitals", {}).get(uid, {})
			var before: Dictionary = proof.get("source_record", {}).get("participants", {}).get(peer, {}).get("actor_vitals", {}).get(uid, {})
			var row: Dictionary = proof.get("accepted_row", {})
			if current.is_empty() or applied.has(proof_key): continue
			# Historical unrelated generations remain history; they cannot
			# supply the source for this original body.
			if current.get("body_generation") != proposal.get("body_generation"): continue
			if proof.get("accepted") != true or not ESSENCE._equivalent(proof.get("scope"), scope) \
				or member.get("character_id") != character \
				or not actor_codec.valid(row, character, scope.world_namespace) or row.status != "accepted" \
				or not _ordinary_actor_vitals_original_row(proof, row) or row.world_id != proof.get("world_id") \
				or not ESSENCE._equivalent(row.receipt, proposal.get("settlement_receipt")) \
				or not ESSENCE._equivalent(row.expected_hp, proposal.get("hp_before")) \
				or not ESSENCE._equivalent(row.max_hp, proposal.get("max_hp")) \
				or not ESSENCE._equivalent(row.hp, proposal.get("hp_after")) or row.fainted != proposal.get("fainted"): continue
			if ESSENCE._equivalent(current, before) and ESSENCE._equivalent(expected, proof.get("record_before")):
				var next: Dictionary = expected.duplicate(true)
				var next_member: Dictionary = next.get("participants", {}).get(peer, {})
				if next_member.is_empty(): next_member = next.get("retained_actor_participants", {}).get(character, {})
				var actor: Dictionary = next_member.actor_vitals[uid]
				actor.hp = proposal.hp_after
				actor.fainted = proposal.fainted
				actor.revision = proposal.revision
				actor.settlement_receipt = proposal.settlement_receipt.duplicate(true)
				actor.receipts[str(proposal.action_id)] = true
				var after: Dictionary = proof.get("record_after", {})
				if int(after.get("seq", -1)) <= int(expected.get("seq", -1)): return false
				next.seq = after.seq
				if not ESSENCE._equivalent(next, after): return false
				expected = next
				progressed = true
				break
			if current.get("revision") == proposal.get("revision") \
				and ESSENCE._equivalent(current.get("settlement_receipt"), proposal.get("settlement_receipt")) \
				and ESSENCE._equivalent(current.get("hp"), proposal.get("hp_after")) \
				and current.get("fainted") == proposal.get("fainted"):
				current.settled_revision = proposal.revision
				applied[proof_key] = true
				progressed = true
				break
		if progressed: continue
		for index: int in leaves.size():
			var leave: Dictionary = leaves[index]
			var key: String = "leave:" + str(index)
			if applied.has(key) or leave.get("encounter_id") != scope.encounter_id \
				or not ESSENCE._equivalent(expected, leave.get("record_before")): continue
			if not leave.get("peer_id") is int or not leave.get("host_seq_before") is int \
				or not expected.get("participants", {}).has(leave.peer_id) \
				or int(leave.host_seq_before) < int(expected.seq): return false
			var trial: RefCounted = preload("res://scripts/net/encounter_host.gd").new(HOST_PEER_ID)
			trial.set("encounters", {scope.encounter_id: expected.duplicate(true)})
			trial.set("seq", int(leave.host_seq_before))
			if trial.call("leave", scope.encounter_id, int(leave.peer_id)).get("ok") != true \
				or not ESSENCE._equivalent(trial.call("record", scope.encounter_id), leave.get("record_after")): return false
			expected = trial.call("record", scope.encounter_id).duplicate(true)
			applied[key] = true
			progressed = true
			break
		if not progressed: return false
	return ESSENCE._equivalent(expected, settled)

## The normal accepted training ACK already owns actor HP/maxHP/generation
## promotion. Reuse that exact shipping transition on a detached record when
## freezing completion; no new body is admitted in the done phase.
func _ordinary_combat_completion_record(terminal: Dictionary, prior: Dictionary, current: Dictionary, world: RefCounted) -> bool:
	var baseline: Dictionary = terminal.get("settled_record", {})
	if baseline.is_empty(): return false
	var trial: RefCounted = preload("res://scripts/combat/accepted_action_host.gd").new(HOST_PEER_ID)
	trial.set("encounters", {str(current.encounter_id): baseline.duplicate(true)})
	for duty: Dictionary in prior.duties:
		var row: Dictionary = world.get("reward_deliveries").get(ESSENCE.training_delivery_id(prior.scope.world_namespace, duty.character_id), {})
		if not TRAINING_WORLD.training_row_valid(row, prior.scope.world_namespace, str(world.get("world_id"))) \
			or row.get("status") != "accepted" or row.get("action") != "combat_round_reward" \
			or not ESSENCE._equivalent(row.get("intent"), duty.intent) \
			or row.get("receipt") != COMBAT_ROUND_REWARD.receipt(duty.character_id, duty.intent, duty.context): return false
		var admitted: Dictionary = _character_authority.call("state", duty.character_id)
		var revision: int = int(_character_authority.call("revision", duty.character_id))
		var proposal: Dictionary = trial.call("stage_actor_training_baseline", row, admitted, revision,
			prior.scope.world_namespace, str(world.get("world_id")))
		if proposal.get("ok") != true or trial.call("commit_actor_training_baseline", proposal, row, admitted,
			revision, world.get("reward_deliveries"), prior.scope.world_namespace, str(world.get("world_id"))) != true: return false
	return ESSENCE._equivalent(trial.call("record", str(current.encounter_id)), current)

## Freeze the actual terminal arbiter/body facts before publication or teardown.
## Retrying an unavailable writer uses these originals, never later owner cards.
func foundation_combat_round_resolution(director: Node, encounter_id: String, round_number: int,
		enemy_record: Dictionary, outcome: String, phase: String = "round") -> Dictionary:
	var refused: Dictionary = {"ok": false, "durable": false, "resolved": false, "code": "actual_terminal_round_required"}
	if not _ordinary_combat_director_live(director) or outcome != "won" or phase not in ["round", "completion"]: return refused
	var world: RefCounted = _game().get("world")
	var scopes: Dictionary = director.get_meta("foundation_ordinary_combat_scopes", {})
	var scope: Dictionary = scopes.get(encounter_id, {})
	if world == null or not COMBAT_ROUND_REWARD.scope_valid(scope) \
		or scope.world_namespace != world.get("reward_delivery_namespace") or scope.session_id != _altar_current_epoch() \
		or scope.realm != preload("res://scripts/data/biome_order.gd").canonical_id(str(director.call("_encounter_realm"))): return refused
	var key: String = JSON.stringify([encounter_id, round_number, phase])
	var retained: Dictionary = director.get_meta("foundation_combat_round_pending", {})
	var prior_round: Dictionary = retained.get(JSON.stringify([encounter_id, round_number, "round"]), {})
	if phase == "completion" and (prior_round.is_empty() or not _ordinary_combat_round_saved(prior_round, world)):
		return {"ok": false, "durable": false, "resolved": false, "code": "original_round_owner_save_pending"}
	var original: Dictionary = retained.get(key, {})
	if original.is_empty():
		if director.call("ordinary_actor_vitals_pending", encounter_id) != false:
			return {"ok": false, "durable": false, "resolved": false, "code": "original_actor_owner_save_pending"}
		var host: RefCounted = director.get("_encounter_host")
		if host == null or host.get_script() not in [preload("res://scripts/net/encounter_host.gd"), preload("res://scripts/combat/accepted_action_host.gd")]: return refused
		var record: Dictionary = host.call("record", encounter_id)
		var rounds: Dictionary = director.get("_ordinary_combat_rounds")
		var terminal: Dictionary = rounds.get(encounter_id, {})
		var spec: Dictionary = director.get("_trainer_spec")
		var manager: Node = director.get("_manager") as Node
		var enemy_body: Node3D = director.get("_trainer_body") as Node3D
		var enemy: RefCounted = enemy_body.get("instance") as RefCounted if is_instance_valid(enemy_body) else null
		if spec.has("master") or spec.has("rematch") or spec.get("id") != scope.trainer_id \
			or record.get("encounter_id") != encounter_id or record.get("phase") != "done" \
			or record.get("kind") not in ["trainer", "boss"] or preload("res://scripts/data/biome_order.gd").canonical_id(str(record.get("realm"))) != scope.realm \
			or record.get("opponent", {}).get("round") != round_number \
			or record.get("opponent", {}).get("owner_npc") != scope.trainer_id \
			or terminal.get("round") != round_number or terminal.get("outcome") != outcome \
			or (phase == "round" and (not ESSENCE._equivalent(terminal.get("settled_record"), record) \
				or not _ordinary_combat_settled_record(terminal.get("record", {}), record, director.get_meta("foundation_ordinary_vitals_commits", {}), director.get_meta("foundation_ordinary_leave_transitions", [])))) \
			or not ESSENCE._equivalent(terminal.get("enemy"), enemy_record) \
			or not is_instance_valid(enemy_body) or not enemy_body.is_inside_tree() or enemy == null \
			or manager.get("_wild") != enemy_body or manager.get("_enemy") != enemy \
			or record.get("opponent", {}).get("card", {}).get("uid") != enemy_record.get("uid") \
			or not ESSENCE._equivalent(preload("res://scripts/save/water_capture_codec.gd").encode(enemy), enemy_record) \
			or enemy_record.get("hp") != 0 or enemy_record.get("fainted") != true: return refused
		if phase == "completion" and not _ordinary_combat_completion_record(terminal, prior_round, record, world): return refused
		var participants: Array = []
		var members: Dictionary = record.get("participants", {}).duplicate(true)
		if phase == "round":
			for original_peer: Variant in terminal.record.get("participants", {}):
				if members.has(original_peer): continue
				var original_member: Dictionary = terminal.record.participants[original_peer]
				var departed: Dictionary = record.get("retained_actor_participants", {}).get(original_member.get("character_id"), {})
				if departed.is_empty(): return refused
				members[original_peer] = departed
		if phase == "completion":
			for prior: Dictionary in prior_round.duties:
				var previous_peer: int = int(prior.context.binding.peer_id)
				if not members.has(previous_peer):
					var departed: Dictionary = record.get("retained_actor_participants", {}).get(prior.character_id, {})
					if departed.is_empty(): return refused
					members[previous_peer] = departed
		if members.is_empty() or members.size() > 4: return refused
		for peer: Variant in members:
			if not peer is int or peer < 1: return refused
			var member: Dictionary = members[peer]
			var character: String = str(member.get("character_id", ""))
			var current_peer: int = int(_registry.call("peer_for_character", character))
			if character.is_empty() or (current_peer > 0 and _authority_character(current_peer) != character) \
				or (_character_authority.call("state", character) as Dictionary).is_empty(): return refused
			participants.append({"peer_id": peer, "character_id": character})
		var duties: Array = []
		for participant: Dictionary in participants:
			var peer: int = participant.peer_id
			var character: String = participant.character_id
			var state: Dictionary = _character_authority.call("state", character)
			var member: Dictionary = members[peer]
			var body: Node3D = director.call("deployed_body_for", peer) as Node3D
			var active: String = str(member.get("actor_bound_uid", ""))
			if phase == "completion":
				for prior: Dictionary in prior_round.duties:
					if prior.character_id == character and prior.context.binding.peer_id == peer:
						active = str(prior.context.binding.active_uid)
			var actors: Dictionary = member.get("actor_vitals", {})
			var actor: Dictionary = actors.get(active, {})
			if state.get("character_id") != character or not state.get("party") is Array \
				or actor.is_empty() \
				or (phase == "round" and (int(actor.get("body_instance_id", 0)) <= 0 \
					or (record.get("participants", {}).has(peer) and (not is_instance_valid(body) \
						or not body.is_inside_tree() or actor.get("body_instance_id") != body.get_instance_id())))) \
				or member.get("creature_uid") != active or int(actor.get("body_generation", 0)) < 1: return refused
			var vitals: Array = []
			for card: Dictionary in state.party:
				var actual: Dictionary = actors.get(card.get("uid"), {})
				vitals.append({"uid": card.get("uid"), "hp": actual.get("hp", card.get("hp")),
					"max_hp": actual.get("max_hp", card.get("max_hp")), "fainted": actual.get("fainted", card.get("fainted")),
					"actor_generation": int(actual.get("body_generation", 0))})
			var actor_source: Dictionary = participant.duplicate(true)
			actor_source.merge({"active_uid": active, "actor_generation": int(actor.body_generation), "settled_vitals": vitals})
			var duty: Dictionary = COMBAT_ROUND_REWARD.make_duty(scope.world_namespace, scope.session_id, scope.realm,
				scope.trainer_id, encounter_id, round_number, enemy_record, actor_source, participants, phase)
			if duty.is_empty(): return refused
			duties.append(duty)
		original = {"scope": scope.duplicate(true), "round": round_number, "phase": phase, "enemy": enemy_record.duplicate(true),
			"outcome": outcome, "source_id": COMBAT_ROUND_REWARD.source_id(duties[0].intent, duties[0].context), "duties": duties}
		retained[key] = original.duplicate(true)
		director.set_meta("foundation_combat_round_pending", retained)
	if not ESSENCE._equivalent(original.scope, scope) or original.round != round_number or original.phase != phase \
		or original.outcome != outcome or not ESSENCE._equivalent(original.enemy, enemy_record): return refused
	var writer: Node = get_node_or_null(^"LedgerRpc")
	if writer == null: return {"ok": false, "durable": false, "resolved": false, "code": "round_writer_unavailable"}
	var journal: Dictionary = writer.call("journal_foundation_event", original.source_id, original.duties)
	if journal.get("ok") != true or journal.get("durable") != true:
		return {"ok": false, "durable": false, "resolved": false, "code": "round_source_save_pending"}
	var ready: bool = _ordinary_combat_round_saved(original, world)
	return {"ok": true, "durable": true, "resolved": ready,
		"code": "round_owner_saved" if ready else "round_owner_save_pending", "source_id": original.source_id}

func _ordinary_round_pending_characters() -> Dictionary:
	var waiting: Dictionary = {}
	for director: Node in _foundation_directors_under(_foundation_realm_roots()):
		if not _ordinary_combat_director_live(director): continue
		var rounds: Dictionary = director.get("_ordinary_combat_rounds")
		for terminal: Dictionary in rounds.values():
			var source: Dictionary = terminal.get("record", {})
			var trainer: Dictionary = preload("res://scripts/world/trainer_npc.gd").trainer(str(source.get("opponent", {}).get("owner_npc", "")))
			var final_round: bool = int(terminal.get("round", 0)) == preload("res://scripts/world/trainer_npc.gd").team_of(trainer).size()
			if terminal.get("resolved") == true and (not final_round or terminal.get("completion_resolved") == true): continue
			for member: Dictionary in source.get("participants", {}).values():
				waiting[str(member.get("character_id", ""))] = true
	return waiting

func _ordinary_combat_round_saved(original: Dictionary, world: RefCounted) -> bool:
	var scope: Dictionary = original.scope
	for duty: Dictionary in original.duties:
		var peer: int = int(_registry.call("peer_for_character", duty.character_id))
		if peer < 1 or _authority_character(peer) != duty.character_id:
			return false
		var latest: Dictionary = world.get("reward_deliveries").get(ESSENCE.training_delivery_id(scope.world_namespace, duty.character_id), {})
		var receipt: String = COMBAT_ROUND_REWARD.receipt(duty.character_id, duty.intent, duty.context)
		if not TRAINING_WORLD.training_row_valid(latest, scope.world_namespace, str(world.get("world_id"))) \
			or latest.get("status") != "accepted" or not latest.after.redesign_character.transaction_receipts.has(receipt) \
			or _foundation_decision(peer, latest).get("saved") != true: return false
	return true

func foundation_combat_mastery(director: Node, encounter_id: String, peer: Variant, action: int) -> Dictionary:
	if not is_host() or not is_instance_valid(director) or director.get("_session") != self \
		or director.get_script() == null or not FOUNDATION_DIRECTORS.has(director.get_script().resource_path): return {"ok": false, "durable": false}
	var host: RefCounted = director.get("_encounter_host")
	if host == null or not host.has_method("move_mastery_outcome"): return {"ok": false, "durable": false}
	var original: Dictionary = host.call("move_mastery_outcome", encounter_id, peer, action)
	if original.is_empty(): return {"ok": true, "durable": true, "no_mastery": true}
	var world: RefCounted = _game().get("world")
	if original.get("encounter_id") != encounter_id or original.get("action") != action \
		or world == null or _altar_current_epoch().is_empty(): return {"ok": false, "durable": false}
	var outcomes: Array = [original]
	var parent := str(original.get("outcome", {}).get("action_id", ""))
	if action < 0:
		if not original.get("outcomes") is Array or original.outcomes.is_empty() \
			or original.outcomes.size() > 2: return {"ok": false, "durable": false}
		outcomes = original.outcomes
		parent = str(original.get("action_id", ""))
	if parent.is_empty(): return {"ok": false, "durable": false}
	var duties: Array = []
	var child_ids := {}
	var creatures := {}
	var owner := ""
	for source: Variant in outcomes:
		if not source is Dictionary or not source.get("outcome") is Dictionary \
			or not source.get("binding") is Dictionary or not source.get("context") is Dictionary:
			return {"ok": false, "durable": false}
		var event: Dictionary = source.outcome
		var binding: Dictionary = source.binding
		var character := str(binding.get("character_id", ""))
		var child := str(event.get("action_id", ""))
		var creature := str(binding.get("creature_uid", ""))
		if character.is_empty() or creature.is_empty() or event.get("attacker_uid") != creature \
			or source.context.get("world_namespace") != world.reward_delivery_namespace \
			or source.context.get("session_id") != _altar_current_epoch() or child.is_empty() \
			or child_ids.has(child) or (not owner.is_empty() and owner != character) \
			or (action < 0 and (creatures.has(creature) or child == parent)):
			return {"ok": false, "durable": false}
		owner = character
		child_ids[child] = true
		creatures[creature] = true
		var context := {"source_key": "combat_mastery:" + child, "event_confirmed": true,
			"world_namespace": world.reward_delivery_namespace, "session_id": _altar_current_epoch(),
			"encounter_id": encounter_id, "participants": [character], "binding": binding.duplicate(true),
			"outcome": event.duplicate(true)}
		if action < 0:
			context["parent_action_id"] = parent
			context["tag_part"] = source.get("part")
			if preload("res://scripts/net/foundation_event.gd").tag_mastery_parent(context,
				{"action_id":child, "creature_uid":creature}, character) != parent:
				return {"ok": false, "durable": false}
		duties.append({"character_id": character, "action": "combat_mastery",
			"intent": {"action_id": child, "creature_uid": creature}, "context": context})
	var writer := get_node_or_null(^"LedgerRpc")
	var result: Dictionary = writer.call("journal_foundation_event", "mastery:" + parent, duties) if writer != null else {}
	if result.get("ok") == true and result.get("durable") == true:
		host.call("acknowledge_move_mastery", encounter_id, peer, action, parent)
	return result


## Hosted worlds are siblings of current_scene, retained by Realms so their
## multiplayer node paths match guests. Every combat settlement scan must see
## the same registered roots, including an empty shell waiting on its journal.
func _foundation_realm_roots() -> Array[Node]:
	var roots: Array[Node] = []
	if is_inside_tree() and get_tree().current_scene != null:
		roots.append(get_tree().current_scene)
	var hosted := realms()
	if is_host() and is_instance_valid(hosted):
		for realm: String in hosted.call("hosted_realms"):
			var world: Node = hosted.call("shell", realm)
			if is_instance_valid(world) and not roots.has(world): roots.append(world)
	return roots


## Nodes in `group` at or under any of `roots` whose script is one of
## `scripts`, each once. The group (joined in the script's _enter_tree)
## replaces walking every node of a realm: Stormwood alone holds ~70k nodes,
## and the one-second foundation polls walked it several times per tick.
## A detached root (a unit fixture outside the tree) has no group index and is
## walked directly.
static func _foundation_group_under(group: StringName, roots: Array, scripts: Array) -> Array[Node]:
	var out: Array[Node] = []
	var attached: Array[Node] = []
	var tree: SceneTree = null
	for root: Variant in roots:
		if not is_instance_valid(root): continue
		if (root as Node).is_inside_tree():
			attached.append(root)
			tree = (root as Node).get_tree()
			continue
		var nodes: Array[Node] = [root]
		while not nodes.is_empty():
			var node: Node = nodes.pop_back()
			for child: Node in node.get_children(): nodes.append(child)
			var script: Script = node.get_script()
			if script != null and scripts.has(script.resource_path) and not out.has(node): out.append(node)
	if tree == null: return out
	for node: Node in tree.get_nodes_in_group(group):
		var script: Script = node.get_script()
		if script == null or not scripts.has(script.resource_path): continue
		for root: Node in attached:
			if root == node or root.is_ancestor_of(node):
				out.append(node)
				break
	return out


func _foundation_directors_under(roots: Array) -> Array[Node]:
	return _foundation_group_under(FOUNDATION_DIRECTOR_GROUP, roots, FOUNDATION_DIRECTORS)


func _retry_combat_mastery_sources() -> void:
	for node: Node in _foundation_directors_under(_foundation_realm_roots()):
		var host: RefCounted = node.get("_encounter_host")
		if host == null or not host.has_method("pending_move_mastery"): continue
		for pending: Dictionary in host.call("pending_move_mastery"):
			var result := foundation_combat_mastery(node, str(pending.encounter_id), pending.peer, int(pending.action))
			if result.get("durable") != true: return # Preserve the exact original and retry after the writer recovers.


## A saved replay obligation is enough; this never fabricates an owner ACK or
## awards mastery. An ordinary world snapshot cannot replace this first write.
func prepare_process_exit() -> Dictionary:
	if is_host():
		_retry_combat_mastery_sources()
		var nodes := _foundation_realm_roots()
		while not nodes.is_empty():
			var node: Node = nodes.pop_back()
			for child: Node in node.get_children(): nodes.append(child)
			var script: Script = node.get_script()
			if script == null or not FOUNDATION_DIRECTORS.has(script.resource_path): continue
			var host: RefCounted = node.get("_encounter_host")
			if host != null and not (host.call("pending_move_mastery") as Array).is_empty():
				return {"ok": false, "reason": "Could not save the latest combat result. The game will stay open; please try exiting again."}
	return {"ok": true}


func _prepare_process_exit_step(save_progress: bool) -> String:
	var checked := prepare_process_exit()
	if checked.get("ok") != true: return str(checked.reason)
	if save_progress and not preload("res://scripts/ui/graphics_restart.gd").save_progress(_game()):
		return "Could not save progress. The game will stay open; please try again."
	return ""


## One guarded process boundary for window close, explicit quit and restart.
## Title/recovery callers preserve their existing no-new-save behavior while
## still requiring every already-earned original to have its durable replay.
func request_process_exit(restart_graphics: bool = false, save_progress: bool = false) -> String:
	if _process_exit_in_flight: return "An exit is already being prepared."
	_process_exit_in_flight = true
	_process_exit_refusal = ""
	var game := _game()
	var preserve_autosave: bool = game != null and game.has_method("process_exit_preserves_autosave") \
		and game.call("process_exit_preserves_autosave") == true
	var write_progress: bool = save_progress and not preserve_autosave
	var was_host := is_host()
	var reason := _prepare_process_exit_step(write_progress)
	# Recovery/title already used immediate process close. Do not enter leave
	# or shell teardown: both ordinary saves would overwrite the recovery point.
	if reason.is_empty() and write_progress and is_active():
		leave("graphics_restart" if restart_graphics else "quit")
		while is_active() and _process_exit_refusal.is_empty():
			await get_tree().process_frame
	if reason.is_empty(): reason = _process_exit_refusal
	# A late accepted hit may finish during reliable-goodbye flushing. Check
	# immediately before OS exit, after the final close gate, with no yield.
	if reason.is_empty(): reason = _prepare_process_exit_step(write_progress and was_host)
	if not reason.is_empty():
		_process_exit_in_flight = false
		if game != null and game.has_method("show_process_exit_refusal"): game.call("show_process_exit_refusal", reason)
		return reason
	_complete_process_exit(restart_graphics)
	return ""


func _complete_process_exit(restart_graphics: bool) -> void:
	preload("res://scripts/net/steam_lobby.gd").leave_for_quit(_game())
	if restart_graphics:
		var arguments := PackedStringArray()
		if not OS.has_feature("standalone"):
			arguments.append_array(["--path", ProjectSettings.globalize_path("res://")])
		OS.set_restart_on_exit(true, arguments)
	get_tree().quit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_inside_tree():
		call_deferred("_request_window_close")


func _request_window_close() -> void:
	var scene := get_tree().current_scene
	var live_world := scene != null and scene.scene_file_path != TITLE_SCENE
	await request_process_exit(false, live_world)


func foundation_event_stage_epoch(accepted: Dictionary) -> String:
	var context: Dictionary = accepted.get("host_context", {})
	var world: RefCounted = _game().get("world")
	if accepted.get("action") == "tether_item":
		if context.get("session_id") != _ordinary_actor_vitals_journal_epoch(): return ""
		for director: Node in _foundation_directors_under(_foundation_realm_roots()):
			if not _ordinary_combat_director_live(director): continue
			var host: RefCounted = director.get("_encounter_host")
			if host == null: continue
			for original: Dictionary in host.call("pending_tether_items", str(accepted.get("intent", {}).get("request", {}).get("encounter_id", ""))):
				if original.character_id == accepted.get("character_id") and ESSENCE._equivalent(original.intent, accepted.get("intent")) \
					and ESSENCE._equivalent(original.context, context): return context.session_id
		return ""
	var row: Variant = world.reward_deliveries.get(context.get("retained_event", ""))
	if not preload("res://scripts/net/foundation_event.gd").valid(row, world.reward_delivery_namespace, world.world_id): return _altar_current_epoch()
	for duty: Dictionary in row.duties:
		var capture: bool = accepted.get("action") == "wild_capture" and duty.action == "capture_offer" and accepted.intent.get("offer_id") == duty.context.offer_id
		if duty.character_id != accepted.get("character_id") or (not capture and (duty.action != accepted.get("action") or duty.intent != accepted.get("intent"))): continue
		var canonical: Dictionary = context.duplicate(true)
		for field: String in ["character_id", "expected_revision", "in_range", "retained_event", "in_combat", "foundation_runtime_authorized"]: canonical.erase(field)
		if duty.action == "boss_relic":
			# These are re-derived from the retained event's actual world on retry,
			# not extra fields in the immutable victory capture.
			canonical.erase("boss_settlement_world_flags")
			if not duty.context.has("world_namespace"): canonical.erase("world_namespace")
		if ESSENCE._equivalent(canonical, duty.context): return row.session_id
	return ""

func homestead_breakthrough_service() -> Node:
	return get_node_or_null(^"FoundationComposition/BreakthroughService")

func _foundation_breakthrough_submit(action: String, intent: Dictionary, source: Node) -> Dictionary:
	if action not in ["feast_cook", "feast_feed", "master_duel", "master_chest"]: return _foundation_refusal("action_unavailable")
	var key := "personal_feast_feed"
	if action in ["master_duel", "master_chest"]:
		if not is_instance_valid(source) or source.get_script() != preload("res://scripts/masters/master_site.gd") or source.get("master_id") != intent.get("master_id"): return _foundation_refusal("actual_master_site_required")
		key = "master:" + str(intent.master_id)
	if action == "feast_cook":
		if not is_instance_valid(source) or not source.is_in_group("placed_building"): return _foundation_refusal("actual_kitchen_required")
		key = "%s:%s:%s" % [source.get_meta("building_id", ""), source.get_meta("realm", ""), source.get_meta("building_uid", "")]
	var view := homestead_personal_view()
	return _foundation_send(action, key, intent, int(view.get("registry_revision", -1)))

func _foundation_master_site(peer: int, master_id: String, chest: bool) -> Node3D:
	if STATION_RULES.config().get("runtime_enabled") != true or _altar_peer_in_combat(peer): return null
	var definition := preload("res://scripts/creatures/breakthrough.gd").master(master_id)
	var writer := get_node_or_null(^"LedgerRpc")
	if definition.is_empty() or writer == null or admitted_character_state(peer).is_empty(): return null
	var actor: Dictionary = writer.call("_water_actor_context", peer, {})
	if not actor.get("position") is Vector3 or actor.get("realm") != preload("res://scripts/data/biome_order.gd").runtime_id(definition.biome): return null
	var world_node := _portal_world_node(actor.realm)
	if world_node == null: return null
	var found: Node3D
	for node: Node in world_node.find_children("*", "Node3D", true, false):
		if node.get_script() != preload("res://scripts/masters/master_site.gd") or node.get("master_id") != master_id or node.get("_mounted") != true: continue
		if found != null: return null
		found = node as Node3D
	if found == null: return null
	var anchor := found.get_node_or_null(^"RecipeChest" if chest else ^"Master") as Node3D
	return found if anchor != null and actor.position.distance_to(anchor.global_position) <= float(definition.prompt_radius_m) else null

func _foundation_master_director(site: Node3D) -> Node:
	if site == null: return null
	for node: Node in site.get_parent().find_children("*", "Node", true, false):
		if node.get_script() != null and FOUNDATION_DIRECTORS.has(node.get_script().resource_path): return node
	return null

## Called only from the bound live host director after CombatManager's actual
## won outcome. It is deliberately excluded from the public action RPC.
func foundation_master_outcome(director: Node, frozen: Dictionary) -> Dictionary:
	if not is_host() or not is_instance_valid(director) or director.get_script() == null \
		or not FOUNDATION_DIRECTORS.has(director.get_script().resource_path) \
		or director.get("_session") != self or director.call("retained_master_win") != frozen \
		or director.get("_manager").call("outcome") != "won" or frozen.get("character_id") != _authority_character(local_peer_id()) \
		or frozen.get("world_namespace") != _game().get("world").reward_delivery_namespace \
		or frozen.get("session_id") != _game().get("world").world_id \
		or not frozen.get("participants") is Dictionary or frozen.participants.size() != 1 \
		or not frozen.participants.has(local_peer_id()): return FOUNDATION_ACTIONS.deny("canonical_duel_win_required")
	var intent := {"master_id": frozen.master_id, "creature_uid": frozen.creature_uid, "encounter_id": frozen.encounter_id}
	var character: String = frozen.character_id
	var world: RefCounted = _game().get("world")
	var row: Dictionary = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character), {})
	if row.get("action") == "master_win" and row.get("intent") == intent: return {"ok": true, "durable": true}
	var context := {"source_key": "master_encounter:" + frozen.encounter_id, "validated_host_outcome": "win", "participant_count": frozen.participants.size(),
		"encounter_id": frozen.encounter_id, "creature_uid": frozen.creature_uid, "master_id": frozen.master_id}
	return get_node(^"LedgerRpc").call("journal_foundation_event", "master:%s:%s" % [frozen.master_id, frozen.encounter_id], [{"character_id": character, "action": "master_win", "intent": intent, "context": context}])

## The independent host simulation's actual accepted terminal is the producer.
## This is not an RPC and accepts no guest-declared win or creature result.
func foundation_guest_master_outcome(director: Node, frozen: Dictionary) -> Dictionary:
	if not is_host() or not is_instance_valid(director) or director.get_script() == null \
		or not FOUNDATION_DIRECTORS.has(director.get_script().resource_path) or director.get("_session") != self \
		or not frozen.get("encounter_id") is String or frozen.encounter_id.is_empty() \
		or director.call("retained_guest_master_win", frozen.encounter_id) != frozen \
		or frozen.get("world_namespace") != _game().get("world").reward_delivery_namespace \
		or frozen.get("session_id") != _game().get("world").world_id \
		or not frozen.get("participants") is Dictionary or frozen.participants.size() != 1:
		return FOUNDATION_ACTIONS.deny("canonical_guest_duel_win_required")
	var participant: Dictionary = frozen.participants.values()[0]
	if participant.get("character_id") != frozen.get("character_id") or participant.get("creature_uid") != frozen.get("creature_uid"):
		return FOUNDATION_ACTIONS.deny("canonical_guest_duel_win_required")
	var intent := {"master_id": frozen.master_id, "creature_uid": frozen.creature_uid, "encounter_id": frozen.encounter_id}
	var context := {"source_key": "master_encounter:" + frozen.encounter_id, "validated_host_outcome": "win", "participant_count": 1,
		"encounter_id": frozen.encounter_id, "creature_uid": frozen.creature_uid, "master_id": frozen.master_id}
	return get_node(^"LedgerRpc").call("journal_foundation_event", "master:%s:%s" % [frozen.master_id, frozen.encounter_id],
		[{"character_id": frozen.character_id, "action": "master_win", "intent": intent, "context": context}])

func _personal_tm_context(peer: int, key: String) -> Dictionary:
	# Learning uses the admitted owner's portable Satchel. Equipping continues
	# to require the actual Altar/camp context in the loadout action.
	var character := _authority_character(peer)
	if character.is_empty() or key != "personal_tm:" + character or _altar_peer_in_combat(peer): return {}
	return {"character_id": character, "expected_revision": int(_character_authority.call("revision", character)),
		"source_key": key, "in_range": true, "in_combat": false, "owns_character": true}

func personal_tm_scope() -> Dictionary:
	var envelope := _altar_envelope("tm_teach", "personal_tm:" + _local_character_id())
	if envelope.is_empty(): return {}
	return {"character_id": envelope.character_id, "world_namespace": envelope.world_namespace, "session_epoch": envelope.session_epoch}

func personal_tm_submit(original: Dictionary, revision: int, scope: Dictionary) -> Dictionary:
	if scope.is_empty() or not ESSENCE._equivalent(scope, personal_tm_scope()): return _foundation_refusal("tm_owner_context_changed")
	return _foundation_send("tm_teach", "personal_tm:" + _local_character_id(), original, revision)

func _personal_pouch_context(peer: int, key: String) -> Dictionary:
	var character := _authority_character(peer)
	if not preload("res://scripts/combat/tether_commands.gd").enabled() or character.is_empty() \
		or key != "personal_pouch:" + character or _altar_peer_in_combat(peer): return {}
	return {"character_id": character, "expected_revision": int(_character_authority.call("revision", character)),
		"source_key": key, "station_kind": "personal_pouch", "in_range": true, "in_combat": false, "owns_character": true}

func personal_pouch_scope() -> Dictionary:
	var envelope := _altar_envelope("tether_pouch", "personal_pouch:" + _local_character_id())
	if envelope.is_empty(): return {}
	return {"character_id": envelope.character_id, "world_namespace": envelope.world_namespace, "session_epoch": envelope.session_epoch}

func personal_pouch_available() -> bool:
	return preload("res://scripts/combat/tether_commands.gd").enabled() and not _altar_peer_in_combat(local_peer_id())

func personal_pouch_submit(original: Dictionary, revision: int, scope: Dictionary) -> Dictionary:
	if scope.is_empty() or not ESSENCE._equivalent(scope, personal_pouch_scope()): return _foundation_refusal("pouch_owner_context_changed")
	return _foundation_send("tether_pouch", "personal_pouch:" + _local_character_id(), original, revision)
func personal_candy_submit(original: Dictionary, revision: int, scope: Dictionary) -> Dictionary:
	if scope.is_empty() or not ESSENCE._equivalent(scope, personal_tm_scope()): return _foundation_refusal("candy_owner_context_changed")
	return _foundation_send("candy_feed", "personal_candy_feed", original, revision)

func homestead_submit_action(action: String, original: Dictionary, station: Node3D, revision: int) -> Dictionary:
	var key := "homestead_recovery"
	if is_instance_valid(station): key = "%s:%s:%s" % [station.get_meta("building_id", ""), station.get_meta("realm", ""), station.get_meta("building_uid", "")]
	if action == "groom" and not is_host():
		var retained := retained_training_transaction(["groom"])
		if retained.get("intent") != original: return _groom_service().call("begin", original, key)
	return _foundation_send(action, key, original, revision)

func homestead_start_refining(station: Node3D, recipe_id: String, amount: int) -> Dictionary:
	if not is_instance_valid(station) or station.get_script() != preload("res://scripts/build/station_piece.gd") \
		or station.call("station_id") != "forge": return _foundation_refusal("actual_forge_required")
	return _foundation_send("refine_start", station.call("source_key"), {"recipe_id": recipe_id, "amount": amount}, -1)

func homestead_actor_context(actor: CharacterBody3D, uid: String) -> Dictionary:
	var forge := get_node_or_null(^"FoundationComposition/ForgeHost")
	return forge.call("actor_context", actor, uid) if forge != null else {}

func homestead_commit_refine_unit(plan: Dictionary, ticket: String, actor: CharacterBody3D) -> Dictionary:
	var forge := get_node_or_null(^"FoundationComposition/ForgeHost")
	return forge.call("commit_unit", plan, ticket, actor) if forge != null else {}

func retained_training_transaction(actions: Array) -> Dictionary:
	# Read the existing durable journal after reload. This is a presentation
	# projection, never a new transaction, receipt or owner candidate.
	var row := _owner_training_row()
	var game := _game()
	if game == null or game.get("world") == null or game.get("local") == null \
		or not TRAINING_WORLD.training_row_valid(row, game.get("world").reward_delivery_namespace, game.get("world").world_id) \
		or row.character_id != _local_character_id() or not actions.has(row.action): return {}
	return {"action": row.action, "intent": row.intent.duplicate(true), "receipt": row.receipt,
		"original_revision": int(row.character_revision) - 1, "status": row.status}

func _register_homestead_station_node(key: String, station: Node3D) -> bool:
	if not is_instance_valid(station) or not station.is_in_group("placed_building"): return false
	var checked := STATION_RULES.record(STATION_RULES.config(), _game().get("world").placed_buildings, str(station.get_meta("building_uid", "")))
	if checked.get("ok") != true or checked.key != key: return false
	var prior: WeakRef = _homestead_stations.get(key)
	if prior != null and prior.get_ref() != null and prior.get_ref() != station: return false
	_homestead_stations[key] = weakref(station)
	return true

func _unregister_homestead_station_node(key: String, station: Node3D) -> void:
	var prior: WeakRef = _homestead_stations.get(key)
	if prior != null and prior.get_ref() == station: _homestead_stations.erase(key)

## The host's reach is measured from the point the station's own prompt is
## offered at (interaction_origin), so a prompt the player can use is in range.
func _station_interaction_origin(station: Node3D) -> Vector3:
	return station.call("interaction_origin") if station.has_method("interaction_origin") else station.global_position

func _foundation_source(peer: int, key: String, part: String = "workbench") -> Dictionary:
	if not is_host() or admitted_character_state(peer).is_empty(): return {}
	var actor_transport := get_node_or_null(^"LedgerRpc")
	if actor_transport == null: return {}
	var actor: Dictionary = actor_transport.call("_water_actor_context", peer, {})
	if actor.get("character_id") != _authority_character(peer) or not actor.get("position") is Vector3 or _altar_peer_in_combat(peer): return {}
	if key.begins_with("forward_camp:"): return _foundation_camp_context(peer, key, actor, part)
	var weak: WeakRef = _homestead_stations.get(key, _altar_stations.get(key))
	var station := weak.get_ref() as Node3D if weak != null else null
	if station == null or not station.is_inside_tree(): return {}
	var cfg := STATION_RULES.config()
	if cfg.get("runtime_enabled") != true: return {}
	var checked := STATION_RULES.record(cfg, _game().get("world").placed_buildings, str(station.get_meta("building_uid", "")))
	if checked.get("ok") != true or checked.key != key or actor.get("realm") != checked.record.realm: return {}
	var p: Array = checked.record.position
	if station.global_position.distance_to(Vector3(p[0], p[1], p[2])) > 0.01 \
		or absf(wrapf(rad_to_deg(station.global_rotation.y) - checked.record.yaw_deg, -180, 180)) > 0.01 \
		or actor.position.distance_to(_station_interaction_origin(station)) > float(cfg.interaction_radius_m): return {}
	var tier := STATION_RULES.effective_tier(cfg, _game().get("world").placed_buildings, checked.record.uid)
	if tier.get("ok") != true: return {}
	return {"character_id": _authority_character(peer), "expected_revision": int(_character_authority.call("revision", _authority_character(peer))),
		"source_key": key, "station_id": checked.record.id, "station_kind": checked.record.id,
		"homestead": true, "in_range": true, "in_combat": false, "effective_tier": tier.effective_tier, "den_index": checked.index}

## Only a registered, paid Den and the admitted actor's current host-observed
## presence can start care. The exact saved original reconciles earlier in
## _foundation_handle, so source loss never strands an accepted transaction.
func _foundation_groom_context(peer: int, key: String) -> Dictionary:
	if not is_inside_tree() or not is_host(): return {}
	var game := _game()
	var cfg := STATION_RULES.config()
	if game == null or game.get("world") == null or cfg.get("runtime_enabled") != true \
		or cfg.get("den_runtime_enabled") != true or cfg.get("den", {}).get("runtime_enabled") != true \
		or preload("res://scripts/data/redesign_data.gd").json("res://data/config/f32_runtime.json").get("runtime_enabled") != true: return {}
	var source := _foundation_source(peer, key)
	if source.get("station_id") != "den" or source.get("homestead") != true: return {}
	var weak: WeakRef = _homestead_stations.get(key)
	var station := weak.get_ref() as Node3D if weak != null else null
	var lifecycle := get_node_or_null(^"FoundationComposition/TravelLifecycle")
	if station == null or not station.is_inside_tree() or station.is_queued_for_deletion() \
		or station.get_script() != preload("res://scripts/build/station_piece.gd") or lifecycle == null: return {}
	var actor := game.call("find_player") as CharacterBody3D if peer == local_peer_id() else lifecycle.call("remote_body", peer) as CharacterBody3D
	var safety: Dictionary = lifecycle.call("local_sample") if peer == local_peer_id() else lifecycle.call("host_context", peer)
	if actor == null or not actor.is_inside_tree() or actor.is_queued_for_deletion() or safety.get("realm") != "meadows": return {}
	var preparation_fence: bool = peer != local_peer_id() and _groom_passive != null \
		and _groom_passive.call("allows_fence", peer, key) == true and safety.get("station_ack_only") == true
	for hazard: String in ["dialogue", "cutscene", "downed", "swimming", "flying"]:
		if preparation_fence and hazard in ["dialogue", "cutscene"]: continue
		if safety.get(hazard) != false: return {}
	var shell := _portal_world_node("meadows")
	if shell == null or not shell.is_ancestor_of(actor) or not shell.is_ancestor_of(station) \
		or actor.global_position.distance_to(_station_interaction_origin(station)) > float(cfg.den.radius_m): return {}
	var world: RefCounted = game.get("world")
	var uid := str(station.get_meta("building_uid", ""))
	if not ESSENCE._integer(world.day, 1, 2147483646) or not ESSENCE._opaque_id(world.world_id) \
		or not ESSENCE._opaque_id(world.reward_delivery_namespace) or key != "den:meadows:" + uid: return {}
	source.merge({"source_id": uid, "source_generation": uid, "world_id": world.world_id,
		"world_namespace": world.reward_delivery_namespace, "host_day": int(world.day),
		"realm": "meadows", "actor_realm": "meadows", "registered_live_source": true,
		"paid_den": true, "modal_open": false, "resource_runtime_authorized": true}, true)
	return source

func homestead_station_available(key: String) -> bool:
	if not snapshot_ready() or _owner_training_mutation_blocked(_game().get("local")): return false
	if is_host(): return _foundation_source(local_peer_id(), key).get("in_range") == true
	return not _altar_current_epoch().is_empty() and _homestead_stations.has(key)

func homestead_gear_context(station: Node3D, revision: int) -> Dictionary:
	if not is_instance_valid(station) or not is_host(): return {}
	var key := "%s:%s:%s" % [station.get_meta("building_id", ""), station.get_meta("realm", ""), station.get_meta("building_uid", "")]
	var context := _foundation_source(local_peer_id(), key)
	return context if context.get("expected_revision") == revision else {}

func _foundation_camp_context(peer: int, key: String, actor: Dictionary, part: String) -> Dictionary:
	const CAMP = preload("res://scripts/build/forward_camp_rules.gd")
	var camp: Node3D
	for node: Node in get_tree().get_nodes_in_group("placed_building"):
		if node.get_script() != preload("res://scripts/build/forward_camp.gd") or node.call("source_key") != key: continue
		if camp != null: return {}
		camp = node as Node3D
	if camp == null or not camp.is_inside_tree() or camp.scale != Vector3.ONE: return {}
	var context := CAMP.source_context(CAMP.config(), _game().get("world").placed_buildings,
		str(camp.get_meta("building_uid", "")), actor.position, actor.realm, _authority_character(peer),
		int(_character_authority.call("revision", _authority_character(peer))), false, part)
	var source := CAMP.record(_game().get("world").placed_buildings, str(camp.get_meta("building_uid", "")))
	if context.is_empty() or source.get("ok") != true: return {}
	var p: Array = source.record.position
	if camp.global_position.distance_to(Vector3(p[0], p[1], p[2])) > 0.01 \
		or absf(wrapf(rad_to_deg(camp.global_rotation.y) - source.record.yaw_deg, -180, 180)) > 0.01: return {}
	return context

func forward_camp_available(camp: Node3D) -> bool:
	if not is_instance_valid(camp): return false
	if not is_host():
		var game := _game()
		if game == null or game.get("world") == null or game.get("local") == null \
			or not snapshot_ready() or _owner_training_mutation_blocked(game.get("local")) \
			or _altar_peer_in_combat(local_peer_id()): return false
		var scope := _foundation_view_scope(_altar_envelope("personal_view", "homestead_view"))
		var view := _personal_view_for_scope(scope)
		if scope.is_empty() or int(view.get("registry_revision", -1)) < 0:
			_camp_revision_known()
			return false
		var actor := game.call("find_player") as Node3D
		if not is_instance_valid(actor) or not actor.is_inside_tree(): return false
		return _forward_camp_guest_in_range(camp, game.get("world").placed_buildings,
			actor.global_position, _local_realm(), _local_character_id(), int(view.registry_revision))
	for part: String in ["bed", "workbench", "cookpot"]:
		if _foundation_source(local_peer_id(), camp.call("source_key"), part).get("in_range") == true: return true
	return false

## A guest may present the current camp; every action still quotes/commits on
## the host. No cached character state authorizes a debit or loadout change.
static func _forward_camp_guest_in_range(camp: Node3D, records: Array, actor_at: Vector3,
		realm: String, character: String, revision: int) -> bool:
	const CAMP = preload("res://scripts/build/forward_camp_rules.gd")
	if not is_instance_valid(camp) or not camp.is_inside_tree() or not camp.is_in_group("placed_building") \
		or camp.get_script() != preload("res://scripts/build/forward_camp.gd") or camp.scale != Vector3.ONE: return false
	var uid := str(camp.get_meta("building_uid", ""))
	var source := CAMP.record(records, uid)
	if source.get("ok") != true or camp.call("source_key") != source.key \
		or str(camp.get_meta("realm", "")) != realm: return false
	for node: Node in camp.get_tree().get_nodes_in_group("placed_building"):
		if node != camp and node.get_script() == preload("res://scripts/build/forward_camp.gd") \
			and node.call("source_key") == source.key: return false
	return _forward_camp_record_in_range(records, uid, camp.global_transform, actor_at, realm, character, revision)

static func _forward_camp_record_in_range(records: Array, uid: String, pose: Transform3D,
		actor_at: Vector3, realm: String, character: String, revision: int) -> bool:
	const CAMP = preload("res://scripts/build/forward_camp_rules.gd")
	var source := CAMP.record(records, uid)
	if source.get("ok") != true: return false
	var p: Array = source.record.position
	if not pose.is_finite() or pose.origin.distance_to(Vector3(p[0], p[1], p[2])) > 0.01 \
		or not pose.basis.is_equal_approx(Basis(Vector3.UP, deg_to_rad(source.record.yaw_deg))): return false
	for part: String in ["bed", "workbench", "cookpot"]:
		if CAMP.source_context(CAMP.config(), records, uid, actor_at, realm, character,
			revision, false, part).get("in_range") == true: return true
	return false

func forward_camp_prepare_rest(camp: Node3D, original: Dictionary) -> Dictionary:
	if not is_instance_valid(camp): return FOUNDATION_ACTIONS.deny("camp_unavailable")
	var view := homestead_personal_view()
	return _foundation_send("camp_rest", camp.call("source_key"), original, int(view.get("registry_revision", -1)))

func forward_camp_placement_available() -> bool:
	return preload("res://scripts/build/forward_camp_rules.gd").config().get("runtime_enabled") == true \
		and snapshot_ready() and _foundation_camp_pending.is_empty() and not _owner_training_mutation_blocked(_game().get("local")) \
		and _camp_revision_known()

## A guest's camp intent carries its admitted character revision from the
## host's personal view; until one has arrived it asks (at most once a second).
func _camp_revision_known() -> bool:
	if is_host(): return true
	if int(_foundation_personal_cache.get("registry_revision", -1)) >= 0: return true
	var now := Time.get_ticks_msec()
	if now - _camp_view_requested_ms >= 1000:
		_camp_view_requested_ms = now
		homestead_personal_view()
	return false

func forward_camp_submit_build(original: Dictionary, placer: Node) -> Dictionary:
	if not is_instance_valid(placer) or placer.get_script() != preload("res://scripts/build/build_placer.gd"): return FOUNDATION_ACTIONS.deny("actual_placer_required")
	if not _foundation_camp_pending.is_empty():
		return FOUNDATION_ACTIONS.deny("reconcile_original_camp")
	if not _camp_revision_known(): return FOUNDATION_ACTIONS.deny("camp_unavailable")
	var view := homestead_personal_view()
	_foundation_camp_pending = {"original": original.duplicate(true), "revision": int(view.get("registry_revision", -1)),
		"character_id": _local_character_id(), "world_namespace": _game().get("world").reward_delivery_namespace}
	return _retry_foundation_camp()

func _retry_foundation_camp() -> Dictionary:
	if _foundation_camp_pending.is_empty(): return {}
	if _foundation_camp_pending.character_id != _local_character_id() \
		or _foundation_camp_pending.world_namespace != _game().get("world").reward_delivery_namespace: return FOUNDATION_ACTIONS.deny("original_character_world_required")
	var result := _foundation_send("camp_build", "forward_camp_build", _foundation_camp_pending.original, _foundation_camp_pending.revision)
	if result.get("settled") == true or result.get("terminal_refusal") == true: _foundation_camp_pending.clear()
	return result

func _foundation_build_context(peer: int, original: Dictionary) -> Dictionary:
	if preload("res://scripts/build/forward_camp_rules.gd").config().get("runtime_enabled") != true \
		or not is_host() or _altar_peer_in_combat(peer): return {}
	var game := _game()
	var actor: Node3D = game.call("find_player") as Node3D if peer == local_peer_id() else _foundation_remote_actor(peer)
	if actor == null or admitted_character_state(peer).is_empty(): return {}
	var character := _authority_character(peer)
	var revision := int(_character_authority.call("revision", character))
	var context := {}
	for placer: Node in get_tree().get_nodes_in_group("build_placer"):
		if not placer.get_parent().is_ancestor_of(actor): continue
		if original.get("action") == "place":
			context = preload("res://scripts/build/forward_camp_host.gd").placement_context(placer, game, actor, character, revision, _local_realm(), false, original)
		elif original.get("action") == "pack":
			var parties: Array = []
			var complete := true
			var peers: Array = _registry.call("peer_ids")
			if not peers.has(peer): peers.append(peer)
			for admitted_peer: int in peers:
				if admitted_character_state(admitted_peer).is_empty(): complete = false; break
				parties.append(_character_authority.call("state", _authority_character(admitted_peer)).party)
			for node: Node in get_tree().get_nodes_in_group("placed_building"):
				if node.get_meta("building_uid", "") != original.get("uid"): continue
				context = preload("res://scripts/build/forward_camp_host.gd").pack_context(placer, game, node as Node3D, actor, character, revision, _local_realm(), false, parties, complete)
		break
	if context.is_empty(): return {}
	context.source_key = "forward_camp_build"
	context.world_before = game.get("world").placed_buildings.duplicate(true)
	context.next_building_uid = int(game.get("world").next_building_uid)
	return context

## F34#4: a guest's camp is validated against its own host-side trainer body,
## which must stand in the host's loaded realm (the host's placer and ground
## decide); its realm comes from the host's own actor transport, never a packet.
func _foundation_remote_actor(peer: int) -> Node3D:
	var lifecycle := get_node_or_null(^"FoundationComposition/TravelLifecycle")
	var transport := get_node_or_null(^"LedgerRpc")
	if lifecycle == null or transport == null: return null
	var body := lifecycle.call("remote_body", peer) as Node3D
	var seen: Dictionary = transport.call("_water_actor_context", peer, {})
	if body == null or not body.is_inside_tree() or seen.get("character_id") != _authority_character(peer) \
		or str(seen.get("realm", "")) != _local_realm(): return null
	return body

func open_creature_loadouts(camp: Node3D, key: String) -> bool:
	if not forward_camp_available(camp) or camp.call("source_key") != key: return false
	var members: Array = _game().get("local").party.call("members")
	if members.is_empty(): return false
	var panel: CanvasLayer = preload("res://scripts/ui/companion_details_panel.gd").new()
	_game().add_child(panel)
	var service := _game().get_node_or_null(^"FoundationLoadoutService")
	if panel.call("configure_loadout_service", service, key) != true: panel.queue_free(); return false
	return panel.call("open", _game(), str(members[0].uid), "Loadout", true) == true

const REDESIGN_STATE := preload("res://scripts/data/redesign_state.gd")

## Stage B Wave 2 lane 2.A. THE SESSION: host, join, leave, and the handshake.
##
## Mounted by `game_state.gd::_ready()` as `/root/Game/Session`. A child of the
## one autoload rather than a second autoload (the one-autoload rule), and a
## `Node` rather than a `RefCounted` because it needs `multiplayer`, RPCs and a
## `_process` tick. The node path is identical in every process, which is what
## makes its RPCs resolve at all.
##
## D95 is the transport contract: `ENetMultiplayerPeer`, listen server, up to
## four peers, TWO transfer channels -- `CHANNEL_LEDGER` for ledger/encounter
## traffic and `CHANNEL_SNAPSHOT` for the world snapshot, so a joiner's snapshot
## never queues behind somebody's movement. Nothing outside this file calls
## `multiplayer.` to open or close a peer.
##
## ## Solo is a one-peer session
##
## `title_screen.gd::_enter_world()` calls `host()` on both Start New Game and
## Load, so there is exactly one code path into play. A solo player is a host
## with no clients: `is_host()` true, `peer_count()` 1, `is_multi_peer()` false.
##
## `is_host()` is deliberately true when there is NO session at all. Every
## headless test, capture tool and editor run that never hosts anything still
## has to be allowed to write its world -- "not a client" is the honest question
## the four D100 autosave sites are actually asking, and answering it with
## `multiplayer.is_server()` would have made every one of them false in exactly
## those contexts (that call needs a live peer to mean anything).
##
## ## Spike gotchas honoured here
## (`ralph/reports/MP-0C-SPIKE-ENET-0905/REPORT.md`)
##
##   1. Every flag a signal sets lives in `_box`, a Dictionary -- a GDScript
##      lambda captures an outer `bool` BY VALUE, so a polling loop reading a
##      bare local hangs forever with no error. `join()`'s two waits read `_box`.
##   2. Peer ids are large random 32-bit numbers; only the listen server is 1.
##      `peer_registry.gd` keys on the real id and logs it verbatim.
##   3. Authority is set inside a `spawn_function`, never after tree entry.
##      No spawner here yet (2.C owns the rigs); noted so it is not forgotten.

const PEER_REGISTRY := preload("res://scripts/net/peer_registry.gd")
const REALM_SHELLS := preload("res://scripts/net/realm_shells.gd")
const REALM_TRANSITION := preload("res://scripts/net/realm_transition.gd")
const SNAPSHOT_TRANSFER := preload("res://scripts/net/snapshot_transfer.gd")
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const TRAINING_WORLD := preload("res://autoload/world_state.gd")
const CHARACTER_AUTHORITY := preload("res://scripts/net/character_authority.gd")
const CHARACTER_IDENTITY := preload("res://scripts/save/character_identity.gd")
const BUILD_FINGERPRINT := preload("res://scripts/net/build_fingerprint.gd")
## Kept as text rather than preloading steam_lobby.gd, which Session must not
## depend on. test_steam_lobby.gd pins the two strings together.
const STEAM_PROTOCOL_REFUSAL := "This connection uses an incompatible Tetherbound protocol."
const CONFIG_PATH := "res://data/config/multiplayer.json"
const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"

## D95's two channels. Godot adds its own three system channels beneath these,
## so transfer_channel 1 and 2 are ENet channels 3 and 4 on the wire.
const CHANNEL_LEDGER := 1
const CHANNEL_SNAPSHOT := 2

## Frames a leaving host keeps its socket open so the reliable `session_ended`
## broadcast reaches everyone. Six at 60 Hz is 100 ms -- two orders of magnitude
## over the 6.9 ms median loopback RTT the ENet spike measured, and still
## imperceptible to the player who just chose to quit.
const CLOSE_FLUSH_FRAMES := 6
## Terminal reasons (refusal, kick, snapshot abort, host exit) are reliable
## RPCs. ENet's disconnect discards reliable packets the other side has not
## acknowledged yet, so on a lossy link a fixed frame count can drop the
## reason. The client learns nothing, and with the long realm-loading
## peer timeout it waits out the generic handshake timeout. Instead the
## host keeps the link up after CLOSE_FLUSH_FRAMES until the other side
## closes it (clients tear down as soon as a terminal reason arrives) or
## these bounds pass. Measured on the harness proxy at 30% loss and
## 150+-30 ms delay: ralph/reports/INVITE-COOP.
const REFUSAL_LINGER_S := 10.0
const HOST_CLOSE_LINGER_S := 5.0
## A client that says goodbye keeps its old transport open this long for the
## host to close the link. The host closes only after it has read the goodbye;
## closing from the client side straight away lets ENet discard the unread
## goodbye with the disconnect. Only the detached transport waits: the session
## itself ends at once (`_lingering_peer`).
const GOODBYE_LINGER_S := 1.5

const HOST_PEER_ID := PEER_REGISTRY.HOST_PEER_ID

var _altar_epoch := Crypto.new().generate_random_bytes(16).hex_encode()
var _altar_host_epoch := ""
var _tether_tonic_observer_scope: Array = []
var _altar_host_namespace := ""
var _altar_stations: Dictionary = {} # Weak mounted nodes, never placement truth.
var _altar_quote_request: Dictionary = {}
var _altar_spend_request: Dictionary = {}
var _owner_training_retry: Dictionary = {} # Only weak refs + exact row identity, no balances.
var _owner_training_install := false
var _owner_training_install_rollback := false
var _training_bootstrap_waiting := false
var _character_authority: RefCounted = CHARACTER_AUTHORITY.new()


signal altar_essence_quote_completed(key: String, owned_uid: String, quote_id: String, result: Dictionary)
signal altar_essence_spend_completed(key: String, spend_id: String, result: Dictionary)
signal peer_joined(peer_id: int, character_id: String)
signal peer_left(peer_id: int)
## Wave 6 lane 6.A. Somebody crossed a realm boundary without leaving the
## session. Emitted on every peer, from the replicated registry, so a world
## scene can reconcile what it draws without asking who moved.
signal peer_realm_changed(peer_id: int, from_realm: String, to_realm: String)
## Host-local terminal edge for a coordinated client departure. The registry
## changes at `peer_realm_changed`; old authoritative bodies may be retained
## invisibly until this later receiver-ready boundary drains their final state.
signal peer_realm_departure_settled(peer_id: int, from_realm: String, to_realm: String)
signal snapshot_applied()
signal stormwood_strike_received(event: Dictionary)
signal stormwood_arch_arrival(event: Dictionary)
signal stormwood_encounter_message(event: Dictionary)
signal session_ended(reason: String)
## Emitted only after the active MultiplayerPeer has been detached and closed.
## A platform lobby can use this edge to leave its discovery lobby without
## racing the host's reliable session-ended flush.
signal transport_closed()

## "" (no session), "host" or "client". The single source of truth for
## `is_host()`; `multiplayer.is_server()` is only consulted inside RPC bodies,
## where a live peer is guaranteed to exist.
var _mode: String = ""
var _peer: MultiplayerPeer = null
var _transport_kind := ""
## World-first joins load their destination before constructing a peer. During
## that measured load window they are already prospective clients: they must
## neither act as authority nor save the temporary local world/character.
var _preparing_client := false
var _registry: RefCounted = PEER_REGISTRY.new()
var _config: Dictionary = {}
var _clock_accum: float = 0.0
var _capacity: int = 0

## Spike finding 2 (the real one): a Dictionary state box for every flag a
## signal callback sets and a polling loop reads. `connected`, `snapshot` and
## `failed` are all set from signal or RPC context, and read by callers polling
## `snapshot_ready()` / `is_active()` a frame at a time.
##
## NOTHING in this file is a coroutine, deliberately. Every public entry point
## returns immediately and the caller polls -- a step arm with a frame budget, a
## UI screen with a spinner. An `await` inside `host()`/`join()`/`leave()` would
## have to survive being reached through `Object.call()` (which is how
## `game_state.gd` and `peer_runner.gd` both reach this file, since there is no
## `class_name` to type against), and a suspended call through `call()` is
## exactly the kind of thing that works until it silently does not.
##
## `snapshot` starts TRUE, not false: it is the answer to "may this process act
## in the world", and a solo or session-less process may. Only `join()` closes
## it, and only the host's snapshot reopens it.
var _box: Dictionary = {
	"connected": false,
	"snapshot": true,
	"handshake_snapshot_applied": false,
	"failed": false,
	"host_rejected": false,
	"failure_reason": "",
	"ended": "",
}

## The character summary `join()` was given, sent the moment ENet reports the
## connection up (`_on_connected_to_server`).
var _pending_hello: Dictionary = {}

## Frames left before a leaving host may close its socket. A reliable
## `session_ended` broadcast has to get off the wire before the peer under it
## goes away, and counting frames in `_process` is how that happens without
## this function becoming a coroutine. After the frames, the host still waits
## for every remote peer to close (they tear down on the reason) or for
## `_closing_deadline_ms`, whichever is first.
var _closing_frames: int = 0

## A leaving client's old transport, detached from this Session and polled on
## its own until the host closes it or GOODBYE_LINGER_S passes. The session is
## already over (`is_active()` false, `session_ended` emitted), so the title can
## host, load or join again straight away.
var _lingering_peer: MultiplayerPeer = null
var _lingering_deadline_ms := 0
var _closing_deadline_ms: int = 0
var _closing_reason: String = ""

## Unadmitted, kicked or aborted transport peer -> `{frames, deadline_ms}`.
## The per-peer form of the host-close lifecycle above: queue the terminal
## reason, keep the socket alive for at least CLOSE_FLUSH_FRAMES, and then
## until the peer closes it (`_on_peer_disconnected` erases the entry) or
## the refusal deadline passes. These peers are not in the registry while
## they linger, so they are never admitted and never receive a snapshot.
var _rejected_disconnect_frames: Dictionary = {}

## Admitted peers that said goodbye before closing (`leave()` on a client).
## Their disconnect frees the seat at once instead of reserving it for the
## reconnect window. A lost goodbye only means the seat is held, which is the
## safe direction.
var _departing_peers: Dictionary = {}

## Admitted peers whose character took a held reconnect seat at hello.
var _reserved_rejoins: Dictionary = {}

## One snapshot chunk may be in flight per joining peer. The receiver boundary
## is raised only by BEGIN on the ledger channel; chunks remain independently
## ordered on the snapshot channel and are acknowledged one at a time.
var _snapshot_sends: Dictionary = {}
var _next_snapshot_transfer_id := 1
var _snapshot_receive: RefCounted = SNAPSHOT_TRANSFER.new()
var _snapshot_receive_id := 0
var _early_snapshot_chunk: Dictionary = {}
var _bootstrap_boundary := false
var _bootstrap_deltas: Array[Dictionary] = []
var _bootstrap_delta_bytes := 0
var _latest_bootstrap_registry: Dictionary = {}
var _bootstrap_registry_received := false
var _pending_snapshot_ack: Dictionary = {}

## Wave 6 lane 6.A: `/root/Game/Session/Realms`, the host's headless shells.
## Mounted in `_ready()` so its node path is identical in every process, the
## same reason `LedgerRpc` is mounted with the session rather than by its
## first consumer.
var _realms: Node = null
var realm_transition: Node = null


func _ready() -> void:
	name = "Session"
	get_tree().auto_accept_quit = false
	add_to_group(preload("res://scripts/ui/input_owner.gd").GROUP)
	add_to_group("story_modal")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_config = _load_config()
	realm_transition = REALM_TRANSITION.new()
	add_child(realm_transition)
	_realms = REALM_SHELLS.new()
	add_child(_realms)
	var api := multiplayer
	if api != null:
		api.peer_connected.connect(_on_peer_connected)
		api.peer_disconnected.connect(_on_peer_disconnected)
		api.connected_to_server.connect(_on_connected_to_server)
		api.connection_failed.connect(_on_connection_failed)
		api.server_disconnected.connect(_on_server_disconnected)


func _load_config() -> Dictionary:
	# `FileAccess.open` on `res://data/config/*.json`, the same way
	# `spawn_tables.gd::config()` and every other config reader in this repo
	# does it -- not `ResourceLoader`, which would treat the file as an import.
	var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var section: Variant = (parsed as Dictionary).get("session", {})
	return section if typeof(section) == TYPE_DICTIONARY else {}


func config() -> Dictionary:
	return _config.duplicate(true)


func _cfg(key: String, fallback: Variant) -> Variant:
	var v: Variant = _config.get(key, fallback)
	return v if v != null else fallback


func default_port() -> int:
	return int(_cfg("port", 27015))


func max_peers() -> int:
	return int(_cfg("max_peers", 4))


# --- public API ---------------------------------------------------------------

## Open a listen server. Returns whether the port was bound.
##
## Never fatal: a failed bind (another process already on the port, a locked
## down box) leaves the session inactive, which is a solo game that cannot be
## joined -- not a game that refuses to start. `title_screen.gd` relies on that.
func host(port: int = -1, peers: int = -1) -> bool:
	if is_active():
		return is_host()
	var use_port := port if port > 0 else default_port()
	var cap := peers if peers > 0 else max_peers()
	var p := ENetMultiplayerPeer.new()
	# create_server() counts transport CLIENTS, while `cap` counts admitted peers
	# including the host. Keep one spare transport-only handshake seat so a join
	# against a full registry reaches admission and receives `session_full`; the
	# registry remains hard-capped at `cap`, so this never creates a fifth player.
	var err := p.create_server(use_port, maxi(1, cap), int(_cfg("channel_count", 2)))
	if err != OK:
		push_warning("Session.host: could not bind udp/%d (err %d); staying offline-solo" % [use_port, err])
		return false
	if not host_with_peer(p, cap, "enet"):
		p.close()
		return false
	print("[session] hosting on udp/%d (cap %d, channels %d); local peer id %d"
		% [use_port, cap, int(_cfg("channel_count", 2)), multiplayer.get_unique_id()])
	return true


## Install an already-created listen peer. Platform discovery/relay adapters
## create their own MultiplayerPeer, but admission, identity and snapshots must
## still pass through this Session rather than growing a parallel handshake.
func host_with_peer(peer: MultiplayerPeer, cap: int = -1,
		transport_kind: String = "steam") -> bool:
	if is_active():
		return is_host() and _peer == peer
	if not transport_peer_valid(peer, true):
		push_warning("Session.host_with_peer: peer is not a connected server with peer id 1")
		return false
	var use_cap := cap if cap > 0 else max_peers()
	if use_cap < 1 or use_cap > max_peers():
		push_warning("Session.host_with_peer: capacity %d is outside 1..%d"
			% [use_cap, max_peers()])
		return false
	_peer = peer
	multiplayer.multiplayer_peer = peer
	_mode = "host"
	_transport_kind = transport_kind.strip_edges().to_lower()
	if _transport_kind.is_empty():
		_transport_kind = "custom"
	_capacity = use_cap
	_box["connected"] = true
	_box["snapshot"] = true
	_box["handshake_snapshot_applied"] = false
	_box["failed"] = false
	_box["host_rejected"] = false
	_box["failure_reason"] = ""
	_box["ended"] = ""
	_registry.call("clear")
	_registry.call("add", HOST_PEER_ID, _local_character_id(), _local_display_name(),
		_local_realm(), _local_appearance_id())
	# Hash the content now, while the host is opening, so the first joiner's
	# hello does not pay for it (build_fingerprint.gd caches per process).
	BUILD_FINGERPRINT.current()
	if _realms != null:
		_realms.call("reconcile")
	print("[session] hosting via %s (cap %d); local peer id %d"
		% [_transport_kind, use_cap, multiplayer.get_unique_id()])
	return true


## Dial a host. Returns whether the client socket was created -- NOT whether
## the handshake finished. The caller polls `snapshot_ready()`, which stays
## false until the host's world snapshot has actually been applied; that is
## deliverable 3's "a joiner may not send intents before `snapshot_applied`",
## and it is a state anything can ask at any time rather than a moment only the
## one caller that awaited `join()` ever saw.
##
## `handshake_failed()` distinguishes "still waiting" from "this will never
## finish" so a polling caller does not have to run its budget out to learn the
## connection was refused.
func join(ip: String, port: int = -1, character_summary: Dictionary = {}) -> bool:
	_close_lingering_peer()
	if is_active():
		leave()
		if is_active():
			return false
	var use_port := port if port > 0 else default_port()
	var p := ENetMultiplayerPeer.new()
	var err := p.create_client(ip, use_port, int(_cfg("channel_count", 2)))
	if err != OK:
		push_warning("Session.join: create_client(%s, %d) failed err=%d" % [ip, use_port, err])
		return false
	if not join_with_peer(p, character_summary, "enet"):
		p.close()
		return false
	print("[session] dialling %s:%d as '%s' (%s)"
		% [ip, use_port, _local_display_name(), _local_character_id()])
	return true


## Install an already-created client peer. The peer may still be CONNECTING;
## `_on_connected_to_server()` drives the same hello path used by ENet.
func join_with_peer(peer: MultiplayerPeer, character_summary: Dictionary = {},
		transport_kind: String = "steam") -> bool:
	_close_lingering_peer()
	if is_active():
		leave()
		if is_active():
			return false
	if not transport_peer_valid(peer, false):
		push_warning("Session.join_with_peer: peer is disconnected or identifies as a server")
		return false
	_peer = peer
	multiplayer.multiplayer_peer = peer
	var game := _game()
	if game != null and game.has_method("relinquish_world_save_ownership"):
		game.call("relinquish_world_save_ownership")
	_mode = "client"
	_preparing_client = false
	_transport_kind = transport_kind.strip_edges().to_lower()
	if _transport_kind.is_empty():
		_transport_kind = "custom"
	_box["connected"] = false
	_box["snapshot"] = false
	_box["handshake_snapshot_applied"] = false
	_box["failed"] = false
	_box["host_rejected"] = false
	_box["failure_reason"] = ""
	_box["ended"] = ""
	_registry.call("clear")

	# D100's portable half, on the way IN. Before the summary is built, so a
	# restored character's own realm and display name are what this peer
	# announces rather than the blank ones a fresh process holds. See
	# `_restore_character_here()` for why this is here and not after the
	# snapshot.
	_adopt_character_id(str(character_summary.get("character_id", "")))
	_restore_character_here(str(character_summary.get("character_id", "")))

	var summary := character_summary.duplicate(true)
	if not summary.has("character_id"):
		summary["character_id"] = _local_character_id()
	if not summary.has("display_name"):
		summary["display_name"] = _local_display_name()
	if not summary.has("realm"):
		summary["realm"] = _local_realm()
	if not summary.has("appearance_id"):
		summary["appearance_id"] = _local_appearance_id()
	# Build the proof from the restored portable document, never caller summary
	# fields or later per-action packet inventory/rank proposals.
	var admission_game := _game()
	if admission_game != null and admission_game.get("local") != null:
		summary["portable_authority"] = CHARACTER_AUTHORITY.portable_projection(admission_game.get("local").save_data())
		summary["personal_flags"] = admission_game.get("local").flags.call("save_data").duplicate(true)
		summary["discovered_landmarks"] = _groom_service().call("admission_landmarks")
		# The payouts this character holds settled, and those it is owed by a
		# full bag (grant_due): a rejoin is "behind" if one this world recorded
		# is in neither; only settled ones are in its satchel.
		var settled: Array[String] = []
		var owed: Array[String] = []
		for key: Variant in admission_game.get("local").satchel_escrow:
			var row: Variant = admission_game.get("local").satchel_escrow[key]
			if row is Dictionary and row.get("kind") == "reward_delivery":
				if row.get("status") == "settled": settled.append(str(key))
				elif row.get("status") == "grant_due": owed.append(str(key))
		summary["settled_deliveries"] = settled
		summary["owed_deliveries"] = owed
		summary["owner_passive_stream"] = _owner_passive_service().call("arm_owner", summary.portable_authority, summary.discovered_landmarks)
	# Always this process's own fingerprint: a caller cannot claim another build.
	summary["build"] = BUILD_FINGERPRINT.current()
	_pending_hello = summary
	print("[session] dialling via %s as '%s' (%s)"
		% [_transport_kind, str(summary["display_name"]), str(summary["character_id"])])
	return true


## Pure validation kept public for focused transport adapter tests. A client
## peer is allowed to be CONNECTING; a server must already be CONNECTED.
static func transport_peer_valid(peer: MultiplayerPeer, hosting: bool) -> bool:
	if peer == null:
		return false
	var status := peer.get_connection_status()
	if status == MultiplayerPeer.CONNECTION_DISCONNECTED:
		return false
	if hosting and status != MultiplayerPeer.CONNECTION_CONNECTED:
		return false
	var unique_id := peer.get_unique_id()
	return unique_id == HOST_PEER_ID if hosting else unique_id > HOST_PEER_ID


func transport_kind() -> String:
	return _transport_kind


static func transport_uses_enet_timeouts(peer: MultiplayerPeer) -> bool:
	return peer is ENetMultiplayerPeer


## A connection attempt is not durable play. Until the authoritative world
## snapshot lands, refusal/cancel/timeout must leave the selected portable
## character byte-for-byte untouched.
func client_character_save_ready() -> bool:
	return _mode == "client" and bool(_box.get("handshake_snapshot_applied", false))


## Close authority and snapshot gates while JoinDriver builds the destination
## world, without claiming an active session or attempting RPCs before a peer
## exists. Idempotent for the one pending join attempt.
func prepare_client_join() -> bool:
	if is_active():
		return _mode == "client"
	var game := _game()
	if game != null and game.has_method("relinquish_world_save_ownership"):
		game.call("relinquish_world_save_ownership")
	_preparing_client = true
	_box["snapshot"] = false
	_box["handshake_snapshot_applied"] = false
	_box["failed"] = false
	_box["host_rejected"] = false
	_box["failure_reason"] = ""
	_box["ended"] = ""
	return true


func cancel_client_join_preparation() -> void:
	if is_active():
		return
	_preparing_client = false
	_box["snapshot"] = true


## True once a joiner's handshake has definitively failed (connection refused,
## or the peer torn down under it). Never true on a host or a solo process.
func handshake_failed() -> bool:
	return bool(_box.get("failed", false))


## A specific host refusal when one was delivered. Existing polling callers can
## keep using `handshake_failed()`; invite/join UI can present this text instead
## of waiting for or collapsing into the generic handshake timeout.
func handshake_failure_reason() -> String:
	return str(_box.get("failure_reason", ""))


## True only when the host delivered an admission verdict. Transport failures
## remain retryable under JoinDriver's existing retry_for_s budget.
func handshake_rejected_by_host() -> bool:
	return bool(_box.get("host_rejected", false))


## Leave, whichever end this is.
##
## Host (deliverable 4): save the world, tell everyone, let ENet flush, close.
## Client: save its own character, close. A client never writes the world --
## that is D100, and it is enforced at the four autosave sites through
## `Game.is_host()`, not by hoping a client never reaches one.
func leave(reason: String = "left") -> void:
	if not is_active() or _closing_frames > 0:
		return
	if is_host():
		_save_world_here()
		if int(_registry.call("size")) > 1:
			# One round trip's worth of frames so the reliable `session_ended`
			# packet actually leaves before the socket closes under it. Counted
			# down in `_process`; see `_closing_frames`.
			rpc("_rpc_session_ended", reason)
			_closing_reason = reason
			_closing_frames = CLOSE_FLUSH_FRAMES
			_closing_deadline_ms = Time.get_ticks_msec() + int(
				1000.0 * float(_cfg("host_close_linger_s", HOST_CLOSE_LINGER_S)))
			return
	else:
		_save_character_here()
		# The goodbye is sent into the transport now; the transport alone then
		# waits for the host while the session ends below, synchronously.
		_teardown(_say_goodbye())
		session_ended.emit(reason)
		return
	_teardown()
	session_ended.emit(reason)


## Host-only. Drops one peer; the registry replicates without it.
func kick(peer_id: int) -> bool:
	if not is_active() or not is_host() or peer_id == HOST_PEER_ID:
		return false
	if not bool(_registry.call("has", peer_id)):
		return false
	rpc_id(peer_id, "_rpc_session_ended", "kicked")
	_linger_then_disconnect(peer_id)
	_registry.call("remove", peer_id)
	_broadcast_registry()
	peer_left.emit(peer_id)
	if _realms != null:
		_realms.call("reconcile")
	return true


## Not a client. True for solo and for a process with no session at all -- see
## this file's header for why that, and not `multiplayer.is_server()`, is what
## the D100 autosave sites ask.
func is_host() -> bool:
	return _mode != "client" and not _preparing_client


## Why the last session ended ("host_gone" when the host link dropped without
## the host's own reason, else the reason the host or this peer gave). Empty
## while a session is live or before the first one; a new session clears it.
func end_reason() -> String:
	return str(_box.get("ended", ""))


func is_active() -> bool:
	return _mode != ""


## True once there is somebody else in the session -- what D97's interim
## `enter_realm()` refusal and D105's sleep vote both key off.
func is_multi_peer() -> bool:
	return peer_count() > 1


# --- realms (Wave 6 lane 6.A) ----------------------------------------------------

## The host's shell manager, `/root/Game/Session/Realms`. Never null after
## `_ready()`; a caller still checks, because a `Session` reached through
## `Object.call()` before its first frame is a real state.
func realms() -> Node:
	return _realms


## Which realm a peer is standing in, from the replicated registry. THE answer
## to that question for anybody but the local player -- D97 is explicit that
## nothing authoritative reads `Game.current_realm`, and from this lane on
## that global is only ever true of this process.
func realm_of(peer_id: int) -> String:
	if not is_active():
		return _local_realm() if peer_id == local_peer_id() else ""
	var row: Dictionary = _registry.call("row", peer_id)
	return str(row.get("realm", ""))


## Every peer standing in `realm`, ordered by peer id.
func peers_in_realm(realm: String) -> Array:
	var out: Array = []
	for entry: Variant in peers():
		if entry is Dictionary and str((entry as Dictionary).get("realm", "")) == realm:
			out.append(int((entry as Dictionary).get("peer_id", 0)))
	return out


## Every realm somebody is standing in right now, ordered. What
## `realm_shells.gd` reconciles against.
func occupied_realms() -> Array:
	var seen: Dictionary = {}
	for entry: Variant in peers():
		if entry is Dictionary:
			var realm := str((entry as Dictionary).get("realm", ""))
			if not realm.is_empty():
				seen[realm] = true
	var out: Array = seen.keys()
	out.sort()
	return out


## Directive rule 16, this end of it. `game_state.gd::enter_realm()` calls this
## BEFORE it swaps the scene, and that ordering is the deliverable: the host
## takes this peer's body out of the realm it is leaving while the peer is
## still standing in it, so nobody is left drawing a trainer who has gone.
##
## Solo and session-less: nothing to tell anybody, and no shells to keep, so
## this is a no-op and a crossing is exactly what it always was.
func announce_realm(from_realm: String, to_realm: String) -> void:
	if not is_active() or from_realm == to_realm:
		return
	if realm_transition != null and bool(realm_transition.call("owns_announcement", from_realm, to_realm)):
		return
	if is_host():
		_apply_realm_change(HOST_PEER_ID, from_realm, to_realm)
		return
	# Compatibility for announcements outside Game's controlled client travel.
	# Game.enter_realm is asynchronous; its coordinator owns the actual drain
	# and membership commit when a client transition is active.
	rpc_id(HOST_PEER_ID, "_rpc_realm_changed", from_realm, to_realm)


## Client -> host, ledger channel. Reliable: a lost realm change would leave
## the host simulating the wrong world for this peer indefinitely.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_realm_changed(from_realm: String, to_realm: String) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not bool(_registry.call("has", sender)):
		return
	# The host trusts the peer about where IT is standing and nothing else:
	# `from_realm` is taken from the registry, not from the packet, so a peer
	# cannot claim to have left a realm it was never in.
	_apply_realm_change(sender, str(_registry.call("row", sender).get("realm", "")), to_realm)


## The one place a realm change lands, whoever moved. Registry first (it is
## what `realm_shells.gd` and the per-realm spawners read), then the
## replication, then the shells, then the signal.
func _apply_realm_change(peer_id: int, from_realm: String, to_realm: String) -> void:
	if from_realm == to_realm:
		return
	_registry.call("set_realm", peer_id, to_realm)
	# BEFORE the shells reconcile. `trainer_spawn.gd` listens for this and
	# withdraws the moving peer's body from the realm it has left. Coordinated
	# client departures may keep the old host node invisibly as a cache target
	# until destination readiness, then reconcile it normally.
	peer_realm_changed.emit(peer_id, from_realm, to_realm)
	_broadcast_registry()
	if _realms != null:
		_realms.call("reconcile")


## Called by RealmTransition only after the mover has built and acknowledged
## its destination receiver. This is deliberately local to the host: its
## authoritative spawners own the old body and replicate the eventual free.
func settle_realm_departure(peer_id: int, from_realm: String, to_realm: String) -> void:
	if not is_active() or not is_host():
		return
	peer_realm_departure_settled.emit(peer_id, from_realm, to_realm)


## Peers in the session. 1 when solo or session-less: the local player is
## always one peer, and a caller dividing by this must never get zero.
func peer_count() -> int:
	if not is_active():
		return 1
	return maxi(1, int(_registry.call("size")))


## Seats the host is holding for players inside the reconnect window
## (`reconnect_window_s`). Admission already counts them; the Players tab and
## the Steam invite need to as well, or they offer a seat nobody can take.
## Always 0 on a client, which keeps no reservations.
func held_seat_count() -> int:
	if not is_active() or not is_host():
		return 0
	return int(_registry.call("reservation_count"))


func peers() -> Array:
	if not is_active():
		return [PEER_REGISTRY.make_row(HOST_PEER_ID, _local_character_id(),
			_local_display_name(), _local_realm(), _local_appearance_id())]
	return _registry.call("rows")


func registry() -> RefCounted:
	return _registry


func registry_fingerprint() -> int:
	return int(_registry.call("fingerprint"))


func local_peer_id() -> int:
	if not is_active():
		return HOST_PEER_ID
	return multiplayer.get_unique_id()


## Deliverable 3's gate: false on a joiner that has not yet applied the host's
## world. Always true on a host and on a session-less process.
func snapshot_ready() -> bool:
	return bool(_box.get("snapshot", true))


## Unlike `snapshot_ready()`, this remains false after a failed join tears its
## socket down and the session-less process becomes safe to act again. Tests and
## admission UI can therefore distinguish an explicit pre-snapshot refusal from
## a successful handshake followed by a later disconnect.
func handshake_snapshot_applied() -> bool:
	return bool(_box.get("handshake_snapshot_applied", false))


func mode() -> String:
	return _mode


# --- handshake ----------------------------------------------------------------

## Client -> host, ledger channel. The joiner's character summary.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_hello(summary: Dictionary) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	# The first refusal owns this transport peer until its queued reason flushes.
	# Ignore repeated hellos without resetting that deadline: otherwise a sender
	# could be admitted during the short flush window and then disconnected when
	# the old rejection timer expires.
	if _rejected_disconnect_frames.has(sender):
		return
	if _closing_frames > 0:
		# The host is saving and closing; nothing admitted now would ever hear
		# `session_ended`.
		_reject_hello(sender, "host_closing", "The host is closing this world.")
		return
	if _transport_kind == "steam":
		var game := _game()
		var lobby := game.get_node_or_null(^"SteamLobby") if game != null else null
		var reason := "The friends lobby is unavailable."
		if lobby != null and lobby.has_method("admission_error"):
			reason = str(lobby.call("admission_error", sender, summary))
		if not reason.is_empty():
			var code := "incompatible_version" \
				if reason == STEAM_PROTOCOL_REFUSAL else "steam_lobby_refused"
			_reject_hello(sender, code, reason)
			return
	# Build/content compatibility precedes identity and capacity, so a
	# mismatched joiner hears the specific reason even when the session is
	# full, and nothing about this world is prepared for it.
	var compat: Dictionary = BUILD_FINGERPRINT.compare(
		BUILD_FINGERPRINT.current(), summary.get("build", null))
	if not bool(compat.get("ok", false)):
		_reject_hello(sender, str(compat.get("code", "incompatible_version")),
			str(compat.get("reason", "")))
		return
	var raw_character_id: Variant = summary.get("character_id", null)
	var verdict: Dictionary = _registry.call(
		"admission_verdict", sender, raw_character_id, _capacity if _capacity > 0 else max_peers())
	if not bool(verdict.get("ok", false)):
		_reject_hello(sender, str(verdict.get("code", "host_refused")),
			str(verdict.get("reason", "The host refused this connection.")))
		return
	var character_id: String = raw_character_id
	if not _bind_character_authority():
		_reject_hello(sender, "world_not_ready", "The host world is not ready to admit this character.")
		return
	var portable: Variant = summary.get("portable_authority")
	var authority_errors := CHARACTER_AUTHORITY.errors(portable, character_id)
	if not CHARACTER_AUTHORITY.personal_flags_valid(summary.get("personal_flags", {"flags": []})): authority_errors.append("Invalid portable personal flags")
	if _groom_service().call("admission_valid", summary.get("discovered_landmarks"), true) != true: authority_errors.append("Invalid portable landmark identities")
	if not authority_errors.is_empty():
		_reject_hello(sender, "invalid_character", "That portable character could not be admitted. Your files remain unchanged.")
		return
	if bool(_registry.call("has_reservation", character_id)):
		_reserved_rejoins[sender] = true
	var display_name := str(summary.get("display_name", ""))
	var realm := str(summary.get("realm", "meadows"))
	var appearance_id := str(summary.get("appearance_id", "trainer"))
	var added: Dictionary = _registry.call(
		"add", sender, character_id, display_name, realm, appearance_id)
	if added.is_empty():
		# Defence in depth if registry state changes between the verdict and add.
		_reject_hello(sender, "character_in_use",
			"That character is already connected to this world.")
		return
	var held_snapshot: Dictionary = _character_authority.call("snapshot_record", character_id)
	var rejoin_applied: Array = []
	var seeded: Dictionary = _character_authority.call("seed_admitted_character", portable, character_id)
	var payout_lists := rejoin_payout_lists(summary)
	if seeded.get("ok") == true and seeded.get("already_seeded") != true:
		_character_authority.call("seed_absorbed_deliveries", character_id, _game().get("world").reward_deliveries, payout_lists.get("owed", []))
	elif seeded.get("ok") == true:
		# A returning owner (owner ruling 2026-10-05): its declaration is
		# adopted unless it is behind this world's record, which then wins and
		# the owner adopts it through the owner-passive readmit
		# (character_authority.rejoin_admission).
		var rejoin := rejoin_admission_for(character_id, portable, summary, payout_lists)
		rejoin_applied = rejoin.get("applied", [])
		if rejoin.get("code") != "held":
			print("[session] rejoin of %s: %s %s" % [character_id.left(18), str(rejoin.get("code", "")), str(rejoin.get("detail", ""))])
	if seeded.get("ok") == true and _character_authority.call("seed_personal_flags", character_id, summary.get("personal_flags", {"flags": []})) != true: seeded = {"ok": false}
	if seeded.get("ok") == true and _character_authority.call("seed_discovered_landmarks", character_id, summary.get("discovered_landmarks", {})) != true: seeded = {"ok": false}
	if bool(seeded.get("ok", false)):
		seeded = _character_authority.call("recover_durable_vitals", character_id, _game().get("world").reward_deliveries)
	if bool(seeded.get("ok", false)):
		seeded = _character_authority.call("recover_durable_training", character_id, _game().get("world").reward_deliveries)
	if not bool(seeded.get("ok", false)):
		# A refused hello leaves this world's record exactly as it was (review H1).
		if not held_snapshot.is_empty(): _character_authority.call("restore_record", character_id, held_snapshot)
		last_rejoin_admission.erase(character_id) # never a stale code for a later stream (review L5)
		_registry.call("remove", sender)
		_reject_hello(sender, "invalid_character", "That portable character could not be admitted. Your files remain unchanged.")
		return
	credit_rejoin_gathers(character_id, rejoin_applied)
	_groom_service().call("admitted", character_id, _character_authority.call("discovered_landmarks", character_id))
	_owner_passive_service().call("admitted", sender, summary)
	if realm_transition != null and bool(realm_transition.call("prepare_joined_sender", sender)):
		return
	_finish_peer_hello(sender)


func _reject_hello(sender: int, code: String, reason: String) -> void:
	# Reliable and on the ledger channel, matching every other terminal session
	# reason. Keep the peer alive for the same measured frame flush used by a
	# coordinated host close; an immediate disconnect can drop the queued reason.
	rpc_id(sender, "_rpc_admission_rejected", code, reason)
	_linger_then_disconnect(sender)
	print("[session] refused peer %d (%s): %s" % [sender, code, reason])


## Host -> one unadmitted joiner. No character/world save occurs: a failed
## handshake must not create or overwrite durable state.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_admission_rejected(code: String, reason: String) -> void:
	if is_host():
		return
	_box["failed"] = true
	_box["host_rejected"] = true
	_box["failure_reason"] = reason
	_box["ended"] = code
	_teardown()
	session_ended.emit(code)


func _finish_peer_hello(sender: int) -> void:
	if not is_host() or not bool(_registry.call("has", sender)):
		return
	if _snapshot_sends.has(sender):
		# A repeated hello cannot replace the immutable baseline or reset the
		# acknowledgement cursor of the transfer already serving this peer.
		return
	var row: Dictionary = _registry.call("row", sender)
	rpc_id(sender, "_rpc_altar_epoch", _altar_epoch, str(_game().get("world").reward_delivery_namespace), str(row.get("character_id", "")))
	var character_id := str(row.get("character_id", ""))
	var display_name := str(row.get("display_name", ""))
	var realm := str(row.get("realm", ""))
	print("[session] peer %d joined as '%s' (%s) in %s" % [sender, display_name, character_id, realm])
	# Capture one immutable baseline before BEGIN. Registry and later ledger
	# deltas share BEGIN's reliable channel; chunks use the independent snapshot
	# channel and cannot broaden that boundary through cross-channel assumptions.
	var snapshot := _world_snapshot().duplicate(true)
	if not _start_snapshot_send(sender, snapshot):
		return
	_broadcast_registry()
	peer_joined.emit(sender, character_id)
	arm_legacy_home_key_check(sender)
	# The joiner may be arriving into a realm this process is not standing in
	# (a rejoin carries the character's last realm forward, `peer_registry
	# .gd::add`). Standing its shell up is this call, not a special case.
	if _realms != null:
		_realms.call("reconcile")


func _start_snapshot_send(peer_id: int, snapshot: Dictionary) -> bool:
	var transfer_id := _next_snapshot_transfer_id
	_next_snapshot_transfer_id += 1
	if _next_snapshot_transfer_id <= 0:
		_next_snapshot_transfer_id = 1
	var codec: RefCounted = SNAPSHOT_TRANSFER.new()
	var encoded: Dictionary = codec.call("encode_snapshot", snapshot, transfer_id)
	if not bool(encoded.get("ok", false)):
		_abort_host_snapshot(peer_id, str(encoded.get("error", "World snapshot could not be encoded.")))
		return false
	_snapshot_sends[peer_id] = {
		"transfer_id": transfer_id,
		"chunks": encoded.get("chunks", []),
		"next_index": 0,
		"awaiting_index": -1,
		"deadline_ms": Time.get_ticks_msec() \
			+ int(float(_cfg("handshake_timeout_s", 60.0)) * 1000.0),
	}
	var begin_error := rpc_id(peer_id, "_rpc_snapshot_begin", encoded.get("descriptor", {}))
	if begin_error != OK:
		_abort_host_snapshot(peer_id, "The host could not send the world snapshot descriptor.")
		return false
	return _send_next_snapshot_chunk(peer_id)


func _send_next_snapshot_chunk(peer_id: int) -> bool:
	if not _snapshot_sends.has(peer_id):
		return false
	var state: Dictionary = _snapshot_sends[peer_id]
	if int(state.get("awaiting_index", -1)) >= 0:
		return true
	var chunks: Array = state.get("chunks", [])
	var index := int(state.get("next_index", 0))
	if index >= chunks.size():
		_snapshot_sends.erase(peer_id)
		return true
	state["awaiting_index"] = index
	_snapshot_sends[peer_id] = state
	var send_error := rpc_id(peer_id, "_rpc_snapshot_chunk",
		int(state.get("transfer_id", 0)), index, chunks[index])
	if send_error != OK:
		_abort_host_snapshot(peer_id, "The host could not send the world snapshot data.")
		return false
	return true


@rpc("any_peer", "call_remote", "reliable", CHANNEL_SNAPSHOT)
func _rpc_snapshot_chunk_ack(transfer_id: int, index: int) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not _snapshot_sends.has(sender):
		return
	var state: Dictionary = _snapshot_sends[sender]
	if transfer_id != int(state.get("transfer_id", 0)) \
			or index != int(state.get("awaiting_index", -1)):
		_abort_host_snapshot(sender, "The world snapshot acknowledgement was invalid.")
		return
	state["awaiting_index"] = -1
	state["next_index"] = index + 1
	_snapshot_sends[sender] = state
	_send_next_snapshot_chunk(sender)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_snapshot_begin(descriptor: Dictionary) -> void:
	_receive_snapshot_begin(descriptor, true)


func _receive_snapshot_begin(descriptor: Dictionary, send_ack: bool) -> bool:
	if is_host() or _bootstrap_boundary:
		return false
	if not bool(_snapshot_receive.call("begin", descriptor)):
		_fail_snapshot_receive(str(_snapshot_receive.call("last_error")), send_ack)
		return false
	_snapshot_receive_id = int(descriptor.get("transfer_id", 0))
	_bootstrap_boundary = true
	if _early_snapshot_chunk.is_empty():
		return true
	var early := _early_snapshot_chunk
	_early_snapshot_chunk = {}
	return _receive_snapshot_chunk(int(early.get("transfer_id", 0)),
		int(early.get("index", -1)), early.get("bytes", PackedByteArray()), send_ack)


@rpc("authority", "call_remote", "reliable", CHANNEL_SNAPSHOT)
func _rpc_snapshot_chunk(transfer_id: int, index: int, bytes: PackedByteArray) -> void:
	_receive_snapshot_chunk(transfer_id, index, bytes, true)


func _receive_snapshot_chunk(transfer_id: int, index: int, bytes: PackedByteArray,
		send_ack: bool) -> bool:
	if is_host():
		return false
	if not _bootstrap_boundary:
		if transfer_id <= 0 or index != 0 or bytes.is_empty() \
				or bytes.size() > SNAPSHOT_TRANSFER.DEFAULT_CHUNK_BYTES:
			_fail_snapshot_receive("World snapshot data arrived before a valid descriptor.", send_ack)
			return false
		if not _early_snapshot_chunk.is_empty():
			var same := transfer_id == int(_early_snapshot_chunk.get("transfer_id", 0)) \
				and index == int(_early_snapshot_chunk.get("index", -1)) \
				and bytes == (_early_snapshot_chunk.get("bytes", PackedByteArray()) as PackedByteArray)
			if not same:
				_fail_snapshot_receive("Conflicting world snapshot data arrived before its descriptor.", send_ack)
			return same
		_early_snapshot_chunk = {
			"transfer_id": transfer_id,
			"index": index,
			"bytes": bytes.duplicate(),
		}
		return true
	if not bool(_snapshot_receive.call("accept_chunk", transfer_id, index, bytes)):
		_fail_snapshot_receive(str(_snapshot_receive.call("last_error")), send_ack)
		return false
	if bool(_snapshot_receive.call("is_ready")):
		if send_ack:
			_pending_snapshot_ack = {"transfer_id": transfer_id, "index": index}
		return _finalize_snapshot_receive()
	if send_ack and not _send_snapshot_ack(transfer_id, index):
		return false
	return true


func _send_snapshot_ack(transfer_id: int, index: int) -> bool:
	if _peer == null:
		return false
	var send_error := rpc_id(HOST_PEER_ID, "_rpc_snapshot_chunk_ack", transfer_id, index)
	if send_error == OK:
		return true
	_fail_snapshot_receive("The world snapshot acknowledgement could not be sent.", false)
	return false


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_snapshot_abort(transfer_id: int, reason: String) -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	var state: Dictionary = _snapshot_sends.get(sender, {})
	if int(state.get("transfer_id", 0)) == transfer_id:
		_abort_host_snapshot(sender, reason, false)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_snapshot_failed(reason: String) -> void:
	if not is_host():
		_fail_snapshot_receive(reason, false)


func _abort_host_snapshot(peer_id: int, reason: String, notify: bool = true) -> void:
	_snapshot_sends.erase(peer_id)
	if notify and _peer != null:
		rpc_id(peer_id, "_rpc_snapshot_failed", reason)
	if bool(_registry.call("remove", peer_id)):
		_broadcast_registry()
		peer_left.emit(peer_id)
		if _realms != null:
			_realms.call("reconcile")
	_linger_then_disconnect(peer_id)
	push_warning("[session] snapshot for peer %d failed: %s" % [peer_id, reason])


func _fail_snapshot_receive(reason: String, notify_host: bool) -> void:
	var message := reason.strip_edges()
	if message.is_empty():
		message = "The world snapshot could not be verified."
	var transfer_id := _snapshot_receive_id
	_box["failed"] = true
	_box["failure_reason"] = message
	_box["ended"] = "snapshot_failed"
	if notify_host and _peer != null and transfer_id > 0:
		rpc_id(HOST_PEER_ID, "_rpc_snapshot_abort", transfer_id, message)
	_clear_snapshot_bootstrap()
	if _peer != null:
		_teardown()


func _finalize_snapshot_receive() -> bool:
	# BEGIN and registry are ordered on the ledger channel, but the independent
	# snapshot channel may finish first. Readiness waits for both boundaries.
	if not bool(_snapshot_receive.call("is_ready")) or not _bootstrap_registry_received:
		return true
	var data: Dictionary = _snapshot_receive.call("snapshot")
	var game := _game()
	if game == null or not game.has_method("apply_world_snapshot"):
		_fail_snapshot_receive("The received world snapshot could not be applied.", true)
		return false
	# Reject the whole bootstrap before any world, registry or queued-delta
	# mutation. WorldState's void loader refusal must never be acknowledged.
	var redesign_errors := REDESIGN_STATE.validate("world",
		data.get("redesign_world", REDESIGN_STATE.defaults("world")), [], str(data.get("reward_delivery_namespace", "")))
	redesign_errors.append_array(TRAINING_WORLD.foundation_world_errors(data.get("reward_deliveries", {}), str(data.get("reward_delivery_namespace", "")), str(data.get("world_id", "")), data.get("placed_buildings", [])))
	redesign_errors.append_array(preload("res://scripts/net/actor_vitals_delivery.gd").world_errors(
		data.get("reward_deliveries", {}), str(data.get("reward_delivery_namespace", "")), str(data.get("world_id", ""))))
	redesign_errors.append_array(TRAINING_WORLD.training_world_errors(data.get("reward_deliveries", {}), str(data.get("reward_delivery_namespace", "")), str(data.get("world_id", "")), data.get("placed_buildings", [])))
	if not redesign_errors.is_empty():
		_fail_snapshot_receive("The received world snapshot contains invalid redesign data.", true)
		return false
	var ledger_rpc := get_node_or_null(^"LedgerRpc")
	if not _bootstrap_deltas.is_empty() \
			and (ledger_rpc == null or not ledger_rpc.has_method("apply_remote_delta")):
		_fail_snapshot_receive("Queued world changes could not be applied after the snapshot.", true)
		return false
	game.call("apply_world_snapshot", data)
	_sync_tether_tonic_scope()
	if not _latest_bootstrap_registry.is_empty():
		_apply_registry(_latest_bootstrap_registry)
	for delta: Dictionary in _bootstrap_deltas:
		ledger_rpc.call("apply_remote_delta", delta)
	if preload("res://scripts/net/actor_vitals_delivery.gd").has_pending_owner(game.get("world").reward_deliveries, _local_character_id()) \
			and (ledger_rpc == null or not ledger_rpc.has_method("reconcile_actor_vitals_before_ready") \
			or not bool(ledger_rpc.call("reconcile_actor_vitals_before_ready"))):
		_fail_snapshot_receive("Your accepted vitality receipt could not be saved. It remains recoverable on the host.", true)
		return false
	var training_ready: Variant = ledger_rpc.call("reconcile_creature_training_before_ready") \
		if ledger_rpc != null and ledger_rpc.has_method("reconcile_creature_training_before_ready") else null
	if not training_ready is bool or not training_ready:
		_training_bootstrap_waiting = true
		return true # Existing bootstrap stays closed; exact saved decision resumes it.
	_training_bootstrap_waiting = false
	_box["snapshot"] = true
	_box["handshake_snapshot_applied"] = true
	_groom_service().call("begin_resume")
	print("[session] snapshot applied (%d keys, day %d)" % [data.size(), int(data.get("day", 1))])
	var pending_ack := _pending_snapshot_ack.duplicate()
	_clear_snapshot_bootstrap()
	snapshot_applied.emit()
	if not pending_ack.is_empty() and not _send_snapshot_ack(
			int(pending_ack.get("transfer_id", 0)), int(pending_ack.get("index", -1))):
		return false
	return true


## Called by LedgerRpc. True means the delta is owned by this bootstrap queue
## and must not be applied by the ordinary receiver path.
func queue_bootstrap_delta(delta: Dictionary) -> bool:
	if not _bootstrap_boundary or bool(_box.get("snapshot", false)):
		return false
	var encoded := var_to_bytes(delta)
	var next_count := _bootstrap_deltas.size() + 1
	var next_bytes := _bootstrap_delta_bytes + encoded.size()
	if encoded.is_empty() \
			or next_count > int(_cfg("snapshot_delta_queue_max_entries", 4096)) \
			or next_bytes > int(_cfg("snapshot_delta_queue_max_bytes", 8 * 1024 * 1024)):
		_fail_snapshot_receive(
			"Too many world changes arrived while the initial snapshot was loading.", true)
		return true
	_bootstrap_deltas.append(delta.duplicate(true))
	_bootstrap_delta_bytes = next_bytes
	return true


func _clear_snapshot_bootstrap() -> void:
	_snapshot_receive.call("reset")
	_snapshot_receive_id = 0
	_early_snapshot_chunk = {}
	_bootstrap_boundary = false
	_bootstrap_deltas.clear()
	_bootstrap_delta_bytes = 0
	_latest_bootstrap_registry = {}
	_bootstrap_registry_received = false
	_pending_snapshot_ack = {}


## Host -> everyone, ledger channel. The registry, whole (peer_registry.gd's
## header explains why whole and not a delta).
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_registry(payload: Dictionary) -> void:
	if not is_host() and _bootstrap_boundary and not bool(_box.get("snapshot", false)):
		_latest_bootstrap_registry = payload.duplicate(true)
		_bootstrap_registry_received = true
		if bool(_snapshot_receive.call("is_ready")):
			_finalize_snapshot_receive()
		return
	_apply_registry(payload)


func _apply_registry(payload: Dictionary) -> void:
	# The realms BEFORE the load, so a client can tell which peers actually
	# moved. Without this a client learns of a realm change only as a body
	# that stopped updating: `peer_realm_changed` is what its own world scene
	# reconciles what it draws against, and only the host reaches
	# `_apply_realm_change()`.
	var before: Dictionary = {}
	for entry: Variant in (_registry.call("rows") as Array):
		if entry is Dictionary:
			before[int((entry as Dictionary).get("peer_id", 0))] = str((entry as Dictionary).get("realm", ""))
	_registry.call("load_data", payload)
	for entry: Variant in (_registry.call("rows") as Array):
		if not (entry is Dictionary):
			continue
		var row: Dictionary = entry
		var id := int(row.get("peer_id", 0))
		if not before.has(id):
			continue
		var was := str(before[id])
		var now := str(row.get("realm", ""))
		if was != now:
			peer_realm_changed.emit(id, was, now)


## Host -> everyone, ledger channel. D105: `day` and `clock_elapsed_seconds` are
## host truth. The client writes them into its own `WorldState` and resumes its
## live sky from the replicated number; `Game.advance_day()` refuses on a client
## so the local `world_look.gd` day-roll accumulator can never move the day.
@rpc("authority", "call_remote", "unreliable_ordered", CHANNEL_LEDGER)
func _rpc_clock(day: int, elapsed: float) -> void:
	var game := _game()
	if game == null or is_host() or _bootstrap_boundary:
		return
	game.call("apply_host_clock", day, elapsed)


## Same global transport as the day clock: it exists while a client changes
## realms, before the destination's weather node can receive scene RPCs.
@rpc("authority", "call_remote", "unreliable_ordered", CHANNEL_LEDGER)
func _rpc_realm_environment(state: Dictionary) -> void:
	var game := _game()
	if game != null and not is_host() and not _bootstrap_boundary:
		game.set("realm_environment", state)


## Hazard decisions originate in the host's realm simulation. The transport is
## global because a client and host may be standing in different world scenes.
func publish_stormwood_strike(event: Dictionary) -> void:
	if not is_host():
		return
	stormwood_strike_received.emit(event.duplicate(true))
	if is_active():
		rpc("_rpc_stormwood_strike", event)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_stormwood_strike(event: Dictionary) -> void:
	if not is_host():
		stormwood_strike_received.emit(event.duplicate(true))


func request_stormwood_arch_travel(arch_id: String) -> void:
	if is_host():
		_dispatch_stormwood_arch(local_peer_id(), arch_id)
	elif is_active():
		rpc_id(HOST_PEER_ID, "_rpc_stormwood_arch_request", arch_id)


func request_stormwood_encounter(intent: Dictionary) -> void:
	var completing := str(intent.get("kind", "")) in ["disengage", "finalized_death_withdrawal"]
	if not _stormwood_transition_allowed(HOST_PEER_ID, completing):
		return
	if is_host():
		_dispatch_stormwood_encounter(local_peer_id(), intent)
	elif is_active():
		rpc_id(HOST_PEER_ID, "_rpc_stormwood_encounter_request", intent)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_stormwood_encounter_request(intent: Dictionary) -> void:
	if is_host():
		_dispatch_stormwood_encounter(multiplayer.get_remote_sender_id(), intent)


func _dispatch_stormwood_encounter(peer: int, intent: Dictionary) -> void:
	if realm_of(peer) != "stormwood":
		return
	# Requests sent before the sender installs closure must still run before
	# its ledger fence. Receiver gating permits those through requests_closed.
	if not _stormwood_transition_allowed(peer, true):
		return
	var hub := get_tree().get_first_node_in_group("stormwood_encounter_hub")
	if hub != null:
		hub.dispatch(peer, intent)


func send_stormwood_encounter(peer: int, event: Dictionary) -> void:
	if not is_host():
		return
	if not _stormwood_transition_allowed(peer, true):
		return
	if peer == local_peer_id():
		stormwood_encounter_message.emit(event.duplicate(true))
	elif is_active() and realm_of(peer) == "stormwood":
		rpc_id(peer, "_rpc_stormwood_encounter_message", event)


func _stormwood_transition_allowed(peer: int, completing: bool) -> bool:
	return realm_transition == null or bool(realm_transition.call(
		"scene_rpc_allowed", "stormwood", peer, completing))


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_stormwood_encounter_message(event: Dictionary) -> void:
	if not is_host():
		stormwood_encounter_message.emit(event)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_stormwood_arch_request(arch_id: String) -> void:
	if is_host():
		_dispatch_stormwood_arch(multiplayer.get_remote_sender_id(), arch_id)


func _dispatch_stormwood_arch(peer_id: int, arch_id: String) -> void:
	if realm_of(peer_id) != "stormwood":
		return
	var runtime := get_tree().get_first_node_in_group("stormwood_arch_runtime")
	if runtime == null:
		return
	var verdict: Dictionary = runtime.travel_for_peer(peer_id, arch_id)
	if peer_id == local_peer_id():
		stormwood_arch_arrival.emit(verdict)
	elif is_active():
		rpc_id(peer_id, "_rpc_stormwood_arch_arrival", verdict)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_stormwood_arch_arrival(event: Dictionary) -> void:
	if not is_host():
		stormwood_arch_arrival.emit(event)


## Client -> host. Best effort: a deliberate leave frees the seat at once.
@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_goodbye() -> void:
	if not is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	if bool(_registry.call("has", sender)):
		_departing_peers[sender] = true
		# Retire existing scene senders while this endpoint still has channels.
		# ENet removes it only on a later poll; cached Sync visibility must not
		# keep targeting the disconnecting endpoint in that interval.
		if realm_transition != null:
			realm_transition.call("_refresh_scopes")
		# Close from this side, after the goodbye has been read, so the
		# leaving client's disconnect cannot discard it. See GOODBYE_LINGER_S.
		if _peer != null:
			_peer.disconnect_peer(sender)


## The existing goodbye lifetime, read by the scene replication coordinator.
## It is not an admission, world-readiness or held-seat decision.
func peer_is_departing(peer_id: int) -> bool:
	return bool(_departing_peers.get(peer_id, false))


## Returns whether a goodbye went out. The caller then tears the session down
## at once and leaves only the old transport polling (`_lingering_peer`) until
## the host closes it. A goodbye that is lost anyway only means the seat is
## held for the reconnect window.
func _say_goodbye() -> bool:
	# Only an admitted client holds a seat worth freeing. A failed or
	# unfinished join tears down at once, so the title can host or join again
	# without waiting on a goodbye nobody will answer.
	if _peer == null or not is_inside_tree() or multiplayer.multiplayer_peer != _peer \
			or not bool(_box.get("connected", false)) \
			or not bool(_box.get("handshake_snapshot_applied", false)):
		return false
	rpc_id(HOST_PEER_ID, "_rpc_goodbye")
	return true


## Host -> everyone (or one kicked peer), ledger channel.
@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_session_ended(reason: String) -> void:
	if is_host():
		return
	_box["ended"] = reason
	_save_character_here()
	_teardown()
	session_ended.emit(reason)
	_return_to_title(reason)


# --- transport callbacks --------------------------------------------------------

func _on_peer_connected(peer_id: int) -> void:
	_configure_transport_timeout(peer_id)
	# Nothing to do until the joiner says hello: the registry row is built from
	# the character summary, not from an id arriving on its own.
	print("[session] transport: peer %d connected" % peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	_rejected_disconnect_frames.erase(peer_id)
	# A joiner whose world snapshot was never acknowledged never played here;
	# it gets no held seat (it can still rejoin like anyone else).
	# A character that came back through its own held seat keeps it even if a
	# flaky link drops it again mid-snapshot -- the case the seat exists for.
	var mid_snapshot := _snapshot_sends.has(peer_id) and not _reserved_rejoins.has(peer_id)
	_snapshot_sends.erase(peer_id)
	_reserved_rejoins.erase(peer_id)
	var departed := bool(_departing_peers.get(peer_id, false)) or mid_snapshot
	_departing_peers.erase(peer_id)
	if realm_transition != null:
		realm_transition.call("peer_disconnected", peer_id)
	if not is_host():
		return
	var lost_character := str((_registry.call("row", peer_id) as Dictionary).get("character_id", ""))
	# Ruling (b): a departing guest's open gather batch is journaled now; its
	# rejoin's reward reconciliation applies it.
	var gather_writer := get_node_or_null(^"LedgerRpc")
	if gather_writer != null and not lost_character.is_empty(): gather_writer.call("flush_gather_batch", lost_character)
	if _groom_passive != null: _groom_passive.call("departed", lost_character)
	# The departed transport's owner-passive stream ends with it, so the
	# character's next stream is admitted instead of shadowed (re-proof).
	if _owner_passive != null: _owner_passive.call("peer_departed", peer_id)
	_cancel_unjournaled_departed_items(peer_id)
	if bool(_registry.call("remove", peer_id)):
		if not departed and _closing_frames == 0 and peer_id != HOST_PEER_ID:
			var window_ms := int(1000.0 * float(_cfg("reconnect_window_s", 120.0)))
			if window_ms > 0 and bool(_registry.call("reserve", lost_character,
					Time.get_ticks_msec() + window_ms)):
				print("[session] holding a seat for '%s' for %d s"
					% [lost_character, window_ms / 1000])
		_broadcast_registry()
		peer_left.emit(peer_id)
		print("[session] peer %d left; %d remain" % [peer_id, peer_count()])
		# Deliverable 5, and the case that sank D97's first design: the peer
		# who just vanished may have been the only one in its realm, and its
		# shell holds world state nothing else does. `reconcile()` tears that
		# shell down THROUGH the host's own world save, so a disconnect
		# mid-fight in an otherwise empty realm loses nothing.
		if _realms != null:
			_realms.call("reconcile")


func _on_connected_to_server() -> void:
	_configure_transport_timeout(HOST_PEER_ID)
	_box["connected"] = true


## ENet's stock 5 s minimum timeout is shorter than a legitimate procedural
## realm crossing. During a split-realm transition both processes can be busy:
## the client builds its destination while the host stands up the matching
## simulation shell. Each build yields frames and is bounded by Game's 120 s
## readiness deadline, but a reliable packet sent immediately before one of
## those builds can otherwise age past ENet's minimum and tear down a healthy
## session. Keep transport tolerance above Game's bounded 120 s loading window. The
## network smoke's independent 15 s heartbeat remains the freeze detector.
func _configure_transport_timeout(peer_id: int) -> void:
	if not transport_uses_enet_timeouts(_peer):
		return
	if not timeout_peer_is_physical(is_host(), peer_id):
		return
	var enet_peer := _peer as ENetMultiplayerPeer
	var transport_peer := enet_peer.get_peer(peer_id)
	if transport_peer == null:
		return
	transport_peer.set_timeout(
		int(_cfg("peer_timeout_limit", 32)),
		int(_cfg("peer_timeout_min_ms", 135_000)),
		int(_cfg("peer_timeout_max_ms", 180_000)))


static func timeout_peer_is_physical(hosting: bool, peer_id: int) -> bool:
	# ENet clients receive logical peer_connected events for fellow clients,
	# but their only physical remote connection is the server. get_peer() logs
	# an error for a relayed ID before its null result could be checked.
	return peer_id > 0 and (peer_id != HOST_PEER_ID if hosting else peer_id == HOST_PEER_ID)


func _on_connection_failed() -> void:
	_box["failed"] = true
	_teardown()


func _on_server_disconnected() -> void:
	# A host refusal tears down from its reason RPC. Ignore the later transport
	# edge rather than replacing that specific reason with `host_gone`.
	if _mode != "client":
		return
	if _box.get("ended", "") == "":
		_box["ended"] = "host_gone"
	_save_character_here()
	_teardown()
	session_ended.emit("host_gone")
	_return_to_title("host_gone")


# --- host clock (D105) -----------------------------------------------------------

func _process(delta: float) -> void:
	_bind_training_container_guards()
	if _groom_passive != null: _groom_passive.call("tick", delta)
	if _owner_passive != null: _owner_passive.call("tick", delta)
	_tick_legacy_home_keys(delta)
	# Building the host portal context re-projects and recovers the whole local
	# character record (~100 ms in Tidewake); cancel_invalid() can only act on a
	# frozen Home Key channel, so build it only while one is open.
	if portal_runtime_ready() and is_host() and _portal_policy.call("has_open_channels") == true:
		var portal_context := _host_portal_context(local_peer_id())
		if not portal_context.is_empty(): _portal_policy.call("cancel_invalid", portal_context)
	if _training_bootstrap_waiting:
		var training_transport := get_node_or_null(^"LedgerRpc")
		if training_transport != null and training_transport.has_method("reconcile_creature_training_before_ready"):
			training_transport.call("reconcile_creature_training_before_ready")
	_poll_lingering_peer()
	if _closing_frames > 0:
		if _closing_frames > 1:
			_closing_frames -= 1
			return
		if not _close_flushed():
			return
		_finish_closing()
		return
	_flush_rejected_peers()
	_expire_snapshot_sends()
	# A joiner sends its character summary the moment ENet reports the link up.
	# Done here rather than straight from `_on_connected_to_server` so the rpc
	# goes out on an ordinary frame with the peer fully installed.
	if _mode == "client" and not _pending_hello.is_empty() and bool(_box.get("connected", false)):
		var summary := _pending_hello
		_pending_hello = {}
		print("[session] connected as peer %d; sending hello" % multiplayer.get_unique_id())
		rpc_id(HOST_PEER_ID, "_rpc_hello", summary)
	if not is_active() or not is_host() or int(_registry.call("size")) <= 1:
		return
	_clock_accum += delta
	var interval := float(_cfg("clock_sync_interval_s", 1.0))
	if _clock_accum < interval:
		return
	_clock_accum = 0.0
	var game := _game()
	if game == null:
		return
	rpc("_rpc_clock", int(game.get("day")), float(game.get("clock_elapsed_seconds")))
	var environment: Variant = game.get("realm_environment")
	if environment is Dictionary:
		rpc("_rpc_realm_environment", environment)


## Hold one peer's link open until its terminal reason is delivered. See
## REFUSAL_LINGER_S.
func _linger_then_disconnect(peer_id: int) -> void:
	_rejected_disconnect_frames[peer_id] = {
		"frames": CLOSE_FLUSH_FRAMES,
		"deadline_ms": Time.get_ticks_msec() + int(
			1000.0 * float(_cfg("refusal_linger_s", REFUSAL_LINGER_S))),
	}


## Service a leaving client's detached transport until the host has closed it
## (so the goodbye was read) or the bound passes, then close it.
func _exit_tree() -> void:
	_close_lingering_peer()


## A new join closes a leaving transport that is still waiting on the host, so
## its disconnect reaches the host ahead of the new hello: a fast rejoin cannot
## collide with its own old registry row (`character_in_use`). If that loses
## the goodbye, the host holds the seat and the same character reclaims it.
func _close_lingering_peer() -> void:
	if _lingering_peer != null:
		_lingering_peer.close()
		_lingering_peer = null


func _poll_lingering_peer() -> void:
	if _lingering_peer == null:
		return
	_lingering_peer.poll()
	if _lingering_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED \
			and Time.get_ticks_msec() < _lingering_deadline_ms:
		return
	_lingering_peer.close()
	_lingering_peer = null


func _finish_closing() -> void:
	if _process_exit_in_flight:
		var checked := prepare_process_exit()
		if checked.get("ok") != true:
			# Keep the actual source and host authority alive for a retry. Peers
			# may already have left, but transport closure is not a save receipt.
			_process_exit_refusal = str(checked.reason)
			_closing_frames = 0
			_closing_deadline_ms = 0
			_closing_reason = ""
			return
	var reason := _closing_reason
	_closing_frames = 0
	_closing_deadline_ms = 0
	_closing_reason = ""
	_teardown()
	session_ended.emit(reason)


## The final frame of a host close waits here until every remote peer has
## closed its side, or the deadline passes, so a dead or silent client cannot
## hold the host open.
func _close_flushed() -> bool:
	if _peer == null or not is_inside_tree() or multiplayer.multiplayer_peer != _peer:
		return true
	if multiplayer.get_peers().is_empty():
		return true
	return Time.get_ticks_msec() >= _closing_deadline_ms


func _flush_rejected_peers() -> void:
	if _rejected_disconnect_frames.is_empty():
		return
	var now := Time.get_ticks_msec()
	for raw_peer: Variant in _rejected_disconnect_frames.keys():
		var peer_id := int(raw_peer)
		var state: Dictionary = _rejected_disconnect_frames[raw_peer]
		var frames := int(state.get("frames", 0)) - 1
		if frames > 0 or now < int(state.get("deadline_ms", 0)):
			state["frames"] = maxi(frames, 0)
			continue
		_rejected_disconnect_frames.erase(raw_peer)
		if _peer != null:
			_peer.disconnect_peer(peer_id)


func _expire_snapshot_sends() -> void:
	if _snapshot_sends.is_empty() or not is_active() or not is_host():
		return
	var now := Time.get_ticks_msec()
	for raw_peer: Variant in _snapshot_sends.keys():
		var peer_id := int(raw_peer)
		var state: Dictionary = _snapshot_sends.get(raw_peer, {})
		if now > int(state.get("deadline_ms", now + 1)):
			_abort_host_snapshot(peer_id,
				"The world snapshot transfer timed out before the client acknowledged it.")


# --- internals -------------------------------------------------------------------

func _broadcast_registry() -> void:
	if not is_host() or not is_active():
		return
	if _registry.call("size") > 1:
		rpc("_rpc_registry", _registry.call("save_data"))


func _world_snapshot() -> Dictionary:
	var game := _game()
	if game == null:
		return {}
	# Through `Game`, not straight off `Game.world`: the four scene-facing sync
	# seams (buildings, satchels, harvest, clock) have to run first or the
	# snapshot describes a world one build behind the one the host is standing
	# in.
	if game.has_method("world_snapshot"):
		return game.call("world_snapshot")
	return {}


## Deliverable 4/D100: the host, and only the host, writes the world.
func _save_world_here() -> void:
	var game := _game()
	if game == null:
		return
	game.call("save_game", int(game.call("autosave_slot")))


## Deliverable 4/D100's other half: every peer writes its own character.
##
## D100's autosave ownership at the one site that is not `Game.autosave_here()`:
## the host writes its world (through the slot save, which writes the split pair
## with it), and a client writes ONLY its own portable character file.
##
## Lane 1.C wrote the second half. Before it, this printed "no character file to
## write yet" and a client left a session having recorded nothing at all -- the
## fog it had walked off, the creatures it had levelled and the satchel it had
## filled all went with the process.
##
## `_capture_player_pose()` first, for the same reason `game_state.gd::save_game()`
## calls it before every slot write: a character file whose pose is wherever the
## trainer last happened to be captured drops them somewhere else on the next
## Continue, which is exactly the thing a portable character must not do.
func _save_character_here() -> void:
	var game := _game()
	if game == null:
		return
	if is_host():
		game.call("save_game", int(game.call("autosave_slot")))
		return
	if not client_character_save_ready():
		print("[session] client leave: handshake never applied a snapshot; portable character unchanged")
		return
	var save_system: Variant = game.get("save_system")
	if save_system == null:
		push_warning("[session] client leave: no Game.save_system to write a character with")
		return
	if game.has_method("_capture_player_pose"):
		game.call("_capture_player_pose")
	var character_id := _local_character_id()
	if bool((save_system as RefCounted).call("save_character", game, character_id)):
		print("[session] client leave: wrote character '%s' (no world file -- D100)" % character_id)
	else:
		push_warning("[session] client leave: could not write character '%s'" % character_id)


## A caller who joins AS a named character makes this process that character.
##
## FINDING this fixes, found by row 21: `join()` put the caller's
## `character_id` into `_pending_hello` and nowhere else, so the registry row,
## the world and the other peers all knew this peer as (say)
## `reconnect-smoke-character` while its own `PlayerState.character_id` stayed
## empty. `_local_character_id()` then MINTED a `peer-<pid>-<usec>` id on the way
## out, and `_save_character_here()` wrote the character file under THAT --
## a file the next join by the announced id could never find. The write and the
## read were addressing two different names for one trainer.
##
## Only ever a stamp, never a clear: an empty argument leaves whatever this
## process already had, so `join()` with no summary keeps minting exactly as it
## did.
func _adopt_character_id(wanted_id: String) -> void:
	if wanted_id.is_empty():
		return
	var game := _game()
	if game == null:
		return
	var local: Variant = game.get("local")
	if local == null:
		return
	(local as RefCounted).set("character_id", wanted_id)


## D100's portable half, on the way back IN, and the other half of
## `_save_character_here()` above. **§17 item 21.**
##
## `character_save.gd::apply()` was written by lane 1.C as "the entry point for
## the multiplayer paths that have a character id and no slot at all" and had no
## caller: every peer WROTE `user://characters/<id>/character.json` on the way
## out and nothing ever read one back, so a rejoiner arrived as whatever its
## process still happened to hold in memory. A peer whose process restarted --
## the case the file exists for -- arrived as a blank trainer.
##
## Called from `join()` rather than after the host's snapshot, for two reasons:
## the character half names no world (that is the whole point of the split, see
## `character_save.gd`'s header), so it does not need the world to exist yet;
## and the hello this peer is about to send carries its display name and realm,
## which have to be the RESTORED ones or the registry row advertises a trainer
## nobody is playing.
##
## `false`, never fatal, on every miss: no id, no save system, no file. Joining
## as a fresh trainer is the correct outcome for a character that has never been
## saved, which is every first join, and it must not be an error.
##
## **Only when the caller NAMED a character.** An empty `wanted_id` returns
## immediately and does not fall back to `_local_character_id()`, because the
## other caller on this tree is `scripts/mp/join_driver.gd`, which dials with no
## summary at all -- and `title_screen.gd::_begin_join()` has already loaded slot
## 0 by then. Restoring over the top of a slot the player just chose to continue
## would replace their party with whatever the character file last held, which is
## the one thing this must not do. When that screen grows the character picker its
## own comment promises, it will name an id and come through here.
##
## The HOST never comes through here at all: `host()` does not call it.
func _restore_character_here(wanted_id: String) -> bool:
	if wanted_id.is_empty():
		return false
	var game := _game()
	if game == null:
		return false
	var character_id := wanted_id
	var save_system: Variant = game.get("save_system")
	if save_system == null:
		return false
	var characters: Variant = (save_system as RefCounted).call("characters")
	if characters == null:
		return false
	if not bool((characters as RefCounted).call("has", character_id)):
		print("[session] join: no character file for '%s'; arriving as a fresh trainer"
			% character_id)
		return false
	if not bool((characters as RefCounted).call("apply", game, character_id)):
		push_warning("[session] join: could not apply character '%s'" % character_id)
		return false
	print("[session] join: restored character '%s' from disk (D100 portable half)"
		% character_id)
	return true


## `linger_transport`: a client that just sent its goodbye. The session state is
## torn down exactly as always, but the transport is detached and handed to
## `_poll_lingering_peer()` instead of being closed under the goodbye.
func _teardown(linger_transport: bool = false) -> void:
	if _groom_passive != null: _groom_passive.call("reset")
	if _owner_passive != null: _owner_passive.call("reset")
	_owner_passive_altar_original.clear()
	if _altar_traits_transport != null: _altar_traits_transport.call("reset")
	# Session's altar epoch survives a transport teardown. Explicitly retire
	# observations and consumed travel identities before a peer can rejoin.
	for path: NodePath in [^"FoundationComposition/TravelLifecycle", ^"FoundationComposition/PortalArrival", ^"FoundationComposition/ForgeHost"]:
		var travel_service := get_node_or_null(path)
		if travel_service != null: travel_service.call("reset")
	_portal_policy.call("bind_world", "")
	_portal_requests.clear()
	_portal_request_at.clear()
	# Peer ids are reused and the next session may serve another world; a
	# rejoin re-seeds the guest's persisted beats and re-arms at admission.
	_opening_gift_requested.clear()
	_legacy_home_key_due.clear()
	_regional_ack_refusals_logged.clear()
	_portal_waiters.clear()
	var had_transport := _peer != null
	if realm_transition != null:
		realm_transition.call("reset")
	# Before the peer goes away, not after: `realm_shells.gd::_tear_down()`
	# asks `Game.is_host()` whether it may write the world, and that answer
	# flips the moment `_mode` is cleared below.
	if _realms != null:
		_realms.call("release_all")
	if is_inside_tree() and multiplayer != null \
			and multiplayer.multiplayer_peer == _peer and _peer != null:
		multiplayer.multiplayer_peer = null
	if _peer != null:
		if linger_transport:
			if _lingering_peer != null:
				_lingering_peer.close()
			_lingering_peer = _peer
			_lingering_deadline_ms = Time.get_ticks_msec() + int(
				1000.0 * float(_cfg("goodbye_linger_s", GOODBYE_LINGER_S)))
		else:
			_peer.close()
	_peer = null
	_mode = ""
	_sync_tether_tonic_scope()
	_transport_kind = ""
	_preparing_client = false
	_capacity = 0
	_registry.call("clear")
	_box["connected"] = false
	_box["snapshot"] = true
	_pending_hello = {}
	_closing_frames = 0
	_closing_deadline_ms = 0
	_rejected_disconnect_frames.clear()
	_departing_peers.clear()
	_reserved_rejoins.clear()
	_snapshot_sends.clear()
	_clear_snapshot_bootstrap()
	_clock_accum = 0.0
	if had_transport:
		transport_closed.emit()


func _return_to_title(reason: String) -> void:
	var game := _game()
	if game != null and game.has_method("push_world_message"):
		game.call("push_world_message",
			"The host closed the world." if reason != "kicked" else "You were removed from the world.")
	var tree := get_tree()
	if tree == null:
		return
	tree.change_scene_to_file(TITLE_SCENE)


func _game() -> Node:
	return get_parent()


## Shared detached truth for protected keys and the host combat roster.
## Equipment comes from the one admitted personal record; legacy realm power
## is inactive in this read view until protected personal hang is implemented.
func admitted_character_state(peer_id: int) -> Dictionary:
	var trace := BACKGROUND_TRACE.begin("admission.total", peer_id)
	var result := _admitted_character_state_work(peer_id)
	BACKGROUND_TRACE.end("admission.total", trace, peer_id)
	return result


func _admitted_character_state_work(peer_id: int) -> Dictionary:
	if not is_host(): return {}
	var binding_trace := BACKGROUND_TRACE.begin("admission.bind_authority", peer_id)
	var bound := _bind_character_authority()
	BACKGROUND_TRACE.end("admission.bind_authority", binding_trace, peer_id)
	if not bound:
		return {}
	var character := _authority_character(peer_id)
	if character.is_empty():
		return {}
	if peer_id == local_peer_id():
		var game := _game()
		if game != null and game.get("local") != null:
			var projection_trace := BACKGROUND_TRACE.begin("admission.local_save_projection", peer_id)
			var portable := CHARACTER_AUTHORITY.portable_projection(game.get("local").save_data())
			BACKGROUND_TRACE.end("admission.local_save_projection", projection_trace, peer_id)
			var refresh_trace := BACKGROUND_TRACE.begin("admission.refresh_host_local", peer_id)
			var refreshed: Dictionary = _character_authority.call("refresh_host_local", portable, character)
			BACKGROUND_TRACE.end("admission.refresh_host_local", refresh_trace, peer_id)
			if not bool(refreshed.get("ok", false)):
				return {}
			var vitals_trace := BACKGROUND_TRACE.begin("admission.recover_vitals", peer_id)
			var recovered: Dictionary = _character_authority.call("recover_durable_vitals", character, game.get("world").reward_deliveries)
			BACKGROUND_TRACE.end("admission.recover_vitals", vitals_trace, peer_id)
			if not bool(recovered.get("ok", false)):
				return {}
	var training_trace := BACKGROUND_TRACE.begin("admission.recover_training", peer_id)
	var training_recovered: Dictionary = _character_authority.call("recover_durable_training", character, _game().get("world").reward_deliveries)
	BACKGROUND_TRACE.end("admission.recover_training", training_trace, peer_id)
	if training_recovered.get("ok") != true: return {}
	var game_for_portals := _game()
	if game_for_portals != null and game_for_portals.get("world") != null:
		var portals_trace := BACKGROUND_TRACE.begin("admission.recover_portals", peer_id)
		var portals: Dictionary = _character_authority.call("recover_durable_portals", character, game_for_portals.get("world").reward_deliveries)
		BACKGROUND_TRACE.end("admission.recover_portals", portals_trace, peer_id)
		if portals.get("ok") != true: return {}
	var actor_trace := BACKGROUND_TRACE.begin("admission.actor_stat_state", peer_id)
	var result: Dictionary = _character_authority.call("actor_stat_state", character)
	BACKGROUND_TRACE.end("admission.actor_stat_state", actor_trace, peer_id)
	return result


func admitted_character_revision(peer_id: int) -> int:
	if admitted_character_state(peer_id).is_empty():
		return -1
	return int(_character_authority.call("revision", _authority_character(peer_id)))


## Internal host contact CAS, never an RPC or a client numeric rank.
func host_commit_creature_mastery(peer_id: int, creature_uid: String,
		expected_character_revision: int, expected_uses: Dictionary, expected_receipts: Dictionary,
		next_uses: Dictionary, next_receipts: Dictionary) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {"ok": false, "code": "not_admitted", "revision": -1}
	return _character_authority.call("commit_creature_mastery", _authority_character(peer_id), creature_uid,
		expected_character_revision, expected_uses, expected_receipts, next_uses, next_receipts)


func host_commit_creature_loadout(peer_id: int, creature_uid: String,
		expected_character_revision: int, expected_loadout_revision: int, expected_last_edit: Dictionary,
		next_loadout: Dictionary, next_loadout_revision: int, next_edit_receipt: Dictionary) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {"ok": false, "code": "not_admitted", "revision": -1}
	return _character_authority.call("commit_creature_loadout", _authority_character(peer_id), creature_uid,
		expected_character_revision, expected_loadout_revision, expected_last_edit,
		next_loadout, next_loadout_revision, next_edit_receipt)


func admitted_pending_loadout(peer_id: int) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {}
	return _character_authority.call("pending_creature_loadout", _authority_character(peer_id))


## Internal service door. The authority result receiver sends a reliable ACK
## only after the portable write; the service binds its actual RPC sender.
func host_ack_creature_loadout(peer_id: int, creature_uid: String,
		loadout_revision: int, edit_receipt: Dictionary) -> bool:
	if admitted_character_state(peer_id).is_empty():
		return false
	return bool(_character_authority.call("acknowledge_creature_loadout", _authority_character(peer_id),
		creature_uid, loadout_revision, edit_receipt))


## Private owner transport proof only. No RPC, balance or persisted bag: this
## remembers which validated host receipt was applied while its bool save
## refused. Weak identity prevents another PlayerState reusing that proof.
var _owner_vitals_retries: Dictionary = {}


func _owner_vitals_retry_key(player: RefCounted, world: RefCounted, uid: String) -> String:
	return "%s\n%s\n%s" % [world.get("reward_delivery_namespace"), player.get("character_id"), uid]


func _owner_vitals_retry_receipt(player: RefCounted, world: RefCounted, uid: String) -> Dictionary:
	var raw: Variant = _owner_vitals_retries.get(_owner_vitals_retry_key(player, world, uid))
	if not raw is Dictionary or raw.player.get_ref() != player or raw.world.get_ref() != world:
		return {}
	return raw.row.duplicate(true)


func _retain_owner_vitals_retry(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	var actor := preload("res://scripts/net/actor_vitals_delivery.gd")
	var character := str(player.get("character_id"))
	var world_namespace := str(world.get("reward_delivery_namespace"))
	if character.is_empty() or not actor.valid(row, character, world_namespace) \
			or row.world_id != str(world.get("world_id")) \
			or not actor.equivalent(world.get("reward_deliveries").get(row.delivery_id), row):
		return false
	var key := _owner_vitals_retry_key(player, world, row.creature_uid)
	var config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/character_authority.json"))
	var limit: Variant = config.get("owner_vitals_retry_limit", 0) if config is Dictionary else 0
	if not (limit is int or limit is float) or not is_finite(float(limit)) \
			or float(limit) != floor(float(limit)) or float(limit) < 1.0 or float(limit) > 16384.0 \
			or (not _owner_vitals_retries.has(key) and _owner_vitals_retries.size() >= int(limit)):
		return false # Never evict an unsaved proof to accept a replay.
	_owner_vitals_retries[key] = {"player": weakref(player), "world": weakref(world), "row": row.duplicate(true)}
	return true


func _clear_owner_vitals_retry(player: RefCounted, world: RefCounted, row: Dictionary) -> void:
	var key := _owner_vitals_retry_key(player, world, row.creature_uid)
	var prior := _owner_vitals_retry_receipt(player, world, row.creature_uid)
	if not prior.is_empty() and int(prior.journal_revision) <= int(row.journal_revision):
		_owner_vitals_retries.erase(key)


## Every ordinary autosave uses the same snapshot preparation. An accepted
## unsaved HP value without its exact marker must never become a new portable
## disk baseline. The prepared receiver installs that marker before writing.
func _owner_vitals_snapshot_allowed(player: RefCounted, payload: Dictionary) -> bool:
	var actor := preload("res://scripts/net/actor_vitals_delivery.gd")
	for proof: Dictionary in _owner_vitals_retries.values():
		if proof.player.get_ref() != player:
			continue
		var row: Dictionary = proof.row
		if str(player.get("character_id")) != row.character_id \
				or (payload.has("character_id") and payload.character_id != row.character_id) \
				or not payload.get("party") is Array \
				or not payload.get("satchel_escrow") is Dictionary:
			return false
		var marker: Variant = payload.satchel_escrow.get(row.delivery_id)
		var expected: Dictionary = row.duplicate(true)
		expected.status = "settled"
		if not actor.equivalent(marker, expected):
			return false
		var found := false
		for owned: Variant in payload.party:
			if owned is Dictionary and owned.get("uid") == row.creature_uid:
				if found or not actor.equivalent(owned.get("hp"), row.hp) \
						or not actor.equivalent(owned.get("max_hp"), row.max_hp) or owned.get("fainted") != row.fainted:
					return false
				found = true
		if not found:
			return false
	return true


## Host EncounterHost caller only; packet values never reach this door.
func host_commit_creature_vitals(peer_id: int, creature_uid: String,
		expected_character_revision: int, expected_hp: float, expected_fainted: bool,
		next_hp: float, next_fainted: bool, host_receipt: Dictionary) -> Dictionary:
	if not is_host() or _authority_character(peer_id).is_empty() \
			or (_character_authority.call("state", _authority_character(peer_id)) as Dictionary).is_empty():
		return {"ok": false, "code": "not_admitted", "revision": -1}
	var character := _authority_character(peer_id)
	var stage: Dictionary = _character_authority.call("stage_creature_vitals", character, creature_uid,
		expected_character_revision, expected_hp, expected_fainted, next_hp, next_fainted, host_receipt)
	if not bool(stage.get("ok", false)) or bool(stage.get("duplicate", false)):
		return stage
	var accepted: Dictionary = _character_authority.call("staged_creature_vitals", stage)
	var transport := get_node_or_null(^"LedgerRpc")
	if transport == null:
		_character_authority.call("finish_creature_vitals", stage, false)
		return {"ok": false, "code": "ledger_not_prepared", "durable": false}
	var durable: Dictionary = transport.call("journal_actor_vitals_prepared", peer_id, character, accepted)
	var saved := bool(durable.get("ok", false))
	if not bool(_character_authority.call("finish_creature_vitals", stage, saved)):
		return {"ok": false, "code": "authority_stage_changed", "durable": saved}
	if not saved:
		return durable
	stage.erase("token")
	stage["accepted"] = accepted.duplicate(true)
	stage.accepted.durable = true
	stage["durable"] = true
	return stage


## Called only AFTER the exact pure EncounterHost actor commit. Publication
## may invoke owner saves or signals; it must never run inside the frozen CAS.
func host_finalize_creature_vitals(peer_id: int, creature_uid: String, receipt: Dictionary) -> bool:
	if not is_host():
		return false
	var transport := get_node_or_null(^"LedgerRpc")
	if transport == null:
		return false
	return bool(transport.call("publish_actor_vitals", peer_id, _authority_character(peer_id), creature_uid, receipt))


func admitted_pending_vitals(peer_id: int) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {}
	return _character_authority.call("pending_creature_vitals", _authority_character(peer_id))


func host_ack_creature_vitals(peer_id: int, creature_uid: String,
		character_revision: int, receipt: Dictionary) -> bool:
	if not is_host() or admitted_character_state(peer_id).is_empty(): return false
	var character: String = _authority_character(peer_id)
	var world: RefCounted = _game().get("world")
	var actor_codec: Script = preload("res://scripts/net/actor_vitals_delivery.gd")
	var row: Dictionary = world.get("reward_deliveries").get(actor_codec.delivery_id(str(world.get("reward_delivery_namespace")), character, creature_uid), {})
	if not actor_codec.valid(row, character, str(world.get("reward_delivery_namespace"))) \
		or row.get("status") != "accepted" or row.world_id != str(world.get("world_id")) \
		or row.character_revision != character_revision or not ESSENCE._equivalent(row.receipt, receipt): return false
	var directors: Array[Node] = _foundation_directors_under(_foundation_realm_roots())
	# Validate both immutable source epochs before releasing any pending CAS.
	for director: Node in directors:
		var proof: Dictionary = director.get_meta("foundation_ordinary_vitals_commits", {}).get(receipt.get("receipt_id"), {})
		if proof.is_empty():
			if _ordinary_actor_vitals_owned_origin(director, row): return false
			continue
		if not _ordinary_combat_director_live(director) or proof.get("character_id") != character \
			or proof.get("world_id") != row.world_id or proof.get("scope", {}).get("world_namespace") != row.world_namespace \
			or proof.get("scope", {}).get("session_id") != _altar_current_epoch() \
			or not _ordinary_actor_vitals_original_row(proof, row) \
			or not ESSENCE._equivalent(proof.get("proposal", {}).get("settlement_receipt"), receipt) \
			or (proof.get("accepted") == true and not ESSENCE._equivalent(proof.get("accepted_row"), row)): return false
	# Authority may already be released when the accepted duplicate repairs a
	# lost arbiter ACK. Only the exact accepted world decision permits that retry.
	var pending: Dictionary = _character_authority.call("pending_creature_vitals", character)
	if pending.has(creature_uid) and _character_authority.call("acknowledge_creature_vitals", character,
		creature_uid, character_revision, receipt) != true: return false
	for director: Node in directors:
		var proofs: Dictionary = director.get_meta("foundation_ordinary_vitals_commits", {})
		var proof: Dictionary = proofs.get(receipt.get("receipt_id"), {})
		if proof.is_empty(): continue
		if not _ordinary_combat_director_live(director) or proof.get("character_id") != character \
			or proof.get("world_id") != row.world_id or proof.get("scope", {}).get("world_namespace") != row.world_namespace \
			or proof.scope.session_id != _altar_current_epoch() or not _ordinary_actor_vitals_original_row(proof, row) \
			or not ESSENCE._equivalent(proof.get("proposal", {}).get("settlement_receipt"), receipt): return false
		var host: RefCounted = director.get("_encounter_host")
		if host == null or host.get_script() not in [preload("res://scripts/net/encounter_host.gd"), preload("res://scripts/combat/accepted_action_host.gd")]: return false
		var record: Dictionary = host.call("record", str(receipt.encounter_id))
		var members: Array = record.get("participants", {}).values()
		members.append_array(record.get("retained_actor_participants", {}).values())
		var found: bool = false
		for member: Dictionary in members:
			if member.get("character_id") != character: continue
			var actor: Dictionary = member.get("actor_vitals", {}).get(creature_uid, {})
			if actor.is_empty(): return false
			if int(actor.get("settled_revision", -1)) >= int(receipt.vitals_revision):
				found = true # Historical ACK cannot rewrite a newer actor/body.
			elif host.call("acknowledge_actor_vitals", str(receipt.encounter_id), character,
				creature_uid, int(receipt.vitals_revision), receipt) == true: found = true
		if not found: return false
		if proof.get("accepted") == true:
			if not ESSENCE._equivalent(proof.get("accepted_row"), row): return false
		else:
			if _character_authority.call("promote_accepted_vitals_marker", character, row) != true: return false
			proof["accepted"] = true
			proof["accepted_row"] = row.duplicate(true)
		director.set_meta("foundation_ordinary_vitals_commits", proofs)
	# A rejoin admission parked behind this character's in-flight vitals can
	# now compare the settled markers the owner already saved (the owner's own
	# traffic re-checks too: owner_passive_sync.receive_host).
	if (_character_authority.call("pending_creature_vitals", character) as Dictionary).is_empty():
		_owner_passive_service().call("retry_deferred", character)
	return true


func admitted_portal_keys(peer_id: int) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {}
	return _character_authority.call("protected_keys", _authority_character(peer_id), _accepted_world_deliveries())


## Explicit staging for the existing synchronous LedgerRpc world-save boundary.
func host_stage_portal_debit(peer_id: int, biome: String, receipt: String) -> Dictionary:
	if admitted_character_state(peer_id).is_empty():
		return {"ok": false, "code": "not_admitted"}
	return _character_authority.call("stage_portal_debit", _authority_character(peer_id),
		biome, receipt, _accepted_world_deliveries())


func host_commit_portal_debit(stage: Dictionary) -> bool:
	return is_host() and bool(_character_authority.call("commit_portal_debit", stage))


func host_finish_portal_debit(stage: Dictionary, world_saved: bool) -> bool:
	return is_host() and bool(_character_authority.call("finish_portal_debit", stage, world_saved))


func _accepted_world_deliveries() -> Array:
	var game := _game()
	if game == null or game.get("world") == null:
		return []
	var records: Variant = game.get("world").get("reward_deliveries")
	return records.values() if records is Dictionary else []


func _authority_character(peer_id: int) -> String:
	if peer_id == local_peer_id():
		return _local_character_id()
	var row: Dictionary = _registry.call("row", peer_id)
	return str(row.get("character_id", ""))


func _bind_character_authority() -> bool:
	var game := _game()
	if game == null or game.get("world") == null:
		return false
	var raw: Variant = game.get("world").get("reward_delivery_namespace")
	# Existing Game snapshot bootstrap owns world identity creation. Use its
	# same host-only seam once when the identity is not yet established.
	if not raw is String or raw.is_empty():
		_world_snapshot()
		raw = game.get("world").get("reward_delivery_namespace")
	if not raw is String or not bool(_character_authority.call("bind_world", raw)): return false
	_sync_tether_tonic_scope()
	_character_authority.call("bind_portal_pending_reader", _pending_portal_for)
	return true


func _local_character_id() -> String:
	var game := _game()
	if game == null:
		return ""
	var local: Variant = game.get("local")
	if local == null:
		return ""
	var id := str((local as RefCounted).get("character_id"))
	if id.is_empty():
		# The title normally creates identity before a session starts. Automation
		# and older entry points still need the same stable, slot-independent form.
		id = CHARACTER_IDENTITY.mint()
		(local as RefCounted).set("character_id", id)
	return id


func _local_display_name() -> String:
	var game := _game()
	if game == null:
		return "Trainer"
	var local: Variant = game.get("local")
	if local == null:
		return "Trainer"
	var n := str((local as RefCounted).get("display_name"))
	return n if not n.is_empty() else "Trainer"


func _local_appearance_id() -> String:
	var game := _game()
	if game == null:
		return "trainer"
	var local: Variant = game.get("local")
	if not local is Object:
		return "trainer"
	var appearance := str((local as Object).get("chosen_character"))
	return appearance if not appearance.is_empty() else "trainer"


func _local_realm() -> String:
	var game := _game()
	if game == null:
		return "meadows"
	return str(game.get("current_realm"))


func _altar_current_epoch() -> String:
	if is_host(): return _altar_epoch
	var game := _game()
	return _altar_host_epoch if game != null and game.get("world") != null and game.get("world").reward_delivery_namespace == _altar_host_namespace else ""


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_epoch(epoch: String, world_namespace: String, character: String) -> void:
	if is_host() or not _altar_hex_id(epoch) or character != _local_character_id() or world_namespace.is_empty(): return
	_altar_host_epoch = epoch
	_altar_host_namespace = world_namespace
	_sync_tether_tonic_scope()


static func _altar_hex_id(raw: Variant) -> bool:
	if not raw is String or raw.length() != 32: return false
	for code: int in raw.to_utf8_buffer():
		if not (code >= 48 and code <= 57) and not (code >= 97 and code <= 102): return false
	return true


func _altar_envelope(op: String, key: String) -> Dictionary:
	var game := _game()
	if game == null or game.get("world") == null or _altar_current_epoch().is_empty(): return {}
	return {"op": op, "session_epoch": _altar_current_epoch(),
		"world_namespace": game.get("world").reward_delivery_namespace,
		"character_id": _local_character_id(), "station_key": key}


func _altar_envelope_matches(peer: int, envelope: Dictionary, fields: Array) -> bool:
	if not is_host() or envelope.size() != fields.size(): return false
	for field: String in fields:
		if not envelope.has(field): return false
	var character := _authority_character(peer)
	return not character.is_empty() and (peer == local_peer_id() or bool(_registry.call("has", peer))) \
		and envelope.character_id == character and envelope.session_epoch == _altar_epoch \
		and envelope.world_namespace == _game().get("world").reward_delivery_namespace \
		and ESSENCE._opaque_id(envelope.station_key)


## Trusted builder registration stores a weak node only. Each use rechecks
## committed UID, realm, ID, pose and the owning Homestead placement policy.
func _register_altar_station_node(key: String, building: Node3D) -> bool:
	if _altar_station_record(key, building).is_empty(): return false
	var prior: WeakRef = _altar_stations.get(key)
	if prior != null and prior.get_ref() != null and prior.get_ref() != building: return false
	_altar_stations[key] = weakref(building)
	return true


func _unregister_altar_station_node(key: String, building: Node3D) -> void:
	var prior: WeakRef = _altar_stations.get(key)
	if prior != null and prior.get_ref() == building: _altar_stations.erase(key)


func _altar_station_record(key: String, building: Node3D) -> Dictionary:
	var game := _game()
	if game == null or not is_instance_valid(building) or not building.is_inside_tree() \
			or not building.is_in_group("placed_building") or building.get_meta("building_id", "") != "altar" \
			or building.get_meta("realm", "") != "meadows" or not key.begins_with("altar:meadows:"): return {}
	var uid := key.trim_prefix("altar:meadows:")
	if not ESSENCE._component(uid) or not game.get("items").call("buildable", "altar") is Dictionary \
			or (game.get("items").call("buildable", "altar") as Dictionary).is_empty(): return {}
	var selected: Dictionary = {}
	for raw: Variant in game.get("world").placed_buildings:
		if raw is Dictionary and raw.get("uid") == uid:
			if not selected.is_empty(): return {}
			selected = raw.duplicate(true)
	if selected.get("id") != "altar" or selected.get("realm", "meadows") != "meadows" \
			or selected.get("removed", false) != false: return {}
	var position: Variant = selected.get("position")
	var yaw: Variant = selected.get("yaw_deg")
	if not position is Array or position.size() != 3 or not (yaw is int or yaw is float) \
			or not is_finite(float(yaw)): return {}
	for coordinate: Variant in position:
		if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)): return {}
	var authored := Vector3(float(position[0]), float(position[1]), float(position[2]))
	if building.global_position.distance_to(authored) > 0.01 \
			or absf(wrapf(rad_to_deg(building.global_rotation.y) - float(yaw), -180.0, 180.0)) > 0.01: return {}
	# Deliberately closed until the canonical owning build/plot validator is
	# wired. No duplicated farmhouse bounds or synthetic station fallback.
	if not game.has_method("altar_placement_is_authorized") \
			or game.call("altar_placement_is_authorized", selected, building) != true: return {}
	# Pending paid placement may register its real node after durable world publication; owner mutation/readiness guards still prevent its use.
	if TRAINING_WORLD.altar_paid_provenance(game.get("world").reward_deliveries, game.get("world").reward_delivery_namespace, game.get("world").world_id, selected, "", false).is_empty(): return {}
	return selected


func _altar_station_for_peer(peer: int, key: String) -> bool:
	var weak: WeakRef = _altar_stations.get(key)
	var building := weak.get_ref() as Node3D if weak != null else null
	if _altar_station_record(key, building).is_empty(): return false
	var transport := get_node_or_null(^"LedgerRpc")
	if transport == null: return false
	var context: Dictionary = transport.call("_water_actor_context", peer, {})
	if context.get("character_id") != _authority_character(peer) or context.get("realm") != "meadows" \
			or not context.get("position") is Vector3: return false
	if _altar_peer_in_combat(peer): return false
	var radius: Variant = ESSENCE.config().get("altar_interaction_radius_m")
	return (radius is int or radius is float) and is_finite(float(radius)) and float(radius) > 0.0 \
		and (context.position as Vector3).distance_to(building.global_position) <= float(radius)


func altar_station_available(key: String) -> bool:
	if ESSENCE.config().get("altar_runtime_enabled") != true or not ESSENCE.config().get("altar_runtime_enabled") is bool: return false
	if _owner_training_mutation_blocked(_game().get("local")) or not snapshot_ready(): return false
	if is_host(): return _altar_station_for_peer(local_peer_id(), key) and not admitted_character_state(local_peer_id()).is_empty()
	var weak: WeakRef = _altar_stations.get(key)
	return not _altar_current_epoch().is_empty() and weak != null \
		and not _altar_station_record(key, weak.get_ref() as Node3D).is_empty()


func quote_altar_essence_spend(key: String, uid: String, quote_id: String) -> Dictionary:
	if not _altar_hex_id(quote_id) or not ESSENCE._component(uid): return {"ok": false, "code": "invalid_quote"}
	var envelope := _altar_envelope("altar_quote", key)
	if envelope.is_empty(): return {"ok": false, "code": "authority_missing"}
	envelope["owned_uid"] = uid
	envelope["quote_id"] = quote_id
	_altar_quote_request = envelope.duplicate(true)
	if is_host(): return _handle_altar_quote(local_peer_id(), envelope)
	if not is_active(): return {"ok": false, "code": "authority_missing"}
	rpc_id(HOST_PEER_ID, "_rpc_altar_quote", envelope)
	return {"ok": false, "pending": true, "code": "quote_pending"}


func _handle_altar_quote(peer: int, envelope: Dictionary) -> Dictionary:
	if ESSENCE.config().get("altar_runtime_enabled") != true or not ESSENCE.config().get("altar_runtime_enabled") is bool: return {"ok": false, "code": "altar_not_ready"}
	if not _altar_envelope_matches(peer, envelope, ["op", "session_epoch", "world_namespace", "character_id", "station_key", "owned_uid", "quote_id"]) \
			or envelope.op != "altar_quote" or not _altar_hex_id(envelope.quote_id) \
			or not ESSENCE._component(envelope.owned_uid) or not _altar_station_for_peer(peer, envelope.station_key):
		return {"ok": false, "code": "station_unavailable"}
	if admitted_character_state(peer).is_empty(): return {"ok": false, "code": "not_admitted"}
	var character := _authority_character(peer)
	# Refresh/bind above uses the existing local owner, but prices and stage
	# ALWAYS use its full protected record, not the masked combat read view.
	return ESSENCE.quote_spend(_character_authority.call("state", character), character,
		envelope.owned_uid, int(_character_authority.call("revision", character)), ESSENCE.config(), PROGRESSION.config())


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_quote(envelope: Dictionary) -> void:
	if not is_host(): return
	var peer := multiplayer.get_remote_sender_id()
	var result := _handle_altar_quote(peer, envelope)
	if bool(_registry.call("has", peer)): rpc_id(peer, "_rpc_altar_quote_result", envelope, result)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_quote_result(envelope: Dictionary, result: Dictionary) -> void:
	if is_host() or not ESSENCE._equivalent(envelope, _altar_quote_request) \
			or envelope.get("session_epoch") != _altar_current_epoch() \
			or envelope.get("character_id") != _local_character_id() \
			or envelope.get("world_namespace") != _game().get("world").reward_delivery_namespace: return
	_altar_quote_request = {}
	altar_essence_quote_completed.emit(envelope.station_key, envelope.owned_uid, envelope.quote_id, result.duplicate(true))


func submit_altar_essence_spend(key: String, intent: Dictionary) -> Dictionary:
	return _send_altar_spend("altar_spend", key, intent)


func reconcile_altar_essence_spend(key: String, intent: Dictionary) -> Dictionary:
	return _send_altar_spend("altar_reconcile", key, intent)


func _send_altar_spend(op: String, key: String, intent: Dictionary) -> Dictionary:
	var envelope := _altar_envelope(op, key)
	if envelope.is_empty(): return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	envelope["intent"] = intent.duplicate(true)
	_altar_spend_request = envelope.duplicate(true)
	if op == "altar_spend": _owner_passive_altar_original = envelope.duplicate(true)
	if is_host(): return _handle_altar_spend(local_peer_id(), envelope)
	if not is_active(): return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	rpc_id(HOST_PEER_ID, "_rpc_altar_spend", envelope)
	return {"ok": false, "resolved": false, "code": "awaiting_saved_decision"}


func _handle_altar_spend(peer: int, envelope: Dictionary) -> Dictionary:
	var refuse := {"ok": false, "resolved": true, "durable": false, "saved": false, "code": "invalid_spend"}
	if not _altar_envelope_matches(peer, envelope, ["op", "session_epoch", "world_namespace", "character_id", "station_key", "intent"]) \
			or not envelope.op in ["altar_spend", "altar_reconcile"] or not envelope.intent is Dictionary: return refuse
	var intent: Dictionary = envelope.intent
	if intent.size() != 5 or not _altar_hex_id(intent.get("spend_id")): return refuse
	for field: String in ["creature_uid", "expected_level", "payment_item", "expected_character_revision"]:
		if not intent.has(field): return refuse
	var character := _authority_character(peer)
	var world: RefCounted = _game().get("world")
	var id := ESSENCE.training_delivery_id(world.reward_delivery_namespace, character)
	var row: Variant = world.reward_deliveries.get(id)
	if row is Dictionary and row.action_id == intent.spend_id:
		if not ESSENCE._equivalent(row.intent, intent): return refuse
		return _training_decision(peer, row)
	# An old spend may be superseded only after it was durably accepted.
	# Its complete eight-part receipt remains in the SAME personal history.
	if admitted_character_state(peer).is_empty(): return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	var full: Dictionary = _character_authority.call("state", character)
	var revision := int(_character_authority.call("revision", character))
	var proposal := ESSENCE.stage_core_spend(full, character, revision, intent, ESSENCE.config(),
		PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	if proposal.get("duplicate") == true and row is Dictionary and row.status == "accepted" and TRAINING_WORLD.training_row_valid(row, world.reward_delivery_namespace, world.world_id) and row.after.redesign_character.transaction_receipts.has(proposal.receipt):
		return {"ok": true, "resolved": true, "durable": true, "saved": true, "receipt": proposal.receipt,
			"character_revision": int(intent.expected_character_revision) + 1, "journal_revision": row.journal_revision}
	if proposal.get("duplicate") == true or envelope.op == "altar_reconcile":
		return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	if proposal.get("ok") != true:
		refuse.code = proposal.get("code", "invalid_spend")
		return refuse
	if ESSENCE.config().get("altar_runtime_enabled") != true or not ESSENCE.config().get("altar_runtime_enabled") is bool:
		refuse.code = "altar_not_ready"
		return refuse
	if peer != local_peer_id() and (ESSENCE.config().get("altar_remote_spend_enabled") != true or not ESSENCE.config().get("altar_remote_spend_enabled") is bool):
		refuse.code = "remote_training_baseline_not_ready"
		return refuse
	if not _altar_station_for_peer(peer, envelope.station_key):
		refuse.code = "station_unavailable"
		return refuse
	var saver: RefCounted = _game().get("save_system")
	if saver == null: return refuse
	saver.call("finish_fallback") # All callbacks BEFORE re-freezing actual identity/state.
	if saver.call("fallback_busy") == true or not _altar_envelope_matches(peer, envelope,
		["op", "session_epoch", "world_namespace", "character_id", "station_key", "intent"]) \
		or not _altar_station_for_peer(peer, envelope.station_key) or admitted_character_state(peer).is_empty(): return refuse
	full = _character_authority.call("state", character)
	revision = int(_character_authority.call("revision", character))
	proposal = ESSENCE.stage_core_spend(full, character, revision, intent, ESSENCE.config(),
		PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	if proposal.get("ok") != true: return proposal
	if peer != local_peer_id():
		var context := {"character_id": character, "expected_revision": revision, "source_key": envelope.station_key,
			"station_id": "altar", "actual_altar": true, "in_range": true, "in_combat": false,
			"foundation_runtime_authorized": true}
		var ready: Dictionary = _owner_passive_service().call("action_gate", peer, "altar_spend", envelope, context)
		if ready.get("ok") != true: return ready
	var transport := get_node_or_null(^"LedgerRpc")
	var committed := ESSENCE.commit_host_training(_character_authority, transport, peer, character,
		"altar_spend", intent.spend_id, intent, proposal)
	if committed.get("durable") != true:
		refuse.code = committed.get("code", "training_journal_failed")
		return refuse
	transport.call("publish_creature_training", peer, character, committed.receipt)
	return {"ok": false, "resolved": false, "durable": true, "saved": false,
		"receipt": committed.receipt, "code": "awaiting_saved_decision"}


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_spend(envelope: Dictionary) -> void:
	if not is_host(): return
	var peer := multiplayer.get_remote_sender_id()
	var result := _handle_altar_spend(peer, envelope)
	if bool(_registry.call("has", peer)): rpc_id(peer, "_rpc_altar_spend_result", envelope, result)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_altar_spend_result(envelope: Dictionary, result: Dictionary) -> void:
	if is_host() or not ESSENCE._equivalent(envelope, _altar_spend_request) \
			or envelope.get("session_epoch") != _altar_current_epoch() \
			or envelope.get("character_id") != _local_character_id() \
			or envelope.get("world_namespace") != _game().get("world").reward_delivery_namespace: return
	# A reply is correlation/presentation only, never a portable state import.
	if result.get("ok") == true:
		var row := _owner_training_row()
		if row.is_empty() or _training_decision(local_peer_id(), row).get("ok") != true \
				or not row.after.redesign_character.transaction_receipts.has(result.get("receipt")): return
	altar_essence_spend_completed.emit(envelope.station_key, envelope.intent.spend_id, result.duplicate(true))


func host_ack_creature_training(peer: int, row: Dictionary) -> bool:
	var world: RefCounted=_game().get("world")
	if row.get("status")!="accepted" or not ESSENCE._equivalent(world.reward_deliveries.get(row.get("delivery_id")),row): return false
	var character := _authority_character(peer)
	if character.is_empty() or character != row.get("character_id"): return false
	if not _tether_item_live_consumer_ready(row): return false
	# Load can expose accepted history before this host's first lazy admission.
	# Recover only its actual local player through the existing validated path.
	if peer == local_peer_id() and int(_character_authority.call("revision", character)) < 0:
		if admitted_character_state(peer).is_empty(): return false
	var pending: bool = _character_authority.call("creature_training_is_pending", character) == true
	if not pending and (row.get("action") != "tether_item" or not _tether_item_original_pending(row)):
		# A recovered saved marker is history, not permission to rewrite live HP.
		return _acknowledge_training_and_readmit(character, row)
	if pending and _character_authority.call("creature_training_pending_matches", character, row) != true: return false
	if row.get("kind") == "altar_building": return _acknowledge_training_and_readmit(character, row)
	var bundle: Dictionary=_training_actor_baseline_proposals(peer,row)
	if bundle.get("ok")!=true: return false
	# Private actor commits have no publishing/reentrant callback. All proposed
	# changes were checked before the accepted row's writer and again here.
	for proposal: Dictionary in bundle.proposals:
		if proposal.host.call("commit_actor_training_baseline",proposal.stage,row,bundle.admitted,
			bundle.revision,world.reward_deliveries,world.reward_delivery_namespace,world.world_id)!=true: return false
	if not _install_host_tether_tonic(peer, row): return false
	if not _acknowledge_training_and_readmit(character, row): return false
	return _finalize_tether_item_row(row) if row.get("action") == "tether_item" else true


func _acknowledge_training_and_readmit(character: String, row: Dictionary) -> bool:
	if _character_authority.call("acknowledge_creature_training", character, row) != true: return false
	# A pending bounty/training row may have held this character's first
	# rejoin declaration. Only its actual accepted owner ACK releases it.
	if _owner_passive != null: _owner_passive.call("retry_deferred", character)
	return true


func _tether_item_original_pending(row: Dictionary) -> bool:
	for director: Node in _foundation_directors_under(_foundation_realm_roots()):
		if not _ordinary_combat_director_live(director): continue
		var host: RefCounted = director.get("_encounter_host")
		if host == null: continue
		for original: Dictionary in host.call("pending_tether_items", str(row.get("intent", {}).get("request", {}).get("encounter_id", ""))):
			if ESSENCE._equivalent(original.intent, row.get("intent")) and ESSENCE._equivalent(original.context, row.get("host_context")):
				return true
	return false


func _tether_item_live_consumer_ready(row: Dictionary) -> bool:
	if row.get("action") != "tether_item": return true
	var items: RefCounted = preload("res://scripts/world/death_satchel_rules.gd").db()
	if not items.call("definition", str(row.get("intent", {}).get("effect", {}).get("item_id", ""))).has("creature_buff"): return true
	var game := _game()
	return is_inside_tree() and game != null and game.get("session") == self \
		and game.has_signal("party_passive_tick") and _character_authority != null \
		and _owner_passive_service() != null

func _install_host_tether_tonic(peer: int, row: Dictionary) -> bool:
	if row.get("action") != "tether_item": return true
	var buff: Dictionary = preload("res://scripts/world/death_satchel_rules.gd").db().call("definition",
		str(row.get("intent", {}).get("effect", {}).get("item_id", ""))).get("creature_buff", {})
	if buff.is_empty(): return true
	var character := _authority_character(peer)
	var stream: Dictionary = _owner_passive.get("hosts").get(character, {})
	if peer != local_peer_id() and (stream.is_empty() or stream.get("peer") != peer \
		or stream.get("epoch") != _altar_current_epoch() or stream.get("departed") == true): return false
	var stream_id := "local" if peer == local_peer_id() else str(stream.id)
	var sequence := int(_game().get("_passive_observation_sequence")) if peer == local_peer_id() else int(stream.cursor.sequence)
	for director: Node in _foundation_directors_under(_foundation_realm_roots()):
		if not _ordinary_combat_director_live(director): continue
		var host: RefCounted = director.get("_encounter_host")
		if host == null: continue
		for original: Dictionary in host.call("pending_tether_items", str(row.intent.request.encounter_id)):
			if not ESSENCE._equivalent(original.intent, row.intent) or not ESSENCE._equivalent(original.context, row.host_context): continue
			var now_ms := Time.get_ticks_msec()
			var uid := str(row.intent.effect.creature_uid)
			var changes_wind: bool = buff.get("stat") in ["wind_cap", "wind_regen"]
			if changes_wind: _settle_tether_tonic_wind(character, uid, now_ms)
			director.call("capture_tether_tonic_card", peer, str(row.intent.effect.creature_uid))
			if _character_authority.call("install_saved_tether_tonic", character, row, original,
				stream_id, _altar_current_epoch(), sequence) != true: return false
			if peer == local_peer_id():
				_tether_tonic_observer_scope = _tether_tonic_current_scope()
				_sync_tether_tonic_scope()
			if changes_wind:
				_settle_tether_tonic_wind(character, uid, now_ms, _tether_tonic_wind_profile(character, uid))
			original["tonic_receipt"] = row.receipt
			return true
	return false

func _settle_tether_tonic_wind(character: String, uid: String, now_ms: int, profile: Dictionary = {}) -> void:
	for director: Node in _foundation_directors_under(_foundation_realm_roots()):
		if not _ordinary_combat_director_live(director): continue
		var host: RefCounted = director.get("_encounter_host")
		if host != null: host.call("settle_tether_tonic_wind", character, uid, now_ms, profile)

func _tether_tonic_wind_profile(character: String, uid: String) -> Dictionary:
	var admitted: Dictionary = _character_authority.call("state", character)
	var stream: Dictionary = _owner_passive.get("hosts").get(character, {}) if _owner_passive != null else {}
	for owned: Dictionary in admitted.get("party", []):
		if owned.get("uid") != uid: continue
		var passive := owned.duplicate(true)
		var local_member: RefCounted
		if character == _local_character_id() and _game() != null and _game().get("local") != null:
			for member: RefCounted in _game().get("local").party.call("members"):
				if member.get("uid") == uid: local_member = member
			if local_member != null:
				for field: String in preload("res://scripts/net/owner_passive_replay.gd").PASSIVE_FIELDS:
					if field in local_member: passive[field] = local_member.get(field)
		if stream.get("epoch") == _altar_current_epoch() and str(stream.get("error", "")).is_empty():
			for card: Dictionary in stream.get("cursor", {}).get("state", {}).get("party", []):
				if card.get("uid") != uid: continue
				for field: String in preload("res://scripts/net/owner_passive_replay.gd").PASSIVE_FIELDS:
					if card.has(field): passive[field] = card[field]
		var creature: RefCounted = preload("res://scripts/save/water_capture_codec.gd").decode_owned(passive, admitted.redesign_character)
		if creature == null: return {}
		var projection: Dictionary = _character_authority.call("tether_tonic_projection", character)
		if local_member != null:
			var managed: Dictionary = local_member.get_meta("tether_tonic_projection", {}).get("receipts", {}).duplicate()
			for effect: Dictionary in projection.get(uid, {}).get("effects", []): managed[str(effect.id)] = true
			for native: Dictionary in local_member.get("active_buffs"):
				if not managed.has(str(native.id)):
					creature.call("apply_buff", str(native.id), str(native.stat), float(native.scale), float(native.remaining_s))
		for effect: Dictionary in projection.get(uid, {}).get("effects", []):
			creature.call("apply_buff", str(effect.id), str(effect.stat), float(effect.scale), float(effect.remaining_s))
		var condition := preload("res://scripts/creatures/creature_condition.gd")
		return preload("res://scripts/combat/combat_manager.gd").host_wind_profile({
			"species_id": creature.get("species_id"), "bond_nodes": creature.call("bond_nodes"),
			"nourishment_fraction": condition.nourishment_fraction(creature, condition.config()),
			"wind_cap_scale": creature.call("buff_scale", "wind_cap"),
			"wind_regen_scale": creature.call("buff_scale", "wind_regen")})
	return {}

func admitted_tether_tonics(peer: int) -> Dictionary:
	if not is_host() or _character_authority == null: return {}
	return _character_authority.call("tether_tonic_projection", _authority_character(peer))

func tether_tonic_passive_card(peer: int, uid: String, owned: Dictionary) -> Dictionary:
	var stream: Dictionary = _owner_passive.get("hosts").get(_authority_character(peer), {}) if _owner_passive != null else {}
	if stream.get("peer") != peer or stream.get("epoch") != _altar_current_epoch() \
		or stream.get("departed") == true or not str(stream.get("error", "")).is_empty(): return owned
	var result := owned.duplicate(true)
	for card: Dictionary in stream.get("cursor", {}).get("state", {}).get("party", []):
		if card.get("uid") != uid: continue
		for field: String in preload("res://scripts/net/owner_passive_replay.gd").PASSIVE_FIELDS:
			if card.has(field): result[field] = card[field]
	return result

func _tick_host_tether_tonics(character: String, delta: float, uids: Array, stream_id: String,
		epoch: String, sequence: int) -> void:
	if not is_host() or _character_authority == null or epoch != _altar_current_epoch(): return
	var now_ms := Time.get_ticks_msec()
	var before: Dictionary = _character_authority.call("tether_tonic_projection", character)
	var boundaries: Array[String] = []
	for uid: String in uids:
		for effect: Dictionary in before.get(uid, {}).get("effects", []):
			if effect.get("stat") in ["wind_cap", "wind_regen"] and float(effect.remaining_s) <= delta:
				if not boundaries.has(uid): boundaries.append(uid)
	for uid: String in boundaries: _settle_tether_tonic_wind(character, uid, now_ms)
	_character_authority.call("tick_tether_tonics", character, delta, uids, stream_id, epoch, sequence)
	if boundaries.is_empty(): return
	var after: Dictionary = _character_authority.call("tether_tonic_projection", character)
	for uid: String in boundaries:
		if after.get(uid, {}).get("version") != before.get(uid, {}).get("version"):
			_settle_tether_tonic_wind(character, uid, now_ms, _tether_tonic_wind_profile(character, uid))

func _tether_tonic_current_scope() -> Array:
	var game := _game()
	if game == null or game.get("local") == null or game.get("world") == null: return []
	return [_local_character_id(), game.get("world").reward_delivery_namespace, _altar_current_epoch()]

func _sync_tether_tonic_scope() -> void:
	var game := _game()
	var scope := _tether_tonic_current_scope()
	if game == null: return
	# Empty projection only retires managed buffs from a different context.
	_apply_host_tether_tonics({})
	if _tether_tonic_observer_scope != scope: _tether_tonic_observer_scope.clear()
	if not game.has_signal("party_passive_tick"): return
	var live: bool = not scope.is_empty() and is_host() and _character_authority != null \
		and _tether_tonic_observer_scope == scope and _character_authority.get("_world_instance") == scope[1]
	if live:
		live = false
		for held: Dictionary in _character_authority.call("tether_tonic_projection", _local_character_id()).values():
			if not held.get("effects", []).is_empty(): live = true
	var connected := game.is_connected("party_passive_tick", _tether_tonic_party_tick)
	if live and not connected: game.connect("party_passive_tick", _tether_tonic_party_tick)
	elif not live and connected: game.disconnect("party_passive_tick", _tether_tonic_party_tick)

func _tether_tonic_party_tick(observation: Dictionary) -> void:
	var game := _game()
	if game == null: return
	if game.get("world") == null or not is_host() or _character_authority == null \
		or _tether_tonic_observer_scope != _tether_tonic_current_scope() \
		or _character_authority.get("_world_instance") != game.get("world").reward_delivery_namespace:
		_sync_tether_tonic_scope()
		return
	if game == null or observation.get("character_id") != _local_character_id() \
		or observation.get("world_namespace") != game.get("world").reward_delivery_namespace \
		or observation.get("session_epoch") != _altar_current_epoch(): return
	if is_host():
		_tick_host_tether_tonics(_local_character_id(), float(observation.delta), [observation.uid],
			"local", _altar_current_epoch(), int(observation.sequence))
		var live := false
		for held: Dictionary in _character_authority.call("tether_tonic_projection", _local_character_id()).values():
			if not held.get("effects", []).is_empty(): live = true
		if not live: _sync_tether_tonic_scope()

## These projections arrive only on the existing authenticated passive carrier
## after its character/world/epoch/current-stream checks. No portable buff import.
func _apply_host_tether_tonics(projected: Dictionary) -> bool:
	var game := _game()
	if game == null or game.get("local") == null: return false
	var party: RefCounted = game.get("local").get("party") as RefCounted
	if party == null or not party.has_method("members"): return false
	var context := _tether_tonic_current_scope()
	for member: RefCounted in party.call("members"):
		var uid := str(member.get("uid"))
		var seen: Dictionary = member.get_meta("tether_tonic_projection", {})
		if not seen.is_empty() and seen.get("context") != context:
			var carried: Array = member.get("active_buffs")
			for index: int in range(carried.size() - 1, -1, -1):
				if seen.get("receipts", {}).has(str(carried[index].get("id", ""))): carried.remove_at(index)
			seen = {}
			member.set_meta("tether_tonic_projection", {"context": context, "version": -1, "receipts": {}})
		var row: Dictionary = projected.get(uid, {})
		if row.is_empty() or context.is_empty(): continue
		if seen.get("context") == context and int(seen.get("version", -1)) >= int(row.get("version", -1)): continue
		var previous: Dictionary = seen.get("receipts", {}) if seen.get("context") == context else {}
		var buffs: Array = member.get("active_buffs")
		var effects: Array = row.get("effects", [])
		for index: int in range(buffs.size() - 1, -1, -1):
			var id := str(buffs[index].get("id", ""))
			if previous.has(id) and not effects.any(func(effect: Dictionary) -> bool: return effect.get("id") == id): buffs.remove_at(index)
		for effect: Dictionary in effects:
			var id := str(effect.id)
			var live := -1.0
			for buff: Dictionary in buffs:
				if buff.get("id") == id: live = float(buff.remaining_s)
			# A duplicate receipt cannot resurrect a locally expired effect.
			if previous.get(id) == effect.get("receipt") and live < 0.0: continue
			var remaining := minf(live, float(effect.remaining_s)) if live >= 0.0 and previous.get(id) == effect.get("receipt") else float(effect.remaining_s)
			if remaining > 0.0: member.call("apply_buff", id, str(effect.stat), float(effect.scale), remaining)
			previous[id] = effect.receipt
		member.set_meta("tether_tonic_projection", {"context": context, "version": int(row.version), "receipts": previous})
	return true

func _install_owner_tether_tonic(player: RefCounted, row: Dictionary) -> bool:
	if row.get("action") != "tether_item": return true
	var buff: Dictionary = preload("res://scripts/world/death_satchel_rules.gd").db().call("definition",
		str(row.intent.effect.item_id)).get("creature_buff", {})
	if buff.is_empty(): return true
	var uid := str(row.intent.effect.creature_uid)
	for member: RefCounted in player.party.call("members"):
		if member.get("uid") != uid: continue
		var context := [_local_character_id(), _game().get("world").reward_delivery_namespace, _altar_current_epoch()]
		var seen: Dictionary = member.get_meta("tether_tonic_projection", {})
		var receipts: Dictionary = seen.get("receipts", {}) if seen.get("context") == context else {}
		if receipts.get(str(buff.id)) == row.receipt: return true
		# Recovery history has no new actual BOOL-save edge and cannot regrant it.
		if _owner_training_retry.get("receipt") != row.receipt or _owner_training_retry.get("saved") != true: return true
		if member.call("apply_buff", str(buff.id), str(buff.stat), float(buff.scale), float(buff.duration_s)) != true: return false
		receipts[str(buff.id)] = row.receipt
		member.set_meta("tether_tonic_projection", {"context": context, "version": -1, "receipts": receipts})
		return true
	return false


func _finalize_tether_item_row(row: Dictionary) -> bool:
	for director: Node in _foundation_directors_under(_foundation_realm_roots()):
		if not _ordinary_combat_director_live(director): continue
		if director.call("finalize_saved_tether_item", row) != true: return false
	return true


## One validated owner result outlives replacement of the per-character world
## row by a later station action. It is presentation correlation, never state.
var _tether_item_saved_result: Dictionary = {}

func tether_item_owner_result_saved(result: Dictionary) -> bool:
	var game := _game()
	if game == null or not game.get("local") is RefCounted or not game.get("world") is RefCounted:
		_tether_item_saved_result.clear()
		return false
	if _tether_item_saved_result.is_empty(): return false
	var proof: Dictionary = _tether_item_saved_result
	if proof.player.get_ref() != game.get("local") or proof.world.get_ref() != game.get("world") \
		or proof.world_namespace != game.get("world").reward_delivery_namespace \
		or proof.world_id != game.get("world").world_id or proof.epoch != _altar_current_epoch():
		_tether_item_saved_result.clear()
		return false
	return result == proof.result and game.get("local").character_id == result.get("character_id") \
		and game.get("local").redesign_character.transaction_receipts.has(result.get("receipt"))


func _training_decision(peer: int, row: Dictionary) -> Dictionary:
	var world: RefCounted = _game().get("world")
	if not TRAINING_WORLD.training_row_valid(row, world.reward_delivery_namespace, world.world_id) \
			or row.character_id != _authority_character(peer) \
			or not ESSENCE._equivalent(world.reward_deliveries.get(row.delivery_id), row):
		return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	if row.status != "accepted" or (is_host() and _character_authority.call("creature_training_is_pending", str(row.character_id)) == true):
		return {"ok": false, "resolved": false, "durable": true, "saved": false,
			"receipt": row.receipt, "code": "awaiting_saved_decision"}
	if peer == local_peer_id() and not _game().get("local").redesign_character.transaction_receipts.has(row.receipt):
		return {"ok": false, "resolved": false, "code": "decision_unavailable"}
	return {"ok": true, "resolved": true, "durable": true, "saved": true, "receipt": row.receipt,
		"character_revision": row.character_revision, "journal_revision": row.journal_revision}


func _deliver_training_decision(peer: int, row: Dictionary) -> void:
	if not is_host(): return
	OPENING_HOME_KEY.accepted(self, peer, row)
	if row.get("action") == "waystone_touch": _waystone_delivery_accepted(peer, row)
	if peer == local_peer_id():
		var settled := _settle_owner_training_accepted(_game().get("local"), _game().get("world"), row)
		# A host's own homestead action (solo too) is answered "awaiting" by
		# _foundation_send and settles here; nothing else announced it, so a
		# station panel stayed on "awaiting_saved_decision" with its buttons off.
		# Guests hear theirs through _rpc_foundation_reply; groom has its own.
		var action := str(row.get("action", ""))
		if settled and (action in FOUNDATION_ACTIONS.ACTIONS or action in CHARACTER_ACTIONS.ACTIONS) and action != "groom" and _homestead_completion_once(row):
			homestead_action_completed.emit(action, (row.get("intent", {}) as Dictionary).duplicate(true), _foundation_decision(peer, row))
	elif bool(_registry.call("has", peer)):
		rpc_id(peer, "_rpc_training_decision", _altar_epoch, row.delivery_id, int(row.journal_revision), row.receipt)


## The accepted row is re-delivered by the background poll and replays, so
## its completion is announced once per receipt (review: a later toast or
## sound would otherwise repeat every poll).
var _homestead_completed_receipts: Dictionary = {}

func _homestead_completion_once(row: Dictionary) -> bool:
	var key := str(row.get("receipt", "")) + "|" + str(row.get("delivery_id", ""))
	if _homestead_completed_receipts.has(key): return false
	if _homestead_completed_receipts.size() >= 256: _homestead_completed_receipts.clear()
	_homestead_completed_receipts[key] = true
	return true


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_training_decision(epoch: String, id: String, revision: int, receipt: String) -> void:
	if is_host() or epoch != _altar_current_epoch(): return
	# Host published its saved accepted delta first on this SAME channel.
	# While bootstrap is closed that delta is queued; finish the existing path.
	if _training_bootstrap_waiting:
		_finalize_snapshot_receive()
	var row := _owner_training_row()
	if row.get("delivery_id") == id and row.get("journal_revision") == revision and row.get("receipt") == receipt:
		var settled := _settle_owner_training_accepted(_game().get("local"), _game().get("world"), row)
		# The guest's _rpc_foundation_reply carried only the host's immediate
		# "awaiting" marker; this saved settlement is the terminal answer its
		# station panel waits for (groom keeps its own completion path).
		var action := str(row.get("action", ""))
		if settled and (action in FOUNDATION_ACTIONS.ACTIONS or action in CHARACTER_ACTIONS.ACTIONS) and action != "groom" and _homestead_completion_once(row):
			homestead_action_completed.emit(action, (row.get("intent", {}) as Dictionary).duplicate(true),
				{"ok": true, "resolved": true, "durable": true, "saved": true, "settled": true,
					"owner_saved": true, "owner_acknowledged": true, "receipt": row.receipt})


## The input-owner graph asks `_owner_training_row()` many times a frame
## (`owns_input`), and a full typed validation of every retained training row
## costs ~100 ms once a world holds any -- enough to stall a fight to seconds
## per frame. Its answer is a pure function of these inputs, so it is reused
## until any of them, the delivery map's content included, changes.
var _owner_training_row_key: Array = []
var _owner_training_row_deliveries: Dictionary = {}
var _owner_training_row_value: Dictionary = {}

## One local pending identity points at the durable row already in WorldState.
## It stores no party/inventory/balance or alternative receipt history.
func _owner_training_row() -> Dictionary:
	var game := _game()
	if game == null or not game.get("local") is RefCounted or not game.get("world") is RefCounted: return {}
	var world: RefCounted = game.get("world")
	var character := str(game.get("local").character_id)
	var key := [world.get_instance_id(), world.reward_delivery_namespace, world.world_id, character,
		world.reward_deliveries.size(), world.reward_deliveries.hash()]
	# The hash only finds the entry; the content itself must match too.
	if key != _owner_training_row_key or world.reward_deliveries != _owner_training_row_deliveries:
		_owner_training_row_value = TRAINING_WORLD.training_owner_row(world.reward_deliveries, world.reward_delivery_namespace, world.world_id, character)
		_owner_training_row_key = key
		_owner_training_row_deliveries = world.reward_deliveries.duplicate(true)
	return _owner_training_row_value.duplicate(true)


func _owner_training_mutation_blocked(player: RefCounted, ignore_untouched_groom: bool = false) -> bool:
	var game := _game()
	if game == null or player == null or player != game.get("local"): return false
	if _groom_passive != null and _groom_passive.call("blocked", player) == true \
		and not (ignore_untouched_groom and _groom_passive.call("local_untouched", player) == true): return true
	if _owner_passive != null and _owner_passive.call("blocked", player) == true: return true
	var row := _owner_training_row()
	if _pending_portal_for(str(player.character_id)): return true
	if is_host() and _character_authority.call("creature_training_is_pending", str(player.character_id)) == true:
		return true
	if row.is_empty(): return not _owner_training_retry.is_empty() # Missing recovery truth cannot unlock.
	if row.status == "pending": return true
	return not _owner_training_retry.is_empty()


## Diagnostic only: which of `_owner_training_mutation_blocked`'s holds is set.
func _owner_snapshot_block_reason(player: RefCounted, ignore_untouched_groom: bool = false) -> String:
	# Mirrors _owner_training_mutation_blocked: an untouched groom (e.g. the
	# resume opened on every snapshot apply) still holds owner mutations; a
	# save's refusal (which ignores an untouched groom) passes true.
	if _groom_passive != null and _groom_passive.call("blocked", player) == true \
		and not (ignore_untouched_groom and _groom_passive.call("local_untouched", player) == true):
		return "groom passive pending phase=%s%s" % [str((_groom_passive.get("pending") as Dictionary).get("phase", "")),
			" (untouched)" if _groom_passive.call("local_untouched", player) == true else ""]
	if _owner_passive != null and _owner_passive.call("blocked", player) == true:
		return "owner passive pending phase=%s" % str(_owner_passive.get("pending").get("phase"))
	if _pending_portal_for(str(player.get("character_id"))): return "portal pending"
	if is_host() and _character_authority.call("creature_training_is_pending", str(player.get("character_id"))) == true:
		return "host creature training pending: " + str(_character_authority.call("training_lock_reason", str(player.get("character_id"))))
	var row := _owner_training_row()
	if not row.is_empty() and row.get("status") == "pending": return "training row pending"
	if not _owner_training_retry.is_empty(): return "training retry unsaved"
	return "training row does not match the live record"


## Compose the existing input-owner and story-modal graph; closing Altar UI
## cannot unlock movement/menu/care while a real saved decision is pending.
func owns_input() -> bool:
	return _game() != null and _owner_training_mutation_blocked(_game().get("local"))


func is_open() -> bool:
	return owns_input()


## Stored child callbacks must not retain their owning PlayerState. Static
## adapters also remain fail-closed if the Session has already been freed.
static func _training_guard_live_owner(owner: WeakRef, session: WeakRef) -> RefCounted:
	var live_session: Node = session.get_ref() as Node
	var player: RefCounted = owner.get_ref() as RefCounted
	if live_session == null or player == null: return null
	var game: Node = live_session.call("_game") as Node
	return player if game != null and game.get("local") == player else null


static func _weak_training_mutation_blocked(owner: WeakRef, session: WeakRef) -> bool:
	var player := _training_guard_live_owner(owner, session)
	return player == null or session.get_ref().call("_owner_training_mutation_blocked", player) == true


static func _weak_training_inventory_write_allowed(index: int, stack: Variant, owner: WeakRef, session: WeakRef) -> bool:
	var player := _training_guard_live_owner(owner, session)
	return player != null and session.get_ref().call("_owner_training_inventory_write_allowed", index, stack, player) == true


static func _weak_training_release_write_allowed(index: int, owner: WeakRef, session: WeakRef) -> bool:
	var player := _training_guard_live_owner(owner, session)
	return player != null and session.get_ref().call("_owner_training_release_write_allowed", index, player) == true


static func _weak_training_release_rollback_allowed(snapshot: Dictionary, owner: WeakRef, session: WeakRef) -> bool:
	var player := _training_guard_live_owner(owner, session)
	return player != null and session.get_ref().call("_owner_training_release_rollback_allowed", snapshot, player) == true


func _bind_training_container_guards() -> void:
	var game := _game()
	if game == null or not game.get("local") is RefCounted: return
	var player: RefCounted = game.get("local")
	var owner_ref: WeakRef = weakref(player)
	var session_ref: WeakRef = weakref(self)
	var inv: Variant = player.get("inventory")
	var party: Variant = player.get("party")
	if inv is RefCounted and inv.has_method("bind_owner_mutation_guard"):
		inv.call("bind_owner_mutation_guard", _weak_training_mutation_blocked.bind(owner_ref, session_ref),
			_weak_training_inventory_write_allowed.bind(owner_ref, session_ref))
	if party is RefCounted and party.has_method("bind_owner_mutation_guard"):
		party.call("bind_owner_mutation_guard", _weak_training_mutation_blocked.bind(owner_ref, session_ref),
			_weak_training_release_write_allowed.bind(owner_ref, session_ref), _weak_training_release_rollback_allowed.bind(owner_ref, session_ref), _weak_capture_roster_allowed.bind(owner_ref, session_ref))


func _retain_owner_training_retry(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	var game := _game()
	if game == null or game.get("local") != player or game.get("world") != world \
			or not ESSENCE._equivalent(_owner_training_row(), row) or row.status != "pending": return false
	if not _owner_training_retry.is_empty() and (_owner_training_retry.player.get_ref() != player \
		or _owner_training_retry.world.get_ref() != world or _owner_training_retry.receipt != row.receipt): return false
	var capture_originals: Variant = _owner_training_retry.get("capture_originals")
	var released: Variant = _owner_training_retry.get("release_instance")
	if preload("res://scripts/net/character_record_rules.gd").training_version(row) in [2, 3] and row.get("action") in ["trait_release", "essence_release"] and released == null:
		# Bind identity while the real original instance is still owned. A weak
		# identity is not a sixth creature or a second authoritative roster.
		if ESSENCE._equivalent(preload("res://scripts/net/character_record_rules.gd").portable_projection(player.call("save_data")), row.before):
			for instance: RefCounted in player.get("party").call("members"):
				if instance.get("uid") == row.intent.creature_uid: released = weakref(instance)
	_owner_training_retry = {"player": weakref(player), "world": weakref(world),
		"delivery_id": row.delivery_id, "journal_revision": row.journal_revision, "receipt": row.receipt,
		"saved": _owner_training_retry.get("saved", false), "release_instance": released}
	if capture_originals is Array: _owner_training_retry.capture_originals = capture_originals
	if row.get("action") in ["wild_capture", "starter_choice"] and not _owner_training_retry.has("capture_originals"):
		var originals: Array = []
		for member: RefCounted in player.get("party").call("members"): originals.append(weakref(member))
		_owner_training_retry.capture_originals = originals
	_bind_training_container_guards()
	return true


func _begin_owner_training_install(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	if _owner_training_retry.is_empty() or _owner_training_retry.player.get_ref() != player \
			or _owner_training_retry.world.get_ref() != world or _owner_training_retry.receipt != row.receipt \
			or not ESSENCE._equivalent(_owner_training_row(), row): return false
	_owner_training_install = true
	return true


func _end_owner_training_install() -> void:
	_owner_training_install = false
	_owner_training_install_rollback = false


func _owner_training_inventory_write_allowed(index: int, stack: Variant, player: RefCounted) -> bool:
	if _owner_portal_inventory_write_allowed(index, stack, player): return true
	var row := _owner_training_row()
	return _owner_training_install and not _owner_training_retry.is_empty() \
		and _owner_training_retry.player.get_ref() == player and row.status == "pending" \
		and _owner_training_retry.receipt == row.receipt and index >= 0 and index < row.after.inventory.size() \
		and ESSENCE._equivalent((row.before if _owner_training_install_rollback else row.after).inventory[index], stack)


func _mark_owner_training_saved(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	if _owner_training_retry.is_empty() or _owner_training_retry.player.get_ref() != player \
			or _owner_training_retry.world.get_ref() != world or _owner_training_retry.receipt != row.receipt \
			or not ESSENCE._equivalent(_owner_training_row(), row) \
			or not ESSENCE.owner_matches_after(preload("res://scripts/net/character_record_rules.gd").training_projection(player.call("save_data"), row, ESSENCE.training_projection), row.after): return false
	_owner_training_retry.saved = true
	return true


func _owner_training_snapshot_allowed(player: RefCounted, payload: Dictionary) -> bool:
	if _groom_passive != null and _groom_passive.call("snapshot_allowed", player, payload) == true: return true
	if _owner_passive != null and _owner_passive.call("snapshot_allowed", player, payload) == true: return true
	if _pending_portal_for(str(player.character_id)):
		return not _owner_portal_conflicting_transaction(player) and _owner_portal_snapshot_allowed(player, payload)
	# A groom still waiting on the host has installed nothing locally: it never
	# refuses a character save (a guest leaving mid-resume must keep its file).
	if not _owner_training_mutation_blocked(player, true): return true
	var row := _owner_training_row()
	return not row.is_empty() and payload.get("character_id") == player.get("character_id") \
		and ESSENCE.owner_matches_after(preload("res://scripts/net/character_record_rules.gd").training_projection(payload, row, ESSENCE.training_projection), row.after) \
		and payload.redesign_character.transaction_receipts.has(row.receipt)


func _settle_owner_training_accepted(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	if _game() == null or _game().get("local") != player or _game().get("world") != world \
			or row.get("status") != "accepted" or not ESSENCE._equivalent(_owner_training_row(), row) \
			or not player.redesign_character.transaction_receipts.has(row.receipt): return false
	if is_host() and _character_authority.call("creature_training_is_pending", str(player.character_id)) == true: return false
	if not _owner_training_retry.is_empty():
		if _owner_training_retry.player.get_ref() != player or _owner_training_retry.world.get_ref() != world \
			or _owner_training_retry.receipt != row.receipt or _owner_training_retry.saved != true \
			or not ESSENCE.owner_matches_after(preload("res://scripts/net/character_record_rules.gd").training_projection(player.call("save_data"), row, ESSENCE.training_projection), row.after): return false
		if not _install_owner_tether_tonic(player, row): return false
		_owner_training_retry = {}
	if row.get("action") == "tether_item":
		_tether_item_saved_result = {"player": weakref(player), "world": weakref(world),
			"world_namespace": world.reward_delivery_namespace, "world_id": world.world_id, "epoch": _altar_current_epoch(),
			"result": {"request": row.intent.request.duplicate(true), "receipt": row.receipt,
				"character_id": row.character_id, "creature_uid": row.intent.effect.creature_uid, "saved": true}}
	if _owner_passive != null: _owner_passive.call("owner_settled", row)
	_advance_personal_view_revision(row)
	if _owner_passive_altar_original.get("intent", {}).get("spend_id") == row.action_id:
		_owner_passive_altar_original.clear()
	if not _altar_spend_request.is_empty() and _altar_spend_request.get("intent", {}).get("spend_id") == row.action_id:
		var request := _altar_spend_request.duplicate(true)
		_altar_spend_request = {}
		altar_essence_spend_completed.emit(request.station_key, row.action_id,
			_training_decision(local_peer_id(), row))
	return true


func _altar_peer_in_combat(peer: int) -> bool:
	var roots := _foundation_realm_roots()
	if roots.is_empty(): return true
	var found_host := false
	for node: Node in _foundation_directors_under(roots):
		if node.has_method("pending_remote_rematch_settlement") and node.call("pending_remote_rematch_settlement") == true: return true
		# A done round and an idle manager still belong to the same trainer
		# battle during send-out. Staging mastery here can defer its owner ACK
		# into the next active round and fence the very inputs needed to finish.
		if node.get("_session") == self and node.call("trainer_battle_active") == true \
			and (node.get("_trainer_battle_participants") as Dictionary).has(peer): return true
		# Portal/station use can precede the first combat ingress. Resolve that
		# same real host arbiter before asking whether its guest is fighting.
		if is_host() and node.get("_session") == self and node.get("_encounter_host") == null:
			node.call("_ensure_encounter_arbiters")
		var host: Variant = node.get("_encounter_host")
		if host is RefCounted and host.has_method("record") and host.has_method("is_participant"):
			if host.has_method("pending_move_mastery"):
				for pending: Dictionary in host.call("pending_move_mastery"):
					if pending.peer == peer or (pending.peer is String and pending.peer == _authority_character(peer)): return true
			found_host = true
			var records: Variant = host.get("encounters")
			if not records is Dictionary: return true
			for id: Variant in records:
				var record: Variant = records[id]
				if not record is Dictionary: return true
				if record.get("phase") != "done" and host.call("is_participant", str(id), peer) == true: return true
	if peer != local_peer_id(): return not found_host
	return _foundation_local_manager_in_combat(get_tree().current_scene if is_inside_tree() else null)


## Water/Cloudreach and Stormwood inherit the production manager's state.
## Only the local scene can answer for the local owner: an idle manager in a
## hosted sibling realm must never stand in for a missing local manager.
static func _foundation_local_manager_in_combat(world: Node) -> bool:
	if not is_instance_valid(world): return true
	var found := false
	for node: Node in _foundation_group_under(FOUNDATION_COMBAT_MANAGER_GROUP, [world], FOUNDATION_COMBAT_MANAGERS):
		found = true
		if node.call("is_fighting") == true: return true
	return not found


func _training_actor_baseline_proposals(peer: int, training: Dictionary) -> Dictionary:
	var game:=_game()
	var nodes := _foundation_realm_roots()
	if not is_host() or game==null or game.get("world")==null or nodes.is_empty(): return {"ok":false}
	var world: RefCounted=game.get("world")
	var character:=_authority_character(peer)
	if character.is_empty() or character!=training.get("character_id") \
		or not TRAINING_WORLD.training_row_valid(training,world.reward_delivery_namespace,world.world_id): return {"ok":false}
	var admitted: Dictionary=_character_authority.call("state",character)
	var revision:=int(_character_authority.call("revision",character))
	var seen: Dictionary={}
	var proposals: Array[Dictionary]=[]
	# Use the same authenticated director index as the other foundation
	# retries; a training ACK must not rescan every terrain/vegetation node.
	# The helper retains the detached-fixture walk and exact script/root guards.
	for node: Node in _foundation_directors_under(nodes):
		# Normal gathering/crafting can precede the first combat ingress, which
		# otherwise creates this same sole arbiter lazily. An empty real arbiter
		# can validate the baseline without fabricating an encounter or actor.
		node.call("_ensure_encounter_arbiters")
		var host: Variant=node.get("_encounter_host")
		if not host is RefCounted or not host.has_method("stage_actor_training_baseline"): return {"ok":false}
		if seen.has(host.get_instance_id()): continue
		seen[host.get_instance_id()]=true
		var stage: Dictionary=host.call("stage_actor_training_baseline",training,admitted,revision,world.reward_delivery_namespace,world.world_id)
		if stage.get("ok")!=true: return {"ok":false,"code":stage.get("code")}
		proposals.append({"host":host,"stage":stage})
	return {"ok":not proposals.is_empty(),"proposals":proposals,"admitted":admitted,"revision":revision}

func training_actor_baseline_ready(peer: int, training: Dictionary) -> bool:
	# Also runs before Ledger's accepted World write, including recovery with
	# no live private original. Unmounted tonics cannot become accepted here.
	if not _tether_item_live_consumer_ready(training): return false
	if training.get("kind") == "altar_building": return TRAINING_WORLD.altar_build_row_valid(training, _game().get("world").reward_delivery_namespace, _game().get("world").world_id) and training.character_id == _authority_character(peer)
	return _training_actor_baseline_proposals(peer,training).get("ok")==true


## OFF until the coherent paid placement+mounted training path is proved.
## Method presence does not authorize a free or client-priced placement.
func altar_canonical_producer_available() -> bool:
	var cfg := ESSENCE.config()
	var game := _game()
	return cfg.get("altar_runtime_enabled") is bool and cfg.altar_runtime_enabled == true \
		and cfg.get("altar_building_runtime_enabled") is bool and cfg.altar_building_runtime_enabled == true \
		and not TRAINING_WORLD.altar_recipe().is_empty() and game != null and game.get("world") != null \
		and not str(game.get("world").reward_delivery_namespace).is_empty() \
		and get_node_or_null(^"LedgerRpc") != null and game.has_method("altar_placement_is_authorized")


func altar_building_placement_available() -> bool:
	var cfg := ESSENCE.config()
	return cfg.get("altar_building_runtime_enabled") is bool and cfg.altar_building_runtime_enabled == true \
		and cfg.get("altar_runtime_enabled") is bool and cfg.altar_runtime_enabled == true \
		and not TRAINING_WORLD.altar_recipe().is_empty() and _game() != null and snapshot_ready() \
		and not _owner_training_mutation_blocked(_game().get("local")) \
		and (is_host() or cfg.get("altar_remote_spend_enabled") == true)


## Existing place/dismantle ingress calls this only after sender resolution.
## Request supplies a pose or UID, never stock, recipe, character or proposed state.
func host_altar_building(peer: int, request: Dictionary) -> Dictionary:
	var refusal := {"ok": false, "pending": false, "kind": request.get("kind", ""), "peer": peer,
		"code": "altar_not_ready", "reason": "Altar building is not ready yet.", "txn_id": request.get("txn_id", ""), "delta": {"ops": []}}
	if not is_host() or not _altar_hex_id(request.get("txn_id")) or request.get("realm") != "meadows": return refusal
	var game := _game()
	var character := _authority_character(peer)
	if game == null or character.is_empty(): return refusal
	var world: RefCounted = game.get("world")
	if not ESSENCE._integer(world.next_building_uid, 1, 2147483646): return refusal
	var id := TRAINING_WORLD.altar_build_id(world.reward_delivery_namespace, character, request.txn_id)
	var prior: Variant = world.reward_deliveries.get(id)
	if prior is Dictionary:
		# Reconcile the frozen ID before probing a now-removed building or stock.
		if not TRAINING_WORLD.altar_build_row_valid(prior, world.reward_delivery_namespace, world.world_id) \
			or not ESSENCE._equivalent(prior.intent.request, request):
			refusal.code = "building_receipt_conflict"
			return refusal
		var transport := get_node_or_null(^"LedgerRpc")
		if transport != null: transport.call("_process_creature_training", prior)
		return {"ok": true, "pending": true, "kind": prior.action, "peer": peer, "code": "duplicate",
			"reason": "", "txn_id": prior.action_id, "uid": prior.intent.record.uid, "delta": {"ops": []}}
	if not altar_building_placement_available() or peer != local_peer_id():
		# Actual remote full-state care/buff drift remains a closed dependency.
		return refusal
	var saver: RefCounted = game.get("save_system")
	if saver == null: return refusal
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true or _authority_character(peer) != character \
		or not altar_building_placement_available() or _altar_peer_in_combat(peer) \
		or admitted_character_state(peer).is_empty(): return refusal
	var actor: Node3D = game.call("_find_player") as Node3D
	if not is_instance_valid(actor) or not actor.is_inside_tree() or not actor.global_position.is_finite() \
		or game.get("current_realm") != "meadows": return refusal
	var full: Dictionary = _character_authority.call("state", character)
	var revision := int(_character_authority.call("revision", character))
	var record: Dictionary = {}
	var placer: Node
	for node: Node in get_tree().get_nodes_in_group("build_placer"):
		if node.is_inside_tree() and get_tree().current_scene.is_ancestor_of(node) \
			and node.get_script() != null and node.get_script().resource_path == "res://scripts/build/build_placer.gd":
			if placer != null: return refusal
			placer = node
	if placer == null: return refusal
	if request.get("kind") == "place_building":
		if request.size() != 7 or request.get("id") != "altar" or request.get("paid") != true \
			or not request.get("position") is Array or request.position.size() != 3 \
			or not (request.get("yaw_deg") is int or request.get("yaw_deg") is float) \
			or not is_finite(float(request.yaw_deg)): return refusal
		for cell: Variant in request.position:
			if not (cell is int or cell is float) or not is_finite(float(cell)): return refusal
		var position := Vector3(float(request.position[0]), float(request.position[1]), float(request.position[2]))
		var inv := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(full.inventory)
		var plan: Dictionary = placer.call("validate_altar_placement", game, "meadows", position, float(request.yaw_deg), inv, actor)
		if plan.get("ok") != true or not ESSENCE._equivalent(plan.get("cost"), TRAINING_WORLD.altar_recipe()): return refusal
		record = {"id": "altar", "realm": "meadows", "uid": "b%d" % int(world.next_building_uid),
			"position": plan.position.duplicate(true), "yaw_deg": plan.yaw_deg, "paid": true}
	elif request.get("kind") == "dismantle":
		if request.size() != 4 or not request.get("uid") is String: return refusal
		var key: String = "altar:meadows:" + request.uid
		var weak: WeakRef = _altar_stations.get(key)
		var building := weak.get_ref() as Node3D if weak != null else null
		if not is_instance_valid(building) or not _altar_station_for_peer(peer, key): return refusal
		var resolved: Dictionary = placer.call("resolve_altar_station", game, key, building)
		if resolved.get("ok") != true: return refusal
		record = resolved.record.duplicate(true)
		if TRAINING_WORLD.altar_paid_provenance(world.reward_deliveries, world.reward_delivery_namespace, world.world_id, record, character).is_empty(): return refusal
	else: return refusal
	var proposal := TRAINING_WORLD.altar_build_transition(full, character, revision, request.kind,
		request.txn_id, record, world.reward_delivery_namespace)
	if proposal.is_empty():
		refusal.code = "building_stock_or_receipt_refused"
		return refusal
	var stage: Dictionary = _character_authority.call("stage_altar_building", character, proposal)
	if stage.get("ok") != true:
		refusal.code = stage.get("code", "building_stage_refused")
		return refusal
	var transport := get_node_or_null(^"LedgerRpc")
	var journal_trace := ALTAR_TRACE.begin("host.original_journal")
	var result: Dictionary = transport.call("journal_altar_building_prepared", peer, stage, request) if transport != null else {}
	ALTAR_TRACE.end("host.original_journal", journal_trace)
	var registry_trace := ALTAR_TRACE.begin("host.original_registry_finish")
	if _character_authority.call("finish_creature_training", stage, result.get("durable") == true) != true:
		ALTAR_TRACE.end("host.original_registry_finish", registry_trace, "refused")
		return refusal
	ALTAR_TRACE.end("host.original_registry_finish", registry_trace)
	if result.get("durable") != true:
		refusal.code = result.get("code", "building_journal_failed")
		return refusal
	var publication_trace := ALTAR_TRACE.begin("host.original_publish")
	transport.call("publish_altar_building", peer, character, result.delivery_id, stage.receipt)
	ALTAR_TRACE.end("host.original_publish", publication_trace)
	return result.verdict


## F31 paid Homestead stations/attachments: the same authority, world BOOL,
## owner BOOL, ACK and refund journal as the Altar, with a version-2 record.
## Host-local only for now: a guest's full-state drift is the same closed
## dependency as remote Altar building, so a guest is refused, never priced.
func homestead_building_available(id: String) -> bool:
	return HOMESTEAD_BUILDING.requires_journal(id) and is_host() and _homestead_building_ready() \
		and not HOMESTEAD_BUILDING.cost(id).is_empty()


func _homestead_building_ready() -> bool:
	var game := _game()
	return STATION_RULES.config().get("runtime_enabled") == true and game != null \
		and game.get("world") != null and not str(game.get("world").reward_delivery_namespace).is_empty() \
		and snapshot_ready() and not _owner_training_mutation_blocked(game.get("local")) \
		and get_node_or_null(^"LedgerRpc") != null


## Den removal needs the complete host projection of every resting owner.
## A solo host observes its own five; a shared world fails closed.
func homestead_validate_dismantle(uid: String) -> Dictionary:
	var game := _game()
	if game == null or not is_host() or game.get("world") == null: return STATION_RULES.deny("den_owners_unavailable")
	var target := STATION_RULES.dismantle(STATION_RULES.config(), game.get("world").placed_buildings, uid)
	if target.get("ok") != true or target.record.id != "den": return target
	if is_multi_peer() or game.get("party") == null: return STATION_RULES.validate_resting_owners(target, [], false)
	var rows: Array = []
	for creature: Variant in game.get("party").call("members"):
		if not creature is RefCounted: return STATION_RULES.deny("den_owners_unavailable")
		rows.append({"resting": bool(creature.get("resting")), "rest_bed_index": int(creature.get("rest_bed_index"))})
	return STATION_RULES.validate_resting_owners(target, [rows], true)


## Existing place/dismantle ingress calls this only after sender resolution.
## The request supplies a pose/parent or a UID, never stock, price or state.
func host_homestead_building(peer: int, request: Dictionary) -> Dictionary:
	var refusal := {"ok": false, "pending": false, "kind": request.get("kind", ""), "peer": peer,
		"code": "station_transaction_unavailable", "reason": STATION_RULES.reason("station_transaction_unavailable"),
		"txn_id": request.get("txn_id", ""), "delta": {"ops": []}}
	if not is_host() or not HOMESTEAD_BUILDING.txn_valid(request.get("txn_id")) or request.get("realm") != "meadows": return refusal
	var game := _game()
	var character := _authority_character(peer)
	if game == null or character.is_empty() or game.get("world") == null: return refusal
	var world: RefCounted = game.get("world")
	if not ESSENCE._integer(world.next_building_uid, 1, 2147483646): return refusal
	var id := HOMESTEAD_BUILDING.delivery_id(world.reward_delivery_namespace, character, request.txn_id)
	if id.is_empty(): return refusal
	var prior: Variant = world.reward_deliveries.get(id)
	if prior is Dictionary:
		# Reconcile the frozen ID before probing a now-removed building or stock.
		if not HOMESTEAD_BUILDING.row_valid(prior, world.reward_delivery_namespace, world.world_id) \
			or not ESSENCE._equivalent(prior.intent.request, request):
			refusal.code = "building_receipt_conflict"
			return refusal
		var replay := get_node_or_null(^"LedgerRpc")
		if replay != null: replay.call("_process_creature_training", prior)
		return {"ok": true, "pending": true, "kind": prior.action, "peer": peer, "code": "duplicate",
			"reason": "", "txn_id": prior.action_id, "uid": prior.intent.record.uid, "delta": {"ops": []}}
	if peer != local_peer_id():
		refusal.code = "station_host_only"
		refusal.reason = STATION_RULES.reason("station_host_only")
		return refusal
	if not _homestead_building_ready(): return refusal
	var saver: RefCounted = game.get("save_system")
	if saver == null: return refusal
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true or _authority_character(peer) != character \
		or not _homestead_building_ready() or _altar_peer_in_combat(peer) \
		or admitted_character_state(peer).is_empty(): return refusal
	var actor: Node3D = game.call("_find_player") as Node3D
	if not is_instance_valid(actor) or not actor.is_inside_tree() or not actor.global_position.is_finite() \
		or game.get("current_realm") != "meadows": return refusal
	var full: Dictionary = _character_authority.call("state", character)
	var revision := int(_character_authority.call("revision", character))
	var placer: Node
	for node: Node in get_tree().get_nodes_in_group("build_placer"):
		if node.is_inside_tree() and get_tree().current_scene.is_ancestor_of(node) \
			and node.get_script() != null and node.get_script().resource_path == "res://scripts/build/build_placer.gd":
			if placer != null: return refusal
			placer = node
	if placer == null: return refusal
	var cfg := STATION_RULES.config()
	var record: Dictionary = {}
	if request.get("kind") == "place_building":
		if request.size() != HOMESTEAD_BUILDING.PLACE_REQUEST_FIELDS.size() \
			or not HOMESTEAD_BUILDING.requires_journal(request.get("id")) or request.get("paid") != true \
			or not request.get("parent_uid") is String or not request.get("position") is Array \
			or request.position.size() != 3 or not STATION_RULES.number(request.get("yaw_deg")): return refusal
		for cell: Variant in request.position:
			if not STATION_RULES.number(cell): return refusal
		var price := HOMESTEAD_BUILDING.cost(request.id)
		if price.is_empty(): return refusal
		var position := Vector3(float(request.position[0]), float(request.position[1]), float(request.position[2]))
		var inv := preload("res://scripts/world/death_satchel_rules.gd").inventory_from(full.inventory)
		# Admitted inventory and personal attachment recipes, the actual body,
		# the canonical world records and the real ground decide; never the ghost.
		var plan: Dictionary = placer.call("validate_station_placement", game, request.id, "meadows", position,
			float(request.yaw_deg), inv, actor, full.redesign_character, request.parent_uid)
		if plan.get("ok") != true:
			refusal.code = str(plan.get("code", refusal.code))
			refusal.reason = STATION_RULES.reason(refusal.code)
			return refusal
		if not ESSENCE._equivalent(plan.get("cost"), price) or plan.get("parent_uid") != request.parent_uid: return refusal
		record = {"id": request.id, "realm": "meadows", "uid": "b%d" % int(world.next_building_uid),
			"position": plan.position.duplicate(true), "yaw_deg": float(plan.yaw_deg), "paid": true,
			"parent_uid": str(plan.parent_uid), "slot": int(plan.slot)}
	elif request.get("kind") == "dismantle":
		if request.size() != HOMESTEAD_BUILDING.DISMANTLE_REQUEST_FIELDS.size() \
			or not HOMESTEAD_BUILDING.uid_valid(request.get("uid")): return refusal
		var legal := STATION_RULES.dismantle(cfg, world.placed_buildings, request.uid)
		if legal.get("ok") == true and legal.record.id == "den": legal = homestead_validate_dismantle(request.uid)
		if legal.get("ok") != true:
			refusal.code = str(legal.get("code", refusal.code))
			refusal.reason = STATION_RULES.reason(refusal.code)
			return refusal
		if not HOMESTEAD_BUILDING.record_valid(legal.record):
			refusal.code = "unproved_paid_station"
			return refusal
		var building: Node3D
		for node: Node in get_tree().get_nodes_in_group("placed_building"):
			if node.get_meta("building_uid", "") != request.uid or not get_tree().current_scene.is_ancestor_of(node): continue
			if building != null: return refusal
			building = node as Node3D
		var key := "%s:meadows:%s" % [legal.record.id, request.uid]
		if not is_instance_valid(building) or placer.call("resolve_station", game, key, building).get("ok") != true \
			or actor.global_position.distance_to(building.global_position) > float(cfg.get("maximum_place_distance_m", 0)): return refusal
		record = legal.record.duplicate(true)
		if TRAINING_WORLD.altar_paid_provenance(world.reward_deliveries, world.reward_delivery_namespace, world.world_id, record, character).is_empty():
			refusal.code = "unproved_paid_station"
			return refusal
	else: return refusal
	var proposal := HOMESTEAD_BUILDING.transition(full, character, revision, request.kind,
		request.txn_id, record, world.reward_delivery_namespace)
	if proposal.is_empty():
		refusal.code = "building_stock_or_receipt_refused"
		refusal.reason = STATION_RULES.reason("station_materials")
		return refusal
	var stage: Dictionary = _character_authority.call("stage_altar_building", character, proposal)
	if stage.get("ok") != true:
		refusal.code = stage.get("code", "building_stage_refused")
		return refusal
	var transport := get_node_or_null(^"LedgerRpc")
	var result: Dictionary = transport.call("journal_altar_building_prepared", peer, stage, request) if transport != null else {}
	if _character_authority.call("finish_creature_training", stage, result.get("durable") == true) != true:
		return refusal
	if result.get("durable") != true:
		refusal.code = result.get("code", "building_journal_failed")
		return refusal
	transport.call("publish_altar_building", peer, character, result.delivery_id, stage.receipt)
	return result.verdict


## Cost/refund-only owner import. Party/body objects are never replaced or
## rewritten by a building delivery. Every replay still performs a bool save.
func apply_altar_building_owner(row: Dictionary) -> Dictionary:
	var game := _game()
	var saver: RefCounted = game.get("save_system") if game != null else null
	if saver == null or not saver.has_method("save_character_prepared"): return {"ok": false}
	var fallback_trace := ALTAR_TRACE.begin("owner.finish_fallback")
	saver.call("finish_fallback")
	ALTAR_TRACE.end("owner.finish_fallback", fallback_trace)
	if saver.call("fallback_busy") == true or game != _game(): return {"ok": false}
	var player: RefCounted = game.get("local")
	var world: RefCounted = game.get("world")
	var validate_trace := ALTAR_TRACE.begin("owner.canonical_row")
	if not TRAINING_WORLD.altar_build_row_valid(row, world.reward_delivery_namespace, world.world_id) \
		or row.character_id != player.get("character_id") or row.status != "pending" \
		or not ESSENCE._equivalent(world.reward_deliveries.get(row.delivery_id), row):
		ALTAR_TRACE.end("owner.canonical_row", validate_trace, "refused")
		return {"ok": false}
	ALTAR_TRACE.end("owner.canonical_row", validate_trace)
	var snapshot_trace := ALTAR_TRACE.begin("owner.original_snapshot")
	var snapshot: Dictionary = player.call("save_data")
	var projected := ESSENCE.training_projection(snapshot)
	ALTAR_TRACE.end("owner.original_snapshot", snapshot_trace)
	var applied: bool = snapshot.redesign_character.transaction_receipts.has(row.receipt)
	if not ESSENCE._equivalent(projected, row.after if applied else row.before): return {"ok": false}
	var retention_trace := ALTAR_TRACE.begin("owner.bind_original_retry")
	if not _retain_owner_training_retry(player, world, row) or not _begin_owner_training_install(player, world, row):
		ALTAR_TRACE.end("owner.bind_original_retry", retention_trace, "refused")
		return {"ok": false}
	ALTAR_TRACE.end("owner.bind_original_retry", retention_trace)
	var install_trace := ALTAR_TRACE.begin("owner.original_install")
	if not applied:
		for index: int in row.after.inventory.size():
			var stack: Variant = row.after.inventory[index]
			if not ESSENCE._equivalent(snapshot.inventory[index], stack):
				player.get("inventory").call("set_slot", index, stack.duplicate(true) if stack is Dictionary else null)
		player.set("redesign_character", row.after.redesign_character.duplicate(true))
	_end_owner_training_install()
	ALTAR_TRACE.end("owner.original_install", install_trace)
	var owner_save_trace := ALTAR_TRACE.begin("owner.original_projection_and_bool_write")
	if not ESSENCE._equivalent(ESSENCE.training_projection(player.call("save_data")), row.after) \
		or saver.call("save_character_prepared", game, str(player.character_id)) != true:
		ALTAR_TRACE.end("owner.original_projection_and_bool_write", owner_save_trace, "projection_or_bool_refused")
		return {"ok": false, "pending": true, "code": "owner_building_save_failed"}
	ALTAR_TRACE.end("owner.original_projection_and_bool_write", owner_save_trace, "saved")
	var marker_trace := ALTAR_TRACE.begin("owner.mark_original_saved")
	if not _mark_owner_training_saved(player, world, row):
		ALTAR_TRACE.end("owner.mark_original_saved", marker_trace, "refused")
		return {"ok": false, "saved": true}
	ALTAR_TRACE.end("owner.mark_original_saved", marker_trace)
	return {"ok": true, "saved": true}

## Actual owning world and SAME prepared writers, including offline solo.
## Presence alone is not capability: the coherent runtime opt-in stays OFF.
func _host_wild_training_context() -> Dictionary:
	var unavailable := {"ready": false}
	var game := _game()
	var cfg := ESSENCE.config()
	if not is_host() or game == null or game.get("session") != self \
		or not cfg.get("wild_victory_runtime_enabled") is bool or cfg.wild_victory_runtime_enabled != true \
		or not game.get("world") is RefCounted or not game.get("local") is RefCounted \
		or not _bind_character_authority(): return unavailable
	var world: RefCounted = game.get("world")
	var saver: RefCounted = game.get("save_system")
	var transport := get_node_or_null(^"LedgerRpc")
	if saver == null or not saver.has_method("save_world_prepared") \
		or not saver.has_method("save_character_prepared") or transport == null \
		or not transport.has_method("journal_creature_training_prepared") \
		or not ESSENCE._opaque_id(world.get("world_id")) \
		or not ESSENCE._opaque_id(world.get("reward_delivery_namespace")) \
		or not ESSENCE._opaque_id(_altar_epoch): return unavailable
	return {"ready": true, "world_id": str(world.world_id),
		"world_namespace": str(world.reward_delivery_namespace), "session_id": _altar_epoch}


## Resolve the real mounted runtime's ORIGINAL retained capture, never a
## claimed dead enemy/participant packet. Combat owns this read-only seam.
## Missing source/lifecycle producer closes this actual door.
func _retained_host_wild_source(frozen: Dictionary) -> Dictionary:
	var context := _host_wild_training_context()
	if context.get("ready") != true or get_tree().current_scene == null \
		or frozen.get("world_id") != context.world_id \
		or frozen.get("world_namespace") != context.world_namespace \
		or frozen.get("session_id") != context.session_id \
		or not frozen.get("record") is Dictionary: return {}
	var id: Variant = frozen.record.get("encounter_id")
	if not id is String or id.is_empty(): return {}
	var nodes: Array[Node] = [get_tree().current_scene]
	var found: Dictionary = {}
	while not nodes.is_empty():
		var node: Node = nodes.pop_back()
		for child: Node in node.get_children(): nodes.append(child)
		if node.get_script() == null or not FOUNDATION_DIRECTORS.has(node.get_script().resource_path): continue
		if not node.has_method("host_wild_victory_source"): continue
		var retained: Variant = node.call("host_wild_victory_source", id)
		if not retained is Dictionary or not ESSENCE._equivalent(retained, frozen): continue
		if not found.is_empty(): return {} # Never resolve an ambiguous host.
		var host: Variant = node.get("_encounter_host")
		if not host is RefCounted or not host.has_method("record"): return {}
		var current: Dictionary = host.call("record", id)
		if current.get("phase") != "done" or current.get("kind") != "wild" \
			or not current.get("opponent") is Dictionary or not frozen.record.get("opponent") is Dictionary \
			or not ESSENCE._equivalent(current.opponent, frozen.record.opponent) \
			or not current.get("participants") is Dictionary: return {}
		# Departure may move lifetime records to the existing retained map;
		# initial solo scope intentionally requires the actual current owner.
		found = {"director": node, "host": host, "current": current}
	return found


## Host-internal only; no reward RPC and no new source/balance store. The
## combat runtime retains ORIGINAL source through refusal, disconnect and
## terminal rendering. Existing saved rows are the only durable recovery.
func _commit_host_wild_victory(frozen: Dictionary) -> Dictionary:
	var refused := {"ok": false, "durable": false, "resolved": false, "code": "wild_training_unavailable"}
	var source := _retained_host_wild_source(frozen)
	if source.is_empty() or not frozen.get("record", {}).get("participants") is Dictionary \
		or not frozen.get("deployments") is Array: return refused
	var participants: Dictionary = frozen.record.participants
	# Every guest participant's share is retained FIRST, as its own durable
	# owner duty (the owner-passive gate, owner save and ACK), so the host's
	# own row below never pays the host and silently drops a peer.
	var guests := _journal_guest_wild_defeats(frozen, source.get("current", {}))
	if guests.get("durable") != true: return guests
	if not participants.has(local_peer_id()):
		return {"ok": true, "durable": true, "resolved": true, "code": "guest_shares_retained"}
	var peer := local_peer_id()
	var character := _authority_character(peer)
	var participant: Variant = participants[peer]
	if character.is_empty() or not participant is Dictionary \
		or participant.get("character_id") != character: return refused
	var game := _game()
	var saver: RefCounted = game.get("save_system")
	if saver == null: return refused
	saver.call("finish_fallback") # Callbacks before refreezing source/state.
	if saver.call("fallback_busy") == true or _authority_character(peer) != character \
		or _retained_host_wild_source(frozen).is_empty() \
		or admitted_character_state(peer).is_empty(): return refused
	var world: RefCounted = game.get("world")
	var full: Dictionary = _character_authority.call("state", character)
	var revision := int(_character_authority.call("revision", character))
	var proposal := ESSENCE.stage_captured_host_victory(full, character, revision, peer, frozen,
		ESSENCE.config(), PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
	if proposal.get("ok") != true: return proposal
	var id := ESSENCE.training_delivery_id(world.reward_delivery_namespace, character)
	var old: Variant = world.reward_deliveries.get(id)
	var transport := get_node_or_null(^"LedgerRpc")
	if proposal.get("duplicate") == true:
		# A later accepted row can supersede this original event, but only its
		# exact immutable personal receipt proves prior durable application.
		if not TRAINING_WORLD.training_row_valid(old, world.reward_delivery_namespace, world.world_id) \
			or not old.after.redesign_character.transaction_receipts.has(proposal.receipt): return refused
		if old.get("action_id") == frozen.get("source_id"):
			if old.status == "pending" and transport != null: transport.call("_process_creature_training", old)
			return {"ok": true, "durable": true, "resolved": old.status == "accepted",
				"receipt": proposal.receipt, "delivery_id": old.delivery_id}
		if old.status != "accepted": return refused
		return {"ok": true, "durable": true, "resolved": true, "receipt": proposal.receipt,
			"code": "previous_saved_event"}
	if transport == null or proposal.get("action") != "wild_defeat" \
		or proposal.get("action_id") != frozen.get("source_id"): return refused
	var committed := ESSENCE.commit_host_training(_character_authority, transport, peer, character,
		"wild_defeat", proposal.action_id, proposal.intent, proposal)
	if committed.get("durable") != true: return committed
	# Same typed owner importer/real bool-save/receipt-only ACK as Altar.
	# Return only transfer durability; completion UI never causes a second XP.
	transport.call("publish_creature_training", peer, character, committed.receipt)
	return {"ok": true, "durable": true, "resolved": false, "receipt": committed.receipt,
		"delivery_id": committed.delivery_id, "code": "awaiting_saved_decision"}

## A canonical wild victory this guest took part in has not yet DELIVERED its
## `wild_defeat_share`: still settling vitals, or journaled but not yet
## accepted into the authority record. Its other duties and requests wait, so
## nothing changes the record the share stages on in between.
func _guest_wild_share_outstanding(character: String, world: RefCounted) -> bool:
	var receipts: Array = (_character_authority.call("state", character) as Dictionary).get("redesign_character", {}).get("transaction_receipts", [])
	for raw: Variant in world.reward_deliveries.values():
		if not raw is Dictionary or raw.get("kind") != "foundation_event" or not str(raw.get("source_id", "")).begins_with("wild_xp:") \
			or not preload("res://scripts/net/foundation_event.gd").valid(raw, world.reward_delivery_namespace, world.world_id): continue
		if _wild_share_refused.has(str(raw.delivery_id) + "|" + character): continue
		for duty: Variant in raw.get("duties", []):
			if duty is Dictionary and duty.get("action") == "wild_defeat_share" and duty.get("character_id") == character \
				and not receipts.has(ESSENCE.defeat_receipt(character, duty.intent)): return true
	for director: Node in _foundation_directors_under(_foundation_realm_roots()):
		var fights: Variant = director.get("_shared_host_fights")
		if not fights is Dictionary or not director.has_method("_shared_host_fight"): continue
		for id: Variant in fights:
			var runtime: Node = director.call("_shared_host_fight", str(id))
			if runtime == null or not runtime.has_meta(&"wild_victory_source") \
				or bool(runtime.get_meta(&"wild_victory_resolved", false)): continue
			var original: Variant = runtime.get_meta(&"wild_victory_source")
			if not original is Dictionary or not original.get("record", {}).get("participants") is Dictionary: continue
			for peer: Variant in original.record.participants:
				if peer == local_peer_id() or original.record.participants[peer].get("character_id") != character: continue
				var share := preload("res://scripts/net/foundation_event.gd").identity({"world_namespace": world.reward_delivery_namespace,
					"session_id": _altar_current_epoch(), "source_id": "wild_xp:" + str(original.get("source_id", ""))})
				if not world.reward_deliveries.has(share): return true
	return false

## Retained shares the host found can never stage (event+character -> code).
var _wild_share_refused: Dictionary = {}

static func _wild_share_permanent(code: String) -> bool:
	return code in ["receipt_budget", "receipt_conflict", "owned_enemy_refused", "actual_host_wild_defeat_required",
		"not_actual_wild_defeat", "invalid_defeat_event", "invalid_defeat_identity", "invalid_defeat_participants",
		"invalid_defeat_active_uid", "invalid_defeat_XP_or_cap", "invalid_defeat_payout", "invalid_defeat",
		"defeat_schema_or_candidate_unavailable", "inventory_full"]

## F27: each guest participant of a host wild victory gets one retained
## `wild_defeat_share` duty, its event staged once here from the SAME frozen capture
## (actual killing hit, deployments, mode) against that guest's admitted
## record. Retries find the retained event and never restage it.
func _journal_guest_wild_defeats(frozen: Dictionary, live: Dictionary) -> Dictionary:
	var world: RefCounted = _game().get("world")
	var participants: Dictionary = frozen.record.participants
	var characters: Array[String] = []
	var peers: Array = participants.keys()
	peers.sort()
	for peer: Variant in peers:
		characters.append(str((participants[peer] as Dictionary).get("character_id", "")))
	var source := "wild_xp:" + str(frozen.get("source_id", ""))
	var existing := preload("res://scripts/net/foundation_event.gd").identity(
		{"world_namespace": world.reward_delivery_namespace, "session_id": _altar_current_epoch(), "source_id": source})
	if world.reward_deliveries.has(existing): return {"ok": true, "durable": true}
	var duties: Array = []
	for peer: Variant in peers:
		if peer == local_peer_id(): continue
		var character := str((participants[peer] as Dictionary).get("character_id", ""))
		var admitted: Dictionary = _character_authority.call("state", character) if not character.is_empty() else {}
		var member: Dictionary = live.get("participants", {}).get(peer, {})
		if member.is_empty(): member = live.get("retained_actor_participants", {}).get(character, {})
		var vitals: Array = WILD_ACTOR_SCOPE.settled_vitals(admitted, member) if not admitted.is_empty() else []
		# Every fight hit must already be owner-saved into the authority record,
		# so eligibility, the owner and the frozen vitals all agree. Otherwise
		# retry the whole set later; a partial set is never journaled (one
		# stamped guest would lose its award).
		if admitted.is_empty() or not ESSENCE._equivalent(WILD_ACTOR_SCOPE.settled_before(admitted, {"settled_vitals": vitals}), admitted):
			return {"ok": false, "durable": false, "resolved": false, "code": "guest_wild_vitals_settling"}
		var staged := ESSENCE.stage_captured_host_victory(admitted, character,
			int(_character_authority.call("revision", character)), int(peer), frozen,
			ESSENCE.config(), PROGRESSION.config(), TEACHING.available_moves, TEACHING.character_loadout_mirror)
		if staged.get("duplicate") == true: continue # Already holds this win's receipt.
		if staged.get("ok") != true:
			# An invalid admitted state for this event (never a transient hold).
			push_warning("[session] wild_defeat_share for %s refused: %s" % [character, str(staged.get("code", ""))])
			continue
		duties.append({"character_id": character, "action": "wild_defeat_share", "intent": staged.intent.duplicate(true),
			"context": {"source_key": source, "validated_host_outcome": "win", "defeat_event": staged.intent.duplicate(true),
				"settled_vitals": vitals, "participants": characters.duplicate(),
				"world_namespace": world.reward_delivery_namespace, "session_id": _altar_current_epoch()}})
	if duties.is_empty(): return {"ok": true, "durable": true}
	var journal: Dictionary = get_node(^"LedgerRpc").call("journal_foundation_event", source, duties)
	if journal.get("durable") != true: return {"ok": false, "durable": false, "resolved": false, "code": "guest_wild_shares_pending"}
	return journal

## Appended to the existing Session; all state remains its existing admission
## registry, WorldState.reward_deliveries and the owner's transaction receipts.
const PORTAL_POLICY := preload("res://scripts/net/portal_action_policy.gd")
const PORTAL_RECEIPT := preload("res://scripts/net/portal_delivery.gd")
var _portal_policy: RefCounted = PORTAL_POLICY.new()
var _portal_request_serial := 0
var _portal_requests: Dictionary = {}
## Touch retries are fire-and-forget: one the host never answers (e.g. its
## owner-passive gate retained it and a later retry won) would otherwise stay
## here for the session. Travel requests keep their own lifecycle.
var _portal_request_at: Dictionary = {}
const PORTAL_TOUCH_REQUEST_TTL_MS := 120000

func _prune_portal_touch_requests() -> void:
	var now := Time.get_ticks_msec()
	for id: Variant in _portal_request_at.keys():
		var frozen: Dictionary = _portal_requests.get(id, {})
		if frozen.is_empty(): _portal_request_at.erase(id)
		elif frozen.get("payload", {}).get("kind") == "waystone_touch" and now - int(_portal_request_at[id]) > PORTAL_TOUCH_REQUEST_TTL_MS:
			_portal_requests.erase(id)
			_portal_request_at.erase(id)
var _portal_waiters: Dictionary = {}


func portal_runtime_ready() -> bool:
	return config().get("redesign_portal_runtime_enabled", false) == true


func portal_character_state() -> Dictionary:
	var game := _game()
	if game == null or game.get("local") == null: return {}
	var player: RefCounted = game.get("local")
	return {"character_id": player.character_id,
		"waystones_activated": player.redesign_character.waystones_activated.duplicate(true),
		"last_waystones": player.redesign_character.last_waystones.duplicate(true)}


func portal_view(arch_id: String) -> Dictionary:
	var unavailable := {"ready": false, "open": false, "has_key": false, "fifth_arch_stirred": false}
	var game := _game()
	if not portal_runtime_ready() or game == null or game.get("local") == null or game.get("world") == null: return unavailable
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/portals.json"))
	if not raw is Dictionary: return unavailable
	var arch := PORTAL_POLICY._find_arch(raw, arch_id)
	if arch.is_empty(): return unavailable
	return preload("res://scripts/net/portal_view.gd").build(game.get("local"), game.get("world"), arch)


func request_portal_action(payload: Dictionary) -> Dictionary:
	if not portal_runtime_ready() or not PORTAL_POLICY.valid_payload(payload): return {"ok": false, "reason": "Travel is not ready yet."}
	var game := _game()
	if game == null or game.get("world") == null or game.get("local") == null: return {"ok": false, "reason": "Your character is not ready."}
	var world: RefCounted = game.get("world")
	var character := str(game.get("local").character_id)
	var generation := _altar_current_epoch()
	if character.is_empty() or world.reward_delivery_namespace.is_empty() or generation.is_empty(): return {"ok": false, "reason": "Your character is still joining."}
	_portal_request_serial += 1
	var id := "%s:%d" % [generation, _portal_request_serial]
	var frozen := {"request_id": id, "world_instance_id": world.reward_delivery_namespace,
		"session_epoch": generation, "character_id": character, "payload": payload.duplicate(true)}
	_prune_portal_touch_requests()
	_portal_requests[id] = frozen.duplicate(true)
	_portal_request_at[id] = Time.get_ticks_msec()
	if is_host(): _host_portal_action.call_deferred(local_peer_id(), frozen)
	else: _send_portal_action.call_deferred(frozen)
	return {"ok": true, "request_id": id}


func _send_portal_action(frozen: Dictionary) -> void:
	if is_host() or not is_active() or frozen.session_epoch != _altar_current_epoch(): return
	# Publish the registered owner's current lifecycle immediately before the
	# action on the same reliable channel. A previous safe sample cannot mask
	# damage, a new modal or a traversal change occurring on this frame.
	var lifecycle := get_node_or_null(^"FoundationComposition/TravelLifecycle")
	if lifecycle == null or lifecycle.call("publish_now") != true:
		_receive_portal_reply({"ok": false, "reason": "Your travel state is not ready.", "request_id": frozen.request_id,
			"kind": frozen.payload.kind, "character_id": frozen.character_id,
			"world_instance_id": frozen.world_instance_id, "session_epoch": frozen.session_epoch})
		return
	rpc_id(HOST_PEER_ID, "_rpc_portal_action", frozen.duplicate(true))


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_portal_action(envelope: Dictionary) -> void:
	if is_host(): _host_portal_action(multiplayer.get_remote_sender_id(), envelope)

func send_portal_owner_permit(producer: Node, peer: int, envelope: Dictionary, permit: Dictionary) -> void:
	if not is_host() or producer != get_node_or_null(^"FoundationComposition/PortalArrival") \
		or peer == local_peer_id() or not _portal_envelope_valid(peer, envelope): return
	rpc_id(peer, "_rpc_portal_owner_permit", envelope, permit)

func portal_owner_travel_started(producer: Node, envelope: Dictionary, permit: Dictionary) -> bool:
	# Presentation handoff only: the original request remains pending until
	# ordinary supported contact, portable bool-save and accepted host ACK.
	if producer == null or producer != get_node_or_null(^"FoundationComposition/PortalArrival") \
		or _portal_requests.get(envelope.get("request_id"), {}) != envelope \
		or not envelope.get("payload") is Dictionary \
		or envelope.get("payload", {}).get("kind") != "home_key_finish" \
		or producer.call("presentation_binding", envelope, permit) != true: return false
	var key := _game().get_node_or_null(^"HomeKey")
	if key != null: return await key.call("travel_started", str(envelope.request_id))
	return false

func portal_owner_save_waiting(producer: Node, envelope: Dictionary, permit: Dictionary) -> void:
	if producer == null or producer != get_node_or_null(^"FoundationComposition/PortalArrival") \
		or _portal_requests.get(envelope.get("request_id"), {}) != envelope \
		or not envelope.get("payload") is Dictionary or envelope.payload.get("kind") != "home_key_finish" \
		or producer.call("presentation_binding", envelope, permit, true) != true: return
	var key := _game().get_node_or_null(^"HomeKey")
	if key != null: key.call("save_waiting", str(envelope.request_id))

@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_portal_owner_permit(envelope: Dictionary, permit: Dictionary) -> void:
	if is_host() or not is_active() or not portal_runtime_ready() \
		or _portal_requests.get(envelope.get("request_id"), {}) != envelope \
		or envelope.get("session_epoch") != _altar_current_epoch() \
		or envelope.get("character_id") != _local_character_id() \
		or envelope.get("world_instance_id") != _game().get("world").reward_delivery_namespace \
		or envelope.get("payload", {}).get("kind") not in ["home_key_finish", "portal_enter"] \
		or permit.size() != 7 or permit.get("peer_id") != local_peer_id() \
		or permit.get("character_id") != envelope.character_id or permit.get("world_instance_id") != envelope.world_instance_id \
		or not permit.get("request_id") is String or permit.request_id.is_empty() \
		or not permit.get("origin_realm") is String or permit.origin_realm != _local_realm() \
		or permit.get("realm") not in ["meadows", "water", "cloudreach", "stormwood"] \
		or not permit.get("entry_id") is String or permit.entry_id.is_empty(): return
	var arrival := get_node_or_null(^"FoundationComposition/PortalArrival")
	if arrival != null: arrival.call("owner_travel", self, envelope, permit)

func report_portal_owner_saved(producer: Node, envelope: Dictionary, permit_id: String) -> void:
	if is_host() or not is_active() or producer != get_node_or_null(^"FoundationComposition/PortalArrival") \
		or _portal_requests.get(envelope.get("request_id"), {}) != envelope: return
	rpc_id(HOST_PEER_ID, "_rpc_portal_owner_notice", envelope, permit_id, "")

func report_portal_owner_refused(producer: Node, envelope: Dictionary, permit_id: String, reason: String) -> void:
	if is_host() or not is_active() or producer != get_node_or_null(^"FoundationComposition/PortalArrival") \
		or _portal_requests.get(envelope.get("request_id"), {}) != envelope or reason.is_empty(): return
	rpc_id(HOST_PEER_ID, "_rpc_portal_owner_notice", envelope, permit_id, reason.left(192))

@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_portal_owner_notice(envelope: Dictionary, permit_id: String, refused: String) -> void:
	var peer: int = multiplayer.get_remote_sender_id()
	if not is_host() or permit_id.length() > 192 or refused.length() > 192 or not _portal_envelope_valid(peer, envelope): return
	var arrival := get_node_or_null(^"FoundationComposition/PortalArrival")
	if arrival != null: arrival.call("owner_notice", peer, envelope, permit_id, refused)


func _portal_envelope_valid(peer: int, envelope: Dictionary) -> bool:
	var game := _game()
	return (is_host() and portal_runtime_ready() and game != null and game.get("world") != null and
		envelope.size() == 5 and envelope.get("request_id") is String and envelope.request_id.length() <= 192 and
		envelope.request_id.begins_with(_altar_epoch + ":") and envelope.get("session_epoch") == _altar_epoch and
		envelope.get("character_id") == _authority_character(peer) and not str(envelope.character_id).is_empty() and
		envelope.get("world_instance_id") == game.get("world").reward_delivery_namespace and
		envelope.get("payload") is Dictionary and PORTAL_POLICY.valid_payload(envelope.payload))


func _host_portal_action(peer: int, envelope: Dictionary) -> void:
	if not _portal_envelope_valid(peer, envelope): return
	var arrival := get_node_or_null(^"FoundationComposition/PortalArrival")
	if arrival != null and arrival.call("original_pending", peer, envelope) == true: return # Existing exact permit/checkpoint owns retries.
	var context := _host_portal_context(peer)
	if context.is_empty():
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your authoritative travel state is not ready."})
		return
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/portals.json"))
	var stones: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/waystones.json"))
	if not cfg is Dictionary or not stones is Dictionary: return
	_portal_policy.call("bind_world", envelope.world_instance_id)
	var prior_channels: Array[Dictionary] = _portal_policy.call("open_channels")
	var result: Dictionary = _portal_policy.call("evaluate", envelope.payload.duplicate(true), context, cfg, stones, Time.get_ticks_msec())
	var channels := get_node_or_null(^"FoundationComposition/HomeKeyChannels")
	if result.get("ok") != true:
		if channels != null:
			var remaining: Array[Dictionary] = _portal_policy.call("open_channels")
			for row: Dictionary in prior_channels:
				if row.character_id == envelope.character_id and not remaining.has(row): channels.call("ended", row)
		_portal_reply(peer, envelope, result)
		return
	if channels != null: channels.call("approved", peer, envelope, result, str(context.realm))
	match str(envelope.payload.kind):
		"portal_unlock":
			_commit_portal_unlock(peer, envelope, result.prepared)
		"waystone_touch":
			_commit_waystone_touch(peer, envelope, result.prepared)
		"home_key_begin", "home_key_cancel":
			_portal_reply(peer, envelope, result)
		"home_key_finish", "portal_enter":
			var consumer := get_node_or_null(^"FoundationComposition/PortalArrival")
			if consumer == null: _portal_reply(peer, envelope, {"ok": false, "reason": "The arrival service is unavailable."})
			else: consumer.call("travel", self, peer, envelope.duplicate(true), result.duplicate(true))


func _commit_portal_unlock(peer: int, envelope: Dictionary, result: Dictionary) -> void:
	var game := _game()
	var saver: RefCounted = game.get("save_system")
	if saver == null or not bool(saver.call("finish_fallback")) or saver.call("fallback_busy") == true:
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your save is still being written."})
		return
	# Flush can deliver callbacks, so re-read all current binding/state before
	# freezing the debit; no mutable envelope survives across that callback.
	if not _portal_envelope_valid(peer, envelope) or _host_portal_context(peer).is_empty(): return
	var receipt := PORTAL_RECEIPT.receipt(envelope.world_instance_id, result.biome, envelope.character_id)
	var existing: Variant = game.get("world").reward_deliveries.get(receipt)
	var ledger: Node = get_node_or_null("LedgerRpc")
	if ledger == null: return
	_portal_waiters[receipt] = {"peer": peer, "envelope": envelope.duplicate(true)}
	if PORTAL_RECEIPT.valid(existing, envelope.character_id, envelope.world_instance_id):
		ledger.call("publish_portal_delivery", peer, envelope.character_id, receipt)
		if existing.status == "accepted": _portal_delivery_accepted(peer, existing)
		return
	var stage := host_stage_portal_debit(peer, result.biome, receipt)
	if stage.get("ok") != true or stage.get("duplicate") == true or not host_commit_portal_debit(stage):
		if stage.get("ok") == true and stage.get("duplicate") != true: host_finish_portal_debit(stage, false)
		_portal_waiters.erase(receipt)
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your protected key is not ready to spend."})
		return
	var journal: Dictionary = ledger.call("journal_portal_delivery_prepared", peer, envelope.character_id, result.biome, int(stage.key_slot))
	var saved: Variant = journal.get("ok") == true and journal.get("durable") == true
	host_finish_portal_debit(stage, saved)
	if not saved:
		_portal_waiters.erase(receipt)
		_portal_reply(peer, envelope, {"ok": false, "reason": "The portal could not save. Your key is safe."})
		return
	ledger.call("publish_portal_delivery", peer, envelope.character_id, receipt)


func _portal_delivery_accepted(peer: int, row: Dictionary) -> void:
	var game_now := _game()
	if peer != local_peer_id() and row.get("status") == "accepted" and game_now != null \
		and PORTAL_RECEIPT.equivalent(game_now.get("world").reward_deliveries.get(row.get("receipt")), row):
		_character_authority.call("promote_settled_portal_marker", _authority_character(peer), row)
	var waiter: Dictionary = _portal_waiters.get(row.get("receipt"), {})
	if waiter.is_empty() or waiter.peer != peer or not _portal_envelope_valid(peer, waiter.envelope): return
	var game := _game()
	var canonical: Variant = game.get("world").reward_deliveries.get(row.receipt)
	if row.status != "accepted" or not PORTAL_RECEIPT.equivalent(canonical, row): return
	_portal_waiters.erase(row.receipt)
	_portal_reply(peer, waiter.envelope, {"ok": true, "durable": true, "receipt": row.receipt,
		"biome": row.biome, "arch_id": waiter.envelope.payload.arch_id})


func _commit_waystone_touch(peer: int, envelope: Dictionary, result: Dictionary) -> void:
	if not _portal_envelope_valid(peer, envelope): return
	# Host-local: refresh the authority record from the live save first, so the
	# staged baseline (and its revision) include this frame's care drift.
	if peer == local_peer_id() and admitted_character_state(peer).is_empty():
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your waystone could not save. Touch it again."})
		return
	var character: String = envelope.character_id
	var current: Dictionary = _character_authority.call("state", character)
	var writer := get_node_or_null(^"LedgerRpc")
	if current.is_empty() or writer == null: return
	var stone: Dictionary = result.waystone
	var world: RefCounted = _game().get("world")
	var id := ESSENCE.training_delivery_id(world.reward_delivery_namespace, character)
	var row: Dictionary = world.reward_deliveries.get(id, {})
	# Retry the saved original before considering another touch. Lost ACKs
	# never create a second mutation or replace an unsettled owner baseline.
	if row.get("action") == "waystone_touch" and row.get("intent", {}).get("waystone_id") == stone.id:
		_portal_waiters[row.receipt] = {"peer": peer, "envelope": envelope.duplicate(true),
			"first_activation": not row.before.redesign_character.waystones_activated.get(stone.biome, []).has(stone.id)}
		writer.call("_process_creature_training", row)
		if row.status == "accepted": _waystone_delivery_accepted(peer, row)
		return
	if current.redesign_character.last_waystones.get(stone.biome) == stone.id \
		and current.redesign_character.waystones_activated.get(stone.biome, []).has(stone.id):
		_portal_reply(peer, envelope, {"ok": true, "durable": true, "waystone_id": stone.id, "first_activation": false})
		return
	var touch_id: String = Crypto.new().generate_random_bytes(16).hex_encode()
	var context := {"character_id": character, "expected_revision": int(_character_authority.call("revision", character)),
		"in_range": true, "in_combat": false, "foundation_runtime_authorized": true,
		"validated_touch": true, "source_key": "waystone:" + str(stone.id), "touch_id": touch_id,
		"realm": str(stone.realm_id), "world_namespace": world.reward_delivery_namespace}
	# A guest's portable record keeps drifting (care, bond walking) between host
	# samples. Freeze and replay its exact owner inputs first, as every other
	# owner request does, so the staged before equals the owner's own baseline.
	# The touch itself commits from _owner_passive_commit_request; a retry with
	# a new envelope while that original is pending gets no second mutation.
	# Stage first, as foundation requests do: a semantic refusal (e.g. the
	# receipt limit) replies now instead of freezing the owner in a checkpoint.
	var preview: Dictionary = preload("res://scripts/net/waystone_action.gd").stage(current,
		{"waystone_id": stone.id, "touch_id": touch_id}, context)
	if preview.get("ok") != true:
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your waystone could not save. Touch it again.",
			"waystone_id": stone.id, "code": str(preview.get("code", ""))})
		return
	if peer != local_peer_id():
		var request := preload("res://scripts/net/owner_passive_preparation.gd").waystone_request(envelope)
		var ready: Dictionary = _owner_passive_service().call("action_gate", peer, "waystone_touch", request, context)
		if ready.get("ok") != true:
			if ready.get("code") not in ["owner_passive_checkpoint_pending", "owner_passive_original_pending"]:
				_portal_reply(peer, envelope, {"ok": false, "reason": "Your waystone could not save. Touch it again.",
					"code": "gate:" + str(ready.get("code", ""))})
			return
	var committed := _waystone_commit_prepared(peer, envelope, context)
	if committed.get("durable") != true:
		_portal_reply(peer, envelope, {"ok": false, "reason": "Your waystone could not save. Touch it again.",
			"code": "commit:" + str(committed.get("code", committed.get("reason", "")))})


## Stages the frozen touch with exactly the context that was (for a guest)
## checkpointed. The waiter replies to the original envelope once the owner
## save is acknowledged (_waystone_delivery_accepted).
func _waystone_commit_prepared(peer: int, envelope: Dictionary, context: Dictionary) -> Dictionary:
	if not _portal_envelope_valid(peer, envelope): return FOUNDATION_ACTIONS.deny("waystone_envelope_changed")
	var character: String = envelope.character_id
	var current: Dictionary = _character_authority.call("state", character)
	var writer := get_node_or_null(^"LedgerRpc")
	var stones: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/waystones.json"))
	if current.is_empty() or writer == null or not stones is Dictionary: return FOUNDATION_ACTIONS.deny("waystone_unavailable")
	var stone: Dictionary = PORTAL_POLICY._find_stone(stones, str(envelope.payload.waystone_id))
	if stone.is_empty(): return FOUNDATION_ACTIONS.deny("waystone_unavailable")
	var receipt := "craft:waystone_%s:%s" % [str(context.touch_id).sha256_text(), character]
	_portal_waiters[receipt] = {"peer": peer, "envelope": envelope.duplicate(true),
		"first_activation": not current.redesign_character.waystones_activated.get(stone.biome, []).has(stone.id)}
	var committed := FOUNDATION_ACTIONS.commit(_character_authority, writer, peer, character,
		int(context.expected_revision), "waystone_touch", {"waystone_id": stone.id, "touch_id": context.touch_id}, context)
	if committed.get("durable") != true: _portal_waiters.erase(receipt)
	return preload("res://scripts/net/waystone_action.gd").commit_outcome(committed)

func _waystone_delivery_accepted(peer: int, row: Dictionary) -> void:
	var waiter: Dictionary = _portal_waiters.get(row.get("receipt"), {})
	if waiter.is_empty() or waiter.peer != peer or row.get("status") != "accepted" \
		or not _portal_envelope_valid(peer, waiter.envelope): return
	var world: RefCounted = _game().get("world")
	if not ESSENCE._equivalent(world.reward_deliveries.get(row.delivery_id), row) \
		or _foundation_decision(peer, row).get("saved") != true: return
	_portal_waiters.erase(row.receipt)
	_portal_reply(peer, waiter.envelope, {"ok": true, "durable": true,
		"waystone_id": row.intent.waystone_id, "first_activation": waiter.first_activation})


func _portal_reply(peer: int, envelope: Dictionary, result: Dictionary) -> void:
	if not _portal_envelope_valid(peer, envelope): return
	if result.get("ok") != true and envelope.payload.get("kind") == "waystone_touch":
		print("[waystone] host refused peer %d %s: %s" % [peer, str(envelope.payload.get("waystone_id", "")), str(result.get("code", result.get("reason", "")))])
	var reply := result.duplicate(true)
	if reply.get("prepared") is Dictionary:
		for key: Variant in reply.prepared:
			if key not in ["request_id", "kind", "character_id", "world_instance_id", "session_epoch", "ok", "durable"]: reply[key] = reply.prepared[key]
		reply.erase("prepared")
	reply.merge({"request_id": envelope.request_id, "kind": envelope.payload.kind,
		"character_id": envelope.character_id, "world_instance_id": envelope.world_instance_id,
		"session_epoch": envelope.session_epoch}, true)
	if peer == local_peer_id(): _receive_portal_reply.call_deferred(reply)
	else: rpc_id(peer, "_rpc_portal_result", reply)


@rpc("authority", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_portal_result(reply: Dictionary) -> void:
	if not is_host(): _receive_portal_reply(reply)


func _receive_portal_reply(reply: Dictionary) -> void:
	var frozen: Dictionary = _portal_requests.get(reply.get("request_id"), {})
	var game := _game()
	if frozen.is_empty() or game == null or game.get("world") == null or game.get("local") == null: return
	if (reply.get("character_id") != frozen.character_id or reply.get("world_instance_id") != frozen.world_instance_id or
		reply.get("session_epoch") != frozen.session_epoch or reply.get("kind") != frozen.payload.kind or
		frozen.character_id != game.get("local").character_id or frozen.world_instance_id != game.get("world").reward_delivery_namespace or
		frozen.session_epoch != _altar_current_epoch()): return
	_portal_requests.erase(frozen.request_id)
	var arrival := get_node_or_null(^"FoundationComposition/PortalArrival")
	if arrival != null: arrival.call("owner_finished", reply)
	game.emit_signal("portal_action_result", reply.duplicate(true))


func _portal_world_node(realm: String) -> Node3D:
	var scene := get_tree().current_scene
	var node: Node3D = scene as Node3D if realm == _local_realm() else realms().call("shell", realm) as Node3D
	if node == null or (node.has_method("shell_build_complete") and node.call("shell_build_complete") != true): return null
	return node


## Read-only binding shared by the live indexed lookup and detached source
## controls. Tree readiness/lifetime is checked separately at every view.
static func _portal_director_owned_by(world_node: Node, owner: Node, director: Node) -> bool:
	return is_instance_valid(world_node) and is_instance_valid(owner) and is_instance_valid(director) \
		and world_node.is_ancestor_of(director) and director.get_script() != null \
		and FOUNDATION_DIRECTORS.has(director.get_script().resource_path) \
		and director.get("_session") == owner and director.has_method("trainer_battle_active") \
		and director.has_method("encounter_record")


func _portal_world_directors(world_node: Node3D) -> Array[Node]:
	var result: Array[Node] = []
	if not is_instance_valid(world_node) or not world_node.is_inside_tree() or world_node.is_queued_for_deletion() \
		or world_node.get_tree() != get_tree() or world_node != _portal_world_node(_local_realm()): return result
	# Actual base Director registers on every enter_tree, inherited by all
	# approved regional Directors. SceneTree drops departed/freed members;
	# late/replacement Directors appear without caching a prior combat answer.
	for director: Node in get_tree().get_nodes_in_group(&"foundation_portal_directors"):
		if not director.is_inside_tree() or director.is_queued_for_deletion() \
			or director.get_tree() != get_tree() or not _portal_director_owned_by(world_node, self, director): continue
		result.append(director)
	return result


func _host_portal_context(peer: int) -> Dictionary:
	if not is_host() or not portal_runtime_ready(): return {}
	var admitted := admitted_character_state(peer)
	if admitted.is_empty(): return {}
	if peer != local_peer_id():
		var lifecycle := get_node_or_null(^"FoundationComposition/TravelLifecycle")
		return lifecycle.call("host_context", peer) if lifecycle != null else {}
	var game := _game()
	var player := game.call("find_player") as CharacterBody3D
	var realm := _local_realm()
	var world_node := _portal_world_node(realm)
	if player == null or world_node == null or not player.is_inside_tree() or player.is_queued_for_deletion() \
		or not world_node.is_ancestor_of(player): return {}
	var swim: Node = player.get("swim_controller")
	var fly: Node = player.get("fly_controller")
	var downed := game.get_node_or_null("DownedState")
	var vitals: RefCounted = player.get("vitals")
	var swimming := preload("res://scripts/net/foundation_travel_lifecycle.gd").swimming_observation(realm, swim)
	if swimming.is_empty() or fly == null or downed == null or vitals == null: return {}
	var input_owner := preload("res://scripts/ui/input_owner.gd").current(get_tree())
	var key := game.get_node_or_null("HomeKey")
	var dialogue := false
	var cutscene := input_owner != null and input_owner != key
	for node: Node in get_tree().get_nodes_in_group("progression_restore"):
		if world_node.is_ancestor_of(node) and node.has_method("is_fading") and node.call("is_fading") == true: cutscene = true
	for node: Node in get_tree().get_nodes_in_group("story_modal"):
		if node.has_method("is_open") and node.call("is_open") == true:
			if node.get_script() == preload("res://scripts/onboarding/lesson_panel.gd"): cutscene = true
			else: dialogue = true
	var combat := false
	var directors := _portal_world_directors(world_node)
	if directors.is_empty(): return {}
	for director: Node in directors:
		if director.call("trainer_battle_active") == true: combat = true
		var manager: Node = director.get("_manager")
		if manager != null and manager.has_method("is_fighting") and manager.call("is_fighting") == true: combat = true
		var host_record: RefCounted = director.get("_encounter_host")
		if host_record != null:
			for record: Variant in host_record.get("encounters").values():
				if record is Dictionary and record.get("realm") == realm and record.get("phase") in ["active", "catching", "resolving"] and record.get("participants", {}).has(peer): combat = true
	var positions: Dictionary = {}
	var arches: Dictionary = {}
	for hall: Node in get_tree().get_nodes_in_group("crossing_halls"):
		if world_node.is_ancestor_of(hall):
			for id: String in ["home", "tidewake", "cloudreach", "stormwood", "biome5", "biome6", "biome7", "biome8"]:
				var arch: Node3D = hall.call("arch", id)
				if arch != null: arches[id] = arch.global_position
	for stone: Node in get_tree().get_nodes_in_group("waystones"):
		if world_node.is_ancestor_of(stone) and stone.get("realm_id") == realm:
			var id := str(stone.get("waystone_id"))
			if positions.has(id): return {}
			positions[id] = (stone as Node3D).global_position
	var personal: Dictionary = _character_authority.call("state", admitted.character_id)
	return {"world_instance_id": game.get("world").reward_delivery_namespace, "character_id": admitted.character_id,
		"peer_id": peer, "realm": realm, "position": player.global_position, "damage_revision": vitals.get("damage_revision"),
		"combat": combat, "dialogue": dialogue, "cutscene": cutscene, "swimming": bool(swimming.swimming),
		"flying": bool(fly.call("is_flying")), "downed": bool(downed.call("is_downed")),
		"home_key_owned": _home_key_authoritative_owned(peer),
		"character_unlocks": personal.redesign_character.portal_unlocks.duplicate(),
		"world_unlocks": game.get("world").redesign_world.portal_unlocks.duplicate(),
		"character_stirred": _character_authority.call("character_fifth_stirred", admitted.character_id),
		"owned_portal_keys": admitted_portal_keys(peer), "last_waystones": personal.redesign_character.last_waystones.duplicate(true),
		"waystones_activated": personal.redesign_character.waystones_activated.duplicate(true),
		"waystone_positions": positions, "arch_positions": arches}


func home_key_refusal() -> String:
	if not portal_runtime_ready(): return "The Home Key is not ready yet."
	var context: Dictionary = _host_portal_context(local_peer_id()) if is_host() else {}
	if not is_host():
		var lifecycle := get_node_or_null(^"FoundationComposition/TravelLifecycle")
		if lifecycle != null:
			context = lifecycle.call("local_sample")
			context.combat = _altar_peer_in_combat(local_peer_id())
	if context.is_empty(): return "Your travel state is not ready."
	return PORTAL_POLICY.refusal(context)

func publish_travel_lifecycle(producer: Node, sample: Dictionary) -> bool:
	if is_host() or not is_active() or producer != get_node_or_null(^"FoundationComposition/TravelLifecycle") \
		or _peer == null or _peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED \
		or not snapshot_ready() \
		or not preload("res://scripts/net/foundation_travel_lifecycle.gd").valid_sample(sample): return false
	return rpc_id(HOST_PEER_ID, "_rpc_travel_lifecycle", sample) == OK

@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_travel_lifecycle(sample: Dictionary) -> void:
	# Resources, the Forge and rematches read this lifecycle too, so it is not
	# gated on portals; accept() still checks the admitted sender's character,
	# epoch, world and sequence. Portal/Home Key decisions keep their own gate.
	if not is_host(): return
	var lifecycle := get_node_or_null(^"FoundationComposition/TravelLifecycle")
	if lifecycle != null: lifecycle.call("accept", multiplayer.get_remote_sender_id(), sample)

## Read-only pending predicate over the one durable world carrier. Unknown
## matching rows fail closed; this is not a new pending store or inventory.
func _pending_portal_for(character: String) -> bool:
	var game := _game()
	if game == null or game.get("world") == null: return true
	var world: RefCounted = game.get("world")
	for row: Variant in world.reward_deliveries.values():
		if row is Dictionary and row.get("kind") == "portal_unlock" and row.get("character_id") == character:
			if not PORTAL_RECEIPT.valid(row, character, world.reward_delivery_namespace) or row.status not in ["accepted"]: return true
	return false


var _owner_portal_install: Dictionary = {}

func _owner_portal_conflicting_transaction(player: RefCounted) -> bool:
	var row := _owner_training_row()
	return not _owner_training_retry.is_empty() or (not row.is_empty() and row.status == "pending") or (is_host() and _character_authority.call("creature_training_is_pending", player.character_id) == true)


func _begin_owner_portal_install(player: RefCounted, world: RefCounted, row: Dictionary, slot: int) -> bool:
	var game := _game()
	if game == null or player != game.get("local") or world != game.get("world") or not _owner_portal_install.is_empty() or _owner_portal_conflicting_transaction(player): return false
	if not PORTAL_RECEIPT.valid(row, player.character_id, world.reward_delivery_namespace) or row.status != "pending" or not PORTAL_RECEIPT.equivalent(world.reward_deliveries.get(row.receipt), row): return false
	if slot < 0 or player.inventory.stack_at(slot) != {"id": row.item, "n": 1}: return false
	_owner_portal_install = {"player": weakref(player), "world": weakref(world), "receipt": row.receipt, "slot": slot, "item": row.item, "rollback": false}
	return true


func _end_owner_portal_install() -> void:
	_owner_portal_install.clear()


func _owner_portal_inventory_write_allowed(index: int, stack: Variant, player: RefCounted) -> bool:
	var game := _game()
	if game == null or _owner_portal_install.is_empty() or _owner_portal_install.player.get_ref() != player or _owner_portal_install.world.get_ref() != game.get("world") or index != _owner_portal_install.slot: return false
	var row: Variant = game.get("world").reward_deliveries.get(_owner_portal_install.receipt)
	if not PORTAL_RECEIPT.valid(row, player.character_id, game.get("world").reward_delivery_namespace) or row.status != "pending": return false
	return stack == {"id": _owner_portal_install.item, "n": 1} if _owner_portal_install.rollback else stack == null


func _owner_portal_snapshot_allowed(player: RefCounted, payload: Dictionary) -> bool:
	var game := _game()
	if game == null or player != game.get("local"): return false
	var world: RefCounted = game.get("world")
	for row: Variant in world.reward_deliveries.values():
		if not row is Dictionary or row.get("kind") != "portal_unlock" or row.get("character_id") != player.character_id or row.get("status") != "pending": continue
		if not PORTAL_RECEIPT.valid(row, player.character_id, world.reward_delivery_namespace): return false
		var expected: Dictionary = row.duplicate(true)
		expected.status = "settled"
		if not PORTAL_RECEIPT.equivalent(payload.get("satchel_escrow", {}).get(row.receipt), expected): return false
		if not payload.get("redesign_character", {}).get("transaction_receipts", []).has(row.receipt): return false
		for stack: Variant in payload.get("inventory", []):
			if stack is Dictionary and stack.get("id") == row.item: return false
	return true


## Prepared publisher's host-internal exact-stage gate. Sender resolution and
## generation come from this Session; no network method exposes a full stage.
func character_action_stage_matches(peer: int, accepted: Dictionary) -> bool:
	if not is_host() or _character_authority == null or _altar_current_epoch().is_empty(): return false
	var character := _authority_character(peer)
	if character.is_empty() or character != accepted.get("character_id"): return false
	if accepted.get("action") not in preload("res://scripts/net/character_action_rules.gd").ACTIONS and accepted.get("action") not in preload("res://scripts/net/foundation_actions.gd").ACTIONS: return false
	var stage: Variant = _character_authority.call("staged_creature_training", accepted)
	return stage is Dictionary and not stage.is_empty() and ESSENCE._equivalent(stage, accepted)


func _begin_owner_training_rollback(player: RefCounted, world: RefCounted, row: Dictionary) -> bool:
	if not _owner_training_install or _owner_training_retry.is_empty() \
		or _owner_training_retry.player.get_ref() != player or _owner_training_retry.world.get_ref() != world \
		or _owner_training_retry.receipt != row.get("receipt") or not ESSENCE._equivalent(_owner_training_row(), row): return false
	_owner_training_install_rollback = true
	return true


func _owner_training_release_write_allowed(index: int, player: RefCounted) -> bool:
	var row := _owner_training_row()
	if not _owner_training_install or _owner_training_install_rollback or preload("res://scripts/net/character_record_rules.gd").training_version(row) not in [2, 3] \
		or not row.get("action") in ["trait_release", "essence_release"] or row.get("status") != "pending" or _owner_training_retry.is_empty() \
		or _owner_training_retry.player.get_ref() != player or _owner_training_retry.receipt != row.receipt: return false
	var original: Variant = _owner_training_retry.get("release_instance")
	var member: RefCounted = player.get("party").call("at", index)
	return original is WeakRef and original.get_ref() == member and member != null \
		and member.get("uid") == row.intent.creature_uid \
		and ESSENCE._equivalent(preload("res://scripts/net/character_record_rules.gd").portable_projection(player.call("save_data")), row.before)


func _owner_training_release_rollback_allowed(snapshot: Dictionary, player: RefCounted) -> bool:
	if _owner_training_install_rollback and _owner_training_row().get("action") == "wild_capture": return _capture_roster_allowed(snapshot.get("members", []), true, player)
	var row := _owner_training_row()
	if not _owner_training_install or not _owner_training_install_rollback or preload("res://scripts/net/character_record_rules.gd").training_version(row) not in [2, 3] \
		or not row.get("action") in ["trait_release", "essence_release"] or row.get("status") != "pending" or _owner_training_retry.is_empty() \
		or _owner_training_retry.player.get_ref() != player or _owner_training_retry.receipt != row.receipt \
		or not snapshot.get("members") is Array or snapshot.members.size() != row.before.party.size(): return false
	var original: Variant = _owner_training_retry.get("release_instance")
	if not original is WeakRef or original.get_ref() == null: return false
	var survivors: Array = []
	var expected: Dictionary = row.before.duplicate(true)
	var removed := -1
	for index: int in snapshot.members.size():
		var member: Variant = snapshot.members[index]
		if not member is RefCounted or member.get("uid") != row.before.party[index].uid: return false
		if member.get("uid") == row.intent.creature_uid:
			if removed >= 0 or member != original.get_ref(): return false
			removed = index
		else: survivors.append(member)
	if removed < 0 or player.get("party").call("members") != survivors: return false
	expected.party.remove_at(removed)
	return ESSENCE._equivalent(preload("res://scripts/net/character_record_rules.gd").portable_projection(player.call("save_data")), expected)

static func _weak_capture_roster_allowed(members: Array, rollback: bool, owner: WeakRef, session_ref: WeakRef) -> bool:
	return owner.get_ref() != null and session_ref.get_ref() != null and session_ref.get_ref().call("_capture_roster_allowed", members, rollback, owner.get_ref()) == true

func _capture_roster_allowed(members: Array, rollback: bool, player: RefCounted) -> bool:
	var row := _owner_training_row()
	if not _owner_training_install or rollback != _owner_training_install_rollback or row.get("version") != 3 \
		or row.get("action") not in ["wild_capture", "starter_choice"] or row.get("status") != "pending" or _owner_training_retry.is_empty() \
		or _owner_training_retry.player.get_ref() != player or _owner_training_retry.receipt != row.receipt: return false
	# F01#6a: an original starter is admitted only onto the empty roster.
	if row.action == "starter_choice" and not (row.before.party as Array).is_empty(): return false
	var expected: Array = (row.before if rollback else row.after).party
	var originals: Array = _owner_training_retry.get("capture_originals", [])
	if members.size() != expected.size() or members.size() > 5 or originals.size() != row.before.party.size(): return false
	for index: int in members.size():
		var member: Variant = members[index]
		if not member is RefCounted: return false
		# Compare the same portable projection the row was staged from: it
		# carries no in-fight energy meter (character_record_rules), and passive
		# care keeps accruing between the host's stage and this install (the
		# owner apply keeps it: ESSENCE.merge_owner_passive). Identity, stats
		# and loadout stay exact.
		var live_card: Dictionary = preload("res://scripts/save/water_capture_codec.gd").encode(member, (row.before if rollback else row.after).redesign_character)
		var expected_card: Dictionary = expected[index].duplicate(true)
		live_card.erase("energy")
		expected_card.erase("energy") # A newcomer's staged card is the raw capture card.
		if not ESSENCE.owner_matches_after({"party": [live_card]}, {"party": [expected_card]}): return false
		var old_index := -1
		for old: int in row.before.party.size():
			if row.before.party[old].uid == expected[index].uid: old_index = old
		if old_index >= 0 and originals[old_index].get_ref() != member: return false
		if old_index < 0 and (rollback or expected[index].uid != _capture_newcomer_uid(row)): return false
	return true


## The one creature a roster install may add: a capture's offered card, or
## (F01#6a) the original starter the guest asked the host to stage.
func _capture_newcomer_uid(row: Dictionary) -> String:
	if row.get("action") == "starter_choice":
		return str(row.get("intent", {}).get("creature", {}).get("uid", ""))
	return str(row.get("host_context", {}).get("creature", {}).get("uid", ""))

func _foundation_capture_context(peer: int, key: String) -> Dictionary:
	if preload("res://scripts/repeatables/alpha_respawns.gd").config().get("runtime_enabled") != true \
		or not is_host() or admitted_character_state(peer).is_empty() or _altar_peer_in_combat(peer): return {}
	var world: RefCounted = _game().world
	var character := _authority_character(peer)
	var actor: Dictionary = get_node(^"LedgerRpc").call("_water_actor_context", peer, {})
	if actor.get("character_id") != character or not actor.get("position") is Vector3: return {}
	for row: Variant in world.reward_deliveries.values():
		if not preload("res://scripts/net/foundation_event.gd").valid(row, world.reward_delivery_namespace, world.world_id): continue
		for duty: Dictionary in row.duties:
			if duty.action != "capture_offer" or duty.character_id != character or duty.context.source_key != key or duty.context.realm != actor.get("realm"): continue
			var context: Dictionary = duty.context.duplicate(true)
			context.character_id = character
			context.expected_revision = _character_authority.call("revision", character)
			context.in_range = true
			context.in_combat = false
			context.foundation_runtime_authorized = true
			context.retained_event = row.delivery_id
			return context
	return {}


## F01#6a. A guest's original starter enters this host's admitted record only
## through the staged `starter_choice` action (scripts/net/starter_choice_action.gd),
## never from the guest's own write. The host context comes from the host's own
## config and registry; `game_state.gd::_original_starter_admitted()` asks.
const STARTER_CHOICE := preload("res://scripts/net/starter_choice_action.gd")

func _foundation_starter_context(peer: int) -> Dictionary:
	if not is_host() or peer == local_peer_id() or admitted_character_state(peer).is_empty() or _altar_peer_in_combat(peer): return {}
	if config().get("redesign_ending_runtime_enabled") != true and not portal_runtime_ready(): return {}
	var character := _authority_character(peer)
	if character.is_empty(): return {}
	var species: Variant = preload("res://scripts/story/opening_beats.gd").config().get("starters", {}).get("species", [])
	if not species is Array or species.is_empty(): return {}
	return STARTER_CHOICE.host_context(character, int(_character_authority.call("revision", character)),
		species, int(PROGRESSION.config().get("level", {}).get("starter_level", 3)))

## Guest only. Re-asked by the opening director until the row reads accepted;
## the host answers an identical request from its existing row. The revision is
## the host registry's, read from the personal view this also refreshes.
func request_original_starter(card: Dictionary) -> Dictionary:
	if is_host() or not is_active() or card.is_empty(): return FOUNDATION_ACTIONS.deny("authority_missing")
	var character := _local_character_id()
	var view := _foundation_personal_cache
	_foundation_send("personal_view", "homestead_view", {}, -1)
	if view.get("character_id") != character or not ESSENCE._integer(view.get("registry_revision"), 0, 2147483646):
		return {"ok": false, "resolved": false, "code": "awaiting_personal_view"}
	return _foundation_send("starter_choice", STARTER_CHOICE.source_key(character), STARTER_CHOICE.intent(card), int(view.registry_revision))

const OPENING_HOME_KEY := preload("res://scripts/net/opening_home_key.gd")

func request_opening_home_key(source: Node) -> bool:
	if not portal_runtime_ready() or source == null: return false
	if is_host():
		var transport := get_node_or_null(^"LedgerRpc")
		if transport == null: return false
		var decision: Dictionary = transport.call("journal_opening_home_key_prepared", local_peer_id(), source)
		if decision.get("durable") != true or _owner_training_mutation_blocked(_game().get("local")): return false
		for row: Variant in _game().get("local").satchel_escrow.values():
			if preload("res://scripts/net/home_key_action.gd").valid_escrow(row, _local_character_id()): return true
		return false
	var game := _game()
	if not is_active() or not handshake_snapshot_applied() or game == null or game.get("local") == null or game.get("world") == null: return false
	var request := OPENING_HOME_KEY.envelope(game.get("local").character_id, game.get("world").reward_delivery_namespace, _altar_current_epoch())
	if not OPENING_HOME_KEY.valid_envelope(request, game.get("local").character_id, game.get("world").reward_delivery_namespace, _altar_current_epoch()): return false
	rpc_id(HOST_PEER_ID, "_rpc_opening_home_key", request)
	return false # The saved portable owe/deliver CAS completes the spoken effect.


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_opening_home_key(request: Dictionary) -> void:
	if is_host(): OPENING_HOME_KEY.host_grant(self, multiplayer.get_remote_sender_id(), request)


var _home_key_delivery_retry_at: Dictionary = {}
## This owner's latest Home Key reconcile request per gift: the host's
## owner-passive freeze must name exactly the request this owner sent.
var _home_key_requests_sent: Dictionary = {}

func _request_home_key_delivery(delivery: Dictionary) -> void:
	var game := _game()
	if not portal_runtime_ready() or game == null or game.get("local") == null or game.get("world") == null: return
	# The host stages a full-record Home Key row: wait until every find this
	# owner applied has been replayed into the host's admitted record.
	if not is_host() and _owner_passive != null and _owner_passive.call("reward_replay_pending") == true: return
	var character: String = game.get("local").character_id
	var id: String = str(delivery.get("delivery_id", ""))
	var origin: String = str(delivery.get("world_namespace", ""))
	if id.is_empty() or origin.is_empty() or delivery.get("character_id") != character: return
	var epoch := _altar_current_epoch()
	var retry_key := JSON.stringify([character, game.get("world").reward_delivery_namespace, epoch, id])
	var now := Time.get_ticks_msec()
	if now < int(_home_key_delivery_retry_at.get(retry_key, 0)): return
	_home_key_delivery_retry_at[retry_key] = now + 3000
	var request := OPENING_HOME_KEY.envelope(character, game.get("world").reward_delivery_namespace, epoch)
	request.delivery_id = id
	request.origin_namespace = origin
	if is_host(): OPENING_HOME_KEY.host_reconcile(self, local_peer_id(), request)
	elif is_active() and handshake_snapshot_applied():
		_home_key_requests_sent[id] = request.duplicate(true)
		rpc_id(HOST_PEER_ID, "_rpc_home_key_delivery", request)


@rpc("any_peer", "call_remote", "reliable", CHANNEL_LEDGER)
func _rpc_home_key_delivery(request: Dictionary) -> void:
	if is_host(): OPENING_HOME_KEY.host_reconcile(self, multiplayer.get_remote_sender_id(), request)


## Characters saved before the portal runtime finished the opening without a
## Home Key; the host journals their deterministic grant (opening_home_key.gd
## host_legacy_grant), which the ordinary delivery path then settles once.
## Armed only when such a character can arrive: a loaded save (local) or an
## admitted guest. A check stays armed through transient not-ready results
## for at most LEGACY_HOME_KEY_WINDOW_MS.
var _legacy_home_key_left := 0.0
var _legacy_home_key_due: Dictionary = {}
const LEGACY_HOME_KEY_WINDOW_MS := 60000

func arm_legacy_home_key_check(peer: int) -> void:
	if is_host() and portal_runtime_ready(): _legacy_home_key_due[peer] = Time.get_ticks_msec()

## Characters whose verified opening-gift request reached this host this
## session (host memory only; a rejoin re-seeds the guest's persisted beats).
var _opening_gift_requested: Dictionary = {}

func note_opening_gift_requested(peer: int) -> void:
	var character := _authority_character(peer)
	if not is_host() or character.is_empty(): return
	_opening_gift_requested[character] = true
	arm_legacy_home_key_check(peer)

func opening_gift_requested(peer: int) -> bool:
	return _opening_gift_requested.get(_authority_character(peer)) == true

func _tick_legacy_home_keys(delta: float) -> void:
	_legacy_home_key_left -= delta
	if _legacy_home_key_due.is_empty() or _legacy_home_key_left > 0.0 or not is_host() or not portal_runtime_ready() or _game() == null: return
	_legacy_home_key_left = 2.0
	for peer: Variant in _legacy_home_key_due.keys():
		var expired: bool = Time.get_ticks_msec() - int(_legacy_home_key_due[peer]) > LEGACY_HOME_KEY_WINDOW_MS
		if int(peer) != local_peer_id() and not bool(_registry.call("has", int(peer))): expired = true
		var result: Dictionary = {} if expired else OPENING_HOME_KEY.host_legacy_grant(self, int(peer))
		if expired or result.is_empty() or result.get("durable") == true: _legacy_home_key_due.erase(peer)


func _home_key_authoritative_owned(peer: int) -> bool:
	return OPENING_HOME_KEY.authoritative_owned(self, peer)
