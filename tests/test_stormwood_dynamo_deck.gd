extends "res://tests/test_case.gd"

## The Dynamo deck the Marrow fight and the Break stand on
## (tests/smoke_stormwood_marrow_press.gd found each of these live).
const DYNAMO := preload("res://scripts/world/stormwood_dynamo.gd")
const TRAINERS := preload("res://scripts/world/stormwood_trainers.gd")
const PROGRESSION_STATE := preload("res://autoload/progression_state.gd")


func test_the_deck_floor_is_solid_only_where_the_ring_and_infill_are() -> void:
	assert_false(DYNAMO.deck_solid_at(Vector2(0, 5)), "the 9 m core hole is not floor")
	assert_false(DYNAMO.deck_solid_at(Vector2(0, 50)), "beyond the deck edge is not floor")
	assert_true(DYNAMO.deck_solid_at(Vector2(10, -20)), "Captain Marrow's seat is on solid deck")
	for bank in 4:
		var at := Vector2.RIGHT.rotated(TAU * bank / 4.0) * 35.0
		assert_true(DYNAMO.deck_solid_at(at), "conduit %d stands on solid deck" % bank)
	var gap_mid := deg_to_rad(256.0)
	assert_false(DYNAMO.deck_solid_at(Vector2.RIGHT.rotated(gap_mid) * 26.0),
		"the ascent's open band in the ring gap is not floor")
	assert_true(DYNAMO.deck_solid_at(Vector2.RIGHT.rotated(gap_mid) * 38.0), "the infill outside the band is floor")
	assert_true(DYNAMO.deck_solid_at(Vector2.RIGHT.rotated(gap_mid) * 15.0), "the infill inside the band is floor")


func test_marrow_seats_left_the_core_hole() -> void:
	for path: String in ["res://data/config/stormwood_trainers.json", "res://data/config/stormwood_npcs.json"]:
		var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		for row: Dictionary in parsed.get("trainers", parsed.get("characters", [])):
			if str(row.get("surface_id", "")) != "dynamo_core":
				continue
			var local := Vector2(float(row.position[0]) - DYNAMO.CORE_POSITION.x, float(row.position[2]) - DYNAMO.CORE_POSITION.z)
			assert_true(DYNAMO.deck_solid_at(local), "%s stands on solid Dynamo deck" % str(row.id))


func test_the_marrow_challenge_wins_its_seat_until_beaten() -> void:
	var spec := {"id": "captain_marrow_dynamo_core", "defeat_flag": "stormwood:trainer:captain_marrow_dynamo_core:defeated",
		"rechallenge": false}
	var flags := PROGRESSION_STATE.new()
	assert_eq(TRAINERS.stormwood_prompt_priority(spec, flags), 1, "the open challenge outranks the same-person NPC's greeting")
	flags.set_flag(str(spec.defeat_flag))
	assert_true(TRAINERS.stormwood_prompt_priority(spec, flags) < 0, "once beaten the NPC's own lines win the press")
	assert_eq(TRAINERS.stormwood_prompt_priority({"id": "officer_nysa_deepwood_rod",
		"defeat_flag": "stormwood:trainer:officer_nysa_deepwood_rod:defeated"}, PROGRESSION_STATE.new()), 0,
		"an ordinary trainer keeps the base priority")
