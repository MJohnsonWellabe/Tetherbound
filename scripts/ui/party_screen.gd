extends "res://scripts/ui/screen.gd"

## The party: five slots, who is out, and what each one is worth.
##
## Reads the party and draws it. Owns no state of its own except which row the
## cursor is on. Everything else is pulled from the party node every frame rather
## than cached on a signal, for `combat_hud.gd`'s reason: a menu that keeps its
## own copy of the party is a menu that can disagree with the party, and the
## first time that happens is the first time somebody catches a pal with the
## screen open.
##
## FIVE is not a tunable here. `CLAUDE.md`: "Player can own only five pals total.
## Never implement pal storage beyond five." The screen asks the party for its
## capacity and then clamps it, so a party that one day reports six gets five
## slots and a warning rather than a sixth row that quietly implements storage.
##
## The party may not exist. This screen is loaded into test scenes before the
## party node is, and it renders an honest five empty slots in that case instead
## of erroring — an empty party and a missing party look different, and both look
## deliberate.

# STYLE is inherited from screen.gd. Declaring it again here is a parse error,
# which is the language making the same point this file would have: there is one
# set of UI colours and one text treatment.

const MAX_SLOTS := 5

## How long a refusal stays on screen. Long enough to read, short enough that it
## does not still be there when you have moved on. Tunable.
const NOTICE_SECONDS := 2.0

## The words for an overall appraisal, worst to best.
##
## Words rather than a number, because GAME_DESIGN.md §11 says appraisal is shown
## "through stars/bars, not exact IV numbers", and because "Promising" is
## something you can feel about a creature in a way that 0.62 is not.
const VERDICTS := ["Poor", "Ordinary", "Promising", "Excellent", "Exceptional"]

## Keys whose display name is not just the key capitalised.
const KEY_NAMES := {
	"hp": "HP",
	"max_hp": "HP",
	"atk": "Attack",
	"attack": "Attack",
	"def": "Defence",
	"defence": "Defence",
	"defense": "Defence",
	"iv": "Quality",
	"overall": "Overall",
}

## Keys that are the appraisal's own summary rather than one of its rows. If the
## data layer supplies one of these as a String, it is used verbatim as the
## verdict and is not repeated in the list below it.
const SUMMARY_KEYS := ["summary", "grade", "verdict"]

@export var party_path: NodePath

var _rows: Array[PanelContainer] = []
var _fills: Array[StyleBoxFlat] = []
var _template: PanelContainer = null
var _notice: String = ""
var _notice_left: float = 0.0

@onready var _slots: VBoxContainer = $Body/Slots
@onready var _detail: PanelContainer = $Body/Detail
@onready var _detail_name: Label = $Body/Detail/Pad/Lines/Who
@onready var _detail_body: RichTextLabel = $Body/Detail/Pad/Lines/Appraisal


func _ready() -> void:
	# Rows are built BEFORE the base class runs, on purpose. `screen.gd` walks the
	# whole tree once to outline and shadow every label in it; a row duplicated
	# after that walk would be the one unreadable thing on the screen, and it
	# would be unreadable in exactly the way the walk exists to prevent.
	_build_rows()
	_detail.add_theme_stylebox_override(
		"panel", STYLE.panel_style(STYLE.ROW_BG, STYLE.PANEL_EDGE)
	)
	super()


## Five rows duplicated from one authored template.
##
## The alternative was five hand-written copies in the .tscn. They stay identical
## for about a week. One template also means the row layout is a thing you can
## change once, which matters because the release ceremony is going to want to
## draw the same row.
func _build_rows() -> void:
	_template = _slots.get_node_or_null(^"SlotTemplate") as PanelContainer
	if _template == null:
		push_error("party screen has no SlotTemplate row to duplicate")
		return
	_slots.remove_child(_template)

	for i in MAX_SLOTS:
		var row := _template.duplicate() as PanelContainer
		row.name = "Slot%d" % (i + 1)
		row.visible = true
		var fill := STYLE.bar_style(STYLE.HEALTH_FULL)
		STYLE.dress_bar(row.get_node(^"Pad/Lines/Health") as ProgressBar, fill)
		_slots.add_child(row)
		_rows.append(row)
		_fills.append(fill)


# ------------------------------------------------------------------ the party

## The party node, or null if it is not there yet.
##
## Checked by method rather than by class, because the party is another agent's
## file and this screen should keep working if it grows a base class.
func _party() -> Node:
	var node := get_node_or_null(party_path)
	if node == null or not node.has_method("members"):
		return null
	return node


