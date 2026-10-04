extends Node

## F27#1 release payout for the ORDINARY catch-overflow ceremony (a catch
## parked on Game.pending_catch by encounter_director._resolve_catch). It
## implements tab_creatures' typed release service shape and commits the
## release as the existing `essence_release` character action: the host's
## essence.stage_release recomputes the payout from its own admitted record,
## journals it with the "release:<uid>" receipt, the owner applies and saves,
## and only then does the newcomer take the freed holder. No balance, receipt
## or creature snapshot is supplied by this service.
##
## Scope: the solo/host owner only. A guest's ordinary catch is not admitted by
## the host (catches are untyped), so a guest keeps the legacy release with no
## payout until typed catches land; this service never claims a guest's catch.
signal release_completed(release_id: String, result: Dictionary)

const NODE_NAME := "EssenceReleaseService"
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const RULES := preload("res://scripts/net/character_action_rules.gd")
const PARTY := preload("res://autoload/party.gd")
const ACTION := "essence_release"

var _game: Node
## release_id -> {"intent", "pending": WeakRef, "pending_uid", "released_uid", "settling"}
var _requests: Dictionary = {}


static func attach(game: Node) -> Node:
	if game == null or not game.is_inside_tree(): return null
	var existing := game.get_node_or_null(NodePath(NODE_NAME))
	if existing != null: return existing if existing.get_script() == load("res://scripts/net/essence_release_service.gd") else null
	var service: Node = load("res://scripts/net/essence_release_service.gd").new()
	service.name = NODE_NAME
	service._game = game
	# The ceremony pauses the tree while the Team screen holds the choice; the
	# saved decision must still settle underneath it.
	service.process_mode = Node.PROCESS_MODE_ALWAYS
	game.add_child(service)
	return service


static func enabled() -> bool:
	return ESSENCE.config().get("ordinary_release_payout_enabled") == true


func _session() -> Node:
	return _game.get("session") as Node if is_instance_valid(_game) else null


func _host_owner() -> bool:
	var session := _session()
	return enabled() and session != null and session.call("is_host") == true \
		and _game.get("local") != null and _game.get("world") != null


## Ordinary pending catches only: no Foundation offer, no Water claim, and
## only on the host/solo owner whose own record the host admits.
func owns_pending_capture(pending: RefCounted) -> bool:
	if pending == null or not _host_owner() or _game.get("pending_catch") != pending: return false
	for meta: StringName in [&"foundation_capture_offer", &"foundation_capture_traits"]:
		if pending.has_meta(meta): return false
	for key: String in _requests:
		if _requests[key].pending.get_ref() == pending: return true
	return not str(pending.get("uid")).is_empty() # Water claims never reach here (tab_creatures).


func _admitted() -> Dictionary:
	var session := _session()
	return session.call("admitted_character_state", session.call("local_peer_id")) if session != null else {}


func _context(pending_uid: String) -> Dictionary:
	var session := _session()
	var character: String = session.call("_authority_character", session.call("local_peer_id"))
	var authority: Object = session.get("_character_authority")
	if character.is_empty() or authority == null: return {}
	return {"character_id": character, "expected_revision": int(authority.call("revision", character)),
		"source_key": "release_ceremony:" + pending_uid, "in_range": true, "in_combat": false,
		"release_ceremony": true, "foundation_runtime_authorized": true}


func quote_release(pending_uid: String, released_uid: String) -> Dictionary:
	var pending: RefCounted = _game.get("pending_catch") if is_instance_valid(_game) else null
	if pending == null or str(pending.get("uid")) != pending_uid or not owns_pending_capture(pending): return {}
	var admitted := _admitted()
	if admitted.is_empty(): return {}
	var context := _context(pending_uid)
	if context.is_empty(): return {}
	var payout: Array = []
	if not released_uid.is_empty():
		var found: Dictionary = {}
		for row: Variant in admitted.get("party", []):
			if row is Dictionary and row.get("uid") == released_uid: found = row
		if found.is_empty() or admitted.party.size() != PARTY.MAX_CREATURES: return {}
		payout = ESSENCE.release_payout(found, ESSENCE.config())
		if payout.is_empty(): return {}
	return {"ok": true, "pending_uid": pending_uid, "released_uid": released_uid,
		"ceremony_id": "release_ceremony:" + pending_uid,
		"expected_character_revision": int(context.expected_revision), "payout": payout}


