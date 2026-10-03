extends "res://tests/test_case.gd"

## Combat progression wiring (D30 XP-on-victory) and the mid-combat switch
## seam (D32) — the LOGIC combat_manager.gd exposes, tested against a bare,
## un-`_ready()`d CombatManager instance.
##
## combat_manager.gd extends Node, not RefCounted, so it cannot be this file's
## own base class the way creature_instance.gd/progression.gd are for
## tests/test_progression.gd. Instead each test builds a throwaway
## `CombatManager.new()` and pokes its state through `.set()`/`.get()`/`.call()`
## — the exact reflection style `encounter_director.gd` already uses to talk
## to every Node it does not own the script of.
##
## `.new()` alone never calls `_ready()` (that only fires on entering a
## SceneTree), so the functions exercised here are chosen to be the ones that
## do not need it: `_award_victory` and the whole switch seam only ever touch
## `_party`, `_active_index`, `_enemy`, `state`, `_catch_phase`, `_action` and
## `_switch_lockout` — plain data, no child nodes. `is_aiming()` is the one
## switch guard that DOES need a live `_throw` node (built in `_ready`); it is
## not exercised here for that reason, and `smoke_combat.gd` already proves
## the whole wired-in-a-real-scene fight, start to finish, including that
## guard's sibling checks.
##
## OWNER-0901-BOND-MILESTONES removed both `_apply_catch_bond` (a caught
## creature no longer gets a bond head start -- every creature starts its
## milestone ladder at 0/50, caught or not) and bond's separate per-victory
## gain (`_award_victory`'s existing `battles_fought` increment, tested below,
## already IS the ladder's first milestone -- see bond_milestones.json's own
## comment for why no new crediting code was needed there).

const COMBAT_MANAGER := preload("res://scripts/combat/combat_manager.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")
const CREATURE_CODEC := preload("res://scripts/save/water_capture_codec.gd")
const ACCEPTED_ACTION_HOST := preload("res://scripts/combat/accepted_action_host.gd")
const COMBAT_ROUND_REWARD := preload("res://scripts/net/combat_round_reward.gd")
const F48_ACTOR_TOPUP := preload("res://tools/net/f48_actor_topup.gd")
const F48_PEER_RUNNER := preload("res://tools/net/peer_runner.gd")

## Disclosed ownership-answer seam; canonical host proof is tested separately.
class DurableTrainerRewardsFixture extends Node:
	var owned_encounter := "host-owned-round"
	var answer: Variant = true
	var release_ready: bool = false
	var vitals_pending: bool = false
	func uses_durable_trainer_rewards(encounter_id: String) -> Variant:
		return answer if encounter_id == owned_encounter else false
	func ordinary_combat_round_release_ready(_encounter_id: String) -> bool:
		return release_ready
	func ordinary_actor_vitals_pending(_encounter_id: String) -> bool:
		return vitals_pending

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}

var _managers: Array[Node] = []


func after_each() -> void:
	# Bare Nodes have no tree to own their lifetime; RefCounted test teardown
	# alone cannot free the manager or the party records it still holds.
	for manager: Node in _managers:
		if is_instance_valid(manager):
			manager.free()
	_managers.clear()


func _creature(level: int, nickname: String) -> RefCounted:
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	creature.level = level
	creature.nickname = nickname
	return creature


func _manager() -> Node:
	var manager: Node = COMBAT_MANAGER.new()
	_managers.append(manager)
	return manager


## A manager pre-set to a live, active fight with `party` seated and `active`
## piloted — the state every switch guard reads.
func _in_combat(party: Array[RefCounted], active: int) -> Node:
	var mgr := _manager()
	mgr.set("_party", party)
	mgr.set("_active_index", active)
	mgr.set("state", COMBAT_MANAGER.State.ACTIVE)
	return mgr


# --- XP + bond on victory (D30, combat_manager._award_victory) --------------