## One snapshot per frame, rather than `at(index)` five times.
##
## `at()` exists and would work, but five separate reads down one list is five
## chances to draw half of one party and half of another if something changes
## mid-frame. One array cannot do that.
func _members() -> Array:
	var party := _party()
	if party == null:
		return []
	var list: Variant = party.call("members")
	return list if list is Array else []


func _capacity() -> int:
	var party := _party()
	if party == null:
		return MAX_SLOTS
	if not party.has_method("capacity"):
		return MAX_SLOTS
	var reported := int(party.call("capacity"))
	if reported > MAX_SLOTS:
		# Loud, once you look. CLAUDE.md forbids owning more than five, and a
		# party that reports more has either grown storage or broken its own
		# rule; either way the screen is not the place to find out quietly.
		push_warning("party reports capacity %d; clamping to %d" % [reported, MAX_SLOTS])
	return clampi(reported, 1, MAX_SLOTS)


func _active_index() -> int:
	var party := _party()
	if party == null:
		return -1
	return int(_number(party, "active_index", -1.0))


## Read a number off something that may not have it.
##
## Every property this screen reads belongs to another agent's file. A missing
## one comes back as null, and `int(null)` and `float(null)` are runtime errors —
## which would take a party menu that is 95% correct and turn it into a red
## screen. A wrong-looking number is a bug report; a crash in a menu is an
## evening.
static func _number(target: Object, key: String, fallback: float) -> float:
	if target == null:
		return fallback
	var value: Variant = target.get(key)
	if value is int or value is float:
		return float(value)
	return fallback


# ------------------------------------------------------------------- drawing

func screen_title() -> String:
	if _party() == null:
		return "Party"
	return "Party    %d / %d" % [_members().size(), _capacity()]


func hints() -> Array[Array]:
	var members := _members()
	var index := focus_index()
	var filled: bool = index < members.size() and members[index] != null
	var can_send: bool = filled and index != _active_index() and not _is_down(members[index])
	var rows: Array[Array] = []
	rows.append(["↕", "Choose", true])
	rows.append(["A", "Send out", can_send])
	rows.append(["B", "Back", true])
	return rows


func focus_count() -> int:
	return _capacity()


func refresh() -> void:
	_notice_left = maxf(0.0, _notice_left - get_process_delta_time())
	if _notice_left <= 0.0:
		_notice = ""

	var members := _members()
	var capacity := _capacity()
	# The cursor can outlive the row it was on — releasing a pal, or a party that
	# reports a smaller capacity than it did last frame.
	if focus_index() >= capacity:
		set_focus_index(capacity - 1)

	for i in _rows.size():
		var row := _rows[i]
		row.visible = i < capacity
		if not row.visible:
			continue
		var member: Object = members[i] if i < members.size() else null
		_draw_row(i, row, member)

	_draw_detail(members[focus_index()] if focus_index() < members.size() else null)


func _draw_row(index: int, row: PanelContainer, member: Object) -> void:
	var focused := index == focus_index()
	var head_name := row.get_node(^"Pad/Lines/Head/Name") as Label
	var head_level := row.get_node(^"Pad/Lines/Head/Level") as Label
	var health := row.get_node(^"Pad/Lines/Health") as ProgressBar
	var trait_label := row.get_node(^"Pad/Lines/Foot/Trait") as Label
	var state := row.get_node(^"Pad/Lines/Foot/State") as Label

	if member == null:
		# An empty slot reads as EMPTY, not as missing. The row keeps its height,
		# its border and its number, and says so in words — the same lesson the
		# cooldown verb taught: a widget that vanishes reads as broken, one that
		# changes reads as an answer.
		row.add_theme_stylebox_override("panel", STYLE.panel_style(
			STYLE.ROW_FOCUS_BG if focused else STYLE.ROW_EMPTY_BG,
			STYLE.ROW_FOCUS_EDGE if focused else STYLE.ROW_EMPTY_EDGE
		))
		head_name.text = "Slot %d — empty" % (index + 1)
		head_name.modulate = Color(0.62, 0.64, 0.60)
		head_level.text = ""
		health.value = 0.0
		health.modulate = Color(1.0, 1.0, 1.0, 0.25)
		trait_label.text = "room for one more"
		state.text = ""
		return

	row.add_theme_stylebox_override("panel", STYLE.panel_style(
		STYLE.ROW_FOCUS_BG if focused else STYLE.ROW_BG,
		STYLE.ROW_FOCUS_EDGE if focused else STYLE.PANEL_EDGE
	))
	head_name.text = _display_of(member)
	head_name.modulate = Color(1.0, 1.0, 1.0) if not _is_down(member) else Color(0.70, 0.62, 0.60)
	head_level.text = "Lv %d" % int(_number(member, "level", 1.0))

	var hp := _number(member, "hp", 0.0)
	var max_hp := maxf(1.0, _number(member, "max_hp", 1.0))
	var fraction := clampf(hp / max_hp, 0.0, 1.0)
	health.value = fraction * 100.0
	health.modulate = Color.WHITE
	_fills[index].bg_color = STYLE.HEALTH_LOW.lerp(STYLE.HEALTH_FULL, fraction)
	trait_label.text = "%s        %d / %d HP" % [_trait_of(member), roundi(hp), roundi(max_hp)]

	# Both states are drawn. "Reserve" is not the absence of "active"; it is a
	# thing the pal is doing, and a blank where the other row has a word reads as
	# a label that failed to load.
	if _is_down(member):
		state.text = "✕  down"
		state.modulate = Color(0.85, 0.42, 0.36)
	elif index == _active_index():
		state.text = "◆  out with you"
		state.modulate = Color(0.56, 0.84, 0.42)
	else:
		state.text = "·  in reserve"
		state.modulate = Color(0.58, 0.60, 0.55)


