extends "res://tests/test_case.gd"

const SPECIES_PATH := "res://data/creatures/species.json"
const CLOUDREACH_PATH := "res://data/config/cloudreach_chapter.json"
const STORMWOOD_PATH := "res://data/config/stormwood_encounters.json"
const STORMWOOD_TRAINERS_PATH := "res://data/config/stormwood_trainers.json"
const WATER_PATH := "res://data/config/water_encounters.json"
const WATER_TRAINERS_PATH := "res://data/config/water_characters.json"
const WATER_ROSTER_PATH := "res://data/config/water_roster.json"
const WATER_ALPHA_PATH := "res://data/config/water_alpha.json"

const CLOUDREACH_NEW: Array[String] = [
	"pebbik", "craghorn", "stormcapra", "skyrill", "aeriex", "ribbonray",
	"breezetail", "cloudfang", "cliffspike", "tempestwing", "solmane",
]
const STORMWOOD_NEW: Array[String] = [
	"voltwig", "glimmermoth", "stormbrush", "mosshock", "staticub",
	"tanglevolt", "stormraven", "thundertunnel", "voltarach", "fulgocobra",
]
const WATER_NEW: Array[String] = [
	"cannonback", "riptusk", "mirejaw", "aquaryn", "torrentoad", "cragclaw",
	"riverdrake", "sirenseal", "mangrove_monitor", "tidecoil", "abyssal_guardian",
]


func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed as Dictionary if parsed is Dictionary else {}


func _record(placed: Dictionary, species_id: String) -> void:
	placed[species_id] = int(placed.get(species_id, 0)) + 1


func test_every_installed_new_species_is_placed_in_its_biome() -> void:
	var species: Dictionary = _read(SPECIES_PATH).get("species", {})
	var placed := {
		"cloudreach": _cloudreach_placements(),
		"stormwood": _stormwood_placements(),
		"water": _water_placements(),
	}
	var expected := {
		"cloudreach": CLOUDREACH_NEW,
		"stormwood": STORMWOOD_NEW,
		"water": WATER_NEW,
	}
	for biome: String in expected:
		for species_id: String in expected[biome]:
			assert_true(species.has(species_id), "%s is not installed" % species_id)
			assert_true((placed[biome] as Dictionary).has(species_id),
				"%s is not placed in %s" % [species_id, biome])


func test_later_biome_tables_only_reuse_the_three_authored_meadows_anchors() -> void:
	var allowed := {
		"cloudreach": CLOUDREACH_NEW + ["galecrest"],
		"stormwood": STORMWOOD_NEW + ["sparkit"],
		"water": WATER_NEW + ["mosshell"],
	}
	var placed := {
		"cloudreach": _cloudreach_placements(),
		"stormwood": _stormwood_placements(),
		"water": _water_placements(),
	}
	for biome: String in allowed:
		for species_id: String in (placed[biome] as Dictionary):
			assert_true((allowed[biome] as Array).has(species_id),
				"%s reuses undocumented species %s" % [biome, species_id])


func test_alpha_and_legendary_identities_match_the_authoritative_roster() -> void:
	var cloudreach := _read(CLOUDREACH_PATH)
	var cloud_roles: Dictionary = {}
	for table: Dictionary in cloudreach.get("encounter_tables", []):
		for entry: Dictionary in table.get("entries", []):
			cloud_roles[str(entry.get("role", ""))] = entry
	assert_eq(str(cloud_roles.get("rare_glider", {}).get("placeholder_species", "")), "tempestwing")
	assert_eq(str(cloud_roles.get("rare_glider", {}).get("roster_identity", "")), "alpha_catch")
	assert_eq(str(cloud_roles.get("summit_sentinel", {}).get("placeholder_species", "")), "solmane")
	assert_eq(str(cloud_roles.get("summit_sentinel", {}).get("roster_identity", "")), "legendary")

	var stormwood := _read(STORMWOOD_PATH)
	var alpha_count := 0
	for encounter: Dictionary in stormwood.get("named_encounters", []):
		if str(encounter.get("id", "")).ends_with("_alpha"):
			alpha_count += 1
			assert_eq(str(encounter.get("placeholder_species", "")), "voltarach")
	assert_eq(alpha_count, 3)
	assert_eq(str(stormwood.get("legendary_placeholder", {}).get("placeholder_species", "")),
		"fulgocobra")

	var water := _read(WATER_PATH)
	var scripted: Dictionary = {}
	for encounter: Dictionary in water.get("scripted_encounter_references", []):
		scripted[str(encounter.get("id", ""))] = str(encounter.get("species_id", ""))
	assert_eq(scripted.get("water_aquaryn_alpha"), "aquaryn")
	assert_eq(scripted.get("water_abyssal_guardian_release"), "abyssal_guardian")
	assert_eq(str(_read(WATER_ALPHA_PATH).get("species_id", "")), "water_aquaryn")


