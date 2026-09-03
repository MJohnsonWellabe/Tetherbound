extends "res://tests/test_case.gd"

## The reported "interact works about half the time", pinned at its mechanism.
##
## `harvest_node.gd::_on_gathered()` hands a tool press to
## `harvest_logic.gd::swing_answers_the_prompt()`, which asks `tool_hold.gd::
## swing_at()` to swing at the node the player actually pressed. When a swing
## was ALREADY running, that used to be answered "yes, the running swing will
## gather something itself" -- and `_resolve_swing()` resolves against the
## swing's own `_swing_target`, which is whatever the PREVIOUS press aimed it
## at, or (for an unaimed `use_tool` swing) whatever a cone search finds
## nearest. Neither is necessarily the node under the player's thumb. So the
## press was answered by a swing that hit something else, or nothing, and the
## node the player was standing at yielded nothing at all.
##
## Reproduced in-container 2026-09-03 by `smoke_gate_b_continuous` (run 2 of 3,
## axe equipped and in hand, arbiter winner the node's own Interactable,
## `cooling=false`, and no swing started). Run 1 of the same commit passed the
## same step, which is the "about half the time".
##
## What this file pins is the RULE, at the impact frame, because that is what
## decides whether the running swing can still be spent. It instantiates the
## real `tool_hold.gd` and calls the real `swing_at()`; the swing timing is
## driven by hand rather than by `_process`, so the assertions are about the
## rule and not about a frame budget.

const TOOL_HOLD := preload("res://scripts/player/tool_hold.gd")


func _hold_with_an_axe() -> Node3D:
	var hold := Node3D.new()
	hold.set_script(TOOL_HOLD)
	# `swing()` refuses on an empty hand, which is a different refusal from the
	# one under test, so put something in it. Set directly: equipping for real
	# wants the item database and a bone attachment, and neither is what this
	# file is about.
	hold.set("_equipped", "axe")
	return hold


func _a_node(name_hint: String) -> Node3D:
	var node := Node3D.new()
	node.name = name_hint
	return node


func test_an_idle_hand_swings_at_the_node_that_was_pressed() -> void:
	var hold := _hold_with_an_axe()
	var bush := _a_node("Bush")
	assert_true(bool(hold.call("swing_at", bush)), "an idle hand should take the swing")
	assert_true(bool(hold.call("is_swinging")), "the swing should be running")
	assert_eq(hold.call("swing_target"), bush, "the swing should be aimed at the pressed node")
	bush.free()
	hold.free()


## The re-aim. A second press before the impact frame belongs to the newer
## press: the player is looking at THIS node now.
func test_a_press_before_the_impact_re_aims_the_running_swing() -> void:
	var hold := _hold_with_an_axe()
	var first := _a_node("Tree")
	var second := _a_node("Bush")
	hold.call("swing_at", first)
	assert_false(bool(hold.get("_swing_resolved")), "the swing has not hit yet")

	assert_true(bool(hold.call("swing_at", second)),
		"a press before the impact should be taken, not dropped")
	assert_eq(hold.call("swing_target"), second,
		"the running swing should now be aimed at the node just pressed")
	first.free()
	second.free()
	hold.free()


## The refusal that matters. Once the swing has hit, it cannot gather again --
## so claiming the press would lose it. `swing_at()` says no, and
## `harvest_node.gd::_on_gathered()` answers the press with its direct yield.
## This is the case that used to return true and silently swallow the press.
func test_a_press_after_the_impact_is_refused_so_the_caller_can_answer_it() -> void:
	var hold := _hold_with_an_axe()
	var first := _a_node("Tree")
	var second := _a_node("Bush")
	hold.call("swing_at", first)
	# The impact frame, reached the way `_process` reaches it.
	hold.set("_swing_resolved", true)
	assert_true(bool(hold.call("is_swinging")), "the swing is still playing out its tail")

	assert_false(bool(hold.call("swing_at", second)),
		"a spent swing must not claim the press -- refusing is what lets the "
		+ "node's own gather answer it instead")
	first.free()
	second.free()
	hold.free()


## The one thing the old short-circuit was protecting against, still protected:
## the press is never answered twice.
func test_the_pressed_node_is_the_only_thing_the_swing_is_aimed_at() -> void:
	var hold := _hold_with_an_axe()
	var first := _a_node("Tree")
	var second := _a_node("Bush")
	hold.call("swing_at", first)
	hold.call("swing_at", second)
	assert_ne(hold.call("swing_target"), first,
		"the earlier target must be dropped, or one swing would owe two nodes")
	first.free()
	second.free()
	hold.free()


func test_an_empty_hand_still_refuses() -> void:
	var hold := Node3D.new()
	hold.set_script(TOOL_HOLD)
	var bush := _a_node("Bush")
	assert_false(bool(hold.call("swing_at", bush)), "nothing in hand, nothing to swing")
	bush.free()
	hold.free()
