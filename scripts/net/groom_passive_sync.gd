extends RefCounted
const BACKGROUND_TRACE := preload("res://scripts/net/background_work_trace.gd")

## Groom's preparation uses the existing admitted record and character file.
## This transient observer carries no inventory, HP, reward or receipt ledger.
const E := preload("res://scripts/creatures/essence.gd")
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const FIELDS := ["nourishment", "happiness", "rested_seconds_left", "rested", "distance_m_together", "landmarks_visited_together"]
const COUNTERS := ["distance_m_together", "landmarks_visited_together"]
const REALMS := ["meadows", "water", "cloudreach", "stormwood"]
const MAX_OBSERVATION_GAP_MS := 2000
const MAX_ELAPSED := 86400.0
const MAX_DISCOVERIES := 1024
const MAX_CHARACTERS := 4
var _session: WeakRef
var observations: Dictionary = {}
var preparations: Dictionary = {}
var pending: Dictionary = {}
var installing := false
var _poll_left := 0.0
var committing: Dictionary = {}

class ConditionCard extends RefCounted:
	var nourishment := 0.0
	var happiness := 0.0
	var rested_seconds_left := 0.0
	var rested := false
	var resting := false

func _init(session: Node = null) -> void:
	if session != null: _session = weakref(session)

func owner() -> Node:
	return _session.get_ref() as Node if _session != null else null

static func fingerprint(record: Dictionary) -> String:
	# Canonical JSON survives decoded integral floats and Dictionary key order.
	return JSON.stringify(_canonical(record)).sha256_text()

static func _canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var next := {}
		var keys: Array = value.keys()
		keys.sort()
		for key: Variant in keys: next[key] = _canonical(value[key])
		return next
	if value is Array:
		var next: Array = []
		for item: Variant in value: next.append(_canonical(item))
		return next
	if value is float and is_finite(value) and value == floorf(value): return int(value)
	return value

static func unchanged_core(record: Dictionary) -> Dictionary:
	var core := record.duplicate(true)
	for card: Dictionary in core.get("party", []):
		for field: String in FIELDS: card.erase(field)
	return core

## Only host-observed elapsed time and movement feed this pure derivation.
## No client duration, position, quantity or replacement card is accepted.
static func derive(before: Dictionary, elapsed: float, distance: float, landmarks: int) -> Dictionary:
	if not RECORD.errors(before, str(before.get("character_id", ""))).is_empty() \
		or not is_finite(elapsed) or elapsed < 0.0 or elapsed > MAX_ELAPSED \
		or not is_finite(distance) or distance < 0.0 or distance > MAX_ELAPSED * 40.0 \
		or landmarks < 0 or landmarks > MAX_DISCOVERIES: return {}
	var after := before.duplicate(true)
	for index: int in after.party.size():
		var card: Dictionary = after.party[index]
		var condition := ConditionCard.new()
		for field: String in ["nourishment", "happiness", "rested_seconds_left", "rested", "resting"]: condition.set(field, card[field])
		# Match hunger-threshold order at bounded host observation steps.
		var left := elapsed
		while left > 0.0:
			var step := minf(left, 0.5)
			CONDITION.tick(condition, CONDITION.config(), step)
			left -= step
		for field: String in ["nourishment", "happiness", "rested_seconds_left", "rested"]: card[field] = condition.get(field)
		card.distance_m_together = float(card.distance_m_together) + distance
		card.landmarks_visited_together = int(card.landmarks_visited_together) + landmarks
		# CharacterSave and the world journal use this JSON number encoding.
		# Freeze NEW passive outputs in that durable representation before the
		# hash/CAS. Unchanged history and every immutable/HP field stay verbatim.
		for field: String in ["nourishment", "happiness", "rested_seconds_left", "distance_m_together"]:
			if E._equivalent(card[field], before.party[index][field]): continue
			if not is_finite(float(card[field])): return {}
			var encoded: Variant = JSON.parse_string(JSON.stringify([card[field]]))
			if not encoded is Array or encoded.size() != 1 or not (encoded[0] is float or encoded[0] is int): return {}
			card[field] = float(encoded[0])
	return after if RECORD.errors(after, str(after.character_id)).is_empty() else {}

