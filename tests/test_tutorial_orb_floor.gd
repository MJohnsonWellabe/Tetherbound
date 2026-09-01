extends "res://tests/test_case.gd"

## The opening must not be able to run out of orbs.
##
## `combat_manager.gd::configure_tutorial_catch_assist()` keeps half of
## docs/OPENING_SEQUENCE.md's promise that the practice catch cannot fail twice:
## `catch_math.apply_failure_bound()` converts the second FAILED ROLL. It counts
## landed throws on purpose -- a throw that never reached the creature is not a
## failed catch -- and that leaves the other half open. A player who MISSES is
## bounded by nothing except how many orbs they are carrying.
##
## Which would be harmless if orbs were replaceable at that point, and they are
## not. Grandpa hands over fifty (`give:orb_basic:50`, data/dialogue/opening.json).
## The renewable recipe is taught by Mira's required opening visit, but the
## player still cannot craft during this authored practice catch. So an opening
## that runs dry is a hard dead-end:
## `throw_aim.gd::try_begin_aim()` refuses every further press with "no orbs
## left" while `sequence_director.gd` holds the beat waiting for a catch that
## can no longer be attempted. There is no exit but a new game.
##
## `opening.json`'s `catch_orb_floor` is the floor under that, applied by the
## director on the refusal itself. This test covers the two halves that a
## behavioural run cannot pin down on its own: that the config still carries a
## floor at all, and that the floor is wired behind the SAME beat-and-species
## predicate as the failure bound, so it cannot follow the player out of the
## opening. The live end-to-end evidence is
## `tests/smoke_gate_a_opening_segment.gd`, which drains the satchel to its last
## orb before the catch loop specifically so every run walks this path.

const DIRECTOR_PATH := "res://scripts/story/sequence_director.gd"
const OPENING_CONFIG := "res://data/config/opening.json"


func _director_source() -> String:
	var file := FileAccess.open(DIRECTOR_PATH, FileAccess.READ)
	assert_true(file != null, "sequence_director.gd is missing")
	if file == null:
		return ""
	return file.get_as_text()


func _encounter() -> Dictionary:
	var file := FileAccess.open(OPENING_CONFIG, FileAccess.READ)
	assert_true(file != null, "data/config/opening.json is missing")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "opening.json does not parse as an object")
	if not (parsed is Dictionary):
		return {}
	return (parsed as Dictionary).get("encounter", {})


func test_the_opening_configures_a_floor_under_the_tutorial_orb_supply() -> void:
	var encounter := _encounter()
	assert_true(encounter.has("catch_orb_floor"),
		"opening.json's encounter beat has no catch_orb_floor; running out of orbs "
		+ "during the practice catch dead-ends the game with no way out but a new one")
	var floor_value := int(encounter.get("catch_orb_floor", 0))
	assert_true(floor_value > 0,
		"catch_orb_floor is %d; a floor of zero is no floor" % floor_value)
	# Not a stockpile either. The floor exists so the beat stays winnable, not so
	# the player leaves the opening with a satchel Grandpa never gave them.
	assert_true(floor_value <= 50,
		"catch_orb_floor is %d, more than Grandpa's own gift of fifty" % floor_value)


func test_the_floor_answers_the_refusal_the_empty_satchel_actually_emits() -> void:
	var source := _director_source()
	# The exact string throw_aim.gd emits. If that wording ever changes, the
	# handler silently stops firing and the dead-end comes back with every test
	# still green -- so the two are pinned together here.
	var throw_file := FileAccess.open("res://scripts/combat/throw_aim.gd", FileAccess.READ)
	assert_true(throw_file != null, "throw_aim.gd is missing")
	if throw_file == null:
		return
	assert_true(throw_file.get_as_text().contains('throw_refused.emit("no orbs left")'),
		"throw_aim.gd no longer refuses an empty satchel with 'no orbs left'; "
		+ "sequence_director.gd matches on that exact string")
	assert_true(source.contains('"no orbs left"'),
		"sequence_director.gd does not react to the empty-satchel refusal")
	assert_true(source.contains('_manager.connect("catch_refused"'),
		"sequence_director.gd never connects catch_refused, so the floor can never fire")


## Both ways into the floor must reach the one that checks the predicate.
##
## There are two: the per-frame hold (so the beat never runs dry) and the
## refusal backstop (for a drain that lands between frames). Neither may apply
## the floor on its own -- one rule, one place, or the two drift apart and only
## one of them stays gated.
func test_both_entry_points_route_through_the_one_gated_restock() -> void:
	var source := _director_source()
	assert_true(source.contains("_hold_the_tutorial_orb_floor()"),
		"sequence_director.gd has no _hold_the_tutorial_orb_floor")
	var start := source.find("func _on_catch_refused(")
	assert_true(start >= 0, "sequence_director.gd has no _on_catch_refused handler")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var handler := source.substr(start, (end - start) if end > start else -1)
	assert_true(handler.contains("_hold_the_tutorial_orb_floor()"),
		"the refusal handler restocks by itself instead of going through the gated path")
	assert_false(handler.contains("inventory"),
		"the refusal handler touches the satchel directly; the gate lives in "
		+ "_hold_the_tutorial_orb_floor and this would bypass it")
	# Per-frame, so the player never presses a button that does nothing.
	var process_start := source.find("func _process(")
	assert_true(process_start >= 0, "sequence_director.gd has no _process")
	if process_start < 0:
		return
	var process_end := source.find("\nfunc ", process_start + 1)
	var process_body := source.substr(
		process_start, (process_end - process_start) if process_end > process_start else -1
	)
	assert_true(process_body.contains("_hold_the_tutorial_orb_floor()"),
		"the floor is not held per frame; reacting to the refusal alone restocks "
		+ "one press too late, after a button that visibly did nothing")


func test_the_floor_cannot_follow_the_player_out_of_the_opening() -> void:
	var source := _director_source()
	var start := source.find("func _hold_the_tutorial_orb_floor(")
	assert_true(start >= 0, "sequence_director.gd has no _hold_the_tutorial_orb_floor")
	if start < 0:
		return
	var end := source.find("\nfunc ", start + 1)
	var body := source.substr(start, (end - start) if end > start else -1)
	# Same gate as the failure bound: beat AND species. A floor that checked only
	# the beat would restock a player fighting something else in the meadow, and
	# one that checked only the species would follow every later Bramblebun.
	assert_true(body.contains("_is_tutorial_catch()"),
		"the orb floor does not check that this is the authored practice catch; "
		+ "it would restock fights the opening has nothing to do with")
	var predicate_start := source.find("func _is_tutorial_catch(")
	assert_true(predicate_start >= 0, "sequence_director.gd has no _is_tutorial_catch predicate")
	if predicate_start < 0:
		return
	var predicate_end := source.find("\nfunc ", predicate_start + 1)
	var predicate := source.substr(
		predicate_start, (predicate_end - predicate_start) if predicate_end > predicate_start else -1
	)
	assert_true(predicate.contains("BEATS.ENCOUNTER"),
		"_is_tutorial_catch does not check the beat")
	assert_true(predicate.contains("species_id"),
		"_is_tutorial_catch does not check the species")


func test_the_floor_reads_its_size_from_config_rather_than_a_literal() -> void:
	var source := _director_source()
	assert_true(source.contains('"catch_orb_floor"'),
		"sequence_director.gd hardcodes the restock size instead of reading "
		+ "opening.json's catch_orb_floor; CLAUDE.md keeps tunables in data")