func _draw_detail(member: Object) -> void:
	if _party() == null:
		_detail_name.text = "No party"
		_detail_body.text = (
			"[color=#%s]There is no party to read yet.\n\n" % STYLE.INK_DIM
			+ "This screen is pointed at a party node through its "
			+ "[b]party_path[/b] and nothing is there. That is expected before "
			+ "the party exists; it is a wiring mistake afterwards.[/color]"
		)
		return

	if member == null:
		_detail_name.text = "Empty slot"
		_detail_body.text = "[color=#%s]%s[/color]" % [
			STYLE.INK_DIM,
			"Nothing here yet. Catch a pal and it takes the first free slot.\n\n"
			+ "Five is the whole party — there is no box, no storage and no "
			+ "sixth slot. When a sixth pal is caught you choose which five you "
			+ "keep."
		]
		_append_notice()
		return

	_detail_name.text = _display_of(member)
	var lines: Array[String] = []
	var species := str(member.get("species_id"))
	var display := _display_of(member)
	# Only worth saying when the nickname hides it. "Meadow Hopper (meadow
	# hopper)" is noise.
	if species != "" and species != "<null>" and not display.to_lower().contains(species.replace("_", " ")):
		lines.append("[color=#%s]%s[/color]" % [STYLE.INK_DIM, _humanise(species)])
	lines.append("[b]Level %d[/b]        %d / %d HP" % [
		int(_number(member, "level", 1.0)),
		roundi(_number(member, "hp", 0.0)),
		roundi(_number(member, "max_hp", 1.0)),
	])
	lines.append("[color=#%s]Trait[/color]  %s" % [STYLE.INK_DIM, _trait_of(member)])
	lines.append("")
	lines.append_array(_appraisal_lines(member))
	_detail_body.text = "\n".join(lines)
	_append_notice()


func _append_notice() -> void:
	if _notice == "":
		return
	_detail_body.text += "\n\n[color=#%s]%s[/color]" % [STYLE.WARN, _notice]


# ----------------------------------------------------------------- appraisal

## The appraisal, as a verdict and a short list of bars.
##
## The data layer decides what an appraisal contains; this only decides how to
## say it. That split is deliberate — what makes a pal good is a design question
## that belongs in `scripts/pals/`, and a screen that hard-codes the four stats
## it knows about is a screen that silently drops the fifth.
func _appraisal_lines(member: Object) -> Array[String]:
	if not member.has_method("appraisal"):
		return ["[color=#%s]No appraisal available for this one.[/color]" % STYLE.INK_DIM]
	var data: Variant = member.call("appraisal")
	if not data is Dictionary or (data as Dictionary).is_empty():
		return ["[color=#%s]Not appraised yet.[/color]" % STYLE.INK_DIM]

	var appraisal: Dictionary = data
	var rows: Array[String] = []
	var scores: Array[float] = []
	var summary := ""

	for key: Variant in appraisal.keys():
		var name := str(key)
		# `_comment` and friends. `palette.json` and `species.json` both carry
		# keys like that and there is no reason an appraisal would not.
		if name.begins_with("_"):
			continue
		var value: Variant = appraisal[key]
		if SUMMARY_KEYS.has(name) and value is String:
			summary = str(value)
			continue
		var fraction := _as_fraction(value)
		if is_nan(fraction):
			rows.append("[color=#%s]%s[/color]  %s" % [STYLE.INK_DIM, _label_for(name), _as_text(value)])
			continue
		scores.append(fraction)
		rows.append("[color=#%s]%s[/color]  %s" % [
			STYLE.INK_DIM, _label_for(name), STYLE.stars(fraction)
		])

	var lines: Array[String] = []
	if summary == "" and not scores.is_empty():
		var total := 0.0
		for score in scores:
			total += score
		summary = _verdict(total / float(scores.size()))
	if summary != "":
		lines.append("[color=#%s]Appraisal[/color]  [b]%s[/b]" % [STYLE.INK_DIM, summary])
	else:
		lines.append("[color=#%s]Appraisal[/color]" % STYLE.INK_DIM)
	lines.append_array(rows)
	return lines