static func owner_plan(current: Dictionary, prepared: Dictionary) -> Dictionary:
	if not valid(prepared) or not RECORD.errors(current, str(prepared.get("character_id", ""))).is_empty() \
		or not E._equivalent(unchanged_core(current), unchanged_core(prepared.after)):
		return {"ok": false, "code": "groom_baseline_conflict"}
	# A host that did not observe an earned movement/landmark cannot erase it.
	for index: int in current.party.size():
		for field: String in COUNTERS:
			if float(current.party[index][field]) > float(prepared.after.party[index][field]):
				return {"ok": false, "code": "groom_unobserved_progress"}
	return {"ok": true, "state": prepared.after.duplicate(true)}

static func valid(prepared: Dictionary) -> bool:
	var fields := ["character_id", "world_namespace", "session_epoch", "intent", "source_key", "revision", "before", "after", "elapsed", "distance", "landmarks", "discoveries", "preparation_id", "hash"]
	if prepared.size() != fields.size(): return false
	for field: String in fields:
		if not prepared.has(field): return false
	for field: String in ["character_id", "world_namespace", "session_epoch", "source_key"]:
		if not E._opaque_id(prepared[field]): return false
	if not prepared.intent is Dictionary or prepared.intent.size() != 2 \
		or not E._component(prepared.intent.get("creature_uid")) or not _action_id(prepared.intent.get("action_id")) \
		or not E._integer(prepared.revision, 0, 2147483645) or not E._integer(prepared.landmarks, 0, 1024) \
		or not prepared.before is Dictionary or not prepared.after is Dictionary \
		or not (prepared.elapsed is float or prepared.elapsed is int) \
		or not (prepared.distance is float or prepared.distance is int) or not _action_id(prepared.preparation_id) \
		or not discovery_shape(prepared.discoveries): return false
	var discovery_count := 0
	for ids: Array in prepared.discoveries.values(): discovery_count += ids.size()
	if prepared.landmarks > discovery_count: return false
	var derived := derive(prepared.before, float(prepared.elapsed), float(prepared.distance), int(prepared.landmarks))
	return not derived.is_empty() and prepared.character_id == derived.character_id \
		and E._equivalent(derived, prepared.after) and prepared.hash == preparation_hash(prepared)

static func preparation_hash(prepared: Dictionary) -> String:
	var bound := prepared.duplicate(true)
	bound.erase("hash")
	return fingerprint(bound)

static func discovery_shape(raw: Variant) -> bool:
	if not raw is Dictionary or raw.size() > REALMS.size(): return false
	var total := 0
	for realm: Variant in raw:
		if realm not in REALMS or not raw[realm] is Array: return false
		var seen := {}
		for id: Variant in raw[realm]:
			if not E._component(id) or seen.has(id): return false
			seen[id] = true
			total += 1
	return total <= MAX_DISCOVERIES

static func _action_id(value: Variant) -> bool:
	return value is String and value.length() == 32 and value.is_valid_hex_number(false) and value.to_lower() == value

func _scope() -> Dictionary:
	var session := owner()
	var game: Node = session.call("_game") if session != null else null
	if game == null or game.get("local") == null or game.get("world") == null: return {}
	return {"character_id": game.get("local").character_id, "world_namespace": game.get("world").reward_delivery_namespace,
		"session_epoch": session.call("_altar_current_epoch")}

func blocked(player: RefCounted) -> bool:
	var session := owner()
	return not pending.is_empty() and session != null and session.call("_game") != null and player == session.call("_game").get("local") \
		and pending.scope == _scope()

func snapshot_allowed(player: RefCounted, payload: Dictionary) -> bool:
	return blocked(player) and installing and pending.get("prepared") is Dictionary \
		and E._equivalent(RECORD.portable_projection(payload), pending.prepared.after) \
		and E._equivalent(payload.get("realm_maps"), pending.get("maps"))

func admission_landmarks() -> Dictionary:
	var session := owner()
	var player: RefCounted = session.call("_game").get("local")
	var result := {}
	for realm: String in REALMS:
		var map: RefCounted = player.call("map_for", realm)
		if map != null: result[realm] = map.call("save_data").get("landmarks", []).duplicate()
	return result

