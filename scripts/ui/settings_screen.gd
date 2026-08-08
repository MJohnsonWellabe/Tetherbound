extends "res://scripts/ui/screen.gd"

## Settings: the few knobs the owner asked for, each applied the moment it
## changes and persisted the same moment (to `user://settings.json`, through
## `settings.gd` — see its header for the two-file split).
##
## Rows are declared in `_entries()` rather than authored five times in the
## .tscn, and VALUES ARE PULLED every frame like every other screen: a settings
## row that cached "Off" while the file said on would be the menu disagreeing
## with the game about the game's own rules.
##
## Left/right changes a value (`on_nudge` — the same verb every screen uses for
## "a row with a value on it"); A toggles a toggle and opens the remap screen.
## Nothing here needs an Apply button: there is no setting whose half-applied
## state is dangerous, and a handheld can lose power at any moment.

const SETTINGS := preload("res://scripts/ui/settings.gd")

## Master volume moves in these steps. Coarse on purpose — a menu driven by
## a D-pad wants ten presses across the range, not a hundred. Tunable.
const VOLUME_STEP := 0.1

@export var remap_screen_path: NodePath

var _rows: Array[PanelContainer] = []
var _template: PanelContainer = null

@onready var _list: VBoxContainer = $Body/List
@onready var _footnote: RichTextLabel = $Body/Footnote


func _ready() -> void:
	_build_rows()
	super()


## What the screen offers. A function, not a const, because the combat-speed
## row's choices come from data (`speed_choices` in settings.json) and data is
## not loaded when consts are.
func _entries() -> Array[Dictionary]:
	return [
		{
			"id": "free_build",
			"label": "Free building",
			"kind": "toggle",
			"blurb": "Building costs no materials. The ghost never goes amber over an empty pocket.",
		},
		{
			"id": "speed_scale",
			"label": "Combat speed",
			"kind": "choice",
			"blurb": "How fast the opponent fights. Applies from the next fight.",
		},
		{
			"id": "master_volume",
			"label": "Master volume",
			"kind": "volume",
			"blurb": "Everything the game plays, in one knob.",
		},
		{
			"id": "remap",
			"label": "Button mapping",
			"kind": "screen",
			"blurb": "See and change what every button does.",
		},
	]


func _build_rows() -> void:
	_template = _list.get_node_or_null(^"RowTemplate") as PanelContainer
	if _template == null:
		push_error("settings screen has no RowTemplate row to duplicate")
		return
	_list.remove_child(_template)
	for i in _entries().size():
		var row := _template.duplicate() as PanelContainer
		row.name = "Row%d" % (i + 1)
		row.visible = true
		_list.add_child(row)
		_rows.append(row)


func screen_title() -> String:
	return "Settings"


func hints() -> Array[Array]:
	var entry := _focused_entry()
	var kind := str(entry.get("kind", ""))
	var rows: Array[Array] = []
	rows.append(["Up/Down", "Choose", true])
	rows.append(["Left/Right", "Change", kind == "choice" or kind == "volume" or kind == "toggle"])
	rows.append([STYLE.glyph(&"menu_confirm"),
		"Open" if kind == "screen" else "Toggle", kind == "screen" or kind == "toggle"])
	rows.append([STYLE.glyph(&"menu_cancel"), "Back", true])
	return rows


func focus_count() -> int:
	return _entries().size()


func _focused_entry() -> Dictionary:
	var entries := _entries()
	if focus_index() >= entries.size():
		return {}
	return entries[focus_index()]


func refresh() -> void:
	var entries := _entries()
	for i in _rows.size():
		var row := _rows[i]
		var entry: Dictionary = entries[i] if i < entries.size() else {}
		var focused := i == focus_index()
		row.add_theme_stylebox_override("panel", STYLE.panel_style(
			STYLE.ROW_FOCUS_BG if focused else STYLE.ROW_BG,
			STYLE.ROW_FOCUS_EDGE if focused else STYLE.PANEL_EDGE
		))
		(row.get_node(^"Pad/Line/Label") as Label).text = str(entry.get("label", ""))
		(row.get_node(^"Pad/Line/Value") as Label).text = _value_text(entry)
	_footnote.text = "[center][color=#%s]%s[/color][/center]" % [
		STYLE.INK_DIM, str(_focused_entry().get("blurb", ""))
	]


func _value_text(entry: Dictionary) -> String:
	match str(entry.get("kind", "")):
		"toggle":
			return "On" if bool(SETTINGS.value(str(entry["id"]), false)) else "Off"
		"choice":
			return str(SETTINGS.speed_choices()[_choice_index()].get("label", "?"))
		"volume":
			return "%d%%" % roundi(SETTINGS.master_volume() * 100.0)
		"screen":
			return "…"
	return ""


## Which of the speed choices the stored multiplier is, nearest wins. Nearest
## rather than exact, so a hand-edited or stale value still lands on a real
## position instead of drawing a selector pointing at nothing.
func _choice_index() -> int:
	var stored := SETTINGS.speed_scale()
	var choices := SETTINGS.speed_choices()
	var best := 0
	var best_distance := INF
	for i in choices.size():
		var distance := absf(float((choices[i] as Dictionary).get("value", 1.0)) - stored)
		if distance < best_distance:
			best_distance = distance
			best = i
	return best


func on_nudge(index: int, direction: int) -> void:
	var entries := _entries()
	if index >= entries.size():
		return
	var entry := entries[index]
	match str(entry.get("kind", "")):
		"toggle":
			SETTINGS.set_value(str(entry["id"]), not bool(SETTINGS.value(str(entry["id"]), false)))
		"choice":
			var choices := SETTINGS.speed_choices()
			var next := clampi(_choice_index() + direction, 0, choices.size() - 1)
			SETTINGS.set_value("speed_scale", float((choices[next] as Dictionary).get("value", 1.0)))
		"volume":
			var wanted := clampf(SETTINGS.master_volume() + float(direction) * VOLUME_STEP, 0.0, 1.0)
			SETTINGS.set_value("master_volume", wanted)
			# Heard immediately, or the knob cannot be set by ear.
			SETTINGS.apply_master_volume()


func on_activate(index: int) -> void:
	var entries := _entries()
	if index >= entries.size():
		return
	var entry := entries[index]
	match str(entry.get("kind", "")):
		"toggle":
			on_nudge(index, 1)
		"screen":
			_open_remap()


func _open_remap() -> void:
	var screen := get_node_or_null(remap_screen_path) as Control
	var stack := get_parent()
	if screen == null or stack == null or not stack.has_method("push"):
		push_warning("settings screen has no remap screen wired at '%s'" % remap_screen_path)
		return
	stack.call("push", screen)