func test_award_victory_splits_xp_between_the_active_creature_and_its_bench() -> void:
	var mgr := _manager()
	var cfg := PROGRESSION.config()

	var winner := _creature(3, "Champ")
	var bench := _creature(3, "Bench")
	var fainted_bench := _creature(3, "Downed")
	fainted_bench.fainted = true
	var enemy := _creature(4, "")

	mgr.set("_party", [winner, bench, fainted_bench] as Array[RefCounted])
	mgr.set("_active_index", 0)
	mgr.set("_enemy", enemy)

	# Ground truth: whatever a direct gain_xp() call against a freshly built
	# level-3 creature produces, so this does not pin a specific tuned xp number
	# from progression.json (CLAUDE.md: those numbers are tunable and expected
	# to move).
	var award: int = PROGRESSION.xp_award_for(enemy.level, cfg)
	var share: int = PROGRESSION.party_share(award, cfg)
	# The live legacy award stays ordinary while the hybrid host transaction
	# remains inactive. Detached reduced-XP staging does not activate this path.
	var award_cfg: Dictionary = cfg.get("xp_award", {})
	var ordinary: int = int(float(award_cfg.get("base", 18.0))
		+ float(award_cfg.get("per_enemy_level", 6.0)) * float(enemy.level))
	assert_eq(award, ordinary, "inactive hybrid staging preserves the full ordinary victory award")
	assert_true(award > 0 and share > 0)
	var reference_winner := _creature(3, "")
	reference_winner.gain_xp(award, cfg)
	var reference_bench := _creature(3, "")
	reference_bench.gain_xp(share, cfg)

	mgr.call("_award_victory")

	assert_eq(winner.level, reference_winner.level,
		"the active creature's level should match a direct gain_xp(award)")
	assert_eq(winner.xp, reference_winner.xp,
		"the active creature's xp should match a direct gain_xp(award)")
	assert_eq(bench.level, reference_bench.level,
		"the bench's level should match a direct gain_xp(party_share)")
	assert_eq(bench.xp, reference_bench.xp,
		"the bench's xp should match a direct gain_xp(party_share)")
	assert_eq(fainted_bench.xp, 0, "a fainted party member should not gain xp")
	assert_eq(fainted_bench.level, 3, "a fainted party member should not level up")
	var winner_xp: int = int(winner.xp)
	var bench_xp: int = int(bench.xp)
	mgr.call("_award_victory")
	assert_eq(winner.xp, winner_xp, "re-reading the same done fight cannot grant XP again")
	assert_eq(bench.xp, bench_xp)


## OWNER-0901-BOND-MILESTONES: `battles_fought` (also prompt 67's release-
## ceremony history counter) IS the bond ladder's first milestone now, and
## it goes to every non-fainted party member who was in the fight, not only
## the one who landed the win -- matching the owner's own "defeat 50 wild
## creatures TOGETHER" wording, and the same "whole party, not just active"
## rule the xp party_share above already follows.
func test_award_victory_credits_battles_fought_to_every_non_fainted_member() -> void:
	var mgr := _manager()

	var winner := _creature(3, "Champ")
	var bench := _creature(3, "Bench")
	var fainted_bench := _creature(3, "Downed")
	fainted_bench.fainted = true
	mgr.set("_party", [winner, bench, fainted_bench] as Array[RefCounted])
	mgr.set("_active_index", 0)
	mgr.set("_enemy", _creature(4, ""))

	mgr.call("_award_victory")

	assert_eq(winner.battles_fought, 1, "the active creature fought and should be credited")
	assert_eq(bench.battles_fought, 1, "a non-fainted bench member was in the fight too")
	assert_eq(fainted_bench.battles_fought, 0, "a fainted member did not fight")


func test_award_victory_records_last_xp_award_for_the_hud() -> void:
	var mgr := _manager()
	var cfg := PROGRESSION.config()
	var winner := _creature(3, "Champ")
	mgr.set("_party", [winner] as Array[RefCounted])
	mgr.set("_active_index", 0)
	var enemy := _creature(4, "")
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
	var winner := _creature(3, "Champ")
	mgr.set("_party", [winner] as Array[RefCounted])
	mgr.set("_active_index", 0)
	# _enemy left null -- combat_manager should refuse quietly, not crash.
	mgr.call("_award_victory")
	assert_eq(winner.xp, 0)
	assert_eq(winner.battles_fought, 0, "no fight happened, so no bond-ladder credit either")


