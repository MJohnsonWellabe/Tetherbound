extends "res://tests/test_case.gd"

const HANDOFF := preload("res://tests/helpers/f49_disk_handoff.gd")

func _state() -> Dictionary:
	var state := {"party": [], "redesign_character": {"creatures": {}, "master_wins": [], "feast_recipes": []},
		"inventory": {"0": {"id": "essence_ground", "n": 12}}, "realm": "meadows"}
	for index in 5:
		var uid := "original-%d" % index
		state.party.append({"uid": uid, "species": "mudsnout", "level": 10, "xp": 0})
		state.redesign_character.creatures[uid] = {"cap_level": 10, "breakthroughs": [], "evolution_choices": {}}
	return state

func _receipt() -> Dictionary:
	var state := _state()
	state.training = HANDOFF.training_snapshot(state)
	return {"profile": HANDOFF.TRAINING_PROFILE, "state": state}

func test_split_and_prior_exact_meadows_orders_are_admitted() -> void:
	assert_eq(HANDOFF.order_profile(HANDOFF.MEADOWS_PIECES, HANDOFF.MEADOWS_REALMS), "legacy")
	assert_eq(HANDOFF.order_profile(HANDOFF.MEADOWS_PIECES.slice(1), HANDOFF.MEADOWS_REALMS.slice(1)), "legacy")
	assert_eq(HANDOFF.order_profile(HANDOFF.TRAINED_MEADOWS_PIECES, HANDOFF.TRAINED_MEADOWS_REALMS), HANDOFF.TRAINING_PROFILE)
	assert_eq(HANDOFF.order_profile(HANDOFF.TRAINED_MEADOWS_PIECES.slice(1),
		HANDOFF.TRAINED_MEADOWS_REALMS.slice(1)), HANDOFF.TRAINING_PROFILE)
	assert_eq(HANDOFF.order_profile(HANDOFF.TRAINED_MEADOWS_PIECES + HANDOFF.BOUNDARIES,
		HANDOFF.TRAINED_MEADOWS_REALMS + HANDOFF.REALMS), HANDOFF.TRAINING_PROFILE)
	var skipped: Array = HANDOFF.TRAINED_MEADOWS_PIECES.duplicate()
	skipped.erase("training_t1_altar_3")
	assert_eq(HANDOFF.order_profile(skipped, HANDOFF.TRAINED_MEADOWS_REALMS), "")
	var no_return: Array = HANDOFF.TRAINED_MEADOWS_PIECES.duplicate()
	no_return.erase("training_t2_return")
	assert_eq(HANDOFF.order_profile(no_return, HANDOFF.TRAINED_MEADOWS_REALMS), "")
	# Masters follow masters.json chapter_guidance: Orin's loop returns before
	# the Warrens; Mira's lies past the Relay (mill_crossing_restored) and
	# returns before the Sigils.
	var order: Array = HANDOFF.TRAINED_MEADOWS_PIECES
	assert_eq(order[order.find("warrens") - 1], "training_t1_return")
	assert_eq(order[order.find("relay") + 1], "training_t2_earn")
	assert_eq(order[order.find("sigils") - 1], "training_t2_return")
	assert_true(order.find("training_t2_master") > order.find("relay"), "Mira after the mill crossing opens")
	var no_t1_return: Array = HANDOFF.TRAINED_MEADOWS_PIECES.duplicate()
	no_t1_return.erase("training_t1_return")
	assert_eq(HANDOFF.order_profile(no_t1_return, HANDOFF.TRAINED_MEADOWS_REALMS), "")
	var reordered: Array = HANDOFF.TRAINED_MEADOWS_PIECES.duplicate()
	var first := reordered.find("training_t1_master")
	reordered[first] = "training_t1_feed"
	reordered[first + 2] = "training_t1_master"
	assert_eq(HANDOFF.order_profile(reordered, HANDOFF.TRAINED_MEADOWS_REALMS), "")
	var realms: Array = HANDOFF.TRAINED_MEADOWS_REALMS.duplicate()
	realms[3] = "water"
	assert_eq(HANDOFF.order_profile(HANDOFF.TRAINED_MEADOWS_PIECES, realms), "")

