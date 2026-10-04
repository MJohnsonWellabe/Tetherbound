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
## A Tidewake Water capture claim the host's own claim service presented
## (scripts/net/water_capture_claims.gd) is routed the same way: the typed
## release pays and frees the holder, then the claim settles the newcomer
## through its own durable receipt. A Guardian offer keeps its own path.
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
	# Only the full-belt ceremony; a free-slot catch keeps its ordinary path.
	if pending.has_meta(&"water_capture_claim"):
		var water := _water(pending)
		if water == null or water.call("is_guardian_offer", pending) == true: return false
	var party: RefCounted = _game.get("party")
	return party != null and party.call("is_full") == true and not str(pending.get("uid")).is_empty()


## Tidewake's capture claim service, only while it owns this pending catch.
func _water(pending: RefCounted) -> Node:
	var water := _game.get_node_or_null(^"Session/LedgerRpc/WaterCaptureClaims") if is_instance_valid(_game) else null
	return water if water != null and water.call("owns_pending", pending) == true else null


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
	var holder := -1
	var party: RefCounted = _game.get("party")
	for i: int in int(party.call("size")) if party != null else 0:
		if str((party.call("at", i) as RefCounted).get("uid")) == released: holder = i
	_requests[id] = {"intent": {"release_id": id, "creature_uid": released}, "pending": weakref(pending),
		"pending_uid": str(pending.get("uid")), "released_uid": released, "holder": holder,
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
		if request.get("reported_unavailable") != true:
			request.reported_unavailable = true # Once per outage, not per frame.
			release_completed.emit(id, {"ok": false, "resolved": false, "code": "release_host_unavailable"})
		return
	request.reported_unavailable = false
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


## The Water ceremony seats the newcomer in the holder the player freed, as
## its legacy settle did. Order only: a failed save just keeps the appended
## order, which is still the same five owned creatures.
func _seat_in_released_holder(newcomer: RefCounted, holder: int) -> void:
	var party: RefCounted = _game.get("party")
	var from: int = party.call("members").find(newcomer) if party != null else -1
	if from < 0 or holder < 0 or holder >= int(party.call("size")) or from == holder: return
	party.call("move", from, holder)
	var saver: RefCounted = _game.get("save_system")
	if saver != null and saver.has_method("save_character"): saver.call("save_character", _game, str(_game.get("local").get("character_id")))


func _process(_delta: float) -> void:
	for id: String in _requests.keys(): reconcile_release(id)


## The saved release is the owner's own durable state; the newcomer then
## takes the freed holder through the ordinary party add.
func _finish(id: String, decision: Dictionary) -> void:
	var request: Dictionary = _requests[id]
	var pending: RefCounted = request.pending.get_ref()
	var party: RefCounted = _game.get("party")
	if pending == null or _game.get("pending_catch") != pending:
		# The newcomer left the seam (the saved release stands): say so, never
		# report a joined newcomer that is not there.
		_requests.erase(id)
		release_completed.emit(id, {"ok": false, "resolved": true, "code": "newcomer_unavailable"})
		return
	var water := _water(pending)
	if water != null:
		if party.has_method("owner_mutation_blocked") and party.call("owner_mutation_blocked") == true: return
		# Released: the newcomer takes the freed holder under the claim's own
		# saved receipt. Declined: the claim saves the refusal (index 5 is the
		# newcomer). A failed save keeps the claim; retried next frame.
		var settled: Dictionary = water.call("complete_pending_capture", PARTY.MAX_CREATURES if request.released_uid.is_empty() else -1)
		if settled.get("ok") != true: return
		_seat_in_released_holder(pending, int(request.get("holder", -1)))
	else:
		if not request.released_uid.is_empty():
			if party.has_method("owner_mutation_blocked") and party.call("owner_mutation_blocked") == true: return
			if not party.call("add", pending): return # Retried next frame; never a sixth.
		_game.set("pending_catch", null)
	_requests.erase(id)
	var result := decision.duplicate(true)
	result.ok = true
	result.resolved = true
	release_completed.emit(id, result)
