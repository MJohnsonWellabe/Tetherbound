extends VBoxContainer

## Base class for one screen inside the pause menu.
##
## A tab does three things and nothing else:
##
##   build()        construct its nodes, once, from GameState
##   poll()         re-read GameState and write labels, every frame it is shown
##   first_focus()  say what the stick lands on when the tab opens
##
## The split matters. scripts/ui/combat_hud.gd sets the house rule — UI reads
## state each frame and never keeps a copy of it — and `poll()` is that rule.
## But rebuilding twenty-four slot buttons sixty times a second would also
## destroy the focused node sixty times a second, which on a controller means
## the cursor cannot be moved at all. So structure is rebuilt only when
## `revision()` changes, and values are written every frame.
##
## `revision()` is a plain integer off GameState, not a signal. Adding a signal
## bus here would give the menu a second way to learn about state, and the first
## time the two disagree it costs an afternoon.

## The dark blue-gray/teal panel language `playground_hud.gd` established for
## the exploration HUD (bible §16). Tabs that want a panel reach for `_panel()`
## below rather than inventing their own colours, so a grid here and a bar
## there read as one HUD rather than two agents' guesses at "dark and teal."
const PANEL_BG := Color(0.07, 0.09, 0.13, 0.78)
const PANEL_BORDER := Color(0.55, 0.85, 0.86, 0.65)

## Set by the menu shell before build(). The tab uses it for `say()` and for
## reaching the item database.
var menu: Node = null


func _init() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 14)


## Construct nodes. Called once when the tab is first shown, and again whenever
## `revision()` changes. Implementations must clear their own children first.
func build() -> void:
	pass


## Re-read state and write values. Called every frame this tab is on screen.
func poll() -> void:
	pass


## Where the controller cursor starts. Null means "the menu keeps focus on the
## tab row", which is the right answer for a tab with nothing to select.
func first_focus() -> Control:
	return null


## A stamp that changes when the underlying state changes shape. Compared, never
## interpreted, so a tab may sum several counters into it.
func revision() -> int:
	return 0


## Say something in the menu's status line. Tabs do not own a message area of
## their own; one line in one place means a message cannot be missed because it
## appeared somewhere the player was not looking.
func say(message: String) -> void:
	if menu != null:
		menu.call("say", message)


## Shorthand used by every tab. Kept here so no tab reaches for the autoload by
## name in twelve places.
func state() -> Node:
	return menu.get("game") if menu != null else null


## Wraps `content` in the dark/teal panel (see PANEL_BG/PANEL_BORDER above).
## Copies `content`'s size flags onto the wrapper so wrapping never changes
## how a row lays out — a caller that expanded before still expands after.
func _panel(content: Control, margin: int = 18) -> PanelContainer:
	var box := StyleBoxFlat.new()
	box.bg_color = PANEL_BG
	box.border_color = PANEL_BORDER
	box.border_width_left = 2
	box.border_width_right = 2
	box.border_width_top = 2
	box.border_width_bottom = 2
	box.corner_radius_top_left = 14
	box.corner_radius_top_right = 14
	box.corner_radius_bottom_left = 14
	box.corner_radius_bottom_right = 14
	box.content_margin_left = margin
	box.content_margin_top = margin
	box.content_margin_right = margin
	box.content_margin_bottom = margin

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.size_flags_horizontal = content.size_flags_horizontal
	panel.size_flags_vertical = content.size_flags_vertical
	panel.add_child(content)
	return panel
