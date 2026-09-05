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
##
## N04-DIALOGUE-PORTRAITS, 2026-09-05, added the other half: the REAL panel
## (`scenes/ui/dialogue_panel.tscn`, put in the tree so its `@onready` nodes
## exist) is opened on two different villagers in sequence and asked what
## plate it actually drew (`current_portrait()`), which is CL-G11's own ask
## in `docs/GATE2_GATE3_CLOSURE_PLAN.md`. The same panel is then opened on the
## shared trainer refusal with the challenged trainer's identity laid over it,
## the way `trainer_npc.gd` does it, and must show that trainer's face.

const RUNNER := preload("res://scripts/story/dialogue_runner.gd")
const TRAINERS := preload("res://scripts/world/trainer_npc.gd")
const PANEL_SCENE := preload("res://scenes/ui/dialogue_panel.tscn")

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

## The stronghold's bodiless speakers: a status readout, a duty board and the
## chamber's own second-person narration ("You pull it."). They are what the
## PLAYER reads and sees, and the finale lane chose the player's own plate for
## them on purpose (data/dialogue/stronghold.json `_comment_portraits`). They
## are exempt from the not-the-player's-face rule BY NAME and nothing else in
## that file is: the Warden is a person with a body and a plate, and is held
## to the rank-family rule below like every other speaker.
const BODILESS_NARRATION_SPEAKERS: Array[String] = [
	"Tether Readout", "Tether Duty Board", "Chamber Five",
]

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


## The shared refusal every trainer opens with nothing usable to fight with,
## and the one trainer whose face the assertions below name. Both are the
## real table's own entries, not fixtures.
const GENERIC_REFUSAL := "trainer_no_usable_creature"
const PRACTICE_TRAINER := "practice_trainer"


func _is_exempt(speaker: String) -> bool:
	return speaker in BODILESS_NARRATION_SPEAKERS


## The panel the player sees. `Engine.get_main_loop()` is null for the whole
## life of tests/run_tests.gd (see test_party_seam.gd), so the scene is stood
## up off-tree the way test_companion_presence.gd stands up a creature: the
## `@onready` fields are bound by hand to the same node paths the scene file
## declares, then `_ready()` is called. Everything the panel does after that
## -- pull the line, resolve the plate, load the texture -- is the real code.
func _panel() -> Node:
	var panel: Node = PANEL_SCENE.instantiate()
	for field: String in [
		"_box:Root/Box",
		"_portrait:Root/Box/Margin/Row/Portrait",
		"_speaker:Root/Box/Margin/Row/Text/Speaker",
		"_body:Root/Box/Margin/Row/Text/Body",
		"_hint:Root/Box/Margin/Row/Text/Hint",
	]:
		var pair: PackedStringArray = field.split(":")
		var node: Node = panel.get_node_or_null(NodePath(pair[1]))
		assert_true(node != null, "dialogue_panel.tscn has no %s" % pair[1])
		panel.set(pair[0], node)
	panel.call("_ready")
	return panel


func _drop(panel: Node) -> void:
	panel.free()


## What the runner says a conversation's own plate is, read the way the panel
## reads it (first line, no overlay).
func _authored_portrait(id: String) -> String:
	var probe: RefCounted = RUNNER.new()
	if not probe.start(id):
		return ""
	var portrait := str(probe.line().get("portrait", ""))
	probe.close()
	return portrait


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
		var speaker: String = entry["speaker"]
		if _is_exempt(speaker):
			continue
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
		var speaker: String = entry["speaker"]
		if _is_exempt(speaker):
			continue
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


func test_the_bodiless_narration_carve_out_names_only_speakers_that_exist() -> void:
	# A carve-out for a speaker nobody says is a carve-out that has quietly
	# widened: every name in it must still be spoken somewhere, or it comes
	# out of the list.
	var spoken: Dictionary = {}
	for entry: Dictionary in _every_line():
		spoken[entry["speaker"]] = true
	for name: String in BODILESS_NARRATION_SPEAKERS:
		assert_true(spoken.has(name), "'%s' is exempt but no line is spoken by it any more" % name)


func test_the_warden_wears_his_own_plate_in_every_one_of_his_conversations() -> void:
	# He was the last named speaker still drawn with the player's face.
	var seen := 0
	for entry: Dictionary in _every_line():
		if not str(entry["speaker"]).begins_with("Warden "):
			continue
		seen += 1
		assert_eq(str(entry["portrait"]).get_file(), "warden.png",
			"%s[%d] is spoken by %s and should wear warden.png" % [entry["id"], entry["index"], entry["speaker"]])
	assert_true(seen >= 3, "expected the Warden's three stronghold conversations, found %d lines" % seen)


## --- the real panel ----------------------------------------------------------

func test_two_villagers_in_sequence_draw_two_different_plates_on_the_real_panel() -> void:
	# CL-G11's own ask: open two different NPCs' conversations one after the
	# other and confirm the frame shows two different faces, each the
	# speaker's own. Halda and Oskar stand in the same square; Mira and Tam
	# share Halda's rig and still draw different plates.
	var pairs := [
		["tournament_halda", "village_oskar"],
		["village_mira", "village_tam"],
	]
	var panel := _panel()
	for pair: Array in pairs:
		var drawn: Array[String] = []
		for id: String in pair:
			assert_true(bool(panel.call("start", id)), "the panel refused to open '%s'" % id)
			var shown := str(panel.call("current_portrait"))
			assert_ne(shown, "", "'%s' drew no plate at all" % id)
			assert_eq(shown, _authored_portrait(id),
				"'%s' drew %s, not the plate its own line names" % [id, shown.get_file()])
			assert_ne(shown, PLAYER_PORTRAIT, "'%s' drew the player's face" % id)
			drawn.append(shown)
			panel.call("close")
		assert_ne(drawn[0], drawn[1],
			"'%s' and '%s' drew the same plate (%s)" % [pair[0], pair[1], drawn[0].get_file()])
	_drop(panel)


