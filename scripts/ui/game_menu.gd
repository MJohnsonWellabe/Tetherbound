extends CanvasLayer

## The pause menu shell: tabs, focus, and the two things opening a menu must do.
##
## Those two things are the whole reason this is not just a Control someone
## dropped into a scene. Opening pauses the tree, and releases the mouse that
## scripts/world/playground_world.gd captures unconditionally and never gives
## back; closing restores both, to whatever they were rather than to a guess.
## Getting the restore wrong is invisible until the player closes the menu and
## finds the camera dead.
##
## The tab list comes from data/config/menu.json. The previous prototype kept
## its pause menu in src/data/pauseMenu.json for the same reason: a new screen
## should be a JSON entry plus a tab script, never a new branch in here.
##
## CONTROLLER FIRST, and this is not a preference. Tetherbound ships on an ROG
## Ally. A menu that needs a mouse is a broken menu, so everything selectable is
## a focusable Control, the theme makes focus the loudest state on screen, and
## Godot's built-in ui_* actions (which carry d-pad and stick bindings by
## default) drive the cursor. Nothing here reads a device.

const CONFIG_PATH := "res://data/config/menu.json"
## D28: the teal focus ring theme replaces the old gold one. The prior
## resource (`scenes/ui/menu_theme.tres`) is left in place, unreferenced.
const THEME_PATH := "res://assets/ui/theme/tetherbound_theme.tres"
const KEY_BINDINGS := preload("res://scripts/ui/key_bindings.gd")
const AUDIO_CUES := preload("res://scripts/ui/audio_cues.gd")
const INPUT_GLYPH := preload("res://scripts/ui/input_glyph.gd")
const INPUT_OWNER := preload("res://scripts/ui/input_owner.gd")

## How long a status line stays up. Long enough to read on a handheld held at
## arm's length, short enough that it is gone before the next one arrives.
const STATUS_SECONDS := 3.0

## How long the panic chord has to be held before every control goes back to its
## default. Long enough that it cannot happen by accident during a fight.
const PANIC_SECONDS := 1.5

## OF23: frames `_read_actions` sits out its own "not open -> open on
## `menu_cancel`" check after `suppress_reopen()` is called. `menu_cancel` and
## `build_cancel` share gamepad B (project.godot) — closing `build_menu.gd` on
## a B press is the SAME still-just-pressed press this shell would otherwise
## read, on its own `_process`, as "open." Two frames, the same width
## `dialogue_panel.gd::OPEN_GUARD_FRAMES` uses for its own edge, for the same
## reason: whichever node's `_process` happens to run first this frame, the
## guard still covers it.
const REOPEN_GUARD_FRAMES := 2

## Screens that own the whole display while they are up: the conversation box,
## the naming grid, the starter orbs. Joined by the panels themselves in their
## own `_ready()`, and consulted by `open()` below.
##
## A group rather than a list of node paths, for the same reason
## `_find_combat()` looks for a method instead of a path: these panels live in
## the world scene and this shell is an autoload, so any path written here is a
## path that rots the day a scene is rearranged. A group also means the rule is
## enforced in ONE place — a fourth modal joins the group and is covered, rather
## than having to remember to call `hold_input()` from its own `open()`, which
## is exactly what the starter picker and the dialogue panel both forgot.
const STORY_MODAL_GROUP := &"story_modal"

var game: Node = null

## The player's controls. Owned here rather than by the autoload because this
## node is the settings screen's shell and is mounted at boot in every scene
## anyway; see docs/decisions/D15.
var bindings: RefCounted = null

var _config: Dictionary = {}
var _tabs: Array = []
var _bodies: Array = []
var _tab_buttons: Array = []
## The bare label text for each tab, kept apart from the Button's own `text`
## because the selected tab's text gets a leading accent glyph spliced onto
## it (spec §16) and splicing onto the button's own text a second time would
## accumulate glyphs rather than replace one.
var _tab_labels: Array = []
var _index: int = 0

var _open: bool = false
## Whatever the mouse was doing before the menu opened. Restored on close, so
## the menu works the same whether it was opened from a captured-mouse world or
## from a future scene that never captured it.
var _mouse_before: int = Input.MOUSE_MODE_VISIBLE
var _paused_before: bool = false