## Owner, on a rejoin readmit (owner_passive_sync `_readmit_owner`): the
## host's held landmark set wins inside its world, so the owner's maps take it
## exactly; a landmark the owner discovered but the host never replayed is
## simply discovered again by walking. Refuses an unknown realm or landmark.
func adopt_landmarks(discovered: Dictionary) -> bool:
	if not admission_valid(discovered): return false
	var player: RefCounted = owner().call("_game").get("local")
	for realm: String in REALMS:
		var map: RefCounted = player.call("map_for", realm)
		if map == null: continue
		var data: Dictionary = map.call("save_data")
		data["landmarks"] = (discovered.get(realm, []) as Array).duplicate()
		map.call("load_data", data)
	return true

func admission_valid(raw: Variant, complete: bool = false) -> bool:
	if not discovery_shape(raw): return false
	if complete and raw.size() != REALMS.size(): return false
	var player: RefCounted = owner().call("_game").get("local")
	for realm: String in raw:
		var map: RefCounted = player.call("map_for", realm)
		if map == null: return false
		var definitions: Dictionary = map.get("_landmark_defs")
		for id: String in raw[realm]:
			if not definitions.has(id): return false
	return true

func admitted(character: String, seen: Dictionary) -> void:
	if observations.has(character):
		observations[character].last_ms = 0
		return
	_prune_departed()
	if observations.size() >= MAX_CHARACTERS: return
	var known := {}
	for realm: String in REALMS:
		var ids: Variant = seen.get(realm, [])
		if not ids is Array or ids.size() > 1024: continue
		for id: Variant in ids:
			if E._component(id): known[realm + ":" + id] = true
	observations[character] = {"revision": -1, "elapsed": 0.0, "distance": 0.0,
		"landmarks": 0, "committed": known, "visits": {}, "last_ms": 0, "body": 0, "realm": "", "position": Vector3.ZERO}

func departed(character: String) -> void:
	if observations.has(character): observations[character].last_ms = 0
	# Same host retains its exact reservation for the stable character. No
	# disconnected time is observed, and rejoin cannot rebase this preparation.

func reset() -> void:
	var session := owner()
	if session != null:
		for character: String in preparations:
			session.get("_character_authority").call("cancel_groom_preparation", character, preparations[character].hash)
	observations.clear()
	preparations.clear()
	pending.clear()
	installing = false

func observe(character: String, revision: int, now_ms: int, body: int, realm: String,
		position: Vector3, landmark_defs: Dictionary, paused: bool, authority_state: Dictionary = {}) -> void:
	if not observations.has(character): admitted(character, {})
	if not observations.has(character): return
	var sample: Dictionary = observations[character]
	if paused or not position.is_finite():
		sample.last_ms = 0
		return
	if sample.revision != revision:
		sample.revision = revision
		# Unrelated revisions preserve pending visits. A feed, rest or roster
		# change requires an ordered flush, not replaying old time onto a new UID.
		var timing := []
		for card: Dictionary in authority_state.get("party", []):
			var relevant := {"uid": card.uid, "resting": card.resting}
			for field: String in FIELDS: relevant[field] = card[field]
			timing.append(relevant)
		if sample.has("timing") and not E._equivalent(sample.timing, timing) \
			and (sample.elapsed > 0.0 or sample.distance > 0.0 or not sample.visits.is_empty()): sample.chronology_conflict = true
		sample.timing = timing
	var gap := now_ms - int(sample.last_ms)
	if sample.last_ms > 0 and gap > 0 and gap <= MAX_OBSERVATION_GAP_MS \
		and sample.body == body and sample.realm == realm:
		sample.elapsed += float(gap) / 1000.0
		var distance: float = sample.position.distance_to(position)
		# Same 30 m discontinuity exclusion as ordinary discovery, additionally
		# bounded by observed time so a teleport never becomes walking credit.
		if distance <= minf(30.0, float(gap) * 0.04): sample.distance += distance
	var visited := false
	for id: String in landmark_defs:
		var definition: Dictionary = landmark_defs[id]
		var key := realm + ":" + id
		if sample.committed.has(key) or sample.visits.has(key) or definition.get("manual_discovery", false) == true: continue
		var at: Vector3 = definition.get("position", Vector3.ZERO)
		if Vector2(at.x - position.x, at.z - position.z).length() <= float(definition.get("discover_radius", 0.0)) \
			and absf(at.y - position.y) <= float(definition.get("height_tolerance", INF)):
			sample.visits[key] = true
			visited = true
	if visited: sample.landmarks += 1 # Game credits one visit per discovery tick.
	sample.last_ms = now_ms
	sample.body = body
	sample.realm = realm
	sample.position = position

