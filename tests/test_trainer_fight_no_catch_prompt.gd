extends "res://tests/test_case.gd"

## Hard rule: catch only during wild combat, never trainer-owned creatures.
## A trainer duel showed "F Aim · 43 orbs" (captures F03#1 r10). The throw was
## already refused; the HUD must not offer it either.
const HUD := preload("res://scripts/ui/combat_hud.gd")
const CATCH := preload("res://scripts/combat/catch_math.gd")


func test_a_trainer_owned_target_shows_no_catch_prompt_and_refuses_the_throw() -> void:
	var owned := HUD.action_hint("F", 43, "Q", "R", false)
	assert_false(owned.contains("Aim") or owned.contains("orbs"), "no catch prompt in a trainer fight: " + owned)
	assert_true(owned.contains("Switch") and owned.contains("Flee"))
	assert_true(HUD.action_hint("F", 43, "Q", "R", true).contains("Aim · 43 orbs"), "wild fights keep the prompt")
	assert_false(CATCH.can_be_caught(false, true), "a trainer-owned creature can never be caught")
	assert_true(CATCH.can_be_caught(false, false), "a standing wild creature can")
