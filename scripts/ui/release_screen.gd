extends "res://scripts/ui/screen.gd"

## Six pals and five places. The screen where the party limit is paid for.
##
## MEADOWS_VERTICAL_SLICE.md M5 ends with the line this whole screen is written
## against: "Do not settle for a generic 'delete' dialog." A list with a Delete
## button satisfies every other bullet in that milestone and fails the one that
## matters, because what the player is doing here is not deleting a record. They
## caught a creature, named it, levelled it, and now one of six is going back to
## the meadow and will not come back.
##
## SO ALL SIX ARE ON SCREEN AT ONCE. Not a list you scroll and not a dialog that
## asks about one pal at a time: the decision is a comparison, and a comparison
## you have to make from memory is a comparison the player will make badly and
## then regret. The sixth — the one just caught — is marked three ways (its own
## header word, its own border, its own line) because the single most confusing
## thing this screen could do is let the stranger look like one of the family.
##
## THERE IS NO WAY OUT. `party.gd`'s header says why in the data layer: "THERE IS
## NO OVERFLOW. No box, no PC, no 'temporarily holding' list, not even a private
## one... The moment a sixth can sit anywhere in memory, the release ceremony
## stops being the only way to resolve a full party, and the design's one
## irreversible decision becomes optional." B on this screen is the same rule
## wearing a different coat: backing out would be a sixth pal parked in a menu.
## So B answers, in the pal's own terms, and stays put.
##
## The exception is a ceremony with nothing in it. A screen that cannot resolve
## anything is a wiring fault rather than a decision, and trapping the player
## inside one would turn a missing NodePath into a lost save. See `cancel()`.
##
## Pull, don't push, like every other screen: the six are read from the ceremony
## every frame rather than snapshotted, so a card cannot end up describing a
## creature that has since changed.

# STYLE is inherited from screen.gd. Declaring it again here is a parse error,
# which is the language making the same point party_screen.gd makes: there is one
# set of UI colours and one text treatment.

## How a pal is put into words. The same file the party menu uses, on purpose:
## if that menu calls a pal "Promising" and this screen calls the same pal
## something else, the player has been handed two different reasons and one
## irreversible button.
const CARD := preload("res://scripts/ui/pal_card.gd")

## Six. Five of yours plus the one you just caught, and it is not a tunable —
## `party.gd` fixes the five as a const rather than a config value because "a
## config value can be edited; a const has to be argued with", and the sixth is
## the capture that started this. A ceremony that reports more gets six cards and
## a warning rather than a seventh card that quietly implements storage.
const MAX_CARDS := 6

## Three across, two down. Six in a row would be six narrow strips nobody can
## read a trait off; six in a column is the party menu with an extra row, which
## is exactly the "generic list" the milestone warns about.
const COLUMNS := 3

## How long a refusal stays on screen. Longer than the party menu's 2.0s: the one
## message this screen has to deliver is the reason B did not work, and a player
## who just pressed B is looking at the buttons rather than at the panel.
const NOTICE_SECONDS := 3.4

## The newcomer's border and header word.
##
## Amber, and specifically NOT `tether_oxblood` — `ui_style.gd` reserves that for
## Team Tether and says a menu "is the last place it should start leaking from".
## Amber is already the game's colour for "the game is telling you something about
## this", from the build ghost through to every refusal line, and it cannot be
## confused with the green the focus ring uses.
const NEW_MARK := STYLE.WARN

signal ceremony_resolved(released_name: String)

## The farewell, pushed ON TOP of this screen rather than replacing it. A sibling
## under the same stack rather than something instanced on the press, for the
## reason `screen_stack.tscn` gives: instancing a screen at the moment it opens is
## a hitch in the one frame the player is watching for a response.
##
## `screen_stack.gd` exists for this exact push — "the release ceremony is a
## screen that opens over the party list and has to come back to it" — and the six
## stay visible and dimmed underneath, so the farewell reads as being about one of
## them rather than as having thrown them away.
@export var farewell_screen_path: NodePath

## The ceremony object, held as an Object rather than typed.
##
## It lives in `scripts/pals/release_ceremony.gd`, which is another agent's file,
## and every call into it goes through `has_method` first — `party_screen.gd`
## takes the same care with the party for the same reason: a wrong-looking number
## is a bug report, and a crash in the one screen the player cannot leave is the
## evening they lost their party.
var _ceremony: Object = null

