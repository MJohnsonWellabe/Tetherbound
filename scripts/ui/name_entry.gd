extends RefCounted

## The buffer and the cursor behind the naming prompt. Pure: no nodes, no input.
##
## This is the project's first text entry, and on the primary target — a ROG
## Ally — there is no keyboard attached. Godot's virtual keyboard
## (`DisplayServer.virtual_keyboard_show`) exists on mobile and does nothing on
## Windows, and Steam's overlay keyboard is only there when the game was
## launched through Steam. So the game brings its own grid, and this is the half
## of it that can be tested without a screen.
##
## A physical keyboard still types straight into the same buffer. The two paths
## share this object rather than sharing a Control, so neither can drift into
## having its own idea of what the pal is called.

## Long enough for a real name, short enough to fit a HUD nameplate beside a
## health bar without eliding. TUNABLE.
const MAX_LENGTH := 14

## Cell tokens. Single characters that cannot appear in a name, so a cell is
## either one of these or a literal character to type.
const BACKSPACE := "\b"
const DONE := "\n"
const SPACE := " "

## The on-screen keyboard.
##
## Upper and lower case are both laid out rather than hidden behind a shift
## cell. A shift is a mode, and a mode on a grid the player is visiting exactly
## once in the whole game is a thing to explain rather than a thing to use.
##
## Rows may be ragged; the cursor clamps to the row it is on.
const ROWS := [
	["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"],
	["K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"],
	["U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3"],
	["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"],
	["k", "l", "m", "n", "o", "p", "q", "r", "s", "t"],
	["u", "v", "w", "x", "y", "z", "4", "5", "6", "7"],
	["8", "9", "-", "'", SPACE, BACKSPACE, DONE],
]

var text: String = ""
var row: int = 0
var _column: int = 0
## The column a deliberate LEFT/RIGHT press (or a direct assignment, e.g. a
## test teleporting the cursor) last asked for, independent of the clamped
## `column` below. Rows are ragged (the bottom row is 7 cells, every other
## row is 10), so moving down onto a shorter row clamps `column` to stay in
## bounds — but without this, moving back up afterwards left the cursor
## stuck at the clamped position instead of back where the player actually
## was, which reads as the cursor randomly drifting left every time you
## brush the bottom row. OF3: named as part of the naming screen's
## "controller navigation" complaint.
var _desired_column: int = 0

## Kept as a property, not a plain field, so every write — `move()`'s own
## horizontal step or a caller teleporting the cursor directly, as the tests
## do — updates `_desired_column` in the same place, rather than every call
## site having to remember to.
var column: int:
	get:
		return _column
	set(value):
		_column = value
		_desired_column = value


func reset() -> void:
	text = ""
	row = 0
	column = 0


## --- the grid ---------------------------------------------------------------

func rows() -> Array:
	return ROWS


## Move the cursor. Wraps vertically and horizontally: on a handheld the grid is
## seven rows deep and a cursor that stops dead at the bottom edge makes the
## bottom row — which holds Done — the most expensive cell to reach.
func move(dx: int, dy: int) -> void:
	if dy != 0:
		row = wrapi(row + dy, 0, ROWS.size())
		# Restore the column the player actually asked for, clamped only far
		# enough to stay on this (possibly shorter) row — not through the
		# `column` property, which would overwrite `_desired_column` with the
		# clamped value and forget it the moment the clamp is needed.
		_column = mini(_desired_column, _row_length() - 1)
	if dx != 0:
		column = wrapi(column + dx, 0, _row_length())


func selected() -> String:
	return str(ROWS[row][column])


## Fire the selected cell. Returns what it did — "typed", "backspace", "done" or
## "" for a Done pressed on an empty name — so the caller can decide whether the
## prompt closes without re-deriving the rule.
func activate() -> String:
	var cell := selected()
	match cell:
		BACKSPACE:
			backspace()
			return "backspace"
		DONE:
			return "done" if is_valid() else ""
		_:
			return "typed" if type(cell) else ""


## --- the buffer -------------------------------------------------------------

## Append one character. Returns false when it was refused, so a full buffer is
## silent rather than pretending.
func type(character: String) -> bool:
	if character.length() != 1:
		return false
	if text.length() >= MAX_LENGTH:
		return false
	# A name that begins with a space is a name the player cannot see they typed.
	if character == SPACE and text.strip_edges() == "":
		return false
	text += character
	return true


func backspace() -> void:
	if text.length() > 0:
		text = text.substr(0, text.length() - 1)


## Naming is MANDATORY (docs/OPENING_SEQUENCE.md: "a pal you did not name is a
## pal you did not adopt"), so this is the only gate on the whole beat. Nothing
## anywhere offers a skip.
func is_valid() -> bool:
	return sanitised().length() > 0


## What actually gets stored. Trimmed, inner runs of spaces collapsed, capped.
func sanitised() -> String:
	var trimmed := text.strip_edges()
	while trimmed.contains("  "):
		trimmed = trimmed.replace("  ", " ")
	if trimmed.length() > MAX_LENGTH:
		trimmed = trimmed.substr(0, MAX_LENGTH)
	return trimmed


## How a cell should be drawn. The two tokens are not printable.
static func cell_label(cell: String) -> String:
	match cell:
		BACKSPACE:
			return "DEL"
		DONE:
			return "OK"
		SPACE:
			return "space"
		_:
			return cell


func _row_length() -> int:
	return (ROWS[row] as Array).size()
