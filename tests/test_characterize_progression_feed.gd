extends "res://tests/test_case.gd"

## STAGE B 0.E — characterization fence for scripts/creatures/progression_feed.gd.
##
## Pins what the file DOES today, ahead of Wave 1's 1.B re-homing it onto
## `PlayerState`. This is not a redesign review: where the code's actual
## behaviour is surprising (drain() vs epoch(), clear()'s epoch bump), the
## test pins the surprising behaviour and says so, rather than the behaviour
## that would look more consistent. See docs/specs/STAGE_B_MULTIPLAYER_EXECUTION_PLAN.md
## Wave 0 row 0.E / Wave 1 row 1.B.
##
## The feed is `static` (module-level Godot singleton state), so every test
## calls FEED.clear() in before_each -- the file's own reset contract -- to
## start from a known state without depending on run order.

const FEED := preload("res://scripts/creatures/progression_feed.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}


func before_each() -> void:
	FEED.clear()


func _creature() -> RefCounted:
	return CREATURE.from_species("terrapup", DEFINITION)


# --- push / latest_seq / revision -------------------------------------------

func test_push_increments_latest_seq_and_revision_by_one_per_event() -> void:
	assert_eq(FEED.latest_seq(), 0, "sanity: clear() leaves seq at zero")
	var rev0 := FEED.revision()
	var e1 := FEED.push("xp_gained", null, {"amount": 1})
	assert_eq(int(e1.get("seq", -1)), 1, "the first push after clear() is seq 1")
	assert_eq(FEED.latest_seq(), 1)
	assert_eq(FEED.revision(), rev0 + 1, "one push is exactly one revision bump")
	FEED.push("xp_gained", null, {"amount": 1})
	assert_eq(FEED.latest_seq(), 2, "seq keeps climbing across pushes")
	assert_eq(FEED.revision(), rev0 + 2)


func test_push_stamps_kind_seq_creature_id_name_and_species_on_the_stored_event() -> void:
	var c := _creature()
	c.nickname = "Tup"
	var event := FEED.push("xp_gained", c, {"amount": 7})
	assert_eq(str(event.get("kind", "")), "xp_gained")
	assert_eq(int(event.get("creature_id", 0)), c.get_instance_id())
	assert_eq(str(event.get("name", "")), "Tup", "name comes from the creature's own label()")
	assert_eq(str(event.get("species_id", "")), "terrapup")
	assert_eq(int(event.get("amount", 0)), 7, "the caller's own payload survives untouched")


func test_push_with_a_null_creature_still_stores_the_event_using_the_payload_name() -> void:
	# The team-wide reward receipt has no individual creature (the file's own
	# header comment on `reward_summary`).
	var event := FEED.push("reward_summary", null, {"name": "Team", "receipt": "x"})
	assert_eq(int(event.get("creature_id", -1)), 0)
	assert_eq(str(event.get("name", "")), "Team")
	assert_eq(str(event.get("species_id", "")), "")


# --- peek_since --------------------------------------------------------------

func test_peek_since_returns_only_strictly_newer_events_oldest_first_and_does_not_consume() -> void:
	FEED.push("xp_gained", null, {"tag": "a"})
	var cursor := FEED.latest_seq()
	FEED.push("xp_gained", null, {"tag": "b"})
	FEED.push("xp_gained", null, {"tag": "c"})
	var newer := FEED.peek_since(cursor)
	assert_eq(newer.size(), 2, "only the two events pushed after the cursor")
	assert_eq(str(newer[0].get("tag", "")), "b", "oldest of the newer events first")
	assert_eq(str(newer[1].get("tag", "")), "c")
	assert_eq(FEED.events().size(), 3, "peeking must not drain")
	assert_eq(FEED.peek_since(FEED.latest_seq()).size(), 0, "nothing newer than the newest seq")


func test_peek_since_hands_back_copies_not_the_stored_dictionary() -> void:
	FEED.push("xp_gained", null, {"context": {"route": "trial"}})
	var seen := FEED.peek_since(0)
	seen[0].context.route = "mutated"
	assert_eq(str(FEED.events()[0].context.route), "trial",
		"a reader mutating its own copy must not corrupt the stored event")


# --- drain: empties, bumps REVISION -- does NOT touch epoch() ---------------
#
# The plan's own Wave 0 row describes this as "drain() empties and bumps
# epoch()". Reading the file: drain() increments `_revision`, and nothing in
# it touches `_epoch` -- only clear() does that. Pinning the ACTUAL behaviour
# per this file's own instruction ("pin what it does, not what seems right").
# See '## Findings for Wave 1' in the report.

func test_drain_empties_the_log_and_returns_what_was_in_it() -> void:
	FEED.push("xp_gained", null, {"tag": "a"})
	FEED.push("bond_credit", null, {"tag": "b"})
	var drained := FEED.drain()
	assert_eq(drained.size(), 2)
	assert_eq(FEED.events().size(), 0, "the live log is now empty")


func test_drain_bumps_revision_but_leaves_epoch_and_seq_untouched() -> void:
	FEED.push("xp_gained", null, {})
	var seq_before := FEED.latest_seq()
	var epoch_before := FEED.epoch()
	var rev_before := FEED.revision()
	FEED.drain()
	assert_eq(FEED.revision(), rev_before + 1, "drain is a change a revision-poller must see")
	assert_eq(FEED.epoch(), epoch_before,
		"drain does NOT bump epoch today -- only clear() does; a presenter cursor is not invalidated by a drain")
	assert_eq(FEED.latest_seq(), seq_before, "drain does not reset the sequence counter")


# --- clear: resets seq/revision to zero, and DOES bump epoch ----------------

func test_clear_resets_seq_and_revision_to_zero_and_empties_the_log() -> void:
	FEED.push("xp_gained", null, {})
	FEED.push("xp_gained", null, {})
	FEED.clear()
	assert_eq(FEED.latest_seq(), 0)
	assert_eq(FEED.revision(), 0)
	assert_eq(FEED.events().size(), 0)


func test_clear_bumps_epoch_so_a_reused_seq_cannot_replay_old_presentation_cursors() -> void:
	FEED.push("xp_gained", null, {})
	var epoch_before := FEED.epoch()
	FEED.clear()
	assert_true(FEED.epoch() > epoch_before, "clear() is the new-game reset; epoch must move")
	FEED.push("xp_gained", null, {})
	assert_eq(FEED.latest_seq(), 1, "seq legitimately restarts at 1 after clear -- this is exactly why epoch exists")


# --- xp_remaining / xp_near / xp_fraction: real data/config/progression.json numbers ---
#
# Real curve (data/config/progression.json, read 2026-09-05): xp_to_next_base
# 40, xp_to_next_exponent 1.15, cap 50. xp_award base 30, per_enemy_level 16.
# progression_feedback.json's near.xp_fights is 1.0.
#   xp_to_next(1)  = floor(40 * 1^1.15)  = 40
#   xp_to_next(5)  = floor(40 * 5^1.15)  = 254
#   xp_award_for(1) = 30 + 16*1 = 46
#   xp_award_for(5) = 30 + 16*5 = 110

func test_xp_remaining_is_needed_minus_current_xp_against_the_real_curve() -> void:
	var cfg := PROGRESSION.config()
	var c := _creature()
	c.set_level(5, cfg)
	assert_eq(int(c.call("xp_to_next", cfg)), 254, "sanity: the shipped curve at level 5")
	c.xp = 200
	assert_eq(FEED.xp_remaining(c, cfg), 54)
	c.xp = 0
	assert_eq(FEED.xp_remaining(c, cfg), 254)


func test_xp_near_uses_one_level_matched_wild_win_against_the_real_curve() -> void:
	var cfg := PROGRESSION.config()
	var c := _creature()
	c.set_level(1, cfg)
	# Level 1 costs 40 xp; one level-matched win pays 46 -- always near at L1.
	assert_true(FEED.xp_near(c, cfg), "the first level is cheaper than one real fight's award")
	c.set_level(5, cfg)
	# Level 5 costs 254; one win pays 110 -- 254 xp short is NOT near.
	assert_false(FEED.xp_near(c, cfg), "254 xp short is more than one level-5 fight's worth")
	c.xp = 200  # 54 short, well under the 110 one-fight threshold
	assert_true(FEED.xp_near(c, cfg))
	c.set_level(50, cfg)
	assert_false(FEED.xp_near(c, cfg), "at the level cap there is no next level to be near")


func test_xp_fraction_is_current_over_needed_clamped_and_one_when_nothing_is_needed() -> void:
	var cfg := PROGRESSION.config()
	var c := _creature()
	c.set_level(5, cfg)  # needs 254
	c.xp = 127
	assert_almost_eq(FEED.xp_fraction(c, cfg), 0.5, 0.001)
	c.xp = 0
	assert_almost_eq(FEED.xp_fraction(c, cfg), 0.0, 0.001)


func test_xp_helpers_return_zero_false_zero_for_a_null_creature() -> void:
	var cfg := PROGRESSION.config()
	assert_eq(FEED.xp_remaining(null, cfg), 0)
	assert_false(FEED.xp_near(null, cfg))
	assert_almost_eq(FEED.xp_fraction(null, cfg), 0.0, 0.001)


# --- is_moment / is_tick: every kind the file's own header names -----------
#
## PROGRESSION-VISIBLE header lists: xp_gained, level_up, bond_credit,
## bond_near, bond_milestone, reward_summary.

func test_is_moment_is_true_only_for_level_up_bond_milestone_and_reward_summary() -> void:
	assert_true(FEED.is_moment({"kind": "level_up"}))
	assert_true(FEED.is_moment({"kind": "bond_milestone"}))
	assert_true(FEED.is_moment({"kind": "reward_summary"}))
	assert_false(FEED.is_moment({"kind": "xp_gained"}))
	assert_false(FEED.is_moment({"kind": "bond_credit"}))
	assert_false(FEED.is_moment({"kind": "bond_near"}))
	assert_false(FEED.is_moment({"kind": "unknown_future_kind"}))


func test_is_tick_is_true_only_for_xp_gained_and_bond_credit() -> void:
	assert_true(FEED.is_tick({"kind": "xp_gained"}))
	assert_true(FEED.is_tick({"kind": "bond_credit"}))
	assert_false(FEED.is_tick({"kind": "level_up"}))
	assert_false(FEED.is_tick({"kind": "bond_milestone"}))
	assert_false(FEED.is_tick({"kind": "reward_summary"}))
	assert_false(FEED.is_tick({"kind": "bond_near"}))


func test_bond_near_is_neither_moment_nor_tick() -> void:
	# bond_near is a real event kind the header lists, and belongs to neither
	# bucket -- worth pinning explicitly since it is easy to assume it is a
	# tick (it fires alongside bond_credit) when it is actually silent HUD-wise.
	assert_false(FEED.is_moment({"kind": "bond_near"}))
	assert_false(FEED.is_tick({"kind": "bond_near"}))
