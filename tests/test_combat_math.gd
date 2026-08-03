extends "res://tests/test_case.gd"

## Combat arithmetic and creature state.
##
## These assert the properties that make a fight comprehensible — more attack
## hurts more, more defence hurts less, energy has to be earned before it is
## spent — not specific tuned numbers. Tuning is the owner's job on the Ally and
## a test that pins the exact damage of a quick attack would break every time
## the fight is made to feel better, which trains people to ignore it.

const MATH := preload("res://scripts/combat/combat_math.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")


# --- damage ---------------------------------------------------------------

func test_damage_rises_with_attack() -> void:
	var weak := MATH.base_damage(10.0, 10.0, 20.0)
	var strong := MATH.base_damage(10.0, 30.0, 20.0)
	assert_true(strong > weak, "more attack should hurt more (%f vs %f)" % [strong, weak])


func test_damage_falls_with_defence() -> void:
	var soft := MATH.base_damage(10.0, 20.0, 5.0)
	var armoured := MATH.base_damage(10.0, 20.0, 40.0)
	assert_true(armoured < soft, "more defence should hurt less (%f vs %f)" % [armoured, soft])


func test_equal_stats_deal_exactly_the_move_power() -> void:
	# The reason the formula is shaped the way it is: move power stays a number
	# a designer can reason about rather than an arbitrary coefficient.
	assert_almost_eq(MATH.base_damage(20.0, 25.0, 25.0), 20.0, 0.001)


func test_damage_never_reaches_zero_against_huge_defence() -> void:
	# A fight that cannot progress is worse than one that is slow. There is
	# always chip damage.
	var chip := MATH.base_damage(10.0, 1.0, 100000.0)
	assert_true(chip >= 1.0, "expected a damage floor, got %f" % chip)


func test_damage_does_not_explode_against_zero_defence() -> void:
	# The bug this formula exists to avoid: a raw attack/defence ratio goes to
	# infinity as defence approaches zero and one-shots read as a bug.
	var against_nothing := MATH.base_damage(10.0, 20.0, 0.0)
	assert_true(against_nothing < 100.0, "damage against zero defence was %f" % against_nothing)


func test_variance_brackets_the_base_value() -> void:
	var base := MATH.base_damage(20.0, 25.0, 25.0)
	var low := MATH.rolled_damage(20.0, 25.0, 25.0, 0.0)
	var mid := MATH.rolled_damage(20.0, 25.0, 25.0, 0.5)
	var high := MATH.rolled_damage(20.0, 25.0, 25.0, 1.0)
	assert_true(low < base, "roll 0 should be under the base")
	assert_almost_eq(mid, base, 0.001, "roll 0.5 should be exactly the base")
	assert_true(high > base, "roll 1 should be over the base")


func test_variance_is_small_enough_not_to_decide_a_fight() -> void:
	var low := MATH.rolled_damage(20.0, 25.0, 25.0, 0.0)
	var high := MATH.rolled_damage(20.0, 25.0, 25.0, 1.0)
	assert_true(high < low * 1.5, "spread %f..%f is wide enough to decide fights" % [low, high])


# --- aiming ---------------------------------------------------------------
#
# Attacks are aimed and can miss (docs/decisions/D07). These pin the properties
# that make a miss feel fair: you hit what you are facing and close to, you miss
# what is behind you or out of reach, and the boundaries are where the config
# says they are.

const NORTH := Vector3(0.0, 0.0, 1.0)


func test_an_attack_hits_what_is_directly_in_front() -> void:
	assert_true(MATH.in_hit_cone(Vector3.ZERO, NORTH, Vector3(0.0, 0.0, 2.0), 2.6, 90.0))


func test_an_attack_misses_what_is_out_of_reach() -> void:
	assert_false(MATH.in_hit_cone(Vector3.ZERO, NORTH, Vector3(0.0, 0.0, 4.0), 2.6, 90.0))


func test_an_attack_misses_what_is_behind_it() -> void:
	# The whole reason facing is a skill. If this passed, turning around would be
	# free and positioning would be decoration.
	assert_false(MATH.in_hit_cone(Vector3.ZERO, NORTH, Vector3(0.0, 0.0, -2.0), 2.6, 90.0))


func test_the_cone_edge_is_where_the_config_says_it_is() -> void:
	var inside := Vector3(1.0, 0.0, 1.05)   # a shade under 45 degrees off
	var outside := Vector3(1.0, 0.0, 0.95)  # a shade over
	assert_true(MATH.in_hit_cone(Vector3.ZERO, NORTH, inside, 2.6, 90.0), "just inside a 90 degree arc")
	assert_false(MATH.in_hit_cone(Vector3.ZERO, NORTH, outside, 2.6, 90.0), "just outside a 90 degree arc")


func test_a_wider_cone_forgives_more() -> void:
	var off_to_the_side := Vector3(1.4, 0.0, 1.0)
	assert_false(MATH.in_hit_cone(Vector3.ZERO, NORTH, off_to_the_side, 2.6, 60.0))
	assert_true(MATH.in_hit_cone(Vector3.ZERO, NORTH, off_to_the_side, 2.6, 120.0))


func test_height_does_not_decide_a_hit() -> void:
	# The fight happens on a hillside. Missing because the opponent is uphill,
	# with nothing on screen to explain it, is the least fair miss there is.
	var uphill := Vector3(0.0, 1.6, 2.0)
	assert_true(MATH.in_hit_cone(Vector3.ZERO, NORTH, uphill, 2.6, 90.0))


