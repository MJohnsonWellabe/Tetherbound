extends "res://scripts/ui/screen.gd"

## The world map: what you have walked, and everything worth walking back to.
##
## GAME_DESIGN.md §23. The picture is `map_canvas.gd`; this is the screen around
## it — the list of places down the right, the cursor that rings one of them on
## the map, and the two verbs the player has.
##
## THE LIST IS THE POINT, not decoration beside the map. A pin on a map tells you
## where something is; a row tells you what it is and HOW FAR, and "how far" is
## the number that gets a player back to the satchel holding their axe. §22's
## satchels are the reason this screen shipped in M9 rather than later.
##
## NO FAST TRAVEL. §23: "No free map fast travel before teleport progression."
## Confirm on a place does not move the trainer and never will from here; the only
## thing A does on a row is remove a marker the player themselves placed.
##
## WHAT IS DELIBERATELY MISSING: names for markers. §23 asks for manual markers
## and says nothing about naming them, and text entry on a controller is the
## thirteen-column grid `rename_screen.gd` already had to build once. Markers are
## numbered in the order they were dropped.

const CARD_SEPARATION := 6

@export var map_path: NodePath
@export var player_path: NodePath
@export var home_path: NodePath
@export var satchels_path: NodePath
## The world, for the elevation shading under the revealed cells. Optional: the
## map draws flat without it.
@export var world_path: NodePath = NodePath("../..")

## How long a notice stays up, matching the other screens.
const NOTICE_SECONDS := 2.5

var _notice: String = ""
var _notice_left: float = 0.0

## The rows as they were last drawn: `{kind, label, where, index}`. Rebuilt every
## refresh and read by `on_activate`, so the row the player pressed A on is the
## row they were looking at.
var _rows: Array[Dictionary] = []

@onready var _canvas: Control = $Body/Canvas
@onready var _places: RichTextLabel = $Body/Side/Pad/Lines/Places
@onready var _side: PanelContainer = $Body/Side
@onready var _legend: RichTextLabel = $Body/Side/Pad/Lines/Legend

const KIND_DROP := "drop"
const KIND_HOME := "home"
const KIND_SATCHEL := "satchel"
const KIND_MARKER := "marker"


func _ready() -> void:
	_side.add_theme_stylebox_override("panel", STYLE.panel_style(STYLE.ROW_BG, STYLE.PANEL_EDGE))
	_wire_canvas()
	super()


## Hand the canvas ABSOLUTE paths to the same nodes this screen reads.
##
## Absolute, and that is the whole reason this function exists rather than four
## exported paths in `map_screen.tscn`. `screen.gd` REPARENTS everything a screen
## authors into its content area on ready, so a relative `../../../WorldMap` set
## in the scene file would be pointing one level off the moment the screen was
## first shown — and the canvas would silently draw an empty map rather than
## erroring. One source for the wiring, resolved once, at a depth that cannot
## change.
func _wire_canvas() -> void:
	if _canvas == null:
		return
	for pair: Array in [
		["map_path", map_path],
		["player_path", player_path],
		["home_path", home_path],
		["satchels_path", satchels_path],
		["world_path", world_path],
	]:
		var target: Node = get_node_or_null(pair[1] as NodePath)
		if target != null:
			_canvas.set(str(pair[0]), target.get_path())


func _map() -> Node:
	var node := get_node_or_null(map_path)
	return node if node != null and node.has_method("markers") else null


func _player() -> Node3D:
	return get_node_or_null(player_path) as Node3D


func _home() -> Node:
	var node := get_node_or_null(home_path)
	return node if node != null and node.has_method("home_point") else null


func _satchels() -> Node:
	var node := get_node_or_null(satchels_path)
	return node if node != null and node.has_method("satchels") else null


# ------------------------------------------------------------------- the rows

## Everything on the map, as a list, in the order it is drawn.
##
## Rebuilt from the sources every frame rather than kept: a satchel emptied while
## this screen is open must leave the list, and a cached row would be a place the
## player could still select after walking away with its contents.
func _build_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	rows.append({"kind": KIND_DROP, "label": "Drop a marker where you stand", "where": Vector3.INF})

	var home := _home()
	if home != null:
		var where: Vector3 = home.call("home_point")
		if where != Vector3.INF:
			rows.append({"kind": KIND_HOME, "label": "Home", "where": where})

	var satchels := _satchels()
	if satchels != null:
		var bags: Array = satchels.call("satchels")
		for i in bags.size():
			var satchel: RefCounted = bags[i]
			rows.append({
				"kind": KIND_SATCHEL,
				"label": "Satchel %d  ·  %d stack%s" % [
					int(satchel.id), int(satchel.count()), "" if int(satchel.count()) == 1 else "s"
				],
				"where": satchel.where as Vector3,
			})

	var map := _map()
	if map != null:
		var pins: Array = map.call("markers")
		for i in pins.size():
			var marker: Dictionary = pins[i]
			rows.append({
				"kind": KIND_MARKER,
				"label": str(marker.get("label", "Marker")),
				"where": Vector3(float(marker["x"]), float(marker["y"]), float(marker["z"])),
				"index": i,
			})
	return rows