func tick(delta: float) -> void:
	var session := owner()
	if session == null: return
	if not pending.is_empty() and pending.scope != _scope(): pending.clear()
	_poll_left -= delta
	if _poll_left > 0.0: return
	_poll_left = 0.25
	var trace := BACKGROUND_TRACE.begin("groom.poll")
	if session.call("is_host") == true:
		var prune_trace := BACKGROUND_TRACE.begin("groom.prune_departed")
		_prune_departed()
		BACKGROUND_TRACE.end("groom.prune_departed", prune_trace)
		var sample_trace := BACKGROUND_TRACE.begin("groom.sample_host")
		_sample_host()
		BACKGROUND_TRACE.end("groom.sample_host", sample_trace)
	elif not pending.is_empty() and session.call("snapshot_ready") == true:
		var retry_trace := BACKGROUND_TRACE.begin("groom.retry_owner")
		_retry_owner()
		BACKGROUND_TRACE.end("groom.retry_owner", retry_trace)
	BACKGROUND_TRACE.end("groom.poll", trace)

func _prune_departed() -> void:
	var session := owner()
	if session == null or session.call("is_host") != true: return
	var registry: RefCounted = session.call("registry")
	if registry == null: return
	for character: String in observations.keys():
		if registry.call("peer_for_character", character) != 0 or registry.call("has_reservation", character) == true: continue
		# Seat expiry explicitly cancels only an unawarded reservation. Any
		# saved Groom decision remains in the existing durable world journal.
		if preparations.has(character):
			session.get("_character_authority").call("cancel_groom_preparation", character, preparations[character].hash)
			preparations.erase(character)
		observations.erase(character)

func _sample_host() -> void:
	var session := owner()
	if not session.is_inside_tree(): return
	var lifecycle := session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
	var registry: RefCounted = session.call("registry")
	if lifecycle == null or registry == null: return
	var authority: RefCounted = session.get("_character_authority")
	for row: Dictionary in registry.call("rows"):
		var peer := int(row.peer_id)
		if peer == session.call("local_peer_id"): continue
		var character: String = session.call("_authority_character", peer)
		var actor: CharacterBody3D = lifecycle.call("remote_body", peer)
		var realm := str(row.get("realm", ""))
		var shell: Node3D = session.call("_portal_world_node", realm)
		if character.is_empty() or actor == null or shell == null or not shell.is_ancestor_of(actor) \
			or not actor.is_physics_processing() or actor.is_queued_for_deletion():
			if observations.has(character): observations[character].last_ms = 0
			continue
		var map: RefCounted = session.call("_game").get("local").call("map_for", realm)
		var definitions := landmark_definitions(map, realm, session.call("_foundation_flags", peer),
			session.call("_game").get("world").flags.call("all_set"))
		observe(character, int(authority.call("revision", character)), Time.get_ticks_msec(), actor.get_instance_id(), realm,
			actor.global_position, definitions, preparations.has(character) or authority.call("creature_training_is_pending", character) == true,
			authority.call("state", character))

## Read authored geometry, never the host player's discovered/unlocked view.
static func landmark_definitions(map: RefCounted, realm: String, personal: Dictionary, world_flags: Array) -> Dictionary:
	var result := {}
	if map == null: return result
	if realm in ["cloudreach", "stormwood"]:
		for row: Dictionary in map.get("_world_data").get("landmarks", []):
			var required: Array = [str(row.get("requires_unlock", ""))]
			if realm == "cloudreach" and row.id == "waterward_overlook": required = ["captain_veyra_defeated", "cloudreach_winds_restored", "stormward_route_revealed"]
			var allowed := true
			for flag: String in required:
				if not flag.is_empty() and personal.get(flag) != true and not world_flags.has(flag): allowed = false
			if not allowed: continue
			var at: Array = row.position
			result[row.id] = {"position": Vector3(at[0], at[1], at[2]), "discover_radius": map.get("_discovery_radius"), "height_tolerance": map.get("_height_tolerance")}
	else:
		for id: String in map.get("_landmark_defs"):
			var row: Dictionary = map.get("_landmark_defs")[id]
			var at: Vector2 = row.position
			result[id] = {"position": Vector3(at.x, 0, at.y), "discover_radius": row.get("discover_radius", 0.0), "manual_discovery": row.get("manual_discovery", false)}
	return result

