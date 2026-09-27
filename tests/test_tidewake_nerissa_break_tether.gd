extends "res://tests/test_case.gd"

## BOSSES 4.11 Break Tether: Captain Nerissa's final send-out, Riptusk, fights
## with a 1.1 s heavy tell and 0.9 s recovery. Her multiplied strike power
## (foe_power_multiplier) still applies. Her earlier members keep the shared
## 0.8 s floor.

const DATA := preload("res://scripts/world/water_encounter_runtime_data.gd")
const MATH := preload("res://scripts/combat/combat_math.gd")


func _nerissa() -> Dictionary:
	var characters: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/water_characters.json"))
	for trainer: Dictionary in characters.get("trainers", []):
		if str(trainer.id) == "water_trainer_nerissa":
			return trainer
	return {}


func test_final_riptusk_carries_the_break_tether_heavy_tell() -> void:
	var nerissa := _nerissa()
	var team: Array = nerissa.get("team", [])
	assert_eq(team.size(), 4, "Nerissa keeps her four-creature team")
	var errors: Array[String] = []
	var last := DATA.team_member(nerissa, team[-1], errors)
	assert_true(errors.is_empty(), "team member translates cleanly: %s" % ", ".join(errors))
	assert_eq(str(team[-1].species), "riptusk", "Riptusk is the fourth and final send-out")
	var combat: Dictionary = last.get("combat", {})
	assert_almost_eq(float(combat.get("telegraph", 0.0)), 1.1, 0.001, "heavy tell 1.1 s")
	assert_almost_eq(float(combat.get("recovery", 0.0)), 0.9, 0.001, "recovery 0.9 s")
	var base := float(MATH.config().get("enemy_trainer", {}).get("power", MATH.config().get("enemy", {}).get("power", 8.0)))
	assert_almost_eq(float(combat.get("power", 0.0)), base * float(nerissa.foe_power_multiplier), 0.001,
		"the captain's power multiplier still applies")
	for index in team.size() - 1:
		var member := DATA.team_member(nerissa, team[index], errors)
		assert_false((member.get("combat", {}) as Dictionary).has("telegraph"),
			"%s keeps the shared tell floor" % str(team[index].species))