func test_water_runtime_presentations_use_installed_species_meshes() -> void:
	var installed: Dictionary = _read(SPECIES_PATH).get("species", {})
	var roster: Dictionary = _read(WATER_ROSTER_PATH).get("species", {})
	for species_id: String in WATER_NEW:
		var presentation: Dictionary = roster.get(species_id, {}).get("placeholder", {})
		assert_eq(str(presentation.get("model", "")),
			str(installed.get(species_id, {}).get("placeholder", {}).get("model", "")))
		assert_eq(str(presentation.get("status", "")), "installed_species_mesh")
	var mosshell: Dictionary = roster.get("mosshell", {}).get("placeholder", {})
	assert_eq(str(mosshell.get("source_species", "")), "mosshell")
	assert_eq(str(mosshell.get("status", "")), "reused_meadows_anchor")


func _cloudreach_placements() -> Dictionary:
	var chapter := _read(CLOUDREACH_PATH)
	var placed: Dictionary = {}
	for table: Dictionary in chapter.get("encounter_tables", []):
		for entry: Dictionary in table.get("entries", []):
			_record(placed, str(entry.get("placeholder_species", "")))
	for trainer: Dictionary in chapter.get("trainer_ladder", []):
		for member: Dictionary in trainer.get("team_contract", {}).get("slots", []):
			_record(placed, str(member.get("placeholder_species", "")))
	for member: Dictionary in chapter.get("final_encounter", {}).get("opposition_contract", {}).get("slots", []):
		_record(placed, str(member.get("placeholder_species", "")))
	return placed


func _stormwood_placements() -> Dictionary:
	var encounters := _read(STORMWOOD_PATH)
	var placed: Dictionary = {}
	for table: Dictionary in encounters.get("tables", []):
		for role: Dictionary in table.get("roles", []):
			_record(placed, str(role.get("placeholder_species", "")))
	for encounter: Dictionary in encounters.get("named_encounters", []):
		_record(placed, str(encounter.get("placeholder_species", "")))
	_record(placed, str(encounters.get("legendary_placeholder", {}).get("placeholder_species", "")))
	for trainer: Dictionary in _read(STORMWOOD_TRAINERS_PATH).get("trainers", []):
		for member: Dictionary in trainer.get("party", []):
			_record(placed, str(member.get("placeholder_species", "")))
	return placed


func _water_placements() -> Dictionary:
	var encounters := _read(WATER_PATH)
	var placed: Dictionary = {}
	for table: Dictionary in encounters.get("tables", []):
		for entry: Dictionary in table.get("entries", []):
			_record(placed, str(entry.get("species_id", "")))
	for key: String in ["named_encounters", "scripted_encounter_references"]:
		for encounter: Dictionary in encounters.get(key, []):
			_record(placed, str(encounter.get("species_id", "")))
	for trainer: Dictionary in _read(WATER_TRAINERS_PATH).get("trainers", []):
		for member: Dictionary in trainer.get("team", []):
			_record(placed, str(member.get("species", "")))
	return placed
