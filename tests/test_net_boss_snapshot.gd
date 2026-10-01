extends "res://tests/test_case.gd"

const PEER := preload("res://tools/net/peer_runner.gd")


class Creature extends RefCounted:
	var hp := 124.403


class Director extends RefCounted:
	var creature := Creature.new()
	var record := {"struck_counts": {1: 1}, "opponent": {"hp": 194.787}}

	func encounter_record() -> Dictionary:
		return record

	func ally_instance() -> RefCounted:
		return creature

	func boss_hit() -> void:
		creature.hp = 109.718
		record["struck_counts"][1] += 1


func test_hit_in_old_opening_gap_is_in_atomic_window() -> void:
	var director := Director.new()
	var pre := PEER.boss_combat_snapshot(director)
	# Previously HP was read before this hit, but the opening count after it.
	director.boss_hit()
	var legacy_opening_count := int(director.record["struck_counts"][1])
	var post := PEER.boss_combat_snapshot(director)
	assert_eq(legacy_opening_count, int(post["record"]["struck_counts"][1]),
		"negative control: the old inner counter window misses the hit")
	assert_true(float(pre["my_creature_hp"]) > float(post["my_creature_hp"]))
	assert_eq(int(post["record"]["struck_counts"][1]) - int(pre["record"]["struck_counts"][1]), 1,
		"atomic samples correctly reject the boss-contaminated window")


func test_hit_after_closing_sample_does_not_change_frozen_window() -> void:
	var director := Director.new()
	var pre := PEER.boss_combat_snapshot(director)
	var post := PEER.boss_combat_snapshot(director)
	# Previously the closing count was read before this hit and HP after it.
	director.boss_hit()
	assert_true(float(post["my_creature_hp"]) > director.creature.hp,
		"negative control: a later HP probe would widen the window")
	assert_eq(pre["my_creature_hp"], post["my_creature_hp"], "quiet-window HP remains exact")
	assert_eq(pre["record"]["struck_counts"], post["record"]["struck_counts"])
	assert_eq(int(post["record"]["struck_counts"][1]), 1, "later combat cannot mutate the sample")


func test_unexplained_hp_loss_still_fails_unchanged_hp_criterion() -> void:
	var director := Director.new()
	var pre := PEER.boss_combat_snapshot(director)
	director.creature.hp -= 5.0
	var post := PEER.boss_combat_snapshot(director)
	assert_eq(pre["record"]["struck_counts"], post["record"]["struck_counts"])
	assert_true(absf(float(post["my_creature_hp"]) - float(pre["my_creature_hp"])) >= 0.001,
		"a friendly-fire defect with no boss hit remains a failure")


const HOST := preload("res://scripts/net/encounter_host.gd")
const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const MOVES := preload("res://scripts/creatures/move_db.gd")
const CONTACT := preload("res://scripts/combat/contact_spacing.gd")


class GeometryBody extends Node3D:
	var sample_centre := Vector3(0.0, 2.0, 0.0)
	var half_length := 2.0

	func centre() -> Vector3:
		return sample_centre

	func body_radius() -> float:
		return 0.5

	func contact_half_length() -> float:
		return half_length


class GeometryManager extends RefCounted:
	var _moves: RefCounted = MOVES.load_default()
	var id := ""
	var opponent: Node3D

	func encounter_id() -> String:
		return id

	func enemy_body() -> Node3D:
		return opponent


class GeometryDirector extends RefCounted:
	var hosting := true
	var bodies := {}
	var card := {"creature_uid": "actual-deployed-uid", "move_quick": "burrow_strike"}

	func is_encounter_host() -> bool:
		return hosting

	func _local_peer_id() -> int:
		return 1

	func deployed_body_for(peer_id: int) -> Node3D:
		return bodies.get(peer_id) as Node3D

	func _creature_card_for(_peer_id: int) -> Dictionary:
		return card

	func host_card_cooldown_multiplier(_card: Dictionary) -> float:
		return 1.0