func test_standing_inside_something_always_connects() -> void:
	# Two overlapping creatures give a zero-length direction. Whiffing every
	# attack at point-blank range reads as the game being broken at exactly the
	# most frantic moment.
	assert_true(MATH.in_hit_cone(Vector3.ZERO, NORTH, Vector3.ZERO, 2.6, 90.0))


func test_the_shipped_quick_attack_can_actually_miss() -> void:
	# A forgiving cone is a design choice; a cone so wide it cannot miss is a
	# missing mechanic. This fails if player_quick is ever tuned past 180 or its
	# range past the arena.
	var quick: Dictionary = MATH.config().get("player_quick", {})
	var behind := Vector3(0.0, 0.0, -1.0)
	assert_false(MATH.move_connects(quick, Vector3.ZERO, NORTH, behind),
		"the shipped quick attack hits things behind it")


func test_the_shipped_enemy_attack_is_within_its_own_reach() -> void:
	# The opponent closes to `preferred_range` and swings from there. If that is
	# outside its own reach it stands just too far away and whiffs forever,
	# which looks exactly like broken AI.
	var enemy: Dictionary = MATH.config().get("enemy", {})
	var preferred := float(enemy.get("preferred_range", 2.1))
	var reach := float(enemy.get("range", 2.6))
	assert_true(preferred < reach,
		"enemy stops at %.2fm but only reaches %.2fm; it can never land a hit" % [preferred, reach])


# --- energy ---------------------------------------------------------------

func test_charged_is_refused_on_an_empty_meter() -> void:
	assert_false(MATH.can_use_charged(0.0))


func test_energy_accumulates_to_a_cap() -> void:
	var energy := 0.0
	for i in 20:
		energy = MATH.energy_after_quick(energy)
	assert_almost_eq(energy, MATH.max_energy(), 0.001, "energy should stop at the cap")


func test_a_charged_attack_is_reachable_in_a_sane_number_of_quicks() -> void:
	# The single most important number in the fight's feel. Too many and the
	# charged attack never happens; too few and it is only a better quick.
	var needed := MATH.quicks_to_charge()
	assert_between(float(needed), 2.0, 8.0, "takes %d quick attacks to charge" % needed)


func test_refused_charged_attack_spends_nothing() -> void:
	var before := MATH.charged_cost() - 1.0
	assert_almost_eq(MATH.energy_after_charged(before), before, 0.001)


func test_spending_a_charged_attack_empties_the_meter() -> void:
	assert_almost_eq(MATH.energy_after_charged(MATH.charged_cost()), 0.0, 0.001)


# --- creature state -------------------------------------------------------

func test_species_table_loads() -> void:
	assert_true(SPECIES.has("wild_rabbit"), "wild_rabbit should be defined")
	assert_true(SPECIES.has("starter_ground"), "starter_ground should be defined")


func test_unknown_species_returns_null_rather_than_a_broken_instance() -> void:
	assert_eq(SPECIES.spawn("does_not_exist"), null)


func test_a_spawned_creature_starts_whole() -> void:
	var pal: RefCounted = SPECIES.spawn("wild_rabbit")
	assert_eq(pal.hp, pal.max_hp)
	assert_eq(pal.energy, 0.0)
	assert_false(pal.fainted)
	assert_eq(pal.hp_fraction(), 1.0)


func test_two_creatures_of_one_species_have_independent_health() -> void:
	# The bug this guards: writing current HP onto shared species data gives
	# every creature of a species the same health bar.
	var a: RefCounted = SPECIES.spawn("wild_rabbit")
	var b: RefCounted = SPECIES.spawn("wild_rabbit")
	a.take_damage(30.0)
	assert_true(b.hp > a.hp, "damaging one rabbit must not damage the other")


func test_faint_is_reported_exactly_once() -> void:
	var pal: RefCounted = SPECIES.spawn("wild_rabbit")
	assert_false(pal.take_damage(1.0), "a survivable hit is not a faint")
	assert_true(pal.take_damage(9999.0), "the killing blow reports the faint")
	assert_false(pal.take_damage(9999.0), "hitting a fainted creature must not re-report")


func test_health_floors_at_zero() -> void:
	var pal: RefCounted = SPECIES.spawn("wild_rabbit")
	pal.take_damage(9999.0)
	assert_eq(pal.hp, 0.0)
	assert_eq(pal.hp_fraction(), 0.0)


func test_a_fainted_creature_cannot_use_a_charged_attack() -> void:
	var pal: RefCounted = SPECIES.spawn("starter_ground")
	pal.energy = MATH.max_energy()
	pal.take_damage(9999.0)
	assert_false(pal.can_use_charged(), "a fainted creature should not act")


func test_quick_attacks_charge_the_meter_and_charged_spends_it() -> void:
	var pal: RefCounted = SPECIES.spawn("starter_ground")
	assert_false(pal.can_use_charged())
	for i in MATH.quicks_to_charge():
		pal.gain_energy_from_quick()
	assert_true(pal.can_use_charged(), "should be chargeable after the expected quicks")
	assert_true(pal.spend_charged())
	assert_false(pal.can_use_charged(), "spending should empty the meter")


func test_healing_restores_a_fainted_creature() -> void:
	var pal: RefCounted = SPECIES.spawn("wild_rabbit")
	pal.take_damage(9999.0)
	pal.heal_fully()
	assert_eq(pal.hp, pal.max_hp)
	assert_false(pal.fainted)
