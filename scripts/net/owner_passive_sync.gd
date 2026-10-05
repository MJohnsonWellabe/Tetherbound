extends RefCounted

## Exact owner-input replay before an ORIGINAL retained research duty. This
## never installs a host candidate into the owner or replaces an immutable row.
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const PREP := preload("res://scripts/net/owner_passive_preparation.gd")
const HASH := preload("res://scripts/net/research_passive_preparation.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const E := preload("res://scripts/creatures/essence.gd")
const EVENT := preload("res://scripts/net/foundation_event.gd")
const GROOM := preload("res://scripts/net/groom_passive_sync.gd")
const RESEARCH := preload("res://scripts/creatures/research_actions.gd")
const CLOUD_MAP := preload("res://scripts/world/cloudreach_map_state.gd")
const DATA := preload("res://scripts/data/redesign_data.gd")
const REQUEST_KINDS := ["foundation_request", "altar_spend", "manual_refine", "altar_traits", "portal_arrival"]
const REQUEST_ACTIONS := ["station_craft", "feast_cook", "feast_feed", "relic_hang", "master_chest"]
const RETAINED_ACTIONS := ["research_event", "master_win", "boss_relic", "combat_mastery", "combat_round_reward"]
const MAX_BUFFER := 120000
const MAX_BATCH := 64
const MAX_PEERS := 4
const MAX_SPEED := 40.0
## The recorder starts before the existing connection+snapshot handshake.
## This bounded initial allowance does not replace or extend those deadlines.
const ADMISSION_ALLOWANCE_S := 80.0
const INITIAL_POSE_LAG_S := 2.0
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
## Host: a rejoined stream refused for a real conflict, by character, so the
## reason is re-sent to that owner rather than left as silence.
var refused: Dictionary = {}
var pending: Dictionary = {}
var committing: Dictionary = {}
var saving := false
var _left := 0.0
var _reported_error := ""
var _reported_ignore := ""

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

func _discoveries() -> Dictionary:
	return owner().call("_groom_service").call("admission_landmarks")

func _projection() -> Dictionary:
	return RECORD.portable_projection(_game().get("local").call("save_data"))

func arm_owner(before: Dictionary, discoveries: Dictionary) -> Dictionary:
	var cursor := REPLAY.begin(before, discoveries)
	if cursor.is_empty(): return {}
	local = {"id": Crypto.new().generate_random_bytes(16).hex_encode(), "character": before.character_id,
		"base_hash": HASH.fingerprint(before), "sequence": 0, "prefix_hash": cursor.prefix_hash,
		"inputs": [], "acked": 0, "error": "", "last_settlement": "", "rebase": {}, "admission_pending": true}
	pending.clear()
	var game := _game()
	if game != null:
		game.set("_travel_pos_valid", false)
		game.set("_discovery_elapsed", 0.0)
	return {"id": local.id, "baseline_hash": local.base_hash}

func record_input(input: Dictionary) -> void:
	if local.is_empty() or not pending.is_empty() or not str(local.error).is_empty(): return
	if local.inputs.size() >= MAX_BUFFER:
		local.error = "owner_passive_buffer_full"
		return # Never discard an unacknowledged transition.
	var packet := input.duplicate(true)
	packet.version = 1
	packet.sequence = int(local.sequence) + 1
	local.sequence = packet.sequence
	local.prefix_hash = HASH.fingerprint({"previous": local.prefix_hash, "packet": packet})
	local.inputs.append(packet)

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

func recording_active() -> bool:
	return not local.is_empty() and pending.is_empty() and str(local.error).is_empty()

func _scope() -> Dictionary:
	var game := _game()
	if game == null or game.get("world") == null or game.get("local") == null or owner() == null: return {}
	return {"character_id": game.get("local").character_id, "world_id": game.get("world").world_id,
		"world_namespace": game.get("world").reward_delivery_namespace,
		"session_epoch": owner().call("_altar_current_epoch")}

func _send_host(message: Dictionary, stream_id: String = "") -> void:
	if local.is_empty() or owner() == null or owner().call("snapshot_ready") != true: return
	var packet := _scope()
	packet.merge(message, true)
	packet.stream_id = local.id if stream_id.is_empty() else stream_id
	owner().call("_owner_passive_send_host", packet)

func _send_owner(peer: int, stream: Dictionary, message: Dictionary) -> void:
	var packet := {"character_id": stream.character, "world_id": stream.world_id,
		"world_namespace": stream.world_namespace, "session_epoch": stream.epoch, "stream_id": stream.id}
	packet.merge(message, true)
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
	if E._equivalent(before, declared) and HASH.fingerprint(before) == declaration.get("baseline_hash"):
		_add_host(peer, character, str(declaration.id), before, discoveries)
		return
	# Rejoin: the owner kept ticking care/travel drift the host never
	# acknowledged, so the declaration differs from the host's recovered
	# authority. Re-admit against that authority when the difference is ONLY
	# in the passive fields owner-passive replay itself governs
	# (owner_passive_replay.gd `_core`); the owner adopts the host's values
	# (`readmit`). Any other difference is a real conflict: refuse it with a
	# reason the owner receives, never silently.
	var core_matches: bool = declared is Dictionary and HASH.fingerprint(declared) == declaration.get("baseline_hash") \
		and E._equivalent(REPLAY._core(before), REPLAY._core(declared))
	if not core_matches:
		var reason := "owner_passive_admission_conflict: %s" % ", ".join(_differing_paths("", before, declared, 0, []).slice(0, 8))
		refused[character] = {"id": str(declaration.id), "reason": reason, "peer": peer}
		push_warning("[owner-passive] refused rejoined stream for %s: %s" % [character.left(18), reason])
		_send_refusal(peer, character)
		return
	if not _add_host(peer, character, str(declaration.id), before, discoveries): return
	hosts[character].readmit = {"op": "readmit", "baseline": before.duplicate(true),
		"baseline_hash": HASH.fingerprint(before), "discoveries_hash": HASH.fingerprint({"discovered": discoveries})}
	print("[owner-passive] re-admitting %s on the host's recovered authority (passive drift only)" % character.left(18))
	_send_owner(peer, hosts[character], hosts[character].readmit)


## Host, on a transport leaving: its streams end with it. A portal-departed
## stream stays for `_recovery_admitted`; anything else would shadow the
## owner's next stream forever (re-proof: rejoin left admission pending).
func peer_departed(peer: int) -> void:
	for character: String in hosts.keys():
		var stream: Dictionary = hosts[character]
		if int(stream.get("peer", 0)) == peer and stream.get("departed") != true:
			_drop_host(character)
	for character: String in refused.keys():
		if int(refused[character].get("peer", 0)) == peer: refused.erase(character)


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
	if packet.get("op") == "rebase":
		_rebase_host(peer, packet)
		return
	if not hosts.has(character):
		if refused.get(character, {}).get("id") == packet.get("stream_id"): _send_refusal(peer, character)
		return
	var stream: Dictionary = hosts[character]
	if stream.get("departed") == true:
		stream = stream.get("recovery", {})
		if stream.is_empty(): return
	if stream.has("readmit") and stream.peer == peer and stream.id == packet.get("stream_id"):
		if packet.get("op") == "readmitted" and packet.get("baseline_hash") == stream.readmit.baseline_hash:
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
	var registry: RefCounted = session.call("registry")
	var realm := ""
	for row: Dictionary in registry.call("rows"):
		if row.get("peer_id") == peer: realm = str(row.get("realm", ""))
	var map: RefCounted = _game().get("local").call("map_for", realm)
	var definitions := GROOM.landmark_definitions(map, realm, session.call("_foundation_flags", peer),
		_game().get("world").flags.call("all_set"))
	var context := {"realm": realm, "landmarks": definitions, "max_speed": MAX_SPEED,
		"max_elapsed": ADMISSION_ALLOWANCE_S + float(Time.get_ticks_msec() - int(stream.started_ms)) / 1000.0}
	var lifecycle := session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
	var actor: CharacterBody3D = lifecycle.call("remote_body", peer) if lifecycle != null else null
	var shell: Node3D = session.call("_portal_world_node", realm)
	if actor != null and shell != null and shell.is_ancestor_of(actor):
		context.initial_position = actor.global_position
		context.initial_max_distance = MAX_SPEED * INITIAL_POSE_LAG_S
	return context

## A host-accepted physical placement explains one same-stream false travel
## baseline. Peer inputs cannot create this capability or choose its anchor.
func travel_reset_confirmed(peer: int, realm: String, anchor: Vector3) -> void:
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
		"anchor": [anchor.x, anchor.y, anchor.z], "sequence": stream.cursor.sequence}

