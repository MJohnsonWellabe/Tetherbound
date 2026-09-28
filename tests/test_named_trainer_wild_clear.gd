extends "res://tests/test_case.gd"

## F04#2 (round-1 judge B1): no wild body spawns or wanders onto a named
## Meadows trainer's fight ground (combat.json arena.named_trainer_wild_clear_m).

const DIRECTOR := preload("res://scripts/combat/encounter_director.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")


func _stand(id: String) -> Vector3:
	var at: Array = TRAINERS.trainer(id).get("position", []) as Array
	return Vector3(float(at[0]), 0.0, float(at[1])) if at.size() >= 2 else Vector3.INF


func test_every_captain_and_the_warden_hold_a_clear_ground() -> void:
	var director: Node = DIRECTOR.new()
	var clear := float((MATH.config().get("arena", {}) as Dictionary).get("named_trainer_wild_clear_m", 0.0))
	assert_true(clear >= 11.0, "the clear ground must reach at least the 11 m fight ring")
	for id: String in ["relay_captain", "captain_riverwatch", "captain_field", "captain_ridge", "warden_aldis"]:
		var stand := _stand(id)
		assert_ne(stand, Vector3.INF, "%s has a stand" % id)
		assert_false(bool(director.call("_clear_of_named_trainer_grounds", stand + Vector3(3.0, 0.0, 2.0))),
			"a wild may not settle 3.6 m from %s" % id)
		assert_true(bool(director.call("_clear_of_named_trainer_grounds", stand + Vector3(clear + 1.0, 0.0, 0.0))),
			"a wild may settle just outside %s's ground" % id)
	director.free()


func test_ordinary_trainers_and_open_country_are_unaffected() -> void:
	var director: Node = DIRECTOR.new()
	var grunts := 0
	for raw: Variant in TRAINERS.trainers():
		var spec := raw as Dictionary
		if str(spec.get("rank", "")) != "grunt":
			continue
		var at: Array = spec.get("position", []) as Array
		var stand := Vector3(float(at[0]), 0.0, float(at[1]))
		var named_near := false
		for id: String in ["relay_captain", "captain_riverwatch", "captain_field", "captain_ridge", "warden_aldis"]:
			if _stand(id).distance_to(stand) < 30.0:
				named_near = true
		if named_near:
			continue
		grunts += 1
		assert_true(bool(director.call("_clear_of_named_trainer_grounds", stand)),
			"%s's ground is not a named fight ground" % str(spec.get("id", "?")))
	assert_true(grunts > 0, "the scan found ordinary trainers")
	director.free()