func _verdict(fraction: float) -> String:
	var index := clampi(int(clampf(fraction, 0.0, 0.999) * float(VERDICTS.size())), 0, VERDICTS.size() - 1)
	return VERDICTS[index]


## A number turned into a 0-1 rating, or NAN if it plainly is not one.
##
## TWO conventions are accepted and they are told apart by TYPE, not by value: a
## float is read as a 0-1 fraction, an int as a count of stars out of five. That
## is the only way to tell `1` meaning "one star" from `1.0` meaning "perfect",
## and it is a genuine trap — if the party ever hands back `{"attack": 1}` meaning
## a perfect roll, this will draw one star and be confidently wrong. The fix, if
## it comes up, belongs on the data side: appraisals should be floats in 0-1.
func _as_fraction(value: Variant) -> float:
	if value is float:
		var number: float = value
		return number if number >= 0.0 and number <= 1.0 else NAN
	if value is int:
		var count: int = value
		return float(count) / float(STYLE.STARS) if count >= 0 and count <= STYLE.STARS else NAN
	return NAN


func _as_text(value: Variant) -> String:
	if value is bool:
		return "yes" if value else "no"
	if value is float:
		return "%.1f" % (value as float)
	if value is Array:
		var parts: Array[String] = []
		for entry: Variant in value:
			parts.append(str(entry))
		return ", ".join(parts)
	return str(value)


func _label_for(key: String) -> String:
	return str(KEY_NAMES.get(key, _humanise(key)))


func _humanise(id: String) -> String:
	return id.replace("_", " ").capitalize()


# ------------------------------------------------------------------- members

## The name to show. `display()` is the party's own answer to "nickname if set,
## else species name" and this screen does not second-guess it — a menu that
## re-derived the name would be the place a nickname stopped showing up.
func _display_of(member: Object) -> String:
	if member.has_method("display"):
		return str(member.call("display"))
	var fallback := str(member.get("display_name"))
	return fallback if fallback != "" and fallback != "<null>" else "?"


## The trait, in words.
##
## `trait_id` is an id — `sturdy`, `quick_footed` — and there is no trait
## catalogue on the data side yet (`data/traits/` is empty). Until there is, this
## humanises the id, which is right often enough to be useful and wrong in a way
## that is obvious. If the party grows a `trait_name()` it is used instead, so
## the fix on that side needs no change on this one.
func _trait_of(member: Object) -> String:
	if member.has_method("trait_name"):
		var named := str(member.call("trait_name"))
		if named != "":
			return named
	var id := str(member.get("trait_id"))
	if id == "" or id == "<null>":
		return "no trait"
	return _humanise(id)


func _is_down(member: Object) -> bool:
	if member == null:
		return false
	if member.get("fainted") == true:
		return true
	return _number(member, "hp", 1.0) <= 0.0


# ------------------------------------------------------------------- actions

func on_activate(index: int) -> void:
	var party := _party()
	if party == null:
		_say("there is no party to change")
		return
	var members := _members()
	if index >= members.size() or members[index] == null:
		_say("that slot is empty")
		return
	if _is_down(members[index]):
		# Refused with a reason rather than silently ignored, for
		# `combat_hud._on_catch_refused`'s reason: "I pressed it and nothing
		# happened" is indistinguishable from a bug.
		_say("%s is out of the fight" % _display_of(members[index]))
		return
	if index == _active_index():
		_say("%s is already out with you" % _display_of(members[index]))
		return
	if not party.has_method("set_active"):
		_say("this party cannot switch")
		return
	party.call("set_active", index)


func on_pushed() -> void:
	# Open on whoever is out. The pal you are looking at is almost always the one
	# you were just fighting with, and starting the cursor at slot one means
	# scrolling back to it every time.
	var active := _active_index()
	if active >= 0:
		set_focus_index(active)
	_notice = ""
	_notice_left = 0.0


func _say(message: String) -> void:
	_notice = message
	_notice_left = NOTICE_SECONDS
