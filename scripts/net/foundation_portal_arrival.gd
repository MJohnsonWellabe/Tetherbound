extends Node

## Consumes a host-issued permit, uses normal realm loading, then measures the
## destination's actual supported ground. Success requires the portable write.
var _pending: Dictionary = {}
var _offered: Dictionary = {} # Original authenticated permit, retained through checkpoint settlement.
var _remote: Dictionary = {}
var _retry_left := 0.0

func _ready() -> void:
	add_to_group(preload("res://scripts/ui/input_owner.gd").GROUP)
	add_to_group("story_modal")
	var session: Node = get_parent().get_parent()
	session.connect("peer_left", func(peer: int) -> void:
		session.call("_owner_passive_service").call("portal_departed", peer)
		_remote.erase(peer))
	session.connect("session_ended", func(_reason: String) -> void:
		_remote.clear()
		_pending.clear()
		_offered.clear())

## Solo menus pause the controller, but the session's arrival deadline keeps
## running. Retain ordinary input ownership until this exact travel settles;
## the controller still applies gravity and measures real contact underneath.
func owns_input() -> bool:
	return not _pending.is_empty() and _same_owner()

func is_open() -> bool:
	return owns_input()

func reset() -> void:
	_remote.clear()
	_pending.clear()
	_offered.clear()

func original_pending(peer: int, envelope: Dictionary) -> bool:
	return _remote.has(peer) and _remote[peer].envelope == envelope

func travel(session: Node, peer: int, envelope: Dictionary, result: Dictionary) -> void:
	if session.call("is_host") != true or (peer == session.call("local_peer_id") and not _pending.is_empty()) or _remote.has(peer):
		session.call("_portal_reply", peer, envelope, {"ok": false, "reason": "Another arrival is still settling."})
		return
	var policy: RefCounted = session.get("_portal_policy")
	var game: Node = session.call("_game")
	var context: Dictionary = session.call("_host_portal_context", peer)
	var permit: Dictionary = policy.call("consume_permit", str(result.get("prepared", {}).get("travel_permit", "")),
		peer, envelope.character_id, envelope.world_instance_id, str(context.get("realm", "")))
	if permit.is_empty():
		session.call("_portal_reply", peer, envelope, {"ok": false, "reason": "That travel permission has ended."})
		return
	if peer != session.call("local_peer_id"):
		_remote[peer] = {"session": weakref(session), "world": weakref(game.get("world")),
			"envelope": envelope.duplicate(true), "permit": permit.duplicate(true), "owner_saved": false}
		session.call("send_portal_owner_permit", self, peer, envelope, permit)
		session.call("_owner_passive_service").call("portal_begin", peer,
			preload("res://scripts/net/owner_passive_preparation.gd").portal_request(envelope, permit))
		return
	await _travel_owner(session, peer, envelope, permit)

func owner_travel(session: Node, envelope: Dictionary, permit: Dictionary) -> void:
	# Session checked the authority-only RPC against its original pending
	# envelope. A duplicate original permit resumes rather than travels twice.
	if not _offered.is_empty():
		if _offered.envelope == envelope and _offered.permit == permit: return
		session.call("report_portal_owner_refused", self, envelope, str(permit.get("request_id", "")), "Another arrival is still settling.")
		return
	if not _pending.is_empty():
		if _pending.envelope == envelope and _pending.permit == permit: return
		session.call("report_portal_owner_refused", self, envelope, str(permit.get("request_id", "")), "Another arrival is still settling.")
		return
	_offered = {"session": weakref(session), "envelope": envelope.duplicate(true), "permit": permit.duplicate(true)}
	# Only the exact checkpoint's saved grant may now start normal realm travel.

func owner_request_matches(request: Dictionary) -> bool:
	return not _offered.is_empty() and preload("res://scripts/net/owner_passive_preparation.gd").exact(request,
		preload("res://scripts/net/owner_passive_preparation.gd").portal_request(_offered.envelope, _offered.permit))

func start_prepared(request: Dictionary) -> void:
	if not owner_request_matches(request) or not _pending.is_empty(): return
	var session: Node = _offered.session.get_ref()
	if session == null or session.call("_owner_passive_request_matches", "portal_arrival", request) != true: return
	await _travel_owner(session, int(session.call("local_peer_id")), _offered.envelope, _offered.permit)

## The receiver coordinator may load only the destination of this retained,
## consumed host permit. A legacy client-selected realm RPC cannot mint one.
func transition_authorized(peer: int, realm: String) -> bool:
	var original: Dictionary = _remote.get(peer, {})
	if original.is_empty() or original.permit.realm != realm or original.get("owner_saved") == true: return false
	var session: Node = original.session.get_ref()
	return session != null and session.call("is_host") == true \
		and session.call("_game").get("world") == original.world.get_ref() \
		and session.call("_portal_envelope_valid", peer, original.envelope) == true \
		and session.call("_owner_passive_service").call("portal_departure_authorized", peer,
			preload("res://scripts/net/owner_passive_preparation.gd").portal_request(original.envelope, original.permit)) == true