func host_prepare(peer: int, envelope: Dictionary) -> Dictionary:
	var session := owner()
	var character: String = session.call("_authority_character", peer)
	var existing := _saved_original(character, envelope.intent)
	if not existing.is_empty(): return session.call("_foundation_decision", peer, existing)
	if preparations.has(character):
		var retained: Dictionary = preparations[character]
		if not E._equivalent(retained.intent, envelope.intent) or retained.source_key != envelope.station_key: return _deny("groom_preparation_busy", false)
		return {"ok": true, "resolved": false, "code": "groom_baseline_prepared", "prepared": retained.duplicate(true)}
	if preparations.size() >= MAX_CHARACTERS: return _deny("groom_preparation_busy", false)
	var context: Dictionary = session.call("_foundation_groom_context", peer, envelope.station_key)
	if context.is_empty() or envelope.intent.size() != 2 or not _action_id(envelope.intent.get("action_id")) \
		or not E._component(envelope.intent.get("creature_uid")): return _deny("groom_source_unavailable", true)
	_sample_host()
	if not observations.has(character) or observations[character].last_ms <= 0: return _deny("groom_observation_pending", false)
	if observations[character].get("chronology_conflict") == true: return _deny("groom_passive_chronology_changed", true)
	var authority: RefCounted = session.get("_character_authority")
	var before: Dictionary = authority.call("state", character)
	var selected := false
	for card: Dictionary in before.party:
		if card.uid == envelope.intent.creature_uid: selected = true
	if not selected: return _deny("not_owned", true)
	var sample: Dictionary = observations[character]
	var discoveries := {}
	for key: String in sample.visits:
		var parts := key.split(":", true, 1)
		if not discoveries.has(parts[0]): discoveries[parts[0]] = []
		discoveries[parts[0]].append(parts[1])
	var prepared := {"character_id": character, "world_namespace": envelope.world_namespace,
		"session_epoch": envelope.session_epoch, "source_key": envelope.station_key, "intent": envelope.intent.duplicate(true),
		"revision": int(authority.call("revision", character)), "before": before,
		"after": derive(before, sample.elapsed, sample.distance, sample.landmarks),
		"elapsed": sample.elapsed, "distance": sample.distance, "landmarks": sample.landmarks,
		"discoveries": discoveries, "preparation_id": Crypto.new().generate_random_bytes(16).hex_encode()}
	prepared.hash = preparation_hash(prepared)
	if not valid(prepared) or authority.call("reserve_groom_preparation", character, prepared) != true:
		return _deny("groom_preparation_busy", false)
	preparations[character] = prepared.duplicate(true)
	sample.last_ms = 0
	return {"ok": true, "resolved": false, "code": "groom_baseline_prepared", "prepared": prepared}

func allows_fence(peer: int, key: String) -> bool:
	var character: String = owner().call("_authority_character", peer)
	return preparations.get(character, {}).get("source_key") == key

func host_resume(peer: int, envelope: Dictionary) -> Dictionary:
	if not envelope.intent.is_empty() or envelope.revision != -1: return _deny("invalid_groom_resume", true)
	var character: String = owner().call("_authority_character", peer)
	if preparations.has(character):
		return {"ok": true, "resolved": false, "code": "groom_baseline_prepared", "prepared": preparations[character].duplicate(true)}
	return {"ok": false, "resolved": false, "code": "groom_no_preparation"}

func host_cancel(peer: int, envelope: Dictionary) -> Dictionary:
	var session := owner()
	var character: String = session.call("_authority_character", peer)
	var intent: Dictionary = envelope.intent
	if intent.size() != 4: return _deny("invalid_groom_ack", true)
	var original := {"creature_uid": intent.get("creature_uid"), "action_id": intent.get("action_id")}
	var saved := _saved_original(character, original)
	if not saved.is_empty(): return session.call("_foundation_decision", peer, saved)
	var prepared: Dictionary = preparations.get(character, {})
	if prepared.is_empty() or not E._equivalent(prepared.intent, original) or envelope.station_key != prepared.source_key \
		or intent.get("hash") != prepared.hash or intent.get("preparation_id") != prepared.preparation_id \
		or envelope.revision != int(prepared.revision) + 1: return _deny("groom_preparation_changed", true)
	session.get("_character_authority").call("cancel_groom_preparation", character, prepared.hash)
	preparations.erase(character)
	if observations.has(character): observations[character].last_ms = 0
	return _deny("groom_baseline_conflict", true)

