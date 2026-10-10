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
## Solo/host: the release commits locally through the host authority.
## Guest: the release is sent as a Foundation request; the host pays only for
## a creature in its admitted record of this character (a catch from this
## session is untyped and unknown to it). A creature the host does not hold,
## or a release the host refuses, still goes free locally with no payout and
## a readable reason: the payout is refused, never the release. Water claims
## on a guest keep their own path.
signal release_completed(release_id: String, result: Dictionary)

const NODE_NAME := "EssenceReleaseService"
const ESSENCE := preload("res://scripts/creatures/essence.gd")
const RULES := preload("res://scripts/net/character_action_rules.gd")
const PARTY := preload("res://autoload/party.gd")
const ACTION := "essence_release"

var _game: Node
## release_id -> {"intent", "pending": WeakRef, "pending_uid", "released_uid", "settling"}
var _requests: Dictionary = {}
var _prefetched: RefCounted
const STALE_RETRIES := 3
const REFRESH_FRAMES := 600


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


func _guest_owner() -> bool:
	var session := _session()
	return enabled() and session != null and session.call("is_host") != true and session.call("is_active") == true \
		and session.has_method("request_essence_release") and _game.get("local") != null


func _host_owner() -> bool:
	var session := _session()
	return enabled() and session != null and session.call("is_host") == true \
		and _game.get("local") != null and _game.get("world") != null


## Ordinary pending catches only: no Foundation offer, no Water claim, and
## only on the host/solo owner whose own record the host admits.
func owns_pending_capture(pending: RefCounted) -> bool:
	if pending == null or not (_host_owner() or _guest_owner()) or _game.get("pending_catch") != pending: return false
	for meta: StringName in [&"foundation_capture_offer", &"foundation_capture_traits"]:
		if pending.has_meta(meta): return false
	for key: String in _requests:
		if _requests[key].pending.get_ref() == pending: return true
	# Only the full-belt ceremony; a free-slot catch keeps its ordinary path.
	if pending.has_meta(&"water_capture_claim"):
		if not _host_owner(): return false
		var water := _water(pending)
		if water == null or water.call("is_guardian_offer", pending) == true: return false
	var party: RefCounted = _game.get("party")
	var full: bool = party != null and party.call("is_full") == true and not str(pending.get("uid")).is_empty()
	if full and _guest_owner() and _prefetched != pending:
		_prefetched = pending # Once per pending catch: ask for the admitted view.
		_session().call("homestead_personal_view")
	return full


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
	if _guest_owner(): return _guest_quote(pending_uid, released_uid, true)
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


## The guest's quote reads the host's admitted view of this character. A
## creature it does not hold quotes no payout (and says why on release).
func _guest_quote(pending_uid: String, released_uid: String, fetch: bool = false) -> Dictionary:
	# The cached admitted view; only a player-paced quote asks for a fresh one.
	if fetch: _session().call("homestead_personal_view")
	var cached: Variant = _session().get("_foundation_personal_cache")
	var view: Dictionary = cached if cached is Dictionary else {}
	var quote := {"ok": true, "pending_uid": pending_uid, "released_uid": released_uid,
		"ceremony_id": "release_ceremony:" + pending_uid,
		"expected_character_revision": maxi(int(view.get("registry_revision", 0)), 0), "payout": []}
	if released_uid.is_empty(): return quote
	var found: Dictionary = {}
	for row: Variant in view.get("party", []):
		if row is Dictionary and row.get("uid") == released_uid: found = row
	if view.is_empty() or not view.get("registry_revision") is int: quote.unpaid_reason = "the host has not shared your saved team yet"
	elif found.is_empty(): quote.unpaid_reason = "the host has not saved this creature with your team"
	elif view.get("party", []).size() != PARTY.MAX_CREATURES: quote.unpaid_reason = "the host's saved team is not full"
	else:
		quote.payout = ESSENCE.release_payout(found, ESSENCE.config())
		if quote.payout.is_empty(): quote.unpaid_reason = "this creature has no release essence"
	return quote


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
	if _guest_owner() and not released.is_empty():
		var quote := _guest_quote(str(pending.get("uid")), released)
		_requests[id].guest = true
		if quote.has("unpaid_reason"):
			_release_unpaid(id, str(quote.unpaid_reason))
			return
		_requests[id].expected_revision = int(quote.expected_character_revision)
		var session := _session()
		if not session.is_connected("foundation_reply_received", _on_foundation_reply):
			session.connect("foundation_reply_received", _on_foundation_reply)
	reconcile_release(id)


func reconcile_release(id: String) -> void:
	if not _requests.has(id): return
	var request: Dictionary = _requests[id]
	if request.released_uid.is_empty():
		# Declining the newcomer is not a transaction: it goes free, nothing paid.
		_finish(id, {"ok": true, "resolved": true})
		return
	if request.get("guest") == true:
		_reconcile_guest(id)
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


