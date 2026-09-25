extends Node

## Durable capture handover, addressed to a stable character. The host keeps
## the unresolved claim until the character saves a receipt with their party.
## Pending presentation uses the existing five-slot choice, never a reserve.
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const GUARDIAN := preload("res://scripts/world/water_guardian_reward.gd")
const CHANNEL := preload("res://scripts/net/session.gd").CHANNEL_LEDGER
var _pending: Dictionary = {}
var _active: Dictionary = {}
## Claim ids whose refusal the host CONFIRMED this session (a host-confirmed
## chamber decline), or that this character refused while holding the claim
## itself (decline_pending: the host keeps re-sending that claim until its
## refusal is journaled, so a lost refusal is simply resent). A resend of one
## of these is refused again, never presented.
var _declined: Dictionary = {}
## Chamber decline intents still awaiting the host's verdict. A claim with this
## id that arrives meanwhile (an Invite crossing the decline) is HELD: neither
## presented nor refused. The host's ok verdict promotes the hold to _declined;
## a refusal (or a new Invite) releases it, so a decline the host refused can
## never silently refuse a later offer.
var _decline_holds: Dictionary = {}
var _poll := 0.0

## Seams (overridden by unit fixtures): the Game autoload, the host ledger
## bridge that resolves a peer to its actor, and the RPC sender id.
func _game() -> Node:
	return get_node_or_null("/root/Game")

func _bridge() -> Node:
	return get_parent()

func _sender() -> int:
	return multiplayer.get_remote_sender_id()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_poll -= delta
	if _poll > 0:
		return
	_poll = 1.0
	var game := _game()
	# The persistent ledger transport processes while Game is between worlds,
	# and pure unit fixtures may never create player/world state at all.
	if game == null or game.get("world") == null or game.get("local") == null:
		return
	if not _active.is_empty() and (game.pending_catch == null or not _is_local_claim(_active)):
		_active = {}
	# A queued claim from another world instance or character (world change,
	# character switch) is dropped rather than left to drive a decline.
	if not _pending.is_empty() and not _is_local_claim(_pending):
		_pending = {}
	if game.is_host():
		for raw: Variant in game.world.water_capture_claims.values().duplicate():
			if not raw is Dictionary or str(raw.get("character_id", "")).is_empty():
				continue
			var claim: Dictionary = raw
			var peers: Array = game.session.peers_in_realm("water")
			if game.current_realm == "water" and not peers.has(game.session.local_peer_id()):
				peers.append(game.session.local_peer_id())
			for peer: int in peers:
				var actor: Dictionary = _bridge()._water_actor_context(peer, {})
				if str(actor.get("character_id", "")) == str(claim.get("character_id", "")):
					if peer == game.session.local_peer_id():
						receive_claim(claim)
					else:
						_claim.rpc_id(peer, claim)
	_offer_pending()

@rpc("authority", "call_remote", "reliable", CHANNEL)
func _claim(claim: Dictionary) -> void:
	receive_claim(claim)

## This peer's own character, in this world INSTANCE (not only the slot
## locator: another host's "slot-0" world is never this one).
func _is_local_claim(claim: Dictionary) -> bool:
	var game := _game()
	if claim.is_empty() or game == null or game.get("world") == null or game.get("local") == null:
		return false
	return not str(claim.get("id", "")).is_empty() \
		and str(claim.get("character_id", "")) == str(game.local.character_id) \
		and GUARDIAN.claim_matches_world(claim, game.world)

func receive_claim(claim: Dictionary) -> void:
	var game := _game()
	if not _is_local_claim(claim):
		return
	if _declined.has(str(claim.id)):
		_send_decline(str(claim.id))
		return
	if GUARDIAN.already_received(game.local.flags, claim):
		if str(_pending.get("id", "")) == str(claim.id):
			_pending = {}
		_acknowledge(str(claim.id))
		return
	if str(_active.get("id", "")) == str(claim.id):
		return
	_pending = claim.duplicate(true)

func _offer_pending() -> void:
	if _pending.is_empty() or not _active.is_empty() or _decline_holds.has(str(_pending.get("id", ""))):
		return
	var game := _game()
	if GUARDIAN.already_received(game.local.flags, _pending):
		var received_id := str(_pending.id)
		_pending = {}
		_acknowledge(received_id)
		return
	if game.current_realm != "water" or game.pending_catch != null \
			or not GUARDIAN.claim_matches_world(_pending, game.world) or str(_pending.character_id) != game.local.character_id:
		return
	var realm := get_node_or_null("/root/WaterArchipelago")
	if realm == null or realm.simulation_only or not realm.shell_build_complete():
		return
	if realm.get_node("CombatManager").is_fighting():
		return
	var creature := CODEC.decode(_pending.get("creature"))
	if creature == null:
		return
	creature.caught_on_day = maxi(1, game.day)
	creature.set_meta("water_capture_claim", str(_pending.id))
	_active = _pending
	_pending = {}
	game.pending_catch = creature
	# The ordinary menu opens the existing choice if the belt is full. With
	# room, the same durable transaction can complete immediately.
	if not game.local.party.is_full():
		complete_pending_capture(-1)

func owns_pending(creature: RefCounted) -> bool:
	return creature != null and not _active.is_empty() \
		and str(creature.get_meta("water_capture_claim", "")) == str(_active.id)