func test_body_scaled_host_gate_matches_actual_strike_validation() -> void:
	# Legal spacing can exceed the old four-metre fixture gate. Height must not
	# affect this horizontal production predicate; no move range is increased.
	for distance: float in [4.47, 6.0]:
		var body := GeometryBody.new()
		var opponent := GeometryBody.new()
		opponent.sample_centre = Vector3(distance, 9.0, 0.0)
		var manager := GeometryManager.new()
		manager.opponent = opponent
		var director := GeometryDirector.new()
		director.bodies = {1: body}
		var host := HOST.new()
		var rec: Dictionary = host.open(1, "meadows", "boss", {
			"species_id": "galecrest", "hp": 212.1, "hp_max": 212.1,
			"position": [distance, 9.0, 0.0]})
		manager.id = str(rec.encounter_id)
		var before := rec.duplicate(true)
		var authority_before := host.strike_authority_state(manager.id, 1)
		var geometry := PEER.boss_strike_geometry(director, manager, rec)
		assert_eq(geometry.size(), 1)
		assert_almost_eq(float(geometry[0].distance_m), distance, 0.0001,
			"use horizontal centres, not feet or vertical distance")
		var profile := MANAGER.host_move_profile(manager._moves, "player_quick", "burrow_strike",
			body.body_radius(), opponent.body_radius(), 1.0, CONTACT.pair_reach_need(body, opponent))
		assert_eq(geometry[0].range_m, float(profile.range), "the gate uses the unchanged production profile")
		assert_true(float(profile.range) > 4.47, "control pair legitimately clears the observed old gate")
		assert_eq(rec, before, "geometry read cannot mutate HP, participants, phase or Wind")
		assert_eq(host.strike_authority_state(manager.id, 1), authority_before, "geometry read admits no strike/cooldown")
		var result: Dictionary = host.validate_strike({"encounter_id": manager.id, "action": 1,
			"move": profile, "origin": [0.0, 2.0, 0.0], "facing": [1.0, 0.0, 0.0]}, 1,
			{"origin": body.centre(), "now_ms": 1000, "bodies": []})
		assert_eq(result.get("ok"), true)
		assert_eq(geometry[0].can_reach, result.delta.hit, "fixture eligibility agrees with real host geometry")
		assert_eq(result.delta.hit, distance == 4.47, "an actually out-of-range swing still misses")
		body.free()
		opponent.free()


func test_host_geometry_requires_current_fight_and_current_body() -> void:
	var body := GeometryBody.new()
	var opponent := GeometryBody.new()
	var manager := GeometryManager.new()
	manager.opponent = opponent
	var director := GeometryDirector.new()
	director.bodies = {1: body, 22: body}
	var host := HOST.new()
	var rec: Dictionary = host.open(1, "meadows", "boss", {
		"species_id": "galecrest", "hp": 212.1, "hp_max": 212.1, "position": [2.0, 2.0, 0.0]})
	manager.id = str(rec.encounter_id)
	host.join(manager.id, 22)
	var rows := PEER.boss_strike_geometry(director, manager, rec)
	assert_eq(rows.size(), 2)
	assert_eq(rows[0].peer_id, 1)
	assert_true(rows[0].is_local)
	assert_eq(rows[1].peer_id, 22)
	assert_false(rows[1].is_local)
	director.bodies.erase(22)
	assert_eq(PEER.boss_strike_geometry(director, manager, rec).size(), 1, "missing current body is unavailable")
	director.hosting = false
	assert_eq(PEER.boss_strike_geometry(director, manager, rec), [], "guest view cannot authorize the fixture gate")
	director.hosting = true
	manager.id = "other-fight"
	assert_eq(PEER.boss_strike_geometry(director, manager, rec), [], "another bound fight is unavailable")
	manager.id = str(rec.encounter_id)
	host.close(manager.id)
	assert_eq(PEER.boss_strike_geometry(director, manager, rec), [], "terminal record cannot stage a swing")
	body.free()
	opponent.free()
