extends "res://tests/test_case.gd"

## F10 / BOSSES §7: each Stormwood named wild asks its own question through the
## numbers BOSSES authors for it, and nothing drops under the chapter's
## teaching floor (§2 step 3: tell .8 s, recovery .6 s).
const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")

## BOSSES §7, per encounter: profile, then its authored numbers. Power is the
## profile multiplier applied to combat.json's enemy power 8.0.
const BOSSES_7 := {
	"hollows_alpha": ["CHARGER", {"telegraph": 0.8, "lunge": 7.0, "recovery": 0.9, "attack_cooldown": 1.6, "power": 8.0 * 1.3}],
	"capacitor_alpha": ["DIVER", {"telegraph": 0.8, "lunge": 5.5, "recovery": 0.6, "attack_cooldown": 0.9,
		"reposition_distance": 7.0, "reposition_time": 1.6, "power": 8.0 * 0.9}],
	"crown_guardian": ["WALL", {"telegraph": 0.85, "recovery": 1.1, "attack_cooldown": 1.6, "chase_speed": 3.4,
		"reposition_distance": 2.5, "power": 8.0 * 1.5}],
	"old_rodfolk_hall_guardian": ["ACE", {"telegraph": 1.1, "recovery": 1.2, "lunge": 6.0, "attack_cooldown": 1.8,
		"first_attack_delay": 2.5, "power": 8.0 * 1.8}],
	"blackwater_elder": ["CURRENT", {"telegraph": 0.8, "recovery": 0.6, "attack_cooldown": 0.7,
		"reposition_time": 0.5, "reposition_distance": 2.0, "power": 8.0 * 0.8}],
	"glass_field_alpha": ["CHARGER", {"telegraph": 0.8, "lunge": 7.0, "recovery": 0.9, "attack_cooldown": 1.6, "power": 8.0 * 1.3}],
}


func _named() -> Dictionary:
	var out := {}
	for row: Dictionary in CATALOGUE.encounter_catalogue().get("named_encounters", []):
		out[str(row.id)] = row
	return out


func test_each_named_fight_carries_its_bosses_numbers() -> void:
	var named := _named()
	assert_eq(named.size(), 6, "Six Stormwood named wilds")
	for id: String in BOSSES_7:
		assert_true(named.has(id), "%s is authored" % id)
		if not named.has(id):
			continue
		assert_eq(str(named[id].behavior_profile), str(BOSSES_7[id][0]), "%s profile" % id)
		var combat := CATALOGUE.named_combat(named[id])
		var expected: Dictionary = BOSSES_7[id][1]
		for key: String in expected:
			assert_almost_eq(float(combat.get(key, -1.0)), float(expected[key]), 0.001, "%s %s" % [id, key])


func test_no_named_fight_drops_under_the_stormwood_teaching_floor() -> void:
	for row: Dictionary in _named().values():
		var combat := CATALOGUE.named_combat(row)
		if combat.has("telegraph"):
			assert_true(float(combat.telegraph) >= 0.8, "%s tell meets the .8 s floor" % row.id)
		if combat.has("recovery"):
			assert_true(float(combat.recovery) >= 0.6, "%s recovery meets the .6 s floor" % row.id)
	var bare := CATALOGUE.named_combat({"behavior_profile": "DIVER"})
	assert_almost_eq(float(bare.telegraph), 0.8, 0.001, "A bare DIVER profile is clamped up to the floor")
	assert_false(bare.has("recovery"), "An unauthored key keeps combat.json's default rather than the floor")


func test_the_spawned_named_bodies_use_those_numbers() -> void:
	var spawns: Array = CATALOGUE.wild_config("calm").get("spawns", [])
	var seen := 0
	for spawn: Dictionary in spawns:
		var id := str(spawn.get("stormwood_named_id", ""))
		if id.is_empty():
			continue
		seen += 1
		var combat: Dictionary = (spawn.get("alpha", {}) as Dictionary).get("combat", {})
		assert_almost_eq(float(combat.get("telegraph", -1.0)), float(BOSSES_7[id][1].telegraph), 0.001,
			"%s spawns with its own tell" % id)
	assert_eq(seen, 6, "All six named bodies spawn from the production catalogue")
