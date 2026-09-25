extends "res://tests/test_case.gd"

## Coordinator interim ruling (WO-F11-04): a trainer committed to a creature
## fight is not aimed at or hit by storm strikes; the strike may aim at the
## piloted creature, and aiming at the trainer resumes when the fight ends.
## Host-authoritative and per peer.
const LIGHTNING := preload("res://scripts/world/stormwood_lightning.gd")
const RULES := preload("res://scripts/world/stormwood_surge_rules.gd")

const TRAINER := Vector3(10, 0, 20)
const CREATURE := Vector3(14, 0, 23)


func test_config_spares_a_fighting_trainer() -> void:
	assert_true(bool(RULES.new().config.strike.get("spare_trainer_in_fight", false)))


func test_a_fighting_trainer_is_never_targeted_or_hit() -> void:
	assert_eq(LIGHTNING.strike_aim(TRAINER, true, CREATURE, true), CREATURE)
	assert_eq(LIGHTNING.strike_aim(TRAINER, true, null, true), null)
	assert_false(LIGHTNING.trainer_can_be_hit(true, true))


func test_targeting_resumes_when_the_fight_ends() -> void:
	var open := {"enc-1": {"phase": "active", "participants": {7: {}}}}
	assert_true(LIGHTNING.peer_in_fight(7, false, open, []))
	var done := {"enc-1": {"phase": "done", "participants": {7: {}}}}
	var fighting := LIGHTNING.peer_in_fight(7, false, done, [])
	assert_false(fighting)
	assert_eq(LIGHTNING.strike_aim(TRAINER, fighting, CREATURE, true), TRAINER)
	assert_true(LIGHTNING.trainer_can_be_hit(fighting, true))


func test_host_authority_exempts_only_the_fighting_peer() -> void:
	var records := {"enc-1": {"phase": "active", "participants": {7: {}}}}
	assert_true(LIGHTNING.peer_in_fight(7, false, records, []))
	assert_false(LIGHTNING.peer_in_fight(8, false, records, []))
	# A Stormwood hosted trainer fight's participant list, and the host's own
	# local fight, count too.
	assert_true(LIGHTNING.peer_in_fight(9, false, {}, [9]))
	assert_true(LIGHTNING.peer_in_fight(1, true, {}, []))
	assert_false(LIGHTNING.peer_in_fight(1, false, {}, []))
	assert_eq(LIGHTNING.strike_aim(TRAINER, LIGHTNING.peer_in_fight(8, false, records, []), CREATURE, true), TRAINER)


func test_negative_control_flag_off_targets_the_fighting_trainer() -> void:
	assert_eq(LIGHTNING.strike_aim(TRAINER, true, CREATURE, false), TRAINER)
	assert_true(LIGHTNING.trainer_can_be_hit(true, false))
