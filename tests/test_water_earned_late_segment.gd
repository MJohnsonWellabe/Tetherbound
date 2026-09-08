extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/water_earned_late_segment.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")


func test_same_five_preserves_real_signed_instance_identities() -> void:
	var five: Array = []
	for index in 5:
		five.append(SPECIES.spawn("bramblebun"))
	assert_true(SEGMENT.same_five(five, five.duplicate()))
	var changed := five.duplicate()
	changed[4] = SPECIES.spawn("bramblebun")
	assert_false(SEGMENT.same_five(changed, five), "same species is not the retained identity")
	changed = five.duplicate()
	changed.reverse()
	assert_false(SEGMENT.same_five(changed, five))
	assert_false(SEGMENT.same_five(five.slice(0, 4), five.slice(0, 4)))
	changed = five.duplicate()
	changed.append(SPECIES.spawn("water_aquaryn"))
	assert_false(SEGMENT.same_five(changed, changed), "sixth holder is forbidden")
	changed = five.duplicate()
	changed[4] = changed[0]
	assert_false(SEGMENT.same_five(changed, changed), "duplicate holder cannot count twice")
	changed[4] = null
	assert_false(SEGMENT.same_five(changed, changed))


func test_deadline_calls_terminal_owner_once_and_releases_real_inputs() -> void:
	var helper := SEGMENT.new()
	var calls: Array = []
	helper._abort = func(reason: String) -> void: calls.append(reason)
	helper._running = true
	helper._deadline = Time.get_ticks_msec() + 100000
	helper._observe_deadline()
	assert_eq(calls.size(), 0)
	helper._deadline = 1
	Input.action_press("combat_quick")
	Input.action_press("interact")
	helper._observe_deadline()
	helper._observe_deadline()
	assert_eq(calls.size(), 1)
	assert_eq(helper.failures.size(), 1)
	assert_false(Input.is_action_pressed("combat_quick"))
	assert_false(Input.is_action_pressed("interact"))
	assert_false(helper.result().ok)
	assert_eq(SEGMENT.WATCHDOG_MS, 3000000)


func test_expired_navigation_exits_before_any_player_or_physics_access() -> void:
	var nav := SEGMENT.DeadlineNavigator.new(null, null, null, Callable())
	nav.deadline = 1
	assert_false(await nav.walk_to(Vector3(30, 0, 0), 1200),
		"expired nested navigation may not wait on its held-frame fallback")


func test_missing_live_receipt_cannot_credit_the_late_route() -> void:
	var helper := SEGMENT.new()
	assert_false(await helper.run_from_mount(null, Callable()))
	assert_false(helper.result().passed)
	assert_eq(helper.failures.size(), 1)
	assert_eq(helper.result().endpoint, "guardian_freed_before_invitation")


func test_authored_opponent_and_mounted_route_contracts_remain_intact() -> void:
	var characters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	var found := 0
	for trainer: Dictionary in characters.trainers:
		if SEGMENT.TRAINERS.has(str(trainer.id)):
			assert_eq(trainer.team.size(), SEGMENT.TRAINERS[str(trainer.id)], str(trainer.id))
			found += 1
	assert_eq(found, 4)
	var world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_world.json"))
	found = 0
	for route: Dictionary in world.water_routes:
		if SEGMENT.LATE_ROUTES.has(str(route.id)):
			assert_eq(str(route.intended_traversal), "swim_mount")
			assert_true(route.requires_compatible_active_swim_mount)
			assert_true(route.required_equipment.has("swim_saddle"))
			found += 1
	assert_eq(found, 3)


func test_helper_never_loads_the_fixture_or_invites_the_guardian() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/water_earned_late_segment.gd")
	for bypass in ["smoke_water_continuous.gd", "interaction_activate(", "dialogue.advance(",
		".dismount(", ".summon(", ".global_position =", ".hp =", "inventory.add(",
		"party.add(", "_guardian_prompt", "request_guardian_offer("]:
		assert_false(source.contains(bypass), bypass)
