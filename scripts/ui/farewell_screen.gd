extends "res://scripts/ui/screen.gd"

## One pal, by name, and the last chance to change your mind.
##
## The release screen is a comparison; this is not. Everything on it is about a
## single creature — its name is the largest thing on the screen, and what is
## being given up is stated in that creature's own terms rather than as a row in a
## list. GAME_DESIGN.md §"Sixth capture" asks for exactly this: "Use an emotional
## physical presentation rather than a sterile list when practical."
##
## PUSHED ON TOP, never replacing. `screen_stack.gd` records what the alternative
## cost: hiding the screen underneath "made M5's 'keep one, release one' confirm
## appear to throw the six pals away and then bring them back, which is precisely
## the anxiety that screen exists to avoid." The six stay visible and dim; this
## screen deepens its own scrim through `set_stacked()`, which the base class
## already implements and the stack already calls.
##
## TWO VERBS AND NO THIRD. A lets the pal go; B goes back to the six and clears
## the choice, so backing out here leaves the ceremony exactly as it was rather
## than half-decided. There is no "are you sure" after this one, because a confirm
## that confirms a confirm teaches the player to press through both.
##
## The words are a farewell and not a transaction. No "Delete", no "Remove", no
## bare "Confirm?" — the screen says what actually happens: the pal goes back to
## the meadow and does not come back. `party.gd` and GAME_DESIGN.md both make that
## permanent, and a button that hides it behind a verb from a file manager would
## be lying about the one decision the game asks the player to live with.

# STYLE is inherited from screen.gd. Declaring it again here is a parse error,
# which is the language making the same point party_screen.gd makes: there is one
# set of UI colours and one text treatment.

## The same words the party menu and the release screen use for a pal. If this
## screen described the pal differently, the difference would land on the one
## press that cannot be taken back.
const CARD := preload("res://scripts/ui/pal_card.gd")

## How long the goodbye stays up before the screens close.
##
## A beat, not a wait. Popping on the frame the button was pressed puts the player
## back in the world before they have read the pal's name, which turns a release
## into a menu closing. Long enough to read six words, short enough that nobody
## reaches for the button again. Tunable.
const GOODBYE_SECONDS := 2.4

## How long a refusal stays on screen. Tunable, and the same order as the other
## screens' notices.
const NOTICE_SECONDS := 3.2

## Announced when the release actually happened, with the name of the pal that
## left. The release screen listens for this and re-emits it as
## `ceremony_resolved`, which is what the rest of the game is wired to.
signal farewell_finished(released_name: String)

## The ceremony, held as an Object rather than typed — another agent's file, and
## every call guarded, for `release_screen.gd`'s reason.
var _ceremony: Object = null

## The name of the pal that left, captured at the moment `resolve()` succeeded.
##
## Captured rather than read back, because after a resolve the ceremony's
## `chosen()` is entitled to be empty — the pal is gone, that is the point — and a
## goodbye screen that re-reads it would show a blank where the name should be, in
## the one frame the whole ceremony was built for.
var _released_name: String = ""

## True from the confirm until the screens close. While it is set the screen shows
## the goodbye and takes no input: `focus_count()` returns zero so A does nothing,
## and `cancel()` refuses so B cannot cut the moment short or pop a screen that is
## already popping itself.
var _closing: bool = false
var _hold_left: float = 0.0
## Guards the pop-and-emit so one frame cannot fire it twice.
var _finished: bool = false

var _notice: String = ""
var _notice_left: float = 0.0

@onready var _who: PanelContainer = $Body/Who
@onready var _name_label: Label = $Body/Who/Pad/Lines/Name
@onready var _kind_label: Label = $Body/Who/Pad/Lines/Kind
@onready var _giving: PanelContainer = $Body/Giving
@onready var _giving_label: RichTextLabel = $Body/Giving/Pad/Lines/Body
@onready var _closing_label: RichTextLabel = $Body/Closing
@onready var _notice_label: RichTextLabel = $Body/Notice


func _ready() -> void:
	_who.add_theme_stylebox_override(
		"panel", STYLE.panel_style(STYLE.ROW_BG, STYLE.PANEL_EDGE)
	)
	_giving.add_theme_stylebox_override(
		"panel", STYLE.panel_style(STYLE.ROW_BG, STYLE.PANEL_EDGE)
	)
	super()