var _status_left: float = 0.0
var _last_revision: int = -1

## Independent of `_status`/`_status_left`: those live inside `_root`, which is
## invisible while the menu is closed, and this hint is shown precisely when
## the menu refuses to become visible at all.
var _refusal_left: float = 0.0
var _refusal_label: Label = null

## Set while the settings tab is capturing a button. The shell polls actions,
## and the button being rebound is very often one the shell itself reads.
var _deaf: bool = false
var _panic_left: float = PANIC_SECONDS
## OF23. See `REOPEN_GUARD_FRAMES` / `suppress_reopen`.
var _reopen_guard: int = 0

## The fight, found by capability rather than by path so this file holds no
## knowledge of another agent's scene layout. Re-found when it goes away.
var _combat: Node = null

## The exploration HUD (`playground_hud.gd`), found by the same by-name
## convention `game_state.gd::_find_player()` and `playground_hud.gd`'s own
## `AllyCreature` lookup already use for a world scene's singular nodes.
## Re-found on every open() the same defensive way `_combat` is, since a
## capture tool or test harness may add/remove the world scene between opens.
##
## R4.10 bug (blind-judge pass): the world HUD was never hidden while this
## menu was open at all -- not for this tab, not for any other. Dim's 60%
## wash and the panel's own 86%-alpha background (UITokens.BG_PANEL) were
## carrying the whole job of masking it, and neither is fully opaque nor
## full-screen (the panel stops short of the frame's own margin on the right,
## and a content overflow -- six rows during the release ceremony -- pushes
## rows past the panel's bottom edge entirely). The result was readable
## quest-log text and hotbar prompts bleeding through at the screen edges on
## every tab; the ceremony's taller list just made it impossible to miss.
## Actually hiding the HUD's CanvasLayer, not just trusting translucency to
## cover it, is the fix that holds regardless of panel geometry or content
## height, and it now runs for every tab because it lives in open()/close()
## rather than in any one tab's script.
var _world_hud: CanvasLayer = null

## Last focus owner seen while the menu was open, per `AudioCues` wiring
## below -- lets `_process` play `ui_focus` only on a real change, never once
## per frame while the stick sits still on one button.
var _last_focus_owner: Control = null

@onready var _root: Control = $Root
@onready var _tab_row: HBoxContainer = $Root/Frame/Panel/Body/Tabs
@onready var _content: MarginContainer = $Root/Frame/Panel/Body/Content
@onready var _title: Label = $Root/Frame/Panel/Body/Header/Title
@onready var _day: Label = $Root/Frame/Panel/Body/Header/Day
@onready var _status: Label = $Root/Frame/Panel/Body/Status
@onready var _footer: Label = $Root/Frame/Panel/Body/Footer


func _ready() -> void:
	game = get_parent()
	# The shell is a legitimate input owner too. This matters during handoffs:
	# a panel closing after the shell opened must not unpause behind it.
	add_to_group(INPUT_OWNER.GROUP)
	_config = _read_config()
	_load_bindings()

	var theme_resource: Theme = load(THEME_PATH)
	if theme_resource != null:
		_root.theme = theme_resource

	_footer.text = legend(str(_config.get("footer", "")))
	_build_tabs()
	_root.visible = false
	_build_refusal_label()


## A sibling of `_root`, not a child of it, so it can be shown while the menu
## itself stays closed. This layer draws above the combat HUD (layer 20 vs 1,
## see game_menu.tscn), so the hint reaches the player mid-fight, which is the
## one moment it exists to explain.
func _build_refusal_label() -> void:
	_refusal_label = Label.new()
	_refusal_label.name = "RefusalHint"
	_refusal_label.visible = false
	_refusal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_refusal_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_refusal_label.anchor_top = 0.12
	_refusal_label.anchor_bottom = 0.12
	_refusal_label.offset_left = -400
	_refusal_label.offset_right = 400
	_refusal_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_refusal_label.add_theme_font_size_override("font_size", 28)
	_refusal_label.add_theme_constant_override("outline_size", UITokens.OUTLINE_SIZE)
	_refusal_label.add_theme_color_override("font_outline_color", UITokens.OUTLINE)
	_refusal_label.add_theme_color_override("font_shadow_color", Color(UITokens.OUTLINE, 0.6))
	_refusal_label.add_theme_constant_override("shadow_offset_y", 3)
	add_child(_refusal_label)