# --------------------------------------------------------------------- drawing

func screen_title() -> String:
	var map := _map()
	if map == null:
		return "Map"
	# Not a percentage. There is no total to be a percentage OF until the authored
	# Meadows exists, and a made-up denominator would be the one number on this
	# screen that is not true.
	return "Map    %d places explored" % int(map.call("revealed_count"))


func hints() -> Array[Array]:
	var verb := _verb_for(focus_index())
	var rows: Array[Array] = []
	rows.append(["Up/Down", "Choose", true])
	rows.append(["A", str(verb["label"]), bool(verb["ready"])])
	rows.append(["B", "Back", true])
	return rows


func focus_count() -> int:
	return maxi(1, _rows.size())


func refresh() -> void:
	_notice_left = maxf(0.0, _notice_left - get_process_delta_time())
	if _notice_left <= 0.0:
		_notice = ""

	_rows = _build_rows()
	if focus_index() >= _rows.size():
		set_focus_index(_rows.size() - 1)

	var focused: Dictionary = _rows[focus_index()] if focus_index() < _rows.size() else {}
	if _canvas != null:
		# The cursor rings the place it is on, so the list and the picture are the
		# same selection rather than two things to correlate by name.
		_canvas.set("highlight", focused.get("where", Vector3.INF))

	_places.text = "\n".join(_place_lines())
	# Each word in the colour of the pin it names, so the key reads as a key.
	_legend.text = "[color=#%s]▲ you[/color]    [color=#%s]⌂ home[/color]    [color=#%s]▬ satchel[/color]    [color=#%s]✕ marker[/color]" % [
		STYLE.INK, STYLE.GOOD, _ink_for(KIND_SATCHEL), _ink_for(KIND_MARKER)
	]


func _place_lines() -> Array[String]:
	var lines: Array[String] = []
	var trainer := _player()
	var here: Vector3 = trainer.global_position if trainer != null else Vector3.ZERO

	for i in _rows.size():
		var row := _rows[i]
		var focused := i == focus_index()
		var distance := ""
		var where: Vector3 = row.get("where", Vector3.INF)
		if where != Vector3.INF and trainer != null:
			distance = "   [color=#%s]%dm[/color]" % [
				STYLE.INK_DIM, roundi(Vector2(where.x - here.x, where.z - here.z).length())
			]
		var colour := _ink_for(str(row["kind"]))
		lines.append("%s[color=#%s]%s[/color]%s" % [
			"[b]>[/b]  " if focused else "     ", colour, str(row["label"]), distance
		])

	if _rows.size() <= 1:
		lines.append("")
		lines.append("[color=#%s]%s[/color]" % [
			STYLE.INK_DIM,
			"Nothing is pinned yet. The map fills in as you walk, and anything you "
			+ "drop by dying is marked here until you go back for it."
		])
	if not _notice.is_empty():
		lines.append("")
		lines.append("[color=#%s]%s[/color]" % [STYLE.WARN, _notice])
	return lines


## Row colours match the pins on the canvas beside them. A satchel that is amber
## on the map and white in the list is two things the player has to learn.
func _ink_for(kind: String) -> String:
	match kind:
		KIND_HOME:
			return STYLE.GOOD
		KIND_SATCHEL:
			return "d99e47"
		KIND_MARKER:
			return "8cc2e6"
		_:
			return STYLE.INK


# ---------------------------------------------------------------------- verbs

func _verb_for(index: int) -> Dictionary:
	if index < 0 or index >= _rows.size():
		return {"label": "Select", "ready": false}
	match str(_rows[index]["kind"]):
		KIND_DROP:
			return {"label": "Drop marker", "ready": true}
		KIND_MARKER:
			return {"label": "Remove marker", "ready": true}
		_:
			# §23 forbids free fast travel, so there is nothing to do to a place
			# except look at it. The prompt dims rather than disappearing.
			return {"label": "Select", "ready": false}


func on_activate(index: int) -> void:
	if index < 0 or index >= _rows.size():
		return
	var row := _rows[index]
	var map := _map()
	if map == null:
		_say("there is no map to change")
		return

	match str(row["kind"]):
		KIND_DROP:
			var trainer := _player()
			if trainer == null:
				_say("this screen is not wired to the trainer")
				return
			if bool(map.call("add_marker", trainer.global_position)):
				_say("marker dropped where you are standing")
			else:
				_say("that is as many markers as the map will hold")
		KIND_MARKER:
			if bool(map.call("remove_marker", int(row.get("index", -1)))):
				_say("marker removed")
				set_focus_index(maxi(0, index - 1))
			else:
				_say("that marker is already gone")
		KIND_SATCHEL:
			# Said out loud rather than left as a dead button, so nobody concludes
			# the map is broken. §23 is the reason and it is worth quoting to the
			# player in their own words.
			_say("nothing to do from here — you have to walk back for it")
		_:
			_say("nothing to do from here")


func on_pushed() -> void:
	_notice = ""
	_notice_left = 0.0
	set_focus_index(0)


func _say(message: String) -> void:
	_notice = message
	_notice_left = NOTICE_SECONDS
