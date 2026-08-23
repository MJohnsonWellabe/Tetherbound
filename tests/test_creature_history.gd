extends "res://tests/test_case.gd"

## FIVE-CREATURE-PRESSURE (prompt 67): the release ceremony must surface the
## creature's battle history and time together.
##
## The 2026-08-22 Gate C audit found there was nothing to surface. The only
## time-ish field on `creature_instance.gd` was `rested_seconds_left` — no
## battles fought, no caught-on-day, no days-together. A five-creature cap is
## meant to make giving one up cost something, and it cannot cost anything if
## the game cannot say what the creature did.
##
## Three counters rather than an event log: the ceremony needs one honest
## sentence, and a log would be a save-size problem in service of a line nobody
## reads.

const INSTANCE := preload("res://scripts/creatures/creature_instance.gd")
const SPECIES := preload("res://scripts/creatures/creature_species.gd")
const PROGRESSION := preload("res://scripts/creatures/progression.gd")


func _creature() -> RefCounted:
	var cfg := PROGRESSION.config()
	return INSTANCE.from_species(
		"terrapup", SPECIES.definition("terrapup"), 0.5, cfg, [0.5, 0.5, 0.5], [0.5, 0.5])


func test_a_fresh_creature_has_no_history_to_claim() -> void:
	var c := _creature()
	assert_eq(int(c.get("battles_fought")), 0)
	assert_eq(int(c.get("caught_on_day")), 0)
	assert_eq(int(c.get("levels_gained_with_you")), 0)


func test_the_history_survives_a_save_and_load() -> void:
	# The whole point of the counters is that they accumulate across a chapter.
	# A field the save drops is a field that reads zero every time the player
	# actually reaches the ceremony, which is late.
	var file := FileAccess.open("res://scripts/save/save_game.gd", FileAccess.READ)
	assert_true(file != null, "save_game.gd is missing")
	if file == null:
		return
	var source := file.get_as_text()
	for field: String in ["battles_fought", "caught_on_day", "levels_gained_with_you"]:
		var writes := source.count("\"%s\"" % field)
		assert_true(writes >= 2,
			"save_game.gd mentions '%s' %d time(s); it needs both a write and a read"
				% [field, writes])


func test_an_old_save_reports_no_history_rather_than_zero_battles() -> void:
	var file := FileAccess.open("res://scripts/ui/tab_creatures.gd", FileAccess.READ)
	assert_true(file != null, "tab_creatures.gd is missing")
	if file == null:
		return
	var source := file.get_as_text()
	var start := source.find("func _history_line(")
	assert_true(start >= 0, "tab_creatures.gd has no _history_line")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	# A pre-VERSION-14 save was not keeping the history. Printing "0 battles"
	# would be a CLAIM about a creature that may have fought a hundred; printing
	# nothing is the truth.
	assert_true(body.contains("battles > 0"),
		"_history_line does not guard on a positive battle count, so an old save "
		+ "would claim '0 battles beside you' about a creature it simply was not "
		+ "counting for")
	assert_true(body.contains("is_empty()"),
		"_history_line has no empty case; a creature caught this minute has no "
		+ "history and the ceremony must say nothing rather than say zero")


func test_the_farewell_beat_actually_asks_for_the_history() -> void:
	var file := FileAccess.open("res://scripts/ui/tab_creatures.gd", FileAccess.READ)
	if file == null:
		return
	var source := file.get_as_text()
	var start := source.find("func _begin_farewell(")
	assert_true(start >= 0, "tab_creatures.gd has no _begin_farewell")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	assert_true(body.contains("_history_line("),
		"the confirm beat does not include the history; prompt 67 asks for it at "
		+ "the exact press that gives the creature up")


func test_battles_are_recorded_where_the_fight_is_already_scored() -> void:
	var file := FileAccess.open("res://scripts/combat/combat_manager.gd", FileAccess.READ)
	assert_true(file != null, "combat_manager.gd is missing")
	if file == null:
		return
	var source := file.get_as_text()
	assert_true(source.contains("battles_fought"),
		"nothing in combat_manager.gd records a battle fought")
	# It must ride the SAME loop that awards XP, because that loop already skips
	# a fainted member on the rule "it did not fight". Two definitions of what
	# counts as a battle would drift.
	# Anchor on the call that DEFINES the loop, not on a string that happens to
	# sit near it. The first version searched for `last_xp_award.clear()`, which
	# appears TWICE in this file -- once in a reset path hundreds of lines above
	# the award loop -- so it anchored on the wrong one and read a window that
	# could never contain the thing it was looking for. It reported the counter
	# missing from code that has it.
	var start := source.find("gain_xp(")
	assert_true(start >= 0,
		"combat_manager.gd no longer calls gain_xp(); the XP award loop has moved "
		+ "and this check cannot find the site it is about")
	if start < 0:
		return
	# Backed up to the top of the loop body so the window covers it, then
	# generous enough to reach the end of the per-member work.
	start = maxi(0, start - 400)
	var window := source.substr(start, 1400)
	assert_true(window.contains("battles_fought"),
		"battles_fought is not recorded in the XP award loop; that loop already "
		+ "decides who fought, and a second definition of 'fought' would drift "
		+ "from it")


func test_the_caught_day_is_stamped_on_the_one_path_every_catch_takes() -> void:
	var file := FileAccess.open("res://scripts/combat/encounter_director.gd", FileAccess.READ)
	assert_true(file != null, "encounter_director.gd is missing")
	if file == null:
		return
	var source := file.get_as_text()
	var start := source.find("func _resolve_catch(")
	assert_true(start >= 0, "encounter_director.gd has no _resolve_catch")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	assert_true(body.contains("caught_on_day"),
		"_resolve_catch does not stamp the day; it is the one path every catch "
		+ "takes, including the tutorial's, which is why it belongs there")
