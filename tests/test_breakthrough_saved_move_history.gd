extends "res://tests/test_case.gd"

## Actual detached authored eligibility after JSON, not earned UI/save/ACK.
const TEACHING := preload("res://scripts/creatures/teaching.gd")
const BREAKTHROUGH := preload("res://scripts/creatures/breakthrough.gd")

func test_every_authored_tier_move_preserves_eligibility_after_canonical_json_reload() -> void:
	var tiers: Array = []
	for master: Dictionary in BREAKTHROUGH.masters().masters:
		tiers.append(int(master.tier))
		var restored: Array = JSON.parse_string(JSON.stringify(tiers))
		for species: String in TEACHING.learnsets():
			var row: Dictionary = TEACHING.learnsets()[species]
			if row.get("reserved", false): continue
			var current: Array = TEACHING.available_moves(species, 1, tiers)
			var expected: Array[String] = []
			for authored: Dictionary in row.unlocks:
				var granted := (authored.has("level") and int(authored.level) <= 1) \
					or (authored.has("breakthrough_tier") and int(authored.breakthrough_tier) <= tiers.size())
				if granted and not expected.has(str(authored.move_id)): expected.append(str(authored.move_id))
			assert_eq(current, expected, "%s completed prefix %s: exact authored union" % [species, str(tiers)])
			assert_eq(TEACHING.available_moves(species, 1, restored), current,
				"%s completed prefix %s: JSON cannot change the authored union" % [species, str(tiers)])
			for unlock: Dictionary in row.unlocks:
				if not unlock.has("breakthrough_tier"): continue
				assert_eq(current.has(str(unlock.move_id)), expected.has(str(unlock.move_id)),
					"%s prefix %s move %s authored tier %d: any earlier gate remains effective" %
					[species, str(tiers), unlock.move_id, int(unlock.breakthrough_tier)])

func test_stormursa_repeated_hearten_gate_retains_the_actual_earlier_unlock() -> void:
	var gates: Array[int] = []
	for authored: Dictionary in TEACHING.learnsets().stormursa.unlocks:
		if authored.move_id == "hearten" and authored.has("breakthrough_tier"):
			gates.append(int(authored.breakthrough_tier))
	assert_eq(gates, [2,5], "actual authored duplicate gate behind the three returned failures")
	var tiers: Array = []
	for master: Dictionary in BREAKTHROUGH.masters().masters:
		tiers.append(int(master.tier))
		var current := TEACHING.available_moves("stormursa", 1, tiers)
		assert_eq(current.has("hearten"), tiers.size() >= 2, "original tier2 persists through prefixes2,3,4 before tier5")
		assert_eq(TEACHING.available_moves("stormursa", 1, JSON.parse_string(JSON.stringify(tiers))), current)

func test_malformed_saved_prefix_cannot_grant_an_authored_tier_move() -> void:
	for malformed: Array in [[3], [1,3], [1,2,2], [1,2,3.5], ["1",2,3], [10,20,30], [1,2,3,4,5,6]]:
		assert_true(TEACHING.available_moves("ripplet", 30, malformed).is_empty())
		assert_true(TEACHING.available_moves("ripplet", 30, JSON.parse_string(JSON.stringify(malformed))).is_empty())

func test_actual_saved_move_import_retains_the_original_earned_tier_options() -> void:
	var saved := {"uid": "saved_ripplet", "species_id": "ripplet", "level": 30}
	var personal := {"creatures": {"saved_ripplet": {"breakthroughs": [1,2,3], "cap_level": 40}}}
	var original := TEACHING.allowed_saved_moves(saved, personal)
	var restored_saved: Dictionary = JSON.parse_string(JSON.stringify(saved))
	var restored_personal: Dictionary = JSON.parse_string(JSON.stringify(personal))
	assert_eq(TEACHING.allowed_saved_moves(restored_saved, restored_personal), original)
	for unlock: Dictionary in TEACHING.learnsets().ripplet.unlocks:
		if unlock.has("breakthrough_tier") and int(unlock.breakthrough_tier) <= 3:
			assert_true(original.has(str(unlock.move_id)))
	assert_eq(personal.creatures.saved_ripplet.breakthroughs, [1,2,3])
