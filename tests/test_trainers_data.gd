extends "res://tests/test_case.gd"

## The trainer table, data/config/trainers.json (R8.1).
##
## Every failure this file guards is silent at run time. A species renamed in
## one file and not the other produces a trainer who sends out nothing and a
## battle that refuses itself. Two trainers sharing a defeat flag means beating
## one closes the other. A challenge conversation that is not in the dialogue
## table means the challenge prompt opens an empty box and the fight never
## starts. A reward naming an item that does not exist pays out nothing and
## push_errors into a log nobody is reading.
##
## Per docs/decisions/D02 the suite is pure logic only: standing a trainer on
## Terrain3D and beating them is `tests/smoke_trainer_battle.gd`'s job. This
## file owns the TABLE that test and `scripts/combat/encounter_director.gd`
## read.

const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")
const ITEMS_PATH := "res://data/items/items.json"


func _item_ids() -> Array:
	var file := FileAccess.open(ITEMS_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return []
	var items: Variant = (parsed as Dictionary).get("items", {})
	if items is Dictionary:
		return (items as Dictionary).keys()
	var out: Array = []
	for entry: Variant in (items as Array):
		out.append(str((entry as Dictionary).get("id", "")))
	return out


# --- the table is well-formed -------------------------------------------------

func test_the_table_has_at_least_one_trainer() -> void:
	assert_false(TRAINERS.trainers().is_empty(),
		"trainers.json lists nobody; there would be no trainer battle in the game")


func test_every_trainer_has_an_id_a_name_and_a_position() -> void:
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_ne(str(spec.get("id", "")), "", "a trainer entry has no id")
		assert_ne(str(spec.get("name", "")), "",
			"trainer '%s' has no display name; their prompt would read 'Challenge '" % str(spec.get("id", "")))
		var at: Array = spec.get("position", [])
		assert_eq(at.size(), 2,
			"trainer '%s' has no [x, z] position" % str(spec.get("id", "")))


func test_trainer_ids_are_unique() -> void:
	var seen: Array[String] = []
	for entry: Variant in TRAINERS.trainers():
		var id := str((entry as Dictionary).get("id", ""))
		assert_false(seen.has(id), "two trainers share the id '%s'" % id)
		seen.append(id)


func test_every_trainer_has_a_team_of_real_species() -> void:
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		var team := TRAINERS.team_of(spec)
		assert_false(team.is_empty(),
			"trainer '%s' fields no creatures; the battle would refuse itself" % str(spec.get("id", "")))
		for member: Variant in team:
			var creature: Dictionary = member
			var id := str(creature.get("species", ""))
			assert_true(SPECIES.has(id),
				"trainer '%s' fields '%s', which is not in species.json" % [str(spec.get("id", "")), id])
			assert_true(int(creature.get("level", 0)) > 0,
				"trainer '%s' fields a level-%d creature" % [str(spec.get("id", "")), int(creature.get("level", 0))])


func test_every_team_member_can_actually_be_built() -> void:
	# The director builds these through `creature_for()`; a null here is a
	# battle that push_errors and refuses to start.
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		for member: Variant in TRAINERS.team_of(spec):
			var creature: RefCounted = TRAINERS.creature_for(member as Dictionary)
			assert_true(creature != null,
				"trainer '%s' has a team entry that builds no creature" % str(spec.get("id", "")))
			if creature == null:
				continue
			assert_eq(int(creature.get("level")), int((member as Dictionary).get("level", 1)),
				"a trainer's creature did not come out at its authored level")
			assert_true(float(creature.get("hp")) > 0.0,
				"a trainer's creature was built already fainted")


# --- the flags are what stop a battle being farmed ----------------------------

func test_every_trainer_has_a_defeat_flag() -> void:
	# Spec §15 and §17 P1 step 9: the flag is what records the battle as done,
	# what SC15's reward is paid against, and what SC14's bridge will read.
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_ne(str(spec.get("defeat_flag", "")), "",
			"trainer '%s' has no defeat_flag; beating them would change nothing" % str(spec.get("id", "")))


func test_defeat_flags_are_unique() -> void:
	var seen: Array[String] = []
	for entry: Variant in TRAINERS.trainers():
		var flag := str((entry as Dictionary).get("defeat_flag", ""))
		assert_false(seen.has(flag),
			"two trainers share the defeat flag '%s'; beating one would close the other" % flag)
		seen.append(flag)


func test_a_beaten_trainer_cannot_be_challenged_again() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_false(TRAINERS.already_beaten(spec, progression),
			"trainer '%s' reads as beaten on a fresh save" % str(spec.get("id", "")))
		progression.call("set_flag", str(spec.get("defeat_flag", "")))
		assert_true(TRAINERS.already_beaten(spec, progression),
			"trainer '%s' can be re-fought after their flag is set; that is an XP faucet" % str(spec.get("id", "")))


func test_a_beaten_trainer_greets_instead_of_challenging() -> void:
	var progression: RefCounted = PROGRESSION_STATE.new()
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_eq(TRAINERS.conversation_for(spec, progression), str(spec.get("challenge", "")),
			"trainer '%s' does not open their challenge on a fresh save" % str(spec.get("id", "")))
		progression.call("set_flag", str(spec.get("defeat_flag", "")))
		assert_eq(TRAINERS.conversation_for(spec, progression), str(spec.get("defeated", "")),
			"trainer '%s' still opens their challenge after being beaten" % str(spec.get("id", "")))


# --- what they say, and what they pay ------------------------------------------

func test_both_conversations_exist_in_the_dialogue_table() -> void:
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		for key: String in ["challenge", "defeated"]:
			var id := str(spec.get(key, ""))
			assert_ne(id, "", "trainer '%s' names no '%s' conversation" % [str(spec.get("id", "")), key])
			assert_true(RUNNER.has(id),
				"trainer '%s' opens '%s', which no dialogue file defines" % [str(spec.get("id", "")), id])


func test_every_reward_item_exists() -> void:
	var known := _item_ids()
	assert_false(known.is_empty(), "items.json could not be read; the reward check would pass vacuously")
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		for item: Variant in TRAINERS.reward_items(spec):
			var id := str((item as Dictionary).get("id", ""))
			assert_true(known.has(id),
				"trainer '%s' rewards '%s', which items.json does not define" % [str(spec.get("id", "")), id])
			assert_true(int((item as Dictionary).get("count", 0)) > 0,
				"trainer '%s' rewards zero of '%s'" % [str(spec.get("id", "")), id])


func test_reward_coins_and_xp_bonus_are_not_negative() -> void:
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		assert_true(TRAINERS.reward_coins(spec) >= 0,
			"trainer '%s' rewards negative coins" % str(spec.get("id", "")))
		assert_true(TRAINERS.reward_xp_bonus(spec) >= 0,
			"trainer '%s' rewards a negative xp_bonus" % str(spec.get("id", "")))


func test_at_least_one_trainer_pays_coins() -> void:
	# D39: "SC15's trainer payouts later pay coins too." A reward table that
	# never actually pays a coin would leave that promise unkept.
	var any_coins := false
	for entry: Variant in TRAINERS.trainers():
		if TRAINERS.reward_coins(entry as Dictionary) > 0:
			any_coins = true
			break
	assert_true(any_coins,
		"no trainer reward pays out any coins; D39 promised trainer payouts include coins")


func test_every_trainer_has_a_body_to_stand_up_in() -> void:
	for entry: Variant in TRAINERS.trainers():
		var spec: Dictionary = entry
		var cfg := TRAINERS.model_config(spec)
		assert_false(cfg.is_empty(),
			"trainer '%s' names an art.json/npc_ranks.json key that does not exist" % str(spec.get("id", "")))
		assert_ne(str(cfg.get("model", "")), "",
			"trainer '%s' resolves to a config with no model" % str(spec.get("id", "")))


func test_the_flow_numbers_are_sane() -> void:
	var flow := TRAINERS.flow()
	assert_true(float(flow.get("send_out_seconds", 0.0)) > 0.0,
		"send_out_seconds is zero; the next creature would appear on the same frame the last one fell")
	assert_true(float(flow.get("linger_seconds", 0.0)) > 0.0,
		"linger_seconds is zero; a beaten creature would vanish rather than fall")
