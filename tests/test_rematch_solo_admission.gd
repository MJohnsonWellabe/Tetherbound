extends "res://tests/test_case.gd"

## Only the production admission guard is exercised here. The send-out stub
## avoids building a world; actual combat admission requires the F20 replay.
const SESSION := preload("res://scripts/net/session.gd")
const RULES := preload("res://scripts/repeatables/rematch_rules.gd")

class AdmissionProbe extends "res://scripts/combat/encounter_director.gd":
	func can_challenge(_spec: Dictionary) -> bool: return true
	func _send_out_next_creature() -> bool: return true

func test_solo_and_host_admit_but_clients_and_missing_writer_refuse() -> void:
	var session := SESSION.new()
	var director := AdmissionProbe.new()
	director.set("_session", session)
	var spec := RULES.encounter_spec({"id": "practice_trainer", "team": [{"species": "bramblebun", "level": 1}]}, "endgame")
	assert_false(spec.is_empty())
	assert_false(session.is_active())
	assert_true(session.is_host())
	assert_false(director.begin_trainer_battle(spec), "offline solo still needs its actual outcome writer")
	director.set("_rematch_outcome_writer", func(_source: Node, _spec: Dictionary, _won: bool) -> Dictionary: return {})
	assert_true(director.begin_trainer_battle(spec), "offline solo reaches the ordinary trainer send-out path")
	session.set("_mode", "host")
	assert_true(session.is_active())
	assert_true(director.begin_trainer_battle(spec), "active host also reaches send-out")
	session.set("_mode", "client")
	assert_false(director.begin_trainer_battle(spec), "client cannot start an authoritative rematch")
	session.set("_mode", "")
	session.set("_preparing_client", true)
	assert_false(director.begin_trainer_battle(spec), "preparing client cannot use offline authority")
	director.set("_session", null)
	assert_false(director.begin_trainer_battle(spec), "missing session cannot supply authority")
	director.free()
	session.free()
