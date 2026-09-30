extends SceneTree

## F23 actual production manager debit/CAS smoke. No world boot or geometry
## claim; the target body is a synthetic boundary double. Unit run_tests._init
## has no Engine main loop, so these intact assertions run after initialization.
const MASTERY := preload("res://scripts/creatures/move_mastery.gd")

class Individual extends RefCounted:
	var uid := "companion-1"
	var known_moves: Array[String] = ["pebble_toss"]
	var move_mastery_uses: Dictionary = {}
	var move_mastery_receipts: Dictionary = {}
	var move_quick := "pebble_toss"
	var move_charged := "stone_rush"
	var move_utility := ""
	var move_ultimate := ""
	var loadout_revision := 0
	var loadout_last_edit: Dictionary = {}

class TransactionBody extends Node3D:
	var critical := true
	var poise_calls := 0
	var impulse_calls := 0
	func stagger_critical_ready() -> bool: return critical
	func consume_stagger_critical() -> bool:
		var before := critical
		critical = false
		return before
	func apply_poise_damage(_damage: float, _force: bool) -> bool:
		poise_calls += 1
		return false
	func add_impulse(_direction: Vector3, _magnitude: float) -> void: impulse_calls += 1
	func combat_config() -> Dictionary: return {}
	func body_height() -> float: return 1.0
	func centre() -> Vector3: return global_position
	func poise_fraction() -> float: return 1.0
	func is_staggered() -> bool: return critical
	func stagger_seconds_left() -> float: return .6 if critical else 0.0

class TransactionCase extends "res://tests/test_case.gd":
	func exercise(tree: SceneTree) -> void:
		var manager := preload("res://scripts/combat/combat_manager.gd").new()
		var body := TransactionBody.new()
		tree.root.add_child(manager)
		tree.root.add_child(body)
		var enemy := preload("res://scripts/creatures/creature_instance.gd").from_species("bramblebun",preload("res://scripts/creatures/creature_species.gd").definition("bramblebun"))
		enemy.hp = 1.0
		enemy.fainted = false
		manager.set("_enemy", enemy)
		manager.set("_wild", body)
		var captured: Array = []
		var reject := func(uid: String, before: float, applied: float) -> Dictionary:
			captured.append([uid,before,applied,enemy.hp])
			return {"ok": false}
		var result: Dictionary = manager.host_roll_damage({"attack": 100.0},"pebble_toss",9.0,false,{"mastery_rank": 5,"mastery_commit": reject})
		assert_true(result.is_empty(),"refused CAS produces no accepted damage verdict")
		assert_eq(captured.size(),1)
		assert_eq(captured[0],[enemy.uid,1.0,1.0,0.0],"callback sees actual clamped committed HP debit, including overkill")
		assert_eq(enemy.hp,1.0,"refusal restores HP before any poise/impulse/snapshot")
		assert_false(enemy.fainted,"refusal restores faint state too")
		assert_true(body.critical,"refusal does not spend the existing critical window")
		assert_eq(body.poise_calls,0)
		assert_eq(body.impulse_calls,0)
		var mastered := Individual.new()
		var previous: Array = []
		for index: int in 300: previous.append("earned:%d" % index)
		mastered.move_mastery_uses = {"pebble_toss": 300}
		mastered.move_mastery_receipts = {"pebble_toss": previous}
		var saturated := func(uid: String, before: float, applied: float) -> Dictionary:
			var staged := MASTERY.stage_landed_use(mastered,{"action_id":"new:saturated:1","move_id":"pebble_toss",
				"attacker_uid":mastered.uid,"target_uid":uid,"target_hp_before":before,"applied_damage":applied})
			return {"ok": str(staged.get("reason","")) == "saturated"}
		result = manager.host_roll_damage({"attack": 100.0},"pebble_toss",9.0,false,{"mastery_rank": 5,"mastery_commit": saturated})
		assert_false(result.is_empty(),"legal rank-five no-growth contact still deals damage")
		assert_eq(enemy.hp,0.0)
		assert_true(enemy.fainted)
		assert_false(body.critical,"successful contact spends critical once")
		assert_eq(mastered.move_mastery_uses.pebble_toss,300)
		assert_eq(mastered.move_mastery_receipts.pebble_toss.size(),300,"no receipt growth after mastery cap")
		enemy.hp = enemy.max_hp
		enemy.fainted = false
		body.critical = false
		result = manager.host_roll_damage({"attack": 1.0},"pebble_toss",.001,false,{"mastery_rank": 5})
		var damage_cfg: Dictionary = preload("res://scripts/combat/combat_math.gd").config().get("damage", {})
		assert_true(float(result.damage) >= float(damage_cfg.get("minimum", 1.0)))
		assert_true(float(result.damage) <= float(damage_cfg.get("minimum", 1.0)) * (1.0 + float(damage_cfg.get("variance", .1))),
			"mastery enters power before the shared minimum; it cannot multiply already floored damage")
		manager.free()
		body.free()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var proof := TransactionCase.new()
	proof.exercise(self)
	if proof.assertion_count != 16:
		push_error("F23 transaction aborted before all 16 original assertions executed")
		quit(1)
		return
	for failure: String in proof.failures: push_error(failure)
	print("F23 production transaction: %d assertions, %d failed" % [proof.assertion_count, proof.failures.size()])
	if proof.failures.is_empty(): print("ALL CHECKS PASSED: initialized manager rollback/saturation/damage floor")
	quit(0 if proof.failures.is_empty() else 1)
