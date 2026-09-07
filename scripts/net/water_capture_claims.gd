extends Node

## Durable capture handover, addressed to a stable character. The host keeps
## the unresolved claim until the character saves a receipt with their party.
## Pending presentation uses the existing five-slot choice, never a reserve.
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const CHANNEL := preload("res://scripts/net/session.gd").CHANNEL_LEDGER
var _pending: Dictionary = {}
var _active: Dictionary = {}
var _poll := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	_poll -= delta
	if _poll > 0:
		return
	_poll = 1.0
	var game := get_node("/root/Game")
	if not _active.is_empty() and (game.pending_catch == null or str(_active.world_id) != game.world.world_id \
			or str(_active.character_id) != game.local.character_id):
		_active = {}
	if game.is_host():
		for raw: Variant in game.world.water_capture_claims.values().duplicate():
			if not raw is Dictionary or str(raw.get("character_id", "")).is_empty():
				continue
			var claim: Dictionary = raw
			var peers: Array = game.session.peers_in_realm("water")
			if game.current_realm == "water" and not peers.has(game.session.local_peer_id()):
				peers.append(game.session.local_peer_id())
			for peer: int in peers:
				var actor: Dictionary = get_parent()._water_actor_context(peer, {})
				if str(actor.get("character_id", "")) == str(claim.get("character_id", "")):
					if peer == game.session.local_peer_id():
						receive_claim(claim)
					else:
						_claim.rpc_id(peer, claim)
	_offer_pending()

@rpc("authority", "call_remote", "reliable", CHANNEL)
func _claim(claim: Dictionary) -> void:
	receive_claim(claim)

func receive_claim(claim: Dictionary) -> void:
	var game := get_node("/root/Game")
	if str(claim.get("character_id", "")) != game.local.character_id \
			or str(claim.get("world_id", "")) != game.world.world_id or str(claim.get("id", "")).is_empty():
		return
	if game.local.flags.has("water_capture_receipt:" + str(claim.id)):
		_acknowledge(str(claim.id))
		return
	_pending = claim.duplicate(true)

func _offer_pending() -> void:
	if _pending.is_empty() or not _active.is_empty():
		return
	var game := get_node("/root/Game")
	if game.current_realm != "water" or game.pending_catch != null \
			or str(_pending.world_id) != game.world.world_id or str(_pending.character_id) != game.local.character_id:
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
	var game := get_node("/root/Game")
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

func _acknowledge(id: String) -> void:
	var game := get_node("/root/Game")
	if game.is_host():
		_accept_ack(game.session.local_peer_id(), id)
	elif multiplayer.has_multiplayer_peer():
		_ack.rpc_id(1, id)

@rpc("any_peer", "call_remote", "reliable", CHANNEL)
func _ack(id: String) -> void:
	if get_node("/root/Game").is_host():
		_accept_ack(multiplayer.get_remote_sender_id(), id)

func _accept_ack(peer: int, id: String) -> void:
	var game := get_node("/root/Game")
	var claim: Dictionary = game.world.water_capture_claims.get(id, {})
	var actor: Dictionary = get_parent()._water_actor_context(peer, {})
	if claim.is_empty() or str(actor.get("character_id", "")) != str(claim.character_id):
		return
	game.world.water_capture_claims.erase(id)
	if not game.save_system.save_world(game, game.world.world_id):
		game.world.water_capture_claims[id] = claim
