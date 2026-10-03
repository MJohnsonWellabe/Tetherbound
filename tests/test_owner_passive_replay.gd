extends "res://tests/test_case.gd"

## Pure replay against disclosed admitted-record and host-geometry fixtures.
## No actual transport, save, movement authentication or research proof claim.
const REPLAY := preload("res://scripts/net/owner_passive_replay.gd")
const FIXTURE := preload("res://tests/test_den_groom_saved_transaction.gd")
const CONDITION := preload("res://scripts/creatures/creature_condition.gd")
const E := preload("res://scripts/creatures/essence.gd")

func _context() -> Dictionary:
	return {"max_elapsed": 100.0, "max_speed": 40.0, "realm": "meadows", "landmarks": {
		"near": {"position": Vector3(3, 0, 0), "discover_radius": 1.0},
		"also_near": {"position": Vector3(3, 0, 0), "discover_radius": 1.0},
		"far": {"position": Vector3(90, 0, 0), "discover_radius": 1.0},
		"manual": {"position": Vector3.ZERO, "discover_radius": 10.0, "manual_discovery": true},
		"high": {"position": Vector3(3, 50, 0), "discover_radius": 1.0, "height_tolerance": 1.0}}}

func _condition(cursor: Dictionary, delta: float) -> Dictionary:
	var uids: Array = []
	for card: Dictionary in cursor.state.party: uids.append(card.uid)
	return {"version": 1, "sequence": int(cursor.sequence) + 1, "op": "condition", "delta": delta, "uids": uids}

func _discovery(cursor: Dictionary, at: Array, ids: Array = []) -> Dictionary:
	return {"version": 1, "sequence": int(cursor.sequence) + 1, "op": "discovery", "realm": "meadows",
		"from": cursor.position.duplicate(), "to": at.duplicate(), "travel_valid": cursor.travel_valid,
		"new_landmarks": ids.duplicate()}

func _advance(cursor: Dictionary, packet: Dictionary, context: Dictionary = {}) -> Dictionary:
	var result := REPLAY.apply(cursor, packet, _context() if context.is_empty() else context)
	assert_true(result.ok, str(result))
	return result.get("cursor", cursor)

func _denied(cursor: Dictionary, packet: Dictionary, code: String, context: Dictionary = {}) -> void:
	var before := var_to_bytes(cursor)
	var input := var_to_bytes(packet)
	var result := REPLAY.apply(cursor, packet, _context() if context.is_empty() else context)
	assert_false(result.ok)
	assert_eq(result.code, code)
	assert_false(result.has("cursor"), "refusal cannot provide a promoted candidate")
	assert_eq(var_to_bytes(cursor), before, "invalid input cannot mutate caller cursor")
	assert_eq(var_to_bytes(packet), input, "input packet remains immutable")

func test_exact_original_condition_steps_cross_threshold_and_preserve_full_core() -> void:
	var before: Dictionary = FIXTURE.new()._before()
	before.party[0].nourishment = 30.003
	before.party[0].happiness = 61.23456789012345
	before.party[0].rested = true
	before.party[0].rested_seconds_left = 0.15
	var cursor := REPLAY.begin(before, {})
	assert_false(cursor.is_empty())
	var care := REPLAY.CareCard.new()
	for field: String in ["nourishment", "happiness", "rested_seconds_left", "rested", "resting"]: care.set(field, before.party[0][field])
	var expected := before.duplicate(true)
	for delta: float in [0.1, 0.1, 0.016666666666666666, 0.03333333333333333, 0.0]:
		CONDITION.tick(care, CONDITION.config(), delta)
		cursor = _advance(cursor, _condition(cursor, delta))
		for field: String in ["nourishment", "happiness", "rested_seconds_left", "rested"]: expected.party[0][field] = care.get(field)
		assert_eq(var_to_bytes(cursor.state), var_to_bytes(expected), "exact shipping per-frame arithmetic")
	assert_false(cursor.state.party[0].rested)
	assert_true(cursor.state.party[0].nourishment < 30.0)
	assert_true(E._equivalent(REPLAY._core(cursor.state), REPLAY._core(before)))
	assert_eq(var_to_bytes(cursor.base), var_to_bytes(before))
	var single := REPLAY.begin(before, {})
	single = _advance(single, _condition(single, cursor.elapsed))
	assert_ne(cursor.state.party[0].happiness, single.state.party[0].happiness, "threshold order requires original ticks")
	assert_ne(cursor.prefix_hash, single.prefix_hash, "prefix binds exact inputs, not just elapsed")