func test_exact_durable_trainer_round_never_duplicates_local_xp_or_history() -> void:
	for kind: String in ["trainer", "boss"]:
		var mgr := _manager()
		var link := DurableTrainerRewardsFixture.new()
		mgr.add_child(link)
		var winner := _creature(3, "Champ")
		var bench := _creature(3, "Bench")
		mgr.set("_party", [winner, bench] as Array[RefCounted])
		mgr.set("_active_index", 0)
		mgr.set("_enemy", _creature(4, ""))
		mgr.set("_encounter_link", link)
		mgr.set("_encounter_id", link.owned_encounter)
		mgr.set("_encounter_kind", kind)
		var before: Array[Dictionary] = [CREATURE_CODEC.encode(winner), CREATURE_CODEC.encode(bench)]
		mgr.call("_award_victory")
		mgr.call("_award_victory")
		assert_eq([CREATURE_CODEC.encode(winner), CREATURE_CODEC.encode(bench)], before,
			"host journal owns all XP, HP, history, moves and condition changes")
		assert_eq(mgr.get("last_xp_award"), {})
		assert_false(mgr.get("_victory_awarded"))


func test_unowned_or_malformed_durable_answer_preserves_ordinary_award() -> void:
	for scenario: Dictionary in [{"id": "other-round", "kind": "trainer", "answer": true},
		{"id": "", "kind": "boss", "answer": true},
		{"id": "host-owned-round", "kind": "wild", "answer": true},
		{"id": "host-owned-round", "kind": "trainer", "answer": false},
		{"id": "host-owned-round", "kind": "trainer", "answer": "true"},
		{"id": "host-owned-round", "kind": "trainer", "answer": 1},
		{"id": "host-owned-round", "kind": "trainer", "answer": null}]:
		var mgr := _manager()
		var link := DurableTrainerRewardsFixture.new()
		link.answer = scenario.answer
		mgr.add_child(link)
		var winner := _creature(3, "Champ")
		mgr.set("_party", [winner] as Array[RefCounted])
		mgr.set("_active_index", 0)
		mgr.set("_enemy", _creature(4, ""))
		mgr.set("_encounter_link", link)
		mgr.set("_encounter_id", scenario.id)
		mgr.set("_encounter_kind", scenario.kind)
		mgr.call("_award_victory")
		assert_eq(winner.battles_fought, 1, str(scenario))
		assert_true(winner.level > 3 or winner.xp > 0, str(scenario))


# --- the switch seam (D32) ---------------------------------------------------

func test_switchable_indices_excludes_the_active_and_fainted_members() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	b.fainted = true
	var c := _creature(3, "C")
	var mgr := _in_combat([a, b, c] as Array[RefCounted], 0)

	var options: Array = mgr.call("switchable_indices")
	assert_eq(options.size(), 1, "only one member is both alive and not the active one")
	assert_eq(int(options[0]), 2, "the fainted middle member must not be offered")


func test_cycle_active_wraps_and_skips_fainted_members() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	b.fainted = true
	var c := _creature(3, "C")
	var mgr := _in_combat([a, b, c] as Array[RefCounted], 0)

	assert_true(bool(mgr.call("cycle_active", 1)), "should switch to the only living non-active member")
	assert_eq(int(mgr.get("_active_index")), 2, "should have skipped the fainted middle member")

	# Clear the lockout the first switch started, or the second is refused for
	# the wrong reason.
	mgr.set("_switch_lockout", 0.0)
	assert_true(bool(mgr.call("cycle_active", 1)), "should be able to cycle onward")
	assert_eq(int(mgr.get("_active_index")), 0, "cycling forward again should wrap back to the original creature")


func test_cycle_active_returns_false_with_nothing_to_switch_to() -> void:
	var a := _creature(3, "A")
	var mgr := _in_combat([a] as Array[RefCounted], 0)
	assert_false(bool(mgr.call("cycle_active", 1)), "a party of one has nothing to switch to")

	var b := _creature(3, "B")
	b.fainted = true
	var mgr2 := _in_combat([a, b] as Array[RefCounted], 0)
	assert_false(bool(mgr2.call("cycle_active", 1)), "an all-fainted bench has nothing to switch to")


