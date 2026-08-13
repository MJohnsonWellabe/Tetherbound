extends "res://tests/test_case.gd"

## Stamina and fall damage. Pure arithmetic, so it is testable; how the numbers
## FEEL is the owner's call on the Ally and no test here claims otherwise.

const VITALS := preload("res://scripts/player/player_vitals.gd")

var _vitals: RefCounted


func before_each() -> void:
	_vitals = VITALS.new()
	_vitals.configure({
		"stamina": {
			"max": 100.0,
			"sprint_drain_per_second": 10.0,
			"jump_cost": 8.0,
			"regen_per_second": 20.0,
			"regen_delay": 1.0,
			"exhausted_below": 10.0,
		},
		"health": {"max": 100.0},
		"fall_damage": {
			"safe_speed": 12.0,
			"lethal_speed": 32.0,
			"curve": 2.0,
			"max_damage": 100.0,
		},
	})
	_vitals.configure_satiety({
		"satiety": {
			"max": 100.0,
			"drain_per_minute": 0.8,
			"hungry_below": 0.35,
			"critical_below": 0.15,
			"debuffs": {
				"hungry": {"stamina_regen_scale": 0.6},
				"critical": {"stamina_regen_scale": 0.35, "move_speed_scale": 0.92},
			},
		},
	})


func test_starts_full() -> void:
	assert_eq(_vitals.stamina, 100.0)
	assert_eq(_vitals.health, 100.0)
	assert_true(_vitals.can_sprint())


func test_sprinting_drains_stamina() -> void:
	_vitals.tick(1.0, true)
	assert_almost_eq(_vitals.stamina, 90.0, 0.001)


func test_stamina_does_not_regenerate_during_the_delay() -> void:
	_vitals.tick(1.0, true)
	# Half a second of rest is inside the 1.0s delay, so nothing comes back.
	_vitals.tick(0.5, false)
	assert_almost_eq(_vitals.stamina, 90.0, 0.001)


func test_stamina_regenerates_after_the_delay() -> void:
	_vitals.tick(1.0, true)
	_vitals.tick(1.0, false)   # burns the delay exactly
	_vitals.tick(1.0, false)   # first second of actual regen
	assert_almost_eq(_vitals.stamina, 100.0, 0.001)


func test_stamina_never_goes_negative() -> void:
	_vitals.tick(100.0, true)
	assert_eq(_vitals.stamina, 0.0)


func test_exhaustion_latches_until_recovered() -> void:
	_vitals.tick(100.0, true)
	assert_false(_vitals.can_sprint(), "empty meter should refuse sprint")

	# Still below the exhaustion threshold: a stutter-sprint must not work.
	_vitals.tick(1.0, false)
	_vitals.tick(0.4, false)
	assert_false(_vitals.can_sprint(), "8 stamina is under the 10 threshold")

	_vitals.tick(0.2, false)
	assert_true(_vitals.can_sprint(), "past the threshold, sprint is allowed again")


func test_jump_refused_when_stamina_is_short() -> void:
	_vitals.tick(9.3, true)          # leaves 7 stamina, under the cost of 8
	var before: float = _vitals.stamina
	assert_false(_vitals.try_spend_jump())
	assert_almost_eq(_vitals.stamina, before, 0.001, "a refused jump must not spend")


func test_jump_spends_when_affordable() -> void:
	assert_true(_vitals.try_spend_jump())
	assert_almost_eq(_vitals.stamina, 92.0, 0.001)


func test_landing_below_the_safe_speed_is_free() -> void:
	assert_eq(_vitals.fall_damage_for(0.0), 0.0)
	assert_eq(_vitals.fall_damage_for(11.9), 0.0)
	assert_eq(_vitals.fall_damage_for(12.0), 0.0)


func test_fall_damage_rises_with_impact_speed() -> void:
	var slow: float = _vitals.fall_damage_for(18.0)
	var fast: float = _vitals.fall_damage_for(26.0)
	assert_true(slow > 0.0, "past the safe speed should hurt")
	assert_true(fast > slow, "faster landings should hurt more")


func test_fall_damage_curve_is_gentle_near_the_threshold() -> void:
	# The whole point of an exponent above 1: a small overshoot is cheap, so a
	# player is willing to judge a drop rather than avoid every one.
	var midpoint: float = _vitals.fall_damage_for(22.0)
	assert_between(midpoint, 20.0, 30.0, "halfway up the range should cost about a quarter")


func test_fall_damage_caps_at_lethal_speed() -> void:
	assert_almost_eq(_vitals.fall_damage_for(32.0), 100.0, 0.001)
	assert_almost_eq(_vitals.fall_damage_for(500.0), 100.0, 0.001, "damage must not exceed the cap")


