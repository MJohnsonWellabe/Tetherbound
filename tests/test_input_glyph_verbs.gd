extends "res://tests/test_case.gd"

## BINDINGS. `input_glyph.gd`'s device-aware verb resolution, and the sweep that
## found it, kept from rotting.
##
## The defect: `data/progression/objectives.json`'s opening rung -- the tutorial
## line for the game's first catch -- writes the token `{combat_throw}`, and
## CONTROLLER-MAP (`docs/decisions/D68`) had taken `combat_throw`'s joypad event
## away when the orb became a hotbar item thrown with `interact`. Every resolver
## answered honestly ("no pad binding") and fell through to the keyboard key, so
## the card rendered *"pick an orb on the hotbar and press F"* on a frame whose
## every other glyph was a pad glyph -- telling a ROG Ally player to press a key
## the device does not have, on the mechanic the owner reports as the worst
## feeling in the game.
##
## Three properties are locked here, and the third is the one that matters most
## in six months' time:
##
## 1. The verb resolver names the pad button the player really presses.
## 2. The literal resolver stays literal, because the Settings tab's gamepad
##    column rebinds exactly that and must not be shown an alias it cannot edit.
## 3. Every action the pad map deliberately leaves unbound is ACCOUNTED FOR --
##    either aliased to the action that carries its verb, or named in
##    `NO_SINGLE_PAD_BUTTON` below with the reason no alias is honest. A seventh
##    action losing its pad binding shows up here as a failure rather than as
##    another keyboard letter on a handheld.

const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
const CONTROLS := preload("res://tests/test_controls.gd")

const OBJECTIVES_PATH := "res://data/progression/objectives.json"

## The pad-unbound actions that are NOT aliasable, and why. These are the verbs
## CONTROLLER-MAP retired rather than moved: the torch and the build hammer
## became hotbar tools, so the pad path is select-then-press and no single
## button performs the verb. An alias would print "X toggles the torch", which
## is false until the torch is the selected tool -- a different lie, not a fix.
## Their hints must name the two steps in prose the way `objectives.json`'s
## gather and build rungs already do.
const NO_SINGLE_PAD_BUTTON := {
	"torch_toggle": "the torch is a hotbar tool: select it, then interact",
	"torch_place": "same verb's fast-equip half",
	"build_open": "the build hammer is a hotbar tool: select it, then interact",
}


func test_the_throw_verb_names_the_pad_button_that_actually_throws() -> void:
	# `combat_manager.gd::_throw_pressed()` and `throw_aim.gd` both read
	# `interact` beside `combat_throw`'s keyboard F, and
	# `smoke_controller_catching.gd` opens the aim with a physical JOY_BUTTON_X
	# and nothing else. X is the answer a pad player needs.
	assert_eq(INPUT_GLYPH.pad_button_name_for_verb("combat_throw"), "X")


func test_the_flee_verb_names_the_pad_button_that_actually_flees() -> void:
	# `combat_manager.gd::_flee_pressed()` reads `creature_recall` beside
	# `combat_run`'s Escape. D68: "flee is `creature_recall` on RB".
	assert_eq(INPUT_GLYPH.pad_button_name_for_verb("combat_run"), "RB")


func test_the_tool_swing_verb_names_interact() -> void:
	# `harvest_logic.gd`: "X/`interact` is what chops and mines".
	assert_eq(INPUT_GLYPH.pad_button_name_for_verb("use_tool"), "X")


func test_the_literal_resolver_still_reports_no_pad_binding() -> void:
	# The Settings tab's gamepad column reads the literal answer, because that
	# is the cell the player edits. An empty cell for `combat_throw` is correct
	# rather than broken (`data/config/menu.json` says so in as many words), and
	# the alias must never leak into it.
	for id in ["combat_throw", "combat_run", "use_tool"]:
		assert_eq(INPUT_GLYPH.pad_button_name_for_action(str(id)), "",
			"%s should still report no joypad event of its own" % id)


func test_an_action_with_its_own_pad_button_is_never_aliased() -> void:
	# The action's own binding wins, so a player who binds a pad button to
	# `combat_throw` in Settings is told about THEIR button. Verified on an
	# action that has one today rather than by mutating the live InputMap.
	assert_eq(INPUT_GLYPH.pad_button_name_for_verb("interact"), "X")
	assert_eq(INPUT_GLYPH.pad_button_name_for_verb("creature_recall"), "RB")
	assert_eq(INPUT_GLYPH.pad_button_name_for_verb("inventory"), "Y")