# --- auto-switch-on-faint for TRAINER battles only (GATE-F-LEG-S04) --------
#
# `_handle_active_faint()` is exercised directly, the same bare-manager style
# every other switch-seam test above uses -- it only ever touches `_party`,
# `_active_index`, `_enemy_owned` and `state`, none of which need a live
# wild/ally body node.

func test_trainer_fight_auto_switches_when_the_active_creature_faints() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	mgr.set("_enemy_owned", true)

	mgr.call("_handle_active_faint")

	assert_eq(int(mgr.get("_active_index")), 1, "should have switched to the only other living member")
	assert_eq(int(mgr.get("state")), COMBAT_MANAGER.State.ACTIVE,
		"the fight must still be running against a trainer -- a faint no longer ends it while somebody is left")


func test_trainer_fight_still_ends_once_the_whole_party_has_fainted() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	b.fainted = true
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	mgr.set("_enemy_owned", true)

	mgr.call("_handle_active_faint")

	assert_eq(int(mgr.get("state")), COMBAT_MANAGER.State.RESOLVING,
		"with nobody left to switch to, even a trainer fight ends")
	assert_eq(str(mgr.get("_outcome")), "lost")


func test_wild_encounter_still_ends_on_the_first_faint_d32_unchanged() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	mgr.set("_enemy_owned", false)

	mgr.call("_handle_active_faint")

	assert_eq(int(mgr.get("state")), COMBAT_MANAGER.State.RESOLVING,
		"a wild fight still ends the moment the active creature faints, D32 unchanged, even with a healthy bench")
	assert_eq(str(mgr.get("_outcome")), "lost")
	assert_eq(int(mgr.get("_active_index")), 0, "no switch should have happened for a wild encounter")


func test_can_switch_false_when_not_fighting() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	var mgr := _manager()
	mgr.set("_party", [a, b] as Array[RefCounted])
	mgr.set("_active_index", 0)
	# state left at its default, State.INACTIVE.
	assert_false(bool(mgr.call("can_switch")))


func test_can_switch_respects_the_lockout() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)

	mgr.set("_switch_lockout", 1.0)
	assert_false(bool(mgr.call("can_switch")), "a fresh lockout should refuse a switch")

	mgr.set("_switch_lockout", 0.0)
	assert_true(bool(mgr.call("can_switch")), "an elapsed lockout should allow one")


func test_can_switch_false_while_resolving_a_catch() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	mgr.set("_catch_phase", COMBAT_MANAGER.CatchPhase.SHAKING)
	assert_false(bool(mgr.call("can_switch")), "a resolving catch pauses the whole fight")


func test_can_switch_false_while_the_creature_is_committed() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	mgr.set("_action", COMBAT_MANAGER.Action.WINDUP)
	assert_false(bool(mgr.call("can_switch")), "switching mid-swing would refund the attack's commitment")


func test_request_switch_refuses_a_fainted_target() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	b.fainted = true
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	assert_false(bool(mgr.call("request_switch", 1)))
	assert_eq(int(mgr.get("_active_index")), 0, "a refused switch must not change who is active")


func test_request_switch_refuses_an_invalid_index() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)
	assert_false(bool(mgr.call("request_switch", 0)), "switching to the already-active index is not a switch")
	assert_false(bool(mgr.call("request_switch", 5)), "an out-of-range index should be refused")
	assert_false(bool(mgr.call("request_switch", -1)), "a negative index should be refused")


func test_request_switch_swaps_the_active_index_and_starts_the_lockout() -> void:
	var a := _creature(3, "A")
	var b := _creature(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)

	# A Dictionary, not a bare local: GDScript lambdas capture outer locals by
	# value, so writing to a captured `int` from inside the callable would
	# silently mutate the lambda's own copy rather than this variable. A
	# Dictionary is captured by reference, so mutating IT is visible here.
	var captured := {"index": -1}
	mgr.connect("creature_switched", func(index: int) -> void: captured["index"] = index)

	assert_true(bool(mgr.call("request_switch", 1)))
	assert_eq(int(mgr.get("_active_index")), 1)
	assert_eq(int(captured.get("index", -1)), 1, "creature_switched should carry the new index")
	assert_true(float(mgr.get("_switch_lockout")) > 0.0, "a switch should start the lockout")
	# Immediately switching again should now be refused by the lockout.
	assert_false(bool(mgr.call("request_switch", 0)))


