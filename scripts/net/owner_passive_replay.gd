extends RefCounted

## Pure replay of the owner's original care ticks and discovery samples.
## Caller authenticates peer/epoch and supplies host time, realm and geometry.
## No record is imported from a packet; no preparation, save or reward occurs.
const RECORD := preload("res://scripts/net/character_record_rules.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const E := preload("res://scripts/creatures/essence.gd")
const HASH := preload("res://scripts/net/research_passive_preparation.gd")
const REALMS := ["meadows", "water", "cloudreach", "stormwood"]
const PASSIVE_FIELDS := ["nourishment", "happiness", "rested_seconds_left", "rested", "distance_m_together", "landmarks_visited_together"]
const CONDITION_FIELDS := ["version", "sequence", "op", "delta", "uids"]
const DISCOVERY_FIELDS := ["version", "sequence", "op", "realm", "from", "to", "travel_valid", "new_landmarks"]
const CURSOR_FIELDS := ["base", "state", "discovered", "sequence", "elapsed", "discovery_elapsed", "travel_valid", "position", "realm", "prefix_hash"]

class CareCard extends RefCounted:
	var nourishment := 0.0
	var happiness := 0.0
	var rested_seconds_left := 0.0
	var rested := false
	var resting := false

static func begin(record: Dictionary, discovered: Dictionary) -> Dictionary:
	if not _record_valid(record) or not _discoveries_valid(discovered): return {}
	return {"base": record.duplicate(true), "state": record.duplicate(true),
		"discovered": discovered.duplicate(true), "sequence": 0, "elapsed": 0.0,
		"discovery_elapsed": 0.0, "travel_valid": false, "position": [0.0, 0.0, 0.0], "realm": "",
		"prefix_hash": HASH.fingerprint({"base": record, "discovered": discovered})}

static func apply(cursor: Dictionary, packet: Dictionary, context: Dictionary) -> Dictionary:
	if not _cursor_valid(cursor): return _deny("invalid_cursor")
	if not _number(context.get("max_elapsed")) or float(context.max_elapsed) < 0.0 \
		or not _number(context.get("max_speed")) or float(context.max_speed) < 0.0 \
		or context.get("realm") not in REALMS or not context.get("landmarks") is Dictionary:
		return _deny("invalid_context")
	var fields: Array = CONDITION_FIELDS if packet.get("op") == "condition" else DISCOVERY_FIELDS
	if not _fields(packet, fields) or not _integer(packet.get("version")) or packet.version != 1 \
		or packet.get("op") not in ["condition", "discovery"] or not _integer(packet.get("sequence")):
		return _deny("invalid_packet")
	if packet.sequence != int(cursor.sequence) + 1: return _deny("sequence_mismatch")
	if float(cursor.elapsed) > float(context.max_elapsed): return _deny("elapsed_bound")
	var next := cursor.duplicate(true)
	var reason := _condition(next, packet, context) if packet.op == "condition" else _discovery(next, packet, context)
	if not reason.is_empty(): return _deny(reason)
	if not _record_valid(next.state) or not E._equivalent(_core(cursor.state), _core(next.state)):
		return _deny("invalid_result")
	next.sequence = int(packet.sequence)
	next.prefix_hash = HASH.fingerprint({"previous": cursor.prefix_hash, "packet": packet})
	return {"ok": true, "code": "ok", "cursor": next}

static func _condition(next: Dictionary, packet: Dictionary, context: Dictionary) -> String:
	if not _number(packet.delta) or float(packet.delta) < 0.0 or float(packet.delta) > 10.0:
		return "invalid_delta"
	if not packet.uids is Array or packet.uids.size() != next.state.party.size(): return "roster_mismatch"
	for index: int in next.state.party.size():
		if not packet.uids[index] is String or packet.uids[index] != next.state.party[index].uid: return "roster_mismatch"
	var elapsed: float = float(next.elapsed) + float(packet.delta)
	if not is_finite(elapsed) or elapsed > float(context.max_elapsed): return "elapsed_bound"
	var cfg := CONDITION.config()
	for card: Dictionary in next.state.party:
		var care := CareCard.new()
		for field: String in ["nourishment", "happiness", "rested_seconds_left", "rested", "resting"]: care.set(field, card[field])
		# One call per original frame, including threshold-crossing order. Do not
		# sum/rechunk deltas or JSON-round the resulting numeric values.
		CONDITION.tick(care, cfg, float(packet.delta))
		for field: String in ["nourishment", "happiness", "rested_seconds_left", "rested"]: card[field] = care.get(field)
	next.elapsed = elapsed
	next.discovery_elapsed = float(next.discovery_elapsed) + float(packet.delta)
	return ""

static func _discovery(next: Dictionary, packet: Dictionary, context: Dictionary) -> String:
	if packet.realm != context.realm: return "realm_mismatch"
	if not _position(packet.from) or not _position(packet.to) or not packet.travel_valid is bool \
		or not packet.new_landmarks is Array: return "invalid_discovery"
	if float(next.discovery_elapsed) < 0.5: return "discovery_cadence"
	var expected_valid: bool = next.travel_valid and next.realm == context.realm
	# Game drops its travel baseline while an owner mutation fence is active.
	# An authenticated host arrival/placement may explain that same-stream
	# reset, even when its relocation exceeds the active care-tick speed bound.
	# Only the host service supplies this exact, single-use endpoint proof.
	# The owner's input and prefix remain unchanged; a reset earns no distance.
	var reset: bool = expected_valid and packet.travel_valid == false \
		and context.get("travel_reset_authorized") is bool and context.get("travel_reset_authorized") == true \
		and _position(context.get("travel_reset_position")) \
		and E._equivalent(context.travel_reset_position, packet.to)
	if packet.travel_valid != expected_valid and not reset: return "travel_baseline_mismatch"
	if expected_valid and not E._equivalent(packet.from, next.position): return "travel_baseline_mismatch"
	var at := _vector(packet.to)
	var distance := _vector(packet.from).distance_to(at) if expected_valid and not reset else 0.0
	# Only the host service may confirm a discontinuity against the actual
	# same-realm body endpoint. It never creates walking credit, and cannot
	# relax the speed check on an ordinary <=30m discovery step.
	var discontinuity: bool = distance > 30.0 and context.get("discontinuity_authorized") is bool \
		and context.get("discontinuity_authorized") == true
	if not is_finite(distance) or (distance > float(context.max_speed) * float(next.discovery_elapsed) and not discontinuity): return "speed_bound"
	var known: Array = next.discovered.get(packet.realm, [])
	var claimed := {}
	if packet.new_landmarks.size() > 1024: return "invalid_landmark"
	for id: Variant in packet.new_landmarks:
		if not id is String or id.is_empty() or claimed.has(id) or known.has(id) \
			or not context.landmarks.get(id) is Dictionary: return "invalid_landmark"
		var definition: Dictionary = context.landmarks[id]
		var position: Variant = definition.get("position")
		var radius: Variant = definition.get("discover_radius")
		var height: Variant = definition.get("height_tolerance", INF)
		if not position is Vector3 or not position.is_finite() or not _number(radius) or float(radius) < 0.0 \
			or not (height is int or height is float) or is_nan(float(height)) or float(height) < 0.0 \
			or definition.get("manual_discovery", false) != false: return "invalid_landmark"
		if Vector2(position.x - at.x, position.z - at.z).length() > float(radius) \
			or absf(position.y - at.y) > float(height): return "landmark_out_of_range"
		claimed[id] = true
	for card: Dictionary in next.state.party:
		# Same per-poll add and teleport guard as Game/BondMilestones, not a
		# second host polyline or an aggregate add across several discoveries.
		if distance > 0.0 and distance <= 30.0:
			card.distance_m_together = float(card.distance_m_together) + distance
		if not claimed.is_empty(): card.landmarks_visited_together = int(card.landmarks_visited_together) + 1
	for id: String in claimed: known.append(id)
	next.discovered[packet.realm] = known
	if not _discoveries_valid(next.discovered): return "invalid_landmark"
	next.position = packet.to.duplicate()
	next.travel_valid = true
	next.realm = packet.realm
	next.discovery_elapsed = 0.0 # Game drops the discovery throttle remainder.
	return ""

static func _cursor_valid(cursor: Dictionary) -> bool:
	return _fields(cursor, CURSOR_FIELDS) and cursor.base is Dictionary and cursor.state is Dictionary \
		and _record_valid(cursor.base) and _record_valid(cursor.state) \
		and E._equivalent(_core(cursor.base), _core(cursor.state)) and _discoveries_valid(cursor.discovered) \
		and _integer(cursor.sequence) and cursor.sequence >= 0 and cursor.sequence < 2147483647 \
		and _number(cursor.elapsed) and float(cursor.elapsed) >= 0.0 \
		and _number(cursor.discovery_elapsed) and float(cursor.discovery_elapsed) >= 0.0 \
		and float(cursor.discovery_elapsed) <= float(cursor.elapsed) and cursor.travel_valid is bool \
		and _position(cursor.position) and (cursor.realm == "" or cursor.realm in REALMS) \
		and cursor.prefix_hash is String and cursor.prefix_hash.length() == 64 and cursor.prefix_hash.is_valid_hex_number(false)

static func _record_valid(record: Dictionary) -> bool:
	if not RECORD.errors(record, str(record.get("character_id", ""))).is_empty(): return false
	for card: Dictionary in record.party:
		for field: String in ["nourishment", "happiness", "rested_seconds_left", "distance_m_together"]:
			if not _number(card.get(field)) or float(card[field]) < 0.0: return false
		if not card.get("rested") is bool or not card.get("resting") is bool \
			or not _integer(card.get("landmarks_visited_together")) or card.landmarks_visited_together < 0: return false
	return true

static func _discoveries_valid(value: Variant) -> bool:
	if not value is Dictionary or value.size() > REALMS.size(): return false
	var count := 0
	for realm: Variant in value:
		if realm not in REALMS or not value[realm] is Array: return false
		var seen := {}
		for id: Variant in value[realm]:
			if not id is String or id.is_empty() or seen.has(id): return false
			seen[id] = true
			count += 1
	return count <= 1024

static func _core(record: Dictionary) -> Dictionary:
	var result := record.duplicate(true)
	for card: Dictionary in result.party:
		for field: String in PASSIVE_FIELDS: card.erase(field)
	return result

static func _fields(value: Dictionary, fields: Array) -> bool:
	if value.size() != fields.size(): return false
	for field: String in fields:
		if not value.has(field): return false
	return true

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _integer(value: Variant) -> bool:
	return _number(value) and float(value) == floorf(float(value))

static func _position(value: Variant) -> bool:
	return value is Array and value.size() == 3 and _number(value[0]) and _number(value[1]) and _number(value[2]) \
		and _vector(value).is_finite()

static func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))

static func _deny(code: String) -> Dictionary:
	return {"ok": false, "code": code}