func host_commit(peer: int, envelope: Dictionary) -> Dictionary:
	var session := owner()
	var character: String = session.call("_authority_character", peer)
	var intent: Dictionary = envelope.intent
	if intent.size() != 4: return _deny("invalid_groom_ack", true)
	var original := {"creature_uid": intent.get("creature_uid"), "action_id": intent.get("action_id")}
	var saved := _saved_original(character, original)
	if not saved.is_empty(): return session.call("_foundation_decision", peer, saved)
	var prepared: Dictionary = preparations.get(character, {})
	if prepared.is_empty() or not E._equivalent(prepared.intent, original) or envelope.station_key != prepared.source_key \
		or prepared.hash != intent.get("hash") or prepared.preparation_id != intent.get("preparation_id") \
		or envelope.revision != int(prepared.revision) + 1 or envelope.world_namespace != prepared.world_namespace \
		or envelope.session_epoch != prepared.session_epoch: return _deny("groom_preparation_changed", true)
	var authority: RefCounted = session.get("_character_authority")
	if authority.call("commit_groom_preparation", character, prepared) != true: return _deny("groom_baseline_changed", false)
	# One synchronous entry into the existing world journal. This capability is
	# never put in a packet; a raw remote Groom action cannot use the bypass.
	var action := envelope.duplicate(true)
	action.op = "groom"
	action.intent = prepared.intent.duplicate(true)
	committing = action.duplicate(true)
	var result: Dictionary = session.call("_foundation_handle", peer, action)
	committing.clear()
	if result.get("terminal_refusal") == true or not _saved_original(character, original).is_empty():
		preparations.erase(character)
		observations.erase(character)
		admitted(character, authority.call("discovered_landmarks", character))
	else:
		authority.call("retain_groom_preparation", character, prepared)
	return result

func begin(original: Dictionary, key: String) -> Dictionary:
	var session := owner()
	if not pending.is_empty():
		if not E._equivalent(pending.get("intent"), original): return _deny("groom_preparation_busy", false)
		_retry_owner()
		return _deny("awaiting_saved_decision", false)
	var lifecycle := session.get_node_or_null(^"FoundationComposition/TravelLifecycle")
	# Publish the actual free state before acquiring the original's fence.
	if lifecycle == null or lifecycle.call("publish_now") != true: return _deny("groom_source_unavailable", false)
	pending = {"scope": _scope(), "intent": original.duplicate(true), "source_key": key, "phase": "prepare"}
	_feedback("preparing", "Saving your creature's care state…")
	_retry_owner()
	return _deny("awaiting_saved_decision", false)

func begin_resume() -> void:
	if not pending.is_empty(): return
	pending = {"scope": _scope(), "intent": {}, "source_key": "homestead_recovery", "phase": "resume"}

func pending_original(original: Dictionary) -> bool:
	return not pending.is_empty() and pending.scope == _scope() and E._equivalent(pending.intent, original)

func receive(envelope: Dictionary, result: Dictionary) -> void:
	if pending.is_empty() or pending.scope != _scope(): return
	if envelope.op == "groom_resume" and result.get("code") == "groom_no_preparation":
		pending.clear()
		return
	if result.get("code") == "groom_baseline_prepared":
		var prepared: Variant = result.get("prepared")
		if not prepared is Dictionary or not valid(prepared) or not admission_valid(prepared.discoveries) \
			or prepared.character_id != pending.scope.character_id or prepared.world_namespace != pending.scope.world_namespace \
			or prepared.session_epoch != pending.scope.session_epoch: return
		if pending.phase != "resume" and (not E._equivalent(pending.intent, prepared.intent) or pending.source_key != prepared.source_key): return
		if pending.has("prepared") and not E._equivalent(pending.prepared, prepared): return
		pending.intent = prepared.intent.duplicate(true)
		pending.source_key = prepared.source_key
		pending.prepared = prepared.duplicate(true)
		pending.phase = "save"
		_retry_owner()
		return
	if result.get("terminal_refusal") == true or result.get("ok") == true and result.get("resolved") == true:
		var original: Dictionary = pending.intent.duplicate(true)
		pending.clear()
		owner().emit_signal("homestead_action_completed", "groom", original, result)
	elif envelope.op == "groom_commit":
		owner().emit_signal("homestead_action_completed", "groom", pending.intent.duplicate(true), result)