var _cards: Array[PanelContainer] = []
var _fills: Array[StyleBoxFlat] = []
var _notice: String = ""
var _notice_left: float = 0.0

@onready var _grid: GridContainer = $Body/Grid
@onready var _detail: PanelContainer = $Body/Detail
@onready var _detail_name: Label = $Body/Detail/Pad/Lines/Who
@onready var _detail_note: RichTextLabel = $Body/Detail/Pad/Lines/Note
@onready var _detail_vitals: RichTextLabel = $Body/Detail/Pad/Lines/Columns/Vitals
@onready var _detail_trait: RichTextLabel = $Body/Detail/Pad/Lines/Columns/Trait
@onready var _detail_notice: RichTextLabel = $Body/Detail/Pad/Lines/Notice


func _ready() -> void:
	# Cards are built BEFORE the base class runs, on purpose and for exactly the
	# reason `party_screen.gd` gives: `screen.gd` walks the whole tree once to
	# outline and shadow every label in it, and a card duplicated after that walk
	# would be the one unreadable thing on the screen.
	_build_cards()
	_detail.add_theme_stylebox_override(
		"panel", STYLE.panel_style(STYLE.ROW_BG, STYLE.PANEL_EDGE)
	)
	super()


## Six cards duplicated from one authored template — the same pattern as the
## party menu's SlotTemplate and the rename grid's CellTemplate. Six hand-written
## copies in the .tscn stay identical for about a week.
func _build_cards() -> void:
	var template := _grid.get_node_or_null(^"CardTemplate") as PanelContainer
	if template == null:
		push_error("release screen has no CardTemplate to duplicate")
		return
	_grid.remove_child(template)

	for i in MAX_CARDS:
		var card := template.duplicate() as PanelContainer
		card.name = "Card%d" % (i + 1)
		card.visible = true
		var fill := STYLE.bar_style(STYLE.HEALTH_FULL)
		STYLE.dress_bar(card.get_node(^"Pad/Lines/Health") as ProgressBar, fill)
		_grid.add_child(card)
		_cards.append(card)
		_fills.append(fill)

	template.queue_free()


# ------------------------------------------------------------------ the ceremony

## Point the screen at a ceremony. Call this BEFORE pushing it.
##
## Not `on_pushed()`, for `rename_screen.open_for`'s reason: `on_pushed()` takes
## no arguments and the stack is never going to grow a way to pass one — it does
## not know what a screen contains, which is why it can hold any of them.
func set_ceremony(ceremony: Object) -> void:
	_ceremony = ceremony
	_notice = ""
	_notice_left = 0.0
	_start_focus()


## Open on the newcomer.
##
## The one card the player has never seen, and the only one that is not yet
## theirs. Starting on slot one would open the screen with the cursor resting on
## the pal they have had longest, which is the worst possible default for a button
## that is about to be irreversible. Nothing is chosen by where the cursor sits —
## the footer names the pal A would say goodbye to, so there is no silent default
## either way.
func _start_focus() -> void:
	var count := focus_count()
	if count <= 0:
		set_focus_index(0)
		return
	var newcomer := _newcomer_index()
	set_focus_index(newcomer if newcomer >= 0 and newcomer < count else count - 1)


func _has(method: String) -> bool:
	return _ceremony != null and _ceremony.has_method(method)


func _candidates() -> Array:
	if not _has("candidates"):
		return []
	var list: Variant = _ceremony.call("candidates")
	return list if list is Array else []


## How many pals the ceremony is presenting, clamped.
##
## Clamped rather than trusted, exactly as `party_screen._capacity()` clamps the
## party's own answer: a ceremony presenting seven has either grown a box or lost
## count, and the screen is not the place to find that out quietly.
func _count() -> int:
	var reported := 0
	if _has("count"):
		reported = int(_ceremony.call("count"))
	elif _has("candidates"):
		reported = _candidates().size()
	if reported > MAX_CARDS:
		push_warning("ceremony presents %d pals; clamping to %d" % [reported, MAX_CARDS])
	return clampi(reported, 0, MAX_CARDS)


func _newcomer_index() -> int:
	if _has("newcomer_index"):
		return int(_ceremony.call("newcomer_index"))
	# The API says the newcomer is LAST. Falling back to that rather than to -1
	# keeps the mark on the right card if the ceremony ever drops the accessor.
	return _count() - 1