func _reset_matches(peer: int, stream: Dictionary, input: Dictionary, context: Dictionary) -> bool:
	var proof: Dictionary = stream.get("travel_reset", {})
	if proof.is_empty() or input.get("op") != "discovery" or input.get("travel_valid") != false \
		or stream.cursor.travel_valid != true or proof.peer != peer or proof.stream_id != stream.id \
		or proof.epoch != stream.epoch or proof.realm != context.realm or input.get("realm") != proof.realm \
		or int(input.sequence) <= int(proof.sequence) or not E._equivalent(input.get("from"), stream.cursor.position) \
		or not E._equivalent(input.get("to"), proof.anchor) or not REPLAY._position(input.get("to")) \
		or not context.get("initial_position") is Vector3: return false
	var at := Vector3(float(input.to[0]), float(input.to[1]), float(input.to[2]))
	# Reuse the existing live-body discontinuity endpoint tolerance.
	return _endpoint_matches(context.initial_position, at)

static func _endpoint_matches(host_body: Vector3, endpoint: Vector3) -> bool:
	var flat := Vector2(host_body.x - endpoint.x, host_body.z - endpoint.z)
	return flat.length() <= ENDPOINT_HORIZONTAL_M and absf(host_body.y - endpoint.y) <= ENDPOINT_VERTICAL_M