func test_request_switch_preserves_the_switched_out_creatures_hp_and_energy() -> void:
	var a := _creature(3, "A")
	a.hp = 41.0
	a.energy = 60.0
	var b := _creature(3, "B")
	var mgr := _in_combat([a, b] as Array[RefCounted], 0)

	mgr.call("request_switch", 1)

	assert_eq(a.hp, 41.0, "the switched-out creature must keep its hp")
	assert_eq(a.energy, 60.0, "the switched-out creature must keep its energy")


func test_owned_round_finish_retains_actual_enemy_and_link_until_saved_ack() -> void:
	var manager: Node = _manager()
	var link: Node = DurableTrainerRewardsFixture.new()
	manager.add_child(link)
	var enemy: RefCounted = _creature(4, "Original opponent")
	manager.set("_enemy", enemy)
	manager.set("_encounter_link", link)
	manager.set("_encounter_id", "host-owned-round")
	manager.set("_encounter_kind", "trainer")
	manager.set("_outcome", "won")
	manager.set("state", COMBAT_MANAGER.State.RESOLVING)
	manager.call("_finish")
	assert_eq(manager.get("state"), COMBAT_MANAGER.State.RESOLVING)
	assert_eq(manager.get("_enemy"), enemy, "the actual defeated source remains available for the writer")
	assert_eq(manager.get("_encounter_link"), link, "save failure cannot release the exact owner")


func test_owned_pending_health_refuses_switch_without_changing_party() -> void:
	var first: RefCounted = _creature(3, "First")
	var second: RefCounted = _creature(3, "Second")
	var manager: Node = _in_combat([first, second] as Array[RefCounted], 0)
	var link: Node = DurableTrainerRewardsFixture.new()
	link.set("vitals_pending", true)
	manager.add_child(link)
	manager.set("_encounter_link", link)
	manager.set("_encounter_id", "host-owned-round")
	assert_false(bool(manager.call("request_switch", 1)))
	assert_eq(manager.get("_active_index"), 0)
	assert_eq(first.hp, first.max_hp)
	assert_eq(second.hp, second.max_hp)


func test_validated_owned_binding_never_downgrades_after_writer_or_epoch_change() -> void:
	var manager: Node = _manager()
	var link: Node = DurableTrainerRewardsFixture.new()
	manager.add_child(link)
	var winner: RefCounted = _creature(3, "Owned winner")
	manager.set("_party", [winner] as Array[RefCounted])
	manager.set("_active_index", 0)
	manager.set("_enemy", _creature(4, "Enemy"))
	manager.call("bind_encounter", link, "host-owned-round", "trainer")
	var before: Dictionary = CREATURE_CODEC.encode(winner)
	link.set("answer", false) # The actual bound proof was ready; a later source may be unavailable.
	manager.call("_award_victory")
	assert_eq(CREATURE_CODEC.encode(winner), before)
	manager.call("bind_encounter", link, "host-owned-round", "trainer")
	manager.call("_award_victory")
	assert_eq(CREATURE_CODEC.encode(winner), before, "same-ID rebinding cannot enable a legacy double award")
	assert_eq(manager.get("_ordinary_reward_owned_id"), "host-owned-round")
	manager.call("bind_encounter", link, "different-round", "trainer")
	assert_eq(manager.get("_ordinary_reward_owned_id"), "")
	manager.call("_award_victory")
	assert_true(winner.xp > 0)
	assert_eq(winner.battles_fought, 1, "ownership cannot bleed into a different ordinary source")


