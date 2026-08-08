extends "res://tests/test_case.gd"

## What a fight PAYS, and who the fight is fought by.
##
## Both halves of this file exist because of the same failure, twice. M4 shipped
## `pal_instance.grant_xp()` with a level curve, per-level stat growth, a cap and
## six passing unit tests — and no caller anywhere in `scripts/`, so every pal in
## a real session stayed at level 1 forever. It shipped `combat_switch_left` and
## `combat_switch_right` bound in project.godot with a comment reserving them,
## and nothing read either one. Both systems were green and inert at the same
## time.
##
## So these tests are pointed at the WIRING rather than at the arithmetic:
## does a win reach `grant_xp`, does the amount come out of the config, does a
## switch move the same `active_index` the party menu writes. The tuning is
## deliberately tested for SHAPE — a tougher creature pays more, a catch pays
## less than a kill — so rebalancing party.json does not turn the suite red.
##
## `Switchboard` and the reward functions are both reachable without a scene,
## which is the point of where they live. docs/decisions/D02 scopes this runner
## to pure logic; a fight in a real world is tests/smoke_combat.gd's job.

const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const PARTY := preload("res://scripts/pals/party.gd")
const SPECIES := preload("res://scripts/pals/pal_species.gd")
const INSTANCE := preload("res://scripts/pals/pal_instance.gd")

const MINE := "starter_ground"
const WEAK := "wild_rabbit"
const TOUGH := "wild_bristler"


## A pal with no trait, so a random roll cannot move a number being asserted.
## test_party.gd explains this at length; same reasoning.
func _pal(id: String = MINE) -> RefCounted:
	var pal: RefCounted = SPECIES.spawn(id)
	pal.assign_trait("")
	return pal


## The reward table the game actually ships.
func _config() -> Dictionary:
	return INSTANCE.config().get("rewards", {})


## A reward table with every scaling term switched OFF, so an award is exactly
## `win_base` and a wrong number cannot hide behind an exponent.
func _flat_config(win_base: float, stat_total: float) -> Dictionary:
	return {
		"win_base": win_base,
		"level_exponent": 1.0,
		"reference_stat_total": stat_total,
		"level_difference_step": 0.0,
		"level_difference_min": 1.0,
		"level_difference_max": 1.0,
		"caught_fraction": 0.5,
		"bench_fraction": 0.25,
		"minimum": 1,
	}


func _stat_total(pal: RefCounted) -> float:
	return pal.base_hp + pal.base_attack + pal.base_defence


## The director as a bare object. It is a Node, but `award_xp()` takes everything
## it needs as arguments and touches nothing in the tree, so no scene is needed
## to prove the payout — which is exactly why the payout lives there and not
## inside `_on_combat_exited`.
func _director() -> Node:
	return DIRECTOR.new()


func _party_of(count: int) -> RefCounted:
	var party: RefCounted = PARTY.new()
	for i in count:
		var pal := _pal()
		pal.rename("member_%d" % i)
		party.add(pal)
	return party


# --- what a win is worth --------------------------------------------------

func test_the_award_comes_out_of_the_config_and_not_out_of_the_code() -> void:
	# The config is handed IN, so this asserts the number was read rather than
	# written down. A hardcoded award passes nothing here.
	var defeated := _pal(WEAK)
	var mine := _pal()
	var cfg := _flat_config(100.0, _stat_total(defeated))
	assert_eq(DIRECTOR.xp_for_defeating(defeated, mine, false, cfg), 100)

	cfg["win_base"] = 250.0
	assert_eq(DIRECTOR.xp_for_defeating(defeated, mine, false, cfg), 250,
		"changing win_base in the config did not change the award")


func test_a_win_pays_something_under_the_shipping_config() -> void:
	# The flat table above proves the arithmetic; this proves the table the game
	# loads is not empty, mistyped or missing its block.
	var award: int = DIRECTOR.xp_for_defeating(_pal(WEAK), _pal(), false, _config())
	assert_true(award > 0, "beating a wild pal paid %d XP under the shipping config" % award)


