extends "res://tests/test_case.gd"

## F10#2 (BOSSES §7): the three Stormwood named fights whose identity is a lane
## -- Hollows Alpha's "full-body lane cue", Glass Field Alpha's "projected lane
## across glass" and the Hall Guardian's "lit lane telegraph" -- lunge down a
## lane the ground shows during the wind-up (the travelling lunge the Meadows
## named CHARGERs use, combat.json `charger_lunge`). Before this their lunge
## was an impulse and no lane was ever drawn (F10#2 footage, defect 1).
const CATALOGUE := preload("res://scripts/combat/stormwood_encounter_catalogue.gd")
const WILD := preload("res://scripts/creatures/wild_creature.gd")
const LANE_FIGHTS := ["hollows_alpha", "glass_field_alpha", "old_rodfolk_hall_guardian"]


func _named() -> Dictionary:
	var out := {}
	for row: Dictionary in CATALOGUE.encounter_catalogue().get("named_encounters", []):
		out[str(row.id)] = row
	return out


func test_lane_fights_opt_into_the_travelling_lunge() -> void:
	var named := _named()
	for id: String in named:
		var combat := CATALOGUE.named_combat(named[id])
		if LANE_FIGHTS.has(id):
			assert_true(bool(combat.get("lunge_travels", false)), "%s lunges down a shown lane" % id)
			assert_true(float(combat.get("lunge", 0.0)) >= 6.0, "%s keeps its authored lunge length" % id)
		else:
			assert_false(bool(combat.get("lunge_travels", false)), "%s keeps its own attack shape" % id)


func test_the_spawned_named_bodies_carry_the_lane() -> void:
	var seen := 0
	for spawn: Dictionary in CATALOGUE.wild_config("calm").get("spawns", []):
		var id := str(spawn.get("stormwood_named_id", ""))
		if not LANE_FIGHTS.has(id):
			continue
		seen += 1
		var combat: Dictionary = (spawn.get("alpha", {}) as Dictionary).get("combat", {})
		assert_true(bool(combat.get("lunge_travels", false)), "%s spawns with the travelling lunge" % id)
	assert_eq(seen, 3, "All three lane fights spawn from the production catalogue")


func test_the_live_body_honours_the_key() -> void:
	assert_true(WILD._COMBAT_OVERRIDE_KEYS.has("lunge_travels"))
	var body: Node = WILD.new()
	body.combat_override = CATALOGUE.named_combat(_named().hollows_alpha)
	body.refresh_combat_profile()
	assert_true(body.lunge_travels(), "A Hollows Alpha body reports a travelling lunge")
	body.free()
