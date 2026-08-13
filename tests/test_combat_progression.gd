extends "res://tests/test_case.gd"

## Combat progression wiring (D30 XP/bond-on-victory, D30 catch-bond) and the
## mid-combat switch seam (D32) — the LOGIC combat_manager.gd exposes, tested
## against a bare, un-`_ready()`d CombatManager instance.
##
## combat_manager.gd extends Node, not RefCounted, so it cannot be this file's
## own base class the way pal_instance.gd/progression.gd are for
## tests/test_progression.gd. Instead each test builds a throwaway
## `CombatManager.new()` and pokes its state through `.set()`/`.get()`/`.call()`
## — the exact reflection style `encounter_director.gd` already uses to talk
## to every Node it does not own the script of.
##
## `.new()` alone never calls `_ready()` (that only fires on entering a
## SceneTree), so the functions exercised here are chosen to be the ones that
## do not need it: `_award_victory`, `_apply_catch_bond` and the whole switch
## seam only ever touch `_party`, `_active_index`, `_enemy`, `state`,
## `_catch_phase`, `_action` and `_switch_lockout` — plain data, no child
## nodes. `is_aiming()` is the one switch guard that DOES need a live `_throw`
## node (built in `_ready`); it is not exercised here for that reason, and
## `smoke_combat.gd` already proves the whole wired-in-a-real-scene fight,
## start to finish, including that guard's sibling checks.