## Snapshot the input map as project.godot left it, then lay the player's
## overrides on top.
##
## Order matters and so does the timing: this runs at autoload `_ready`, before
## any world scene has read an action. project.godot is never written back to —
## it IS the defaults, and an editor pass over it strips its comments.
##
## A settings file that is missing, corrupt or from a newer build must not stop
## the game booting, so `load_overrides` reports what it found rather than
## failing, and the game carries on with defaults either way.
func _load_bindings() -> void:
	bindings = KEY_BINDINGS.new()
	var settings: Dictionary = _config.get("settings", {}) as Dictionary
	var controls: Dictionary = settings.get("controls", {}) as Dictionary
	bindings.glyphs = controls.get("glyphs", {}) as Dictionary
	var status: int = bindings.load_overrides()
	if status != KEY_BINDINGS.LOAD_OK and status != KEY_BINDINGS.LOAD_MISSING:
		push_warning("controls fell back to defaults (status %d)" % status)


func _read_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("menu config missing: %s" % CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("menu config is not a JSON object: %s" % CONFIG_PATH)
		return {}
	return parsed as Dictionary


func _build_tabs() -> void:
	var listed: Variant = _config.get("tabs", [])
	if typeof(listed) != TYPE_ARRAY:
		return

	for entry in listed:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var tab := entry as Dictionary
		var script_path := str(tab.get("script", ""))
		var script: GDScript = load(script_path)
		if script == null:
			push_error("menu tab '%s' has no script at %s" % [tab.get("id", "?"), script_path])
			continue

		var body: Control = script.new()
		body.set("menu", self)
		body.visible = false
		_content.add_child(body)

		var label := str(tab.get("label", tab.get("id", "?")))
		var button := Button.new()
		button.text = label
		button.toggle_mode = true
		button.focus_mode = Control.FOCUS_ALL
		button.add_theme_font_size_override("font_size", UITokens.FONT_BUTTON)
		# Full-width rail (spec §16): each tab claims an equal share of the
		# row instead of sizing to its own label, so the row reads as one
		# continuous rail rather than a cluster of buttons at the left.
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Bound by index rather than by id: two tabs sharing an id is a data bug
		# that should show as a duplicate label, not as a tab that opens another.
		var slot := _tabs.size()
		button.pressed.connect(func() -> void: select(slot))
		_tab_row.add_child(button)

		_tabs.append(tab)
		_bodies.append(body)
		_tab_buttons.append(button)
		_tab_labels.append(label)
		_style_tab_button(button, label, false)


## The rail treatment for one tab button (spec §16): a 3px teal underline
## and a small ◆ accent beside the label mark the SELECTED tab; every other
## tab is flat with muted text. Applied by index in `select()` rather than
## left to the theme's own toggle/pressed styling, because the theme's
## pressed look is shared with every other toggle button in the menu (the
## settings screen's own toggles included) and this rail wants a look that
## says "tab", not "toggle".
func _style_tab_button(button: Button, label: String, selected: bool) -> void:
	button.text = "◆  %s" % label if selected else label
	var box := StyleBoxFlat.new()
	box.bg_color = UITokens.BG_PANEL_ALT if selected else Color(0, 0, 0, 0)
	box.border_width_bottom = 3 if selected else 0
	box.border_color = UITokens.TEAL
	box.content_margin_left = 12
	box.content_margin_right = 12
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	# "normal" and "pressed" only -- NOT "focus" or "hover". The theme's own
	# teal focus ring (D28, `tetherbound_theme.tres`) has to keep drawing on
	# whichever tab the controller cursor is actually on, selected or not;
	# overriding "focus" here too would silence that ring on every tab except
	# the selected one, which is the one state menu_tab.gd's own header
	# comment says must stay the loudest on screen.
	for state in ["normal", "pressed"]:
		button.add_theme_stylebox_override(state, box)
	button.add_theme_color_override(
		"font_color", UITokens.TEXT_PRIMARY if selected else UITokens.TEXT_SECONDARY
	)
	button.add_theme_color_override(
		"font_hover_color", UITokens.TEXT_PRIMARY if selected else UITokens.TEXT_SECONDARY
	)
	button.add_theme_color_override("font_pressed_color", UITokens.TEXT_PRIMARY)


# --- opening and closing ----------------------------------------------------


func is_open() -> bool:
	return _open


## Open on a tab id, or on whatever was last shown.
##
## Refuses while a fight is running. That started as a binding accident —
## `menu_cancel` and `combat_run` shared Escape / B, so in a fight the button
## already meant "flee" (D14) — and CONTROLLER-MAP has since separated them:
## the shell opens on `game_menu` (Escape / gamepad Menu) and flee is the pad's
## RB. The refusal is kept anyway because it is the behaviour the game shipped
## with and D14 argued for on its own terms: a real-time fight does not stop
## for a pause screen. Deleting it is a design change, not a mapping one.
##
## Refuses the same way while a story modal owns the screen — see
## `_refusal_reason()`. The blind playtest opened this shell on top of the
## starter orbs: the picker kept drawing (it is not `PROCESS_MODE_ALWAYS`, so
## the pause stopped it processing but not rendering) and its title and hints
## ghosted through the menu, over a selector that could no longer be answered.
func open(tab_id: String = "") -> bool:
	if _open:
		return false
	if not _refusal_reason().is_empty():
		return false

	# BEFORE anything below makes a tab visible. The press that opens this shell
	# is STILL DOWN, and gamepad Start is two actions at once: `game_menu` here
	# and `backpack_drop` on the satchel tab (project.godot;
	# data/config/menu.json's Backpack group note explains why drop sits there).
	# The comment further down worked out one half of that collision -- that
	# Menu must not also CLOSE the shell -- and missed this half. With anything
	# at all in the satchel, opening the pause menu landed the player straight
	# in a "Drop it?" confirmation on whatever slot held focus, which calls
	# `hold_input(true)`, so their next B cancelled a drop they never asked for
	# instead of closing the menu. A destructive verb offered unasked, one A
	# press from deleting an item they never selected.
	#
	# Placement is half the fix and it took three tries to get right.
	# `tools/_probe_pause.gd` prints the order: `_read_drop FIRED` lands BEFORE
	# the notification when this loop sits after `select(target)` at the bottom
	# of this function, because `select()` is what makes the tab visible and its
	# poll runs inside that call. Arming from the tab's own closed-to-open
	# transition was one frame later still. The other half is that the tab holds
	# the guard until the button is RELEASED rather than for a frame count --
	# more than one poll elapses before the press comes up, so any countdown
	# gets out-waited.
	for body: Variant in _bodies:
		var node := body as Node
		if node != null and node.has_method("notify_shell_opened"):
			node.call("notify_shell_opened")

	_mouse_before = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_paused_before = get_tree().paused
	get_tree().paused = true

	_open = true
	_root.visible = true
	# Re-read on every open: the Settings tab can rebind any of the keys the
	# footer names, and a legend built once at boot would go stale the moment
	# it did.
	_footer.text = legend(str(_config.get("footer", "")))
	_status.text = ""
	_status_left = 0.0
	# Force a rebuild: state may have moved while the menu was shut.
	_last_revision = -1
	_set_world_hud_visible(false)

	AUDIO_CUES.play(&"ui_accept")

	var target := _index
	if not tab_id.is_empty():
		for i in _tabs.size():
			if str((_tabs[i] as Dictionary).get("id", "")) == tab_id:
				target = i
				break
	select(target)
	return true


func close() -> void:
	if not _open:
		return
	AUDIO_CUES.play(&"ui_cancel")
	_open = false
	_root.visible = false
	# A tab holding the shell deaf cannot un-hold it once it stops being polled.
	_deaf = false
	# Restore, do not assume. A future scene may legitimately open the menu with
	# the mouse already visible, and slamming it back to CAPTURED would trap a
	# cursor the player needs.
	Input.mouse_mode = _mouse_before
	# RG1: the shell releases pause ownership; it must not resurrect a stale
	# paused snapshot captured during an earlier modal transition. All legal
	# open paths originate from the live world, so release means unpaused.
	get_tree().paused = false
	_set_world_hud_visible(true)
	if _index >= 0 and _index < _bodies.size():
		_bodies[_index].call("say", "")


func toggle() -> void:
	if _open:
		close()
	else:
		open()


## OF23: called by `build_menu.gd` right before it closes on a `menu_cancel`/
## `build_cancel` press — B is double-bound to both actions, so without this
## `_read_actions` below sees the exact same still-just-pressed press and
## reopens this shell the instant the build menu closes. A player pressing B
## to leave the build screen would fall straight back into a pause menu they
## never opened from.
func suppress_reopen() -> void:
	_reopen_guard = REOPEN_GUARD_FRAMES


## The id of the tab currently showing ("backpack", "map", ...), or "" when no
## tabs are configured. Lets a caller ask "am I already here?" without reaching
## into `_index` and the tab table itself.
func current_tab_id() -> String:
	if _tabs.is_empty() or _index < 0 or _index >= _tabs.size():
		return ""
	return str((_tabs[_index] as Dictionary).get("id", ""))


func select(index: int) -> void:
	if _tabs.is_empty():
		return
	_deaf = false
	_index = posmod(index, _tabs.size())
	for i in _bodies.size():
		_bodies[i].visible = i == _index
		_tab_buttons[i].button_pressed = i == _index
		_style_tab_button(_tab_buttons[i], str(_tab_labels[i]), i == _index)
	_title.text = str((_tabs[_index] as Dictionary).get("label", "Paused"))
	_last_revision = -1
	_refresh()

	var focus_target: Control = _bodies[_index].call("first_focus")
	if focus_target != null:
		focus_target.grab_focus()
	else:
		_tab_buttons[_index].grab_focus()
	# Land here quietly: `_process`'s focus watch below compares against this
	# so a tab switch's own focus jump doesn't ALSO fire a redundant ui_focus
	# tick on top of the ui_tab cue `next_tab`/the shortcut jump already play.
	_last_focus_owner = get_viewport().gui_get_focus_owner()


func next_tab() -> void:
	AUDIO_CUES.play(&"ui_tab")
	select(_index + 1)


## Owner playtest report: "LB = tab left, RB = tab right." `cycle_action`
## (LB / Q by default) used to be wired to `next_tab()`, which moves the
## selection RIGHT through the on-screen tab row — backwards from what the
## button's own position on the controller promises. This is the LB half;
## `reverse_cycle_action` (RB, below in `_read_actions`) is the RB half.
func previous_tab() -> void:
	AUDIO_CUES.play(&"ui_tab")
	select(_index - 1)


## One status line for the whole menu, so a message cannot appear somewhere the
## player was not looking.
func say(message: String) -> void:
	_status.text = message
	_status_left = STATUS_SECONDS if not message.is_empty() else 0.0


## Why `open()` would refuse right now, or "" if it would not.
##
## One function so the guard and the on-screen explanation cannot drift apart:
## a reason that can be enforced without being said is the silent refusal
## `_flash_refusal()` was written to stop, and a reason that can be said without
## being enforced is worse.
func _refusal_reason() -> String:
	if _fight_in_progress():
		return "Can't open the menu during a fight"
	if _story_modal_open():
		return "Finish what's on screen first"
	return ""


## Is one of the story panels (STORY_MODAL_GROUP) up?
##
## Asked of the group rather than of any particular node, so a panel that is not
## in the current scene — every headless test that never loads a world, the
## menu-only boot screen — simply contributes nothing instead of erroring.
func _story_modal_open() -> bool:
	for node in get_tree().get_nodes_in_group(STORY_MODAL_GROUP):
		if node.has_method("is_open") and bool(node.call("is_open")):
			return true
	return false


## The on-screen explanation `open()` refusing never had: without this, the menu
## button just does nothing and looks broken rather than rules-respecting. See
## `open()`'s own comment on why the menu yields here at all.
## Say whatever `open()` just refused for, if it refused for a reason a player
## needs to hear. Silent when there is none — `open()` also returns false when
## the menu is simply already open, and flashing "..." at that would be noise.
func _explain_refusal() -> void:
	var reason := _refusal_reason()
	if not reason.is_empty():
		_flash_refusal(reason)


func _flash_refusal(message: String) -> void:
	AUDIO_CUES.play(&"ui_error")
	_refusal_label.text = message
	_refusal_label.visible = true
	_refusal_left = STATUS_SECONDS


# --- the frame loop ---------------------------------------------------------


func _process(delta: float) -> void:
	_read_panic(delta)
	_read_actions()

	if _refusal_left > 0.0:
		_refusal_left -= delta
		if _refusal_left <= 0.0:
			_refusal_label.visible = false

	if not _open:
		return

	if _status_left > 0.0:
		_status_left -= delta
		if _status_left <= 0.0:
			_status.text = ""

	# Focus tick (spec 20): a stick nudge across the grid plays a sound only
	# when the FOCUSED CONTROL actually changed, read off the viewport rather
	# than any signal of ours -- one watch here covers every tab body without
	# each one wiring its own `focus_entered` wave.
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner != _last_focus_owner:
		_last_focus_owner = focus_owner
		if focus_owner != null:
			AUDIO_CUES.play(&"ui_focus")

	_day.text = "Day %d" % int(game.get("day")) if game != null else ""
	_refresh()


## Rebuild structure only when the state's shape changed; write values always.
func _refresh() -> void:
	if _index < 0 or _index >= _bodies.size():
		return
	var body: Control = _bodies[_index]
	var revision: int = int(body.call("revision"))
	if revision != _last_revision:
		_last_revision = revision
		body.call("build")
	body.call("poll")


# --- input ------------------------------------------------------------------


## Actions are POLLED, not received as events.
##
## Two reasons, and the second is the one that decided it. A focused Button
## swallows ui_accept and would swallow anything sharing its event, so the close
## and cycle keys have to be read outside the Control tree — and reading them
## here keeps the whole menu on one rule with scripts/ui/combat_hud.gd, which
## polls the fight every frame rather than being pushed at.
##
## Cursor movement and button presses are NOT polled: those are Godot's built-in
## ui_* actions driving Control focus, which is what makes the menu work on a
## stick with no code of ours in the path.
## Stop reading actions for a moment. Called by the settings tab while it is
## waiting for a button: without this, binding `menu_cancel` to A would close the
## menu on the very press that bound it.
##
## R4.10 blind-judge finding (round 3): the tab row stayed fully lit through
## the release ceremony's farewell/goodbye beats, which is genuinely true of
## every OTHER `hold_input(true)` caller too (the backpack's target picker,
## its drop confirmation) -- Q/LB and Tab/RB are refused the whole time
## regardless of which tab is holding the shell, and the row looked live
## anyway. Dimming it here, once, for every held state rather than adding a
## one-off ceremony-only treatment, is both the smaller change and the more
## honest one: "you cannot leave this" is true in all of them, not just this
## one.
func hold_input(held: bool) -> void:
	_deaf = held
	if _tab_row != null:
		_tab_row.modulate.a = 0.35 if held else 1.0


## A tab that borrows a button's meaning while `hold_input` is engaged (the
## backpack's target picker reads `menu_cancel` itself instead of it closing
## the menu) has to say so here too, or this static footer keeps advertising
## the shell's own binding for a button that means something else right now.
## Empty restores the configured default.
func override_footer(text: String) -> void:
	_footer.text = legend(text if not text.is_empty() else str(_config.get("footer", "")))


## Fill `{action}` placeholders in a button legend with the key that action is
## really bound to right now.
##
## The footer used to be a hand-typed string, and it told keyboard players to
## press gamepad buttons: "A  Select    B  Close", while the two entries beside
## them ("Q / LB", "Tab / RB") correctly named both devices. That was not merely
## cosmetic. The literal keyboard B is still bound to `build_open`, so
## a keyboard player who obeyed the legend and pressed B opened the Build tab
## instead of closing the menu — found by a blind playtest, which spent the rest
## of the session unable to leave the screen the same way it came in.
##
## Read off the InputMap rather than retyped, because the Settings tab lets the
## player move every one of these, and a legend that goes stale on a rebind is
## the same defect again with a longer fuse. The gamepad half stays literal:
## `input_glyph.gd`'s icons need a RichTextLabel and this is a plain Label.
func legend(template: String) -> String:
	var out := template
	while true:
		var start := out.find("{")
		if start < 0:
			break
		var end := out.find("}", start)
		if end < 0:
			break
		var action := out.substr(start + 1, end - start - 1)
		out = out.substr(0, start) + INPUT_GLYPH.key_name_for_action(action) + out.substr(end + 1)
	return out


## The way back from a layout the player has broken.
##
## READ OFF THE DEVICE, NOT THE INPUT MAP, and that is the entire point. Every
## other way into this menu goes through an action the player is allowed to move,
## so every other way can be lost. Hold the pad's Menu and View buttons together,
## or F10 on a keyboard, for a second and a half.
##
## docs/TECHNICAL_START.md says never to scatter raw device checks through
## gameplay. This is the exception the rule needs: it is the one check that must
## keep working when the input map cannot be trusted, and it lives in one place.
func _read_panic(delta: float) -> void:
	if not _panic_chord_held():
		_panic_left = PANIC_SECONDS
		return
	_panic_left -= delta
	if _panic_left > 0.0:
		return
	_panic_left = PANIC_SECONDS

	if bindings != null:
		bindings.reset_all()
		bindings.save()
	if not _open:
		open("settings")
	else:
		for i in _tabs.size():
			if str((_tabs[i] as Dictionary).get("id", "")) == "settings":
				select(i)
				break
	say("Every control is back to its default.")


func _panic_chord_held() -> bool:
	if Input.is_key_pressed(KEY_F10):
		return true
	return Input.is_joy_button_pressed(0, JOY_BUTTON_START) \
		and Input.is_joy_button_pressed(0, JOY_BUTTON_BACK)


func _read_actions() -> void:
	if _tabs.is_empty() or _deaf:
		return

	if not _open:
		# An armed ghost owns the whole construction control strip, including Y
		# for Dismantle and B for Cancel. Menu shortcuts share those physical
		# buttons, so the shell must not open Backpack/Map and steal the action
		# before the placer sees it. Changing piece still uses the dedicated live
		# Build menu, not this pause shell.
		if game != null and str(game.get("pending_build")) != "":
			return
		# OF23: `menu_cancel` and `build_cancel` share gamepad B
		# (project.godot). `build_menu.gd` is added straight under
		# `get_tree().root` AFTER this shell (which lives nested inside the
		# `Game` autoload, mounted first) — so on the frame that shared press
		# lands, THIS runs before an open build menu's own `_process` gets a
		# turn to react and close itself. Opening here first would pause the
		# tree, and a paused, non-`PROCESS_MODE_ALWAYS` build menu would never
		# see that same press to close on — it would be stuck open behind a
		# pause menu it never asked for. Standing aside while one is open lets
		# it close on its own turn, later this same frame, tree still
		# unpaused.
		var open_build_menu: Node = get_tree().get_first_node_in_group(&"build_menu")
		if open_build_menu != null and bool(open_build_menu.call("is_open")):
			return
		# Belt-and-suspenders for the reverse ordering (a future refactor that
		# processes build_menu first): `suppress_reopen()` sits this shell out
		# for a couple frames right after a shared-button close, the same
		# width `dialogue_panel.gd::OPEN_GUARD_FRAMES` uses for its own edge.
		if _reopen_guard > 0:
			_reopen_guard -= 1
			return
		if Input.is_action_just_pressed(str(_config.get("open_action", "game_menu"))):
			if not open():
				_explain_refusal()
			return
		for action in _shortcuts().keys():
			if Input.is_action_just_pressed(str(action)):
				if not open(str(_shortcuts()[action])):
					_explain_refusal()
				return
		return

	# CONTROLLER-MAP note: Menu OPENS the shell and B closes it, deliberately
	# asymmetric. Menu could not also close it: gamepad Menu is `backpack_drop`
	# in the satchel tab (data/config/menu.json's "Backpack" group note), so a
	# close on the same button would be a second live verb on one press exactly
	# where the player is holding a stack. B is the authored back button in
	# every menu anyway.
	if Input.is_action_just_pressed(str(_config.get("close_action", "menu_cancel"))):
		close()
		return

	if Input.is_action_just_pressed(str(_config.get("cycle_action", "menu_tab_left"))):
		previous_tab()
		return

	# RB's half of "LB = tab left, RB = tab right" (owner playtest report).
	# `menu_tab_right` is a dedicated action (project.godot) rather than a
	# reuse of `backpack_drop`'s old RB binding — `backpack_drop` moved to
	# gamepad Start (button 6) specifically to free RB for this, since both
	# actions would otherwise fire off the same physical press whenever the
	# backpack tab is the one open.
	if Input.is_action_just_pressed(str(_config.get("reverse_cycle_action", "menu_tab_right"))):
		next_tab()
		return

	# The shortcut key doubles as a jump-to-tab while the menu is already open,
	# so pressing I twice lands on the backpack rather than opening and closing.
	#
	# A shortcut aimed at the tab ALREADY showing is left alone rather than
	# re-selected. Re-selecting was a no-op that still swallowed the press, and
	# `inventory` shares gamepad Y with `backpack_assign` -- which only ever
	# fires on the backpack tab, exactly where `inventory` has nothing left to
	# do. Returning here would have eaten every assign press on a controller.
	for action in _shortcuts().keys():
		if Input.is_action_just_pressed(str(action)):
			var wanted := str(_shortcuts()[action])
			if wanted == current_tab_id():
				continue
			for i in _tabs.size():
				if str((_tabs[i] as Dictionary).get("id", "")) == wanted:
					AUDIO_CUES.play(&"ui_tab")
					select(i)
					break
			return


func _shortcuts() -> Dictionary:
	var shortcuts: Variant = _config.get("shortcuts", {})
	return shortcuts as Dictionary if typeof(shortcuts) == TYPE_DICTIONARY else {}


## Is a fight running anywhere in the current scene?
##
## Found by looking for a node that answers `is_fighting()` rather than by node
## path. Combat belongs to another agent and its scene layout is theirs to move;
## a hard-coded path here would break silently the day it does.
func _fight_in_progress() -> bool:
	if _combat == null or not is_instance_valid(_combat):
		_combat = _find_combat(get_tree().get_current_scene())
	if _combat == null:
		return false
	return bool(_combat.call("is_fighting"))


func _find_combat(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("is_fighting"):
		return node
	for child in node.get_children():
		var found := _find_combat(child)
		if found != null:
			return found
	return null


## Hides (or restores) the world's exploration HUD for the length of this menu
## being open. Looked up fresh each call rather than cached across opens: the
## world scene it lives in can be swapped out from under this autoload (a
## capture tool, a scene reload) between one open() and the next, same reason
## `_find_combat` re-finds `_combat` rather than trusting a stale reference.
## Silently does nothing with no current scene or no HUD in it -- the menu-only
## boot screen and every headless tool/test that never loads a world scene
## still need open()/close() to work.
## Both world HUD layers, not just the exploration one.
##
## `combat_hud.gd` is a SECOND CanvasLayer mounted beside `PlaygroundHUD` in
## `meadows_playground.tscn`, and it draws its own prompt line -- the
## `encounter_director.gd` offer, "Call out Biscuit" / "Put Biscuit away" --
## whenever that director owns the active prompt, fight or no fight. Hiding
## only `PlaygroundHUD` therefore left that line printing through the pause
## menu's own dim, which a blind visual-judge pass read off the map frame as
## the menu failing to hide the HUD beneath it. It was hiding the HUD; there
## were two.
##
## Named explicitly rather than found by group because adding a group means
## editing the world scene and `combat_hud.tscn`, which are not this file's to
## change. If a third world HUD layer is ever added, it must be added here too
## -- and if that happens more than once, a group is the right answer, for
## exactly the reason `input_owner.gd`'s header gives about per-caller gates
## drifting out of sync.
func _set_world_hud_visible(value: bool) -> void:
	INPUT_OWNER.set_world_hud_visible(get_tree(), value)
