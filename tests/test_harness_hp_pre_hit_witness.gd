extends "res://tests/test_case.gd"

const SMOKE := preload("res://tests/smoke_net_harness_max_hp.gd")
const BASE := 134.4
const SCALE := 1.264


func _resting() -> Dictionary:
	return {"hp": BASE, "max_hp": BASE}


func _sample(incoming: float) -> Dictionary:
	var hp := BASE - incoming / SCALE
	var shown_max := BASE * SCALE if incoming > 0.0 else BASE
	return {"fighting": true, "hp": hp, "max_hp": BASE, "saved_max": BASE,
		"shown_hp": hp / BASE * shown_max, "shown_max": shown_max, "incoming_total": incoming}


func test_live_hit_before_manual_strike_keeps_the_exact_host_authority_witness() -> void:
	# MP7's rejected snapshot: an ordinary enemy hit already lowered stored HP
	# and adopted the admitted host scale before the explicit strike command.
	assert_eq(SMOKE.pre_hit_state(_sample(11.77), _resting(), SCALE), "prior_host_hit")
	assert_eq(SMOKE.pre_hit_state(_sample(19.40), _resting(), SCALE), "prior_host_hit")


func test_no_hit_requires_the_original_bare_maximum_and_unchanged_hp() -> void:
	assert_eq(SMOKE.pre_hit_state(_sample(0.0), _resting(), SCALE), "bare_before_host_hit")
	var premature := _sample(0.0)
	premature.shown_max = BASE * SCALE
	premature.shown_hp = premature.shown_max
	assert_eq(SMOKE.pre_hit_state(premature, _resting(), SCALE), "")
	premature = _sample(0.0)
	premature.hp -= 1.0
	premature.shown_hp -= 1.0
	assert_eq(SMOKE.pre_hit_state(premature, _resting(), SCALE), "")


func test_partial_feedback_stays_unclassified_until_counter_and_hp_agree() -> void:
	var partial := _sample(11.77)
	partial.incoming_total = 0.0
	assert_eq(SMOKE.pre_hit_state(partial, _resting(), SCALE), "")
	partial = _sample(11.77)
	partial.hp = BASE
	partial.shown_hp = partial.shown_max
	assert_eq(SMOKE.pre_hit_state(partial, _resting(), SCALE), "")
	assert_eq(SMOKE.pre_hit_state(_sample(11.77), _resting(), SCALE), "prior_host_hit")


func test_wrong_scale_fraction_damage_or_saved_max_cannot_explain_a_prior_hit() -> void:
	var invalid := _sample(11.77)
	invalid.shown_max = BASE
	assert_eq(SMOKE.pre_hit_state(invalid, _resting(), SCALE), "")
	invalid = _sample(11.77)
	invalid.shown_hp += 2.0
	assert_eq(SMOKE.pre_hit_state(invalid, _resting(), SCALE), "")
	invalid = _sample(11.77)
	invalid.incoming_total += 1.0
	assert_eq(SMOKE.pre_hit_state(invalid, _resting(), SCALE), "")
	invalid = _sample(11.77)
	invalid.saved_max *= SCALE
	assert_eq(SMOKE.pre_hit_state(invalid, _resting(), SCALE), "")


func test_missing_counter_nonfinite_or_ended_fight_fails_closed() -> void:
	var invalid := _sample(0.0)
	invalid.erase("incoming_total")
	assert_eq(SMOKE.pre_hit_state(invalid, _resting(), SCALE), "")
	invalid = _sample(11.77)
	invalid.hp = NAN
	assert_eq(SMOKE.pre_hit_state(invalid, _resting(), SCALE), "")
	invalid = _sample(11.77)
	invalid.fighting = false
	assert_eq(SMOKE.pre_hit_state(invalid, _resting(), SCALE), "")