const COMBAT_MANAGER := preload("res://scripts/combat/combat_manager.gd")
const PROGRESSION := preload("res://scripts/pals/progression.gd")
const PAL := preload("res://scripts/pals/pal_instance.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}


func _pal(level: int, nickname: String) -> RefCounted:
	var pal: RefCounted = PAL.from_species("terrapup", DEFINITION)
	pal.level = level
	pal.nickname = nickname
	return pal


func _manager() -> Node:
	return COMBAT_MANAGER.new()


## A manager pre-set to a live, active fight with `party` seated and `active`
## piloted — the state every switch guard reads.
func _in_combat(party: Array[RefCounted], active: int) -> Node:
	var mgr := _manager()
	mgr.set("_party", party)
	mgr.set("_active_index", active)
	mgr.set("state", COMBAT_MANAGER.State.ACTIVE)
	return mgr


# --- XP + bond on victory (D30, combat_manager._award_victory) --------------

func test_award_victory_splits_xp_between_the_active_pal_and_its_bench() -> void:
	var mgr := _manager()
	var cfg := PROGRESSION.config()

	var winner := _pal(3, "Champ")
	var bench := _pal(3, "Bench")
	var fainted_bench := _pal(3, "Downed")
	fainted_bench.fainted = true
	var enemy := _pal(4, "")

	mgr.set("_party", [winner, bench, fainted_bench] as Array[RefCounted])
	mgr.set("_active_index", 0)
	mgr.set("_enemy", enemy)

	# Ground truth: whatever a direct gain_xp() call against a freshly built
	# level-3 pal produces, so this does not pin a specific tuned xp number
	# from progression.json (CLAUDE.md: those numbers are tunable and expected
	# to move).
	var award: int = PROGRESSION.xp_award_for(enemy.level, cfg)
	var share: int = PROGRESSION.party_share(award, cfg)
	var reference_winner := _pal(3, "")
	reference_winner.gain_xp(award, cfg)
	var reference_bench := _pal(3, "")
	reference_bench.gain_xp(share, cfg)

	mgr.call("_award_victory")

	assert_eq(winner.level, reference_winner.level,
		"the active pal's level should match a direct gain_xp(award)")
	assert_eq(winner.xp, reference_winner.xp,
		"the active pal's xp should match a direct gain_xp(award)")
	assert_eq(bench.level, reference_bench.level,
		"the bench's level should match a direct gain_xp(party_share)")
	assert_eq(bench.xp, reference_bench.xp,
		"the bench's xp should match a direct gain_xp(party_share)")
	assert_eq(fainted_bench.xp, 0, "a fainted party member should not gain xp")
	assert_eq(fainted_bench.level, 3, "a fainted party member should not level up")


func test_award_victory_grants_battle_won_bond_only_to_the_active_pal() -> void:
	var mgr := _manager()
	var cfg := PROGRESSION.config()

	var winner := _pal(3, "Champ")
	var bench := _pal(3, "Bench")
	mgr.set("_party", [winner, bench] as Array[RefCounted])
	mgr.set("_active_index", 0)
	mgr.set("_enemy", _pal(4, ""))

	mgr.call("_award_victory")

	var battle_won := int(cfg.get("bond", {}).get("battle_won", 0))
	assert_eq(winner.bond, battle_won, "the active pal should gain the battle-won bond")
	assert_eq(bench.bond, 0, "only the active pal gains bond from landing the win")


func test_award_victory_records_last_xp_award_for_the_hud() -> void:
	var mgr := _manager()
	var cfg := PROGRESSION.config()
	var winner := _pal(3, "Champ")
	mgr.set("_party", [winner] as Array[RefCounted])
	mgr.set("_active_index", 0)
	var enemy := _pal(4, "")
	mgr.set("_enemy", enemy)

	var award: int = PROGRESSION.xp_award_for(enemy.level, cfg)
	mgr.call("_award_victory")

	var readout: Dictionary = mgr.get("last_xp_award")
	assert_true(readout.has("Champ"), "last_xp_award should be keyed by the winner's label")
	var entry: Dictionary = readout.get("Champ", {})
	assert_eq(int(entry.get("xp", -1)), award,
		"last_xp_award should record the raw xp handed to the winner")


func test_award_victory_does_nothing_with_no_enemy_recorded() -> void:
	var mgr := _manager()
	var winner := _pal(3, "Champ")
	mgr.set("_party", [winner] as Array[RefCounted])
	mgr.set("_active_index", 0)
	# _enemy left null -- combat_manager should refuse quietly, not crash.
	mgr.call("_award_victory")
	assert_eq(winner.xp, 0)
	assert_eq(winner.bond, 0)


# --- bond on a successful catch (D30, combat_manager._apply_catch_bond) -----

func test_apply_catch_bond_starts_a_fresh_catch_with_the_configured_bond() -> void:
	var mgr := _manager()
	var cfg := PROGRESSION.config()
	var caught := _pal(2, "")
	assert_eq(caught.bond, 0, "a fresh instance should start unbonded")

	mgr.call("_apply_catch_bond", caught)

	var start := int(cfg.get("bond", {}).get("successful_catch_start", 0))
	assert_eq(caught.bond, start)


func test_apply_catch_bond_tolerates_a_null_catch() -> void:
	var mgr := _manager()
	mgr.call("_apply_catch_bond", null)  # must not crash


# --- the switch seam (D32) ---------------------------------------------------

func test_switchable_indices_excludes_the_active_and_fainted_members() -> void:
	var a := _pal(3, "A")
	var b := _pal(3, "B")
	b.fainted = true
	var c := _pal(3, "C")
	var mgr := _in_combat([a, b, c] as Array[RefCounted], 0)

	var options: Array = mgr.call("switchable_indices")
	assert_eq(options.size(), 1, "only one member is both alive and not the active one")
	assert_eq(int(options[0]), 2, "the fainted middle member must not be offered")


func test_cycle_active_wraps_and_skips_fainted_members() -> void:
	var a := _pal(3, "A")
	var b := _pal(3, "B")
	b.fainted = true
	var c := _pal(3, "C")
	var mgr := _in_combat([a, b, c] as Array[RefCounted], 0)

	assert_true(bool(mgr.call("cycle_active", 1)), "should switch to the only living non-active member")
	assert_eq(int(mgr.get("_active_index")), 2, "should have skipped the fainted middle member")

	# Clear the lockout the first switch started, or the second is refused for
	# the wrong reason.
	mgr.set("_switch_lockout", 0.0)
	assert_true(bool(mgr.call("cycle_active", 1)), "should be able to cycle onward")
	assert_eq(int(mgr.get("_active_index")), 0, "cycling forward again should wrap back to the original pal")


func test_cycle_active_returns_false_with_nothing_to_switch_to() -> void:
	var a := _pal(3, "A")
	var mgr := _in_combat([a] as Array[RefCounted], 0)
	assert_false(bool(mgr.call("cycle_active", 1)), "a party of one has nothing to switch to")

	var b := _pal(3, "B")
	b.fainted = true
	var mgr2 := _in_combat([a, b] as Array[RefCounted], 0)
	assert_false(bool(mgr2.call("cycle_active", 1)), "an all-fainted bench has nothing to switch to")


func test_can_switch_false_when_not_fighting() -> void:
	var a := _pal(3, "A")
	var b := _pal(3, "B")
	var mgr := _manager()
	mgr.set("_party", [a, b] as Array[RefCounted])
	mgr.set("_active_index", 0)
	# state left at its default, State.INACTIVE.
	assert_false(bool(mgr.call("can_switch")))


func test_can_switch_respects_the_lockout() -> void:
	var a := _pal(3, "A")
	var b := _pal(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)

	mgr.set("_switch_lockout", 1.0)
	assert_false(bool(mgr.call("can_switch")), "a fresh lockout should refuse a switch")

	mgr.set("_switch_lockout", 0.0)
	assert_true(bool(mgr.call("can_switch")), "an elapsed lockout should allow one")


func test_can_switch_false_while_resolving_a_catch() -> void:
	var a := _pal(3, "A")
	var b := _pal(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	mgr.set("_catch_phase", COMBAT_MANAGER.CatchPhase.SHAKING)
	assert_false(bool(mgr.call("can_switch")), "a resolving catch pauses the whole fight")


func test_can_switch_false_while_the_pal_is_committed() -> void:
	var a := _pal(3, "A")
	var b := _pal(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	mgr.set("_action", COMBAT_MANAGER.Action.WINDUP)
	assert_false(bool(mgr.call("can_switch")), "switching mid-swing would refund the attack's commitment")


func test_request_switch_refuses_a_fainted_target() -> void:
	var a := _pal(3, "A")
	var b := _pal(3, "B")
	b.fainted = true
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	assert_false(bool(mgr.call("request_switch", 1)))
	assert_eq(int(mgr.get("_active_index")), 0, "a refused switch must not change who is active")


func test_request_switch_refuses_an_invalid_index() -> void:
	var a := _pal(3, "A")
	var b := _pal(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	assert_false(bool(mgr.call("request_switch", 0)), "switching to the already-active index is not a switch")
	assert_false(bool(mgr.call("request_switch", 5)), "an out-of-range index should be refused")
	assert_false(bool(mgr.call("request_switch", -1)), "a negative index should be refused")


func test_request_switch_swaps_the_active_index_and_starts_the_lockout() -> void:
	var a := _pal(3, "A")
	var b := _pal(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)

	# A Dictionary, not a bare local: GDScript lambdas capture outer locals by
	# value, so writing to a captured `int` from inside the callable would
	# silently mutate the lambda's own copy rather than this variable. A
	# Dictionary is captured by reference, so mutating IT is visible here.
	var captured := {"index": -1}
	mgr.connect("pal_switched", func(index: int) -> void: captured["index"] = index)

	assert_true(bool(mgr.call("request_switch", 1)))
	assert_eq(int(mgr.get("_active_index")), 1)
	assert_eq(int(captured.get("index", -1)), 1, "pal_switched should carry the new index")
	assert_true(float(mgr.get("_switch_lockout")) > 0.0, "a switch should start the lockout")
	# Immediately switching again should now be refused by the lockout.
	assert_false(bool(mgr.call("request_switch", 0)))


func test_request_switch_preserves_the_switched_out_pals_hp_and_energy() -> void:
	var a := _pal(3, "A")
	a.hp = 41.0
	a.energy = 60.0
	var b := _pal(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)

	mgr.call("request_switch", 1)

	assert_eq(a.hp, 41.0, "the switched-out pal must keep its hp")
	assert_eq(a.energy, 60.0, "the switched-out pal must keep its energy")
