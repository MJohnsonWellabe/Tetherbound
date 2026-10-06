extends Node

## Host channel lifetime and observer presentation. Events never grant travel,
## inventory or input ownership; only the existing portal policy does that.
var _left := 0.0

func session() -> Node:
	return get_parent().get_parent()

func _ready() -> void:
	session().connect("session_ended", func(_reason: String) -> void: _clear())
	session().connect("peer_left", _peer_left)

func _clear() -> void:
	var key: Node = session().call("_game").get_node_or_null(^"HomeKey")
	if key != null: key.call("clear_remote_raises")

func _peer_left(peer: int) -> void:
	if session().call("is_host") != true: return
	var policy: RefCounted = session().get("_portal_policy")
	for row: Dictionary in policy.call("open_channels"):
		if row.peer_id == peer: _publish(row, false)
	policy.call("disconnected", peer)

func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 0.1
	var owner := session()
	if owner.call("is_host") != true or owner.call("portal_runtime_ready") != true: return
	var policy: RefCounted = owner.get("_portal_policy")
	if policy.call("has_open_channels") != true: return
	for expired: Dictionary in policy.call("tick_expired", Time.get_ticks_msec()):
		_publish(expired, false)
	for row: Dictionary in policy.call("open_channels"):
		var context: Dictionary = owner.call("_host_portal_context", row.peer_id)
		# A late or missing guest sample (> 1 s under load or jitter) is
		# unknown, not a refusal. Cancel only on an observed refusal, realm or
		# damage change. Finish re-evaluates a fresh context with the frozen
		# realm/damage revision, and tick_expired bounds an abandoned channel.
		if context.is_empty(): continue
		if policy.call("cancel_invalid", context) == true:
			_publish(row, false)

func approved(peer: int, envelope: Dictionary, result: Dictionary, realm: String) -> void:
	if session().call("is_host") != true or result.get("ok") != true: return
	var kind: String = envelope.payload.kind
	if kind not in ["home_key_begin", "home_key_cancel", "home_key_finish"]: return
	var use_id: String = result.get("prepared", {}).get("use_id", envelope.payload.get("use_id", ""))
	if use_id.is_empty(): return
	_publish({"peer_id": peer, "character_id": envelope.character_id,
		"world_instance_id": envelope.world_instance_id, "realm": realm,
		"request_id": use_id}, kind == "home_key_begin")

func ended(row: Dictionary) -> void:
	if session().call("is_host") == true: _publish(row, false)

func _publish(row: Dictionary, active: bool) -> void:
	var owner := session()
	var event := {"peer_id": row.peer_id, "character_id": row.character_id,
		"world_instance_id": row.world_instance_id, "session_epoch": owner.call("_altar_current_epoch"),
		"realm": row.realm, "use_id": row.request_id, "active": active}
	_receive(event)
	if owner.call("is_active") == true: _receive.rpc(event)

static func valid(event: Dictionary, character: String, world_namespace: String, epoch: String) -> bool:
	if event.size() != 7 or not event.get("peer_id") is int or event.peer_id < 1 \
		or not event.get("active") is bool: return false
	for field: String in ["character_id", "world_instance_id", "session_epoch", "realm", "use_id"]:
		if not event.get(field) is String or event[field].is_empty() or event[field].length() > 192: return false
	return event.character_id == character and event.world_instance_id == world_namespace \
		and event.session_epoch == epoch and event.realm in ["meadows", "water", "cloudreach", "stormwood"]

@rpc("authority", "call_remote", "reliable", 1)
func _receive(event: Dictionary) -> void:
	var owner := session()
	var game: Node = owner.call("_game")
	if game == null or game.get("world") == null: return
	var peer: int = event.get("peer_id", 0) if event.get("peer_id") is int else 0
	if not valid(event, str(owner.call("_authority_character", peer)),
		str(game.get("world").reward_delivery_namespace), str(owner.call("_altar_current_epoch"))) \
		or peer == owner.call("local_peer_id"): return
	var key := game.get_node_or_null(^"HomeKey")
	if key == null:
		if event.active == false: return
		key = preload("res://scripts/world/home_key.gd").new()
		key.name = "HomeKey"
		game.add_child(key)
	if event.active == false:
		key.call("end_remote_raise", event.use_id)
		return
	if event.realm != str(game.get("current_realm")): return
	var lifecycle := get_parent().get_node_or_null(^"TravelLifecycle")
	var actor: Node3D = lifecycle.call("remote_body", peer) if lifecycle != null else null
	var world: Node3D = owner.call("_portal_world_node", event.realm)
	if actor == null or world == null or not actor.is_inside_tree() or actor.is_queued_for_deletion() \
		or not world.is_ancestor_of(actor): return
	key.call("show_remote_raise", actor, event.use_id)
