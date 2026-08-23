extends "res://tests/test_case.gd"

## The build hammer must not forfeit the interact button to a status line.
##
## Under CONTROLLER-MAP (`ralph/OWNER_DIRECTIVES_2026-08-22.md` §1) `build_open`
## has no pad button: "Build hammer is the same pattern: select it, press
## interact, you are in build mode." So `playground_hud.gd::
## _hammer_opens_the_catalogue()` is the ONLY route into build mode on a pad.
##
## It used to refuse whenever `_arbiter.winning_provider() != null` -- whenever
## ANY provider was drawing a line. But
## `encounter_director.gd::_creature_control_offer()` falls back to a
## NON-ACTIONABLE status line, "[RB] Call out <creature>", for any player who
## has a creature and is standing near nothing else. That is most players most
## of the time, and it advertises a different button entirely.
##
## `interaction_arbiter.gd::activate()` already refuses to fire a non-actionable
## winner, so the interact press was genuinely free -- the hammer was losing the
## button to a line that was never going to consume it. Observed as three of
## three cycles of `smoke_post_modal_control.gd` reporting "the hammer +
## interact opened nothing (the prompt provider EncounterDirector is winning the
## interact button)", and it is the other half of the owner's "building doesn't
## work" report: not a fight for the button, but a forfeit to something that was
## not asking for it.
##
## Pure logic, per test_case.gd/D02. `smoke_post_modal_control.gd` is the live
## check; this pins the CONTRACT, because the failure it guards is a single
## predicate whose regression is invisible in any test that does not boot the
## world with a creature in the party.

const PROMPTS := preload("res://scripts/world/prompt_arbiter.gd")
const HUD_PATH := "res://scripts/ui/playground_hud.gd"


func _hud_source() -> String:
	var file := FileAccess.open(HUD_PATH, FileAccess.READ)
	assert_true(file != null, "playground_hud.gd is missing")
	if file == null:
		return ""
	return file.get_as_text()


func _hammer_gate() -> String:
	var source := _hud_source()
	var start := source.find("func _hammer_opens_the_catalogue(")
	assert_true(start >= 0, "playground_hud.gd has no _hammer_opens_the_catalogue")
	if start < 0:
		return ""
	var end := source.find("\nfunc ", start + 1)
	return source.substr(start, (end - start) if end > start else -1)


func test_the_creature_control_status_line_is_not_actionable() -> void:
	# The premise the fix rests on. If this ever became actionable, the hammer
	# SHOULD stand down and the gate below would be wrong -- so it is asserted
	# here rather than assumed.
	var status := PROMPTS.offer("[RB]  Call out Pip", 0.0, -1, false)
	assert_false(PROMPTS.is_actionable(status),
		"a non-actionable offer reports as actionable; the hammer gate's premise is gone")


func test_an_empty_label_is_not_actionable_either() -> void:
	assert_false(PROMPTS.is_actionable(PROMPTS.offer("", 0.0)),
		"an offer with no label should not count as actionable")


func test_a_real_offer_still_is() -> void:
	assert_true(PROMPTS.is_actionable(PROMPTS.offer("Engage Bramblebun", 3.0)),
		"an ordinary offer must stay actionable, or the hammer would steal the button "
		+ "from a prompt that genuinely wants it")


func test_the_hammer_asks_whether_the_button_is_spoken_for() -> void:
	var gate := _hammer_gate()
	assert_true(gate.contains("is_actionable"),
		"the hammer gate does not check whether the winning offer is ACTIONABLE; "
		+ "it will forfeit the interact button to a status line for a different button, "
		+ "and hammer + interact is the only pad route into build mode")


func test_the_hammer_does_not_stand_down_for_merely_having_a_winner() -> void:
	var gate := _hammer_gate()
	# The exact shape of the old bug: asking WHO is winning rather than WHETHER
	# the button is spoken for.
	var start := gate.find("winning_provider")
	if start < 0:
		return
	var line_end := gate.find("\n", start)
	var line := gate.substr(start, (line_end - start) if line_end > start else -1)
	assert_true(line.contains("is_actionable"),
		"the hammer gate still turns on winning_provider() != null: "
		+ "'%s'" % line.strip_edges())
