extends "res://tests/test_case.gd"

## F14#0 C3 after COMBAT §5 contact spacing: Tess's Mirejaw asks the fight
## camera for a near side-on composition and the trainer for a stand beside the
## ally. Both are opponent-owned, opt-in and presentation-only; every other
## body keeps the shared camera and the arena-midpoint stand.

const MANAGER := preload("res://scripts/combat/combat_manager.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")


class FakeFoe extends Node3D:
	var yaw := 0.0

	func camera_composition_yaw_deg() -> float:
		return yaw


func _tess_team() -> Array:
	var text := FileAccess.get_file_as_string("res://data/config/water_characters.json")
	var data: Variant = JSON.parse_string(text)
	assert_true(data is Dictionary, "water_characters.json parses")
	for npc: Dictionary in (data as Dictionary).get("trainers", []):
		if str(npc.get("id", "")) == "water_trainer_tess":
			return npc.get("team", []) as Array
	return []


func test_a_body_without_the_key_keeps_the_shared_composition() -> void:
	assert_eq(MANAGER.opponent_composition_yaw_deg(null), 0.0)
	var plain := Node3D.new()
	assert_eq(MANAGER.opponent_composition_yaw_deg(plain), 0.0, "no accessor, no override")
	plain.free()


func test_an_authored_yaw_is_read_and_bounded() -> void:
	var foe := FakeFoe.new()
	foe.yaw = 70.0
	assert_eq(MANAGER.opponent_composition_yaw_deg(foe), 70.0)
	foe.yaw = 400.0
	assert_eq(MANAGER.opponent_composition_yaw_deg(foe), 100.0, "a malformed value cannot turn the lens behind the ally")
	foe.yaw = -400.0
	assert_eq(MANAGER.opponent_composition_yaw_deg(foe), -100.0)
	foe.free()


func test_the_combat_override_reaches_the_accessors() -> void:
	var body: Node = WILD.new()
	assert_eq(float(body.call("camera_composition_yaw_deg")), 0.0, "absent means the shared value")
	assert_false(bool(body.call("camera_trainer_beside_ally")))
	body.set("combat_override", {"camera_composition_yaw_deg": 70.0, "camera_trainer_beside_ally": true})
	assert_eq(float(body.call("camera_composition_yaw_deg")), 70.0)
	assert_true(bool(body.call("camera_trainer_beside_ally")))
	body.free()


func test_only_tess_mirejaw_is_opted_in() -> void:
	var team := _tess_team()
	assert_true(team.size() >= 3, "Tess's team is authored")
	var opted := 0
	for member: Dictionary in team:
		var combat: Dictionary = member.get("combat", {}) as Dictionary
		var has_yaw := combat.has("camera_composition_yaw_deg")
		if str(member.get("species", "")) == "mirejaw":
			assert_true(has_yaw and bool(combat.get("camera_trainer_beside_ally", false)), "Mirejaw carries both keys")
			assert_true(float(combat.get("camera_composition_yaw_deg", 0.0)) > 35.0, "wider than the shared 35 degrees")
			opted += 1
		else:
			assert_false(has_yaw or combat.has("camera_trainer_beside_ally"),
				"%s keeps the shared camera (its C3 frames passed)" % str(member.get("species", "")))
	assert_eq(opted, 1)