func test_an_unaliased_padless_action_still_returns_nothing() -> void:
	# The honest answer for a verb a pad genuinely cannot reach in one press.
	# The caller then falls back to the bound key exactly as it did before.
	assert_eq(INPUT_GLYPH.pad_button_name_for_verb("torch_toggle"), "")


func test_the_keyboard_answer_is_untouched() -> void:
	# The other half of the repair's contract: swapping the token to
	# `{interact}` would have inverted the bug, because on a keyboard `interact`
	# is E while the throw really is F. A desktop player must still read F.
	assert_eq(INPUT_GLYPH.key_name_for_action("combat_throw"), "F")
	assert_eq(INPUT_GLYPH.key_name_for_action("interact"), "E")


func test_every_alias_target_actually_carries_a_pad_button() -> void:
	# A table entry pointing at an action that has itself lost its pad binding
	# would resolve to "" and put the keyboard letter straight back on screen,
	# silently.
	for id: String in INPUT_GLYPH.PAD_VERB_ALIAS:
		var target := str(INPUT_GLYPH.PAD_VERB_ALIAS[id])
		assert_true(InputMap.has_action(target),
			"%s is aliased to %s, which is not in the input map" % [id, target])
		assert_ne(INPUT_GLYPH.pad_button_name_for_action(target), "",
			"%s is aliased to %s, which has no joypad button to lend it" % [id, target])


func test_every_alias_key_is_an_action_the_pad_map_left_unbound() -> void:
	# The inverse rot: an entry for an action that has since been GIVEN a pad
	# button is dead weight that reads as load-bearing. `test_controls.gd` owns
	# the authoritative list of what the authored map leaves unbound.
	var unbound: Dictionary = CONTROLS.PAD_UNBOUND_BY_DESIGN
	for id: String in INPUT_GLYPH.PAD_VERB_ALIAS:
		assert_true(unbound.has(id),
			"%s is aliased but is not one of the actions the authored pad map leaves unbound -- remove the alias or update test_controls.gd" % id)


func test_every_padless_action_is_either_aliased_or_explained() -> void:
	# The sweep, encoded. Every action CONTROLLER-MAP took off the pad has to be
	# one of two things: moved (so an alias names where it went) or retired (so
	# it is listed above with the reason no single button performs it). Neither
	# is a state a future action can fall into by accident.
	for id: String in CONTROLS.PAD_UNBOUND_BY_DESIGN:
		var aliased: bool = INPUT_GLYPH.PAD_VERB_ALIAS.has(id)
		var explained: bool = NO_SINGLE_PAD_BUTTON.has(id)
		assert_true(aliased != explained,
			"%s must be either aliased to the action carrying its verb or listed in NO_SINGLE_PAD_BUTTON with why it cannot be -- it is currently %s" % [
				id, ("both" if aliased and explained else "neither")])


func test_no_authored_hint_names_a_verb_a_pad_cannot_reach() -> void:
	# The defect's own shape, swept across the content rather than fixed at one
	# call site. Every `{token}` in every authored `how` line must resolve to a
	# real pad button, or the card that draws it prints a keyboard key on a
	# handheld -- which is exactly what the first-catch rung did.
	var file := FileAccess.open(OBJECTIVES_PATH, FileAccess.READ)
	assert_true(file != null, "could not open %s" % OBJECTIVES_PATH)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_true(parsed is Dictionary, "%s did not parse as an object" % OBJECTIVES_PATH)
	if not (parsed is Dictionary):
		return
	var checked := 0
	for raw: Variant in (parsed as Dictionary).get("main", []):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		for id in _tokens_in(str((raw as Dictionary).get("how", ""))):
			checked += 1
			assert_true(InputMap.has_action(id),
				"objectives.json writes {%s}, which is not an input action" % id)
			assert_ne(INPUT_GLYPH.pad_button_name_for_verb(id), "",
				"objectives.json rung '%s' writes {%s}, which resolves to no pad button -- on a controller that hint names a keyboard key" % [
					str((raw as Dictionary).get("id", "?")), id])
	assert_true(checked > 0, "found no {tokens} at all; the sweep is not looking at anything")


## Every `{action}` id in one authored line, in the order `quest_log.gd`'s own
## `hint_text()` walks them.
func _tokens_in(how: String) -> Array[String]:
	var out: Array[String] = []
	var rest := how
	while true:
		var open_at := rest.find("{")
		if open_at == -1:
			break
		var close_at := rest.find("}", open_at)
		if close_at == -1:
			break
		out.append(rest.substr(open_at + 1, close_at - open_at - 1))
		rest = rest.substr(close_at + 1)
	return out
