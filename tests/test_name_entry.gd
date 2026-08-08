extends "res://tests/test_case.gd"

## Naming the first pal, from a gamepad.
##
## GAME_DESIGN.md §2 lists naming first among the things that make five pals
## matter, and docs/OPENING_SEQUENCE.md makes it mandatory. It is also the first
## text entry in the project, on a handheld with no keyboard — Godot's virtual
## keyboard does nothing on Windows — so the grid below IS the input method,
## not a fallback for one.

const ENTRY := preload("res://scripts/ui/name_entry.gd")

var _entry: RefCounted = null


func before_each() -> void:
	_entry = ENTRY.new()


func _walk_to(cell: String) -> bool:
	# Deliberately by search rather than by hardcoded coordinates: the layout is
	# allowed to be rearranged, and a test that knows Q is at (1, 6) fails on a
	# relayout that is not a bug.
	for r in ENTRY.ROWS.size():
		var row: Array = ENTRY.ROWS[r]
		for c in row.size():
			if str(row[c]) == cell:
				_entry.row = r
				_entry.column = c
				return true
	return false


func _type_word(word: String) -> void:
	for i in word.length():
		assert_true(_walk_to(word[i]), "'%s' is not on the keyboard at all" % word[i])
		_entry.activate()


func test_an_empty_name_cannot_be_confirmed() -> void:
	assert_false(_entry.is_valid(), "naming is mandatory; empty must not pass")
	assert_true(_walk_to(ENTRY.DONE))
	assert_eq(_entry.activate(), "", "Done on an empty name must do nothing at all")


func test_a_name_can_be_typed_and_confirmed() -> void:
	_type_word("Biscuit")
	assert_eq(_entry.text, "Biscuit")
	assert_true(_entry.is_valid())
	assert_true(_walk_to(ENTRY.DONE))
	assert_eq(_entry.activate(), "done")


func test_backspace_removes_the_last_character() -> void:
	_type_word("Ash")
	assert_true(_walk_to(ENTRY.BACKSPACE))
	assert_eq(_entry.activate(), "backspace")
	assert_eq(_entry.text, "As")


func test_backspace_on_an_empty_buffer_is_harmless() -> void:
	_entry.backspace()
	assert_eq(_entry.text, "")


func test_the_name_is_capped() -> void:
	for i in ENTRY.MAX_LENGTH + 6:
		_entry.type("a")
	assert_eq(_entry.text.length(), ENTRY.MAX_LENGTH)
	assert_false(_entry.type("a"), "a full buffer should refuse rather than pretend")


func test_a_name_cannot_start_with_a_space() -> void:
	assert_false(_entry.type(ENTRY.SPACE))
	assert_eq(_entry.text, "")


func test_whitespace_is_tidied_before_it_is_stored() -> void:
	_entry.text = "Old  Man   Willow  "
	assert_eq(_entry.sanitised(), "Old Man Willow")


func test_a_name_of_nothing_but_spaces_is_not_a_name() -> void:
	_entry.text = "   "
	assert_false(_entry.is_valid())


## --- the cursor -------------------------------------------------------------

func test_the_cursor_wraps_rather_than_stopping_dead() -> void:
	_entry.row = 0
	_entry.column = 0
	_entry.move(-1, 0)
	assert_eq(_entry.column, (ENTRY.ROWS[0] as Array).size() - 1, "left from the first cell wraps")
	_entry.row = 0
	_entry.column = 0
	_entry.move(0, -1)
	assert_eq(_entry.row, ENTRY.ROWS.size() - 1, "up from the top row reaches Done's row in one press")


## The bottom row is shorter than the others. A cursor that kept its column
## while moving onto it would sit outside the row and crash on `selected()`.
func test_moving_onto_a_shorter_row_clamps_the_column() -> void:
	var last: int = ENTRY.ROWS.size() - 1
	_entry.row = last - 1
	_entry.column = (ENTRY.ROWS[last - 1] as Array).size() - 1
	_entry.move(0, 1)
	assert_eq(_entry.row, last)
	assert_true(_entry.column < (ENTRY.ROWS[last] as Array).size(), "cursor left the grid")
	assert_ne(_entry.selected(), "", "a clamped cursor still has to name a cell")


func test_every_cell_on_the_keyboard_is_reachable_and_does_something() -> void:
	for r in ENTRY.ROWS.size():
		var row: Array = ENTRY.ROWS[r]
		assert_true(row.size() > 0, "row %d is empty" % r)
		for c in row.size():
			var cell := str(row[c])
			assert_eq(cell.length(), 1, "cell (%d,%d) is not one character: '%s'" % [r, c, cell])
			assert_ne(ENTRY.cell_label(cell), "", "cell (%d,%d) draws as nothing" % [r, c])


func test_the_keyboard_has_the_letters_it_needs() -> void:
	var flat := ""
	for row: Array in ENTRY.ROWS:
		for cell: Variant in row:
			flat += str(cell)
	for i in 26:
		var upper := char("A".unicode_at(0) + i)
		var lower := char("a".unicode_at(0) + i)
		assert_true(flat.contains(upper), "no '%s' on the keyboard" % upper)
		assert_true(flat.contains(lower), "no '%s' on the keyboard" % lower)
	assert_true(flat.contains(ENTRY.BACKSPACE), "no way to delete a mistake")
	assert_true(flat.contains(ENTRY.DONE), "no way to finish")


func test_reset_clears_the_buffer_and_the_cursor() -> void:
	_type_word("Bo")
	_entry.move(0, 3)
	_entry.reset()
	assert_eq(_entry.text, "")
	assert_eq(_entry.row, 0)
	assert_eq(_entry.column, 0)
