extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/water_earned_opening_segment.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

func test_retained_five_accepts_actual_creature_instance_ids() -> void:
	var creatures: Array[RefCounted] = []
	var ids: Array[int] = []
	for _index in 5:
		var creature := CREATURE.new()
		creatures.append(creature)
		ids.append(creature.get_instance_id())
	assert_true(SEGMENT.retained_five(ids, ids))
	var swapped := ids.duplicate()
	swapped[0] = ids[1]
	assert_false(SEGMENT.retained_five(ids, swapped))
	assert_false(SEGMENT.retained_five(swapped, swapped))
	assert_false(SEGMENT.retained_five([0, 1, 2, 3, 4], [0, 1, 2, 3, 4]))
	assert_false(SEGMENT.retained_five([1, 2], [1, 2]))

func test_swim_stick_preserves_world_direction_for_current_camera_without_pose_write() -> void:
	for yaw in [0.0, PI / 4, PI / 2, PI, -PI / 3]:
		var basis := Basis(Vector3.UP, yaw)
		for offset in [Vector3(4, 7, 2), Vector3(-3, -8, 5), Vector3(0, 0, -6)]:
			var axis := SEGMENT.swim_axis(basis, offset)
			var actual := basis * Vector3(axis.x, 0, axis.y)
			var expected := Vector3(offset.x, 0, offset.z).normalized()
			assert_almost_eq(actual.distance_to(expected), 0.0, 0.00001)
			assert_almost_eq(axis.length(), 1.0, 0.00001)

func test_missing_natural_arrival_is_not_a_fixture_fallback() -> void:
	var segment := SEGMENT.new()
	var outcome: Dictionary = await segment.run(null, null, null)
	assert_false(outcome.ok)
	assert_false(outcome.completed_lesson)
	assert_eq(outcome.failures.size(), 1)
	assert_eq(outcome.endpoint, "earned Pell and physical swim lesson, before Reedhaven")

func test_extraction_retains_original_input_distance_and_evidence_limits() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/water_earned_opening_segment.gd")
	var original := FileAccess.get_file_as_string("res://tests/smoke_water_opening_continuous.gd")
	for bound in ["for stance in 8", "for line in 30", "for frame in 2400", "swim_metres < 50.0",
		"offset.length() < 0.5", "int(distance * 65)", "await _frames(8)",
		"player.is_on_floor() or player.swim_controller.is_swimming()"]:
		assert_true(source.contains(bound), bound)
		assert_true(original.contains(bound), "original " + bound)
	assert_eq(SEGMENT.LESSON_MS, 600000)
	assert_true(source.contains("anchor_age >= NAV.CONFINED_FRAMES"))
	assert_true(source.contains("Time.get_ticks_msec() < _deadline_ms"))
	for bypass in ["reset_for_new_game", "SAVE.new", "WORLD.instantiate", "global_position =",
		"camera.set(", "party.add(", "inventory.add(", "set_level(", "assign_hotbar(", "enter_realm("]:
		assert_false(source.contains(bypass), bypass)

func test_water_key_and_gate_receipts_have_production_world_scope() -> void:
	var scopes: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/progression/flag_scopes.json"))
	assert_true((scopes.world.ids as Array).has("realm_key_water"))
	assert_true((scopes.world.ids as Array).has("realm_gate_water_unlocked"))
	assert_true((scopes.world.prefixes as Array).has("stormwood:"))