func test_a_tougher_creature_is_worth_more_than_a_weaker_one() -> void:
	# Nothing sets wild levels yet, so species weight is the ONLY thing that can
	# make one fight worth more than another. If this ever collapses, every fight
	# in the Meadows pays the same and §27's rising danger has nothing to say.
	var mine := _pal()
	var cfg := _config()
	var hopper: int = DIRECTOR.xp_for_defeating(_pal(WEAK), mine, false, cfg)
	var thornback: int = DIRECTOR.xp_for_defeating(_pal(TOUGH), mine, false, cfg)
	assert_true(thornback > hopper,
		"the Thornback (%d XP) is worth no more than the Meadow Hopper (%d XP)" % [thornback, hopper])


func test_punching_up_pays_more_and_punching_down_pays_less() -> void:
	# Inert today — every wild pal is level 1 — and asserted anyway, because the
	# term is in the formula now and a sign error in it would only be discovered
	# by a biome that does not exist yet.
	var mine := _pal()
	mine.set_level(10)
	var cfg := _config()

	var even := _pal(WEAK)
	even.set_level(10)
	var above := _pal(WEAK)
	above.set_level(16)
	var below := _pal(WEAK)
	below.set_level(4)

	var level_award: int = DIRECTOR.xp_for_defeating(even, mine, false, cfg)
	assert_true(DIRECTOR.xp_for_defeating(above, mine, false, cfg) > level_award,
		"a stronger opponent paid no more than an even one")
	assert_true(DIRECTOR.xp_for_defeating(below, mine, false, cfg) < level_award,
		"a weaker opponent paid as much as an even one")


func test_a_catch_pays_less_than_a_kill_and_more_than_nothing() -> void:
	# §15 and D08: catching already costs orbs, a weakened target and seconds of
	# your pal standing undefended, and the creature is the reward. Paying zero
	# would still make killing the pals you want to keep the fastest way to level.
	var defeated := _pal(WEAK)
	var mine := _pal()
	var cfg := _config()
	var won: int = DIRECTOR.xp_for_defeating(defeated, mine, false, cfg)
	var caught: int = DIRECTOR.xp_for_defeating(defeated, mine, true, cfg)
	assert_true(caught > 0, "a catch paid nothing at all")
	assert_true(caught < won, "a catch (%d) paid as much as a kill (%d)" % [caught, won])


func test_the_pals_that_watched_are_paid_less_than_the_one_that_fought() -> void:
	var cfg := _config()
	var share: int = DIRECTOR.xp_for_watching(100, cfg)
	assert_true(share > 0, "the rest of the party was paid nothing; four of five pals fall out of the game")
	assert_true(share < 100, "watching paid as much as fighting; deploying is not a choice")


# --- the win path actually pays -------------------------------------------

func test_winning_pays_the_deployed_pal_and_the_bench_at_the_share() -> void:
	var director := _director()
	var party := _party_of(3)
	var deployed: RefCounted = party.at(0)
	var bench_one: RefCounted = party.at(1)
	var bench_two: RefCounted = party.at(2)
	var defeated := _pal(WEAK)

	var paid: Array = []
	director.connect("xp_awarded", func(pal: RefCounted, amount: int, was_deployed: bool) -> void:
		paid.append({"pal": pal, "amount": amount, "deployed": was_deployed}))

	var expected: int = DIRECTOR.xp_for_defeating(defeated, deployed, false, _config())
	var expected_share: int = DIRECTOR.xp_for_watching(expected, _config())

	director.call("award_xp", defeated, party.members(), deployed, false)

	assert_eq(deployed.xp, expected, "the pal that fought was not paid the award")
	assert_eq(bench_one.xp, expected_share, "the bench was not paid its share")
	assert_eq(bench_two.xp, expected_share, "the bench was not paid its share")
	assert_eq(paid.size(), 3, "the payout was not announced once per pal")
	assert_true(bool((paid[0] as Dictionary)["deployed"]),
		"the pal that fought was not announced as the deployed one")
	director.free()


