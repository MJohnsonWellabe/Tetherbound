extends "res://tests/test_case.gd"

## The actual Halda source lookup must produce all four authored boss teams.
## This does not simulate a fight or prove guest admission/durable rewards.
const MOUNT := preload("res://scripts/net/foundation_rematches.gd")
const RULES := preload("res://scripts/repeatables/rematch_rules.gd")

func test_halda_lookup_resolves_all_four_real_boss_rosters() -> void:
	var mount := MOUNT.new()
	var expected := {
		"warden_aldis": [21, 21, 21, 22, 22],
		"water_trainer_nerissa": [32, 32, 33, 33],
		"captain_veyra_storm_anchor": [43, 43, 44],
		"captain_marrow_dynamo_core": [54, 54, 54, 55, 55],
	}
	for id: String in expected:
		var spec: Dictionary = mount.call("_canonical_boss", id)
		assert_eq(spec.get("id"), id, "the ordinary board finds this canonical boss")
		var levels: Array[int] = []
		for member: Dictionary in spec.get("team", []): levels.append(int(member.get("level", 0)))
		assert_eq(levels, expected[id], "authored team and order survive board lookup")
		var rematch := RULES.encounter_spec(spec, "endgame")
		assert_false(rematch.is_empty(), "the source can become an actual endgame rematch")
		assert_eq(rematch.get("team", []).size(), expected[id].size())
		assert_eq(rematch.get("reward", {}).get("coins", -1), 0, "rematches cannot replay the story payout")
		assert_eq(rematch.get("defeat_flag", "missing"), "")
	assert_eq(mount.call("_canonical_boss", "unknown_boss"), {})
	assert_eq(mount.call("_canonical_boss", "master_1"), {}, "a Master is not a Halda boss")
	mount.free()
