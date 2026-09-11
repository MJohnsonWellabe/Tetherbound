extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/stormwood_earned_waterward_handoff.gd")
const WATER_DIRECTOR := preload("res://scripts/combat/water_encounter_director.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")

class QuietSegment extends SEGMENT:
	func _fail(message: String) -> bool:
		failures.append(message)
		return false

func test_unchanged_five_requires_exact_distinct_identities() -> void:
	assert_true(SEGMENT.same_five([1, 2, 3, 4, 5], [1, 2, 3, 4, 5]))
	assert_false(SEGMENT.same_five([1, 2, 3, 4, 5], [1, 2, 3, 4, 6]))
	assert_false(SEGMENT.same_five([1, 2, 3, 4, 5], [2, 1, 3, 4, 5]))
	assert_false(SEGMENT.same_five([1, 2, 3, 4], [1, 2, 3, 4]))
	assert_false(SEGMENT.same_five([1, 1, 3, 4, 5], [1, 1, 3, 4, 5]))
	assert_false(SEGMENT.same_five([0, 2, 3, 4, 5], [0, 2, 3, 4, 5]))

func test_water_readiness_is_an_observed_signal_not_a_boolean_property() -> void:
	var director := WATER_DIRECTOR.new()
	assert_true(director.has_signal("population_ready"))
	assert_eq(typeof(director.get("population_ready")), TYPE_SIGNAL)
	var segment := SEGMENT.new()
	assert_false(segment._water_population_seen)
	director.population_ready.connect(segment._water_population_ready)
	director.population_ready.emit()
	assert_true(segment._water_population_seen)
	director.free()

func test_real_creature_instance_ids_preserve_the_five() -> void:
	var creatures: Array[RefCounted] = []
	var ids: Array[int] = []
	for index in 5:
		var creature: RefCounted = SPECIES.spawn("bramblebun")
		creatures.append(creature)
		ids.append(creature.get_instance_id())
	assert_true(SEGMENT.same_five(ids, ids.duplicate()), "RefCounted IDs may be signed negative values")
	var changed := ids.duplicate()
	changed[0] = 0
	assert_false(SEGMENT.same_five(changed, changed))
	changed[0] = changed[1]
	assert_false(SEGMENT.same_five(changed, changed))
	assert_false(SEGMENT.same_five(ids, changed))

func test_gate_observer_counts_only_the_exact_provider() -> void:
	var segment := SEGMENT.new()
	var actual := Node.new()
	var other := Node.new()
	segment._gate_prompt_id = actual.get_instance_id()
	segment._watch_gate_activation(other)
	assert_eq(segment._gate_activations, 0)
	segment._watch_gate_activation(actual)
	assert_eq(segment._gate_activations, 1)
	actual.free()
	other.free()

func test_missing_earned_world_cannot_claim_water_arrival() -> void:
	var segment := QuietSegment.new()
	var outcome: Dictionary = await segment.run(null, null, null)
	assert_false(outcome.passed)
	assert_eq(outcome.world, null)
	assert_eq(outcome.failures.size(), 1)

func test_handoff_preserves_production_ceremony_key_and_scene_contracts() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/stormwood_earned_waterward_handoff.gd")
	for bypass in ["global_position =", "face_towards", "enter_realm(", "try_enter(",
		"try_unlock(", "emit_event(", "pending_catch\",", "set_flag(", "save_world(", "party.add("]:
		assert_false(source.contains(bypass), bypass)
	for check in ["stormwood_stormheart_release", "stormwood_stormheart_offer", "_release_target\")) != 5",
		"_farewell_keep", "_farewell_release", "realm_heart_stormwood_earned",
		"stormwood_waterward_aftermath", "for press in 2", "not _has(WATER_UNLOCK) or _has(WATER_KEY)",
		"water_arrival_from_stormwood", "_water_population_seen", "arrived.get_node_or_null(\"EncounterDirector\") == _water_director"]:
		assert_true(source.contains(check), check)

func test_descent_reverses_tested_mouth_inside_one_existing_whole_route_budget() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/stormwood_earned_waterward_handoff.gd")
	var descent := source.substr(source.find("func _walk_actual_descent"))
	assert_true(descent.contains("Vector3(-4, 6, -26), Vector3(0, 6, -40)"))
	assert_true(descent.contains("Engine.get_physics_frames() - started < ASCENT_FRAMES"))
	assert_true(descent.contains("0.8 if lower_index == 0"))
	assert_false(descent.contains("await _fight_current"))
	assert_eq(SEGMENT.ASCENT_FRAMES, 6000)
	assert_eq(SEGMENT.ASCENT_HZ, 60)
	assert_eq(SEGMENT.ASCENT_SCALE, 4.0)