func _reconcile_guest(id: String) -> void:
	var request: Dictionary = _requests[id]
	var local: RefCounted = _game.get("local")
	var receipts: Variant = local.get("redesign_character").get("release_receipts") if local != null and local.get("redesign_character") != null else []
	var owned := false
	for creature: RefCounted in _game.get("party").call("members"): owned = owned or str(creature.get("uid")) == request.released_uid
	if receipts is Array and receipts.has("release:" + request.released_uid) and not owned:
		_finish(id, {"ok": true, "resolved": true}) # The owner applied and saved the host's row.
		return
	if request.has("unpaid_reason"):
		_release_unpaid(id, str(request.unpaid_reason)) # Retried until the owner guard opens.
		return
	if request.submitted: return
	var session := _session()
	if request.has("refresh_from") and session != null:
		var quote := _guest_quote(request.pending_uid, request.released_uid)
		if quote.has("unpaid_reason"):
			_release_unpaid(id, str(quote.unpaid_reason))
			return
		if int(quote.expected_character_revision) == int(request.refresh_from):
			# Fresh view not here yet. An unchanged revision past the bound means
			# the refusal was not staleness: release unpaid rather than wait.
			request.refresh_frames = int(request.get("refresh_frames", 0)) + 1
			if int(request.refresh_frames) > REFRESH_FRAMES:
				_release_unpaid(id, "the host could not confirm your saved team")
			return
		request.expected_revision = int(quote.expected_character_revision)
		request.erase("refresh_from")
	if session == null or session.call("is_active") != true:
		if request.get("reported_unavailable") != true:
			request.reported_unavailable = true
			release_completed.emit(id, {"ok": false, "resolved": false, "code": "release_host_unavailable"})
		return
	request.reported_unavailable = false
	request.submitted = true
	var result: Dictionary = session.call("request_essence_release", request.pending_uid, request.intent, request.expected_revision)
	_on_guest_result(id, result)


func _on_foundation_reply(envelope: Dictionary, result: Dictionary) -> void:
	if envelope.get("op") != ACTION: return
	for id: String in _requests.keys():
		if _requests[id].get("guest") == true and ESSENCE._equivalent(envelope.get("intent"), _requests[id].intent): _on_guest_result(id, result)


## Durable or still in flight: wait for the owner's own saved row. A refusal
## before any durable row frees the creature locally without a payout.
func _on_guest_result(id: String, result: Dictionary) -> void:
	if not _requests.has(id) or result.get("ok") == true or result.get("durable") == true: return
	var code := str(result.get("code", ""))
	if code in ["awaiting_saved_decision", "owner_passive_checkpoint_pending", "owner_passive_original_pending"]: return
	var request: Dictionary = _requests[id]
	if code == "source_or_revision_changed" and int(request.get("stale_retries", 0)) < STALE_RETRIES:
		# Refused with no effect: re-read the admitted revision, send once more.
		request.stale_retries = int(request.get("stale_retries", 0)) + 1
		request.refresh_from = request.expected_revision
		request.refresh_frames = 0
		request.submitted = false
		_session().call("homestead_personal_view")
		return
	_release_unpaid(id, "the host refused the payout (%s)" % code)


## The release itself is never refused: the legacy local release, no payout.
func _release_unpaid(id: String, reason: String) -> void:
	var request: Dictionary = _requests[id]
	# Remembered first: every early return below is retried each frame by
	# _reconcile_guest, so a refused payout can never hold the release.
	request.unpaid_reason = reason
	var pending: RefCounted = request.pending.get_ref()
	var party: RefCounted = _game.get("party")
	if pending == null or _game.get("pending_catch") != pending:
		_requests.erase(id)
		release_completed.emit(id, {"ok": false, "resolved": true, "code": "newcomer_unavailable"})
		return
	if party == null: return
	if party.has_method("owner_mutation_blocked") and party.call("owner_mutation_blocked") == true: return
	var index := -1
	for i: int in int(party.call("size")):
		if str((party.call("at", i) as RefCounted).get("uid")) == request.released_uid: index = i
	if index < 0:
		# The chosen creature already left (and no saved host row explains it):
		# nothing to free, so the newcomer stays on its seam; say so, once.
		_requests.erase(id)
		release_completed.emit(id, {"ok": false, "resolved": true, "code": "release_target_missing"})
		return
	if party.call("remove_at", index) == null: return
	party.call("add", pending)
	_game.set("pending_catch", null)
	# The released creature's character record leaves with it, as the paid
	# release (essence.stage_release) does; a record for a creature no longer
	# owned makes every later character save refuse.
	var local: Object = _game.get("local")
	var record: Variant = local.get("redesign_character") if local != null else null
	if record is Dictionary and record.get("creatures") is Dictionary: (record.creatures as Dictionary).erase(request.released_uid)
	_requests.erase(id)
	if _game.has_method("push_world_message"): _game.call("push_world_message", "Released with no essence: " + reason + ".")
	release_completed.emit(id, {"ok": true, "resolved": true, "unpaid_reason": reason})


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
	elif pending.has_meta(&"water_capture_claim"):
		# The claim service no longer owns it: only its saved receipt may grant
		# this newcomer (tab_creatures._drop_stale_claim); the host re-presents.
		_requests.erase(id)
		release_completed.emit(id, {"ok": false, "resolved": true, "code": "capture_claim_pending"})
		return
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
