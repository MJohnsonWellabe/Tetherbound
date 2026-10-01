extends Node

## Consumes a host-issued permit, uses normal realm loading, then measures the
## destination's actual supported ground. Success requires the portable write.
var _pending: Dictionary = {}
var _retry_left := 0.0

func travel(session: Node, peer: int, envelope: Dictionary, result: Dictionary) -> void:
	if not _pending.is_empty() or session.call("is_host") != true or peer != session.call("local_peer_id"):
		session.call("_portal_reply", peer, envelope, {"ok": false, "reason": "Another arrival is still settling."})
		return
	var policy: RefCounted = session.get("_portal_policy")
	var game: Node = session.call("_game")
	var permit: Dictionary = policy.call("consume_permit", str(result.get("prepared", {}).get("travel_permit", "")),
		peer, envelope.character_id, envelope.world_instance_id, game.get("current_realm"))
	if permit.is_empty():
		session.call("_portal_reply", peer, envelope, {"ok": false, "reason": "That travel permission has ended."})
		return
	_pending = {"session": weakref(session), "game": weakref(game), "peer": peer,
		"envelope": envelope.duplicate(true), "permit": permit.duplicate(true), "seated": false}
	if str(game.get("current_realm")) != permit.realm:
		# Only the consumed host permit chooses this destination; never a debug
		# request or client-provided coordinate. Normal transition drains actors.
		var loaded: bool = await game.call("enter_realm", permit.realm, "", true)
		if not loaded or not _same_owner(): _refuse("The destination could not load."); return
	var frames := 0
	while not str(game.call("pending_entry_for", permit.realm)).is_empty() and frames < 240:
		await get_tree().physics_frame
		frames += 1
		if not _same_owner(): _refuse("Your travel session changed."); return
	if not str(game.call("pending_entry_for", permit.realm)).is_empty(): _refuse("The destination has not settled."); return
	var world_node: Node3D = session.call("_portal_world_node", permit.realm)
	var actor: Node3D = game.call("find_player")
	if world_node == null or actor == null or not world_node.is_ancestor_of(actor): _refuse("The destination is not ready."); return
	var target := Vector3(INF, INF, INF)
	if permit.entry_id == "hall_home":
		for hall: Node in get_tree().get_nodes_in_group("crossing_halls"):
			if world_node.is_ancestor_of(hall):
				if target.is_finite(): _refuse("The home arrival is ambiguous."); return
				target = hall.call("home_arrival")
	else:
		for stone: Node in get_tree().get_nodes_in_group("waystones"):
			if world_node.is_ancestor_of(stone) and stone.get("waystone_id") == permit.entry_id:
				if target.is_finite(): _refuse("The waystone arrival is ambiguous."); return
				target = preload("res://scripts/world/waystone.gd").resolve_position(world_node, stone.get("_row"), true)
	if not target.is_finite() or not world_node.has_method("ground_height_at"): _refuse("The arrival anchor has no ground."); return
	var height := float(world_node.call("ground_height_at", target.x, target.z))
	if not is_finite(height): _refuse("The arrival anchor has no supported ground."); return
	# The actual actor's collision footprint must fit. Terrain support is
	# sampled at four surrounding points; no saved height or invented landing.
	for offset: Vector2 in [Vector2(-0.45, -0.45), Vector2(-0.45, 0.45), Vector2(0.45, -0.45), Vector2(0.45, 0.45)]:
		var support := float(world_node.call("ground_height_at", target.x + offset.x, target.z + offset.y))
		if not is_finite(support) or absf(support - height) > 0.45: _refuse("The arrival anchor is not supported."); return
	actor.global_position = Vector3(target.x, height + 0.08, target.z)
	if actor is CharacterBody3D: actor.velocity = Vector3.ZERO
	_pending.seated = true
	_save_arrival()

func _process(delta: float) -> void:
	_retry_left -= delta
	if _retry_left > 0.0: return
	_retry_left = float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").arch.refresh_seconds)
	if not _pending.is_empty() and _pending.get("seated") == true: _save_arrival()

func _same_owner() -> bool:
	if _pending.is_empty(): return false
	var session: Node = _pending.session.get_ref()
	var game: Node = _pending.game.get_ref()
	return session != null and game != null and session.call("is_host") == true \
		and session.call("_authority_character", _pending.peer) == _pending.envelope.character_id \
		and game.get("world").reward_delivery_namespace == _pending.envelope.world_instance_id \
		and session.call("_altar_current_epoch") == _pending.envelope.session_epoch

func _save_arrival() -> void:
	if not _same_owner(): _refuse("Your travel session changed."); return
	var session: Node = _pending.session.get_ref()
	var game: Node = _pending.game.get_ref()
	var saver: RefCounted = game.get("save_system")
	if saver == null or saver.call("fallback_busy") == true: return
	game.call("_capture_player_pose")
	if saver.call("save_character_prepared", game, _pending.envelope.character_id) != true: return
	if not _same_owner(): _refuse("Your travel session changed."); return
	var envelope: Dictionary = _pending.envelope
	var peer: int = _pending.peer
	_pending.clear()
	session.call("_portal_reply", peer, envelope, {"ok": true, "saved": true, "durable": true, "arrival_applied": true, "arrived": true, "reason": ""})

func _refuse(reason: String) -> void:
	if _pending.is_empty(): return
	var session: Node = _pending.session.get_ref()
	var envelope: Dictionary = _pending.envelope
	var peer: int = _pending.peer
	_pending.clear()
	if session != null: session.call("_portal_reply", peer, envelope, {"ok": false, "reason": reason})
