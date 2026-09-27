extends "res://tests/test_case.gd"

## F14#1: a guest joining a trainer/boss fight mirrors the host's CURRENT
## creature from the record's opponent row instead of borrowing a nearby
## ambient wild. These cover the identity it builds; the two-peer proof is
## tools/net/proof_scenarios/x05_f14_nerissa_coop_parity.json.

const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const CODEC := preload("res://scripts/save/water_capture_codec.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")


func _row(creature: RefCounted, hp: float, round_no: int, with_card: bool) -> Dictionary:
	var row := {"species_id": str(creature.get("species_id")), "level": int(creature.get("level")),
		"hp": hp, "hp_max": float(creature.get("max_hp")), "round": round_no,
		"position": [4.0, 1.0, 5.0], "foot_position": [4.0, 0.0, 5.0], "facing": [0.0, 0.0, 1.0]}
	if with_card:
		row["card"] = CODEC.encode(creature)
	return row


func test_mirror_instance_carries_the_host_identity_and_pool() -> void:
	var director: Node = DIRECTOR.new()
	var host_foe: RefCounted = TRAINERS.creature_for({"species": "terrapup", "level": 55})
	assert_true(host_foe != null, "fixture: a level-55 team member")
	var row := _row(host_foe, 120.0, 1, true)
	var mirror: RefCounted = director.call("_legacy_opponent_instance", row)
	assert_true(mirror != null, "a card row builds an instance")
	assert_eq(str(mirror.get("species_id")), "terrapup")
	assert_eq(int(mirror.get("level")), 55, "the host's level, not an ambient wild's")
	assert_almost_eq(float(mirror.get("max_hp")), float(host_foe.get("max_hp")), 0.001,
		"the bar's denominator is the host's max HP")
	assert_almost_eq(float(mirror.get("hp")), 120.0, 0.001, "and its current HP")
	var bare := _row(host_foe, 50.0, 1, false)
	var spawned: RefCounted = director.call("_legacy_opponent_instance", bare)
	assert_true(spawned != null, "no card: the species at the record's level")
	assert_eq(int(spawned.get("level")), 55)
	assert_almost_eq(float(spawned.get("hp")), 50.0, 0.001)
	var wrong := bare.duplicate(true)
	wrong["species_id"] = "not_a_species"
	assert_true(director.call("_legacy_opponent_instance", wrong) == null,
		"an unbuildable row mirrors nothing (the caller falls back)")
	director.free()


func test_round_key_separates_identical_consecutive_members() -> void:
	var one := {"species_id": "water_cannonback", "level": 55, "round": 1}
	var two := {"species_id": "water_cannonback", "level": 55, "round": 2}
	assert_false(DIRECTOR._legacy_opponent_key(one) == DIRECTOR._legacy_opponent_key(two),
		"the next send-out of the same species is still a new member")
	var hp_changed := one.duplicate()
	hp_changed["hp"] = 3.0
	assert_eq(DIRECTOR._legacy_opponent_key(one), DIRECTOR._legacy_opponent_key(hp_changed),
		"an HP update is the same member")