func complete_pending_capture(release_index: int) -> Dictionary:
	var game := _game()
	if not owns_pending(game.pending_catch):
		return {"ok": false, "reason": "No capture handover is waiting."}
	var result: Dictionary = load("res://scripts/save/water_capture_transaction.gd").settle(game, _active, game.pending_catch, release_index)
	if not result.get("ok", false):
		game.push_world_message("Could not save the capture. The choice is still waiting; try again.")
		return result
	var id := str(_active.id)
	_active = {}
	game.pending_catch = null
	_acknowledge(id)
	return result

## Refuse this character's own pending Guardian offer (WORLD §2.3: "Refusal
## completes the chapter"). A UI calls this; nothing is granted and the host
## settles the offer exactly as an acceptance would, minus the creature.
func decline_pending() -> Dictionary:
	var game := _game()
	var claim := _local_guardian_claim()
	if claim.is_empty():
		return {"ok": false, "reason": "No Guardian offer is waiting."}
	var id := str(claim.id)
	_decline_holds.erase(id)
	_declined[id] = true
	if not _active.is_empty() and str(_active.id) == id:
		_active = {}
		if game.pending_catch != null and str(game.pending_catch.get_meta("water_capture_claim", "")) == id:
			game.pending_catch = null
	if str(_pending.get("id", "")) == id:
		_pending = {}
	_send_decline(id)
	return {"ok": true}

## This character's Guardian claim held locally (pending or presented), only
## while it still belongs to this world instance and local character.
func pending_guardian_id() -> String:
	return str(_local_guardian_claim().get("id", ""))

func _local_guardian_claim() -> Dictionary:
	for claim: Dictionary in [_active, _pending]:
		if str(claim.get("source", "")) == "guardian" and _is_local_claim(claim):
			return claim
	return {}

## A queued claim that the next poll may present (not held for a decline).
func presentable() -> bool:
	return _active.is_empty() and _is_local_claim(_pending) and not _decline_holds.has(str(_pending.id))

## Chamber decline sent to the host: hold (never present, never refuse) a claim
## with this id until the host's verdict arrives.
func hold_for_decline(id: String) -> void:
	if not id.is_empty():
		_decline_holds[id] = true

func held_for_decline(id: String) -> bool:
	return _decline_holds.has(id)

## The host refused the decline, or the player invited again: forget the hold
## so the claim is presented normally.
func release_decline(id: String) -> void:
	_decline_holds.erase(id)

## The host confirmed the refusal: drop a held/queued copy of the claim and
## refuse any stale resend of it.
func confirm_declined(id: String) -> void:
	if id.is_empty():
		return
	_decline_holds.erase(id)
	_declined[id] = true
	var game := _game()
	if str(_active.get("id", "")) == id:
		_active = {}
		if game != null and game.pending_catch != null and str(game.pending_catch.get_meta("water_capture_claim", "")) == id:
			game.pending_catch = null
	if str(_pending.get("id", "")) == id:
		_pending = {}

func is_declined(id: String) -> bool:
	return _declined.has(id)

func _send_decline(id: String) -> void:
	var game := _game()
	if game.is_host():
		_accept_decline(game.session.local_peer_id(), id)
	elif multiplayer.has_multiplayer_peer():
		_decline.rpc_id(1, id)

@rpc("any_peer", "call_remote", "reliable", CHANNEL)
func _decline(id: String) -> void:
	if _game().is_host():
		_accept_decline(_sender(), id)

func _accept_decline(peer: int, id: String) -> void:
	_resolve_guardian(peer, id, false)

func _resolve_guardian(peer: int, id: String, accepted: bool) -> void:
	var game := _game()
	var actor: Dictionary = _bridge()._water_actor_context(peer, {})
	var result: Dictionary = GUARDIAN.resolve(game, _bridge().ledger, id, str(actor.get("character_id", "")), accepted)
	if result.get("ok", false) and result.has("delta") and not (result.delta.ops as Array).is_empty():
		_bridge().publish_journaled_delta(result.delta)

func _acknowledge(id: String) -> void:
	var game := _game()
	if game.is_host():
		_accept_ack(game.session.local_peer_id(), id)
	elif multiplayer.has_multiplayer_peer():
		_ack.rpc_id(1, id)

@rpc("any_peer", "call_remote", "reliable", CHANNEL)
func _ack(id: String) -> void:
	if _game().is_host():
		_accept_ack(_sender(), id)

func _accept_ack(peer: int, id: String) -> void:
	var game := _game()
	var claim: Dictionary = game.world.water_capture_claims.get(id, {})
	if str(claim.get("source", "")) == "guardian":
		# Per-participant settlement; world restoration happens once inside.
		_resolve_guardian(peer, id, true)
		return
	var actor: Dictionary = _bridge()._water_actor_context(peer, {})
	if claim.is_empty() or str(actor.get("character_id", "")) != str(claim.character_id):
		return
	var before: Dictionary = game.world.save_data()
	var revision: int = game.world.revision
	var ledger: RefCounted = _bridge().ledger
	var sequence: int = ledger.seq
	game.world.water_capture_claims.erase(id)
	if not game.save_system.save_world(game, game.world.world_id):
		game.world.load_data(before)
		game.world.revision = revision
		ledger.seq = sequence
