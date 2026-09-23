extends "res://tests/test_case.gd"

## The wild creature's decision table.
##
## These are the questions the owner will actually ask about the opponent —
## "it never lets up", "it backs off too far", "it hits me the instant I finish
## attacking" — asked here rather than by playing a fight and squinting.
##
## They pin BEHAVIOUR, not timings. The durations are tuning and will move; that
## a committed wind-up cannot be cancelled is a rule.

const AI := preload("res://scripts/combat/combat_ai.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")

var cfg: Dictionary = {}


func before_each() -> void:
	cfg = MATH.config().get("enemy", {})


# --- closing --------------------------------------------------------------

func test_it_walks_in_when_out_of_range() -> void:
	assert_eq(AI.decide(AI.Intent.CLOSE, 8.0, 0.0, 0.0, cfg), AI.Intent.CLOSE)


func test_it_attacks_once_it_is_close_and_off_cooldown() -> void:
	assert_eq(AI.decide(AI.Intent.CLOSE, 1.0, 0.0, 0.0, cfg), AI.Intent.TELEGRAPH)


func test_it_keeps_closing_while_its_attack_is_on_cooldown() -> void:
	# Without this it would stand in your face doing nothing, which reads as the
	# AI having crashed.
	assert_eq(AI.decide(AI.Intent.CLOSE, 1.0, 0.0, 0.8, cfg), AI.Intent.CLOSE)


# --- commitment -----------------------------------------------------------

func test_a_windup_cannot_be_cancelled() -> void:
	# The telegraph is the fight's only warning. An opponent that can abort its
	# own wind-up makes the warning worthless and every hit feel unfair.
	assert_eq(AI.decide(AI.Intent.TELEGRAPH, 99.0, 0.3, 0.0, cfg), AI.Intent.TELEGRAPH,
		"a wind-up must run to completion even if the target walks away")


func test_a_finished_windup_becomes_recovery() -> void:
	assert_eq(AI.decide(AI.Intent.TELEGRAPH, 1.0, 0.0, 0.0, cfg), AI.Intent.RECOVER)


func test_recovery_cannot_be_cut_short() -> void:
	# This window is the player's entire reason to watch what the opponent is
	# doing instead of mashing.
	assert_eq(AI.decide(AI.Intent.RECOVER, 1.0, 0.2, 0.0, cfg), AI.Intent.RECOVER)


func test_it_backs_off_after_recovering_rather_than_swinging_again() -> void:
	# Recover straight into another attack and the fight is two creatures
	# standing in each other's faces trading hits, which is the static fight
	# this whole model replaced.
	assert_eq(AI.decide(AI.Intent.RECOVER, 1.0, 0.0, 0.0, cfg), AI.Intent.REPOSITION)


func test_it_comes_back_after_repositioning() -> void:
	assert_eq(AI.decide(AI.Intent.REPOSITION, 6.0, 0.0, 0.0, cfg), AI.Intent.CLOSE)


# --- rooting --------------------------------------------------------------

func test_it_is_rooted_while_winding_up_and_recovering() -> void:
	assert_true(AI.is_rooted(AI.Intent.TELEGRAPH))
	assert_true(AI.is_rooted(AI.Intent.RECOVER))


func test_it_is_mobile_while_closing_and_repositioning() -> void:
	assert_false(AI.is_rooted(AI.Intent.CLOSE))
	assert_false(AI.is_rooted(AI.Intent.REPOSITION))


# --- movement -------------------------------------------------------------

func test_closing_moves_towards_the_target() -> void:
	var towards := Vector3(0.0, 0.0, 4.0)
	var move: Vector3 = AI.movement_for(AI.Intent.CLOSE, towards, 1.0)
	assert_true(move.dot(towards.normalized()) > 0.9, "closing should go straight in")


func test_repositioning_moves_away_and_sideways() -> void:
	var towards := Vector3(0.0, 0.0, 4.0)
	var move: Vector3 = AI.movement_for(AI.Intent.REPOSITION, towards, 1.0)
	assert_true(move.dot(towards.normalized()) < 0.0, "repositioning should give ground")
	assert_true(absf(move.x) > 0.3, "a straight retreat is a rubber band; it should arc")


func test_the_circling_direction_actually_flips() -> void:
	var towards := Vector3(0.0, 0.0, 4.0)
	var left: Vector3 = AI.movement_for(AI.Intent.REPOSITION, towards, 1.0)
	var right: Vector3 = AI.movement_for(AI.Intent.REPOSITION, towards, -1.0)
	assert_true(left.x * right.x < 0.0, "the two reposition directions should be opposites")


func test_a_rooted_creature_does_not_move() -> void:
	var towards := Vector3(0.0, 0.0, 4.0)
	assert_eq(AI.movement_for(AI.Intent.TELEGRAPH, towards, 1.0), Vector3.ZERO)
	assert_eq(AI.movement_for(AI.Intent.RECOVER, towards, 1.0), Vector3.ZERO)
	assert_almost_eq(AI.speed_for(AI.Intent.TELEGRAPH, cfg), 0.0, 0.001)
	assert_almost_eq(AI.speed_for(AI.Intent.RECOVER, cfg), 0.0, 0.001)


func test_movement_survives_standing_on_top_of_the_target() -> void:
	assert_eq(AI.movement_for(AI.Intent.CLOSE, Vector3.ZERO, 1.0), Vector3.ZERO)


# --- the shipped numbers --------------------------------------------------

func test_the_opponent_can_be_outrun() -> void:
	# Movement is the dodge (D07). If the opponent is faster than the player's
	# creature, backing away is impossible and the dodge does not exist.
	var creature_speed := float(MATH.config().get("creature_movement", {}).get("speed", 5.0))
	var chase := float(cfg.get("chase_speed", 4.6))
	assert_true(chase < creature_speed,
		"the opponent chases at %.2f against a creature speed of %.2f; it cannot be escaped" % [chase, creature_speed])


func test_there_is_a_punish_window() -> void:
	# The recovery has to be long enough to walk in and land a quick attack, or
	# watching the opponent buys the player nothing.
	var recovery := float(cfg.get("recovery", 0.75))
	var quick: Dictionary = MATH.config().get("player_quick", {})
	var to_land := float(quick.get("windup", 0.18))
	assert_true(recovery > to_land,
		"recovery of %.2fs is shorter than a %.2fs wind-up; there is nothing to punish" % [recovery, to_land])
