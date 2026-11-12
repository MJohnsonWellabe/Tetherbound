extends "res://tests/test_case.gd"

## F41#8 (LANE-BELOW6, 12 Nov 2026; G-below6-namedposts, 3/3): "Rodkeeper Hesk's
## portrait shows a young dark-haired boy while the in-world speaker is a bearded man
## in a hat." With distinct_bodies_1111 ON Hesk stands on the installed alpha_tracker
## body, which had no plate in plates_by_profile, so his lines kept the authored
## villager_male plate. Each body the three named villagers stand on has its own plate.

const CHAPTER := preload("res://scripts/world/stormwood_chapter.gd")


func _read(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func test_named_villagers_speak_with_the_face_of_the_body_they_stand_on() -> void:
	var registry := _read("res://data/config/stormwood_npcs.json")
	var cfg: Dictionary = registry.get("distinct_bodies_1111", {})
	if not bool(cfg.get("enabled", false)):
		return
	var conversations: Dictionary = _read("res://data/dialogue/stormwood.json").conversations
	conversations.merge(CHAPTER.GLASS_FOR_BRYN.conversations())
	var actors: Array = CHAPTER.distinct_bodies(registry.characters, cfg)
	CHAPTER.apply_npc_portraits(conversations, actors,
		_read("res://data/config/stormwood_dialogue_presentation.json").npc_portraits)
	var expected := {"Rodkeeper Hesk": "sorrel", "Warden-Elect Bryn": "meshy_f41_8_bryn",
		"Elder Maud": "lanekit_f41_8_maud"}
	var seen := {}
	for id: String in conversations:
		var speaker := str(conversations[id].get("speaker", ""))
		if expected.has(speaker):
			assert_eq(str(conversations[id].portrait), "res://assets/ui/portraits/%s.png" % expected[speaker], id)
			seen[speaker] = true
	for speaker: String in expected:
		assert_true(seen.has(speaker), "a registered conversation exists for " + speaker)


func test_every_distinct_body_has_a_plate() -> void:
	var plates: Dictionary = _read("res://data/config/stormwood_dialogue_presentation.json").npc_portraits.plates_by_profile
	var bodies: Dictionary = _read("res://data/config/stormwood_npcs.json").get("distinct_bodies_1111", {}).get("bodies", {})
	for id: String in bodies:
		var plate := str(plates.get(str(bodies[id]), ""))
		assert_true(ResourceLoader.exists(plate), "%s (%s) has an installed plate" % [id, bodies[id]])