func submit_release(request: Dictionary) -> void:
	var id := str(request.get("release_id", ""))
	var pending: RefCounted = _game.get("pending_catch") if is_instance_valid(_game) else null
	if not ESSENCE._component(id) or pending == null or str(pending.get("uid")) != request.get("pending_uid") \
			or not owns_pending_capture(pending) or _requests.has(id):
		release_completed.emit(id, {"ok": false, "resolved": true, "code": "release_unavailable"})
		return
	var released := str(request.get("released_uid", ""))
	_requests[id] = {"intent": {"release_id": id, "creature_uid": released}, "pending": weakref(pending),
		"pending_uid": str(pending.get("uid")), "released_uid": released,
		"expected_revision": int(request.get("expected_character_revision", -1)), "submitted": false}
	reconcile_release(id)


func reconcile_release(id: String) -> void:
	if not _requests.has(id): return
	var request: Dictionary = _requests[id]
	if request.released_uid.is_empty():
		# Declining the newcomer is not a transaction: it goes free, nothing paid.
		_finish(id, {"ok": true, "resolved": true})
		return
	var session := _session()
	if session == null or not _host_owner():
		release_completed.emit(id, {"ok": false, "resolved": false, "code": "release_host_unavailable"})
		return
	var world: RefCounted = _game.get("world")
	var character: String = session.call("_authority_character", session.call("local_peer_id"))
	var row: Variant = world.reward_deliveries.get(ESSENCE.training_delivery_id(world.reward_delivery_namespace, character))
	if row is Dictionary and row.get("action") == ACTION and ESSENCE._equivalent(row.get("intent"), request.intent):
		var decision: Dictionary = session.call("_foundation_decision", session.call("local_peer_id"), row)
		if decision.get("ok") == true and decision.get("owner_saved") == true: _finish(id, decision)
		return # Durable original: wait for its owner save/ACK, never restage.
	if request.submitted: return
	var saver: RefCounted = _game.get("save_system")
	if saver == null: return
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true: return
	var admitted := _admitted()
	var context := _context(request.pending_uid)
	if admitted.is_empty() or context.is_empty() or int(context.expected_revision) != request.expected_revision:
		_requests.erase(id)
		release_completed.emit(id, {"ok": false, "resolved": true, "code": "stale_revision"})
		return
	var authority: RefCounted = session.get("_character_authority")
	var result := RULES.commit_host_action(authority, session.get_node_or_null(^"LedgerRpc"),
		int(session.call("local_peer_id")), character, int(context.expected_revision), ACTION, request.intent, context)
	request.submitted = result.get("durable") == true
	if result.get("durable") != true:
		_requests.erase(id)
		release_completed.emit(id, {"ok": false, "resolved": true, "code": str(result.get("code", "release_refused"))})
		return
	# A solo/host owner usually saves and ACKs inside the publish; settle now.
	reconcile_release(id)


func _process(_delta: float) -> void:
	for id: String in _requests.keys(): reconcile_release(id)


## The saved release is the owner's own durable state; the newcomer then
## takes the freed holder through the ordinary party add.
func _finish(id: String, decision: Dictionary) -> void:
	var request: Dictionary = _requests[id]
	var pending: RefCounted = request.pending.get_ref()
	var party: RefCounted = _game.get("party")
	if pending != null and _game.get("pending_catch") == pending:
		if not request.released_uid.is_empty():
			if party.has_method("owner_mutation_blocked") and party.call("owner_mutation_blocked") == true: return
			if not party.call("add", pending): return # Retried next frame; never a sixth.
		_game.set("pending_catch", null)
	_requests.erase(id)
	var result := decision.duplicate(true)
	result.ok = true
	result.resolved = true
	release_completed.emit(id, result)
