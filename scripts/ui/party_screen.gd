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

## What a trait is CALLED. Read-only, and one direction only — the UI may ask the
## data layer to name a trait; the data layer must never ask the UI anything.
const TRAITS := preload("res://scripts/pals/pal_traits.gd")

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
	# The SPECIES name, and only when a nickname is hiding it. `display_name` is
	# the species' own name — "Bramblit" — where `species_id` is `starter_ground`,
	# an id that belongs in a data file and not on a screen. Showing it under a
	# pal that has no nickname would also just repeat the heading.
	var species_name := str(member.get("display_name"))
	if species_name != "" and species_name != "<null>" and species_name != _display_of(member):
		lines.append("[color=#%s]%s[/color]" % [STYLE.INK_DIM, species_name])
	lines.append("[b]Level %d[/b]        %d / %d HP" % [
		int(_number(member, "level", 1.0)),
		roundi(_number(member, "hp", 0.0)),
		roundi(_number(member, "max_hp", 1.0)),
	])
	# The trait is NOT repeated here — `_appraisal_lines` states it once, with the
	# description that says what it does. It was in both places and read as the
	# screen stuttering.
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
	var lines: Array[String] = []

	# The overall verdict, from the appraisal's own rating rather than from an
	# average this screen computes. The data layer decides what a pal is worth;
	# this only decides how to say it.
	var max_stars := maxi(1, int(appraisal.get("max_stars", STYLE.STARS)))
	var overall := int(appraisal.get("stars", 0))
	lines.append("[color=#%s]Appraisal[/color]  [b]%s[/b]   %s" % [
		STYLE.INK_DIM,
		_verdict(overall, max_stars),
		STYLE.star_row(overall, max_stars),
	])

	# Per stat, compared against the species baseline at this level.
	var stats: Variant = appraisal.get("stats")
	if stats is Dictionary:
		for name: String in (stats as Dictionary).keys():
			var entry: Variant = (stats as Dictionary)[name]
			if not entry is Dictionary:
				continue
			var stat: Dictionary = entry
			# The star row and the pal's actual stat, never the ratio behind them.
			# `data/config/party.json` is explicit: "the UI is expected to draw the
			# stars and may draw the bars, but must not print the ratios." The
			# value is what this pal's attack IS; the ratio is the IV read-out
			# GAME_DESIGN.md §11 says not to build.
			lines.append("[color=#%s]%s[/color]  %s   [color=#%s]%d[/color]" % [
				STYLE.INK_DIM,
				_label_for(name),
				STYLE.star_row(int(stat.get("stars", 0)), max_stars),
				STYLE.INK_DIM,
				roundi(float(stat.get("value", 0.0))),
			])

	# Progress toward the next level, as a sentence rather than as stars — it is
	# a count, and the first version of this screen rendered `xp: 0` as an empty
	# five-star rating because it treated every integer in the appraisal as a
	# score. A generic renderer over a structured payload will always find a
	# number it can misread.
	# The trait, with what it actually DOES. The name on its own is a word the
	# player has to take on trust, and the description is the single line that
	# makes one pal worth keeping over another — which is the whole question M5's
	# release ceremony asks. The data layer already wrote it; not showing it was
	# throwing away the only prose in the payload.
	var trait_entry: Variant = appraisal.get("trait")
	var trait_dict: Dictionary = trait_entry if trait_entry is Dictionary else {}
	var trait_name := str(trait_dict.get("display_name", ""))
	# Falls back to the row's own answer rather than to nothing. Every pal has a
	# trait (§11: "Each pal starts with one trait"), so a blank where the name
	# should be is a data fault, and saying the id out loud is how somebody finds
	# it.
	if trait_name == "":
		trait_name = _trait_of(member)
	lines.append("")
	lines.append("[color=#%s]Trait[/color]  [b]%s[/b]" % [STYLE.INK_DIM, trait_name])
	var description := str(trait_dict.get("description", ""))
	if description != "":
		lines.append("[color=#%s]%s[/color]" % [STYLE.INK_DIM, description])

	var xp := int(appraisal.get("xp", 0))
	var needed := int(appraisal.get("xp_for_next_level", 0))
	if needed > 0:
		lines.append("")
		lines.append("[color=#%s]Next level in %d xp[/color]" % [STYLE.INK_DIM, maxi(needed - xp, 0)])
	return lines


## A word for a star count.
##
## Mapped from the COUNT, not from a fraction of it. Dividing by `max_stars` and
## banding the result put "Poor" and "Excellent" out of reach entirely and made a
## four-star pal read identically to a perfect one — which is exactly backwards
## for a screen whose job is to help somebody decide which pal to release.
##
## Five words over however many stars the data uses, so a `party.json` that moves
## `max_stars` moves the words with it rather than pinning "Exceptional" to a five
## that no longer exists.
func _verdict(stars: int, total: int) -> String:
	var last := VERDICTS.size() - 1
	if total <= 1:
		return VERDICTS[last]
	var position := float(clampi(stars, 1, total) - 1) / float(total - 1)
	return VERDICTS[clampi(int(position * float(last) + 0.5), 0, last)]


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


## The trait, in words, for a slot row.
##
## Asks the trait table directly rather than humanising `trait_id`, so the row and
## the appraisal panel beside it cannot end up calling the same trait two
## different things. `pal_traits.gd` caches its table in a static, so five lookups
## a frame is five dictionary reads.
##
## Reading from `scripts/pals/` is one-way and stays that way: the UI may ask the
## data layer what a trait is called, and the data layer must never ask the UI
## anything. The humanised id survives as the fallback for a trait that is in a
## pal but not in the table, which is a data bug that should still leave a
## readable screen.
func _trait_of(member: Object) -> String:
	var id := str(member.get("trait_id"))
	if id == "" or id == "<null>":
		return "no trait"
	if TRAITS.has(id):
		var named := str(TRAITS.display_name(id))
		if named != "":
			return named
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

	# The checks above catch the refusals this screen can EXPLAIN — empty, down,
	# already out. `set_active` can still say no for a reason this file has never
	# heard of, and swallowing that would put the press back in the "nothing
	# happened" category that every refusal message here exists to keep it out of.
	# `party_manager` records why in `last_refusal()`; if it ever stops, the
	# generic line is still better than silence.
	if bool(party.call("set_active", index)):
		return
	var token := ""
	if party.has_method("last_refusal"):
		token = str(party.call("last_refusal"))
	_say(_refusal_words(token))


## A refusal token, in player voice.
##
## `party.gd` refuses with machine tokens — `no_such_member`, `party_full` — and
## its `refused(token: String)` signal says so in the name. Putting one of those
## on screen unchanged is the mistake `combat_hud` had to undo twice: the bare
## word `open` from the AI's state machine, and "missed — too far, or facing the
## wrong way", which was a developer explaining a branch to himself. The token is
## for code to switch on. This is the sentence.
##
## An unrecognised token falls back to a general line rather than being printed,
## because a token nobody has translated yet is still a token.
func _refusal_words(token: String) -> String:
	match token:
		"party_full":
			return "your party is full — five is the limit"
		"already_held":
			return "that one is already with you"
		"no_such_member":
			return "there is no pal in that slot"
		"not_a_pal":
			return "that cannot join a party"
		_:
			return "that pal cannot go out right now"


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