func _inputs_host(peer: int, stream: Dictionary, packet: Dictionary) -> void:
	if not str(stream.error).is_empty() or not packet.get("inputs") is Array \
		or packet.inputs.is_empty() or packet.inputs.size() > MAX_BATCH: return
	var context := _context(peer, stream)
	for input: Variant in packet.inputs:
		if not input is Dictionary or not input.get("sequence") is int:
			stream.error = "owner_passive_invalid_input"; return
		var sequence: int = input.sequence
		var digest := HASH.fingerprint(input)
		if sequence <= int(stream.cursor.sequence):
			if stream.seen.get(sequence) != digest: stream.error = "owner_passive_conflicting_duplicate"
			if not str(stream.error).is_empty(): return
			continue
		if stream.seen.size() >= MAX_BUFFER:
			stream.error = "owner_passive_host_buffer_full"; return
		if input.get("op") == "discovery" and (stream.cursor.travel_valid != true or stream.cursor.realm != context.realm):
			var at: Variant = input.get("to")
			if not context.get("initial_position") is Vector3:
				_note_host(stream, "input %d waits: no host body for this owner in %s" % [sequence, str(context.realm)])
				return # Realm body has not arrived; retry this exact prefix.
			if not REPLAY._position(at) \
				or context.initial_position.distance_to(Vector3(float(at[0]), float(at[1]), float(at[2]))) > float(context.initial_max_distance):
				stream.first_input_refusal = {"input": input.duplicate(true), "context": context.duplicate(true),
					"cursor_sequence": stream.cursor.sequence, "sampled_ms": Time.get_ticks_msec()}
				stream.error = "owner_passive_initial_pose_unconfirmed"; return
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
					return
				input_context.discontinuity_authorized = true
		var applied: Dictionary
		if input.get("op") in ["actor_vitals_applied", "actor_vitals_saved"]:
			if not owner().has_method("_owner_passive_actor_vitals_context"): return
			var proof: Dictionary = owner().call("_owner_passive_actor_vitals_context", peer, input)
			if proof.is_empty():
				_note_host(stream, "input %d waits: %s has no host vitals proof yet" % [sequence, str(input.op)])
				return # Exact saved op waits the existing authenticated world ACK.
			if input.op == "actor_vitals_applied" and proof.get("revision_before") != stream.revision:
				stream.error = "owner_passive_vitals_revision_conflict"; return
			if input.op == "actor_vitals_saved" and int(proof.row.character_revision) > int(stream.revision):
				stream.error = "owner_passive_vitals_saved_before_applied"; return
			applied = REPLAY.apply_vitals(stream.cursor, input, proof)
		elif input.get("op") == "reward_delivery_applied":
			var row: Variant = _game().get("world").reward_deliveries.get(input.get("delivery_id"))
			applied = REPLAY.apply_delivery(stream.cursor, input, row)
			if applied.get("ok") == true and owner().get("_character_authority").call("apply_owner_reward_delivery",
				stream.character, stream.cursor.base, applied.cursor.base) != true:
				stream.error = "owner_passive_delivery_authority_changed"; return
			if applied.get("ok") == true and row is Dictionary:
				# Ruling (b): a batched gather is now credited; its row may be
				# pruned once the guest's ACK has also landed.
				var gather_writer: Node = owner().get_node_or_null(^"LedgerRpc")
				if gather_writer != null: gather_writer.call("mark_gather_replayed", stream.character, row)
		else:
			applied = REPLAY.apply(stream.cursor, input, input_context)
		if applied.get("ok") != true:
			stream.first_input_refusal = {"input": input.duplicate(true), "context": input_context.duplicate(true),
				"cursor_sequence": stream.cursor.sequence, "sampled_ms": Time.get_ticks_msec()}
			stream.error = str(applied.get("code", "owner_passive_replay_refused")); return
		stream.cursor = applied.cursor
		if input.get("op") == "actor_vitals_applied": stream.revision = applied.revision
		stream.seen[sequence] = digest
		if reset: stream.erase("travel_reset") # Only successful exact replay consumes it.
	_send_owner(peer, stream, {"op": "inputs_ack", "sequence": stream.cursor.sequence})
	if stream.checkpoint.get("recovery") == true and not stream.checkpoint.has("frozen"):
		_recovery_freeze(peer, stream)
	if not stream.checkpoint.is_empty() and stream.checkpoint.has("frozen"):
		_prepare_host(peer, stream)

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
	_send_owner(peer, stream, {"op": op, "id": checkpoint.id, "hash": checkpoint.prepared.hash, "result": checkpoint.result})