func test_original_typed_damage_survives_terminal_but_rejects_changed_body_and_duplicate() -> void:
	var host: RefCounted = ACCEPTED_ACTION_HOST.new()
	var owned: Dictionary = CREATURE_CODEC.encode(_creature(3, "Owned"))
	var rec: Dictionary = host.call("open", 1, "meadows", "trainer",
		{"hp": 100.0, "hp_max": 100.0, "owner_npc": "risha", "card": {"uid": "original-enemy"}, "body_generation": 1},
		str(owned.uid), "original-owner")
	var id: String = str(rec.encounter_id)
	rec["ordinary_combat_reward_owner"] = COMBAT_ROUND_REWARD.scope("original-world", "original-epoch", "meadows", "risha", id)
	var bound: Dictionary = host.call("bind_actor_body", id, 1, "original-owner", owned, 123)
	assert_true(bound.get("ok") == true)
	var proposal: Dictionary = host.call("stage_actor_vitals", id, 1, str(owned.uid),
		int(bound.vitals.body_generation), 0, "original-hit", "damage", 7.5, 4096)
	assert_true(proposal.get("ok") == true)
	var original: Dictionary = ACCEPTED_ACTION_HOST._original(rec)
	host.call("set_phase", id, "done")
	var fresh: Dictionary = host.call("stage_actor_vitals", id, 1, str(owned.uid),
		int(bound.vitals.body_generation), 0, "fresh-hit", "damage", 7.5, 4096)
	assert_false(fresh.get("ok") == true, "terminal does not admit a fresh HP producer")
	assert_true(host.call("verify_original_actor_vitals", proposal, original) == true)
	var altered: Dictionary = proposal.duplicate(true)
	altered["hp_after"] = float(altered.hp_after) - 1.0
	assert_false(host.call("verify_original_actor_vitals", altered, original) == true)
	var actor: Dictionary = rec.participants[1].actor_vitals[owned.uid]
	actor["body_instance_id"] = 124
	assert_false(host.call("verify_original_actor_vitals", proposal, original) == true)
	actor["body_instance_id"] = 123
	var original_scope: Dictionary = rec.ordinary_combat_reward_owner.duplicate(true)
	rec.ordinary_combat_reward_owner["session_id"] = "different-epoch"
	assert_false(host.call("verify_original_actor_vitals", proposal, original) == true)
	rec["ordinary_combat_reward_owner"] = original_scope
	rec.opponent.card["uid"] = "replacement-enemy"
	assert_false(host.call("verify_original_actor_vitals", proposal, original) == true)
	rec.opponent.card["uid"] = "original-enemy"
	var committed: Dictionary = host.call("commit_original_actor_vitals", proposal, original)
	assert_true(committed.get("ok") == true)
	assert_eq(actor.hp, float(owned.hp) - 7.5)
	assert_eq(original.participants[1].actor_vitals[owned.uid].hp, owned.hp, "the original baseline stays immutable")
	assert_false(host.call("verify_original_actor_vitals", proposal, original) == true)
	assert_false((host.call("commit_original_actor_vitals", proposal, original) as Dictionary).get("ok") == true)
	assert_eq((host.call("pending_actor_vitals", id) as Array).size(), 1)
	assert_false(host.call("acknowledge_actor_vitals", id, "original-owner", owned.uid, int(proposal.revision), {}) == true)
	assert_true(host.call("acknowledge_actor_vitals", id, "original-owner", owned.uid, int(proposal.revision), proposal.settlement_receipt) == true)
	assert_true((host.call("pending_actor_vitals", id) as Array).is_empty())


func test_original_typed_damage_targets_same_retained_actor_after_actual_leave() -> void:
	var host: RefCounted = ACCEPTED_ACTION_HOST.new()
	var owned: Dictionary = CREATURE_CODEC.encode(_creature(3, "Departed owned"))
	var rec: Dictionary = host.call("open", 2, "meadows", "boss",
		{"hp": 100.0, "hp_max": 100.0, "owner_npc": "risha", "card": {"uid": "original-enemy"}, "body_generation": 1},
		str(owned.uid), "departed-owner")
	var id: String = str(rec.encounter_id)
	rec["ordinary_combat_reward_owner"] = COMBAT_ROUND_REWARD.scope("original-world", "original-epoch", "meadows", "risha", id)
	var bound: Dictionary = host.call("bind_actor_body", id, 2, "departed-owner", owned, 321)
	assert_true(bound.get("ok") == true)
	var proposal: Dictionary = host.call("stage_actor_vitals", id, 2, str(owned.uid),
		int(bound.vitals.body_generation), 0, "original-departed-hit", "damage", 8.0, 4096)
	assert_true(proposal.get("ok") == true)
	var original: Dictionary = ACCEPTED_ACTION_HOST._original(rec)
	var left: Dictionary = host.call("leave", id, 2)
	assert_true(left.get("ok") == true)
	assert_true(rec.participants.is_empty())
	assert_true(host.call("verify_original_actor_vitals", proposal, original) == true)
	assert_true((host.call("commit_original_actor_vitals", proposal, original) as Dictionary).get("ok") == true)
	assert_eq(rec.retained_actor_participants["departed-owner"].actor_vitals[owned.uid].hp, float(owned.hp) - 8.0)
	assert_true(host.call("acknowledge_actor_vitals", id, "departed-owner", owned.uid,
		int(proposal.revision), proposal.settlement_receipt) == true)
	assert_true((host.call("pending_actor_vitals", id) as Array).is_empty())