func _is_newcomer(index: int) -> bool:
	if _has("is_newcomer"):
		return bool(_ceremony.call("is_newcomer", index))
	var flagged: Variant = _summary(index).get("newcomer")
	if flagged is bool:
		return flagged
	return index == _newcomer_index()


## The pal itself, for the appraisal panel. `summary()` is enough to draw a card;
## it is not enough to draw the appraisal, which is the pal's own to give.
func _at(index: int) -> Object:
	if index < 0 or index >= _count():
		return null
	if _has("at"):
		var pal: Variant = _ceremony.call("at", index)
		if pal is Object:
			return pal
	var list := _candidates()
	if index < list.size() and list[index] is Object:
		return list[index]
	return null


func _summary(index: int) -> Dictionary:
	if not _has("summary") or index < 0 or index >= _count():
		return {}
	var data: Variant = _ceremony.call("summary", index)
	return data if data is Dictionary else {}


## Read a number out of a summary that may not have it, or may have it as a
## string. `CARD.number` does this for objects and the reasoning is identical: a
## missing key comes back null, and `int(null)` is a runtime error in the one
## screen that must not fall over.
static func _figure(source: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = source.get(key)
	if value is int or value is float:
		return float(value)
	return fallback


## Everything one card needs, from the ceremony's summary where it has an answer
## and from the pal itself where it does not.
##
## Both, rather than one or the other. `summary()` is the documented surface and
## is what the ceremony wants drawn; the pal is the fallback that keeps the screen
## honest if a key is missing, and it is the only place a trait's DISPLAY NAME
## comes from — the summary carries `trait_id`, which is a data-file id and not a
## word to put in front of a player.
func _facts(index: int) -> Dictionary:
	var pal := _at(index)
	var summary := _summary(index)

	var pal_name := str(summary.get("name", ""))
	if pal_name == "" or pal_name == "<null>":
		pal_name = CARD.display_of(pal)

	var species := str(summary.get("species", ""))
	if species == "" or species == "<null>":
		species = CARD.species_of(pal)

	var trait_name := ""
	if pal != null:
		trait_name = CARD.trait_of(pal)
	else:
		var id := str(summary.get("trait_id", ""))
		trait_name = CARD.humanise(id) if id != "" and id != "<null>" else "no trait"

	return {
		"name": pal_name,
		"species": species,
		"level": int(_figure(summary, "level", CARD.number(pal, "level", 1.0))),
		"hp": _figure(summary, "hp", CARD.number(pal, "hp", 0.0)),
		"max_hp": maxf(1.0, _figure(summary, "max_hp", CARD.number(pal, "max_hp", 1.0))),
		"trait": trait_name,
		"newcomer": _is_newcomer(index),
		"down": CARD.is_down(pal),
	}


# --------------------------------------------------------------------- drawing

func screen_title() -> String:
	var count := _count()
	if count <= 0:
		return "Release ceremony"
	# States the arithmetic in the title, because it is the whole situation and a
	# player who opened this screen by accident — they cannot have, but still —
	# should not have to infer it from a grid.
	return "Six pals.  You may keep five."


func focus_count() -> int:
	return _count()


func hints() -> Array[Array]:
	var count := _count()
	var index := focus_index()
	var rows: Array[Array] = []
	rows.append(["Up/Down/Left/Right", "Look at each", count > 1])
	if count <= 0:
		rows.append(["A", "Nothing to choose", false])
	else:
		# NAMES THE PAL, like the rename grid names the key under the cursor. "A
		# Select" on a screen where A is irreversible is the least informative word
		# available, and the footer is the only place a screenshot can tell you what
		# the press would have done.
		rows.append(["A", "Say goodbye to %s" % str(_facts(index).get("name", "this one")),
			_farewell_screen() != null])
	# DRAWN AND DIMMED, never hidden. `ui_style.gd`: "a widget that vanishes reads
	# as broken, one that changes reads as an answer." B is a button the player will
	# press; the footer says in advance that it will not take them anywhere, and
	# pressing it says why.
	rows.append(["B", "No way past this", false])
	return rows


func refresh() -> void:
	_notice_left = maxf(0.0, _notice_left - get_process_delta_time())
	if _notice_left <= 0.0:
		_notice = ""

	var count := _count()
	# The cursor can outlive the card it was on — a ceremony that resolves while
	# the screen is still drawing its last frame.
	if count > 0 and focus_index() >= count:
		set_focus_index(count - 1)

	for i in _cards.size():
		var card := _cards[i]
		card.visible = i < count
		if card.visible:
			_draw_card(i, card, _facts(i))

	_draw_detail(count)


func _draw_card(index: int, card: PanelContainer, facts: Dictionary) -> void:
	var focused := index == focus_index()
	var newcomer: bool = bool(facts.get("newcomer", false))
	var tag := card.get_node(^"Pad/Lines/Tag") as Label
	var head_name := card.get_node(^"Pad/Lines/Head/Name") as Label
	var head_level := card.get_node(^"Pad/Lines/Head/Level") as Label
	var health := card.get_node(^"Pad/Lines/Health") as ProgressBar
	var trait_label := card.get_node(^"Pad/Lines/Foot/Trait") as Label
	var vitals := card.get_node(^"Pad/Lines/Foot/Vitals") as Label

	# The newcomer keeps its amber edge even when focused, and the focus fill goes
	# underneath it. Two facts, two channels: the border says which one is the
	# stranger, the fill says which one you are looking at, and neither has to be
	# given up to show the other.
	var edge: Color = Color.html(NEW_MARK) if newcomer else (
		STYLE.ROW_FOCUS_EDGE if focused else STYLE.PANEL_EDGE
	)
	card.add_theme_stylebox_override("panel", STYLE.panel_style(
		STYLE.ROW_FOCUS_BG if focused else STYLE.ROW_BG, edge
	))

	# ITS OWN HEADER WORD. Every card carries the line, so the newcomer's is a
	# different answer rather than an extra thing — a label that only one card has
	# reads as an annotation; a label every card has reads as a fact about all of
	# them, which is what "five of these are yours and one is not" is.
	if newcomer:
		tag.text = "just caught  —  not yours yet"
		tag.modulate = Color.html(NEW_MARK)
	else:
		tag.text = "one of your five"
		tag.modulate = Color.html(STYLE.INK_DIM)

	head_name.text = str(facts.get("name", "?"))
	head_name.modulate = (
		Color(0.70, 0.62, 0.60) if bool(facts.get("down", false)) else Color.WHITE
	)
	head_level.text = "Lv %d" % int(facts.get("level", 1))

	var hp := float(facts.get("hp", 0.0))
	var max_hp := maxf(1.0, float(facts.get("max_hp", 1.0)))
	var fraction := clampf(hp / max_hp, 0.0, 1.0)
	health.value = fraction * 100.0
	_fills[index].bg_color = STYLE.HEALTH_LOW.lerp(STYLE.HEALTH_FULL, fraction)

	trait_label.text = str(facts.get("trait", "no trait"))
	vitals.text = "%d / %d HP" % [roundi(hp), roundi(max_hp)]


## The focused card, at length: species, level, health, appraisal, trait and what
## the trait does.
##
## Below the six rather than beside them, because the six are the comparison and
## a detail column would have squeezed them to a third of the width. `pal_card.gd`
## writes the paragraph, so this is the same appraisal, in the same words, that
## the player has been reading in the party menu since M4 — the one screen where
## a differently-worded second opinion would be actively harmful.
##
## IN TWO COLUMNS, and that is the fix for a measured clip rather than a taste.
## Written as one column this panel drew six of the thirteen lines the worst-case
## pal produces and dropped Attack, Defence, the trait, its description and the xp
## line off the bottom — the appraisal was computed, logged and then not shown,
## which fails M5's "inspect meaningful info" directly. Splitting what the pal IS
## from what it CARRIES roughly halves the height and spends width the panel
## already had. See `pal_card.vitals_column` for where the seam is.
func _draw_detail(count: int) -> void:
	if count <= 0:
		# Honest about which failure this is. An empty ceremony is a wiring fault,
		# not a decision, and `cancel()` lets the player out of it.
		_detail_name.text = "Nobody to present"
		# Full width, not a column: this is prose about the screen rather than facts
		# about a pal, and there is no second half of it to put beside it.
		_write(_detail_note, (
			"[color=#%s]This screen was opened without a release ceremony to run. "
			% STYLE.INK_DIM
			+ "It is handed the six through [b]set_ceremony()[/b] before it is pushed. "
			+ "Nothing has been released and nothing has been lost.[/color]"
		))
		_write(_detail_vitals, "")
		_write(_detail_trait, "")
		_draw_notice()
		return

	var index := focus_index()
	var facts := _facts(index)
	var pal := _at(index)
	_detail_name.text = str(facts.get("name", "?"))

	# The newcomer's sentence sits above both columns. It is a fact about the whole
	# card and not about either half of it, and at full width it is one line rather
	# than the two it wraps to inside a column.
	if bool(facts.get("newcomer", false)):
		_write(_detail_note, "[color=#%s]%s[/color]" % [
			NEW_MARK,
			"The one you just caught. It is not part of your five until you make room for it.",
		])
	else:
		_write(_detail_note, "")

	if pal == null:
		# Everything the summary knew, when the pal itself is out of reach. A card
		# with no appraisal is still a card the player can choose between, and it is
		# still laid out in the same two columns so the panel does not change shape
		# as the cursor passes over it.
		var left: Array[String] = []
		var species := str(facts.get("species", ""))
		if species != "":
			left.append("[color=#%s]%s[/color]" % [STYLE.INK_DIM, species])
		left.append("[b]Level %d[/b]        %d / %d HP" % [
			int(facts.get("level", 1)),
			roundi(float(facts.get("hp", 0.0))),
			roundi(float(facts.get("max_hp", 1.0))),
		])
		_write(_detail_vitals, "\n".join(left))
		_write(_detail_trait, "[color=#%s]Trait  [b]%s[/b][/color]" % [
			STYLE.INK_DIM, str(facts.get("trait", "no trait"))
		])
	else:
		_write(_detail_vitals, "\n".join(CARD.vitals_column(pal)))
		_write(_detail_trait, "\n".join(CARD.trait_column(pal)))
	_draw_notice()


## A refusal, on its own full-width line under the columns.
##
## Its own label rather than appended to the appraisal text, which is what it used
## to be: appended, the answer to "why did B not work" arrived at the bottom of
## the one panel on the screen that was already overflowing, so the single message
## this screen exists to deliver was the message it could not show. On its own row
## it cannot push anything off, because `fit_content` makes it zero-height on
## every frame there is nothing to say.
func _draw_notice() -> void:
	if _notice == "":
		_write(_detail_notice, "")
		return
	_write(_detail_notice, "[color=#%s]%s[/color]" % [STYLE.WARN, _notice])


## Assign only on a change.
##
## A RichTextLabel re-parses its bbcode on every write to `text`, and this panel
## is redrawn every frame from a pal that changes on almost none of them —
## `screen.gd` compares its title and footer before assigning for the same reason.
static func _write(label: RichTextLabel, wanted: String) -> void:
	if label.text != wanted:
		label.text = wanted


# --------------------------------------------------------------------- the grid

## Two rows of three, moved with one cursor.
##
## `screen.gd` moves a single index on `dy` and hands `dx` to `on_nudge`, which is
## right for a list and wrong for a grid — left and right here are movement, not a
## value being changed. The base's index is still what moves, so `confirm()` and
## `on_activate()` arrive exactly as `screen.gd` documents them and nothing
## downstream has to know this screen is special.
##
## Both axes WRAP, for the reason `screen.gd` gives about the party list: a
## selection that stops dead at the edge reads as the stick having disconnected.
## Wrapping through `posmod` over the LIVE count is also what makes this safe with
## fewer than six candidates — there is no arithmetic here that can land on a card
## that has no pal behind it.
##
## The stack drops diagonals before they get here, so only one of these runs per
## step.
func navigate(dx: int, dy: int) -> void:
	var count := focus_count()
	if count <= 0:
		return
	var index := focus_index()
	if dy != 0:
		index = posmod(index + dy * COLUMNS, count)
	if dx != 0:
		index = posmod(index + dx, count)
	set_focus_index(index)


# ------------------------------------------------------------------- the verbs

## A chooses; it does not release.
##
## `choose()` records which of the six the player is considering and the farewell
## screen is where the irreversible press lives, two screens and two buttons away
## from a stick that was already moving. Nothing here calls `resolve()`.
func on_activate(index: int) -> void:
	if _count() <= 0:
		_say("there is nobody here to choose between")
		return
	if index < 0 or index >= _count():
		_say("that card is empty")
		return
	var farewell := _farewell_screen()
	if farewell == null:
		# Named as wiring rather than as a refusal the player caused, the same
		# distinction the party menu draws for a missing rename screen.
		_say("no farewell screen is wired to this ceremony")
		return
	var stack := get_parent()
	if stack == null or not stack.has_method("push"):
		_say("there is nowhere to open the farewell")
		return
	if not _has("choose"):
		_say("this ceremony cannot be decided")
		return
	if not bool(_ceremony.call("choose", index)):
		_say(_refusal_words(_last_refusal()))
		return

	# Subject first, then push — `rename_screen.open_for` again. The farewell needs
	# the ceremony to resolve it, and the stack has no way to carry an argument.
	farewell.call("set_ceremony", _ceremony)
	if farewell.has_signal("farewell_finished") and not farewell.is_connected(
		"farewell_finished", _on_farewell_finished
	):
		farewell.connect("farewell_finished", _on_farewell_finished)
	stack.call("push", farewell)


## B is not a way out, and this is the whole design rather than an oversight.
##
## `party.gd`: there is no overflow anywhere, not even a private one, because the
## moment a sixth pal can sit somewhere while the player thinks about it, the
## ceremony stops being the only way to resolve a full party. Backing out of this
## screen would BE that somewhere. So B answers in the pal's own terms and the
## screen stays exactly where it was.
##
## The exception is a ceremony that has nothing to decide. Returning true there
## would trap the player in a screen that cannot do anything at all, which turns a
## missing NodePath into a lost evening; `screen.gd`'s contract is that false lets
## the stack pop.
func cancel() -> bool:
	if _count() <= 0:
		return false
	# Capitalised. It read as a truncated fragment mid-sentence, which is the last
	# thing this line should look like — it is the screen's answer to the player
	# asking to leave, not a footnote.
	_say("There is nowhere to put a sixth — no box, no storage, nothing waiting "
		+ "outside. One of these six goes back to the meadow before you do.")
	return true


func on_pushed() -> void:
	_notice = ""
	_notice_left = 0.0
	_start_focus()


## Which pal the screen is currently describing, by name.
##
## `focus_index()` on the base class already says WHICH SLOT has the cursor. This
## says which creature that is, and it exists because of what the M5 evidence
## could not do without it: every statement in that transcript about what was
## selected was read out of the hint line the screen itself renders — "[A] Say
## goodbye to Thistle". That is the screen agreeing with itself. A reviewer
## rightly counted it as no independent evidence of selection at all.
func focused_name() -> String:
	var index := focus_index()
	if index < 0 or index >= _count():
		return ""
	return str(_facts(index).get("name", ""))


func _farewell_screen() -> Control:
	var node := get_node_or_null(farewell_screen_path) as Control
	if node == null or not node.has_method("set_ceremony"):
		return null
	return node


func _on_farewell_finished(released_name: String) -> void:
	ceremony_resolved.emit(released_name)
	# The farewell has already taken itself off the stack by the time this arrives,
	# so this screen is the top one and its own pop is the last of the ceremony.
	# Checked rather than assumed: popping a screen somebody else pushed on top of
	# us would take their screen down with it.
	var stack := get_parent()
	if stack == null or not stack.has_method("pop"):
		return
	if stack.has_method("top") and stack.call("top") != self:
		return
	stack.call("pop")


func _last_refusal() -> String:
	if not _has("last_refusal"):
		return ""
	return str(_ceremony.call("last_refusal"))


## A refusal token, in player voice.
##
## The tokens belong to `release_ceremony.gd`, which refuses with machine words
## the way `party.gd` does — `no_such_member`, `party_full` — and its own header
## says why: "The party has no business knowing how a refusal is worded." Putting
## one on screen unchanged is the mistake `combat_hud` had to undo twice. An
## unrecognised token falls back to a general line rather than being printed,
## because a token nobody has translated yet is still a token.
func _refusal_words(token: String) -> String:
	match token:
		"already_resolved":
			return "this has already been decided"
		"no_choice", "nothing_chosen":
			return "nothing is picked yet"
		"no_such_member", "out_of_range":
			return "there is no pal on that card"
		"not_a_pal":
			return "that is not a creature you can let go"
		_:
			return "that one cannot be chosen right now"


func _say(message: String) -> void:
	_notice = message
	_notice_left = NOTICE_SECONDS