## Point the screen at a ceremony. Call this BEFORE pushing it — `on_pushed()`
## takes no arguments and the stack is never going to grow a way to pass one.
func set_ceremony(ceremony: Object) -> void:
	_ceremony = ceremony
	_reset()


func _reset() -> void:
	_closing = false
	_finished = false
	_hold_left = 0.0
	_notice = ""
	_notice_left = 0.0
	_released_name = _display_name_of(_chosen())


func on_pushed() -> void:
	_reset()
	# There is exactly one thing to press here. Zero would mean `screen.gd` never
	# calls `on_activate`, and A would do nothing on the screen where A is the
	# whole point.
	set_focus_index(0)


func on_popped() -> void:
	# Let go of the ceremony, for `rename_screen.on_popped`'s reason: a screen that
	# keeps a reference to a creature the player has just released is a screen that
	# can quietly draw it again on the next frame. The release screen hands the
	# ceremony back every time it pushes this one.
	_ceremony = null


# ------------------------------------------------------------------ the ceremony

func _has(method: String) -> bool:
	return _ceremony != null and _ceremony.has_method(method)


## Whoever the release screen picked, or null.
func _chosen() -> Object:
	if not _has("chosen"):
		return null
	var pal: Variant = _ceremony.call("chosen")
	return pal if pal is Object else null


func _display_name_of(pal: Object) -> String:
	return CARD.display_of(pal) if pal != null else ""


# --------------------------------------------------------------------- drawing

func screen_title() -> String:
	if _closing:
		return "Gone"
	return "Letting one go"


## One thing to press, and nothing at all once the goodbye is up.
##
## `screen.gd` only calls `on_activate` when this is above zero, so returning zero
## while closing is how the screen stops taking input without polling anything —
## which `screen_stack.gd` forbids in its header, and rightly.
func focus_count() -> int:
	return 0 if _closing else 1


func hints() -> Array[Array]:
	var rows: Array[Array] = []
	if _closing:
		# Both glyphs still drawn, both dimmed. `ui_style.gd`: a widget that
		# vanishes reads as broken; one that changes reads as an answer.
		rows.append(["A", "Let go", false])
		rows.append(["B", "Back to the six", false])
		return rows
	var pal := _chosen()
	var pal_name := _display_name_of(pal)
	if pal_name == "":
		rows.append(["A", "Nobody is chosen", false])
		rows.append(["B", "Back to the six", true])
		return rows
	# NAMES THE PAL on both buttons. "Confirm / Cancel" on the one irreversible
	# press in the game tells the player nothing about what they are confirming,
	# and the footer is the only place a screenshot can show what A would have
	# done.
	rows.append(["A", "Let %s go" % pal_name, true])
	rows.append(["B", "Keep %s for now" % pal_name, true])
	return rows


func refresh() -> void:
	_notice_left = maxf(0.0, _notice_left - get_process_delta_time())
	if _notice_left <= 0.0:
		_notice = ""

	if _closing:
		_hold_left = maxf(0.0, _hold_left - get_process_delta_time())
		_draw_goodbye()
		if _hold_left <= 0.0:
			_finish()
		return

	_draw_subject(_chosen())
	_draw_notice()


func _draw_subject(pal: Object) -> void:
	if pal == null:
		# Honest about which failure this is, the way the party menu distinguishes an
		# empty slot from a missing party. Nothing has been released; B goes back.
		_name_label.text = "No one is chosen"
		_kind_label.text = ""
		_giving.visible = true
		_giving_label.text = (
			"[color=#%s]This is the goodbye for one pal, and the release screen has "
			% STYLE.INK_DIM
			+ "not named one.\n\nNothing has been let go. Go back to the six and "
			+ "choose.[/color]"
		)
		_closing_label.text = ""
		_draw_notice()
		return

	var pal_name := _display_name_of(pal)
	_name_label.text = pal_name
	_name_label.modulate = Color.WHITE

	# The species under the name, always — unlike the party menu, which hides it
	# when it would repeat the heading. Here it is part of what is being lost: a
	# named pal is a Bramblit as well as a Pip, and the species is the half of that
	# the player can still catch another of.
	var species := CARD.species_of(pal)
	var level := int(CARD.number(pal, "level", 1.0))
	if species == "" or species == pal_name:
		_kind_label.text = "level %d" % level
	else:
		_kind_label.text = "%s  ·  level %d" % [species, level]
	_kind_label.modulate = Color.html(STYLE.INK_DIM)

	_giving.visible = true
	_giving_label.text = "\n".join(_giving_up_lines(pal))
	_closing_label.text = "[center]%s[/center]" % _permanence_words(pal_name)