func test_discovery_uses_original_polyline_and_one_credit_per_poll() -> void:
	var before: Dictionary = FIXTURE.new()._before()
	before.party[0].distance_m_together = 0.0
	before.party[0].landmarks_visited_together = 0
	var cursor := REPLAY.begin(before, {"meadows": ["already"]})
	cursor = _advance(cursor, _condition(cursor, 0.51))
	cursor = _advance(cursor, _discovery(cursor, [0.0, 0.0, 0.0]))
	assert_eq(cursor.discovery_elapsed, 0.0, "same throttle remainder reset as Game")
	cursor = _advance(cursor, _condition(cursor, 0.5))
	cursor = _advance(cursor, _discovery(cursor, [3.0, 0.0, 0.0], ["near", "also_near"]))
	cursor = _advance(cursor, _condition(cursor, 0.5))
	cursor = _advance(cursor, _discovery(cursor, [3.0, 0.0, 4.0]))
	assert_eq(cursor.state.party[0].distance_m_together, 7.0, "both actual steps retained, not host endpoint chord")
	assert_eq(cursor.state.party[0].landmarks_visited_together, 1, "two new IDs in one poll earn one bond visit")
	assert_eq(cursor.discovered.meadows, ["already", "near", "also_near"])
	cursor = _advance(cursor, _condition(cursor, 1.0))
	cursor = _advance(cursor, _discovery(cursor, [34.0, 0.0, 4.0]))
	assert_eq(cursor.state.party[0].distance_m_together, 7.0, "original over-30m teleport guard")
	assert_true(E._equivalent(REPLAY._core(cursor.state), REPLAY._core(before)))

func test_rejects_bad_sequence_roster_time_and_replacement_without_mutation() -> void:
	var cursor := REPLAY.begin(FIXTURE.new()._before(), {})
	var packet := _condition(cursor, 0.1)
	packet.sequence = 0
	_denied(cursor, packet, "sequence_mismatch")
	packet.sequence = 2
	_denied(cursor, packet, "sequence_mismatch")
	packet.sequence = 1
	packet.uids = ["foreign-creature"]
	_denied(cursor, packet, "roster_mismatch")
	for delta: float in [-0.1, NAN, INF, 10.01]:
		_denied(cursor, _condition(cursor, delta), "invalid_delta")
	var context := _context()
	context.max_elapsed = 0.05
	_denied(cursor, _condition(cursor, 0.1), "elapsed_bound", context)
	packet = _condition(cursor, 0.1)
	packet.after = cursor.state.duplicate(true)
	_denied(cursor, packet, "invalid_packet")
	packet = _condition(cursor, 0.1)
	packet.uids = []
	_denied(cursor, packet, "roster_mismatch")
	packet = _condition(cursor, 0.1)
	cursor = _advance(cursor, packet)
	_denied(cursor, packet, "sequence_mismatch")
	packet = _condition(cursor, 0.1)
	packet.version = true
	_denied(cursor, packet, "invalid_packet")
	packet = _condition(cursor, 0.1)
	packet.delta = "0.1"
	_denied(cursor, packet, "invalid_delta")
	context = _context()
	context.max_elapsed = NAN
	_denied(cursor, _condition(cursor, 0.1), "invalid_context", context)
	var changed := cursor.duplicate(true)
	changed.state.party[0].hp = 0.0
	_denied(changed, _condition(changed, 0.1), "invalid_cursor")

func test_complete_roster_order_is_required_and_all_existing_cards_tick() -> void:
	var player: RefCounted = FIXTURE.new()._player()
	assert_true(player.party.add(preload("res://scripts/creatures/creature_species.gd").spawn("terrapup")))
	var before: Dictionary = preload("res://scripts/net/character_record_rules.gd").portable_projection(player.save_data())
	var cursor := REPLAY.begin(before, {})
	assert_false(cursor.is_empty())
	var packet := _condition(cursor, 0.5)
	packet.uids.reverse()
	_denied(cursor, packet, "roster_mismatch")
	packet = _condition(cursor, 0.5)
	packet.uids[1] = packet.uids[0]
	_denied(cursor, packet, "roster_mismatch")
	cursor = _advance(cursor, _condition(cursor, 0.5))
	for index: int in before.party.size():
		assert_true(cursor.state.party[index].nourishment < before.party[index].nourishment)
		assert_true(E._equivalent(REPLAY._core(cursor.state), REPLAY._core(before)))