func _travel_owner(session: Node, peer: int, envelope: Dictionary, permit: Dictionary) -> void:
	var game: Node = session.call("_game")
	_pending = {"session": weakref(session), "game": weakref(game), "peer": peer,
		"owner": weakref(game.get("local")), "world": weakref(game.get("world")),
		"envelope": envelope.duplicate(true), "permit": permit.duplicate(true), "seated": false}
	if envelope.payload.kind == "home_key_finish":
		var presented: bool = await session.call("portal_owner_travel_started", self, envelope, permit)
		if not presented: _refuse("The Home Key could not finish its fade."); return
		if not _same_owner(): _refuse("Your travel session changed."); return
	if str(game.get("current_realm")) != permit.realm:
		# Only the consumed host permit chooses this destination; never a debug
		# request or client-provided coordinate. Normal transition drains actors.
		var loaded: bool = await game.call("enter_realm", permit.realm, str(permit.entry_id) if permit.entry_id != "hall_home" else "", true)
		if not loaded or not _same_owner(): _refuse("The destination could not load."); return
	var response_msec := int(float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").arch.response_timeout_seconds) * 1000.0)
	var readiness_deadline := Time.get_ticks_msec() + response_msec
	while not str(game.call("pending_entry_for", permit.realm)).is_empty() and Time.get_ticks_msec() < readiness_deadline:
		await get_tree().physics_frame
		if not _same_owner(): _refuse("Your travel session changed."); return
	if not str(game.call("pending_entry_for", permit.realm)).is_empty(): _refuse("The destination has not settled."); return
	var world_node: Node3D = session.call("_portal_world_node", permit.realm)
	var actor: Node3D = game.call("find_player")
	if world_node == null or actor == null or not world_node.is_ancestor_of(actor): _refuse("The destination is not ready."); return
	var target := _arrival_target(world_node, permit)
	if not target.is_finite() or not world_node.has_method("ground_height_at"): _refuse("The arrival anchor has no ground."); return
	# The actual actor's collision footprint must fit. Physical support is
	# sampled at four surrounding points; no saved height or invented landing.
	var collision := actor.get_node_or_null(^"Collision") as CollisionShape3D
	if not actor is CharacterBody3D or collision == null or not collision.shape is CapsuleShape3D \
		or collision.disabled or actor.global_basis.get_scale() != Vector3.ONE:
		_refuse("The arrival collision is not ready."); return
	var radius := (collision.shape as CapsuleShape3D).radius
	var body := actor as CharacterBody3D
	# Co-op: another trainer may already stand on the anchor (two Home Keys in
	# a row). Take the first supported, unobstructed slot from the fixed,
	# host-authored list around it; the host accepts contact only at a slot.
	var landing := Vector3(INF, INF, INF)
	var reason := "The arrival anchor is obstructed."
	for slot: Vector3 in arrival_slots(target):
		var checked := _slot_landing(world_node, body, slot, radius)
		if checked.get("landing") is Vector3:
			landing = checked.landing
			target = slot
			break
		if slot == target: reason = str(checked.reason)
	if not landing.is_finite():
		_refuse(reason); return
	if not body.is_physics_processing() or body.get("_foundation_ground_contact_generation") == null:
		_refuse("The ordinary arrival controller is not processing."); return
	_pending.actor = weakref(body)
	_pending.world_node = weakref(world_node)
	_pending.contact_generation = int(body.get("_foundation_ground_contact_generation"))
	_pending.collision = weakref(collision)
	_pending.capsule = weakref(collision.shape)
	_pending.capsule_height = float(collision.shape.height)
	actor.global_position = landing
	if actor is CharacterBody3D: actor.velocity = Vector3.ZERO
	_pending.anchor = landing
	_pending.radius = radius
	# A terrain sample is only a proposed landing. The live physics body must
	# move through its ordinary controller and report actual walkable contact.
	# The physics-frame signal precedes the controller's move_and_slide. Yield
	# through the idle boundary as well so the seated body gets its first actual
	# controller evaluation before its independent contact response window starts.
	# Cold render work can consume the readiness deadline without any such tick.
	await get_tree().physics_frame
	if not _same_owner(): _refuse("Your travel session changed."); return
	await get_tree().process_frame
	if not _same_owner(): _refuse("Your travel session changed."); return
	var contact_deadline := Time.get_ticks_msec() + response_msec
	print("[portal-arrival] contact window generation=", body.get("_foundation_ground_contact_generation") if is_instance_valid(body) else -1,
		" seated_generation=", _pending.contact_generation, " window_msec=", response_msec,
		" readiness_deadline_passed=", Time.get_ticks_msec() >= readiness_deadline)
	while _same_owner() and not _grounded_actor(body) and Time.get_ticks_msec() < contact_deadline:
		await get_tree().physics_frame
	if not _same_owner() or not _grounded_actor(body):
		print("[portal-arrival] not grounded at the deadline: " + _grounded_failure(body))
		_refuse("The arrival has not reached supported ground."); return
	_pending.seated = true
	_pending.save_deadline_msec = Time.get_ticks_msec() + int(float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").home_key.response_timeout_seconds) * 1000.0)
	_save_arrival()

func _grounded_actor(actor: CharacterBody3D) -> bool:
	return is_instance_valid(actor) and actor.is_on_floor() \
		and actor.is_physics_processing() and _pending.has("actor") and _pending.actor.get_ref() == actor \
		and int(actor.get("_foundation_ground_contact_generation")) > int(_pending.get("contact_generation", -1)) \
		and actor.get("_foundation_ground_contact_position") is Vector3 \
		and actor.global_position.distance_to(actor.get("_foundation_ground_contact_position")) <= actor.safe_margin \
		and _pending.has("collision") and is_instance_valid(_pending.collision.get_ref()) \
		and _pending.collision.get_ref().get("disabled") == false \
		and _pending.collision.get_ref().get("shape") == _pending.capsule.get_ref() \
		and _pending.capsule.get_ref() is CapsuleShape3D \
		and _pending.capsule.get_ref().get("radius") == _pending.radius \
		and _pending.capsule.get_ref().get("height") == _pending.capsule_height \
		and actor.scale == Vector3.ONE and _pending.collision.get_ref().get("scale") == Vector3.ONE \
		and actor.get_floor_normal().angle_to(Vector3.UP) <= actor.floor_max_angle \
		and _pending.has("anchor") and actor.global_position.distance_to(_pending.anchor) <= float(_pending.radius) \
		and _pending.has("world_node") and is_instance_valid(_pending.world_node.get_ref()) \
		and _supported_capsule(_pending.world_node.get_ref(), actor, _pending.anchor, float(_pending.radius))

## Diagnostic only: the first _grounded_actor condition that fails.
func _grounded_failure(actor: CharacterBody3D) -> String:
	if not is_instance_valid(actor): return "no_actor"
	if not actor.is_on_floor(): return "not_on_floor pos=%s" % str(actor.global_position)
	if not actor.is_physics_processing(): return "not_processing"
	if int(actor.get("_foundation_ground_contact_generation")) <= int(_pending.get("contact_generation", -1)): return "no_new_contact"
	var contact: Variant = actor.get("_foundation_ground_contact_position")
	if not contact is Vector3: return "no_contact_position"
	if actor.global_position.distance_to(contact) > actor.safe_margin: return "contact_%.3fm_from_body" % actor.global_position.distance_to(contact)
	if actor.get_floor_normal().angle_to(Vector3.UP) > actor.floor_max_angle: return "floor_too_steep"
	if not _pending.has("anchor") or actor.global_position.distance_to(_pending.anchor) > float(_pending.get("radius", 0.0)):
		return "slid_%.2fm_from_anchor" % (actor.global_position.distance_to(_pending.anchor) if _pending.has("anchor") else -1.0)
	if not _pending.has("world_node") or not is_instance_valid(_pending.world_node.get_ref()): return "no_world_node"
	var support := _capsule_support_failure(_pending.world_node.get_ref(), actor, _pending.anchor, float(_pending.radius))
	if not support.is_empty(): return "capsule_unsupported:" + support
	return "collision_or_scale_changed"

func arrival_binding(envelope: Dictionary, permit: Dictionary) -> bool:
	var peer: int = int(permit.get("peer_id", 0))
	if _remote.has(peer):
		var original: Dictionary = _remote[peer]
		return original.envelope == envelope and original.permit == permit and original.owner_saved == true \
			and _remote_binding(peer, original)
	return not _pending.is_empty() and _same_owner() and _pending.get("seated") == true \
		and _pending.envelope == envelope and _pending.permit == permit \
		and ((_pending.get("journal_started") == true and _original_arrival_row(_pending.world.get_ref(), _pending)) \
			or _grounded_actor(_pending.game.get_ref().call("find_player") as CharacterBody3D))

func presentation_binding(envelope: Dictionary, permit: Dictionary, waiting: bool = false) -> bool:
	return not _pending.is_empty() and _same_owner() and _pending.envelope == envelope and _pending.permit == permit \
		and (not waiting or _pending.get("seated") == true)

func _process(delta: float) -> void:
	_retry_left -= delta
	if _retry_left > 0.0: return
	_retry_left = float(preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json").arch.refresh_seconds)
	if not _pending.is_empty() and _pending.get("seated") == true and not _pending.has("refused"):
		if _pending.get("save_wait_notified") != true and Time.get_ticks_msec() >= int(_pending.get("save_deadline_msec", 0)):
			_pending.save_wait_notified = true
			var owner: Node = _pending.session.get_ref()
			if owner != null: owner.call("portal_owner_save_waiting", self, _pending.envelope, _pending.permit)
		_save_arrival()
	for peer: int in _remote.keys():
		var original: Dictionary = _remote[peer]
		var session: Node = original.session.get_ref()
		if session == null or session.call("is_host") != true \
			or session.call("_game").get("world") != original.world.get_ref() \
			or session.call("_portal_envelope_valid", peer, original.envelope) != true:
			if session != null: session.call("_owner_passive_service").call("portal_departed", peer)
			_remote.erase(peer)
			continue
		if original.owner_saved != true:
			session.call("_owner_passive_service").call("portal_begin", peer,
				preload("res://scripts/net/owner_passive_preparation.gd").portal_request(original.envelope, original.permit))
			continue
		if not _remote_binding(peer, original): continue
		var journal: Dictionary = session.call("foundation_grounded_arrival", self, original.envelope, original.permit)
		if journal.get("durable") == true:
			original.journal_started = true
			# The guest is released once the arrival is durable; mint the reset
			# proof in this same frame, before any of its next inputs can arrive,
			# not after the (possibly retried) world save.
			if original.get("reset_minted") != true:
				original.reset_minted = true
				_confirm_travel_reset(session, peer, str(original.permit.realm))
		if journal.get("ok") != true or journal.get("saved") != true: continue
		_remote.erase(peer)
		session.call("_portal_reply", peer, original.envelope, {"ok": true, "saved": true, "durable": true,
			"arrival_applied": true, "arrived": true, "permit_id": original.permit.request_id, "reason": ""})

## The guest's Game drops its travel baseline while the arrival holds its
## owner record. This host-accepted placement is the proof that explains that
## one reset to the guest's owner-passive replay (as a fly landing does);
## without it the guest's next discovery is a travel_baseline_mismatch and
## every later owner-gated guest action is refused.
static func _confirm_travel_reset(session: Node, peer: int, realm: String) -> void:
	var lifecycle: Node = session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
	var actor: Node3D = lifecycle.call("remote_body", peer) as Node3D if lifecycle != null else null
	if actor == null or not actor.global_position.is_finite() or not session.has_method("owner_passive_travel_reset_confirmed"): return
	session.call("owner_passive_travel_reset_confirmed", peer, realm, actor.global_position, true)

func _same_owner() -> bool:
	if _pending.is_empty(): return false
	var session: Node = _pending.session.get_ref()
	var game: Node = _pending.game.get_ref()
	if game != null and _pending.get("seated") == true and str(game.get("current_realm")) != _pending.permit.realm: return false
	return session != null and game != null and (session.call("is_host") == true or session.call("is_active") == true) \
		and game.get("local") == _pending.owner.get_ref() and game.get("world") == _pending.world.get_ref() \
		and session.call("_authority_character", _pending.peer) == _pending.envelope.character_id \
		and game.get("world").reward_delivery_namespace == _pending.envelope.world_instance_id \
		and session.call("_altar_current_epoch") == _pending.envelope.session_epoch

func _save_arrival() -> void:
	if not _same_owner(): _refuse("Your travel session changed."); return
	var session: Node = _pending.session.get_ref()
	var game: Node = _pending.game.get_ref()
	if session.call("is_host") != true and _original_arrival_row(game.get("world"), _pending):
		session.call("report_portal_owner_saved", self, _pending.envelope, str(_pending.permit.request_id))
		return
	var saver: RefCounted = game.get("save_system")
	var actor := game.call("find_player") as CharacterBody3D
	var retained: bool = _pending.get("journal_started") == true and _original_arrival_row(game.get("world"), _pending)
	if not retained and (actor == null or not _grounded_actor(actor)): _refuse("The arrival support changed before it was saved."); return
	if saver == null or saver.call("fallback_busy") == true: return
	if _pending.get("pose_saved") != true:
		game.call("_capture_player_pose")
		if session.call("is_host") != true:
			var request := preload("res://scripts/net/owner_passive_preparation.gd").portal_request(_pending.envelope, _pending.permit)
			if session.call("_owner_passive_service").call("portal_pose_save", self, request) != true: return
		elif saver.call("save_character_prepared", game, _pending.envelope.character_id) != true: return
		_pending.pose_saved = true
	if not _same_owner() or (not retained and not _grounded_actor(actor)): _refuse("Your travel session changed."); return
	if session.call("is_host") != true:
		session.call("report_portal_owner_saved", self, _pending.envelope, str(_pending.permit.request_id))
		return
	var journal: Dictionary = session.call("foundation_grounded_arrival", self, _pending.envelope, _pending.permit)
	if journal.get("durable") == true and _original_arrival_row(game.get("world"), _pending): _pending.journal_started = true
	if journal.get("ok") != true or journal.get("saved") != true: return
	var envelope: Dictionary = _pending.envelope
	var peer: int = _pending.peer
	var permit_id: String = _pending.permit.request_id
	_pending.clear()
	session.call("_portal_reply", peer, envelope, {"ok": true, "saved": true, "durable": true, "arrival_applied": true, "arrived": true, "permit_id": permit_id, "reason": ""})

func _refuse(reason: String) -> void:
	if _pending.is_empty(): return
	var session: Node = _pending.session.get_ref()
	var envelope: Dictionary = _pending.envelope
	var peer: int = _pending.peer
	var permit_id: String = _pending.permit.request_id
	if session == null: return
	if session.call("is_host") == true:
		_pending.clear()
		session.call("_portal_reply", peer, envelope, {"ok": false, "reason": reason})
	else:
		_pending.refused = reason # Keep original correlation until exact no-effect settlement.
		session.call("report_portal_owner_refused", self, envelope, permit_id, reason)

func owner_finished(reply: Dictionary) -> void:
	var original: Dictionary = _pending if not _pending.is_empty() else _offered
	if original.is_empty() or reply.get("request_id") != original.envelope.request_id: return
	if reply.get("ok") == true and (reply.get("saved") != true or reply.get("permit_id") != original.permit.request_id): return
	_pending.clear()
	_offered.clear()

func owner_notice(peer: int, envelope: Dictionary, permit_id: String, refused: String = "") -> void:
	var original: Dictionary = _remote.get(peer, {})
	if original.is_empty() or original.envelope != envelope or original.permit.request_id != permit_id: return
	var session: Node = original.session.get_ref()
	if session == null or session.call("_portal_envelope_valid", peer, envelope) != true: return
	if not refused.is_empty():
		var request := preload("res://scripts/net/owner_passive_preparation.gd").portal_request(original.envelope, original.permit)
		if session.call("_owner_passive_service").call("portal_refused", peer, request, refused) == true:
			_remote.erase(peer) # Owner receives the exact saved-baseline no-effect completion.
		return
	original.owner_saved = true

func _remote_binding(peer: int, original: Dictionary) -> bool:
	var session: Node = original.session.get_ref()
	if session == null or session.call("is_host") != true or session.call("_game").get("world") != original.world.get_ref() \
		or session.call("_portal_envelope_valid", peer, original.envelope) != true: return false
	# Supported arrival was proved before the first durable journal. Its
	# original row now owns retries; walking after the write cannot force a
	# second trip or mint a second receipt while the owner ACK settles.
	if original.get("journal_started") == true:
		return _original_arrival_row(original.world.get_ref(), original)
	var lifecycle: Node = session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
	if lifecycle == null: return false
	var actor: CharacterBody3D = lifecycle.call("remote_body", peer)
	if actor == null: return false
	var contact: Dictionary = actor.call("foundation_ground_contact")
	var permit: Dictionary = original.permit
	if contact.get("character_id") != original.envelope.character_id or contact.get("realm") != permit.realm \
		or contact.get("world_namespace") != original.envelope.world_instance_id \
		or contact.get("session_epoch") != original.envelope.session_epoch \
		or contact.get("body_instance_id") != actor.get_instance_id() or not contact.get("position") is Vector3: return false
	var world_node: Node3D = session.call("_portal_world_node", str(permit.realm))
	if world_node == null or not world_node.is_ancestor_of(actor): return false
	var anchor := _arrival_target(world_node, permit)
	if not anchor.is_finite() or not world_node.has_method("ground_height_at"): return false
	var radius: float = float(contact.get("capsule_radius", 0.0))
	if radius <= 0.0: return false
	for target: Vector3 in arrival_slots(anchor):
		if _remote_slot_contact(world_node, actor, target, radius, contact.position): return true
	return false

func _remote_slot_contact(world_node: Node3D, actor: CharacterBody3D, target: Vector3, radius: float, at: Vector3) -> bool:
	var height: float = _landing_height(world_node, actor, target, radius)
	if not is_finite(height): return false
	for offset: Vector2 in [Vector2(-radius, 0), Vector2(radius, 0), Vector2(0, -radius), Vector2(0, radius)]:
		var support: float = _landing_height(world_node, actor, target + Vector3(offset.x, 0, offset.y), radius)
		if not is_finite(support) or absf(support - height) > tan(actor.floor_max_angle) * radius: return false
	var landing := Vector3(target.x, height + actor.safe_margin, target.z)
	return at.distance_to(landing) <= radius and _supported_capsule(world_node, actor, target, radius)

func _original_arrival_row(world: RefCounted, original: Dictionary) -> bool:
	var id: String = preload("res://scripts/creatures/essence.gd").training_delivery_id(original.envelope.world_instance_id, original.envelope.character_id)
	var row: Dictionary = world.reward_deliveries.get(id, {})
	return world.call("training_row_valid", row, original.envelope.world_instance_id, world.get("world_id")) == true \
		and row.get("character_id") == original.envelope.character_id \
		and row.get("session_id") == original.envelope.session_epoch \
		and row.get("action") == "portal_arrival" and row.get("intent") == {
		"permit_id": original.permit.request_id, "realm": original.permit.realm, "entry_id": original.permit.entry_id}

func _supported_capsule(world_node: Node3D, actor: CharacterBody3D, target: Vector3, radius: float) -> bool:
	return _capsule_support_failure(world_node, actor, target, radius).is_empty()

## "" when the live capsule is supported; otherwise which check failed.
func _capsule_support_failure(world_node: Node3D, actor: CharacterBody3D, target: Vector3, radius: float) -> String:
	# Terrain/scatter may finish streaming or change after the initial pose.
	# Recheck actual support and the complete live capsule before either owner
	# or host can turn a controller contact into a durable arrival.
	if world_node == null or actor == null or not world_node.is_ancestor_of(actor): return "actor_outside_world"
	var surfaces: Array[Dictionary] = []
	var center := _landing_hit(world_node, actor, target, radius)
	if center.is_empty(): return "no_ground_at_anchor"
	var height: float = center.position.y
	surfaces.append(center)
	for offset: Vector2 in [Vector2(-radius, 0), Vector2(radius, 0), Vector2(0, -radius), Vector2(0, radius)]:
		var surface := _landing_hit(world_node, actor, target + Vector3(offset.x, 0, offset.y), radius)
		if surface.is_empty() or absf(float(surface.position.y) - height) > tan(actor.floor_max_angle) * radius: return "uneven_support"
		surfaces.append(surface)
	var collision := actor.get_node_or_null(^"Collision") as CollisionShape3D
	if collision == null or collision.disabled or not collision.shape is CapsuleShape3D: return "no_capsule"
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	query.transform = collision.global_transform
	query.collision_mask = actor.collision_mask
	# Support is world geometry. A co-op trainer standing in the capsule's
	# reach is not missing ground; slot choice already avoids standing ones.
	var trainers := _other_trainer_rids(world_node, actor)
	query.exclude = [actor.get_rid()] + trainers
	var space := actor.get_world_3d().direct_space_state
	var overlaps: Array[Dictionary] = space.intersect_shape(query, 32)
	if overlaps.is_empty(): return ""
	if overlaps.size() == 32 or not actor.is_on_floor() or not is_finite(actor.safe_margin) \
		or actor.safe_margin <= 0.0 or actor.safe_margin > radius: return "overlap_%d_without_floor" % overlaps.size()
	# A settled controller can retain tiny walkable floor contact. Never waive
	# a whole floor RID: every overlapping shape must have an actual bounded
	# walkable recovery contact, and the complete vertically lifted capsule
	# must clear all bodies, including another shape on the same Hall body.
	var contacts := _walkable_contacts(actor, actor.global_transform, actor.safe_margin, trainers)
	if not _contacts_on_support(world_node, contacts, surfaces, actor.safe_margin): return "contacts_off_support"
	for overlap: Dictionary in overlaps:
		var matched := false
		for contact: Dictionary in contacts:
			if overlap.get("rid") == contact.rid and overlap.get("shape") == contact.shape: matched = true
		if not matched: return "overlap_not_floor:" + str(instance_from_id(overlap.get("collider_id", 0)).get_path() if is_instance_id_valid(overlap.get("collider_id", 0)) and instance_from_id(overlap.get("collider_id", 0)) is Node else "?")
	query.transform.origin.y += actor.safe_margin
	return "" if space.intersect_shape(query, 1).is_empty() else "lifted_capsule_blocked"

## Every other trainer body (remote proxies and this world's local rig).
func _other_trainer_rids(world_node: Node3D, actor: CharacterBody3D) -> Array[RID]:
	var rids: Array[RID] = []
	var bodies: Array[Node] = []
	if actor.is_inside_tree(): bodies = actor.get_tree().get_nodes_in_group(&"remote_trainer")
	var local := world_node.get_node_or_null(^"Player")
	if local != null: bodies.append(local)
	for body: Node in bodies:
		if body is CharacterBody3D and body != actor and world_node.is_ancestor_of(body): rids.append((body as CharacterBody3D).get_rid())
	return rids

func _walkable_contacts(actor: CharacterBody3D, from: Transform3D, depth_limit: float = -1.0, excluded: Array[RID] = []) -> Array[Dictionary]:
	var motion := PhysicsTestMotionParameters3D.new()
	motion.from = from
	motion.exclude_bodies = excluded
	motion.motion = Vector3.ZERO
	motion.margin = actor.safe_margin
	motion.recovery_as_collision = true
	motion.max_collisions = 32
	var result := PhysicsTestMotionResult3D.new()
	if not PhysicsServer3D.body_test_motion(actor.get_rid(), motion, result) \
		or result.get_collision_count() <= 0 or result.get_collision_count() == motion.max_collisions: return []
	var contacts: Array[Dictionary] = []
	for i in result.get_collision_count():
		var normal := result.get_collision_normal(i)
		var depth := result.get_collision_depth(i)
		if not normal.is_finite() or normal.length_squared() == 0.0 or normal.angle_to(Vector3.UP) > actor.floor_max_angle \
			or not is_finite(depth) or depth < 0.0 or (depth_limit >= 0.0 and depth > depth_limit) \
			or result.get_collider(i) is CharacterBody3D: return []
		contacts.append({"rid": result.get_collider_rid(i), "shape": result.get_collider_shape(i),
			"collider": result.get_collider(i), "normal": normal, "point": result.get_collision_point(i)})
	return contacts

func _contacts_on_support(world_node: Node3D, contacts: Array[Dictionary], surfaces: Array[Dictionary], margin: float) -> bool:
	if contacts.is_empty() or surfaces.size() != 5: return false
	var terrain := world_node.get_node_or_null(^"Terrain")
	for contact: Dictionary in contacts:
		if not contact.point.is_finite(): return false
		var matched := false
		for surface: Dictionary in surfaces:
			var same_shape: bool = contact.rid == surface.rid and contact.shape == surface.shape
			# Native dynamic collision and resident triangles can overlap exactly.
			# Accept only this world's actual Terrain3D equivalent floor plane,
			# never a different body or an entire shared Hall/scatter RID.
			var native_equivalent: bool = terrain != null and terrain.is_class("Terrain3D") and contact.collider == terrain
			# Capsule contacts at a triangle edge need not have its ray normal.
			# The same actual shape still needs a walkable contact on one of the
			# five witnessed planes. A cross-shape terrain alias additionally
			# needs the original matching-normal proof of equivalent support.
			if (same_shape or (native_equivalent and contact.normal.is_equal_approx(surface.normal))) \
				and absf(surface.normal.dot(contact.point - surface.position)) <= margin: matched = true
		if not matched: return false
	return true

## The anchor first, then the configured ring (portals.json arch.arrival_slots_m).
## Offsets are authored data; no client coordinate ever enters this list.
static func arrival_slots(anchor: Vector3) -> Array[Vector3]:
	var slots: Array[Vector3] = [anchor]
	var config: Variant = preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json")
	var offsets: Variant = config.get("arch", {}).get("arrival_slots_m", []) if config is Dictionary else []
	if not offsets is Array: return slots
	for offset: Variant in offsets:
		if offset is Array and offset.size() == 2 and (offset[0] is float or offset[0] is int) \
			and (offset[1] is float or offset[1] is int) and is_finite(float(offset[0])) and is_finite(float(offset[1])) \
			and Vector2(float(offset[0]), float(offset[1])) != Vector2.ZERO:
			slots.append(anchor + Vector3(float(offset[0]), 0.0, float(offset[1])))
	return slots

func _slot_landing(world_node: Node3D, body: CharacterBody3D, target: Vector3, radius: float) -> Dictionary:
	var height := _landing_height(world_node, body, target, radius)
	if not is_finite(height): return {"reason": "The arrival anchor has no supported ground."}
	var tolerance := tan(body.floor_max_angle) * radius
	for offset: Vector2 in [Vector2(-radius, 0), Vector2(radius, 0), Vector2(0, -radius), Vector2(0, radius)]:
		var support := _landing_height(world_node, body, target + Vector3(offset.x, 0, offset.y), radius)
		if not is_finite(support) or absf(support - height) > tolerance: return {"reason": "The arrival anchor is not supported."}
	var landing := _capsule_landing(world_node, body, target, radius)
	if not landing.is_finite(): return {"reason": "The arrival anchor is obstructed."}
	return {"landing": landing}

func _capsule_landing(world_node: Node3D, actor: CharacterBody3D, target: Vector3, radius: float) -> Vector3:
	var refused := Vector3(INF, INF, INF)
	if world_node == null or actor == null or not world_node.is_ancestor_of(actor) \
		or not target.is_finite() or not is_finite(radius) or radius <= 0.0 \
		or not is_finite(actor.safe_margin) or actor.safe_margin <= 0.0 or actor.safe_margin > radius: return refused
	var collision := actor.get_node_or_null(^"Collision") as CollisionShape3D
	if collision == null or collision.disabled or collision.top_level or not collision.shape is CapsuleShape3D: return refused
	if (collision.shape as CapsuleShape3D).radius != radius: return refused
	var surfaces: Array[Dictionary] = []
	var height := NAN
	var highest := -INF
	for offset: Vector2 in [Vector2.ZERO, Vector2(-radius, 0), Vector2(radius, 0), Vector2(0, -radius), Vector2(0, radius)]:
		var surface := _landing_hit(world_node, actor, target + Vector3(offset.x, 0, offset.y), radius)
		if surface.is_empty(): return refused
		var support: float = surface.position.y
		if surfaces.is_empty(): height = support
		if absf(support - height) > tan(actor.floor_max_angle) * radius: return refused
		highest = maxf(highest, support)
		surfaces.append(surface)
	var start := Vector3(target.x, height + radius, target.z)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = collision.shape
	var proposed_pose := actor.global_transform
	proposed_pose.origin = start
	query.transform = proposed_pose * collision.transform
	query.collision_mask = actor.collision_mask
	query.exclude = [actor.get_rid()]
	var space := actor.get_world_3d().direct_space_state
	# cast_motion ignores starting overlaps; reject them explicitly.
	if not space.intersect_shape(query, 1).is_empty(): return refused
	query.motion = Vector3(0, -2.0 * radius, 0)
	var fractions := space.cast_motion(query)
	if fractions.size() != 2 or not is_finite(fractions[0]) or not is_finite(fractions[1]) \
		or fractions[0] < 0.0 or fractions[0] > fractions[1] or fractions[1] >= 1.0: return refused
	# Inspect the first unsafe pose as well: a wall, ceiling or another actor
	# must not masquerade as the downward floor hit.
	var unsafe_pose := actor.global_transform
	unsafe_pose.origin = start + query.motion * fractions[1]
	if not _contacts_on_support(world_node, _walkable_contacts(actor, unsafe_pose), surfaces, actor.safe_margin): return refused
	# The physical cast returns a safe/unsafe bracket. Its measured width is
	# the solver's clearance bound; do not substitute an invented height bias.
	var cast_clearance: float = absf(query.motion.y) * (fractions[1] - fractions[0])
	var candidate_y := _cast_landing_y(float(start.y), float(query.motion.y), float(fractions[0]),
		float(actor.safe_margin), highest, cast_clearance)
	var maximum_y: float = highest + actor.safe_margin + cast_clearance
	if not is_finite(maximum_y): return refused
	var encoded_maximum_y := Vector3(0, maximum_y, 0).y
	query.motion = Vector3.ZERO
	# At high world coordinates, encoding the start can put the fraction
	# candidate above its scalar ceiling; native cast and static shape solvers
	# can also disagree about clearance. Test a NEW position at the unchanged
	# measured ceiling in those cases. Never accept the rejected fraction
	# candidate, enlarge the bound, or bypass its actual unsafe floor contact.
	for proposed_y: float in [candidate_y, maximum_y]:
		if not is_finite(proposed_y) or proposed_y > maximum_y: continue
		var landing := Vector3(target.x, proposed_y, target.z)
		if not landing.is_finite() or landing.distance_to(Vector3(target.x, height, target.z)) > radius \
			or landing.y > encoded_maximum_y: continue
		proposed_pose.origin = landing
		query.transform = proposed_pose * collision.transform
		if space.intersect_shape(query, 1).is_empty(): return landing
	return refused

static func _cast_landing_y(start_y: float, motion_y: float, safe_fraction: float, margin: float, highest: float, cast_clearance: float) -> float:
	# Vector3 rounds each arithmetic operation to float32. Evaluate the actual
	# cast coordinates once as scalars before encoding the final pose; otherwise
	# accumulated rounding can reject a valid flat-floor boundary by nanometers.
	# The scalar check still refuses values above the physical cast bound even
	# when both would encode to the same Vector3 coordinate.
	var candidate_y := start_y + motion_y * safe_fraction + margin
	var maximum_y := highest + margin + cast_clearance
	return candidate_y if is_finite(candidate_y) and is_finite(maximum_y) and candidate_y <= maximum_y else NAN

func _landing_height(world_node: Node3D, actor: CharacterBody3D, at: Vector3, radius: float) -> float:
	var hit := _landing_hit(world_node, actor, at, radius)
	return NAN if hit.is_empty() else float(hit.position.y)

func _landing_hit(world_node: Node3D, actor: CharacterBody3D, at: Vector3, radius: float) -> Dictionary:
	# The terrain/stack resolver selects the authored surface neighborhood.
	# Its height is not the collider: the Hall's real nave slab stands 1cm
	# above terrain. Measure that nearby physical floor before testing the
	# complete capsule; a missing, steep or obstructed support stays refused.
	var terrain := _ground_height(world_node, at)
	if not is_finite(terrain) or actor == null or not actor.is_inside_tree() or radius <= 0.0: return {}
	var ray := PhysicsRayQueryParameters3D.create(
		Vector3(at.x, terrain + radius, at.z), Vector3(at.x, terrain - radius, at.z), actor.collision_mask, [actor.get_rid()] + _other_trainer_rids(world_node, actor))
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(ray)
	if hit.is_empty() or not hit.get("position") is Vector3 or not hit.get("normal") is Vector3 \
		or not hit.position.is_finite() or not hit.normal.is_finite() \
		or hit.normal.angle_to(Vector3.UP) > actor.floor_max_angle \
		or hit.get("collider") is CharacterBody3D: return {}
	return hit

func _ground_height(world_node: Node3D, at: Vector3) -> float:
	# The ordinary realm resolver selects the correct stacked Cloudreach
	# surface from the authored target Y; other realms retain terrain height.
	return float(world_node.call("ground_height_near", at)) if world_node.has_method("ground_height_near") \
		else float(world_node.call("ground_height_at", at.x, at.z))

func _arrival_target(world_node: Node3D, permit: Dictionary) -> Vector3:
	var invalid := Vector3(INF, INF, INF)
	var target := invalid
	if permit.entry_id == "hall_home" or (permit.realm == "meadows" and permit.entry_id == "meadows_entry"):
		for hall: Node in get_tree().get_nodes_in_group("crossing_halls"):
			if world_node.is_ancestor_of(hall):
				if target.is_finite(): return invalid
				target = hall.call("home_arrival")
		return target
	for stone: Node in get_tree().get_nodes_in_group("waystones"):
		if world_node.is_ancestor_of(stone) and stone.get("waystone_id") == permit.entry_id:
			if target.is_finite(): return invalid
			target = preload("res://scripts/world/waystone.gd").resolve_position(world_node, stone.get("_row"), true)
	if target.is_finite(): return target
	# The initial portal has an authored ordinary realm entry, before any
	# personal waystone exists. Resolve that exact entry with the real realm.
	var config: Dictionary = preload("res://scripts/data/redesign_data.gd").json("res://data/config/portals.json")
	var canonical: bool = false
	for arch: Dictionary in config.arches:
		var realm: String = "water" if arch.biome == "tidewake" else str(arch.biome)
		if arch.get("kind") == "live" and realm == permit.realm and arch.entry_id == permit.entry_id: canonical = true
	if not canonical or not world_node.has_method("entry_anchor"): return invalid
	var anchor: Variant = world_node.call("entry_anchor", str(permit.entry_id))
	if anchor is Vector3: return anchor
	if not anchor is Dictionary or not anchor.get("position") is Array or anchor.position.size() != 3: return invalid
	for value: Variant in anchor.position:
		if not (value is int or value is float) or not is_finite(float(value)): return invalid
	return Vector3(float(anchor.position[0]), float(anchor.position[1]), float(anchor.position[2]))
