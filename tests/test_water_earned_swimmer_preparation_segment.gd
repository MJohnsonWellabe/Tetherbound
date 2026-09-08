extends "res://tests/test_case.gd"
const SEGMENT := preload("res://tests/helpers/water_earned_swimmer_preparation_segment.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

func _creature(species: String, level: int) -> RefCounted:
	var creature := CREATURE.new()
	creature.species_id = species
	creature.level = level
	return creature

func test_farewell_policy_preserves_unique_species_and_picks_lowest_duplicate() -> void:
	var members := [_creature("sparkit", 1), _creature("mudsnout", 20),
		_creature("bramblebun", 18), _creature("mudsnout", 15), _creature("bramblebun", 17)]
	assert_eq(SEGMENT.outgoing_duplicate(members), 3)
	members[3].level = 17
	assert_eq(SEGMENT.outgoing_duplicate(members), 3, "equal levels use stable earlier slot")
	members[3].species_id = "unique"
	assert_eq(SEGMENT.outgoing_duplicate(members), 4)
	members[4].species_id = "another_unique"
	assert_eq(SEGMENT.outgoing_duplicate(members), -1)
	assert_eq(SEGMENT.outgoing_duplicate([]), -1)
	assert_eq(SEGMENT.outgoing_duplicate([null]), -1)

func test_real_refcounted_identities_are_not_rejected_by_sign() -> void:
	var members := []
	var ids: Array[int] = []
	for index in 5:
		var member := _creature("mudsnout", index + 1)
		members.append(member)
		ids.append(member.get_instance_id())
	assert_eq(SEGMENT._unique_count(ids), 5)
	assert_eq(SEGMENT._unique_count([0, 1, 2, 3, 4]), 0)
	assert_eq(SEGMENT._unique_count([1, 1, 2, 3, 4]), 4)
	assert_eq(SEGMENT.outgoing_duplicate(members), 0)

func test_supply_selection_respects_surplus_and_actual_tidal_recipe_rows() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_pickups.json"))
	var row: Dictionary = {}
	for candidate: Dictionary in source.harvest:
		if str(candidate.id) == "water:tidal_cradle:harvest:013":
			row = candidate
	assert_false(row.is_empty())
	assert_true(SEGMENT.harvest_needed(row, {"reed_fiber": 8}, {"reed_fiber": 7}))
	assert_false(SEGMENT.harvest_needed(row, {"reed_fiber": 8}, {"reed_fiber": 8}))
	assert_false(SEGMENT.harvest_needed(row, {"reed_fiber": 8}, {"reed_fiber": 20}))
	assert_false(SEGMENT.harvest_needed(row, {"driftwood": 6}, {}))
	row = row.duplicate(true)
	row.island_id = "veilfall"
	assert_false(SEGMENT.harvest_needed(row, {"reed_fiber": 8}, {}))

func test_missing_live_entry_fails_without_synthetic_fallback() -> void:
	var result: Dictionary = await SEGMENT.new().run(null, null, null)
	assert_false(result.passed)
	assert_false(result.completed_mounted)
	assert_eq(result.failures.size(), 1)
	assert_eq(result.swimmer, null)

func test_authored_clearance_leaves_workbench_and_bed_even_at_walk_tolerance() -> void:
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	var camps: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_camps.json"))
	var point := SEGMENT.camp_clearance_point(world)
	assert_true(point.is_finite())
	assert_false(SEGMENT.camp_clearance_point({}).is_finite())
	var at := Vector2.ZERO
	for row: Dictionary in camps.camps:
		if str(row.id) == "water_camp_tidal_cradle":
			at = Vector2(row.at[0], row.at[1])
	var craft: Array = camps.tuning.craft_offset_xz
	var bench := at + Vector2(craft[0], craft[1])
	var bed_offset: Array = camps.tuning.creature_bed_offset_xz
	# Production creature-bed prompt local offset and configured radius.
	var bed := at + Vector2(bed_offset[0], bed_offset[1]) + Vector2(0, 0.7)
	var clearance := Vector2(point.x, point.z)
	assert_true(clearance.distance_to(bench) - 1.3 > float(camps.tuning.prompt_radius_m))
	assert_true(clearance.distance_to(at) - 1.3 > float(camps.tuning.prompt_radius_m))
	assert_true(clearance.distance_to(bed) - 1.3 > 2.6)
	var arbiter := preload("res://scripts/world/prompt_arbiter.gd")
	var riding := preload("res://scripts/world/riding_controller.gd")
	var ride := arbiter.offer("Ride caught swimmer", 0.1, riding.RIDE_PRIORITY)
	var workbench := arbiter.offer("Craft at workbench", 2.0, 0)
	assert_eq(arbiter.choose([ride, workbench]), workbench,
		"body proximity alone cannot defeat an in-range camp offer")