func test_disclosed_original_full_topup_uses_exact_actor_receipt_and_survives_terminal() -> void:
	var host: RefCounted = ACCEPTED_ACTION_HOST.new()
	var owned: Dictionary = CREATURE_CODEC.encode(_creature(3, "Fixture owned"))
	var rec: Dictionary = host.call("open", 1, "meadows", "boss",
		{"hp": 100.0, "hp_max": 100.0, "owner_npc": "warden_aldis",
			"card": {"uid": "fixture-original-enemy"}, "body_generation": 1},
		str(owned.uid), "fixture-owner")
	var id: String = str(rec.encounter_id)
	rec["ordinary_combat_reward_owner"] = COMBAT_ROUND_REWARD.scope("fixture-world", "fixture-epoch", "meadows", "warden_aldis", id)
	var bound: Dictionary = host.call("bind_actor_body", id, 1, "fixture-owner", owned, 456)
	assert_true(bound.get("ok") == true)
	var generation: int = int(bound.vitals.body_generation)
	var damage: Dictionary = host.call("stage_actor_vitals", id, 1, str(owned.uid), generation,
		0, "fixture-original-damage", "damage", 7.5, 4096)
	assert_true(damage.get("ok") == true)
	var damage_source: Dictionary = ACCEPTED_ACTION_HOST._original(rec)
	assert_true((host.call("commit_original_actor_vitals", damage, damage_source) as Dictionary).get("ok") == true)
	assert_true(host.call("acknowledge_actor_vitals", id, "fixture-owner", owned.uid,
		int(damage.revision), damage.settlement_receipt) == true)
	var actor: Dictionary = rec.participants[1].actor_vitals[owned.uid]
	assert_eq(actor.hp, float(owned.hp) - 7.5)
	var topup: Dictionary = host.call("stage_actor_vitals", id, 1, str(owned.uid), generation,
		int(actor.revision), "fixture-original-topup", "heal", float(actor.max_hp) - float(actor.hp), 4096)
	assert_true(topup.get("ok") == true)
	var original: Dictionary = ACCEPTED_ACTION_HOST._original(rec)
	assert_true(host.call("verify_original_fixture_actor_topup", topup, original) == true)
	assert_false(host.call("verify_original_actor_vitals", topup, original) == true,
		"the normal damage source cannot authorize a fixture heal")
	var partial: Dictionary = host.call("stage_actor_vitals", id, 1, str(owned.uid), generation,
		int(actor.revision), "fixture-partial-topup", "heal", 3.0, 4096)
	assert_true(partial.get("ok") == true)
	assert_false(host.call("verify_original_fixture_actor_topup", partial, original) == true,
		"even a valid smaller heal is not the disclosed full-topup source")
	var changed: Dictionary = topup.duplicate(true)
	changed["hp_after"] = float(changed.hp_after) - 1.0
	assert_false(host.call("verify_original_fixture_actor_topup", changed, original) == true)
	changed = topup.duplicate(true)
	changed["peer_id"] = 2
	assert_false(host.call("verify_original_fixture_actor_topup", changed, original) == true)
	actor["body_instance_id"] = 457
	assert_false(host.call("verify_original_fixture_actor_topup", topup, original) == true)
	actor["body_instance_id"] = 456
	var original_scope: Dictionary = rec.ordinary_combat_reward_owner.duplicate(true)
	rec.ordinary_combat_reward_owner["session_id"] = "different-fixture-epoch"
	assert_false(host.call("verify_original_fixture_actor_topup", topup, original) == true)
	rec["ordinary_combat_reward_owner"] = original_scope
	rec.opponent.card["uid"] = "replacement-enemy"
	assert_false(host.call("verify_original_fixture_actor_topup", topup, original) == true)
	rec.opponent.card["uid"] = "fixture-original-enemy"
	actor["hp"] = 0.0
	actor["fainted"] = true
	var fainted_source: Dictionary = ACCEPTED_ACTION_HOST._original(rec)
	var revive: Dictionary = host.call("stage_actor_vitals", id, 1, str(owned.uid), generation,
		int(actor.revision), "fixture-forbidden-revive", "heal", float(actor.max_hp), 4096)
	assert_false(revive.get("ok") == true)
	assert_false(host.call("verify_original_fixture_actor_topup", topup, fainted_source) == true)
	actor["hp"] = topup.hp_before
	actor["fainted"] = false
	host.call("set_phase", id, "done")
	var fresh: Dictionary = host.call("stage_actor_vitals", id, 1, str(owned.uid), generation,
		int(actor.revision), "fixture-fresh-terminal-topup", "heal", 7.5, 4096)
	assert_false(fresh.get("ok") == true)
	assert_true(host.call("verify_original_fixture_actor_topup", topup, original) == true)
	assert_true((host.call("commit_original_fixture_actor_topup", topup, original) as Dictionary).get("ok") == true)
	assert_eq(actor.hp, owned.max_hp)
	assert_false(actor.fainted)
	assert_eq(original.participants[1].actor_vitals[owned.uid].hp, float(owned.hp) - 7.5,
		"settlement cannot rewrite the original damaged source")
	assert_false((host.call("commit_original_fixture_actor_topup", topup, original) as Dictionary).get("ok") == true)
	assert_eq((host.call("pending_actor_vitals", id) as Array).size(), 1)
	assert_false(host.call("acknowledge_actor_vitals", id, "fixture-owner", owned.uid,
		int(topup.revision), damage.settlement_receipt) == true)
	assert_true(host.call("acknowledge_actor_vitals", id, "fixture-owner", owned.uid,
		int(topup.revision), topup.settlement_receipt) == true)
	assert_true((host.call("pending_actor_vitals", id) as Array).is_empty())
	host.call("set_phase", id, "active")
	var full: Dictionary = host.call("stage_actor_vitals", id, 1, str(owned.uid), generation,
		int(actor.revision), "fixture-full-again", "heal", 7.5, 4096)
	assert_false(full.get("ok") == true, "full HP cannot mint another topup receipt")
	var next_damage: Dictionary = host.call("stage_actor_vitals", id, 1, str(owned.uid), generation,
		int(actor.revision), "fixture-next-damage", "damage", 5.0, 4096)
	var next_source: Dictionary = ACCEPTED_ACTION_HOST._original(rec)
	assert_true(next_damage.get("ok") == true)
	assert_eq(next_damage.hp_before, owned.max_hp)
	assert_true((host.call("commit_original_actor_vitals", next_damage, next_source) as Dictionary).get("ok") == true)
	assert_eq(actor.hp, float(owned.max_hp) - 5.0)
	assert_true(host.call("acknowledge_actor_vitals", id, "fixture-owner", owned.uid,
		int(next_damage.revision), next_damage.settlement_receipt) == true)
	assert_true((host.call("pending_actor_vitals", id) as Array).is_empty())


func test_actual_fixture_provider_refuses_non_runner_tree_and_detached_request() -> void:
	var driver: Script = F48_PEER_RUNNER
	assert_eq(driver.resource_path, "res://tools/net/peer_runner.gd",
		"the actual driver is compiled by the focused native check")
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	assert_eq(F48_ACTOR_TOPUP.install(tree, F48_ACTOR_TOPUP.DISCLOSURE), null,
		"the actual test tree cannot install the PeerRunner-only aid")
	var provider: Node = F48_ACTOR_TOPUP.new()
	var refused: Dictionary = provider.call("request_topup", null, null)
	assert_eq(refused, {"ok": false, "pending": false, "code": "fixture_source_required"})
	provider.free()
