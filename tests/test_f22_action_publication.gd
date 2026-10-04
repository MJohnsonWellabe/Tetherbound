extends "res://tests/test_case.gd"

class TrackedHost extends "res://scripts/combat/accepted_action_host.gd":
	func _tracking_enabled() -> bool:
		return true


func _fixture() -> Dictionary:
	var host := TrackedHost.new(1)
	var record: Dictionary = host.open(1, "meadows", "wild", {
		"species_id": "bramblebun", "hp": 30.0, "hp_max": 30.0,
		"position": Vector3(2.0, 0.0, 0.0), "body_generation": 1,
		"card": {"uid": "wild-a"}}, "owned-a", "character-a")
	var id := str(record.encounter_id)
	var owned := {"uid": "owned-a", "hp": 100.0, "max_hp": 100.0, "fainted": false}
	var bound: Dictionary = host.bind_actor_body(id, 1, "character-a", owned, 101)
	var generation := int(bound.get("vitals", {}).get("body_generation", 0))
	var binding := {"character_id": "character-a", "creature_uid": "owned-a",
		"actor_generation": generation, "deployment_generation": generation, "body_instance_id": 101}
	var intent := {"encounter_id": id, "action": 1, "move_id": "tackle", "slot": "quick",
		"facing": Vector3.RIGHT, "move": {"range": 2.6, "cone_degrees": 90.0,
			"power": 9.0, "is_quick": true}}
	var view := {"now_ms": 10000, "origin": Vector3.ZERO, "bodies": [], "f22_actor_binding": binding}
	var verdict: Dictionary = host.validate_strike(intent, 1, view)
	return {"host": host, "id": id, "binding": binding, "verdict": verdict, "owned": owned,
		"intent": intent, "view": view}


func _begin(fixture: Dictionary) -> Dictionary:
	return fixture.host.begin_move_action_resolution(fixture.id, 1, 1, fixture.binding, "wild-a", 1)


func test_actual_admission_and_debit_hold_teardown_until_exact_publication() -> void:
	var fixture := _fixture()
	assert_true(fixture.verdict.get("ok") == true)
	assert_true(fixture.verdict.get("delta", {}).get("hit") == true)
	assert_false(bool(fixture.host.move_action_publication_pending(fixture.id)))
	var begun := _begin(fixture)
	assert_true(begun.get("ok") == true and begun.get("tracked") == true)
	assert_true(bool(fixture.host.move_action_publication_pending(fixture.id)))
	assert_false(_begin(fixture).get("ok") == true, "a duplicate arrival cannot invoke the damage writer again")
	assert_false(fixture.host.bind_actor_body(fixture.id, 1, "character-a", fixture.owned, 202).get("ok") == true)
	fixture.host.close(fixture.id)
	fixture.host.forget(fixture.id)
	assert_eq(str(fixture.host.phase(fixture.id)), "active", "pending original prevents close/forget")
	var rolled := {"hp": 21.0, "hp_max": 30.0, "damage": 999.0, "killed": false}
	(fixture.verdict.delta as Dictionary).merge(rolled, true)
	fixture.host.set_opponent_hp(fixture.id, 21.0, 30.0, rolled)
	assert_true(bool(fixture.host.record_move_action_outcome(fixture.id, 1, begun.action_id, rolled, fixture.verdict)))
	var original: Dictionary = fixture.host.move_action_original(fixture.id, 1, begun.action_id)
	assert_eq(float(original.outcome.actual_hp_debit), 9.0, "credit source is actual clamped HP debit, never a claimed damage field")
	assert_true(bool(fixture.host.move_action_publication_pending(fixture.id)))
	assert_false(bool(fixture.host.acknowledge_move_action_publication(fixture.id, 1, begun.action_id, {"ok": true})))
	assert_true(bool(fixture.host.acknowledge_move_action_publication(fixture.id, 1, begun.action_id, fixture.verdict)))
	assert_false(bool(fixture.host.move_action_publication_pending(fixture.id)))
	assert_false(_begin(fixture).get("ok") == true, "completed action remains non-arrivable")
	assert_true((fixture.host.pending_actor_vitals(fixture.id) as Array).is_empty(), "observer creates no new portable vitals receipt")


func test_actor_rebind_and_target_replacement_cannot_resolve_old_admission() -> void:
	var fixture := _fixture()
	assert_true(fixture.verdict.get("ok") == true)
	assert_true(fixture.host.bind_actor_body(fixture.id, 1, "character-a", fixture.owned, 202).get("ok") == true)
	assert_false(_begin(fixture).get("ok") == true, "real canonical body generation invalidates the old launch")
	assert_false(bool(fixture.host.move_action_publication_pending(fixture.id)))
	fixture = _fixture()
	assert_true(bool(fixture.host.set_opponent(fixture.id, {"species_id": "bramblebun", "hp": 30.0,
		"hp_max": 30.0, "position": Vector3(2.0, 0.0, 0.0), "body_generation": 2, "card": {"uid": "wild-b"}})))
	assert_false(_begin(fixture).get("ok") == true)
	assert_eq(float(fixture.host.record(fixture.id).opponent.hp), 30.0)


func test_killing_original_retains_pending_fence_across_terminal_phase() -> void:
	var fixture := _fixture()
	var begun := _begin(fixture)
	assert_true(begun.get("ok") == true)
	var rolled := {"hp": 0.0, "hp_max": 30.0, "damage": 80.0, "killed": true}
	(fixture.verdict.delta as Dictionary).merge(rolled, true)
	fixture.host.set_opponent_hp(fixture.id, 0.0, 30.0, rolled)
	assert_true(bool(fixture.host.record_move_action_outcome(fixture.id, 1, begun.action_id, rolled, fixture.verdict)))
	fixture.host.set_phase(fixture.id, "done")
	assert_eq(str(fixture.host.phase(fixture.id)), "active", "generic terminal changes cannot discard the pending original")
	assert_true(bool(fixture.host.publish_move_action_terminal(fixture.id, 1, begun.action_id, "done")))
	assert_eq(str(fixture.host.phase(fixture.id)), "done")
	assert_true(bool(fixture.host.move_action_publication_pending(fixture.id)), "terminal publication preserves the SAME action authority")
	assert_true(bool(fixture.host.acknowledge_move_action_publication(fixture.id, 1, begun.action_id, fixture.verdict)))
	assert_eq(float(fixture.host.move_action_original(fixture.id, 1, begun.action_id).outcome.actual_hp_debit), 30.0)


func test_rejected_real_validation_creates_no_accepted_action() -> void:
	var fixture := _fixture()
	var stale := (fixture.binding as Dictionary).duplicate()
	stale["character_id"] = "other-character"
	var view := (fixture.view as Dictionary).duplicate()
	view["f22_actor_binding"] = stale
	var intent := (fixture.intent as Dictionary).duplicate(true)
	intent["action"] = 2
	view["now_ms"] = 20000
	assert_false(fixture.host.validate_strike(intent, 1, view).get("ok") == true)
	assert_false(fixture.host.begin_move_action_resolution(fixture.id, 1, 2, stale, "wild-a", 1).get("ok") == true)
	assert_false(bool(fixture.host.move_action_publication_pending(fixture.id)))
