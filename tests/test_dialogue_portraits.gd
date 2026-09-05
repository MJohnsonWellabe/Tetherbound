extends "res://tests/test_case.gd"

## Every conversation line is drawn with the face of whoever is speaking it.
##
## Owner, 2026-09-04 (docs/owner/OWNER_DIRECTIVES_2026-09-04.md item 8b):
## "fix the picture during dialogue always being the main character."
## `dialogue_panel.gd` draws exactly what a line's `portrait` names, so the
## defect was data: `assets/ui/portraits/` held two plates and every villager,
## trainer, Team Tether rank and the Warden pointed at the player's.
##
## The lines are walked through the REAL runner -- `start()`, `line()`,
## `advance()` -- exactly the way the panel reads them, so a per-line
## `portrait` override and a conversation-level one are both covered, and a
## `$name` speaker resolves the same way it does on screen. Nothing here
## greps a JSON file for a string.

const RUNNER := preload("res://scripts/story/dialogue_runner.gd")

const PORTRAIT_DIR := "res://assets/ui/portraits/"
const PLAYER_PORTRAIT := PORTRAIT_DIR + "trainer.png"

## Whatever the runner substitutes for `$name` is the player; a line whose
## resolved speaker equals this probe value is the one kind of line allowed to
## wear `trainer.png`.
const PLAYER_PROBE_NAME := "__the_player__"

## The fixed file contract every dialogue author re-points against. These
## eight names are load-bearing across lanes (the stronghold's own re-point
## names them), so each must exist and load whether or not any line uses it.
const CONTRACT_PLATES: Array[String] = [
	"trainer.png", "grandpa.png",
	"villager_male.png", "villager_female.png",
	"grunt.png", "officer.png", "captain.png", "warden.png",
]

## data/dialogue/stronghold.json is re-pointed by its own lane against the
## contract above; until that lands, its lines are exempt from the
## not-the-player's-face rule ONLY. They are still required to name a portrait
## that loads. Delete this list (and the two `_is_exempt` calls) the moment
## the stronghold re-point is on main -- it is a carve-out, not a policy.
const STRONGHOLD_PATH := "res://data/dialogue/stronghold.json"

## Speaker-name prefixes whose plate family is fixed by the body the game
## stands them in (data/config/npc_ranks.json + the band trainers.json files):
## a Captain wears a captain plate, and so on. Grandpa is his own family.
const RANK_FAMILY_BY_PREFIX := {
	"Grandpa": "grandpa",
	"Captain ": "captain",
	"Officer ": "officer",
	"Warder ": "officer",
	"Watchman ": "grunt",
	"Patrolman ": "grunt",
	"Tether Grunt": "grunt",
	"Tether Patrol": "grunt",
	"Warden ": "warden",
}


var _stronghold_ids: Dictionary = {}


func before_each() -> void:
	_stronghold_ids.clear()
	var file := FileAccess.open(STRONGHOLD_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for id: String in (parsed as Dictionary).get("conversations", {}):
			_stronghold_ids[id] = true


func _is_exempt(id: String) -> bool:
	return _stronghold_ids.has(id)


## Every line of every conversation the runner knows, as the panel would see
## it: `{"id", "index", "speaker", "portrait"}`.
func _every_line() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for id: String in RUNNER.table():
		var probe: RefCounted = RUNNER.new()
		probe.set_value("name", PLAYER_PROBE_NAME)
		if not probe.start(id):
			continue
		var guard := 0
		while probe.is_active() and guard < 200:
			var line: Dictionary = probe.line()
			lines.append({
				"id": id,
				"index": int(line.get("index", guard)),
				"speaker": str(line.get("speaker", "")),
				"portrait": str(line.get("portrait", "")),
			})
			probe.advance()
			guard += 1
	return lines


func test_the_table_actually_has_lines_to_check() -> void:
	assert_true(_every_line().size() > 100, "the dialogue table should hold well over a hundred lines")


func test_every_line_names_a_portrait_that_loads_as_a_texture() -> void:
	for entry: Dictionary in _every_line():
		var where := "%s[%d]" % [entry["id"], entry["index"]]
		var portrait: String = entry["portrait"]
		assert_ne(portrait, "", "%s has no portrait" % where)
		assert_true(portrait.begins_with(PORTRAIT_DIR),
			"%s points outside the portrait folder: %s" % [where, portrait])
		assert_true(ResourceLoader.exists(portrait),
			"%s points at a portrait that is not on disk: %s" % [where, portrait])
		var texture := load(portrait) as Texture2D
		assert_true(texture != null, "%s's portrait did not load as a texture: %s" % [where, portrait])
		if texture != null:
			assert_true(texture.get_width() >= 128 and texture.get_height() >= 128,
				"%s's portrait is too small to read in the panel: %s" % [where, portrait])


func test_no_line_spoken_by_someone_other_than_the_player_wears_the_players_face() -> void:
	var offenders: Array[String] = []
	for entry: Dictionary in _every_line():
		if _is_exempt(entry["id"]):
			continue
		var speaker: String = entry["speaker"]
		if speaker == PLAYER_PROBE_NAME:
			continue
		if entry["portrait"] == PLAYER_PORTRAIT:
			offenders.append("%s[%d] (%s)" % [entry["id"], entry["index"], speaker])
	assert_true(offenders.is_empty(),
		"%d lines not spoken by the player are drawn with the player's face: %s" % [
			offenders.size(), ", ".join(offenders.slice(0, 12))])


func test_the_eight_contract_plates_exist_and_load() -> void:
	for name: String in CONTRACT_PLATES:
		var path := PORTRAIT_DIR + name
		assert_true(ResourceLoader.exists(path), "contract portrait missing: %s" % path)
		var texture := load(path) as Texture2D
		assert_true(texture != null, "contract portrait does not load as a texture: %s" % path)
		if texture != null:
			assert_eq(texture.get_width(), texture.get_height(),
				"%s is not square like the other plates" % name)


func test_ranked_and_family_speakers_wear_their_own_plate_family() -> void:
	for entry: Dictionary in _every_line():
		if _is_exempt(entry["id"]):
			continue
		var speaker: String = entry["speaker"]
		var basename: String = str(entry["portrait"]).get_file().get_basename()
		# Aila is the Cloudreach local_historian body, not Meadows Warden Aldis.
		# Validate her exact installed reference portrait before the rank heuristic.
		if speaker == "Warden Aila" and str(entry["id"]).begins_with("cloudreach_aila_"):
			assert_eq(str(entry["portrait"]), "res://assets/ui/portraits/cloudreach_aila_clean.png")
			continue
		for prefix: String in RANK_FAMILY_BY_PREFIX:
			if not speaker.begins_with(prefix):
				continue
			var family: String = RANK_FAMILY_BY_PREFIX[prefix]
			assert_true(basename.begins_with(family),
				"%s[%d] is spoken by '%s' and should wear a %s plate, not %s" % [
					entry["id"], entry["index"], speaker, family, basename])
