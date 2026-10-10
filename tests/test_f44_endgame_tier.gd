extends "res://tests/test_case.gd"

## F44#1: after credits, every leader and boss returns at the endgame tier
## (L55-60). Over the shipped rematches.json roster and the real Halda boss
## lookup; the engine witness of an actual post-credits endgame rematch
## admission is smoke_f20_ending (f20_ending_probe.admit_endgame_rematch).
const RULES := preload("res://scripts/repeatables/rematch_rules.gd")
const MOUNT := preload("res://scripts/net/foundation_rematches.gd")
const CREDITS := ["regional_credits_seen"]


func _endgame_level(kind: String) -> int:
	return int(RULES.config().endgame_levels.get(kind, -1))


func test_endgame_levels_hold_leaders_and_bosses_at_55_to_60() -> void:
	for kind: String in ["trainer", "leader", "master", "boss"]:
		var level := _endgame_level(kind)
		assert_true(level >= 55 and level <= 60, "%s endgame level %d is within L55-60" % [kind, level])
	assert_true(_endgame_level("boss") >= _endgame_level("leader"), "bosses return at least as strong as leaders")


func test_every_leader_and_boss_opens_only_after_this_characters_credits() -> void:
	var counted := {"leader": 0, "boss": 0}
	for id: String in RULES.config().profiles:
		var row: Dictionary = RULES.profile(id)
		if not counted.has(row.kind): continue
		counted[row.kind] += 1
		assert_false(RULES.available(id, "endgame", [], []), "%s endgame is shut before credits" % id)
		assert_false(RULES.available(id, "endgame", CREDITS, []), "%s endgame does not open from the world's credits" % id)
		assert_true(RULES.available(id, "endgame", [], CREDITS), "%s endgame opens after this character's credits" % id)
		# A one-creature stand-in team: the endgame copy sets every member to the tier.
		var spec := RULES.encounter_spec({"id": id, "team": [{"species": "terrapup", "level": 5}]}, "endgame")
		assert_false(spec.is_empty(), "%s becomes an endgame rematch" % id)
		if spec.is_empty(): continue
		assert_eq(int(spec.team[0].level), _endgame_level(row.kind), "%s returns at the %s endgame level" % [id, row.kind])
		assert_eq(spec.rematch.tier, "endgame")
	assert_true(counted.leader >= 30 and counted.boss == 4, "the shipped roster has its leaders and four bosses (%s)" % str(counted))


func test_real_boss_rosters_return_whole_at_the_endgame_tier() -> void:
	var mount := MOUNT.new()
	for id: String in ["warden_aldis", "water_trainer_nerissa", "captain_veyra_storm_anchor", "captain_marrow_dynamo_core"]:
		var original: Dictionary = mount.call("_canonical_boss", id)
		assert_false(original.is_empty(), "the Halda board finds %s" % id)
		var spec := RULES.encounter_spec(original, "endgame")
		assert_eq(spec.get("team", []).size(), original.get("team", []).size(), "%s keeps its whole team" % id)
		for member: Dictionary in spec.get("team", []):
			assert_eq(int(member.level), _endgame_level("boss"), "%s's %s returns at L%d" % [id, str(member.species), _endgame_level("boss")])
	mount.free()