func test_landing_applies_damage_and_can_kill() -> void:
	var dealt: float = _vitals.apply_landing(32.0)
	assert_almost_eq(dealt, 100.0, 0.001)
	assert_eq(_vitals.health, 0.0)
	assert_true(_vitals.is_dead())


func test_health_never_goes_negative() -> void:
	_vitals.apply_landing(500.0)
	_vitals.apply_landing(500.0)
	assert_eq(_vitals.health, 0.0)


func test_fractions_stay_in_range() -> void:
	assert_eq(_vitals.stamina_fraction(), 1.0)
	_vitals.tick(100.0, true)
	assert_eq(_vitals.stamina_fraction(), 0.0)
	_vitals.apply_landing(500.0)
	assert_eq(_vitals.health_fraction(), 0.0)


## D29 satiety: light hunger, no death.

func test_satiety_drains_at_configured_rate() -> void:
	_vitals.tick_satiety(60.0)   # one minute at 0.8/minute
	assert_almost_eq(_vitals.satiety, 99.2, 0.001)


func test_satiety_floors_at_zero_without_touching_health() -> void:
	_vitals.tick_satiety(1_000_000.0)
	assert_eq(_vitals.satiety, 0.0)
	assert_eq(_vitals.health, 100.0, "hunger must never cost health")
	assert_false(_vitals.is_dead(), "D29: there is no starvation death")


func test_hunger_state_boundaries() -> void:
	_vitals.satiety = 36.0
	assert_eq(_vitals.hunger_state(), "ok")
	_vitals.satiety = 34.0
	assert_eq(_vitals.hunger_state(), "hungry")
	_vitals.satiety = 14.0
	assert_eq(_vitals.hunger_state(), "critical")


func test_eat_clamps_satiety_at_max() -> void:
	_vitals.satiety = 90.0
	_vitals.eat(50.0)
	assert_eq(_vitals.satiety, 100.0)


func test_eat_applies_buff() -> void:
	_vitals.eat(0.0, {"id": "berry_verve", "stat": "stamina_regen_scale", "amount": 1.15, "duration_s": 120.0})
	assert_eq(_vitals.active_buffs.size(), 1)
	assert_eq(_vitals.active_buffs[0]["id"], "berry_verve")


func test_eating_same_buff_again_refreshes_not_stacks() -> void:
	var buff := {"id": "berry_verve", "stat": "stamina_regen_scale", "amount": 1.15, "duration_s": 120.0}
	_vitals.eat(0.0, buff)
	_vitals.tick_satiety(100.0)   # burn most of the timer
	_vitals.eat(0.0, buff)        # eating again should refresh, not add a second entry
	assert_eq(_vitals.active_buffs.size(), 1, "same-id buff must refresh in place")
	assert_almost_eq(float(_vitals.active_buffs[0]["remaining_s"]), 120.0, 0.001)


func test_buff_expires_after_duration() -> void:
	_vitals.eat(0.0, {"id": "berry_verve", "stat": "stamina_regen_scale", "amount": 1.15, "duration_s": 10.0})
	_vitals.tick_satiety(9.9)
	assert_eq(_vitals.active_buffs.size(), 1, "buff should still be active just before expiry")
	_vitals.tick_satiety(0.2)
	assert_eq(_vitals.active_buffs.size(), 0, "buff should be gone once its timer runs out")


func test_stamina_regen_scale_fed_is_full() -> void:
	assert_almost_eq(_vitals.stamina_regen_scale(), 1.0, 0.001)


func test_stamina_regen_scale_hungry() -> void:
	_vitals.satiety = 30.0   # fraction 0.30: below hungry_below, above critical_below
	assert_almost_eq(_vitals.stamina_regen_scale(), 0.6, 0.001)


func test_stamina_regen_scale_critical() -> void:
	_vitals.satiety = 10.0   # fraction 0.10: below critical_below
	assert_almost_eq(_vitals.stamina_regen_scale(), 0.35, 0.001)


func test_stamina_regen_scale_buff_multiplies_fed_baseline() -> void:
	_vitals.eat(0.0, {"id": "berry_verve", "stat": "stamina_regen_scale", "amount": 1.15, "duration_s": 120.0})
	assert_almost_eq(_vitals.stamina_regen_scale(), 1.15, 0.001)


func test_move_speed_scale_only_softens_when_critical() -> void:
	assert_almost_eq(_vitals.move_speed_scale(), 1.0, 0.001, "fed should be full speed")
	_vitals.satiety = 30.0
	assert_almost_eq(_vitals.move_speed_scale(), 1.0, 0.001, "hungry alone should not slow movement")
	_vitals.satiety = 10.0
	assert_almost_eq(_vitals.move_speed_scale(), 0.92, 0.001, "critical hunger should soften movement")


func test_rest_refills_satiety() -> void:
	_vitals.satiety = 10.0
	_vitals.rest()
	assert_eq(_vitals.satiety, 100.0)
