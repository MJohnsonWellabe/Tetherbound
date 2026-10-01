extends SceneTree

## ROOT-only named acceptance component proof. Does not replace ordinary-play,
## SaveGame, bool-save/ACK/rejoin, independent art or character authority proof.
const EVOLUTION := preload("res://scripts/creatures/evolution.gd")
var checks := 0
var failures: Array[String] = []

func _initialize() -> void:
	for entry: Array in [["mudsnout", 2, "heartstone", "tuskroot"],
		["mudsnout", 2, "sunstone", "ashtusk"], ["mosshell", 3, "", "cannonback"],
		["craghorn", 4, "", "stormcapra"]]:
		var before := card(str(entry[0]), int(entry[1]) * 10)
		var frozen := before.duplicate(true)
		var result := EVOLUTION.prepare_feast_choice(before, int(entry[1]), "evolve", str(entry[2]))
		check(result.get("ok") == true, "evolve " + str(entry[3]))
		if result.get("ok") == true:
			check(result.creature.species_id == entry[3], "target " + str(entry[3]))
			check(before == frozen, "planner never mutates input")
			check(result.debit == {}, "cooked stone never debited again")
			for field: String in before:
				if field not in result.species_patch and field != "evolution_choices":
					check(result.creature[field] == before[field], "preserved " + field)
			check(is_equal_approx(float(result.creature.hp) / float(result.creature.max_hp), 0.5), "hp fraction preserved")
		var stay := EVOLUTION.prepare_feast_choice(before, int(entry[1]), "stay", str(entry[2]))
		check(stay.get("ok") == true and stay.creature.species_id == before.species_id, "stay keeps species")
		if stay.get("ok") == true:
			check(stay.choice_record.value == "stay", "stay saved as schema string")
			var reloaded: Dictionary = JSON.parse_string(JSON.stringify(stay.creature))
			check(EVOLUTION.prepare_feast_choice(reloaded, int(entry[1]), "evolve", str(entry[2])).get("code") == "evolution_choice_permanent", "stay permanent after JSON reload")
		check(EVOLUTION.prepare_feast_choice(before, int(entry[1]), "", str(entry[2])).get("code") == "evolution_choice_required", "explicit choice required")
		check(EVOLUTION.prepare_feast_choice(before, int(entry[1]) - 1, "evolve", str(entry[2])).get("ok") == false, "wrong tier refuses")
	check(EVOLUTION.prepare_feast_choice(card("mudsnout", 20), 2, "evolve", "").get("code") == "evolution_catalyst_feast_required", "Mudsnout needs cooked catalyst")
	check(EVOLUTION.prepare_feast_choice(card("mudsnout", 20), 2, "stay", "").get("ok") == true, "base feast stay lifts cap through F28")
	check(EVOLUTION.prepare_feast_choice(card("mosshell", 30), 3, "evolve", "sunstone").get("ok") == false, "wrong cooked catalyst refuses")
	check(EVOLUTION.prepare_feast_choice(card("staticub", 50), 5, "", "").get("ok") == true, "bear off permits cap-only feed")
	check(EVOLUTION.prepare_feast_choice(card("staticub", 50), 5, "evolve", "").get("ok") == false, "bear off refuses evolve")
	check(EVOLUTION.prepare_feast_choice(card("staticub", 50), 5, "", "").get("choice_record") == {}, "disabled bear never records stay")
	check(not EVOLUTION.storm_bear_ready(), "no fake bear PASS")
	for starter: String in ["terrapup", "ripplet", "galewisp"]:
		check(EVOLUTION.prepare_feast_choice(card(starter, 20), 2, "", "").get("ok") == true, "starter cap-only feed")
		check(EVOLUTION.prepare_feast_choice(card(starter, 20), 2, "evolve", "").get("ok") == false, "starter never evolves")
	var corrupt := card("mudsnout", 20)
	corrupt.uid = "foreign-party-slot"
	check(EVOLUTION.prepare_feast_choice(corrupt, 2, "evolve", "heartstone").get("ok") == false, "invalid uid refuses")
	corrupt = card("mudsnout", 20)
	corrupt.iv_hp = NAN
	check(EVOLUTION.prepare_feast_choice(corrupt, 2, "evolve", "heartstone").get("ok") == false, "nonfinite stats refuse")
	check(EVOLUTION.requirements("mudsnout", {"evolution_mode":"breakthrough"}).is_empty(), "legacy standalone evolution refuses on activation")
	print(JSON.stringify({"checks": checks, "failures": failures, "scope": "component only; no acceptance credit"}))
	quit(0 if failures.is_empty() else 1)

func card(species_id: String, level: int) -> Dictionary:
	return {"uid":"creature-00000000000000000000000000000001", "species_id":species_id,
		"nickname":"Old friend", "level":level, "xp":19, "evolution_choices":{},
		"iv_hp":0.7, "iv_attack":0.2, "iv_defence":0.9,
		"boost_hp":2, "boost_attack":3, "boost_defence":4, "max_hp":100.0, "hp":50.0,
		"bond":1, "battles_fought":23, "landmarks_visited_together":4, "distance_m_together":512.0,
		"rest_nights_together":8, "feeds_together":9, "caught_on_day":2, "levels_gained_with_you":15,
		"trait_primary":"steady", "trait_secondary":"brave", "shiny":true,
		"rolled_traits":["steady"], "taught_traits":["brave"], "best":true,
		"known_moves":["spark_bite", "arc_lash"], "move_quick":"spark_bite", "move_charged":"arc_lash",
		"move_utility":"shove", "move_ultimate":"friendship", "move_mastery_uses":{"spark_bite":300},
		"move_mastery_receipts":{"fight1":"spark_bite"}, "loadout_revision":3,
		"loadout_last_edit":{"station":"home"}, "nourishment":77.0, "happiness":84.0, "energy":12.0}

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)
