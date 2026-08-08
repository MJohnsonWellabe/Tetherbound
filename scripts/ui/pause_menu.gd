extends "res://scripts/ui/screen.gd"

## The pause menu: what the Start button opens.
##
## The owner's first session on the Ally: "There doesn't seem to be a menu
## button." There wasn't. Y opened the inventory, View the map, Start the party
## — three screens, three buttons, and no front door. This is the front door:
## one button, one list, every screen and the way out of the game on it.
##
## It OWNS NOTHING. Party, Inventory and Map are the same sibling screens their
## own buttons open; this menu pushes them onto the stack ON TOP of itself, so
## B from any of them lands back here rather than in the world. A player who
## learns "Start, down, A" never has to learn Y and View at all — and a player
## who already knows Y and View has lost nothing, because those buttons still
## work from the world.
##
## Entries are a const list here rather than data in a config: which screens
## exist is code's business (each one is an exported NodePath a scene has to
## wire), and a data file naming node paths would just be the scene's wiring
## written twice, one edit apart from disagreeing with it.

const SETTINGS := preload("res://scripts/ui/settings.gd")

const NOTICE_SECONDS := 2.0

@export var party_screen_path: NodePath
@export var inventory_screen_path: NodePath
@export var map_screen_path: NodePath
@export var settings_screen_path: NodePath

## The node whose `save_now("quit")` is the real quit path — the same call
## `save_director._notification` makes when the window close button is pressed,
## so quitting from this menu and quitting from the window frame write the same
## save for the same reason. `../../` resolves into the world scene the stack is
## instanced in; a bare preview finds nothing there and the row says so.
@export var save_director_path: NodePath = NodePath("../../SaveDirector")

## label, then how to resolve it: a screen path, or one of the two verbs only
## this menu has ("resume", "quit").
const ENTRIES: Array[Array] = [
	["Resume", "resume"],
	["Party", "party"],
	["Inventory", "inventory"],
	["Map", "map"],
	["Settings", "settings"],
	["Save & Quit", "quit"],
]

var _rows: Array[PanelContainer] = []
var _template: PanelContainer = null
var _notice: String = ""
var _notice_left: float = 0.0

@onready var _list: VBoxContainer = $Body/List
@onready var _footnote: RichTextLabel = $Body/Footnote


func _ready() -> void:
	# Rows before super(), for `party_screen._ready()`'s reason: `screen.gd`
	# outlines every label in one walk, and a row duplicated after that walk is
	# the one unreadable thing on the screen.
	_build_rows()
	super()


func _build_rows() -> void:
	_template = _list.get_node_or_null(^"RowTemplate") as PanelContainer
	if _template == null:
		push_error("pause menu has no RowTemplate row to duplicate")
		return
	_list.remove_child(_template)
	for i in ENTRIES.size():
		var row := _template.duplicate() as PanelContainer
		row.name = "Row%d" % (i + 1)
		row.visible = true
		(row.get_node(^"Pad/Label") as Label).text = str(ENTRIES[i][0])
		_list.add_child(row)
		_rows.append(row)


func screen_title() -> String:
	return "Paused"


func hints() -> Array[Array]:
	var rows: Array[Array] = []
	rows.append(["Up/Down", "Choose", true])
	rows.append([STYLE.glyph(&"menu_confirm"), "Select", true])
	rows.append([STYLE.glyph(&"menu_cancel"), "Resume", true])
	return rows


func focus_count() -> int:
	return ENTRIES.size()


func refresh() -> void:
	_notice_left = maxf(0.0, _notice_left - get_process_delta_time())
	if _notice_left <= 0.0:
		_notice = ""
	for i in _rows.size():
		var focused := i == focus_index()
		_rows[i].add_theme_stylebox_override("panel", STYLE.panel_style(
			STYLE.ROW_FOCUS_BG if focused else STYLE.ROW_BG,
			STYLE.ROW_FOCUS_EDGE if focused else STYLE.PANEL_EDGE
		))
	if _notice != "":
		_footnote.text = "[center][color=#%s]%s[/color][/center]" % [STYLE.WARN, _notice]
	else:
		_footnote.text = "[center][color=#%s]Progress autosaves as you play. Save & Quit writes once more on the way out.[/color][/center]" % STYLE.INK_DIM


func on_pushed() -> void:
	set_focus_index(0)
	_notice = ""
	_notice_left = 0.0


func on_activate(index: int) -> void:
	if index >= ENTRIES.size():
		return
	match str(ENTRIES[index][1]):
		"resume":
			_pop_self()
		"party":
			_open(party_screen_path, "party")
		"inventory":
			_open(inventory_screen_path, "inventory")
		"map":
			_open(map_screen_path, "map")
		"settings":
			_open(settings_screen_path, "settings")
		"quit":
			_save_and_quit()


func _pop_self() -> void:
	var stack := get_parent()
	if stack != null and stack.has_method("pop"):
		stack.call("pop")


## Push a sibling screen on top of this one. On top rather than instead: the
## stack exists so that B walks back the way you came, and a menu that swapped
## itself out would strand the player one B short of the world.
func _open(path: NodePath, label: String) -> void:
	var screen := get_node_or_null(path) as Control
	if screen == null:
		# Wiring, named as wiring — `party_screen._draw_detail`'s distinction. A
		# menu row pointing at nothing is a scene mistake, and saying so is how
		# somebody finds it.
		_say("no %s screen is wired to this menu" % label)
		return
	var stack := get_parent()
	if stack == null or not stack.has_method("push"):
		_say("there is nowhere to open the %s screen" % label)
		return
	stack.call("push", screen)


## Write the save the way the window-close path writes it, then leave.
##
## `save_now`, not `request_save`: request coalesces into a write up to
## MIN_WRITE_GAP seconds later, and there are no seconds later. The director
## runs PROCESS_MODE_ALWAYS and this is a direct call, so the paused tree the
## stack created — every menu pauses gameplay — cannot get between the press
## and the file. If the write refuses, the player stays here with the reason on
## screen instead of losing the session to a quit that pretended to save.
func _save_and_quit() -> void:
	var director := get_node_or_null(save_director_path)
	if director != null and director.has_method("save_now"):
		if not bool(director.call("save_now", "quit")):
			_say("could not save — staying here rather than losing progress")
			return
	elif director == null:
		# A preview or a harness with no director. Quit anyway — refusing to
		# close over missing wiring would trap the one person it happens to —
		# but say what did not happen first.
		print("[pause] no SaveDirector at '%s'; quitting without a save" % save_director_path)
	get_tree().quit()


func _say(message: String) -> void:
	_notice = message
	_notice_left = NOTICE_SECONDS
