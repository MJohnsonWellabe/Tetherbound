extends RefCounted

## Exact owner-input replay before an ORIGINAL retained research duty. This
## never installs a host candidate into the owner or replaces an immutable row.
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const PREP := preload("res://scripts/net/owner_passive_preparation.gd")
const HASH := preload("res://scripts/net/research_passive_preparation.gd")
const REWARD := preload("res://scripts/net/reward_delivery.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const E := preload("res://scripts/creatures/essence.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const GROOM := preload("res://scripts/net/groom_passive_sync.gd")
const RESEARCH := preload("res://scripts/creatures/research_actions.gd")
const CLOUD_MAP := preload("res://scripts/world/cloudreach_map_state.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")
const REQUEST_KINDS := ["foundation_request", "altar_spend", "manual_refine", "altar_traits", "portal_arrival", "waystone_touch", "home_key", "tether_item"]
const REQUEST_ACTIONS := ["station_craft", "feast_cook", "feast_feed", "candy_feed", "relic_hang", "relic_power", "master_chest", "essence_release", "tether_pouch", "trainer_equip"]
const RETAINED_ACTIONS := ["research_event", "master_win", "boss_relic", "combat_mastery", "combat_round_reward", "wild_defeat_share"]
const MAX_BUFFER := 120000
const MAX_BATCH := 64
## Owner: without new acknowledgements for this long, resend the window.
const RESEND_STALL_S := 1.5
const CHECKPOINT_RESEND_S := 1.0
const MAX_PEERS := 4
const MAX_SPEED := 40.0
## The recorder starts before the existing connection+snapshot handshake.
## This bounded initial allowance does not replace or extend those deadlines.
const ADMISSION_ALLOWANCE_S := 80.0
const INITIAL_POSE_LAG_S := 2.0
## Hard bound on one peer's pose ring (INITIAL_POSE_LAG_S at 60 physics ticks
## per second is 120); a slower or faster tick only changes how many fit.
const MAX_POSE_SAMPLES := 256
## A live-body endpoint match is horizontal within this distance...
const ENDPOINT_HORIZONTAL_M := 2.0
## ...and vertical within this one. The owner can report an endpoint while its
## body is still airborne (a placement, an arrival or a jump in the air) while
## the host's copy has already settled on the floor below it (CI 37196626495:
## endpoint 2.42 m above a host body 0.06 m away, never matched). Height gives
## no walking credit; the horizontal bound is the one that guards travel.
const ENDPOINT_VERTICAL_M := 6.0
var _session: WeakRef
var local: Dictionary = {}
var hosts: Dictionary = {}
## Host: where this host itself saw each owner's body over the last
## INITIAL_POSE_LAG_S, per physics tick: peer -> {realm, samples: [[ms, Vector3]]}.
## A realm change starts a fresh ring; a missing body or a gone/departed stream
## drops it (_sample_poses), so a pose from another realm or session never counts.
var _pose_ring: Dictionary = {}
## Host: a rejoined stream refused for a real conflict, by character, so the
## reason is re-sent to that owner rather than left as silence.
var refused: Dictionary = {}
var pending: Dictionary = {}
## Host: rejoin admissions waiting for that character's in-flight vitals ACK.
var deferred: Dictionary = {}
var committing: Dictionary = {}
var saving := false
var _left := 0.0
var _reported_error := ""
var _reported_ignore := ""
## F18 rejoin: a host readmit that reached this owner before its handshake
## snapshot set the joined world's scope. One, replayed by tick() once the
## snapshot lands (dropped then if the scope still differs); cleared by reset().
var held_readmit: Dictionary = {}

class NavigationFlags extends RefCounted:
	var flags: Dictionary = {}
	var revision := 0
	func has(id: String) -> bool: return flags.get(id) == true

func _init(session: Node = null) -> void:
	if session != null: _session = weakref(session)

func owner() -> Node:
	return _session.get_ref() as Node if _session != null else null

func _game() -> Node:
	return owner().call("_game") as Node if owner() != null else null

## The owner's discovery identity: the landmarks this stream was admitted with
## plus those its own discovery inputs carried, i.e. exactly what the host
## replays. A landmark that reaches the map with no input (a manual find such as
## the Meadowhart herd, a story reveal such as Cloudreach sync_navigation) never
## enters it, so rebase/readmit seeds always match the host's (G1 follow-up).
## Before a stream is armed, the map's admission landmarks.
func _discoveries() -> Dictionary:
	if local.get("discovered") is Dictionary:
		return (local.discovered as Dictionary).duplicate(true)
	return owner().call("_groom_service").call("admission_landmarks")

func _projection() -> Dictionary:
	return RECORD.portable_projection(_game().get("local").call("save_data"))

func arm_owner(before: Dictionary, discoveries: Dictionary) -> Dictionary:
	var cursor := REPLAY.begin(before, discoveries)
	if cursor.is_empty(): return {}
	local = {"id": Crypto.new().generate_random_bytes(16).hex_encode(), "character": before.character_id,
		"base_hash": HASH.fingerprint(before), "sequence": 0, "prefix_hash": cursor.prefix_hash,
		"inputs": [], "acked": 0, "error": "", "last_settlement": "", "rebase": {}, "admission_pending": true,
		"hello_pending": true,
		"discovered": discoveries.duplicate(true)}
	pending.clear()
	var game := _game()
	if game != null:
		game.set("_travel_pos_valid", false)
		game.set("_discovery_elapsed", 0.0)
	return {"id": local.id, "baseline_hash": local.base_hash}

func record_input(input: Dictionary) -> void:
	if local.is_empty() or not pending.is_empty() or not stormwood_owner.is_empty() or not str(local.error).is_empty(): return
	if local.inputs.size() >= MAX_BUFFER:
		local.error = "owner_passive_buffer_full"
		return # Never discard an unacknowledged transition.
	var packet := input.duplicate(true)
	if packet.get("op") == "discovery" and packet.get("new_landmarks") is Array and local.get("discovered") is Dictionary:
		# The host replays only landmarks its set lacks (it refuses a known one).
		var known: Array = (local.discovered as Dictionary).get(str(packet.get("realm", "")), [])
		packet.new_landmarks = (packet.new_landmarks as Array).filter(func(id: Variant) -> bool: return not known.has(id))
	packet.version = 1
	packet.sequence = int(local.sequence) + 1
	local.sequence = packet.sequence
	local.prefix_hash = HASH.fingerprint({"previous": local.prefix_hash, "packet": packet})
	local.inputs.append(packet)
	if packet.get("op") == "discovery" and local.get("discovered") is Dictionary and packet.get("new_landmarks") is Array:
		var known: Array = (local.discovered as Dictionary).get(str(packet.get("realm", "")), []).duplicate()
		for id: Variant in packet.new_landmarks:
			if id is String and not known.has(id): known.append(id)
		local.discovered[str(packet.get("realm", ""))] = known

func record_vitals(row: Dictionary, saved: bool) -> bool:
	if local.is_empty(): return false
	var scope := _scope()
	var session := owner()
	if session == null or not session.has_method("_owner_passive_actor_vitals_scope") \
		or scope.size() != 4 or local.character != scope.get("character_id"): return false
	# Journal identity belongs to the original HOST writer. The care stream
	# belongs to the current authenticated transport; these epochs are distinct.
	var validated: Variant = session.call("_owner_passive_actor_vitals_scope",row)
	if not validated is Dictionary or validated.size() != 5 \
		or validated.get("journal_session_id") != row.get("session_id"): return false
	for field: String in scope:
		if validated.get(field) != scope[field]: return false
	var actor: Script = preload("res://scripts/net/actor_vitals_delivery.gd")
	if actor.call("valid", row, str(scope.get("character_id", "")), str(scope.get("world_namespace", ""))) != true \
		or row.world_id != scope.get("world_id") \
		or not E._equivalent(_game().get("world").reward_deliveries.get(row.delivery_id), row): return false
	var receipt_hash := HASH.fingerprint(row.receipt)
	var op := "actor_vitals_saved" if saved else "actor_vitals_applied"
	var key: String = op + ":" + receipt_hash + ":" + str(row.journal_revision)
	var seen: Dictionary = local.get("vitals_seen", {})
	if seen.has(key): return true
	if not recording_active() or seen.size() >= MAX_BUFFER or local.inputs.size() >= MAX_BUFFER: return false
	record_input({"op": op, "delivery_id": row.delivery_id, "journal_revision": row.journal_revision, "receipt_hash": receipt_hash})
	seen[key] = true
	local.vitals_seen = seen
	return true

## The owner applied a host-journaled payout to its satchel and saved it.
func record_delivery(row: Dictionary) -> bool:
	if not recording_active() or row.get("character_id") != local.character: return false
	record_input({"op": "reward_delivery_applied", "delivery_id": str(row.get("delivery_id", "")),
		"stacks_hash": HASH.fingerprint({"stacks": row.get("stacks")})})
	return true

## An applied reward delivery this owner has not yet replayed to the host:
## the host's admitted record does not hold it yet (owner side only).
func reward_replay_pending() -> bool:
	for input: Variant in local.get("inputs", []):
		if input is Dictionary and input.get("op") == "reward_delivery_applied": return true
	return false

func recording_active() -> bool:
	return not local.is_empty() and pending.is_empty() and stormwood_owner.is_empty() and str(local.error).is_empty()

## A reward delivery waits until the host has first admitted this join's
## stream (and any readmit settled the payouts its held record already holds,
## _settle_folded). A rebase never folds payouts, so it does not hold them
## (re-review M-2); a join whose admission never lands tells the player once.
const HELLO_WAIT_TELL_MS := 20000
func delivery_ready() -> bool:
	if not recording_active(): return false
	if local.get("hello_pending", false) != true: return true
	# The clock starts at the first payout held after the snapshot (the dial
	# and world build are not waiting on admission; review L-1).
	if not local.has("hello_wait_from_ms"): local.hello_wait_from_ms = Time.get_ticks_msec()
	if not local.get("hello_wait_told", false) and Time.get_ticks_msec() - int(local.hello_wait_from_ms) > HELLO_WAIT_TELL_MS:
		local.hello_wait_told = true
		var game := _game()
		if game != null and game.has_method("push_world_message"): game.call("push_world_message", "Rewards wait until the host has taken your character in.")
	return false

func _scope() -> Dictionary:
	var game := _game()
	if game == null or game.get("world") == null or game.get("local") == null or owner() == null: return {}
	return {"character_id": game.get("local").character_id, "world_id": game.get("world").world_id,
		"world_namespace": game.get("world").reward_delivery_namespace,
		"session_epoch": owner().call("_altar_current_epoch")}

## False when nothing was sent (no stream, or the join snapshot not applied yet).
func _send_host(message: Dictionary, stream_id: String = "") -> bool:
	if local.is_empty() or owner() == null or owner().call("snapshot_ready") != true: return false
	var packet := _scope()
	packet.merge(message, true)
	packet.stream_id = local.id if stream_id.is_empty() else stream_id
	owner().call("_owner_passive_send_host", packet)
	return true

func _send_owner(peer: int, stream: Dictionary, message: Dictionary) -> void:
	var packet := {"character_id": stream.character, "world_id": stream.world_id,
		"world_namespace": stream.world_namespace, "session_epoch": stream.epoch, "stream_id": stream.id}
	packet.merge(message, true)
	if message.get("op") in ["inputs_ack", "rebase_ack", "readmit"]:
		packet["tether_tonics"] = owner().get("_character_authority").call("tether_tonic_projection", str(stream.character))
	owner().call("_owner_passive_send_peer", peer, packet)

func admitted(peer: int, summary: Dictionary) -> void:
	var session := owner()
	var declaration: Variant = summary.get("owner_passive_stream")
	if session == null or session.call("is_host") != true or not declaration is Dictionary \
		or not HASH._hex(declaration.get("id"), 32): return
	var character: String = session.call("_authority_character", peer)
	var authority: RefCounted = session.get("_character_authority")
	var before: Dictionary = authority.call("state", character)
	if hosts.get(character, {}).get("departed") == true:
		_recovery_admitted(peer, summary, hosts[character])
		return
	# A stream still bound to an earlier transport for this character is that
	# departed connection's, never the rejoined owner's (peer_departed normally
	# removed it already; a late disconnect must not shadow the new stream).
	if hosts.has(character) and int(hosts[character].get("peer", 0)) != peer:
		_drop_host(character)
	refused.erase(character)
	var declared: Variant = summary.get("portable_authority")
	var discoveries: Dictionary = authority.call("discovered_landmarks", character)
	# Review G1: both cursors seed their input prefix from (baseline, landmarks).
	# A rejoin keeps the host's held landmarks (seed_discovered_landmarks), so an
	# owner that discovered more before leaving must adopt them (readmit below),
	# or every later checkpoint ends owner_passive_exact_projection_conflict.
	var declared_discoveries: Variant = summary.get("discovered_landmarks", {})
	var discoveries_match: bool = declared_discoveries is Dictionary \
		and HASH.fingerprint({"discovered": declared_discoveries}) == HASH.fingerprint({"discovered": discoveries})
	# Payouts a rejoin folded into the held record that the owner has not yet
	# confirmed settling: it marks them settled (and saves) on the readmit
	# before it may process their redelivery, so any such row forces one.
	var folded: Array = authority.call("unconfirmed_folds", character)
	if E._equivalent(before, declared) and HASH.fingerprint(before) == declaration.get("baseline_hash") and discoveries_match and folded.is_empty():
		_add_host(peer, character, str(declaration.id), before, discoveries)
		return
	# Rejoin: the declaration differs from the host's held record. Passive
	# care/travel drift the host never acknowledged readmits those fields only
	# (owner_passive_replay.gd `_core`). Under "guest wins unless behind" (owner
	# ruling 2026-10-05) a declaration that is not behind was already adopted
	# by the hello (character_authority.rejoin_admission), so any other
	# difference here is a declaration that IS behind: the owner adopts the
	# whole held record (`adopt`). Anything else is refused with a reason.
	var core_matches: bool = declared is Dictionary and HASH.fingerprint(declared) == declaration.get("baseline_hash") \
		and E._equivalent(REPLAY._core(before), REPLAY._core(declared))
	if not core_matches and not (authority.call("pending_creature_vitals", character) as Dictionary).is_empty():
		# The owner left with a host vitals row it saved but never ACKed: its
		# settled escrow is ahead of this authority only by that ACK, which the
		# ledger re-delivers now. Admit once it lands (retry_deferred).
		deferred[character] = {"peer": peer, "summary": summary.duplicate(true),
			"world_id": _game().get("world").world_id, "world_namespace": _game().get("world").reward_delivery_namespace,
			"epoch": session.call("_altar_current_epoch"), "request_id": Crypto.new().generate_random_bytes(16).hex_encode()}
		print("[owner-passive] admission of %s waits for its in-flight vitals ACK" % character.left(18))
		return
	deferred.erase(character)
	if not declared is Dictionary or HASH.fingerprint(declared) != declaration.get("baseline_hash"):
		var reason := "owner_passive_admission_conflict: declaration does not match its stream baseline"
		refused[character] = {"id": str(declaration.id), "reason": reason, "peer": peer}
		push_warning("[owner-passive] refused rejoined stream for %s: %s" % [character.left(18), reason])
		_send_refusal(peer, character)
		return
	var adopt := not E._equivalent(REPLAY._core(before), REPLAY._core(declared))
	var rejoin_code := str((session.get("last_rejoin_admission") as Dictionary).get(character, "")) if "last_rejoin_admission" in session else ""
	if adopt and rejoin_code != "held_wins":
		# Never adopt over a declaration that was not found behind. An open host
		# transaction at the hello (host_duties_unsettled) kept the held record:
		# refused as before the ruling; nothing is lost (the owner keeps its
		# file) and its next rejoin, after the transaction settled, carries a
		# fresh declaration that wins unless behind. (A parked re-decide judged
		# the stale hello declaration and could wait forever: review of 40df9738.)
		var reason := "owner_passive_admission_conflict: %s %s" % [rejoin_code, ", ".join(_differing_paths("", before, declared, 0, []).slice(0, 8))]
		refused[character] = {"id": str(declaration.id), "reason": reason, "peer": peer}
		push_warning("[owner-passive] refused rejoined stream for %s: %s" % [character.left(18), reason])
		_send_refusal(peer, character)
		return
	if not _add_host(peer, character, str(declaration.id), before, discoveries): return
	hosts[character].readmit = {"op": "readmit", "baseline": before.duplicate(true),
		"baseline_hash": HASH.fingerprint(before), "discoveries_hash": HASH.fingerprint({"discovered": discoveries}),
		"discovered": discoveries.duplicate(true), "adopt": adopt, "folded": folded}
	if adopt:
		print("[owner-passive] %s is behind this world's record; it adopts the held record: %s" % [character.left(18), ", ".join(_differing_paths("", before, declared, 0, []).slice(0, 8))])
	else:
		print("[owner-passive] re-admitting %s on the host's recovered authority (passive drift only)" % character.left(18))
	_send_owner(peer, hosts[character], hosts[character].readmit)


## Host, on a transport leaving: its streams end with it. A portal-departed
## stream stays for `_recovery_admitted`; anything else would shadow the
## owner's next stream forever (re-proof: rejoin left admission pending).
func peer_departed(peer: int) -> void:
	_pose_ring.erase(peer)
	for character: String in deferred.keys():
		if int(deferred[character].get("peer", 0)) == peer: deferred.erase(character)
	for character: String in hosts.keys():
		var stream: Dictionary = hosts[character]
		if int(stream.get("peer", 0)) == peer and stream.get("departed") != true:
			_drop_host(character)
	for character: String in refused.keys():
		if int(refused[character].get("peer", 0)) == peer: refused.erase(character)


## Host: only a fresh saved owner declaration can replace the parked hello.
func retry_deferred(character: String) -> void:
	var parked: Dictionary = deferred.get(character, {})
	if parked.is_empty(): return
	var session := owner()
	if session == null or session.call("is_host") != true \
		or session.call("_authority_character", int(parked.peer)) != character \
		or parked.epoch != session.call("_altar_current_epoch") \
		or parked.world_id != _game().get("world").world_id \
		or parked.world_namespace != _game().get("world").reward_delivery_namespace \
		or not (session.get("_character_authority").call("pending_creature_vitals", character) as Dictionary).is_empty(): return
	_send_owner(int(parked.peer), {"character": character, "world_id": parked.world_id,
		"world_namespace": parked.world_namespace, "epoch": parked.epoch,
		"id": parked.summary.owner_passive_stream.id}, {"op": "redeclaration", "request_id": parked.request_id})


func _drop_host(character: String) -> void:
	var stream: Dictionary = hosts.get(character, {})
	var authority: RefCounted = owner().get("_character_authority") if owner() != null else null
	if authority != null and (stream.get("checkpoint", {}) as Dictionary).has("prepared"):
		authority.call("cancel_owner_passive_checkpoint", character, stream.checkpoint.prepared.hash)
	hosts.erase(character)


func _send_refusal(peer: int, character: String) -> void:
	var row: Dictionary = refused.get(character, {})
	if row.is_empty(): return
	var world: RefCounted = _game().get("world")
	_send_owner(peer, {"character": character, "world_id": world.world_id,
		"world_namespace": world.reward_delivery_namespace, "epoch": owner().call("_altar_current_epoch"),
		"id": row.id}, {"op": "admission_refused", "reason": row.reason})


static func _differing_paths(path: String, a: Variant, b: Variant, depth: int, out: Array) -> Array:
	if out.size() >= 16 or E._equivalent(a, b): return out
	if depth < 6 and a is Dictionary and b is Dictionary:
		for key: Variant in (a as Dictionary).keys() + (b as Dictionary).keys():
			if not out.has(path + "/" + str(key)):
				_differing_paths(path + "/" + str(key), (a as Dictionary).get(key), (b as Dictionary).get(key), depth + 1, out)
		return out
	if depth < 6 and a is Array and b is Array and (a as Array).size() == (b as Array).size():
		for i in (a as Array).size(): _differing_paths(path + "[%d]" % i, a[i], b[i], depth + 1, out)
		return out
	out.append(path if not path.is_empty() else "/")
	return out

func _recovery_admitted(peer: int, summary: Dictionary, original_stream: Dictionary) -> void:
	var checkpoint: Dictionary = original_stream.checkpoint
	var prepared: Dictionary = checkpoint.get("prepared", {})
	var baseline: Dictionary = summary.get("portable_authority", {})
	var declaration: Dictionary = summary.owner_passive_stream
	if not PREP.valid_action_host(prepared, original_stream.cursor) or prepared.source_kind != "portal_arrival" \
		or prepared.session_epoch != owner().call("_altar_current_epoch") \
		or prepared.world_id != _game().get("world").world_id \
		or prepared.world_namespace != _game().get("world").reward_delivery_namespace \
		or HASH.fingerprint(baseline) != declaration.get("baseline_hash"): return
	var discoveries: Dictionary = summary.get("discovered_landmarks", {})
	if not original_stream.has("recovery_candidates"):
		original_stream.recovery_candidates = [
			_recovery_candidate(prepared, REPLAY.begin(prepared.before, owner().get("_character_authority").call("discovered_landmarks", original_stream.character))),
			_recovery_candidate(prepared, REPLAY.begin(prepared.after, prepared.discoveries))]
	var candidate: Dictionary = {}
	for known: Dictionary in original_stream.recovery_candidates:
		if not known.is_empty() and PREP.exact(baseline, known.prepared.after) and PREP.exact(discoveries, known.prepared.discoveries):
			candidate = known
			break
	if candidate.is_empty(): return # Only exact latest before/after host replay candidates can reconnect.
	var cursor := REPLAY.begin(baseline, discoveries)
	if cursor.is_empty(): return
	original_stream.recovery = {"peer": peer, "character": original_stream.character, "id": declaration.id,
		"world_id": original_stream.world_id, "world_namespace": original_stream.world_namespace,
		"epoch": original_stream.epoch, "started_ms": Time.get_ticks_msec(), "cursor": cursor,
		"revision": original_stream.revision, "seen": {}, "error": "",
		"checkpoint": {"id": Crypto.new().generate_random_bytes(16).hex_encode(), "recovery": true,
			"original": prepared.duplicate(true), "baseline": candidate.prepared.duplicate(true),
			"baseline_cursor": candidate.cursor.duplicate(true)}}
	_recovery_freeze(peer, original_stream.recovery)

func _recovery_freeze(peer: int, stream: Dictionary) -> void:
	_send_owner(peer, stream, {"op": "portal_recover", "id": stream.checkpoint.id,
		"original": stream.checkpoint.original, "baseline": stream.checkpoint.baseline})

func _recovery_candidate(original: Dictionary, cursor: Dictionary) -> Dictionary:
	if cursor.is_empty(): return {}
	var prepared := PREP.make_action(original.request, original.host_context, cursor.base,
		int(original.revision), str(original.session_epoch), str(original.world_id), cursor,
		Crypto.new().generate_random_bytes(16).hex_encode(), "portal_arrival")
	return {} if prepared.is_empty() else {"prepared": prepared, "cursor": cursor.duplicate(true)}

func _recovery_aggregate(stream: Dictionary) -> Dictionary:
	# Every prior state came from this host's exact replay. Keep only its last
	# bounded candidate and the current stream, rather than a recursive chain.
	var cursor: Dictionary = stream.cursor.duplicate(true)
	cursor.base = stream.checkpoint.baseline.before.duplicate(true)
	return cursor

func _add_host(peer: int, character: String, stream_id: String, before: Dictionary, discoveries: Dictionary) -> bool:
	if not hosts.has(character) and hosts.size() >= MAX_PEERS: return false
	if hosts.has(character) and not hosts[character].get("checkpoint", {}).is_empty(): return false
	var cursor := REPLAY.begin(before, discoveries)
	if cursor.is_empty(): return false
	var world: RefCounted = _game().get("world")
	hosts[character] = {"peer": peer, "character": character, "id": stream_id,
		"world_id": world.world_id, "world_namespace": world.reward_delivery_namespace,
		"epoch": owner().call("_altar_current_epoch"), "started_ms": Time.get_ticks_msec(),
		"cursor": cursor, "revision": owner().get("_character_authority").call("revision", character),
		"seen": {}, "checkpoint": {}, "error": ""}
	owner().get("_character_authority").call("bind_tether_tonic_stream", character, stream_id,
		str(hosts[character].epoch), int(cursor.sequence))
	return true

func _host_scope(peer: int, packet: Dictionary) -> bool:
	var session := owner()
	var game := _game()
	return session != null and game != null and session.call("is_host") == true \
		and packet.get("character_id") == session.call("_authority_character", peer) \
		and packet.get("world_id") == game.get("world").world_id \
		and packet.get("world_namespace") == game.get("world").reward_delivery_namespace \
		and packet.get("session_epoch") == session.call("_altar_current_epoch")

func receive_host(peer: int, packet: Dictionary) -> void:
	if not _host_scope(peer, packet): return
	var character: String = packet.character_id
	if packet.get("op") == "redeclare":
		var stream: Dictionary = hosts.get(character, {})
		if refused.get(character, {}).get("peer") == peer and PREP.exact(refused.get(character, {}).get("redeclaration"), packet):
			_send_refusal(peer, character)
			return
		if stream.get("peer") == peer and PREP.exact(stream.get("redeclaration"), packet):
			_send_owner(peer, stream, stream.readmit if stream.has("readmit") else {"op": "inputs_ack", "sequence": stream.cursor.sequence})
			return # A lost reply never reruns the authority mutation.
		var parked: Dictionary = deferred.get(character, {})
		var summary: Variant = packet.get("summary")
		if parked.is_empty() or parked.get("peer") != peer or parked.get("epoch") != packet.session_epoch \
			or parked.get("world_id") != packet.world_id or parked.get("world_namespace") != packet.world_namespace \
			or packet.get("stream_id") != parked.summary.owner_passive_stream.id \
			or packet.get("request_id") != parked.get("request_id") or not summary is Dictionary \
			or summary.get("character_id") != character or not summary.get("owner_passive_stream") is Dictionary: return
		var declaration: Dictionary = summary.owner_passive_stream
		if not HASH._hex(declaration.get("id"), 32) or declaration.get("id") == packet.stream_id \
			or not summary.get("portable_authority") is Dictionary \
			or declaration.get("baseline_hash") != HASH.fingerprint(summary.portable_authority): return
		var authority: RefCounted = owner().get("_character_authority")
		if not (authority.call("pending_creature_vitals", character) as Dictionary).is_empty(): return
		var undo: Dictionary = authority.call("snapshot_record", character)
		var lists: Dictionary = owner().call("rejoin_payout_lists", summary)
		var result: Dictionary = owner().call("rejoin_admission_for", character, summary.portable_authority, summary, lists)
		if result.get("ok") == true:
			if authority.call("seed_personal_flags", character, summary.get("personal_flags", {"flags": []})) != true \
				or authority.call("seed_discovered_landmarks", character, summary.get("discovered_landmarks", {})) != true:
				result = {"ok": false, "code": "invalid_character"}
		if result.get("ok") != true:
			authority.call("restore_record", character, undo)
			refused[character] = {"id": declaration.id, "peer": peer, "redeclaration": packet.duplicate(true),
				"reason": "owner_passive_admission_conflict: " + str(result.get("code", "invalid_character"))}
			deferred.erase(character)
			_send_refusal(peer, character)
			return
		owner().call("credit_rejoin_gathers", character, result.get("applied", []))
		owner().call("_groom_service").call("admitted", character, authority.call("discovered_landmarks", character))
		admitted(peer, summary)
		if hosts.get(character, {}).get("id") == declaration.id:
			deferred.erase(character)
			hosts[character].redeclaration = packet.duplicate(true)
			if not hosts[character].has("readmit"): _send_owner(peer, hosts[character], {"op": "inputs_ack", "sequence": 0})
		return
	if packet.get("op") == "rebase":
		_rebase_host(peer, packet)
		return
	if not hosts.has(character):
		if refused.get(character, {}).get("id") == packet.get("stream_id"): _send_refusal(peer, character)
		# A parked rejoin admission re-checks on the owner's own traffic once its
		# in-flight vitals are settled (backstop for a lost ACK-side retry).
		if deferred.get(character, {}).get("peer") == peer:
			var authority: RefCounted = owner().get("_character_authority")
			if (authority.call("pending_creature_vitals", character) as Dictionary).is_empty(): retry_deferred(character)
		return
	var stream: Dictionary = hosts[character]
	if stream.get("departed") == true:
		stream = stream.get("recovery", {})
		if stream.is_empty(): return
	if stream.has("readmit") and stream.peer == peer and stream.id == packet.get("stream_id"):
		if packet.get("op") == "readmitted" and packet.get("baseline_hash") == stream.readmit.baseline_hash:
			# The owner saved its settlement of the folded rows: they leave the record.
			owner().get("_character_authority").call("confirm_folds", str(stream.character), stream.readmit.get("folded", []))
			stream.erase("readmit")
			_send_owner(peer, stream, {"op": "inputs_ack", "sequence": stream.cursor.sequence})
		else:
			_send_owner(peer, stream, stream.readmit) # inputs on the old base wait for the owner
		return
	if stream.peer != peer or stream.id != packet.get("stream_id") or stream.epoch != packet.session_epoch: return
	if packet.get("op") == "saved" and stream.get("recovered", {}).get("id") == packet.get("id") \
		and stream.recovered.hash == packet.get("hash") and packet.get("saved") == true:
		_send_owner(peer, stream, {"op": "portal_recovered", "id": packet.id, "hash": packet.hash})
		return
	match packet.get("op"):
		"resume":
			if stream.checkpoint.get("recovery") == true: _recovery_freeze(peer, stream)
			else: _send_owner(peer, stream, {"op": "inputs_ack", "sequence": stream.cursor.sequence})
		"inputs": _inputs_host(peer, stream, packet)
		"frozen": _frozen_host(peer, stream, packet)
		"saved": _saved_host(peer, stream, packet)

func _context(peer: int, stream: Dictionary) -> Dictionary:
	var session := owner()
	var realm := _peer_realm(peer)
	var map: RefCounted = _game().get("local").call("map_for", realm)
	var definitions := GROOM.landmark_definitions(map, realm, session.call("_foundation_flags", peer),
		_game().get("world").flags.call("all_set"))
	var context := {"realm": realm, "landmarks": definitions, "max_speed": MAX_SPEED,
		"max_elapsed": ADMISSION_ALLOWANCE_S + float(Time.get_ticks_msec() - int(stream.started_ms)) / 1000.0}
	var body: Variant = _host_body_position(peer, realm)
	if body is Vector3:
		context.initial_position = body
		context.initial_max_distance = MAX_SPEED * INITIAL_POSE_LAG_S
	return context

## The host's own view of this peer's body in `realm`, or null without one.
func _host_body_position(peer: int, realm: String) -> Variant:
	var session := owner()
	var lifecycle := session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
	var actor: CharacterBody3D = lifecycle.call("remote_body", peer) if lifecycle != null else null
	var shell: Node3D = session.call("_portal_world_node", realm)
	if actor != null and shell != null and shell.is_ancestor_of(actor): return actor.global_position
	return null

func _peer_realm(peer: int) -> String:
	for row: Dictionary in owner().call("registry").call("rows"):
		if row.get("peer_id") == peer: return str(row.get("realm", ""))
	return ""

## Host, every physics tick: record each streaming owner's body.
func _sample_poses() -> void:
	var session := owner()
	if session == null or not session.is_inside_tree() or session.call("is_host") != true:
		_pose_ring.clear()
		return
	var now := Time.get_ticks_msec()
	var live: Dictionary = {}
	for character: String in hosts:
		var stream: Dictionary = hosts[character]
		if stream.get("departed") == true or not stream.get("peer") is int: continue
		var peer: int = stream.peer
		live[peer] = true
		var realm := _peer_realm(peer)
		var body: Variant = _host_body_position(peer, realm)
		if body is Vector3: _record_pose(peer, realm, body, now)
		else: _pose_ring.erase(peer)
	for peer: Variant in _pose_ring.keys():
		if not live.has(peer): _pose_ring.erase(peer)

func _record_pose(peer: int, realm: String, position: Vector3, now_ms: int) -> void:
	var ring: Dictionary = _pose_ring.get(peer, {})
	if ring.get("realm") != realm: ring = {"realm": realm, "samples": []}
	var samples: Array = ring.samples
	samples.append([now_ms, position])
	var oldest := now_ms - int(INITIAL_POSE_LAG_S * 1000.0)
	while not samples.is_empty() and (int(samples[0][0]) < oldest or samples.size() > MAX_POSE_SAMPLES):
		samples.pop_front()
	_pose_ring[peer] = ring

## The first discovery of a stream may lag the guest by INITIAL_POSE_LAG_S
## (MAX_SPEED x lag of walking). Across a teleport (fly landing, Home Key) the
## current body alone breaks that allowance, so a pose the host's own body held
## within the same window, in the same realm, counts too: never any pose the
## host did not observe, never a wider distance.
func _pose_observed_near(peer: int, context: Dictionary, at: Vector3) -> bool:
	var limit := float(context.initial_max_distance)
	if (context.initial_position as Vector3).distance_to(at) <= limit: return true
	var ring: Dictionary = _pose_ring.get(peer, {})
	if ring.get("realm") != context.get("realm"): return false
	var oldest := Time.get_ticks_msec() - int(INITIAL_POSE_LAG_S * 1000.0)
	for sample: Array in ring.get("samples", []):
		if int(sample[0]) >= oldest and (sample[1] as Vector3).distance_to(at) <= limit: return true
	return false

## A host-accepted physical placement explains one same-stream false travel
## baseline. Peer inputs cannot create this capability or choose its anchor.
## A fly landing names the guest's own claimed pose, matched exactly. An
## accepted portal/Home Key arrival (arrival_endpoint) names the host's view
## of the guest's body; the guest's own endpoint is bound only by the live
## host body (as every reset is), not by that stale replica.
func travel_reset_confirmed(peer: int, realm: String, anchor: Vector3, arrival_endpoint: bool = false) -> void:
	if owner() == null or owner().call("is_host") != true or not anchor.is_finite(): return
	var character: String = owner().call("_authority_character", peer)
	var stream: Dictionary = hosts.get(character, {})
	if stream.get("departed") == true: stream = stream.get("recovery", {})
	if stream.is_empty() or stream.peer != peer or stream.epoch != owner().call("_altar_current_epoch") \
		or stream.world_id != _game().get("world").world_id \
		or stream.world_namespace != _game().get("world").reward_delivery_namespace: return
	var context := _context(peer, stream)
	if context.realm != realm or not context.get("initial_position") is Vector3: return
	stream.travel_reset = {"peer": peer, "stream_id": stream.id, "epoch": stream.epoch, "realm": realm,
		"anchor": [anchor.x, anchor.y, anchor.z], "sequence": stream.cursor.sequence, "arrival": arrival_endpoint}

func _reset_matches(peer: int, stream: Dictionary, input: Dictionary, context: Dictionary) -> bool:
	var proof: Dictionary = stream.get("travel_reset", {})
	if proof.is_empty() or input.get("op") != "discovery" or input.get("travel_valid") != false \
		or stream.cursor.travel_valid != true or proof.peer != peer or proof.stream_id != stream.id \
		or proof.epoch != stream.epoch or proof.realm != context.realm or input.get("realm") != proof.realm \
		or int(input.sequence) <= int(proof.sequence) or not E._equivalent(input.get("from"), stream.cursor.position) \
		or not REPLAY._position(input.get("to")) or not REPLAY._position(proof.anchor) \
		or not context.get("initial_position") is Vector3: return false
	var at := Vector3(float(input.to[0]), float(input.to[1]), float(input.to[2]))
	# An arrival proof's anchor is the host's replica at mint time; the guest
	# reports where it stands at its next poll. The live-body check below is
	# the bound for it. A fly proof names the guest's own claim: exact.
	if proof.get("arrival") != true and not E._equivalent(input.get("to"), proof.anchor): return false
	# Reuse the existing live-body discontinuity endpoint tolerance.
	return _endpoint_matches(context.initial_position, at)

static func _endpoint_matches(host_body: Vector3, endpoint: Vector3) -> bool:
	var flat := Vector2(host_body.x - endpoint.x, host_body.z - endpoint.z)
	return flat.length() <= ENDPOINT_HORIZONTAL_M and absf(host_body.y - endpoint.y) <= ENDPOINT_VERTICAL_M

func _inputs_host(peer: int, stream: Dictionary, packet: Dictionary) -> void:
	if not str(stream.error).is_empty() or not packet.get("inputs") is Array \
		or packet.inputs.is_empty() or packet.inputs.size() > MAX_BATCH: return
	# F01#6b: condition ticks of this batch apply to ONE private copy of the
	# cursor (REPLAY.apply_condition_owned). It becomes the stream's cursor only
	# after its record is validated (_settle_working): before any other input
	# and on every exit, so the cursor never holds an unvalidated state.
	var batch := {"working": {}, "tonic_ticks": []}
	var completed := _inputs_host_batch(peer, stream, packet, batch)
	if not _settle_working(stream, batch) or not completed or not str(stream.error).is_empty(): return
	_send_owner(peer, stream, {"op": "inputs_ack", "sequence": stream.cursor.sequence})
	if stream.checkpoint.get("recovery") == true and not stream.checkpoint.has("frozen"):
		_recovery_freeze(peer, stream)
	if not stream.checkpoint.is_empty() and stream.checkpoint.has("frozen"):
		_prepare_host(peer, stream)


func _settle_working(stream: Dictionary, batch: Dictionary) -> bool:
	if (batch.working as Dictionary).is_empty(): return true
	var working: Dictionary = batch.working
	batch.working = {}
	if not REPLAY._record_valid(working.state):
		stream.error = "owner_passive_invalid_result"
		return false
	stream.cursor = working
	# Only the validated new prefix ages the same admitted tonic companion.
	for input: Dictionary in batch.get("tonic_ticks", []):
		if owner().has_method("_tick_host_tether_tonics"):
			owner().call("_tick_host_tether_tonics", str(stream.character), float(input.delta),
				input.uids, str(stream.id), str(stream.epoch), int(input.sequence))
	batch["tonic_ticks"] = []
	return true


func _inputs_host_batch(peer: int, stream: Dictionary, packet: Dictionary, batch: Dictionary) -> bool:
	var context := _context(peer, stream)
	for input: Variant in packet.inputs:
		if input is Dictionary and input.get("op") != "condition" and not _settle_working(stream, batch): return false
		if not input is Dictionary or not input.get("sequence") is int:
			stream.error = "owner_passive_invalid_input"; return false
		var sequence: int = input.sequence
		var digest := HASH.fingerprint(input)
		var at_sequence: int = int(batch.working.sequence) if not (batch.working as Dictionary).is_empty() else int(stream.cursor.sequence)
		if sequence <= at_sequence:
			if stream.seen.get(sequence) != digest: stream.error = "owner_passive_conflicting_duplicate"
			if not str(stream.error).is_empty(): return false
			continue
		if stream.seen.size() >= MAX_BUFFER:
			stream.error = "owner_passive_host_buffer_full"; return false
		if input.get("op") == "discovery" and (stream.cursor.travel_valid != true or stream.cursor.realm != context.realm):
			var at: Variant = input.get("to")
			if not context.get("initial_position") is Vector3:
				_note_host(stream, "input %d waits: no host body for this owner in %s" % [sequence, str(context.realm)])
				return false # Realm body has not arrived; retry this exact prefix.
			if not REPLAY._position(at) \
				or not _pose_observed_near(peer, context, Vector3(float(at[0]), float(at[1]), float(at[2]))):
				stream.first_input_refusal = {"input": input.duplicate(true), "context": context.duplicate(true),
					"cursor_sequence": stream.cursor.sequence, "sampled_ms": Time.get_ticks_msec()}
				stream.error = "owner_passive_initial_pose_unconfirmed"; return false
		var input_context := context.duplicate()
		var reset: bool = _reset_matches(peer, stream, input, context)
		if reset:
			input_context.travel_reset_authorized = true
			input_context.travel_reset_position = input.to.duplicate()
		if input.get("op") == "discovery" and REPLAY._position(input.get("from")) and REPLAY._position(input.get("to")):
			var from := Vector3(float(input.from[0]), float(input.from[1]), float(input.from[2]))
			var to := Vector3(float(input.to[0]), float(input.to[1]), float(input.to[2]))
			if input.get("travel_valid") == true and from.distance_to(to) > 30.0:
				# A real host-observed discontinuity can establish a new endpoint,
				# never walking credit. Wait for replication instead of inventing it.
				if not context.get("initial_position") is Vector3 or not _endpoint_matches(context.initial_position, to):
					_note_host(stream, "input %d waits: discontinuity to %s, host body at %s" % [sequence, str(to),
						str(context.get("initial_position", "none"))])
					return false
				input_context.discontinuity_authorized = true
		var applied: Dictionary
		if input.get("op") in ["actor_vitals_applied", "actor_vitals_saved"]:
			if not owner().has_method("_owner_passive_actor_vitals_context"): return false
			var proof: Dictionary = owner().call("_owner_passive_actor_vitals_context", peer, input)
			if proof.is_empty():
				_note_host(stream, "input %d waits: %s has no host vitals proof yet" % [sequence, str(input.op)])
				return false # Exact saved op waits the existing authenticated world ACK.
			if input.op == "actor_vitals_applied" and proof.get("revision_before") != stream.revision:
				stream.error = "owner_passive_vitals_revision_conflict"; return false
			if input.op == "actor_vitals_saved" and int(proof.row.character_revision) > int(stream.revision):
				stream.error = "owner_passive_vitals_saved_before_applied"; return false
			applied = REPLAY.apply_vitals(stream.cursor, input, proof)
		elif input.get("op") == "reward_delivery_applied":
			var row: Variant = _game().get("world").reward_deliveries.get(input.get("delivery_id"))
			applied = REPLAY.apply_delivery(stream.cursor, input, row)
			if applied.get("ok") == true and owner().get("_character_authority").call("apply_owner_reward_delivery",
				stream.character, stream.cursor.base, applied.cursor.base, str(input.get("delivery_id", ""))) != true:
				stream.error = "owner_passive_delivery_authority_changed"; return false
			if applied.get("ok") == true and row is Dictionary:
				# Ruling (b): a batched gather is now credited; its row may be
				# pruned once the guest's ACK has also landed.
				var gather_writer: Node = owner().get_node_or_null(^"LedgerRpc")
				if gather_writer != null: gather_writer.call("mark_gather_replayed", stream.character, row)
		elif input.get("op") == "condition":
			if (batch.working as Dictionary).is_empty(): batch.working = stream.cursor.duplicate(true)
			var reason := REPLAY.apply_condition_owned(batch.working, input, input_context)
			applied = {"ok": true, "code": "ok"} if reason.is_empty() else {"ok": false, "code": reason}
		else:
			applied = REPLAY.apply(stream.cursor, input, input_context)
		if applied.get("ok") != true:
			stream.first_input_refusal = {"input": input.duplicate(true), "context": input_context.duplicate(true),
				"cursor_sequence": stream.cursor.sequence, "sampled_ms": Time.get_ticks_msec()}
			stream.error = str(applied.get("code", "owner_passive_replay_refused")); return false
		if input.get("op") != "condition": stream.cursor = applied.cursor
		else: (batch.tonic_ticks as Array).append(input.duplicate(true))
		if input.get("op") == "actor_vitals_applied": stream.revision = applied.revision
		stream.seen[sequence] = digest
		if reset: stream.erase("travel_reset") # Only successful exact replay consumes it.
	return true

func gate(peer: int, action: String, intent: Dictionary, event: Dictionary) -> Dictionary:
	var session := owner()
	if peer == session.call("local_peer_id"): return {"ok": true}
	var character: String = session.call("_authority_character", peer)
	var binding := {"character": character, "action": action, "intent": intent, "event": event}
	if E._equivalent(committing, binding): return {"ok": true}
	if action not in RETAINED_ACTIONS or not hosts.has(character): return _deny("owner_passive_recording_unavailable")
	var stream: Dictionary = hosts[character]
	if not str(stream.error).is_empty(): return _deny(str(stream.error))
	var world: RefCounted = _game().get("world")
	var retained: Variant = world.reward_deliveries.get(event.get("retained_event"))
	if not EVENT.valid(retained, world.reward_delivery_namespace, world.world_id): return _deny("owner_passive_retained_event_required")
	var matching: Array[Dictionary] = []
	for duty: Dictionary in retained.duties:
		if duty.character_id != character or duty.action != action or not E._equivalent(duty.intent, intent): continue
		var expected: Dictionary = duty.context.duplicate(true)
		expected.character_id = character
		expected.expected_revision = event.get("expected_revision")
		expected.in_range = true
		expected.retained_event = retained.delivery_id
		if action != "research_event":
			expected.in_combat = false
			expected.foundation_runtime_authorized = true
		if action == "boss_relic":
			# Exactly the two host fields session._retry_foundation_events adds
			# to a retained boss duty before it stages (F19 world-scoped drops).
			expected.boss_settlement_world_flags = world.flags.call("all_set").duplicate()
			expected.world_namespace = world.reward_delivery_namespace
		if E._equivalent(expected, event): matching.append(duty)
	if matching.size() != 1: return _deny("owner_passive_original_duty_required")
	return _checkpoint(peer, stream, binding, retained, matching[0])

func capture_gate(peer: int, envelope: Dictionary, context: Dictionary) -> Dictionary:
	var session := owner()
	if peer == session.call("local_peer_id"): return {"ok": true}
	var character: String = session.call("_authority_character", peer)
	# Only the synchronous post-BOOL/CAS call below can reuse this exact request.
	if committing.get("character") == character and committing.get("action") == "wild_capture" \
		and PREP.exact(committing.get("envelope"), envelope):
		var expected: Dictionary = committing.event.duplicate(true)
		expected.expected_revision = envelope.revision
		return {"ok": true} if PREP.exact(expected, context) else _terminal("owner_passive_source_changed")
	if envelope.get("op") != "wild_capture" or not envelope.get("intent") is Dictionary \
		or not hosts.has(character): return _deny("owner_passive_recording_unavailable")
	if session.has_method("_guest_wild_share_outstanding") \
		and session.call("_guest_wild_share_outstanding", character, _game().get("world")) == true:
		return _deny("owner_passive_wild_share_settling")
	var stream: Dictionary = hosts[character]
	if not str(stream.error).is_empty(): return _deny(str(stream.error))
	var world: RefCounted = _game().get("world")
	if envelope.get("session_epoch") != session.call("_altar_current_epoch") \
		or envelope.get("world_namespace") != world.reward_delivery_namespace: return _deny("owner_passive_capture_scope_changed")
	var retained: Variant = world.reward_deliveries.get(context.get("retained_event"))
	if not EVENT.valid(retained, world.reward_delivery_namespace, world.world_id): return _deny("owner_passive_retained_event_required")
	var matching: Array[Dictionary] = []
	for duty: Dictionary in retained.duties:
		if duty.character_id != character or duty.action != "capture_offer": continue
		var expected: Dictionary = duty.context.duplicate(true)
		expected.character_id = character
		expected.expected_revision = session.get("_character_authority").call("revision", character)
		expected.in_range = true
		expected.in_combat = false
		expected.foundation_runtime_authorized = true
		expected.retained_event = retained.delivery_id
		if PREP.exact(expected, context) and envelope.get("character_id") == character \
			and envelope.get("station_key") == duty.context.source_key \
			and envelope.get("revision") == expected.expected_revision: matching.append(duty)
	if matching.size() != 1: return _deny("owner_passive_original_duty_required")
	var current: Dictionary = session.get("_character_authority").call("state", character)
	var choice: Dictionary = preload("res://scripts/net/foundation_capture_rules.gd").stage(current, envelope.intent, context)
	if choice.get("ok") != true: return _deny(str(choice.get("code", "capture_choice_refused")))
	var binding := {"character": character, "action": "wild_capture", "intent": envelope.intent.duplicate(true),
		"event": context.duplicate(true), "envelope": envelope.duplicate(true)}
	return _checkpoint(peer, stream, binding, retained, matching[0])

func _checkpoint(peer: int, stream: Dictionary, binding: Dictionary, retained: Dictionary, duty: Dictionary) -> Dictionary:
	# A rejoined owner adopts the host's baseline first; a freeze sent before
	# that would park on the owner and make it ignore the readmit (deadlock).
	if stream.has("readmit"): return _deny("owner_passive_readmit_pending")
	if stream.checkpoint.is_empty():
		var authority: RefCounted = owner().get("_character_authority")
		if authority.call("creature_training_is_pending", str(stream.character)) == true: return _deny("owner_passive_prior_transaction_pending")
		stream.checkpoint = {"id": Crypto.new().generate_random_bytes(16).hex_encode(), "binding": binding.duplicate(true),
			"retained": retained.duplicate(true), "duty": duty.duplicate(true)}
	elif not E._equivalent(stream.checkpoint.binding, binding): return _deny("owner_passive_original_pending")
	_send_owner(peer, stream, {"op": "freeze", "id": stream.checkpoint.id,
		"retained_event": retained.delivery_id, "duty_hash": HASH.fingerprint(duty)})
	return _deny("owner_passive_checkpoint_pending")

## Each caller has already authenticated its original request and validated
## its actual station/completed unit with the existing pure action producer.
## No invented retained event represents these explicit player requests.
func action_gate(peer: int, source_kind: String, request: Dictionary, context: Dictionary) -> Dictionary:
	var session := owner()
	if peer == session.call("local_peer_id"): return {"ok": true}
	var character: String = session.call("_authority_character", peer)
	if source_kind not in REQUEST_KINDS: return _deny("owner_passive_request_kind")
	if source_kind == "foundation_request" and request.get("op") not in REQUEST_ACTIONS: return _deny("owner_passive_request_kind")
	if committing.get("character") == character and committing.get("source_kind") == source_kind \
		and PREP.exact(committing.get("envelope"), request):
		return {"ok": true} if PREP.exact(committing.event, context) else _terminal("owner_passive_source_changed")
	if not hosts.has(character): return _deny("owner_passive_recording_unavailable")
	var stream: Dictionary = hosts[character]
	if not str(stream.error).is_empty(): return _deny(str(stream.error))
	var world: RefCounted = _game().get("world")
	if request.get("character_id") != character or request.get("session_epoch") != session.call("_altar_current_epoch") \
		or request.get("world_namespace") != world.reward_delivery_namespace: return _deny("owner_passive_request_scope_changed")
	if stream.has("readmit"): return _deny("owner_passive_readmit_pending")
	# F27: a wild win's guest share stages on the authority record first.
	if session.has_method("_guest_wild_share_outstanding") \
		and session.call("_guest_wild_share_outstanding", character, _game().get("world")) == true:
		return _deny("owner_passive_wild_share_settling")
	var binding := {"character": character, "action": request.get("op"), "source_kind": source_kind,
		"envelope": request.duplicate(true), "event": context.duplicate(true)}
	if stream.checkpoint.is_empty():
		var authority: RefCounted = session.get("_character_authority")
		if authority.call("creature_training_is_pending", character) == true: return _deny("owner_passive_prior_transaction_pending")
		# Validate the exact source shape and locally replayed cursor before
		# asking the owner to freeze. This check does not promote any state.
		var shape := PREP.make_action(request, context, authority.call("state", character),
			int(authority.call("revision", character)), str(stream.epoch), world.world_id, stream.cursor,
			"0".repeat(32), source_kind)
		if shape.is_empty(): return _deny("owner_passive_request_source_changed")
		stream.checkpoint = {"id": Crypto.new().generate_random_bytes(16).hex_encode(),
			"binding": binding, "source_kind": source_kind, "request": request.duplicate(true),
			"host_context": context.duplicate(true)}
	elif not PREP.exact(stream.checkpoint.binding, binding): return _deny("owner_passive_original_pending")
	_send_owner(peer, stream, {"op": "freeze", "id": stream.checkpoint.id, "source_kind": source_kind,
		"request": request, "request_hash": HASH.fingerprint(request)})
	return _deny("owner_passive_checkpoint_pending")

func pending_manual_unit(character: String, ticket: String) -> bool:
	var checkpoint: Dictionary = hosts.get(character, {}).get("checkpoint", {})
	return checkpoint.get("source_kind") == "manual_refine" \
		and checkpoint.get("host_context", {}).get("manual_unit_ticket") == ticket

## Called only by the actual consumed-permit producer, before realm announce.
## Its reservation remains uncommitted throughout normal scene/ground loading.
func portal_begin(peer: int, request: Dictionary) -> Dictionary:
	if request.get("permit", {}).get("peer_id") != peer: return _deny("owner_passive_request_scope_changed")
	var character: String = owner().call("_authority_character", peer)
	var checkpoint: Dictionary = hosts.get(character, {}).get("checkpoint", {})
	if checkpoint.get("source_kind") == "portal_arrival" and PREP.exact(checkpoint.get("request"), request) \
		and checkpoint.get("travel_ready") == true:
		if checkpoint.has("result"): _completion(peer, hosts[character])
		else: _portal_grant(peer, hosts[character])
		return _deny("owner_passive_arrival_pending")
	var context := {"character_id": character, "expected_revision": owner().get("_character_authority").call("revision", character),
		"source_key": "arrival:" + str(request.get("permit", {}).get("request_id", "")), "consumed_portal_permit": true}
	return action_gate(peer, "portal_arrival", request, context)

func _portal_grant(peer: int, stream: Dictionary) -> void:
	var checkpoint: Dictionary = stream.checkpoint
	_send_owner(peer, stream, {"op": "portal_travel", "id": checkpoint.id,
		"hash": checkpoint.prepared.hash, "request": checkpoint.request})

func portal_departure_authorized(peer: int, request: Dictionary) -> bool:
	var character: String = owner().call("_authority_character", peer)
	var checkpoint: Dictionary = hosts.get(character, {}).get("checkpoint", {})
	return checkpoint.get("source_kind") == "portal_arrival" and checkpoint.get("travel_ready") == true \
		and not checkpoint.has("refused") and not checkpoint.has("result") \
		and PREP.exact(checkpoint.get("request"), request)

func portal_grounded(peer: int, request: Dictionary) -> Dictionary:
	var character: String = owner().call("_authority_character", peer)
	var stream: Dictionary = hosts.get(character, {})
	var checkpoint: Dictionary = stream.get("checkpoint", {})
	if checkpoint.get("source_kind") != "portal_arrival" or not PREP.exact(checkpoint.get("request"), request) \
		or checkpoint.get("travel_ready") != true: return _deny("owner_passive_arrival_pending")
	if request.permit.realm == "cloudreach" and not checkpoint.has("arrival_discoveries"):
		var context := _context(peer, stream)
		if context.realm != request.permit.realm or not context.get("initial_position") is Vector3:
			return _deny("owner_passive_arrival_pending")
		# Cloud's scene bind reveals navigation landmarks while this origin
		# checkpoint freezes ordinary discovery ticks. Reproduce that ORIGINAL
		# navigation operation from host ground/flags, without a passive tick.
		# Scene navigation binds BEFORE any personal waystone seating. Only
		# the original canonical first entry proves that same navigation source.
		if _cloud_initial_navigation_bound(request, stream.cursor.state, context.initial_position, stream.cursor.discovered):
			checkpoint.arrival_discoveries = _cloud_arrival_discoveries(stream.cursor.discovered,
				context.initial_position, owner().call("_foundation_flags", peer), _game().get("world").flags.call("all_set"))
	checkpoint.grounded = true # Caller just revalidated actual owner BOOL + host ground binding.
	_commit_saved(peer, stream)
	return checkpoint.get("result", checkpoint.get("last_result", _deny("owner_passive_arrival_pending"))).duplicate(true)

static func _cloud_initial_navigation_bound(request: Dictionary, state: Dictionary, at: Vector3, discovered: Dictionary) -> bool:
	if request.permit.realm != "cloudreach" or not discovered.get("cloudreach", []).is_empty() \
		or not str(state.redesign_character.last_waystones.get("cloudreach", "")).is_empty(): return false
	var world: Dictionary = DATA.json("res://data/config/cloudreach_world.json")
	var entry: Dictionary = world.transition_points.meadows_entry
	if request.permit.entry_id != entry.id: return false
	var position: Array = entry.position
	var region: String = CLOUD_MAP.region_at(world, Vector3(position[0], position[1], position[2]))
	return not region.is_empty() and CLOUD_MAP.region_at(world, at) == region

static func _cloud_arrival_discoveries(previous: Dictionary, at: Vector3, personal: Dictionary, world_flags: Array) -> Dictionary:
	var flags := NavigationFlags.new()
	flags.flags = personal.duplicate(true)
	for id: String in world_flags: flags.flags[id] = true
	var map := CLOUD_MAP.new()
	map.configure_cloudreach(DATA.json("res://data/config/cloudreach_world.json"),
		DATA.json("res://data/config/cloudreach_chapter.json"), flags)
	map.load_data({"realm_id": "cloudreach", "landmarks": previous.get("cloudreach", []).duplicate()})
	map.sync_navigation(flags, at)
	var result := previous.duplicate(true)
	result.cloudreach = map.save_data().landmarks.duplicate()
	return result

func portal_refused(peer: int, request: Dictionary, reason: String) -> bool:
	var character: String = owner().call("_authority_character", peer)
	var stream: Dictionary = hosts.get(character, {})
	var checkpoint: Dictionary = stream.get("checkpoint", {})
	if checkpoint.get("source_kind") != "portal_arrival" or not PREP.exact(checkpoint.get("request"), request) \
		or checkpoint.get("travel_ready") != true or checkpoint.has("result"): return false
	# A prior immutable journal owns recovery; never cancel it for lost ground.
	var world: RefCounted = _game().get("world")
	var row: Dictionary = world.reward_deliveries.get(E.training_delivery_id(world.reward_delivery_namespace, character), {})
	if row.get("action") == "portal_arrival" and row.get("intent", {}).get("permit_id") == request.permit.request_id: return false
	checkpoint.refused = reason
	_commit_saved(peer, stream)
	return true

func portal_pose_save(producer: Node, request: Dictionary) -> bool:
	if producer != owner().get_node_or_null(^"FoundationComposition/PortalArrival") \
		or pending.get("source_kind") != "portal_arrival" or pending.get("phase") != "saved" \
		or not pending.has("prepared") or not PREP.exact(pending.prepared.request, request) \
		or owner().call("_owner_passive_request_matches", "portal_arrival", request) != true \
		or not PREP.exact(_projection(), pending.prepared.after): return false
	var saver: RefCounted = _game().get("save_system")
	if saver == null or saver.call("fallback_busy") == true: return false
	saving = true # Only exact portable state is allowed; actual pose is outside it.
	var saved: bool = saver.call("save_character_prepared", _game(), str(local.character)) == true
	saving = false
	return saved and pending.get("scope") == _scope() and pending.has("prepared") \
		and PREP.exact(_projection(), pending.prepared.after)

func portal_departed(peer: int) -> void:
	for character: String in hosts.keys():
		var stream: Dictionary = hosts[character]
		if stream.get("departed") == true:
			if stream.get("recovery", {}).get("peer") == peer:
				var recovering: Dictionary = stream.recovery
				var candidates: Array[Dictionary] = [{"prepared": recovering.checkpoint.baseline.duplicate(true),
					"cursor": recovering.checkpoint.baseline_cursor.duplicate(true)}]
				if recovering.checkpoint.has("prepared"):
					var proof: Dictionary = recovering.checkpoint.prepared
					if PREP.valid_recovery(proof) and PREP.exact(proof.after, recovering.cursor.state) \
						and proof.final_sequence == recovering.cursor.sequence and proof.input_prefix_hash == recovering.cursor.prefix_hash:
						var next := _recovery_candidate(stream.checkpoint.prepared, _recovery_aggregate(recovering))
						if not next.is_empty(): candidates.append(next)
				stream.recovery_candidates = candidates # Latest save may have kept either exact candidate.
				stream.erase("recovery")
			continue
		if stream.peer == peer and stream.has("recovered"):
			hosts.erase(character) # Its complete passive BOOL/CAS already supplies the new baseline.
			continue
		if stream.peer != peer or stream.checkpoint.get("source_kind") != "portal_arrival": continue
		if stream.checkpoint.has("prepared"):
			if stream.checkpoint.get("travel_ready") != true:
				# The origin BOOL may have reached disk while its ACK was lost.
				# Keep the exact reservation/cursor/permit until a fresh save proves
				# an authenticated reconnect's replay. Hello alone changes nothing.
				stream.departed = true
				stream.peer = -1
				continue
			var authority: RefCounted = owner().get("_character_authority")
			# A known origin BOOL ACK must survive reconnect as the same admitted
			# baseline. This promotes only validated passive input, never arrival.
			if stream.checkpoint.get("travel_ready") == true and not stream.checkpoint.has("result") \
				and authority.call("commit_owner_passive_checkpoint", character, stream.checkpoint.prepared.hash) != true: return
			authority.call("cancel_owner_passive_checkpoint", character, stream.checkpoint.prepared.hash)
		hosts.erase(character) # A new admission must validate its own portable baseline.

func _frozen_host(peer: int, stream: Dictionary, packet: Dictionary) -> void:
	var checkpoint: Dictionary = stream.checkpoint
	if checkpoint.is_empty() or packet.get("id") != checkpoint.id \
		or not packet.get("sequence") is int or not HASH._hex(packet.get("hash"), 64) \
		or not HASH._hex(packet.get("prefix_hash"), 64):
		_note_host(stream, "frozen ignored: checkpoint %s, packet %s" % [str(checkpoint.get("id", "")).left(8), str(packet.get("id", "")).left(8)])
		return
	var frozen := {"sequence": packet.sequence, "hash": packet.hash, "prefix_hash": packet.prefix_hash}
	if checkpoint.has("frozen") and not E._equivalent(checkpoint.frozen, frozen):
		_note_host(stream, "frozen ignored: owner refroze at sequence %d (was %d)" % [int(packet.sequence), int(checkpoint.frozen.sequence)])
		return
	checkpoint.frozen = frozen
	_prepare_host(peer, stream)

func _prepare_host(peer: int, stream: Dictionary) -> void:
	var checkpoint: Dictionary = stream.checkpoint
	if not str(stream.error).is_empty() or checkpoint.is_empty() or not checkpoint.has("frozen"): return
	var frozen: Dictionary = checkpoint.frozen
	if int(stream.cursor.sequence) < int(frozen.sequence):
		_note_host(stream, "prepare waits for inputs: cursor %d < frozen %d" % [int(stream.cursor.sequence), int(frozen.sequence)])
		return
	var projected: Dictionary = stream.cursor.state
	if checkpoint.get("duty", {}).get("action") == "combat_round_reward":
		projected = preload("res://scripts/net/combat_round_reward.gd").settled_before(projected, checkpoint.duty.intent, checkpoint.duty.context)
	elif checkpoint.get("duty", {}).get("action") == "wild_defeat_share" or PREP._master_settled(checkpoint.get("duty", {})):
		projected = preload("res://scripts/net/wild_actor_scope.gd").settled_before(projected, checkpoint.duty.context)
	if stream.cursor.sequence != frozen.sequence or stream.cursor.prefix_hash != frozen.prefix_hash \
		or projected.is_empty() or HASH.fingerprint(projected) != frozen.hash:
		stream.error = "owner_passive_exact_projection_conflict"; return
	if checkpoint.get("recovery") == true:
		if not checkpoint.has("prepared"):
			checkpoint.prepared = PREP.make_recovery(checkpoint.original, checkpoint.baseline, stream.id, stream.cursor, checkpoint.id)
			if checkpoint.prepared.is_empty():
				checkpoint.erase("prepared")
				return
		_send_owner(peer, stream, {"op": "recovery_prepared", "id": checkpoint.id, "prepared": checkpoint.prepared})
		return
	if not checkpoint.has("prepared"):
		var authority: RefCounted = owner().get("_character_authority")
		var before: Dictionary = authority.call("state", stream.character)
		if not E._equivalent(before, stream.cursor.base) or authority.call("revision", stream.character) != stream.revision:
			stream.error = "owner_passive_authority_changed"; return
		var prepared: Dictionary
		if checkpoint.has("source_kind"):
			prepared = PREP.make_action(checkpoint.request, checkpoint.host_context, before, stream.revision,
				stream.epoch, str(stream.world_id), stream.cursor, checkpoint.id, checkpoint.source_kind)
		else:
			prepared = PREP.make(checkpoint.retained, checkpoint.duty, before, stream.revision,
				stream.epoch, stream.cursor, checkpoint.id)
		if prepared.is_empty():
			_note_host(stream, "prepare produced no preparation")
			return
		if authority.call("reserve_owner_passive_checkpoint", stream.character, prepared, checkpoint.get("retained", {}), stream.cursor) != true:
			_note_host(stream, "checkpoint reservation refused (%s)" % str(authority.call("training_lock_reason", stream.character)))
			return
		checkpoint.prepared = prepared
	_send_owner(peer, stream, {"op": "prepared", "id": checkpoint.id, "prepared": checkpoint.prepared,
		"retained": checkpoint.get("retained", {})})

func _saved_host(peer: int, stream: Dictionary, packet: Dictionary) -> void:
	var checkpoint: Dictionary = stream.checkpoint
	if checkpoint.is_empty() or not checkpoint.has("prepared") or packet.get("id") != checkpoint.id \
		or packet.get("hash") != checkpoint.prepared.hash or packet.get("saved") != true: return
	if checkpoint.get("recovery") == true:
		_recovery_saved(peer, stream)
		return
	if checkpoint.has("result"):
		_completion(peer, stream)
		return
	if checkpoint.get("source_kind") == "portal_arrival":
		checkpoint.travel_ready = true # Authenticated ACK of the frozen origin BOOL save.
		if not checkpoint.get("grounded", false) and not checkpoint.has("refused"):
			_portal_grant(peer, stream)
			return
	_commit_saved(peer, stream)

func _recovery_saved(peer: int, stream: Dictionary) -> void:
	var original_stream: Dictionary = hosts.get(stream.character, {})
	var prepared: Dictionary = stream.checkpoint.prepared
	if not str(stream.error).is_empty() or original_stream.get("departed") != true or original_stream.get("recovery") != stream \
		or not PREP.exact(original_stream.checkpoint.prepared, prepared.original) \
		or not PREP.exact(stream.checkpoint.baseline, prepared.baseline) \
		or not PREP.exact(stream.cursor.base, prepared.baseline.after) \
		or not PREP.valid_recovery(prepared) or not PREP.exact(prepared.after, stream.cursor.state) \
		or prepared.final_sequence != stream.cursor.sequence or prepared.input_prefix_hash != stream.cursor.prefix_hash \
		or not PREP.exact(prepared.discoveries, stream.cursor.discovered): return
	var authority: RefCounted = owner().get("_character_authority")
	var checkpoint: Dictionary = stream.checkpoint
	if checkpoint.get("original_resolved") != true:
		if PREP.exact(prepared.baseline.before, prepared.original.after):
			if authority.call("commit_owner_passive_checkpoint", stream.character, prepared.original.hash) != true: return
		elif not PREP.exact(authority.call("state", stream.character), prepared.original.before): return
		if authority.call("cancel_owner_passive_checkpoint", stream.character, prepared.original.hash) != true: return
		checkpoint.original_resolved = true
	# The fresh BOOL also saved the exact reconnect replay. Promote that care
	# through the existing full-record reservation/CAS, using the same consumed
	# original solely as its source binding. No arrival producer is called.
	if not checkpoint.has("passive_prepared"):
		var aggregate := _recovery_aggregate(stream)
		var fresh := PREP.make_action(prepared.original.request, prepared.original.host_context,
			authority.call("state", stream.character), int(authority.call("revision", stream.character)),
			stream.epoch, stream.world_id, aggregate, checkpoint.id, "portal_arrival")
		if fresh.is_empty() or authority.call("reserve_owner_passive_checkpoint", stream.character, fresh, {}, aggregate) != true: return
		checkpoint.passive_prepared = fresh
	if authority.call("commit_owner_passive_checkpoint", stream.character, checkpoint.passive_prepared.hash) != true: return
	if authority.call("cancel_owner_passive_checkpoint", stream.character, checkpoint.passive_prepared.hash) != true: return
	stream.recovered = {"id": stream.checkpoint.id, "hash": prepared.hash}
	checkpoint.no_effect = true # Existing exact rebase establishes a fresh travel baseline.
	checkpoint.recovery = false
	hosts[stream.character] = stream # Same new replay/prefix; no owner state import.
	_send_owner(peer, stream, {"op": "inputs_ack", "sequence": stream.cursor.sequence})
	_send_owner(peer, stream, {"op": "portal_recovered", "id": stream.recovered.id, "hash": stream.recovered.hash})

func _commit_saved(peer: int, stream: Dictionary) -> void:
	var checkpoint: Dictionary = stream.checkpoint
	if checkpoint.has("result"):
		_completion(peer, stream)
		return
	var world: RefCounted = _game().get("world")
	if not checkpoint.has("source_kind") and not E._equivalent(world.reward_deliveries.get(checkpoint.retained.delivery_id), checkpoint.retained): return
	var authority: RefCounted = owner().get("_character_authority")
	if authority.call("commit_owner_passive_checkpoint", stream.character, checkpoint.prepared.hash) != true: return
	committing = checkpoint.binding.duplicate(true)
	var result: Dictionary
	if checkpoint.has("refused"):
		result = _terminal("portal_arrival_refused")
		result.reason = checkpoint.refused
	elif checkpoint.has("source_kind"):
		# Request checkpoints preserve the action revision. Original Altar/
		# Traits intent and immutable receipt correlation are never rewritten.
		result = owner().call("_owner_passive_commit_request", peer, checkpoint.source_kind,
			committing.envelope, checkpoint.host_context)
	elif committing.action == "wild_capture":
		# The exact choice/source remains the authenticated original. Only this
		# host's successful checkpoint CAS advances its expected revision.
		committing.envelope.revision = authority.call("revision", stream.character)
		result = owner().call("_foundation_handle", peer, committing.envelope)
	elif committing.action == "research_event":
		result = RESEARCH.commit(owner(), peer, committing.action, committing.intent, committing.event)
	else:
		result = owner().call("_owner_passive_commit_retained", peer, committing)
	committing.clear()
	checkpoint.last_result = result.duplicate(true)
	var no_effect: bool = _terminal_without_effect(stream, result)
	if result.get("durable") == true or result.get("code") == "research_no_progress" or no_effect:
		authority.call("cancel_owner_passive_checkpoint", stream.character, checkpoint.prepared.hash)
		checkpoint.result = result.duplicate(true)
		checkpoint.no_effect = no_effect
		_completion(peer, stream)
	else:
		authority.call("retain_owner_passive_checkpoint", stream.character, checkpoint.prepared.hash)

func _terminal_without_effect(stream: Dictionary, result: Dictionary) -> bool:
	if result.get("durable") == true or result.get("terminal_refusal") != true or result.get("resolved") != true: return false
	if result.get("code") in ["training_journal_failed", "world_not_prepared", "world_save_failed", "stage_changed", "fallback_busy", "character_busy", "transaction_busy"]: return false
	var authority: RefCounted = owner().get("_character_authority")
	return authority.call("creature_training_is_pending", str(stream.character)) != true \
		and PREP.exact(authority.call("state", stream.character), stream.checkpoint.prepared.after)

func _completion(peer: int, stream: Dictionary) -> void:
	var checkpoint: Dictionary = stream.checkpoint
	var op := "journaled"
	if checkpoint.get("no_effect") == true: op = "no_effect"
	elif checkpoint.result.get("code") == "research_no_progress": op = "no_progress"
	var packet := {"op": op, "id": checkpoint.id, "hash": checkpoint.prepared.hash, "result": checkpoint.result}
	# The host's proven first-arrival navigation reveal, sent exactly when its
	# _rebase_host will seed from it; the owner adopts it, never its own map.
	if checkpoint.get("source_kind") == "portal_arrival" and checkpoint.get("grounded") == true \
		and checkpoint.get("arrival_discoveries") is Dictionary and checkpoint.result.get("durable") == true:
		packet["arrival_discoveries"] = checkpoint.arrival_discoveries.duplicate(true)
	_send_owner(peer, stream, packet)

func receive_owner(packet: Dictionary) -> void:
	if local.is_empty():
		_note_ignored("%s before this owner armed a stream" % str(packet.get("op", "")))
		return
	var scope := _scope()
	for field: String in scope:
		if packet.get(field) != scope[field]:
			if packet.get("op") == "readmit" and owner().call("handshake_snapshot_applied") != true:
				held_readmit = packet.duplicate(true) # This world's scope is not set yet.
				return
			_note_ignored("%s for another %s" % [str(packet.get("op", "")), field])
			return
	if packet.get("stream_id") != local.id and packet.get("op") != "inputs_ack":
		_note_ignored("%s for stream %s, this owner is on %s" % [str(packet.get("op", "")),
			str(packet.get("stream_id", "")).left(8), str(local.id).left(8)])
	if packet.get("stream_id") != local.id:
		if packet.get("op") != "inputs_ack" or local.rebase.get("old_stream") != packet.get("stream_id") \
			or not packet.get("sequence") is int or packet.sequence > int(local.rebase.get("old_sequence", -1)): return
		var old_inputs: Array = local.rebase.get("old_inputs", [])
		while not old_inputs.is_empty() and int(old_inputs[0].sequence) <= int(packet.sequence): old_inputs.pop_front()
		return
	match packet.get("op"):
		"redeclaration":
			if not HASH._hex(packet.get("request_id"), 32) or owner().call("snapshot_ready") != true \
				or not pending.is_empty() or not local.rebase.is_empty() or not str(local.error).is_empty() \
				or local.get("hello_pending") != true: return
			var original_stream: String = local.id
			var game := _game()
			var saved_data: Dictionary = game.get("local").call("save_data")
			var discoveries := _discoveries()
			if not _save_owner_now() or _scope() != scope or local.get("id") != original_stream \
				or not PREP.exact(saved_data, game.get("local").call("save_data")): return
			var summary := {"character_id": local.character, "portable_authority": RECORD.portable_projection(saved_data),
				"personal_flags": saved_data.get("flags", {"flags": []}), "discovered_landmarks": discoveries,
				"settled_deliveries": [], "owed_deliveries": []}
			for key: Variant in saved_data.get("satchel_escrow", {}):
				var row: Variant = saved_data.satchel_escrow[key]
				if row is Dictionary and row.get("kind") == "reward_delivery":
					if row.get("status") == "settled": summary.settled_deliveries.append(str(key))
					elif row.get("status") == "grant_due": summary.owed_deliveries.append(str(key))
			summary.owner_passive_stream = arm_owner(summary.portable_authority, discoveries)
			if summary.owner_passive_stream.is_empty(): return
			pending = {"phase": "redeclaration", "scope": scope, "id": packet.request_id, "original_stream": original_stream,
				"message": {"op": "redeclare", "request_id": packet.request_id, "summary": summary.duplicate(true)}}
			_flush()
		"portal_recover":
			var original: Variant = packet.get("original")
			var baseline: Variant = packet.get("baseline")
			if not HASH._hex(packet.get("id"), 32) or not PREP.valid_action(original) \
				or original.source_kind != "portal_arrival" or original.character_id != scope.character_id \
				or original.world_id != scope.world_id or original.world_namespace != scope.world_namespace \
				or original.session_epoch != scope.session_epoch \
				or not PREP.valid_action(baseline) or baseline.source_kind != "portal_arrival" \
				or baseline.world_id != original.world_id or not PREP.exact(baseline.request, original.request) \
				or not PREP.exact(baseline.host_context, original.host_context) \
				or (not PREP.exact(baseline.before, original.before) and not PREP.exact(baseline.before, original.after)) \
				or local.base_hash != HASH.fingerprint(baseline.after): return
			if not pending.is_empty():
				if pending.id == packet.id and PREP.exact(pending.get("recovery_original"), original) \
					and PREP.exact(pending.get("recovery_baseline"), baseline): _retry_owner()
				return
			var saver: RefCounted = _game().get("save_system")
			if saver == null: return
			saver.call("finish_fallback")
			if saver.call("fallback_busy") == true or _scope() != scope: return
			pending = {"id": packet.id, "scope": scope, "sequence": local.sequence, "prefix_hash": local.prefix_hash,
				"hash": HASH.fingerprint(_projection()), "phase": "frozen", "recovery_original": original.duplicate(true),
				"recovery_baseline": baseline.duplicate(true)}
			_retry_owner()
		"recovery_prepared":
			var prepared: Variant = packet.get("prepared")
			if pending.is_empty() or pending.id != packet.get("id") or not PREP.valid_recovery(prepared) \
				or prepared.preparation_id != pending.id or prepared.stream_id != local.id \
				or not PREP.exact(pending.get("recovery_original"), prepared.original) \
				or not PREP.exact(pending.get("recovery_baseline"), prepared.baseline) \
				or HASH.fingerprint(prepared.before) != local.base_hash \
				or prepared.final_sequence != pending.sequence or prepared.input_prefix_hash != pending.prefix_hash \
				or HASH.fingerprint(prepared.after) != pending.hash \
				or (pending.has("prepared") and not PREP.exact(pending.prepared, prepared)): return
			pending.prepared = prepared.duplicate(true)
			pending.retained = {}
			pending.phase = "save"
			_retry_owner()
		"portal_recovered":
			if pending.get("phase") != "saved" or not pending.has("recovery_original") \
				or pending.id != packet.get("id") or not pending.has("prepared") \
				or pending.prepared.hash != packet.get("hash") \
				or not PREP.exact(_projection(), pending.prepared.after): return
			var old := {"checkpoint_id": pending.id, "checkpoint_hash": pending.prepared.hash}
			var previous := local.duplicate(true)
			var declaration := arm_owner(_projection(), _discoveries())
			if declaration.is_empty(): return
			_queue_rebase(declaration, previous, old)
			_flush() # Original departed permit is cancelled; normal replay starts anew.
		"portal_travel":
			if pending.get("source_kind") != "portal_arrival" or pending.get("phase") != "saved" \
				or pending.get("id") != packet.get("id") or not pending.has("prepared") \
				or packet.get("hash") != pending.prepared.hash \
				or not PREP.exact(packet.get("request"), pending.prepared.request) \
				or owner().call("_owner_passive_request_matches", "portal_arrival", packet.request) != true: return
			var arrival := owner().get_node_or_null(^"FoundationComposition/PortalArrival")
			if arrival != null: arrival.call("start_prepared", packet.request)
		"rebase_ack":
			if owner().has_method("_apply_host_tether_tonics"):
				owner().call("_apply_host_tether_tonics", packet.get("tether_tonics", {}))
			local.rebase = {}
			local.admission_pending = false
		"readmit":
			var admission: Dictionary = pending.duplicate(true) if pending.get("phase") == "redeclaration" else {}
			if not admission.is_empty(): pending.clear()
			_readmit_owner(packet)
			if not admission.is_empty() and local.get("readmitted_hash") != packet.get("baseline_hash"): pending = admission
		"admission_refused":
			var reason := str(packet.get("reason", "owner_passive_admission_conflict"))
			if local.get("admission_refused") == reason: return
			local.admission_refused = reason
			local.error = reason # stops recording and flushing: nothing more to ask
			push_warning("owner passive stream refused by the host: " + reason)
			var game := _game()
			if game != null and game.has_method("push_world_message"):
				game.call("push_world_message", "This world's record of your companions differs from yours. Their care and Altar actions are paused until you rejoin.")
		"inputs_ack":
			if not packet.get("sequence") is int or packet.sequence < local.acked or packet.sequence > local.sequence: return
			if pending.get("phase") == "redeclaration": pending.clear()
			if owner().has_method("_apply_host_tether_tonics"):
				owner().call("_apply_host_tether_tonics", packet.get("tether_tonics", {}))
			local.admission_pending = false
			local.hello_pending = false
			if packet.sequence > int(local.acked): local.ack_progress_ms = Time.get_ticks_msec()
			local.acked = packet.sequence
			while not local.inputs.is_empty() and int(local.inputs[0].sequence) <= int(local.acked): local.inputs.pop_front()
		"freeze":
			if not HASH._hex(packet.get("id"), 32): return
			var request_source: bool = packet.get("source_kind") in REQUEST_KINDS
			if request_source:
				if not packet.get("request") is Dictionary or HASH.fingerprint(packet.request) != packet.get("request_hash") \
					or owner().call("_owner_passive_request_matches", packet.source_kind, packet.request) != true: return
			elif packet.has("source_kind") or not HASH._hex(packet.get("duty_hash"), 64): return
			if not pending.is_empty() and pending.id != packet.id:
				_note_ignored("freeze %s while %s is pending" % [str(packet.id).left(8), str(pending.id).left(8)])
				return
			if pending.is_empty():
				var saver: RefCounted = _game().get("save_system")
				if saver == null: return
				saver.call("finish_fallback") # Complete reentrant save callbacks before freezing any owner state.
				if saver.call("fallback_busy") == true or _scope() != scope or local.is_empty() or local.id != packet.stream_id:
					_note_ignored("freeze %s: fallback_busy=%s scope_changed=%s stream=%s" % [str(packet.id).left(8),
						str(saver.call("fallback_busy")), str(_scope() != scope), str(local.get("id", "")).left(8)])
					return
				pending = {"id": packet.id, "scope": scope, "retained_event": packet.get("retained_event"),
					"duty_hash": packet.get("duty_hash", ""), "sequence": local.sequence, "prefix_hash": local.prefix_hash,
					"hash": HASH.fingerprint(_projection()), "phase": "frozen"}
				if request_source:
					pending.source_kind = packet.source_kind
					pending.request_hash = packet.request_hash
			_retry_owner()
		"prepared":
			if pending.is_empty() or pending.id != packet.get("id"): return
			var prepared: Variant = packet.get("prepared")
			var retained: Variant = packet.get("retained")
			var request_source: bool = pending.has("source_kind")
			if request_source:
				if not PREP.valid_action(prepared) or prepared.source_kind != pending.source_kind \
					or prepared.request_hash != pending.request_hash \
					or owner().call("_owner_passive_request_matches", prepared.source_kind, prepared.request) != true: return
			elif not PREP.valid(prepared, retained) or prepared.retained_event != pending.retained_event \
				or prepared.duty_hash != pending.duty_hash: return
			if prepared.character_id != scope.character_id \
				or prepared.session_epoch != scope.session_epoch or prepared.world_namespace != scope.world_namespace \
				or prepared.world_id != scope.world_id or prepared.final_sequence != pending.sequence \
				or prepared.input_prefix_hash != pending.prefix_hash or HASH.fingerprint(prepared.after) != pending.hash: return
			if pending.has("prepared") and not E._equivalent(pending.prepared, prepared): return
			# F01#6b: the host answers every resent "frozen" with this same
			# preparation; a duplicate must not move a saving/saved owner back
			# to "save" (each such regress was another character save round).
			if pending.has("prepared") and pending.phase != "frozen": return
			pending.prepared = prepared.duplicate(true)
			pending.retained = retained.duplicate(true)
			pending.phase = "save"
			_retry_owner()
		"journaled":
			if not pending.is_empty() and pending.id == packet.get("id"):
				pending.phase = "journaled" # Existing original owner-row settlement releases the fence.
			# The host's proven arrival reveal for this stream's arrival receipt;
			# used only by the settlement of that exact receipt (owner_settled).
			var proven: Variant = packet.get("arrival_discoveries")
			if proven is Dictionary and packet.get("result", {}).get("receipt") is String:
				local.arrival_proof = {"receipt": packet.result.receipt, "discovered": (proven as Dictionary).duplicate(true)}
		"no_progress", "no_effect":
			if pending.is_empty() or pending.id != packet.get("id") or not pending.has("prepared") \
				or packet.get("hash") != pending.prepared.hash \
				or not PREP.exact(_projection(), pending.prepared.after): return
			var result: Dictionary = packet.get("result", {})
			if packet.op == "no_progress" and result.get("code") != "research_no_progress": return
			if packet.op == "no_effect" and (result.get("terminal_refusal") != true or result.get("resolved") != true or result.get("durable") == true): return
			var old := {"checkpoint_id": pending.id, "checkpoint_hash": pending.prepared.hash}
			var terminal_source := str(pending.get("source_kind", ""))
			var terminal_request: Dictionary = pending.prepared.get("request", {}).duplicate(true)
			var previous := local.duplicate(true)
			var declaration := arm_owner(_projection(), _discoveries())
			if declaration.is_empty(): return
			_queue_rebase(declaration, previous, old)
			_flush()
			if packet.op == "no_effect" and not terminal_source.is_empty():
				owner().call("_owner_passive_request_terminal", terminal_source, terminal_request, result)

func blocked(player: RefCounted) -> bool:
	return _game() != null and player == _game().get("local") and ((not pending.is_empty() and pending.scope == _scope()) \
		or (not stormwood_owner.is_empty() and stormwood_owner.scope == _scope() and not stormwood_applying))

func snapshot_allowed(player: RefCounted, payload: Dictionary) -> bool:
	if not stormwood_owner.is_empty() and blocked(player) and (stormwood_saving \
		or (stormwood_owner.get("host") == true and stormwood_owner.get("saved") == true)):
		return PREP.exact(RECORD.portable_projection(payload), stormwood_owner.get("after"))
	return saving and blocked(player) and pending.has("prepared") \
		and PREP.exact(RECORD.portable_projection(payload), pending.prepared.after)

func _retry_owner() -> void:
	if pending.is_empty() or pending.scope != _scope() or not str(local.error).is_empty(): return
	_flush()
	if pending.phase == "frozen":
		if not _resend_due("frozen"): return
		_send_host({"op": "frozen", "id": pending.id, "sequence": pending.sequence,
			"prefix_hash": pending.prefix_hash, "hash": pending.hash})
	elif pending.phase == "save":
		var saver: RefCounted = _game().get("save_system")
		if saver == null: return
		saver.call("finish_fallback")
		if saver.call("fallback_busy") == true or pending.scope != _scope(): return
		var plan := PREP.owner_plan(_projection(), pending.prepared, pending.retained, _discoveries())
		if plan.get("ok") != true:
			local.error = str(plan.get("code", "owner_passive_owner_changed")); return
		saving = true
		var saved: bool = saver.call("save_character_prepared", _game(), str(local.character)) == true
		saving = false
		if not saved or pending.scope != _scope(): return
		if not PREP.exact(_projection(), pending.prepared.after):
			local.error = "owner_passive_owner_changed_after_save"; return
		pending.phase = "saved"
	if pending.phase == "saved" and _resend_due("saved"):
		_send_host({"op": "saved", "id": pending.id, "hash": pending.prepared.hash, "saved": true})


## F01#6b: a checkpoint message goes once when its phase starts, then at most
## once per CHECKPOINT_RESEND_S while the host has not answered (reliable
## transport; the resend only covers a host that dropped the stream).
func _resend_due(phase: String) -> bool:
	var now := Time.get_ticks_msec()
	if pending.get("sent_phase") == phase and now - int(pending.get("sent_ms", 0)) < int(CHECKPOINT_RESEND_S * 1000.0): return false
	pending.sent_phase = phase
	pending.sent_ms = now
	return true

## Owner: the host re-admitted this stream on its recovered authority (see
## `admitted`). Adopt the host's passive values (or, marked `adopt`, its whole
## held record) and restart this stream's cursor on that baseline. Inputs
## recorded on the old base since joining are dropped with it.
func _readmit_owner(packet: Dictionary) -> void:
	var baseline: Variant = packet.get("baseline")
	if not baseline is Dictionary or HASH.fingerprint(baseline) != packet.get("baseline_hash"): return
	if local.get("readmitted_hash") == packet.baseline_hash:
		_send_host({"op": "readmitted", "baseline_hash": packet.baseline_hash})
		return
	var game := _game()
	# Review G1: the host's held landmarks win inside its world. A readmit may
	# carry them; anything else must already match this owner's.
	var held: Variant = packet.get("discovered")
	var adopt: bool = held is Dictionary and HASH.fingerprint({"discovered": held}) == packet.get("discoveries_hash")
	# A durable change (adoption, settled payouts) is saved before "readmitted"
	# (re-review M-1); a failed save puts the owner back and the host resends.
	var durable: bool = packet.get("adopt") == true or not (packet.get("folded", []) as Array).is_empty()
	var undo := _owner_undo_point() if durable and game != null else {}
	var adopted := false
	if pending.is_empty() and game != null and packet.get("adopt") == true \
		and not E._equivalent(REPLAY._core(baseline), REPLAY._core(_projection())):
		# Owner ruling (STATE §0): this world's held record wins; adopt it whole.
		adopted = true
		var outcome := _adopt_held_record(baseline)
		if outcome != "ok":
			_note_ignored("held-record adoption deferred: " + outcome)
			if not local.get("adopt_wait_told", false):
				local.adopt_wait_told = true
				game.call("push_world_message", "Joining this world's record of your character… (" + outcome + ")")
			return
	if not pending.is_empty() or game == null \
		or (not adopt and HASH.fingerprint({"discovered": _discoveries()}) != packet.get("discoveries_hash")) \
		or not E._equivalent(REPLAY._core(baseline), REPLAY._core(_projection())):
		_note_ignored("readmit whose core no longer matches this owner")
		return
	var members: Dictionary = {}
	for member: RefCounted in game.get("party").call("members"): members[str(member.get("uid"))] = member
	for card: Dictionary in baseline.party:
		if members.get(str(card.get("uid", ""))) == null:
			_owner_undo(undo)
			_note_ignored("readmit naming creature %s this owner does not hold" % str(card.get("uid", "")))
			return
	if adopt:
		local.discovered = (held as Dictionary).duplicate(true) # The host's held set wins; maps untouched.
	for card: Dictionary in baseline.party:
		var member: RefCounted = members.get(str(card.get("uid", "")))
		for field: String in REPLAY.PASSIVE_FIELDS:
			if card.has(field) and field in member: member.set(field, card[field])
	if not E._equivalent(_projection(), baseline):
		_owner_undo(undo) # never left adopted, unsaved and unsettled (review L4)
		local.admission_refused = "owner_passive_readmit_mismatch"
		local.error = local.admission_refused
		push_warning("owner passive readmit did not reproduce the host's baseline")
		return
	if (_settle_folded(packet.get("folded", [])) > 0 or adopted) and not _save_owner_now():
		_owner_undo(undo)
		_note_ignored("readmit not saved; the host resends it")
		return
	if owner().has_method("_apply_host_tether_tonics"):
		owner().call("_apply_host_tether_tonics", packet.get("tether_tonics", {}))
	var cursor := REPLAY.begin(baseline, _discoveries())
	if cursor.is_empty(): return
	local.base_hash = packet.baseline_hash
	local.sequence = 0
	local.prefix_hash = cursor.prefix_hash
	local.inputs = []
	local.acked = 0
	local.inflight_through = 0
	local.vitals_seen = {}
	local.readmitted_hash = packet.baseline_hash
	# A cursor restarted on a new base restarts the travel/discovery clocks,
	# exactly as arm_owner does; a discovery input timed on the old clock fails
	# the host's replay as discovery_cadence (re-proof run 2026-10-04T22:09:55Z).
	game.set("_travel_pos_valid", false)
	game.set("_discovery_elapsed", 0.0)
	_send_host({"op": "readmitted", "baseline_hash": packet.baseline_hash})


## The owner's whole state and creature instances, to put back exactly.
func _owner_undo_point() -> Dictionary:
	var party: RefCounted = _game().get("party")
	var player: RefCounted = _game().get("local")
	if party == null or player == null or not player.has_method("save_data"): return {}
	var members := {}
	for member: RefCounted in party.call("members"): members[str(member.get("uid"))] = member
	var active: Variant = party.call("at", int(party.get("_active"))) if "_active" in party else null
	var best: Variant = party.call("at", int(party.get("_best"))) if "_best" in party else null
	return {"data": player.call("save_data"), "members": members,
		"active": str((active as RefCounted).get("uid")) if active is RefCounted else "",
		"best": str((best as RefCounted).get("uid")) if best is RefCounted else ""}


func _owner_undo(undo: Dictionary) -> void:
	if undo.is_empty(): return
	var party: RefCounted = _game().get("party")
	var ordered := _load_keeping_instances(_game().get("local"), party, undo.data, undo.members)
	var uids := ordered.map(func(m: RefCounted) -> String: return str(m.get("uid")))
	party.set("_active", maxi(0, uids.find(undo.active)))
	party.set("_best", uids.find(undo.best) if not str(undo.best).is_empty() else -1)
	party.set("revision", int(party.get("revision")) + 1)


func _save_owner_now() -> bool:
	var saver: RefCounted = _game().get("save_system")
	if saver == null: return false
	if saver.has_method("finish_fallback"): saver.call("finish_fallback") # as the freeze path does
	if saver.call("fallback_busy") == true: return false
	saving = true
	var saved: bool = saver.call("save_character_prepared", _game(), str(local.character)) == true
	saving = false
	return saved


## Owner, on every readmit: the payout rows the host's held record already
## holds while their world row is pending are marked settled here, before this
## owner may process their redelivery (delivery waits for admission,
## session._owner_passive_delivery_ready), so it acknowledges without paying a
## second time (re-review H1). A row this owner already settled is untouched.
func _settle_folded(folded: Variant) -> int:
	if not folded is Array or (folded as Array).is_empty(): return 0
	var player: RefCounted = _game().get("local")
	if player == null or not player.get("satchel_escrow") is Dictionary: return 0
	var escrow: Dictionary = player.get("satchel_escrow")
	var settled_count := 0
	for row: Variant in folded:
		if not row is Dictionary or str(row.get("character_id", "")) != str(player.get("character_id")) \
			or str(row.get("delivery_id", "")) != REWARD.delivery_id(str(row.get("world_namespace", "")), str(row.get("source", "")), str(row.get("character_id", ""))): continue
		if escrow.get(row.delivery_id) is Dictionary and str(escrow[row.delivery_id].get("status", "")) == "settled": continue
		var settled: Dictionary = (row as Dictionary).duplicate(true)
		settled.kind = "reward_delivery"
		settled.status = "settled"
		var flag := str(settled.get("completion_flag", ""))
		if not flag.is_empty() and player.get("flags") != null: (player.get("flags") as RefCounted).call("set_flag", flag, true)
		settled.erase("stacks")
		settled.erase("completion_flag")
		settled.erase("status_ms")
		escrow[row.delivery_id] = settled
		settled_count += 1
	if settled_count > 0: print("[owner-passive] %d payout(s) this world already holds marked settled" % settled_count)
	return settled_count


## Owner, on a readmit marked `adopt`: replace this character's portable
## fields with the host's held record (party, satchel, gear, loadouts,
## receipts, portal/vitals escrow, heart selection). Creatures the record keeps
## are updated in place, so a deployed body still drives the same instance; a
## creature the record lacks (an offline catch) leaves the party, its body put
## away first. (The payouts the record holds are settled by _settle_folded.)
## All or nothing: a failed attempt restores the owner's state exactly (review
## M2). Returns "ok", or why it must wait (the host resends the readmit).
const _RUNTIME_ONLY := ["active_buffs", "combat_override"] # never saved; kept per instance

func _adopt_held_record(baseline: Dictionary) -> String:
	var game := _game()
	var player: RefCounted = game.get("local")
	var party: RefCounted = game.get("party")
	if player == null or party == null: return "no local character"
	var inventory: RefCounted = player.get("inventory")
	if party.call("owner_mutation_blocked") == true \
		or (inventory.has_method("_owner_mutation_blocked") and inventory.call("_owner_mutation_blocked") == true):
		return "a saved companion decision is still settling"
	var kept := {}
	for card: Variant in baseline.get("party", []):
		if card is Dictionary: kept[str(card.get("uid", ""))] = true
	# Bodies of creatures the record lacks are put away only once it applies
	# (review L4). A freed body is checked before its type (review L3).
	var away: Array = []
	for director: Node in _portal_directors(game):
		var ally: Variant = director.get("_ally")
		var body: Variant = director.get("_ally_body")
		if ally is RefCounted and is_instance_valid(body) and not kept.has(str((ally as RefCounted).get("uid"))):
			if not _can_dismiss(director): return "a companion this world does not know is in a fight"
			away.append(director)
	var restore: Dictionary = player.call("save_data")
	var data: Dictionary = restore.duplicate(true)
	var energy := {}
	for card: Dictionary in data.get("party", []): energy[str(card.get("uid", ""))] = card.get("energy", 0.0)
	var cards: Array = []
	for card: Dictionary in baseline.party:
		var copy := card.duplicate(true)
		if energy.has(str(copy.get("uid", ""))): copy.energy = energy[str(copy.uid)]
		cards.append(copy)
	data.party = cards
	data.redesign_character = (baseline.redesign_character as Dictionary).duplicate(true)
	data.inventory = (baseline.inventory as Array).duplicate(true)
	data.equipment = (baseline.equipment as Dictionary).duplicate(true)
	data.realm_hearts = (baseline.realm_hearts as Dictionary).duplicate(true)
	# The escrow rows the projection carries come from the held record; every
	# other row (not portable authority) stays the owner's.
	var mine: Dictionary = RECORD.portable_projection({"character_id": data.get("character_id"), "satchel_escrow": data.get("satchel_escrow", {})})
	var escrow := {}
	for key: Variant in data.get("satchel_escrow", {}):
		if not (mine.portal_escrow as Dictionary).has(key) and not (mine.vitals_escrow as Dictionary).has(key): escrow[key] = data.satchel_escrow[key]
	for key: Variant in baseline.get("portal_escrow", {}): escrow[key] = baseline.portal_escrow[key]
	for key: Variant in baseline.get("vitals_escrow", {}): escrow[key] = baseline.vitals_escrow[key]
	data.satchel_escrow = escrow
	var before := {}
	for member: RefCounted in party.call("members"): before[str(member.get("uid"))] = member
	var active_uid := str((party.call("at", int(party.get("_active"))) as RefCounted).get("uid")) if party.call("at", int(party.get("_active"))) != null else ""
	var best_uid := str((party.call("at", int(party.get("_best"))) as RefCounted).get("uid")) if party.call("at", int(party.get("_best"))) != null else ""
	var ordered := _load_keeping_instances(player, party, data, before)
	var uids := ordered.map(func(m: RefCounted) -> String: return str(m.get("uid")))
	party.set("_active", maxi(0, uids.find(active_uid)))
	party.set("_best", uids.find(best_uid) if not best_uid.is_empty() else -1)
	party.set("revision", int(party.get("revision")) + 1)
	var refused := "" if E._equivalent(REPLAY._core(_projection()), REPLAY._core(baseline)) else "the record could not be applied here"
	for director: Node in away:
		if refused.is_empty() and director.call("dismiss_active_creature") != true: refused = "a companion this world does not know is in a fight"
	if not refused.is_empty():
		var back := _load_keeping_instances(player, party, restore, before)
		var back_uids := back.map(func(m: RefCounted) -> String: return str(m.get("uid")))
		party.set("_active", maxi(0, back_uids.find(active_uid)))
		party.set("_best", back_uids.find(best_uid) if not best_uid.is_empty() else -1)
		party.set("revision", int(party.get("revision")) + 1)
		return refused
	if not local.get("adopt_told", false): # once, even if a failed save retries it (review L-2)
		local.adopt_told = true
		game.call("push_world_message", "This world keeps your character as it was here; changes made elsewhere are not used in it.")
	print("[owner-passive] adopted this world's held record (%d creature(s))" % ordered.size())
	return "ok"


## The director would put its creature away now (the same refusals as
## dismiss_active_creature), checked before anything changes (review L-2).
static func _can_dismiss(director: Node) -> bool:
	var manager: Variant = director.get("_manager")
	if manager is Object and (manager as Object).has_method("is_fighting") and manager.call("is_fighting") == true: return false
	return not (director.has_method("trainer_battle_active") and director.call("trainer_battle_active") == true)


## The encounter directors that may hold this owner's deployed creature.
func _portal_directors(game: Node) -> Array:
	return game.get_tree().get_nodes_in_group(&"foundation_portal_directors") if game.is_inside_tree() else []


## load_data, then keep each creature the data also holds as the SAME
## instance (a deployed body drives it), updated from the freshly loaded one.
func _load_keeping_instances(player: RefCounted, party: RefCounted, data: Dictionary, before: Dictionary) -> Array:
	player.call("load_data", data)
	var ordered: Array = []
	for fresh: RefCounted in party.call("members"):
		var existing: RefCounted = before.get(str(fresh.get("uid")))
		if existing == null:
			ordered.append(fresh)
			continue
		for property: Dictionary in fresh.get_property_list():
			if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and not property.name in _RUNTIME_ONLY:
				existing.set(property.name, fresh.get(property.name))
		ordered.append(existing)
	party.set("_creatures", ordered)
	return ordered


func _flush() -> void:
	if local.is_empty() or not str(local.error).is_empty(): return
	if pending.get("phase") == "redeclaration":
		if pending.scope == _scope(): _send_host(pending.message, str(pending.original_stream))
		return # Saved declaration stays byte-for-byte frozen until admission.
	if not local.rebase.is_empty():
		var old_inputs: Array = local.rebase.get("old_inputs", [])
		if not old_inputs.is_empty():
			_send_host({"op": "inputs", "inputs": old_inputs.slice(0, mini(MAX_BATCH, old_inputs.size())).duplicate(true)}, str(local.rebase.old_stream))
		else:
			var request: Dictionary = local.rebase.duplicate(true)
			request.erase("old_inputs")
			_send_host(request)
		return # Retry until authenticated host accepts this exact saved baseline.
	if local.inputs.is_empty():
		if pending.is_empty() and local.admission_pending: _send_host({"op": "resume"})
		return
	# F01#6b: stop-and-wait. A window goes from the first unacknowledged input
	# (always contiguous with the host's cursor: the host refuses a gap), then
	# nothing more until it is acknowledged, or until acknowledgements stall
	# (the host returns early on a "waits" input and needs that prefix again).
	# Re-sending the whole window every flush cost the host ~126 ms per packet.
	var now := Time.get_ticks_msec()
	if not local.has("ack_progress_ms"): local.ack_progress_ms = now
	var in_flight: bool = int(local.get("inflight_through", 0)) > int(local.acked)
	if in_flight and now - int(local.ack_progress_ms) < int(RESEND_STALL_S * 1000.0): return
	var batch: Array = local.inputs.slice(0, mini(MAX_BATCH, local.inputs.size())).duplicate(true)
	# A window is in flight only once actually sent (a drop before the join
	# snapshot would otherwise wait a whole stall).
	if not _send_host({"op": "inputs", "inputs": batch}): return
	local.ack_progress_ms = now
	local.inflight_through = int(batch[-1].sequence)

## Diagnostic only, once per character and reason: a host checkpoint that
## silently waits leaves the fight's round reward held with no other trace.
var _host_notes: Dictionary = {}

func _note_host(stream: Dictionary, reason: String) -> void:
	var character := str(stream.get("character", ""))
	if _host_notes.get(character) == reason:
		return
	_host_notes[character] = reason
	print("[owner-passive] host %s: %s (t=%dms)" % [character.left(18), reason, Time.get_ticks_msec()])

## Diagnostic: why a host refused an owner's rebase (once per character and reason).
func _note_rebase_refused(character: String, reason: String) -> void:
	_note_host({"character": character}, "rebase refused: " + reason)

## Diagnostic only, once per distinct reason: a packet this owner drops is
## otherwise invisible, and the host simply resends it forever.
func _note_ignored(reason: String) -> void:
	if reason == _reported_ignore:
		return
	_reported_ignore = reason
	print("[owner-passive] ignored " + reason)

func tick(delta: float) -> void:
	if owner() != null and owner().is_inside_tree() and not owner().get_tree().physics_frame.is_connected(_sample_poses):
		owner().get_tree().physics_frame.connect(_sample_poses)
	_left -= delta
	if _left > 0.0: return
	_left = 0.25
	if owner() == null or owner().call("is_host") == true: return
	if not held_readmit.is_empty() and owner().call("handshake_snapshot_applied") == true:
		var readmit := held_readmit
		held_readmit = {}
		receive_owner(readmit)
	if not local.is_empty() and str(local.get("error", "")) != _reported_error:
		_reported_error = str(local.get("error", ""))
		if not _reported_error.is_empty():
			push_warning("owner passive stream stopped on this owner: " + _reported_error)
	if pending.is_empty(): _flush()
	else: _retry_owner()

func owner_settled(row: Dictionary) -> void:
	if local.is_empty() or owner().call("is_host") == true or row.get("status") != "accepted" \
		or row.get("character_id") != local.character or not row.get("after") is Dictionary \
		or local.get("last_settlement") == row.get("receipt") \
		or not PREP.exact(RECORD.training_projection(_projection(), row, E.training_projection), row.after): return
	var previous := local.duplicate(true)
	var discoveries := _discoveries()
	var proof: Variant = local.get("arrival_proof")
	if row.get("action") == "portal_arrival" and proof is Dictionary and proof.get("receipt") == row.get("receipt"):
		# Only the host's own proven arrival reveal (journaled packet) joins the
		# identity; without that proof the host rebases on its replayed set too.
		discoveries = (proof.discovered as Dictionary).duplicate(true)
	var declaration := arm_owner(_projection(), discoveries)
	if declaration.is_empty(): return
	local.last_settlement = row.receipt
	_queue_rebase(declaration, previous, {"receipt": row.receipt, "delivery_id": row.delivery_id})
	_flush()

func _queue_rebase(declaration: Dictionary, previous: Dictionary, binding: Dictionary) -> void:
	local.hello_pending = previous.get("hello_pending", false) == true # a rebase is not a join
	for key: String in ["hello_wait_from_ms", "hello_wait_told", "adopt_told"]:
		if previous.has(key): local[key] = previous[key]
	local.rebase = {"op": "rebase", "baseline_hash": declaration.baseline_hash,
		"old_stream": previous.id, "old_sequence": previous.sequence, "old_prefix_hash": previous.prefix_hash,
		"old_inputs": previous.inputs.duplicate(true), "discoveries_hash": HASH.fingerprint({"discovered": _discoveries()})}
	local.rebase.merge(binding, true)

func _rebase_host(peer: int, packet: Dictionary) -> void:
	if not HASH._hex(packet.get("stream_id"), 32): return
	var world: RefCounted = _game().get("world")
	var row: Variant = world.reward_deliveries.get(packet.get("delivery_id"))
	var authority: RefCounted = owner().get("_character_authority")
	var character: String = packet.character_id
	if hosts.has(character) and hosts[character].id == packet.stream_id:
		if HASH.fingerprint(hosts[character].cursor.base) == packet.get("baseline_hash"):
			_send_owner(peer, hosts[character], {"op": "rebase_ack"})
		return
	var before: Dictionary = authority.call("state", character)
	var discoveries: Dictionary = authority.call("discovered_landmarks", character)
	if hosts.has(character):
		var previous: Dictionary = hosts[character]
		if previous.id != packet.get("old_stream") or previous.cursor.sequence != packet.get("old_sequence") \
			or previous.cursor.prefix_hash != packet.get("old_prefix_hash"):
			_note_rebase_refused(character, "old stream/sequence/prefix differs (readmit=%s)" % str(previous.has("readmit")))
			return
		discoveries = previous.cursor.discovered.duplicate(true)
		var checkpoint: Dictionary = previous.checkpoint
		if not packet.has("checkpoint_id") and row is Dictionary and checkpoint.get("source_kind") == "portal_arrival" \
			and checkpoint.get("grounded") == true and checkpoint.get("result", {}).get("durable") == true \
			and checkpoint.result.get("receipt") == row.get("receipt") \
			and checkpoint.get("arrival_discoveries") is Dictionary \
			and row.get("action") == "portal_arrival" and PREP.exact(row.get("intent"), {
				"permit_id": checkpoint.request.permit.request_id, "realm": checkpoint.request.permit.realm,
				"entry_id": checkpoint.request.permit.entry_id}):
			discoveries = checkpoint.arrival_discoveries.duplicate(true)
	if HASH.fingerprint({"discovered": discoveries}) != packet.get("discoveries_hash"):
		_note_rebase_refused(character, "discoveries differ")
		return
	if packet.has("checkpoint_id"):
		if not hosts.has(character): return
		var old: Dictionary = hosts[character]
		var checkpoint: Dictionary = old.checkpoint
		if old.id != packet.get("old_stream") or checkpoint.get("id") != packet.checkpoint_id \
			or checkpoint.get("prepared", {}).get("hash") != packet.get("checkpoint_hash") \
			or (checkpoint.get("result", {}).get("code") != "research_no_progress" and checkpoint.get("no_effect") != true) \
			or not PREP.exact(before, checkpoint.prepared.after) or HASH.fingerprint(before) != packet.get("baseline_hash"): return
		hosts.erase(character)
		if _add_host(peer, character, packet.stream_id, before, discoveries):
			_send_owner(peer, hosts[character], {"op": "rebase_ack"})
		return
	if not row is Dictionary or row.get("status") != "accepted" or row.get("receipt") != packet.get("receipt") \
		or row.get("character_id") != character or not row.get("after") is Dictionary \
		or not PREP.exact(RECORD.training_projection(before, row, E.training_projection), row.after) \
		or HASH.fingerprint(before) != packet.get("baseline_hash"):
		_note_rebase_refused(character, "settled row/baseline differs (row=%s, baseline_match=%s)" % [
			str(row.get("status", "none") if row is Dictionary else "none"), str(HASH.fingerprint(before) == packet.get("baseline_hash"))])
		return
	if hosts.has(character):
		var checkpoint: Dictionary = hosts[character].checkpoint
		if checkpoint.has("prepared") and not checkpoint.has("result"): return
		hosts.erase(character)
	if _add_host(peer, character, packet.stream_id, before, discoveries):
		_send_owner(peer, hosts[character], {"op": "rebase_ack"})

## The legacy legendary ceremony changes its roster before sending a saved
## answer. Freeze only that ceremony, retaining the stream and every queued
## input. Its original prefix drains normally while the owner choice is saved.
var stormwood_owner: Dictionary = {}
var stormwood_saving := false
var stormwood_applying := false

func stormwood_begin_owner(claim: Dictionary) -> bool:
	var host: bool = owner().call("is_host") == true
	var uid: String = str(claim.get("creature", {}).get("uid", ""))
	if not stormwood_owner.is_empty(): return stormwood_owner.uid == uid and stormwood_owner.scope == _scope()
	if uid.is_empty() or claim.get("recipient_character_id") != _scope().get("character_id") \
		or (not host and (not delivery_ready() or not local.rebase.is_empty())): return false
	if owner().call("_owner_training_mutation_blocked", _game().get("local")) == true: return false
	var undo := _owner_undo_point()
	if undo.is_empty(): return false
	stormwood_owner = {"uid": uid, "scope": _scope(), "before": _projection(), "undo": undo,
		"host": host, "stream_id": local.get("id", ""), "sequence": local.get("sequence", 0),
		"prefix_hash": local.get("prefix_hash", ""), "saved": false}
	return true

## Only the original offer's controller calls this synchronous roster press.
## Every other owner mutation remains fenced; the existing five-slot cap runs.
func stormwood_apply_ceremony(claim: Dictionary, released_uid: String, newcomer: RefCounted) -> bool:
	if stormwood_owner.is_empty() or stormwood_owner.saved or stormwood_owner.scope != _scope() \
		or not PREP.exact(_projection(), stormwood_owner.before) or newcomer == null \
		or newcomer.get("uid") != stormwood_owner.uid: return false
	var selected := claim.duplicate(true)
	selected.kept = true
	var proposal: Dictionary = load("res://scripts/net/character_authority.gd").call("stormwood_answer_proposal", stormwood_owner.before, selected, released_uid)
	if proposal.get("ok") != true: return false
	var party: RefCounted = _game().get("party")
	stormwood_applying = true
	var removed := released_uid.is_empty()
	if not released_uid.is_empty():
		for index: int in int(party.call("size")):
			if party.call("at", index).get("uid") == released_uid:
				removed = party.call("remove_at", index) != null
				break
	var added: bool = removed and party.call("add", newcomer) == true
	stormwood_applying = false
	return added

## Game's normal pending-catch watcher is fenced during this choice. Restore
## its same Team screen if the panic/settings path closed it mid-ceremony.
func stormwood_restore_menu(menu: Node) -> void:
	var pending_creature: RefCounted = _game().get("pending_catch")
	if stormwood_owner.is_empty() or stormwood_owner.saved or stormwood_owner.scope != _scope() \
		or pending_creature == null or pending_creature.get("uid") != stormwood_owner.uid \
		or menu == null or menu.call("is_open") == true: return
	stormwood_applying = true
	menu.call("open", "creatures")
	stormwood_applying = false

func stormwood_save_owner(claim: Dictionary, released_uid: String) -> Dictionary:
	if stormwood_owner.is_empty() or stormwood_owner.uid != claim.get("creature", {}).get("uid") \
		or stormwood_owner.scope != _scope() or (not stormwood_owner.host and local.get("id") != stormwood_owner.stream_id): return {}
	if stormwood_owner.saved:
		if not PREP.exact(_projection(), stormwood_owner.after): return {}
		return {"host_saved": true} if stormwood_owner.host else stormwood_owner.cut.duplicate(true)
	var producer: Script = load("res://scripts/net/character_authority.gd")
	var proposal: Dictionary = producer.call("stormwood_answer_proposal", stormwood_owner.before, claim, released_uid)
	if proposal.get("ok") != true: return {"terminal": true, "code": proposal.get("code", "invalid_stormwood_claim")}
	var personal: Dictionary = _game().local.redesign_character
	if not stormwood_owner.has("after"):
		# Verify the live ceremony first, then install only its derived payout
		# and receipt arrays. No owner-supplied replacement card is accepted.
		var expected := proposal.state.duplicate(true)
		expected.inventory = stormwood_owner.before.inventory.duplicate(true)
		expected.redesign_character.release_receipts = stormwood_owner.before.redesign_character.release_receipts.duplicate()
		expected.redesign_character.transaction_receipts = stormwood_owner.before.redesign_character.transaction_receipts.duplicate()
		if not PREP.exact(_projection(), expected): return {"terminal": true, "code": "stormwood_owner_changed"}
		var inventory: RefCounted = _game().local.inventory
		inventory.set("_slots", proposal.state.inventory.duplicate(true))
		inventory.set("revision", int(inventory.get("revision")) + 1)
		personal.release_receipts = proposal.state.redesign_character.release_receipts.duplicate()
		personal.transaction_receipts = proposal.state.redesign_character.transaction_receipts.duplicate()
	if not PREP.exact(_projection(), proposal.state): return {"terminal": true, "code": "stormwood_owner_changed"}
	stormwood_owner.after = proposal.state.duplicate(true)
	var saver: RefCounted = _game().get("save_system")
	if saver == null: return {}
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true or stormwood_owner.scope != _scope(): return {}
	stormwood_saving = true
	var saved: bool = saver.call("save_character_prepared", _game(), str(_scope().character_id)) == true
	stormwood_saving = false
	if not saved or stormwood_owner.is_empty() or stormwood_owner.scope != _scope() \
		or not PREP.exact(_projection(), proposal.state): return {}
	stormwood_owner.saved = true
	if stormwood_owner.host:
		stormwood_owner.cut = {}
		return {"host_saved": true}
	stormwood_owner.cut = {"stream_id": local.id, "sequence": stormwood_owner.sequence,
		"prefix_hash": stormwood_owner.prefix_hash, "after_hash": HASH.fingerprint(proposal.state)}
	_flush() # No input is discarded, even if the answer reaches the host first.
	return stormwood_owner.cut.duplicate(true)

func stormwood_host_before(peer: int, cut: Dictionary) -> Dictionary:
	var character: String = owner().call("_authority_character", peer)
	var stream: Dictionary = hosts.get(character, {})
	if cut.size() != 4 or stream.is_empty() or stream.get("peer") != peer or stream.get("departed") == true \
		or stream.has("readmit") or not stream.checkpoint.is_empty() or not str(stream.error).is_empty() \
		or stream.id != cut.get("stream_id") or stream.cursor.sequence != cut.get("sequence") \
		or stream.cursor.prefix_hash != cut.get("prefix_hash") or not HASH._hex(cut.get("after_hash"), 64): return {}
	var authority: RefCounted = owner().get("_character_authority")
	if authority.call("revision", character) != stream.revision \
		or not PREP.exact(authority.call("state", character), stream.cursor.base): return {}
	return stream.cursor.state.duplicate(true)

func stormwood_promote_host(peer: int, cut: Dictionary, after: Dictionary, revision: int) -> bool:
	var character: String = owner().call("_authority_character", peer)
	var stream: Dictionary = hosts.get(character, {})
	if stream.is_empty() or stream.id != cut.get("stream_id") or stream.cursor.sequence != cut.get("sequence") \
		or stream.cursor.prefix_hash != cut.get("prefix_hash") or HASH.fingerprint(after) != cut.get("after_hash"): return false
	# Keep stream identity, sequence, prefix, discoveries and travel cursor. Only
	# this saved original roster decision advances its exact canonical baseline.
	stream.cursor.base = after.duplicate(true)
	stream.cursor.state = after.duplicate(true)
	stream.revision = revision
	return true

func stormwood_finish_owner(cut: Dictionary) -> bool:
	if stormwood_owner.is_empty() or stormwood_owner.get("saved") != true \
		or stormwood_owner.scope != _scope() or not PREP.exact(cut, stormwood_owner.cut) \
		or not PREP.exact(_projection(), stormwood_owner.after): return false
	if not stormwood_owner.host: local.base_hash = cut.after_hash
	stormwood_owner.clear()
	_flush()
	return true

func stormwood_cancel_owner() -> void:
	# Before a saved ACK, a rejected choice can safely restore the original
	# live instances. A saved choice stays on disk and reconciles on reconnect.
	if not stormwood_owner.is_empty() and stormwood_owner.get("saved") != true:
		_owner_undo(stormwood_owner.undo)
	stormwood_owner.clear()
	stormwood_saving = false
	stormwood_applying = false

func reset() -> void:
	stormwood_owner.clear()
	stormwood_saving = false
	stormwood_applying = false
	_pose_ring.clear()
	if owner() != null:
		var authority: RefCounted = owner().get("_character_authority")
		if authority != null:
			for stream: Dictionary in hosts.values():
				if stream.checkpoint.has("prepared"):
					authority.call("cancel_owner_passive_checkpoint", stream.character, stream.checkpoint.prepared.hash)
	local.clear()
	held_readmit.clear()
	hosts.clear()
	refused.clear()
	pending.clear()
	committing.clear()
	saving = false

static func _deny(code: String) -> Dictionary:
	return {"ok": false, "durable": false, "resolved": false, "code": code}

static func _terminal(code: String) -> Dictionary:
	return {"ok": false, "durable": false, "resolved": true, "terminal_refusal": true, "code": code}
