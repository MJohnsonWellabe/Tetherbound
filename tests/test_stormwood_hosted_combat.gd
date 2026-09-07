extends "res://tests/test_case.gd"

## Host-owned Stormwood fights have two seams that must stay independent of
## rendering: changing which participant is nearest must not restart the
## opponent's current attack, and the local party must receive one victory
## award when the hosted award hook and host's done record arrive in either
## order. Two-process smoke covers the killing-verdict delivery path itself.

const HOST_FIGHT := preload("res://scripts/combat/stormwood_authoritative_fight.gd")
const STORMWOOD_MANAGER := preload("res://scripts/combat/stormwood_combat_manager.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")

const DEFINITION := {
	"display_name": "Terrapup", "type": "ground",
	"base_hp": 100.0, "base_attack": 20.0, "base_defence": 20.0,
}


class HostedTransport extends Node:
	func hosted_transport() -> bool:
		return true


func _creature(level: int, nickname: String) -> RefCounted:
	var creature: RefCounted = CREATURE.from_species("terrapup", DEFINITION)
	creature.level = level
	creature.nickname = nickname
	return creature


func _hosted_manager(encounter_id: String, party: Array[RefCounted], enemy: RefCounted) -> Node:
	var manager := STORMWOOD_MANAGER.new()
	manager.set("_party", party)
	manager.set("_active_index", 0)
	manager.set("_enemy", enemy)
	# A done record normally begins resolution. These tests exercise the
	# already-authoritative award seam without requiring a rendered arena.
	manager.set("state", STORMWOOD_MANAGER.State.RESOLVING)
	var transport := HostedTransport.new()
	manager.add_child(transport)
	manager.bind_encounter(transport, encounter_id, "trainer")
	return manager


func _killing_done_record(encounter_id: String, seq: int) -> Dictionary:
	return {
		"encounter_id": encounter_id,
		"seq": seq,
		"phase": "done",
		"opponent": {"hp": 0.0, "hp_max": 100.0},
	}


func test_host_retarget_changes_the_body_without_restarting_an_active_windup() -> void:
	var engine := HOST_FIGHT.new()
	var opponent := WILD.new()
	var first_target := Node3D.new()
	var nearer_target := Node3D.new()
	engine.set("_wild", opponent)
	engine.set("_ally_body", first_target)
	# These are the live AI's attack clocks. A call to set_engaged() would reset
	# them, which lets players indefinitely suppress a swing by swapping nearest.
	opponent.set("_opponent", first_target)
	opponent.set("_intent", 2)
	opponent.set("_beat_left", 0.42)
	opponent.set("_cooldown", 0.87)

	engine.set_target_body(nearer_target)

	assert_eq(engine.get("_ally_body"), nearer_target,
		"the host engine should point its hit selection at the newly nearest body")
	assert_eq(opponent.get("_opponent"), nearer_target,
		"the wild body should face the newly selected participant")
	assert_eq(int(opponent.get("_intent")), 2,
		"retargeting must leave the wind-up intent in progress")
	assert_almost_eq(float(opponent.get("_beat_left")), 0.42, 0.0001,
		"retargeting must not restart the current wind-up clock")
	assert_almost_eq(float(opponent.get("_cooldown")), 0.87, 0.0001,
		"retargeting must not reset the next-attack cooldown")

	opponent.free()
	first_target.free()
	nearer_target.free()
	engine.free()


func test_hosted_award_hook_awards_once_when_called_before_done_record() -> void:
	var winner := _creature(3, "Winner")
	var manager := _hosted_manager("round-a", [winner] as Array[RefCounted], _creature(4, "Enemy"))

	# The hosted award hook can run before the record, and that record can be
	# delivered twice by the session transport.
	manager.call("_award_victory")
	manager.apply_encounter_record(_killing_done_record("round-a", 1))
	manager.apply_encounter_record(_killing_done_record("round-a", 1))

	assert_eq(winner.battles_fought, 1,
		"award hook then duplicate done snapshots must credit one completed fight")
	manager.free()


func test_hosted_award_hook_awards_once_when_done_record_arrives_first() -> void:
	var winner := _creature(3, "Winner")
	var manager := _hosted_manager("round-a", [winner] as Array[RefCounted], _creature(4, "Enemy"))

	manager.apply_encounter_record(_killing_done_record("round-a", 1))
	manager.call("_award_victory")
	manager.apply_encounter_record(_killing_done_record("round-a", 2))

	assert_eq(winner.battles_fought, 1,
		"done record then hosted award hook must still credit one completed fight")
	manager.free()


func test_a_new_hosted_round_resets_the_one_award_guard() -> void:
	var winner := _creature(3, "Winner")
	var manager := _hosted_manager("round-a", [winner] as Array[RefCounted], _creature(4, "Enemy A"))

	manager.apply_encounter_record(_killing_done_record("round-a", 1))
	var transport := HostedTransport.new()
	manager.add_child(transport)
	manager.bind_encounter(transport, "round-b", "trainer")
	manager.set("_enemy", _creature(4, "Enemy B"))
	manager.apply_encounter_record(_killing_done_record("round-b", 1))
	manager.apply_encounter_record(_killing_done_record("round-b", 1))

	assert_eq(winner.battles_fought, 2,
		"a fresh bound round must award once after the previous round's guard fired")
	manager.free()