func test_discovery_refuses_bad_cadence_speed_realm_geometry_and_replayed_ids() -> void:
	var cursor := REPLAY.begin(FIXTURE.new()._before(), {})
	_denied(cursor, _discovery(cursor, [0, 0, 0]), "discovery_cadence")
	cursor = _advance(cursor, _condition(cursor, 0.5))
	cursor = _advance(cursor, _discovery(cursor, [0, 0, 0]))
	cursor = _advance(cursor, _condition(cursor, 0.5))
	_denied(cursor, _discovery(cursor, [21, 0, 0]), "speed_bound")
	var packet := _discovery(cursor, [3, 0, 0])
	packet.realm = "water"
	_denied(cursor, packet, "realm_mismatch")
	packet = _discovery(cursor, [3, 0, 0])
	packet.from = [1, 0, 0]
	_denied(cursor, packet, "travel_baseline_mismatch")
	packet = _discovery(cursor, [3, 0, 0])
	packet.travel_valid = false
	_denied(cursor, packet, "travel_baseline_mismatch")
	_denied(cursor, _discovery(cursor, [NAN, 0, 0]), "invalid_discovery")
	_denied(cursor, _discovery(cursor, [3, 0, 0], ["unknown"]), "invalid_landmark")
	_denied(cursor, _discovery(cursor, [3, 0, 0], ["near", "near"]), "invalid_landmark")
	_denied(cursor, _discovery(cursor, [3, 0, 0], ["manual"]), "invalid_landmark")
	_denied(cursor, _discovery(cursor, [3, 0, 0], ["far"]), "landmark_out_of_range")
	_denied(cursor, _discovery(cursor, [3, 0, 0], ["high"]), "landmark_out_of_range")
	cursor = _advance(cursor, _discovery(cursor, [3, 0, 0], ["near"]))
	cursor = _advance(cursor, _condition(cursor, 0.5))
	_denied(cursor, _discovery(cursor, [3, 0, 0], ["near"]), "invalid_landmark")

func test_clone_isolation_and_trusted_realm_transition_start_new_travel_baseline() -> void:
	var before: Dictionary = FIXTURE.new()._before()
	var maps := {"meadows": ["existing"]}
	var cursor := REPLAY.begin(before, maps)
	var initial := var_to_bytes(cursor)
	before.party[0].happiness = 0.0
	maps.meadows.append("later")
	assert_eq(var_to_bytes(cursor), initial)
	var packet := _condition(cursor, 0.5)
	var next := _advance(cursor, packet)
	assert_eq(var_to_bytes(cursor), initial, "successful apply also leaves original untouched")
	packet.uids.clear()
	assert_eq(next.state.party.size(), 1)
	next = _advance(next, _discovery(next, [0, 0, 0]))
	next = _advance(next, _condition(next, 0.5))
	var context := _context()
	context.realm = "water"
	context.landmarks = {}
	packet = _discovery(next, [200, 10, 100])
	packet.realm = "water"
	packet.travel_valid = false
	var distance: float = next.state.party[0].distance_m_together
	next = _advance(next, packet, context)
	assert_eq(next.state.party[0].distance_m_together, distance, "realm entry cannot manufacture travel")
	assert_eq(next.realm, "water")
	next.state.party[0].happiness = 0.0
	assert_ne(cursor.state.party[0].happiness, next.state.party[0].happiness)
	assert_true(REPLAY.begin({}, {}).is_empty())
	var invalid: Dictionary = FIXTURE.new()._before()
	invalid.party[0].nourishment = NAN
	assert_true(REPLAY.begin(invalid, {}).is_empty())

func test_only_trusted_long_discontinuity_bypasses_speed_without_walking_credit() -> void:
	var cursor := REPLAY.begin(FIXTURE.new()._before(), {})
	cursor = _advance(cursor, _condition(cursor, 0.5))
	cursor = _advance(cursor, _discovery(cursor, [0, 0, 0]))
	cursor = _advance(cursor, _condition(cursor, 0.5))
	var packet := _discovery(cursor, [90, 0, 0], ["far"])
	_denied(cursor, packet, "speed_bound")
	var context := _context()
	for flag: Variant in [false, 1, "true", null]:
		context.discontinuity_authorized = flag
		_denied(cursor, packet, "speed_bound", context)
	packet.discontinuity_authorized = true
	_denied(cursor, packet, "invalid_packet")
	packet.erase("discontinuity_authorized")
	context.discontinuity_authorized = true
	_denied(cursor, _discovery(cursor, [21, 0, 0]), "speed_bound", context)
	var distance: float = cursor.state.party[0].distance_m_together
	var visits: int = cursor.state.party[0].landmarks_visited_together
	var accepted := _advance(cursor, packet, context)
	assert_eq(accepted.state.party[0].distance_m_together, distance, "confirmed teleport earns no walking credit")
	assert_eq(accepted.state.party[0].landmarks_visited_together, visits + 1, "actual destination still uses host landmark geometry")
	assert_eq(accepted.discovered.meadows, ["far"])
	packet.new_landmarks = ["near"]
	_denied(cursor, packet, "landmark_out_of_range", context)
