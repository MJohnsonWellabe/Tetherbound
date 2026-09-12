extends "res://tests/test_case.gd"

const MAP_STATE := preload("res://autoload/map_state.gd")
const MAP_REVEAL := preload("res://scripts/world/dialogue_map_reveal.gd")

var map_state: RefCounted = null


func before_each() -> void:
	map_state = MAP_STATE.new()
	var config := JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/map_landmarks.json")) as Dictionary
	map_state.configure(config)


func test_pond_directions_reveal_the_region_fog_and_authored_alpha_pin() -> void:
	assert_false(map_state.is_region_discovered("the_pond"))
	assert_false(map_state.is_alpha_pinned(1900))
	assert_false(map_state.is_discovered(Vector3(-342.0, 0.0, 507.0)))

	assert_true(MAP_REVEAL.apply(map_state, "pond_alpha"))
	assert_true(map_state.is_region_discovered("the_pond"))
	assert_true(map_state.is_alpha_pinned(1900))
	assert_true(map_state.is_discovered(Vector3(-342.0, 0.0, 507.0)),
		"an NPC reveal left the named place under black fog")
	var marker: Dictionary = map_state.objective_marker()
	assert_true(marker.is_empty(), "an optional place reveal must not replace the main objective")
	var pins: Array = map_state.alpha_pins()
	assert_eq(pins.size(), 1)
	assert_eq((pins[0] as Dictionary).position, Vector2(-318.0, 505.0))
	assert_eq((pins[0] as Dictionary).display_name, "Alpha Mosshell")


func test_repeating_the_same_directions_is_a_no_op() -> void:
	assert_true(MAP_REVEAL.apply(map_state, "pond_alpha"))
	var revision := int(map_state.get("revision"))
	assert_false(MAP_REVEAL.apply(map_state, "pond_alpha"))
	assert_eq(int(map_state.get("revision")), revision,
		"repeat NPC dialogue kept rebuilding an unchanged map")


func test_warrens_directions_reveal_the_real_authored_region() -> void:
	assert_true(MAP_REVEAL.apply(map_state, "burrow_warrens"))
	assert_true(map_state.is_region_discovered("the_burrow_warrens"))
	assert_true(map_state.is_discovered(Vector3(-357.0, 0.0, 2610.0)))
	assert_eq(MAP_REVEAL.display_name("burrow_warrens"), "The Burrow Warrens")


func test_unknown_reveal_cannot_change_the_map() -> void:
	var revision := int(map_state.get("revision"))
	assert_false(MAP_REVEAL.apply(map_state, "not_a_place"))
	assert_eq(int(map_state.get("revision")), revision)


func test_reveal_packets_match_the_production_map_and_spawn_sources() -> void:
	var reveals := JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/meadows_map_reveals.json")) as Dictionary
	var pond := ((reveals.reveals as Dictionary).pond_alpha as Dictionary)
	var alpha := (pond.alphas as Array)[0] as Dictionary
	var band := JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/bands/band1_lower_meadows/spawns.json")) as Dictionary
	var source: Dictionary = {}
	for raw: Variant in band.get("spawns", []):
		var cluster := raw as Dictionary
		if int(cluster.get("order", -1)) == int(alpha.order):
			source = cluster
			break
	assert_false(source.is_empty(), "map reveal points at no authored alpha cluster")
	assert_eq(str(alpha.species), str(source.species))
	assert_eq(Vector2(float(alpha.position[0]), float(alpha.position[1])),
		Vector2(float(source.centre[0]), float(source.centre[2])))
	assert_true(source.has("alpha"), "dialogue labelled an ordinary creature as an alpha")

	var map_config := JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/config/map_landmarks.json")) as Dictionary
	var region_ids: Array[String] = []
	for region: Dictionary in map_config.regions:
		region_ids.append(str(region.id))
	for reveal_raw: Variant in (reveals.reveals as Dictionary).values():
		for region: Variant in (reveal_raw as Dictionary).get("regions", []):
			assert_true(region_ids.has(str(region)), "dialogue reveal names no authored map region")


func test_two_road_people_and_the_pond_fisher_deliver_the_reveals() -> void:
	var dialogue := JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dialogue/bands/band1_lower_meadows.json")) as Dictionary
	var conversations := dialogue.conversations as Dictionary
	var expected := {
		"shepherd_the_rise_defeated": "map_reveal:pond_alpha",
		"wanderer_trail_camp_challenge": "map_reveal:burrow_warrens",
		"pond_fisher_greeting": "map_reveal:pond_alpha",
	}
	for conversation_id: String in expected:
		var effects: Array[String] = []
		for raw: Variant in (conversations[conversation_id] as Dictionary).lines:
			if raw is Dictionary:
				var effect := str((raw as Dictionary).get("effect", ""))
				if not effect.is_empty():
					effects.append(effect)
		assert_true(effects.has(expected[conversation_id]),
			"%s gives directions but does not update the map" % conversation_id)


func test_production_dialogue_drain_handles_map_reveal_effects() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/story/sequence_director.gd")
	assert_true(source.contains("\"map_reveal\":\n\t\t\t\t_reveal_map(str(parts[1]))"))
	assert_true(source.contains("DIALOGUE_MAP_REVEAL.apply(map_state, reveal_id)"))
