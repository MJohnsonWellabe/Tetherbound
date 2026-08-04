extends Control

## The chrome every screen shares: the scrim, the panel, the title, the rule and
## the footer hint row. A concrete screen supplies content and answers questions.
##
## The chrome is BUILT IN CODE rather than authored in a scene each screen
## inherits. Hand-written inherited scenes are the usual way to do this in Godot
## and they are also how five screens quietly end up with five different panel
## insets — one gets nudged in the editor, nobody notices, and the game looks
## assembled rather than designed. Building it here means there is exactly one
## panel, one title size and one footer in the project.
##
## What that costs you: everything you author in a concrete screen's .tscn is
## REPARENTED into `content` when the screen enters the tree. `@onready var x :=
## $Body` still works — onready assignments run before this class's `_ready()`
## gets a chance to move anything — but a `get_node("Body")` written later, after
## the move, will not find it. Ask `content` for it, or keep the reference.
##
## Subclasses that override `_ready()` MUST call `super()`. Nothing draws if they
## do not, and the failure is loud enough to catch immediately.
##
## Like `combat_hud.gd`, a screen PULLS. It redraws its title, hints and content
## from whatever owns the data every frame rather than caching a copy and hoping
## a signal arrives. A party menu with its own idea of who is in the party is a
## party menu that can disagree with the party.

const STYLE := preload("res://scripts/ui/ui_style.gd")

## The inset from the screen edge. Anchored, never positioned in absolute pixels
## — the project authors at 1920x1080 and stretches canvas_items, so this has to
## survive a desktop window too. These are offsets from the full-rect anchors, so
## the panel keeps a proportional-looking margin at any size.
const PANEL_INSET := Vector2(180.0, 96.0)

var _scrim: ColorRect = null

## Screens under the top one are dimmed rather than hidden. See
## `screen_stack._mark_active()` for why.
const INACTIVE_TINT := Color(0.55, 0.55, 0.55, 1.0)

@export var title: String = "Screen"

## Where a concrete screen's authored content ends up. A VBoxContainer, so a
## screen that authors two roots stacks them instead of overlapping them.
var content: VBoxContainer = null

var _panel: PanelContainer = null
var _title_label: Label = null
var _hints_label: RichTextLabel = null
var _focus: int = 0
var _screen_active: bool = true
var _last_title: String = ""
var _last_hints: String = ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# The screen is drawn, not clicked. This is a controller-first game and there
	# is no mouse-look action in the input map at all; a Control that eats mouse
	# events here would only ever eat them from something else.
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var authored: Array[Node] = get_children()
	_build_chrome()
	for child in authored:
		remove_child(child)
		content.add_child(child)

	# After the move, so rows and labels a subclass authored are covered too.
	STYLE.make_legible(self)
	_draw_chrome()


func _build_chrome() -> void:
	var scrim := ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = STYLE.SCRIM
	_scrim = scrim
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.offset_left = PANEL_INSET.x
	_panel.offset_top = PANEL_INSET.y
	_panel.offset_right = -PANEL_INSET.x
	_panel.offset_bottom = -PANEL_INSET.y
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override(
		"panel", STYLE.panel_style(STYLE.PANEL_BG, STYLE.PANEL_EDGE, 8)
	)
	add_child(_panel)

	var pad := MarginContainer.new()
	pad.name = "Pad"
	pad.add_theme_constant_override("margin_left", 40)
	pad.add_theme_constant_override("margin_right", 40)
	pad.add_theme_constant_override("margin_top", 28)
	pad.add_theme_constant_override("margin_bottom", 24)
	_panel.add_child(pad)

	var layout := VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 16)
	pad.add_child(layout)

	_title_label = Label.new()
	_title_label.name = "Title"
	_title_label.add_theme_font_size_override("font_size", 46)
	layout.add_child(_title_label)

	# A hairline under the title. Without it the title and the first row read as
	# one list with a very large first item.
	var rule := ColorRect.new()
	rule.name = "Rule"
	rule.color = STYLE.PANEL_EDGE
	rule.custom_minimum_size = Vector2(0.0, 2.0)
	layout.add_child(rule)

	content = VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 16)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(content)

	# RichTextLabel, not Label: the footer dims verbs that are unavailable, and a
	# Label cannot colour part of its own text.
	_hints_label = RichTextLabel.new()
	_hints_label.name = "Hints"
	_hints_label.bbcode_enabled = true
	_hints_label.fit_content = true
	_hints_label.scroll_active = false
	_hints_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hints_label.add_theme_font_size_override("normal_font_size", 28)
	layout.add_child(_hints_label)