func test_the_generic_refusal_wears_the_challenged_trainers_own_face() -> void:
	var spec: Dictionary = TRAINERS.trainer(PRACTICE_TRAINER)
	if spec.is_empty():
		_fail("trainers.json has no '%s'" % PRACTICE_TRAINER)
		return
	var own_plate := _authored_portrait(str(spec.get("challenge", "")))
	assert_ne(own_plate, "", "the practice trainer's challenge names no plate")
	var neutral := _authored_portrait(GENERIC_REFUSAL)
	assert_ne(own_plate, neutral, "this test needs a trainer whose plate differs from the refusal's neutral one")

	var identity: Dictionary = TRAINERS.speaker_identity(spec)
	assert_eq(str(identity.get("portrait", "")), own_plate,
		"speaker_identity() should hand over the trainer's own challenge plate")
	assert_eq(str(identity.get("speaker", "")), str(spec.get("name", "")),
		"speaker_identity() should hand over the trainer's own name")

	var panel := _panel()
	# The way trainer_npc.gd opens it: the shared line, this trainer's face.
	assert_true(bool(panel.call("start", GENERIC_REFUSAL, identity)), "the panel refused the refusal")
	assert_eq(str(panel.call("current_portrait")), own_plate,
		"the refusal drew %s, not the challenged trainer's own %s" % [
			str(panel.call("current_portrait")).get_file(), own_plate.get_file()])
	assert_eq(str(panel.call("current_speaker")), str(spec.get("name", "")),
		"the refusal is labelled '%s', not the trainer's own name" % str(panel.call("current_speaker")))
	panel.call("close")

	# And the way a caller that knows nothing opens it: the neutral plate the
	# JSON names, so no site is worse off for not passing an identity.
	assert_true(bool(panel.call("start", GENERIC_REFUSAL)), "the panel refused the plain refusal")
	assert_eq(str(panel.call("current_portrait")), neutral,
		"with no identity the refusal should fall back to its own neutral plate")
	assert_eq(str(panel.call("current_speaker")), "Trainer")
	_drop(panel)


func test_the_identity_does_not_bleed_into_the_next_conversation() -> void:
	var spec: Dictionary = TRAINERS.trainer(PRACTICE_TRAINER)
	var panel := _panel()
	assert_true(bool(panel.call("start", GENERIC_REFUSAL, TRAINERS.speaker_identity(spec))))
	# Close the way the player does: advance off the last line.
	var guard := 0
	while bool(panel.call("is_open")) and guard < 20:
		panel.call("advance")
		guard += 1
	assert_false(bool(panel.call("is_open")), "advancing past the last line should close the refusal")
	assert_true(bool(panel.call("start", "village_oskar")))
	assert_eq(str(panel.call("current_portrait")), _authored_portrait("village_oskar"),
		"Oskar's greeting drew a plate left over from the previous conversation's identity")
	assert_eq(str(panel.call("current_speaker")), "Oskar")
	_drop(panel)


func test_a_stale_identity_portrait_falls_back_to_the_lines_own_plate() -> void:
	# A body whose plate has not been rendered yet must not empty the frame:
	# the conversation's own (neutral) plate is still better than nothing.
	var panel := _panel()
	var stale := {"speaker": "Somebody", "portrait": PORTRAIT_DIR + "nobody_rendered_this.png"}
	assert_true(bool(panel.call("start", GENERIC_REFUSAL, stale)))
	assert_eq(str(panel.call("current_portrait")), _authored_portrait(GENERIC_REFUSAL))
	assert_eq(str(panel.call("current_speaker")), "Somebody",
		"the name half of the identity should still apply when only the plate is missing")
	_drop(panel)


func test_every_trainer_in_the_table_has_a_face_of_its_own_for_the_refusals() -> void:
	# ~27 trainers across the bands; each one's refusal must be able to wear a
	# plate that exists and is not the player's. Oskar's is villager_male.png
	# because that IS his body's plate, so "not the neutral one" is not the bar.
	var checked := 0
	for spec: Variant in TRAINERS.trainers():
		if not spec is Dictionary:
			continue
		var identity: Dictionary = TRAINERS.speaker_identity(spec as Dictionary)
		var id := str((spec as Dictionary).get("id", "?"))
		var portrait := str(identity.get("portrait", ""))
		assert_ne(portrait, "", "trainer '%s' has no plate for the refusal to wear" % id)
		assert_true(ResourceLoader.exists(portrait), "trainer '%s' names a plate that is not on disk: %s" % [id, portrait])
		assert_ne(portrait, PLAYER_PORTRAIT, "trainer '%s' would refuse the player with the player's own face" % id)
		assert_ne(str(identity.get("speaker", "")), "", "trainer '%s' has no name for the refusal" % id)
		checked += 1
	assert_true(checked >= 20, "expected the whole trainer table, checked %d" % checked)