## What is actually being given up, in sentences.
##
## Not the appraisal panel from the party menu. That panel is built for comparing
## two creatures — stat by stat, star row by star row — and this screen is not a
## comparison; the comparison already happened on the six. What belongs here is
## what this one pal has that nothing else will have again: the level it reached,
## the experience it earned toward the next one, and the trait it was born with.
##
## The verdict word and the stars come from `pal_card.gd` even so, because they
## are the same judgement the player has been reading in the party menu all game
## and this is the worst possible moment to word it differently.
func _giving_up_lines(pal: Object) -> Array[String]:
	var lines: Array[String] = []
	var appraisal := CARD.appraisal_of(pal)
	var level := int(CARD.number(pal, "level", 1.0))

	lines.append("[color=#%s]It reached[/color]  [b]Level %d[/b]" % [STYLE.INK_DIM, level])

	var needed := int(appraisal.get("xp_for_next_level", 0))
	var xp := int(appraisal.get("xp", int(CARD.number(pal, "xp", 0.0))))
	if needed > 0:
		# The number AND its denominator. `pal_instance.grant_xp` is explicit about
		# why: xp is progress within the current level, not a lifetime total, and
		# "anything printing this number should print its denominator with it" —
		# otherwise 312 looks like everything the creature ever earned.
		lines.append("[color=#%s]It earned[/color]  [b]%d of the %d xp[/b]  [color=#%s]it needed for Level %d[/color]" % [
			STYLE.INK_DIM, xp, needed, STYLE.INK_DIM, level + 1
		])
	else:
		lines.append("[color=#%s]It had grown[/color]  [b]as far as it can[/b]" % STYLE.INK_DIM)

	var trait_dict := CARD.trait_data(pal)
	var trait_name := str(trait_dict.get("display_name", ""))
	if trait_name == "":
		trait_name = CARD.trait_of(pal)
	lines.append("[color=#%s]It carried[/color]  [b]%s[/b]" % [STYLE.INK_DIM, trait_name])
	var description := str(trait_dict.get("description", ""))
	if description != "":
		lines.append("[color=#%s]%s[/color]" % [STYLE.INK_DIM, description])

	if not appraisal.is_empty():
		var max_stars := maxi(1, int(appraisal.get("max_stars", STYLE.STARS)))
		var stars := int(appraisal.get("stars", 0))
		lines.append("")
		lines.append("[color=#%s]You appraised it[/color]  [b]%s[/b]   %s" % [
			STYLE.INK_DIM, CARD.verdict(stars, max_stars), STYLE.star_row(stars, max_stars)
		])
	return lines


## The sentence that says what "release" means. It is the whole reason this screen
## is not a delete dialog, so it is stated plainly and it is never abbreviated.
func _permanence_words(pal_name: String) -> String:
	return (
		"%s goes back to the meadow.\n" % pal_name
		+ "It will not be waiting for you there, and it will not come back."
	)


func _draw_goodbye() -> void:
	_name_label.text = _released_name if _released_name != "" else "Gone"
	_name_label.modulate = Color.WHITE
	_kind_label.text = "gone back to the meadow"
	_kind_label.modulate = Color.html(STYLE.INK_DIM)
	# The list of what was given up comes DOWN at this point. Leaving it up while
	# the goodbye is on screen reads as an invoice.
	_giving.visible = false
	_closing_label.text = "[center][color=#%s]Goodbye, %s.[/color][/center]" % [
		STYLE.INK, _released_name if _released_name != "" else "friend"
	]
	if _notice_label.text != "":
		_notice_label.text = ""


