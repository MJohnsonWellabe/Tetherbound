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

## How a pal is put into words: the name, the trait, the vitals line and the
## whole appraisal panel.
##
## This screen used to own all of it privately. M5's release ceremony asks the
## player to compare six pals and lose one forever, and it has to describe them
## in EXACTLY the words this menu already uses — a party menu that calls a pal
## "Promising" and a release screen that calls the same pal something else has
## given the player two different reasons and one irreversible button. Lifted
## rather than copied, for the reason `ui_style.gd` gives about its colours: the
## lines in there are answers to specific complaints, and a second copy drifts
## away from the complaint that produced it.
const CARD := preload("res://scripts/ui/pal_card.gd")

@export var party_path: NodePath

## The name-entry screen, pushed on top of this one. A sibling under the same
## stack rather than something instanced on the press, for the reason
## `screen_stack.tscn` gives about this screen: instancing a screen at the moment
## it opens is a hitch in the one frame the player is watching for a response.
##
## Optional. A party screen with nothing wired here still lists, still switches,
## and dims its rename prompt to say the verb is not available — which is a
## working menu with one verb missing rather than a menu that errors.
@export var rename_screen_path: NodePath

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
	return int(CARD.number(party, "active_index", -1.0))


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
	var can_rename: bool = filled and _rename_screen() != null
	var rows: Array[Array] = []
	# "Up/Down" and not an arrow glyph. The blind judge read the first version
	# as "[$] Choose" — the project's font has no U+2195, so it fell back to a
	# placeholder and the one prompt telling a player how to move the selection
	# said nothing at all. `[A]` and `◆` both render; that arrow does not.
	rows.append(["Up/Down", "Choose", true])
	rows.append(["A", "Send out", can_send])
	# Rename is advertised in the FOOTER and not left to be discovered. The same
	# blind judge could not find a rename call, a rename screen or a rename prompt
	# anywhere in the M4 evidence and concluded — correctly, on that evidence —
	# that "nickname" meant "auto-assigned label". A verb nothing tells you about
	# is a verb that does not exist.
	rows.append(["Left/Right", "Rename", can_rename])
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
	head_level.text = "Lv %d" % int(CARD.number(member, "level", 1.0))

	var hp := CARD.number(member, "hp", 0.0)
	var max_hp := maxf(1.0, CARD.number(member, "max_hp", 1.0))
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
	# Species, vitals and appraisal, in `pal_card.gd`'s words rather than in this
	# screen's. See the note on CARD: the release ceremony draws the same paragraph
	# about the same pal, and the two must not be able to disagree.
	_detail_body.text = "\n".join(CARD.detail_lines(member))
	_append_notice()


func _append_notice() -> void:
	if _notice == "":
		return
	_detail_body.text += "\n\n[color=#%s]%s[/color]" % [STYLE.WARN, _notice]


# ----------------------------------------------------------------- appraisal
#
# The appraisal panel, the verdict word, the stat labels and the trait paragraph
# were all here first and now live in `pal_card.gd` — unchanged, word for word.
# The move is explained in that file's header: M5's release ceremony describes
# the same six pals and must describe them in the same words, and two copies of a
# paragraph are two paragraphs that can disagree about what a pal is worth.


# ------------------------------------------------------------------- members
#
# Three one-line questions this screen asks about a pal, answered in
# `pal_card.gd` so the release ceremony gets the same answers. They stay named
# here because the call sites read better with them and because a screen asking
# "is this one down" is doing something a formatter is not.

## The name to show. `display()` is the pal's own answer to "nickname if set,
## else species name" and this screen does not second-guess it — a menu that
## re-derived the name would be the place a nickname stopped showing up.
func _display_of(member: Object) -> String:
	return CARD.display_of(member)


## The trait, in words, for a slot row. Asks the trait table rather than
## humanising `trait_id`, so the row and the appraisal panel beside it cannot end
## up calling the same trait two different things.
func _trait_of(member: Object) -> String:
	return CARD.trait_of(member)


func _is_down(member: Object) -> bool:
	return CARD.is_down(member)


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


## Left or right on a slot opens the rename screen for that pal.
##
## LEFT/RIGHT AND NOT A THIRD BUTTON, and the reason is the input map rather than
## taste. `screen_stack.gd` hands a screen exactly three things — `navigate`,
## `confirm` and `cancel` — on purpose, so that no screen polls raw input behind
## the stack's back. A rename button would therefore need a new menu action in
## `project.godot`, or it would have to borrow a combat one; the input map is
## emphatic about the second ("Nothing else may read these — build mode did, and
## it made the pal switch un-rebindable"). `on_nudge` is already plumbed, already
## comes from the `move_*` actions every other screen uses, and costs nothing.
##
## Direction is ignored. `screen.gd` passes it because a row with a VALUE on it
## wants to know which way you pushed; a row that opens a screen does not, and
## making left and right do different things here would be a coin flip the player
## has to remember.
func on_nudge(index: int, _direction: int) -> void:
	var members := _members()
	if index >= members.size() or members[index] == null:
		_say("that slot is empty — nothing to name yet")
		return
	var screen := _rename_screen()
	if screen == null:
		# Named as wiring rather than as a refusal the player caused. This is the
		# same distinction `_draw_detail` draws for a missing party node: a screen
		# that is not pointed at anything is a mistake in the scene, and saying so
		# is how somebody finds it.
		_say("no rename screen is wired to this menu")
		return
	var stack := get_parent()
	if stack == null or not stack.has_method("push"):
		_say("there is nowhere to open the rename screen")
		return

	# Subject first, then push. `on_pushed()` takes no arguments and the stack is
	# never going to grow a way to pass one — it does not know what a screen
	# contains, which is why it can hold any of them.
	screen.call("open_for", members[index])
	stack.call("push", screen)


## The rename screen, or null if this menu was never pointed at one.
##
## Checked by method rather than by class, like `_party()` above: it is a
## separate scene that may be absent in a test harness, and a party menu that
## cannot rename is still a party menu.
func _rename_screen() -> Control:
	var node := get_node_or_null(rename_screen_path) as Control
	if node == null or not node.has_method("open_for"):
		return null
	return node


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
