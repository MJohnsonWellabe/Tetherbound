extends "res://tests/test_case.gd"

## A wild creature's "Engage" offer competes with every other prompt on
## distance (prompt_arbiter.gd: priority, then nearest). Harvest prompts are
## points at a trunk or rock; a creature is a body. Measured to the creature's
## CENTRE, a player standing beside a creature that idles against a tree was
## offered "Chop" instead of "Engage" from most bearings -- the batch-6 CI run of
## smoke_catch_respawn_fresh_individual lost the engage offer on all 80 staged
## seats to a tree's Chop prompt. The engage offer is measured to the body's
## surface, the part of the creature the player is actually next to.

const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const ARBITER := preload("res://scripts/world/prompt_arbiter.gd")


func test_engage_distance_is_measured_to_the_body_surface() -> void:
	var from := Vector3.ZERO
	var centre := Vector3(2.4, 0.0, 0.0)
	assert_almost_eq(float(DIRECTOR.engage_offer_distance(from, centre, 0.7)), 1.7, 0.0001)
	assert_almost_eq(float(DIRECTOR.engage_offer_distance(from, Vector3(0.3, 0.0, 0.0), 0.7)), 0.0, 0.0001,
		"never negative inside the body")


func test_a_creature_beside_a_tree_wins_over_the_trees_chop_prompt() -> void:
	# Player 2.4 m from a 0.7 m-radius creature's centre; the tree's Chop point
	# 2.0 m away. The player is 1.7 m from the creature itself.
	var engage := ARBITER.offer("Engage Bramblebun",
		float(DIRECTOR.engage_offer_distance(Vector3.ZERO, Vector3(2.4, 0.0, 0.0), 0.7)))
	var chop := ARBITER.offer("Chop", 2.0)
	var offers: Array = [chop, engage]
	var winner := int(ARBITER.choose_index(offers))
	assert_eq(winner, 1, "the creature the player stands beside wins the prompt")
	# A tree genuinely nearer than the creature's surface still wins.
	var near_chop := ARBITER.offer("Chop", 1.0)
	var closer: Array = [near_chop, engage]
	assert_eq(int(ARBITER.choose_index(closer)), 0, "a nearer tree keeps its prompt")