func _draw_notice() -> void:
	if _notice == "":
		if _notice_label.text != "":
			_notice_label.text = ""
		return
	var wanted := "[center][color=#%s]%s[/color][/center]" % [STYLE.WARN, _notice]
	# Compared before assigning: a RichTextLabel re-parses its bbcode on every
	# write, and this line is identical for every frame of the seconds it is up.
	if _notice_label.text != wanted:
		_notice_label.text = wanted


# ------------------------------------------------------------------- the verbs

## A releases, for real. This is the only place in the project that calls
## `resolve()`.
##
## On an empty Dictionary the screen STAYS. A refusal means nothing happened, and
## closing on it would leave the player back in the world believing a pal is gone
## when it is not — or, worse, believing the sixth was kept when the party never
## took it.
func on_activate(_index: int) -> void:
	if _closing:
		return
	if _ceremony == null:
		_say("there is no ceremony to finish here")
		return
	if not _has("resolve"):
		_say("this ceremony cannot be finished")
		return

	var pal := _chosen()
	if pal == null and _has("chosen_index") and int(_ceremony.call("chosen_index")) < 0:
		_say("nobody is chosen yet — go back and pick one of the six")
		return
	var pal_name := _display_name_of(pal)

	var result: Variant = _ceremony.call("resolve")
	var outcome: Dictionary = result if result is Dictionary else {}
	if outcome.is_empty():
		_say(_refusal_words(_last_refusal()))
		return

	# The name comes from what the ceremony says it RELEASED, not from what this
	# screen thought was chosen. They are the same pal in every ordinary case, and
	# on the day they are not, the goodbye should name the creature that actually
	# left.
	var released: Variant = outcome.get("released")
	if released is Object:
		var released_name := CARD.display_of(released)
		if released_name != "" and released_name != "?":
			pal_name = released_name
	_released_name = pal_name if pal_name != "" else "your pal"

	_notice = ""
	_notice_left = 0.0
	_closing = true
	_hold_left = GOODBYE_SECONDS


## B goes back to the six and UNPICKS.
##
## Returning false hands the pop to the stack, which is the whole contract in
## `screen.gd`. `clear_choice()` is called on the way out so the ceremony is not
## left holding a decision the player walked away from — the release screen would
## otherwise come back with a pal quietly still chosen, and the next A press would
## resolve something the player never confirmed.
func cancel() -> bool:
	if _closing:
		# The goodbye is not a screen you can cancel out of; the pal is already gone
		# and the pop is a timer away. Returning true keeps the stack from popping
		# this screen twice.
		return true
	if _has("clear_choice"):
		_ceremony.call("clear_choice")
	return false


## Pop, then announce.
##
## In that order deliberately: the release screen's handler pops ITSELF, and it
## can only do that safely when this screen is already off the top. The name is
## copied into a local first because `on_popped()` lets go of everything.
func _finish() -> void:
	if _finished:
		return
	_finished = true
	var released_name := _released_name
	var stack := get_parent()
	if stack != null and stack.has_method("pop"):
		if not stack.has_method("top") or stack.call("top") == self:
			stack.call("pop")
	farewell_finished.emit(released_name)


func _last_refusal() -> String:
	if not _has("last_refusal"):
		return ""
	return str(_ceremony.call("last_refusal"))


## A refusal token, in player voice. The tokens belong to `release_ceremony.gd`;
## an unrecognised one falls back to a general line rather than being printed,
## for `party_screen._refusal_words`' reason — a token nobody has translated yet
## is still a token, and the player should never be shown one.
func _refusal_words(token: String) -> String:
	match token:
		"no_choice", "nothing_chosen":
			return "nobody is chosen yet — go back and pick one of the six"
		"already_resolved":
			return "this has already been decided"
		"no_such_member", "out_of_range":
			return "that pal is not among the six any more"
		"party_full":
			return "the party is still full — nothing has been let go yet"
		"not_a_pal":
			return "that is not a creature that can be let go"
		_:
			return "that cannot be done right now, and nothing has changed"


func _say(message: String) -> void:
	_notice = message
	_notice_left = NOTICE_SECONDS
