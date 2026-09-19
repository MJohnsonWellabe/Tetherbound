extends TestCase

const OBSERVER := preload("res://tools/net/strike_transaction_observer.gd")
const IDENTITY := {"encounter_id": "1:1", "peer_id": 123456789,
	"action": 9003, "victim_peer_id": 1}
const INTENT := {"kind": "strike_intent", "encounter_id": "1:1", "action": 9003}


# Override only the transaction body, not its production dispatcher/hook.
# Deliberate damage here proves the actual hook catches an in-handler bug.
class DirectorFixture extends "res://scripts/combat/encounter_director.gd":
	var sample := {"encounter_id": "1:1", "victim_peer_id": 1,
		"victim_hp": 100.0, "opponent_hp": 55.0, "struck_count": 2, "host_now_ms": 1000}
	var damage := 0.0
	var opponent_damage := 0.0
	var enemy_hit := false
	func _ensure_encounter_arbiters() -> void:
		pass
	func _host_strike(_intent: Dictionary, peer_id: int) -> Dictionary:
		sample.victim_hp -= damage
		sample.opponent_hp -= opponent_damage
		if enemy_hit:
			sample.struck_count += 1
		return {"ok": false, "kind": "strike_intent", "peer": peer_id,
			"code": "friendly_target", "delta": {}}
	func read_sample() -> Dictionary:
		return sample


func _observe(director: DirectorFixture) -> RefCounted:
	var observer := OBSERVER.new()
	observer.arm(IDENTITY, director.read_sample)
	director.host_strike_started.connect(observer.started)
	director.host_strike_finished.connect(observer.finished)
	return observer


func test_actual_dispatch_isolates_damage_outside_the_strike_transaction() -> void:
	var director := DirectorFixture.new()
	var observer := _observe(director)
	# An enemy hit between coordinator arm and RPC arrival is outside scope.
	director.sample.victim_hp -= 11.75
	director.sample.struck_count += 1
	var verdict := director._host_commit_encounter(INTENT.duplicate(true), int(IDENTITY.peer_id))
	assert_eq(verdict.code, "friendly_target")
	# A second AI turn after return cannot mutate the captured dictionaries.
	director.sample.victim_hp -= 7.0
	director.sample.struck_count += 1
	var receipt: Dictionary = observer.get("receipt")
	assert_almost_eq(float(receipt.before.victim_hp), 88.25)
	assert_almost_eq(float(receipt.after.victim_hp), 88.25)
	assert_eq(receipt.before.struck_count, 3)
	assert_eq(receipt.after.struck_count, 3)
	assert_true(OBSERVER.assess(receipt, IDENTITY, 999).ok)
	director.free()


func test_actual_dispatch_rejects_friendly_damage_inside_refused_transaction() -> void:
	var director := DirectorFixture.new()
	var observer := _observe(director)
	director.damage = 11.75
	director._host_commit_encounter(INTENT.duplicate(true), int(IDENTITY.peer_id))
	var result := OBSERVER.assess(observer.get("receipt"), IDENTITY, 999)
	assert_false(result.ok, "friendly refusal cannot hide an in-handler HP mutation")
	assert_true(str(result.why).contains("victim_hp changed"))
	director.free()


func test_refusal_cannot_damage_opponent_or_reuse_an_unrelated_receipt() -> void:
	var director := DirectorFixture.new()
	var observer := _observe(director)
	var unrelated := INTENT.duplicate(true)
	unrelated.action = 9002
	director._host_commit_encounter(unrelated, int(IDENTITY.peer_id))
	assert_true((observer.get("receipt") as Dictionary).is_empty())
	director._host_commit_encounter(INTENT.duplicate(true), 42)
	assert_true((observer.get("receipt") as Dictionary).is_empty())
	unrelated = INTENT.duplicate(true)
	unrelated.encounter_id = "other"
	director._host_commit_encounter(unrelated, int(IDENTITY.peer_id))
	assert_true((observer.get("receipt") as Dictionary).is_empty())
	director.opponent_damage = 1.0
	director._host_commit_encounter(INTENT.duplicate(true), int(IDENTITY.peer_id))
	var receipt: Dictionary = observer.get("receipt")
	assert_false(OBSERVER.assess(receipt, IDENTITY, 999).ok)
	assert_false(OBSERVER.assess(receipt, IDENTITY, 1001).ok, "stale snapshots fail closed")
	assert_false(OBSERVER.assess({}, IDENTITY, 999).ok, "missing observer cannot pass")
	director.free()


func test_transaction_requires_matching_refusal_and_an_unchanged_enemy_hit_tally() -> void:
	var director := DirectorFixture.new()
	var observer := _observe(director)
	director._host_commit_encounter(INTENT.duplicate(true), int(IDENTITY.peer_id))
	var receipt: Dictionary = observer.get("receipt")
	var wrong := receipt.duplicate(true)
	wrong.verdict.code = "cooldown"
	assert_false(OBSERVER.assess(wrong, IDENTITY, 999).ok)
	wrong = receipt.duplicate(true)
	wrong.verdict.peer = 42
	assert_false(OBSERVER.assess(wrong, IDENTITY, 999).ok)
	wrong = receipt.duplicate(true)
	wrong.before.erase("victim_hp")
	assert_false(OBSERVER.assess(wrong, IDENTITY, 999).ok)
	# Re-arm the real observer, then increment the tally inside the real hook.
	observer.call("arm", IDENTITY, director.read_sample)
	director.enemy_hit = true
	director._host_commit_encounter(INTENT.duplicate(true), int(IDENTITY.peer_id))
	assert_false(OBSERVER.assess(observer.get("receipt"), IDENTITY, 999).ok)
	director.free()
