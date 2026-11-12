extends "res://tests/test_case.gd"

## F41#8 (LANE-MESHY): `distinct_bodies_1111` gives Rodkeeper Hesk and Warden-elect Bryn
## their own installed bodies; Elder Maud keeps local_historian. Checked on enabled and
## disabled copies, so it holds whichever way the arm ships.

const CHAPTER := preload("res://scripts/world/stormwood_chapter.gd")


func _registry() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://data/config/stormwood_npcs.json"))


func _by_id(actors: Array) -> Dictionary:
	var out := {}
	for actor: Dictionary in actors:
		out[str(actor.id)] = actor
	return out


func test_on_gives_the_trio_three_distinct_installed_bodies() -> void:
	var registry := _registry()
	var cfg: Dictionary = (registry.distinct_bodies_1111 as Dictionary).duplicate(true)
	cfg.enabled = true
	var actors := _by_id(CHAPTER.distinct_bodies(registry.characters, cfg))
	var bodies := {}
	for id: String in ["elder_maud", "rodkeeper_hesk", "warden_elect_bryn"]:
		var profile := str(actors[id].body_profile)
		bodies[profile] = true
		var art: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/config/art.json"))
		assert_true(art.has(profile) and ResourceLoader.exists(str(art[profile].model)), "%s body %s is an installed cast body" % [id, profile])
	assert_eq(bodies.size(), 3, "three different bodies")
	assert_eq(str(actors.elder_maud.body_profile), "local_historian", "Maud keeps the elder body")
	assert_eq(str(actors.elder_maud.get("appearance_variant_id", "")), "lanekit_f41_8_maud", "Maud keeps her variant")
	assert_eq(str(actors.warden_elect_bryn.get("appearance_variant_id", "")), "meshy_f41_8_bryn_teal",
		"Bryn trades the historian-painted variant for the teal one painted for lost_traveler")
	var variants: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string("res://data/config/character_appearance_variants.json")) as Dictionary).variants
	var teal: Dictionary = variants.meshy_f41_8_bryn_teal
	assert_eq(str(teal.expected_base_profile), "lost_traveler")
	assert_true(ResourceLoader.exists(str(teal.body_albedo_override)) and ResourceLoader.exists(str(teal.portrait)))
	assert_false(actors.rodkeeper_hesk.has("appearance_variant_id"), "Hesk wears the installed tracker colours")
	for id: String in actors:
		if id not in ["rodkeeper_hesk", "warden_elect_bryn"]:
			assert_eq(str(actors[id].body_profile), str(_by_id(registry.characters)[id].body_profile), "%s unchanged" % id)


func test_off_changes_nothing() -> void:
	var registry := _registry()
	var cfg: Dictionary = (registry.distinct_bodies_1111 as Dictionary).duplicate(true)
	cfg.enabled = false
	assert_eq(CHAPTER.distinct_bodies(registry.characters, cfg), registry.characters)
	assert_eq(str(registry.distinct_bodies_1111.get("scope", "")), "client_presentation")