func _retry_owner() -> void:
	var session := owner()
	if pending.is_empty() or session.call("snapshot_ready") != true: return
	if pending.phase == "save":
		var saved := save_owner_baseline()
		if saved.get("ok") != true:
			if saved.get("code") in ["groom_baseline_conflict", "groom_unobserved_progress"]:
				pending.phase = "cancel"
			_feedback(str(saved.get("code", "")), "Groom is waiting for your character to save. Retrying the same care action…")
			# Keep the exact original and fence. No failed BOOL write becomes an ACK.
			session.emit_signal("homestead_action_completed", "groom", pending.intent.duplicate(true), saved)
			if pending.phase != "cancel": return
		else: pending.phase = "commit"
	if pending.phase in ["commit", "cancel"]:
		var intent: Dictionary = pending.intent.duplicate(true)
		intent.hash = pending.prepared.hash
		intent.preparation_id = pending.prepared.preparation_id
		session.call("_foundation_send", "groom_cancel" if pending.phase == "cancel" else "groom_commit", pending.source_key, intent, int(pending.prepared.revision) + 1)
	else:
		session.call("_foundation_send", "groom_resume" if pending.phase == "resume" else "groom_prepare", pending.source_key, pending.intent, -1)

func _feedback(code: String, message: String) -> void:
	if pending.is_empty() or pending.get("feedback") == code: return
	pending.feedback = code
	var game: Node = owner().call("_game")
	if game != null and game.has_method("push_world_message"): game.call("push_world_message", message)

func save_owner_baseline() -> Dictionary:
	var session := owner()
	var game: Node = session.call("_game")
	if pending.is_empty() or pending.scope != _scope() or not pending.has("prepared"): return _deny("groom_preparation_changed", false)
	var player: RefCounted = game.get("local")
	var saver: RefCounted = game.get("save_system")
	if saver == null or not saver.has_method("save_character_prepared"): return _deny("prepared_owner_writer_missing", false)
	saver.call("finish_fallback")
	if saver.call("fallback_busy") == true: return _deny("fallback_busy", false)
	var current := RECORD.portable_projection(player.call("save_data"))
	var plan := owner_plan(current, pending.prepared)
	if plan.get("ok") != true: return _deny(str(plan.code), false)
	var members: Array = player.get("party").call("members")
	if members.size() != current.party.size(): return _deny("groom_baseline_conflict", false)
	for index: int in members.size():
		if members[index].get("uid") != current.party[index].uid: return _deny("groom_baseline_conflict", false)
	var old_maps := {}
	for realm: String in pending.prepared.discoveries:
		var map: RefCounted = player.call("map_for", realm)
		old_maps[realm] = map.call("save_data").duplicate(true)
		for id: String in pending.prepared.discoveries[realm]: map.call("discover_landmark", id)
		var discovered: Array = map.call("save_data").get("landmarks", [])
		for id: String in pending.prepared.discoveries[realm]:
			if not discovered.has(id):
				for prior_realm: String in old_maps: player.call("map_for", prior_realm).call("load_data", old_maps[prior_realm])
				return _deny("groom_landmark_view_pending", false)
	for index: int in members.size():
		for field: String in FIELDS: members[index].set(field, plan.state.party[index][field])
	if not E._equivalent(RECORD.portable_projection(player.call("save_data")), plan.state): return _deny("groom_baseline_install_failed", false)
	pending.maps = player.call("save_data").get("realm_maps", {}).duplicate(true)
	installing = true
	var saved: bool = saver.call("save_character_prepared", game, str(player.character_id)) == true
	installing = false
	if not saved: return _deny("groom_baseline_save_failed", false)
	if pending.scope != _scope(): return _deny("groom_preparation_changed", false)
	return {"ok": true, "saved": true}

func _saved_original(character: String, intent: Dictionary) -> Dictionary:
	var session := owner()
	var world: RefCounted = session.call("_game").get("world")
	var row: Dictionary = world.reward_deliveries.get(E.training_delivery_id(world.reward_delivery_namespace, character), {})
	return row if row.get("action") == "groom" and E._equivalent(row.get("intent"), intent) else {}

static func _deny(code: String, terminal: bool) -> Dictionary:
	return {"ok": false, "resolved": terminal, "durable": false, "terminal_refusal": terminal, "code": code}