func _process(_delta: float) -> void:
	# A screen that is not on the stack is still in the tree and still gets a
	# frame. Screens are authored as hidden children of the stack so that opening
	# one is not an instantiation hitch, which means without this guard every
	# screen in the game redraws itself every frame of the entire session.
	if not visible:
		return
	_draw_chrome()
	refresh()


func _draw_chrome() -> void:
	if _title_label == null:
		return
	# Compared before assigning: a RichTextLabel re-parses its bbcode on every
	# `text` write, and the footer is identical on the vast majority of frames.
	var wanted_title := screen_title()
	if wanted_title != _last_title:
		_last_title = wanted_title
		_title_label.text = wanted_title
	var wanted_hints := STYLE.hint_row(hints())
	if wanted_hints != _last_hints:
		_last_hints = wanted_hints
		_hints_label.text = wanted_hints


# ------------------------------------------------------------------- overrides

## What the title bar says. Overridden when it depends on state ("Party  3 / 5").
func screen_title() -> String:
	return title


## The footer row, as [button, label, enabled] triples.
##
## Both glyphs by default, because both buttons always do something on a screen:
## A picks the thing you are on and B goes back. A screen that adds a verb should
## keep these two and append, so the way out never moves.
func hints() -> Array[Array]:
	var rows: Array[Array] = []
	rows.append(["A", "Select", true])
	rows.append(["B", "Back", true])
	return rows


## How many things there are to be on. Zero means the screen has no selection,
## which is a legitimate answer — an appraisal read-out or a message screen.
func focus_count() -> int:
	return 0


## Called when the focused index changed. Content is redrawn from `refresh()`
## anyway, so most screens do not need this; it is here for the ones that have to
## scroll or play a sound.
func on_focus_changed(_index: int) -> void:
	pass


## `menu_confirm` on the focused item.
func on_activate(_index: int) -> void:
	pass


## Left/right on the focused item, for screens where a row has a value to change.
func on_nudge(_index: int, _direction: int) -> void:
	pass


## Redraw from the data. Called every frame; pull, do not cache.
func refresh() -> void:
	pass


func on_pushed() -> void:
	pass


func on_popped() -> void:
	pass


# ------------------------------------------------------ driven by ScreenStack

## Vertical moves the selection and wraps; horizontal is handed to the screen.
##
## Wraps because a five-slot list is short enough that walking off the bottom to
## reach the top is a shorter journey than four presses back up, and because a
## selection that stops dead at the end reads as the stick having disconnected.
func navigate(dx: int, dy: int) -> void:
	if dx != 0:
		on_nudge(_focus, dx)
	if dy == 0:
		return
	var count := focus_count()
	if count <= 0:
		return
	_focus = posmod(_focus + dy, count)
	on_focus_changed(_focus)


func confirm() -> void:
	if focus_count() > 0:
		on_activate(_focus)


## Return true to keep the screen open — the stack pops it otherwise. A screen in
## a sub-state overrides this to back out of the sub-state first.
func cancel() -> bool:
	return false


func focus_index() -> int:
	return _focus


func set_focus_index(index: int) -> void:
	var count := focus_count()
	if count <= 0:
		_focus = 0
		return
	var wanted: int = posmod(index, count)
	if wanted == _focus:
		return
	_focus = wanted
	on_focus_changed(_focus)


func is_screen_active() -> bool:
	return _screen_active


func set_screen_active(active: bool) -> void:
	if active == _screen_active:
		return
	_screen_active = active
	modulate = Color.WHITE if active else INACTIVE_TINT


## Deepen the scrim when this screen is stacked on another one.
##
## Called by the stack on push and pop. A screen at the bottom dims the WORLD,
## which should stay visible; a screen above another dims a SCREEN, which should
## not — otherwise two panels, two titles and two hint rows are all legible at
## once and a player cannot tell which is live.
func set_stacked(stacked: bool) -> void:
	if _scrim != null:
		_scrim.color = STYLE.SCRIM_STACKED if stacked else STYLE.SCRIM