func receive_owner(packet: Dictionary) -> void:
	if local.is_empty():
		_note_ignored("%s before this owner armed a stream" % str(packet.get("op", "")))
		return
	var scope := _scope()
	for field: String in scope:
		if packet.get(field) != scope[field]:
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
			local.rebase = {}
			local.admission_pending = false
		"readmit":
			_readmit_owner(packet)
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
			local.admission_pending = false
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
			pending.prepared = prepared.duplicate(true)
			pending.retained = retained.duplicate(true)
			pending.phase = "save"
			_retry_owner()
		"journaled":
			if not pending.is_empty() and pending.id == packet.get("id"):
				pending.phase = "journaled" # Existing original owner-row settlement releases the fence.
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
	return not pending.is_empty() and _game() != null and player == _game().get("local") and pending.scope == _scope()

func snapshot_allowed(player: RefCounted, payload: Dictionary) -> bool:
	return saving and blocked(player) and pending.has("prepared") \
		and PREP.exact(RECORD.portable_projection(payload), pending.prepared.after)

func _retry_owner() -> void:
	if pending.is_empty() or pending.scope != _scope() or not str(local.error).is_empty(): return
	_flush()
	if pending.phase == "frozen":
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
	if pending.phase == "saved":
		_send_host({"op": "saved", "id": pending.id, "hash": pending.prepared.hash, "saved": true})

