extends "res://tests/test_case.gd"

## D72, owner directive: "No one else in the game should have any of the
## starters." `data/config/opening.json`'s `starters.species` names the three
## (terrapup/ripplet/galewisp, Ground/Water/Air) the player chooses ONE of at
## the very start of the game -- the other two stay with Grandpa. Nothing else
## in the world may hand one out: not a trainer's team, not the ordinary wild
## population, not the rolled spawn tables, not the creature trader, not the
## Burrow Warrens' own residents or guardian.
##
## `test_spawns_data.gd::test_starter_species_never_spawn_in_the_ordinary_wild_population`
## and `test_spawn_tables.gd::test_no_starter_species_can_be_rolled` already pin
## the two wild-population halves of this promise. This file is the rest of
## it -- every other place a `"species"` key can name a creature the player
## can end up owning without ever making the opening choice -- plus a single
## sweep that would catch a new one of any of those shapes automatically: any
## `"species"` value, anywhere in any of these configs, recursively.
##
## Every one of these files is read the same way the live game reads it
## (`band_content.gd`'s merge for the two that are split per band), never a
## raw file parse, so a table that only looks clean before the merge still
## fails here if the merge would actually place a starter.

const BAND_CONTENT := preload("res://scripts/data/band_content.gd")

const TRAINERS_PATH := "res://data/config/trainers.json"
const SPAWNS_PATH := "res://data/config/spawns.json"
const SPAWN_TABLES_PATH := "res://data/config/spawn_tables.json"
const TRADE_PATH := "res://data/config/trade.json"
const WARRENS_PATH := "res://data/config/burrow_warrens.json"
const OPENING_PATH := "res://data/config/opening.json"

const EXPECTED_STARTERS := ["terrapup", "ripplet", "galewisp"]


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_true(file != null, "%s is missing" % path)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "%s is not a JSON object" % path)
	return parsed if parsed is Dictionary else {}


## Every string found under a key literally named `species`, anywhere in
## `node`, walking every nested Dictionary and Array. Catches a starter placed
## in a shape nobody wrote a dedicated test for -- a new trainer entry, a new
## vendor offer, a new dungeon population -- the same way a real content typo
## would actually happen: as one more `"species": "..."` line in a file this
## test already reads in full.
func _all_species_values(node: Variant) -> Array[String]:
	var found: Array[String] = []
	if node is Dictionary:
		for key: Variant in (node as Dictionary).keys():
			var value: Variant = (node as Dictionary)[key]
			if key == "species" and typeof(value) == TYPE_STRING:
				found.append(value as String)
			found.append_array(_all_species_values(value))
	elif node is Array:
		for entry: Variant in (node as Array):
			found.append_array(_all_species_values(entry))
	return found


func _assert_no_starters(species_ids: Array[String], source: String) -> void:
	for id: String in species_ids:
		assert_false(EXPECTED_STARTERS.has(id),
			"%s names starter species '%s'; starters must remain unique to the opening choice" % [source, id])


# --- the starter list itself is what every other check below is measured against ---

func test_the_three_starters_are_the_ones_the_opening_actually_offers() -> void:
	var opening := _read_json(OPENING_PATH)
	var species: Array = (opening.get("starters", {}) as Dictionary).get("species", [])
	assert_eq(species, EXPECTED_STARTERS,
		"opening.json's own starter roster no longer matches what this test (and CLAUDE.md's owner record) expects; update both together, never just the test")


# --- every trainer roster, merged the way the live game merges it -----------

func test_no_trainer_in_the_chapter_fields_a_starter() -> void:
	var trainers: Array = BAND_CONTENT.load_config(TRAINERS_PATH, "trainers").get("trainers", []) as Array
	assert_true(trainers.size() > 0, "the merged trainer table is empty; this test would pass for nothing")
	_assert_no_starters(_all_species_values(trainers), "a merged trainers.json entry")


# --- the ordinary wild population and the rolled spawn tables ---------------
#
# Already pinned individually by test_spawns_data.gd and test_spawn_tables.gd;
# reasserted here with the same generic recursive sweep as everything else in
# this file, so one sweep across every content table is the single place a
# future author can check "did I just add a starter anywhere."

func test_no_ordinary_wild_spawn_names_a_starter() -> void:
	var spawns: Array = BAND_CONTENT.load_config(SPAWNS_PATH, "spawns").get("spawns", []) as Array
	assert_true(spawns.size() > 0, "the merged spawn table is empty; this test would pass for nothing")
	_assert_no_starters(_all_species_values(spawns), "a merged spawns.json entry")


func test_no_rolled_spawn_table_tier_names_a_starter() -> void:
	var config := _read_json(SPAWN_TABLES_PATH)
	_assert_no_starters(_all_species_values(config), "spawn_tables.json")


# --- the creature trader --------------------------------------------------

func test_no_creature_trader_offer_names_a_starter() -> void:
	var trade := _read_json(TRADE_PATH)
	var traders: Dictionary = trade.get("creature_traders", {})
	assert_true(traders.size() > 0, "trade.json has no creature_traders; this test would pass for nothing")
	_assert_no_starters(_all_species_values(traders), "a trade.json creature_traders offer")


# --- the Burrow Warrens: its own residents and its guardian -----------------

func test_no_burrow_warrens_resident_or_guardian_is_a_starter() -> void:
	var warrens := _read_json(WARRENS_PATH)
	assert_true((warrens.get("spawns", []) as Array).size() > 0,
		"burrow_warrens.json has no spawns; this test would pass for nothing")
	assert_true(warrens.has("guardian"), "burrow_warrens.json has no guardian; this test would pass for nothing")
	_assert_no_starters(_all_species_values(warrens.get("spawns", [])), "a burrow_warrens.json resident")
	_assert_no_starters(_all_species_values(warrens.get("guardian", {})), "the burrow_warrens.json guardian")


# --- the whole-file sweep: every "species" value in every table above -------

func test_no_species_value_anywhere_in_any_authored_table_is_a_starter() -> void:
	var offenders: Array[String] = []
	var sources := {
		"trainers.json (merged)": BAND_CONTENT.load_config(TRAINERS_PATH, "trainers"),
		"spawns.json (merged)": BAND_CONTENT.load_config(SPAWNS_PATH, "spawns"),
		"spawn_tables.json": _read_json(SPAWN_TABLES_PATH),
		"trade.json": _read_json(TRADE_PATH),
		"burrow_warrens.json": _read_json(WARRENS_PATH),
	}
	for source: String in sources.keys():
		for id: String in _all_species_values(sources[source]):
			if EXPECTED_STARTERS.has(id):
				offenders.append("%s: %s" % [source, id])
	assert_eq(offenders, [] as Array[String],
		"a starter species must not appear anywhere outside the opening choice: %s" % str(offenders))