func test_a_fainted_party_member_is_paid_nothing() -> void:
	var director := _director()
	var party := _party_of(2)
	var deployed: RefCounted = party.at(0)
	var down: RefCounted = party.at(1)
	down.take_damage(down.max_hp * 2.0)
	assert_true(down.fainted, "the test could not knock the bench pal out")

	director.call("award_xp", _pal(WEAK), party.members(), deployed, false)
	assert_eq(down.xp, 0, "a fainted pal was paid for a fight it was not in")
	assert_true(deployed.xp > 0, "the pal that fought was not paid")
	director.free()


func test_a_creature_caught_in_the_fight_is_not_paid_for_its_own_capture() -> void:
	var director := _director()
	var party := _party_of(1)
	var deployed: RefCounted = party.at(0)
	var newcomer := _pal(WEAK)
	# The roster as it stood when the fight ended — before `_keep()` put the
	# caught creature in it. If the director ever snapshots the party after the
	# catch instead, this is what catches it.
	var roster: Array = party.members()
	party.add(newcomer)

	director.call("award_xp", newcomer, roster, deployed, true)
	assert_eq(newcomer.xp, 0, "the caught creature was paid for being caught")
	assert_true(deployed.xp > 0, "the pal that weakened it was not paid")
	director.free()


func test_enough_xp_levels_the_deployed_pal_and_its_stats_change() -> void:
	# The whole reason any of this exists. A level that does not change the
	# creature is a number going up beside a pal that has not.
	var director := _director()
	var party := _party_of(1)
	var deployed: RefCounted = party.at(0)
	var hp_before: float = deployed.max_hp
	var attack_before: float = deployed.attack
	var defence_before: float = deployed.defence

	var levels: Array = []
	director.connect("pal_levelled", func(pal: RefCounted, level: int, gained: int) -> void:
		levels.append({"pal": pal, "level": level, "gained": gained}))

	# Fight until the level arrives rather than granting a made-up lump, so this
	# measures the actual award against the actual curve. The ceiling is a guard
	# against a reward of zero looping forever, not an expected count.
	var fights := 0
	while deployed.level == 1 and fights < 200:
		director.call("award_xp", _pal(TOUGH), party.members(), deployed, false)
		fights += 1

	assert_eq(deployed.level, 2, "%d wins did not buy a single level" % fights)
	assert_true(fights <= 12, "it took %d wins to reach level 2; the curve and the award disagree" % fights)
	assert_eq(levels.size(), 1, "the level-up was not announced exactly once")
	assert_eq(int((levels[0] as Dictionary)["level"]), 2)
	assert_true(deployed.max_hp > hp_before, "levelling did not raise max HP")
	assert_true(deployed.attack > attack_before, "levelling did not raise attack")
	assert_true(deployed.defence > defence_before, "levelling did not raise defence")
	director.free()


func test_a_capped_pal_gains_no_more_levels_and_is_told_nothing() -> void:
	var director := _director()
	var party := _party_of(1)
	var deployed: RefCounted = party.at(0)
	deployed.set_level(INSTANCE.level_cap())

	var announcements := 0
	director.connect("xp_awarded", func(_pal_ref: RefCounted, _amount: int, _deployed: bool) -> void:
		announcements += 1)

	for i in 25:
		director.call("award_xp", _pal(TOUGH), party.members(), deployed, false)

	assert_eq(deployed.level, INSTANCE.level_cap(), "a capped pal gained a level")
	assert_eq(deployed.xp, 0, "a capped pal is accumulating progress towards a level it cannot reach")
	assert_eq(announcements, 0, "a capped pal was told it had gained XP that went nowhere")
	director.free()


# --- switching ------------------------------------------------------------
#
# Against a real party.gd, because the thing being proved is that the fight and
# the party menu write the SAME index. A stand-in party here would prove nothing.

func _board() -> RefCounted:
	var board: RefCounted = MANAGER.Switchboard.new()
	board.configure({"cooldown": 4.0})
	return board


func test_switching_moves_the_deployed_pal_and_the_party_index_together() -> void:
	var party := _party_of(3)
	var board := _board()
	var was: RefCounted = party.active()

	assert_eq(board.switch(party, 1), 1, "a switch forward did not land on the next slot")
	assert_eq(party.active_index, 1, "the party's own index did not move")
	assert_eq(party.active(), party.at(1), "the party is deploying a different pal than it is pointing at")
	assert_ne(party.active(), was, "the switch left the same creature deployed")