## Owner: the host re-admitted this stream on its recovered authority (see
## `admitted`). Adopt the host's passive values, which are the only fields that
## may differ, and restart this stream's cursor on that baseline. Inputs
## recorded on the old base since joining are dropped with it.
func _readmit_owner(packet: Dictionary) -> void:
	var baseline: Variant = packet.get("baseline")
	if not baseline is Dictionary or HASH.fingerprint(baseline) != packet.get("baseline_hash"): return
	if local.get("readmitted_hash") == packet.baseline_hash:
		_send_host({"op": "readmitted", "baseline_hash": packet.baseline_hash})
		return
	var game := _game()
	if not pending.is_empty() or game == null \
		or HASH.fingerprint({"discovered": _discoveries()}) != packet.get("discoveries_hash") \
		or not E._equivalent(REPLAY._core(baseline), REPLAY._core(_projection())):
		_note_ignored("readmit whose core no longer matches this owner")
		return
	var members: Dictionary = {}
	for member: RefCounted in game.get("party").call("members"): members[str(member.get("uid"))] = member
	for card: Dictionary in baseline.party:
		var member: RefCounted = members.get(str(card.get("uid", "")))
		if member == null: return
		for field: String in REPLAY.PASSIVE_FIELDS:
			if card.has(field) and field in member: member.set(field, card[field])
	if not E._equivalent(_projection(), baseline):
		local.admission_refused = "owner_passive_readmit_mismatch"
		local.error = local.admission_refused
		push_warning("owner passive readmit did not reproduce the host's baseline")
		return
	var cursor := REPLAY.begin(baseline, _discoveries())
	if cursor.is_empty(): return
	local.base_hash = packet.baseline_hash
	local.sequence = 0
	local.prefix_hash = cursor.prefix_hash
	local.inputs = []
	local.acked = 0
	local.vitals_seen = {}
	local.readmitted_hash = packet.baseline_hash
	# A cursor restarted on a new base restarts the travel/discovery clocks,
	# exactly as arm_owner does; a discovery input timed on the old clock fails
	# the host's replay as discovery_cadence (re-proof run 2026-10-04T22:09:55Z).
	game.set("_travel_pos_valid", false)
	game.set("_discovery_elapsed", 0.0)
	_send_host({"op": "readmitted", "baseline_hash": packet.baseline_hash})


func _flush() -> void:
	if local.is_empty() or not str(local.error).is_empty(): return
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
	_send_host({"op": "inputs", "inputs": local.inputs.slice(0, mini(MAX_BATCH, local.inputs.size())).duplicate(true)})

## Diagnostic only, once per character and reason: a host checkpoint that
## silently waits leaves the fight's round reward held with no other trace.
var _host_notes: Dictionary = {}

func _note_host(stream: Dictionary, reason: String) -> void:
	var character := str(stream.get("character", ""))
	if _host_notes.get(character) == reason:
		return
	_host_notes[character] = reason
	print("[owner-passive] host %s: %s (t=%dms)" % [character.left(18), reason, Time.get_ticks_msec()])

## Diagnostic only, once per distinct reason: a packet this owner drops is
## otherwise invisible, and the host simply resends it forever.
func _note_ignored(reason: String) -> void:
	if reason == _reported_ignore:
		return
	_reported_ignore = reason
	print("[owner-passive] ignored " + reason)

func tick(delta: float) -> void:
	_left -= delta
	if _left > 0.0: return
	_left = 0.25
	if owner() == null or owner().call("is_host") == true: return
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
	var declaration := arm_owner(_projection(), _discoveries())
	if declaration.is_empty(): return
	local.last_settlement = row.receipt
	_queue_rebase(declaration, previous, {"receipt": row.receipt, "delivery_id": row.delivery_id})
	_flush()

func _queue_rebase(declaration: Dictionary, previous: Dictionary, binding: Dictionary) -> void:
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
			or previous.cursor.prefix_hash != packet.get("old_prefix_hash"): return
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
	if HASH.fingerprint({"discovered": discoveries}) != packet.get("discoveries_hash"): return
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
		or HASH.fingerprint(before) != packet.get("baseline_hash"): return
	if hosts.has(character):
		var checkpoint: Dictionary = hosts[character].checkpoint
		if checkpoint.has("prepared") and not checkpoint.has("result"): return
		hosts.erase(character)
	if _add_host(peer, character, packet.stream_id, before, discoveries):
		_send_owner(peer, hosts[character], {"op": "rebase_ack"})

func reset() -> void:
	if owner() != null:
		var authority: RefCounted = owner().get("_character_authority")
		if authority != null:
			for stream: Dictionary in hosts.values():
				if stream.checkpoint.has("prepared"):
					authority.call("cancel_owner_passive_checkpoint", stream.character, stream.checkpoint.prepared.hash)
	local.clear()
	hosts.clear()
	refused.clear()
	pending.clear()
	committing.clear()
	saving = false

static func _deny(code: String) -> Dictionary:
	return {"ok": false, "durable": false, "resolved": false, "code": code}

static func _terminal(code: String) -> Dictionary:
	return {"ok": false, "durable": false, "resolved": true, "terminal_refusal": true, "code": code}
