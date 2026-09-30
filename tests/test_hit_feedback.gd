extends "res://tests/test_case.gd"

const FEEDBACK := preload("res://scripts/combat/hit_feedback.gd")

func test_replayed_and_older_hits_do_not_repeat_and_issuers_are_independent() -> void:
	var history: Dictionary = {}
	assert_true(FEEDBACK.admit(history, {"action_id":"fight:1:3"}))
	assert_false(FEEDBACK.admit(history, {"action_id":"fight:1:3"}))
	assert_false(FEEDBACK.admit(history, {"action_id":"fight:1:2"}))
	assert_true(FEEDBACK.admit(history, {"action_id":"fight:2:1"}))
	assert_false(FEEDBACK.admit(history, {"action_id":"fight:1:bad"}))
	assert_true(FEEDBACK.admit(history, {"action_id":"fight:1:4"}, false))
	assert_eq(history["fight:1"], 3, "preview never consumes the host receipt")

func test_weighted_feedback_is_immutable_and_preserves_host_damage() -> void:
	var light := FEEDBACK.receipt("fight:1:1", "pebble_toss", {}, "quick", 17.25, 1.0, false, Vector3.RIGHT)
	var heavy := FEEDBACK.receipt("fight:1:2", "stone_rush", {}, "charged", 17.25, 1.0, false, Vector3.RIGHT)
	assert_true(light.is_read_only())
	assert_true(heavy.knockback_m > light.knockback_m)
	assert_true(heavy.hitstop_seconds > light.hitstop_seconds)
	assert_eq(light.damage, 17.25, "presentation never rerolls host damage")
	assert_eq(light.direction, Vector3.RIGHT)
	assert_eq(FEEDBACK.weight_for({"slot": "charged"}, "quick"), "heavy", "incoming named moves use their authored weight even through the enemy quick fallback")

func test_frozen_launch_rejects_replacement_actors_generation_and_realm() -> void:
	var launch := FEEDBACK.launch("fight:2:4", "fight", "owned-1", "wild-1", "stone_rush", "charged", Vector3.ZERO, Vector3.RIGHT, 0.2, 7)
	assert_true(launch.is_read_only())
	assert_true(FEEDBACK.launch_matches(launch, "fight", "owned-1", "wild-1", 7))
	assert_false(FEEDBACK.launch_matches(launch, "next-fight", "owned-1", "wild-1", 7))
	assert_false(FEEDBACK.launch_matches(launch, "fight", "replacement-owned", "wild-1", 7))
	assert_false(FEEDBACK.launch_matches(launch, "fight", "owned-1", "replacement-wild", 7))
	assert_false(FEEDBACK.launch_matches(launch, "fight", "owned-1", "wild-1", 8), "same UID cannot reuse an old body generation")

func test_giant_and_profile_reductions_apply_once() -> void:
	var normal := FEEDBACK.receipt("a", "stone_rush", {}, "charged", 20.0, 1.0, false, Vector3.RIGHT)
	var giant := FEEDBACK.receipt("b", "stone_rush", {}, "charged", 20.0, 1.0, false, Vector3.RIGHT, float(FEEDBACK.config().giant_height_m), 0.5)
	assert_almost_eq(giant.knockback_m, normal.knockback_m * float(FEEDBACK.config().giant_knockback_scale) * 0.5, 0.00001)
	assert_true(FEEDBACK.impulse_for(giant) < FEEDBACK.impulse_for(normal))

func test_critical_effective_resisted_and_ordinary_numbers_differ() -> void:
	var plain := FEEDBACK.receipt("a", "", {}, "quick", 20.0, 1.0, false, Vector3.RIGHT)
	var crit := FEEDBACK.receipt("b", "", {}, "quick", 20.0, 1.25, true, Vector3.RIGHT)
	var strong := FEEDBACK.receipt("c", "", {}, "quick", 20.0, 1.25, false, Vector3.RIGHT)
	var weak := FEEDBACK.receipt("d", "", {}, "quick", 20.0, 0.8, false, Vector3.RIGHT)
	var base := FEEDBACK.number_style(plain, true)
	assert_true(FEEDBACK.number_style(crit, true).font_px > base.font_px)
	assert_true(FEEDBACK.number_style(strong, true).font_px > base.font_px)
	assert_true(FEEDBACK.number_style(weak, true).font_px < base.font_px)
	assert_true(FEEDBACK.number_style(crit, true).colour != base.colour)
	assert_true(FEEDBACK.number_style(plain, false).font_px < base.font_px)