func test_switching_backwards_walks_the_other_way() -> void:
	var party := _party_of(3)
	var board := _board()
	assert_eq(board.switch(party, -1), 2, "a switch backwards from the first slot should wrap to the last")
	assert_eq(party.active_index, 2)


func test_a_fainted_pal_is_never_switched_to() -> void:
	# §16: a fainted pal is unavailable. Deploying one mid-fight is a switch that
	# loses the fight for you.
	var party := _party_of(3)
	(party.at(1) as RefCounted).take_damage((party.at(1) as RefCounted).max_hp * 2.0)
	var board := _board()

	assert_eq(board.switch(party, 1), 2, "the switch landed on the fainted pal instead of stepping over it")
	assert_eq(party.active_index, 2)
	assert_false((party.active() as RefCounted).fainted, "an unconscious creature was deployed")


func test_a_switch_with_nobody_left_standing_is_refused() -> void:
	var party := _party_of(2)
	(party.at(1) as RefCounted).take_damage((party.at(1) as RefCounted).max_hp * 2.0)
	var board := _board()

	assert_eq(board.refusal(party, 1), MANAGER.Switchboard.REFUSED_ALL_DOWN)
	assert_eq(board.switch(party, 1), -1, "a switch to a fainted-only party went through")
	assert_eq(party.active_index, 0, "a refused switch moved the deployed pal anyway")


func test_switching_with_one_pal_is_refused_rather_than_looking_like_it_worked() -> void:
	# Wrapping back onto the same creature would be a button that appears to work
	# and changes nothing, which is worse than a button that says no.
	var party := _party_of(1)
	var board := _board()

	assert_eq(board.refusal(party, 1), MANAGER.Switchboard.REFUSED_ALONE)
	assert_eq(board.switch(party, 1), -1, "a one-pal party switched")
	assert_eq(party.active_index, 0)


func test_an_empty_party_refuses_rather_than_crashing() -> void:
	var board := _board()
	assert_eq(board.refusal(PARTY.new(), 1), MANAGER.Switchboard.REFUSED_ALONE)
	assert_eq(board.refusal(null, 1), MANAGER.Switchboard.REFUSED_NO_PARTY)


func test_the_cooldown_blocks_a_second_immediate_switch() -> void:
	# §14: "Switching has a cooldown." Without it the correct play is to swap
	# every time the opponent commits, and the party stops being five creatures
	# and becomes one health bar with five segments.
	var party := _party_of(3)
	var board := _board()

	assert_eq(board.switch(party, 1), 1)
	assert_eq(board.refusal(party, 1), MANAGER.Switchboard.REFUSED_COOLING)
	assert_eq(board.switch(party, 1), -1, "a second switch went through on the same frame")
	assert_eq(party.active_index, 1, "a switch refused by the cooldown moved the party anyway")

	board.tick(1.0)
	assert_eq(board.switch(party, 1), -1, "the cooldown expired early")

	board.tick(3.0)
	assert_true(board.ready(), "the cooldown never ran down")
	assert_eq(board.switch(party, 1), 2, "the switch never became available again")
	assert_eq(party.active_index, 2)


func test_the_cooldown_length_comes_from_the_config() -> void:
	var board: RefCounted = MANAGER.Switchboard.new()
	board.configure({"cooldown": 9.0})
	var party := _party_of(2)
	board.switch(party, 1)
	board.tick(8.0)
	assert_false(board.ready(), "the board ignored the configured cooldown and used its own")
	board.tick(1.0)
	assert_true(board.ready())


func test_a_fight_opens_with_the_cooldown_ready() -> void:
	# Otherwise the first switch of a fight is refused for a reason that belongs
	# to the previous one.
	var board := _board()
	board.switch(_party_of(2), 1)
	assert_false(board.ready())
	board.configure({"cooldown": 4.0})
	assert_true(board.ready(), "a new fight began with the last fight's cooldown still running")
