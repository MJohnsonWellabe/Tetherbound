extends "res://tests/test_case.gd"

## F14#0 Aquaryn: an ordinary strike that authors `face_lock_fraction`
## (COMBAT §5) locks its heading for the rest of its tell; one that does not
## keeps full-tell tracking exactly as before.

const WILD := preload("res://scripts/creatures/wild_creature.gd")
const AI := preload("res://scripts/combat/combat_ai.gd")
const CREATURE := preload("res://scripts/creatures/creature_instance.gd")


class Target extends Node3D:
	func body_radius() -> float: return 0.6


func _wild(extra: Dictionary) -> Node:
	var wild := WILD.new()
	var target := Target.new()
	target.position = Vector3(0.0, 0.0, 3.0)
	var creature: RefCounted = CREATURE.from_species("guardian", {
		"display_name": "Guardian", "type": "water", "base_hp": 100.0,
		"base_attack": 20.0, "base_defence": 20.0,
	})
	wild.set("instance", creature)
	wild.set("_opponent", target)
	var cfg := {"power": 8.0, "telegraph": 1.7, "recovery": 2.8, "range": 16.0,
		"cone_degrees": 28.0, "lunge": 3.4, "preferred_range": 11.2,
		"body_clearance": 1.0, "damage_scale": 1.6}
	cfg.merge(extra, true)
	wild.set("_combat_cfg", cfg)
	wild.add_child(target)
	return wild


func test_ordinary_strike_without_lock_tracks_the_whole_tell() -> void:
	var wild := _wild({})
	wild.call("_enter", AI.Intent.TELEGRAPH)
	assert_true((wild.get("_selected_attack") as Dictionary).is_empty(), "no selected attack: today's path")
	wild.set("_beat_left", 0.01)
	assert_false(wild.call("_selected_heading_is_locked"), "ordinary strike never locks")
	wild.free()


func test_authored_face_lock_locks_after_its_fraction() -> void:
	var wild := _wild({"face_lock_fraction": 0.5})
	wild.call("_enter", AI.Intent.TELEGRAPH)
	wild.set("_beat_left", 1.0)
	assert_false(wild.call("_selected_heading_is_locked"), "first half still tracks")
	wild.set("_beat_left", 0.8)
	assert_true(wild.call("_selected_heading_is_locked"), "second half is locked")
	assert_almost_eq(float((wild.call("combat_config") as Dictionary).range), 16.0, 0.5,
		"the locked profile keeps the authored reach")
	wild.call("_enter", AI.Intent.RECOVER)
	assert_true(wild.call("_selected_heading_is_locked"), "the lock holds through recovery")
	wild.call("_enter", AI.Intent.REPOSITION)
	assert_true((wild.get("_selected_attack") as Dictionary).is_empty(), "the tell is released afterwards")
	assert_true((wild.get("_combat_cfg") as Dictionary).has("range"),
		"clearing the selected attack never clears the live config")
	wild.free()


func test_face_lock_is_an_allowed_override_key() -> void:
	assert_true(WILD._COMBAT_OVERRIDE_KEYS.has("face_lock_fraction"))
