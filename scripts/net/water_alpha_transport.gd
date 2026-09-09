extends Node

## Persistent transport: realm shells may still be loading when a peer arrives.
## All authority stays in the host's WaterAlpha service, never in this router.
const CHANNEL := preload("res://scripts/net/session.gd").CHANNEL_LEDGER
var _latest_snapshot: Dictionary = {}

func submit(intent: Dictionary) -> Dictionary:
	var completing := str(intent.get("kind", "")) in ["catch_finished", "disengage"]
	if not _transition_allowed(1, completing):
		return _transition_refusal(intent)
	var game := get_node("/root/Game")
	if game.is_host():
		return _commit_if_allowed(intent, int(game.session.local_peer_id()))
	if not multiplayer.has_multiplayer_peer():
		return {"ok": false, "pending": false, "reason": "You are not connected to this world."}
	_rpc_intent.rpc_id(1, intent)
	return {"ok": false, "pending": true}

func _transition_allowed(peer: int, completing: bool) -> bool:
	var game := get_node_or_null("/root/Game")
	if game == null or game.session == null:
		return true
	var transition: Node = game.session.realm_transition
	return transition == null or bool(transition.call("scene_rpc_allowed", "water", peer, completing))

func _transition_refusal(intent: Dictionary) -> Dictionary:
	return {"ok": false, "pending": false, "kind": str(intent.get("kind", "")),
		"reason": "This realm is closing for travel."}

func _commit_if_allowed(intent: Dictionary, peer: int) -> Dictionary:
	# All sender requests preceding its ledger fence must still be consumed.
	# Receiver policy closes this after request settlement, not on host install.
	if not _transition_allowed(peer, true):
		return _transition_refusal(intent)
	return _commit(intent, peer)

func _commit(intent: Dictionary, peer: int) -> Dictionary:
	var service := get_node_or_null("/root/WaterArchipelago/WaterAlpha")
	if service == null or not bool(service.get("ready_for_intents")):
		return {"ok": false, "pending": false, "kind": str(intent.get("kind", "")),
			"reason": "The Tidal Cradle is still loading. Try again in a moment."}
	var actor: Dictionary = get_parent().call("_water_actor_context", peer, {})
	if str(actor.get("realm", "")) != "water":
		return {"ok": false, "pending": false, "kind": str(intent.get("kind", "")),
			"reason": "You must be in Tidewake."}
	return service.call("host_commit", intent, peer, actor)

func deliver(peer: int, kind: String, payload: Dictionary) -> void:
	if not _transition_allowed(peer, true):
		return
	var game := get_node("/root/Game")
	if not game.is_host():
		return
	if peer == int(game.session.local_peer_id()):
		_receive(kind, payload)
	elif multiplayer.has_multiplayer_peer():
		_rpc_message.rpc_id(peer, kind, payload)

func consume_snapshot() -> Dictionary:
	var result := _latest_snapshot
	_latest_snapshot = {}
	return result

@rpc("any_peer", "call_remote", "reliable", CHANNEL)
func _rpc_intent(intent: Dictionary) -> void:
	if not get_node("/root/Game").is_host():
		return
	var sender := multiplayer.get_remote_sender_id()
	var verdict := _commit_if_allowed(intent, sender)
	deliver(sender, "verdict", verdict)

@rpc("authority", "call_remote", "reliable", CHANNEL)
func _rpc_message(kind: String, payload: Dictionary) -> void:
	_receive(kind, payload)

func _receive(kind: String, payload: Dictionary) -> void:
	var service := get_node_or_null("/root/WaterArchipelago/WaterAlpha")
	if service != null and bool(service.get("ready_for_intents")):
		service.call("receive_authority", kind, payload)
	elif kind == "snapshot":
		_latest_snapshot = payload.duplicate(true)
