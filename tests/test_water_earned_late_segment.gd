extends "res://tests/test_case.gd"

const SEGMENT := preload("res://tests/helpers/water_earned_late_segment.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const HUMAN := preload("res://tests/helpers/water_human_late_segment.gd")


func test_short_late_boundaries_require_exact_before_and_after_milestones() -> void:
	var chart := [HUMAN.BEX_FLAGS[0]]
	var won := chart + ["defeated_water_trainer_bex"]
	var starts := {"departure": [], "salt_crossing": [], "salt_chart": [],
		"sluice_crossing": chart, "bex": chart, "bex_recovery": won}
	var ends := {"departure": [], "salt_crossing": [], "salt_chart": chart,
		"sluice_crossing": chart, "bex": won, "bex_recovery": HUMAN.BEX_FLAGS}
	for piece: String in starts:
		assert_eq(HUMAN.piece_entry_error(piece, starts[piece]), "", piece)
		assert_eq(HUMAN.short_exit_error(piece, ends[piece]), "", piece)
		for flag: String in ends[piece]:
			var missing: Array = ends[piece].duplicate()
			missing.erase(flag)
			assert_ne(HUMAN.short_exit_error(piece, missing), "", piece + " missing " + flag)
		for future: String in HUMAN.CALDER_FLAGS + HUMAN.VENN_FLAGS + HUMAN.END_FLAGS:
			assert_ne(HUMAN.short_exit_error(piece, ends[piece] + [future]), "", piece + " future " + future)
	assert_ne(HUMAN.piece_entry_error("bex", won), "", "cannot credit a pre-won fight")
	assert_ne(HUMAN.short_exit_error("bex", chart), "", "cannot save unfinished combat as victory")
	assert_eq(HUMAN.SHORT_WATCHDOG_MS, 240000)


func test_short_movement_handoff_requires_receipt_position_and_training() -> void:
	var state := {"uids": ["a", "b", "c", "d", "e"], "flags": [], "items": {"coin": 20},
		"realm": "water", "player": [10, 2, 30], "training": {"party": [{"uid": "a", "cap_level": 20}]}}
	var receipt := {"passed": true, "segment": "07a1_departure", "after": state.duplicate(true)}
	assert_eq(HUMAN.short_receipt_error("07a2_salt_crossing", receipt, state), "")
	assert_ne(HUMAN.short_receipt_error("07a3_salt_chart", receipt, state), "", "same flags cannot skip crossing")
	for change: Dictionary in [{"player": [90, 2, 30]}, {"player": []}, {"player": ["10", 2, 30]},
		{"uids": ["b", "a", "c", "d", "e"]}, {"training": {}}, {"items": {"coin": 19}}]:
		var loaded := state.duplicate(true)
		loaded.merge(change, true)
		assert_ne(HUMAN.short_receipt_error("07a2_salt_crossing", receipt, loaded), "", str(change))
	for verdict: Variant in [false, "true", 1]:
		var bad := receipt.duplicate(true)
		bad.passed = verdict
		assert_ne(HUMAN.short_receipt_error("07a2_salt_crossing", bad, state), "")
	var legacy := state.duplicate(true)
	legacy.erase("training")
	assert_eq(HUMAN.short_receipt_error("07a1_departure", {"passed": true, "segment": "05_tidal", "after": legacy}, legacy), "",
		"first historical boundary remains explicitly unproven; runner retains generated ancestry")
	assert_ne(HUMAN.short_receipt_error("07a2_salt_crossing", {"passed": true, "segment": "07a1_departure", "after": legacy}, legacy), "")
	assert_eq(HUMAN.short_receipt_error("07b_calder", {"passed": true, "segment": "07a6_bex_recovery", "after": state}, state), "")


class SaltRouteRecorder extends "res://tests/helpers/water_human_late_segment.gd":
	var actions: Array[String] = []
	var stop_at := ""
	func _record(action: String) -> bool:
		actions.append(action)
		return action != stop_at
	func _tidal_departure() -> bool: return _record("departure")
	func _cross_route(id: String) -> bool: return _record(id)
	func _salt_chart() -> bool: return _record("chart")
	func _sluice_approach() -> bool: return _record("sluice")
	func _defeat_trainer(id: String, flag: String) -> bool: return _record(id + ":" + flag)
	func _bex_recovery() -> bool: return _record("recovery")
	func _same_party() -> bool: return true
	func _expired() -> bool: return false


func test_original_salt_bex_operation_order_and_fail_fast_survive_split() -> void:
	var route := SaltRouteRecorder.new()
	assert_true(await route._salt_bex())
	var expected := ["departure", HUMAN.LATE_ROUTES[0], "chart", "sluice",
		"water_trainer_bex:defeated_water_trainer_bex", "recovery"]
	assert_eq(route.actions, expected)
	for index in expected.size():
		var failed := SaltRouteRecorder.new()
		failed.stop_at = expected[index]
		assert_false(await failed._salt_bex())
		assert_eq(failed.actions, expected.slice(0, index + 1), "never run past a failed original operation")


func test_human_late_split_requires_exact_predecessor_milestones() -> void:
	assert_eq(HUMAN.piece_entry_error("salt_bex", []), "")
	assert_eq(HUMAN.piece_entry_error("calder", HUMAN.BEX_FLAGS), "")
	assert_eq(HUMAN.piece_entry_error("venn", HUMAN.BEX_FLAGS + HUMAN.CALDER_FLAGS), "")
	assert_eq(HUMAN.piece_entry_error("nerissa", HUMAN.BEX_FLAGS + HUMAN.CALDER_FLAGS + HUMAN.VENN_FLAGS), "")
	for piece: String in ["calder", "venn", "nerissa"]:
		assert_ne(HUMAN.piece_entry_error(piece, []), "", "a generated empty boundary cannot skip a predecessor")
		var required: Array = HUMAN.BEX_FLAGS + (HUMAN.CALDER_FLAGS if piece in ["venn", "nerissa"] else []) + (HUMAN.VENN_FLAGS if piece == "nerissa" else [])
		for flag: String in required:
			var missing := required.duplicate()
			missing.erase(flag)
			assert_ne(HUMAN.piece_entry_error(piece, missing), "", "missing earned milestone " + flag)
		for flag: String in HUMAN.END_FLAGS:
			assert_ne(HUMAN.piece_entry_error(piece, required + [flag]), "", "cannot precredit ending " + flag)
	assert_ne(HUMAN.piece_entry_error("salt_bex", HUMAN.BEX_FLAGS), "")
	assert_ne(HUMAN.piece_entry_error("unknown", []), "")
	assert_ne(HUMAN.piece_entry_error("all", []), "", "combined long runs cannot start")


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
	var human_routes := 0
	var direct_mount_routes := 0
	for route: Dictionary in world.water_routes:
		var id := str(route.id)
		var edge := str(route.get("edge_id", ""))
		if not SEGMENT.LATE_ROUTES.has(edge + "_sheltered"):
			continue
		if id.ends_with("_sheltered"):
			assert_eq(str(route.intended_traversal), "human_level_0")
			assert_false(bool(route.get("requires_compatible_active_swim_mount", false)))
			assert_true((route.get("required_equipment", []) as Array).is_empty())
			human_routes += 1
		elif id.ends_with("_direct"):
			assert_eq(str(route.intended_traversal), "swim_mount")
			assert_true(route.requires_compatible_active_swim_mount)
			assert_true(route.required_equipment.has("swim_saddle"))
			direct_mount_routes += 1
	assert_eq(human_routes, 3)
	assert_eq(direct_mount_routes, 3)
	var tidal_dock: Dictionary = {}
	for dock: Dictionary in world.docks:
		if str(dock.get("outbound_edge", "")) == "tidal_cradle_to_salt_crown":
			tidal_dock = dock
			break
	assert_false(tidal_dock.is_empty())
	assert_eq(str(tidal_dock.get("unlock_flag", "")), "water_aquaryn_resolved",
		"the runtime dock/current gate opens from the shared catch-or-defeat outcome")
	var characters_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	for trainer_id: String in ["water_trainer_bex", "water_trainer_calder"]:
		var trainer: Dictionary = {}
		for candidate: Dictionary in characters_data.trainers:
			if str(candidate.id) == trainer_id:
				trainer = candidate
		assert_eq(trainer.get("requires_flags", []), ["water_dock_salt_crown_landing_charted"],
			"%s is unavailable before the Salt Crown chart" % trainer_id)
	var veilfall: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_veilfall.json"))
	var intake: Dictionary = veilfall.controls[0]
	assert_eq(intake.get("requires", []), ["water_dock_sluice_isle_both_controls_disabled"],
		"Veilfall intake remains downstream of both Sluice controls")


func test_helper_never_loads_the_fixture_or_invites_the_guardian() -> void:
	var source := FileAccess.get_file_as_string("res://tests/helpers/water_earned_late_segment.gd")
	for bypass in ["smoke_water_continuous.gd", "interaction_activate(", "dialogue.advance(",
		".dismount(", ".summon(", ".global_position =", ".hp =", "inventory.add(",
		"party.add(", "_guardian_prompt", "request_guardian_offer("]:
		assert_false(source.contains(bypass), bypass)