func test_legacy_bridge_is_shared_but_old_warrens_cannot_claim_training() -> void:
	var legacy := {"state": _state()}
	assert_eq(HANDOFF.profile_error(legacy, "bridge", HANDOFF.TRAINING_PROFILE), "")
	assert_ne(HANDOFF.profile_error(legacy, "training_t1_altar_1", HANDOFF.TRAINING_PROFILE), "")
	assert_ne(HANDOFF.profile_error(legacy, "warrens", HANDOFF.TRAINING_PROFILE), "")
	assert_ne(HANDOFF.profile_error(legacy, "tidewake_handoff", HANDOFF.TRAINING_PROFILE), "")
	assert_eq(HANDOFF.profile_error(legacy, "warrens", ""), "")
	assert_ne(HANDOFF.profile_error(_receipt(), "bridge", ""), "")
	var unknown := _receipt()
	unknown.profile = "future_or_forged"
	assert_ne(HANDOFF.profile_error(unknown, "bridge", HANDOFF.TRAINING_PROFILE), "")

func test_training_projection_must_match_saved_levels_caps_and_history() -> void:
	var receipt := _receipt()
	assert_eq(HANDOFF.profile_error(receipt, "training_t1_altar_1", HANDOFF.TRAINING_PROFILE), "")
	for field: String in ["level", "xp"]:
		var changed := receipt.duplicate(true)
		changed.state.party[0][field] += 1
		assert_ne(HANDOFF.profile_error(changed, "training_t1_altar_1", HANDOFF.TRAINING_PROFILE), "")
	var changed := receipt.duplicate(true)
	changed.state.redesign_character.creatures["original-0"].cap_level = 20
	assert_ne(HANDOFF.profile_error(changed, "training_t1_feed", HANDOFF.TRAINING_PROFILE), "")
	changed = receipt.duplicate(true)
	changed.state.redesign_character.master_wins.append("master_t1")
	assert_ne(HANDOFF.profile_error(changed, "training_t1_master", HANDOFF.TRAINING_PROFILE), "")
	changed = receipt.duplicate(true)
	changed.state.erase("training")
	assert_ne(HANDOFF.profile_error(changed, "training_t1_feed", HANDOFF.TRAINING_PROFILE), "")

func test_generated_receipt_cannot_enter_training_even_at_shared_bridge() -> void:
	for field: String in ["input_mode", "generated_origin"]:
		var receipt := {"state": _state()}
		receipt[field] = "generated_fixture"
		assert_ne(HANDOFF.profile_error(receipt, "bridge", HANDOFF.TRAINING_PROFILE), "")
	var receipt := _receipt()
	receipt.kind = "f49_generated_fixture_handoff"
	assert_ne(HANDOFF.profile_error(receipt, "training_t1_altar_1", HANDOFF.TRAINING_PROFILE), "")

func test_legacy_load_exception_preserves_full_character_comparison() -> void:
	var legacy := {"state": _state()}
	var observed: Dictionary = legacy.state.duplicate(true)
	observed.training = HANDOFF.training_snapshot(observed)
	assert_eq(HANDOFF.load_comparison_state(observed, legacy, "bridge", HANDOFF.TRAINING_PROFILE), legacy.state)
	assert_true(observed.has("training"), "comparison must not mutate the observed state")
	observed.redesign_character.creatures["original-0"].cap_level = 20
	assert_ne(HANDOFF.load_comparison_state(observed, legacy, "bridge", HANDOFF.TRAINING_PROFILE), legacy.state)
	assert_ne(HANDOFF.load_comparison_state(observed, legacy, "warrens", HANDOFF.TRAINING_PROFILE), legacy.state)
	var stamped := _receipt()
	assert_true(HANDOFF.load_comparison_state(observed, stamped, "bridge", HANDOFF.TRAINING_PROFILE).has("training"))

func test_projection_is_detached_and_does_not_repair_missing_records() -> void:
	var state := _state()
	var projected := HANDOFF.training_snapshot(state)
	projected.party[0].breakthroughs.append(1)
	assert_eq(state.redesign_character.creatures["original-0"].breakthroughs, [])
	state.redesign_character.creatures.erase("original-0")
	assert_eq(HANDOFF.training_snapshot(state), {})
